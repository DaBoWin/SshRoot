#!/bin/bash

# 一键设置root密码和SSH端口脚本
# 作者: Assistant
# 版本: 1.0

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户并自动提升权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_warn "检测到非root用户，正在尝试提升权限..."
        
        # 检查sudo是否可用
        if ! command -v sudo >/dev/null 2>&1; then
            log_error "sudo命令不可用，请手动切换到root用户"
            log_info "使用命令: su - 或 sudo -i"
            exit 1
        fi
        
        # 检查当前用户是否在sudo组
        if ! sudo -n true 2>/dev/null; then
            log_error "当前用户没有sudo权限"
            log_info "请使用以下方式之一："
            echo "  1. sudo $0"
            echo "  2. sudo -i 然后运行 $0"
            echo "  3. su - 切换到root用户后运行"
            exit 1
        fi
        
        log_info "正在以root权限重新执行脚本..."
        exec sudo "$0" "$@"
    fi
    
    log_info "已确认root权限"
}

# 生成随机密码
generate_password() {
    local length=${1:-12}
    tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c $length
}

# 设置root密码
set_root_password() {
    log_step "设置root密码"
    
    echo "请选择密码设置方式:"
    echo "1) 生成随机密码"
    echo "2) 设置自定义密码"
    read -p "请输入选择 (1-2): " password_choice
    
    case $password_choice in
        1)
            NEW_PASSWORD=$(generate_password 16)
            log_info "生成的随机密码: $NEW_PASSWORD"
            echo "请务必保存此密码！"
            read -p "按回车键继续..."
            ;;
        2)
            while true; do
                read -s -p "请输入新的root密码: " NEW_PASSWORD
                echo
                read -s -p "请再次确认密码: " CONFIRM_PASSWORD
                echo
                
                if [[ "$NEW_PASSWORD" == "$CONFIRM_PASSWORD" ]]; then
                    if [[ ${#NEW_PASSWORD} -lt 8 ]]; then
                        log_warn "密码长度至少8位，请重新输入"
                        continue
                    fi
                    break
                else
                    log_warn "两次输入的密码不一致，请重新输入"
                fi
            done
            ;;
        *)
            log_error "无效选择"
            exit 1
            ;;
    esac
    
    # 设置密码
    echo "root:$NEW_PASSWORD" | chpasswd
    if [[ $? -eq 0 ]]; then
        log_info "root密码设置成功"
    else
        log_error "root密码设置失败"
        exit 1
    fi
}

# 设置SSH端口
set_ssh_port() {
    log_step "配置SSH端口"
    
    # 获取当前SSH端口
    CURRENT_PORT=$(grep -E "^#?Port" /etc/ssh/sshd_config | grep -o '[0-9]*' | head -1)
    if [[ -z "$CURRENT_PORT" ]]; then
        CURRENT_PORT=22
    fi
    
    log_info "当前SSH端口: $CURRENT_PORT"
    
    while true; do
        read -p "请输入新的SSH端口 (1024-65535，回车保持当前端口): " NEW_PORT
        
        if [[ -z "$NEW_PORT" ]]; then
            NEW_PORT=$CURRENT_PORT
            log_info "保持当前端口: $NEW_PORT"
            break
        fi
        
        if [[ "$NEW_PORT" =~ ^[0-9]+$ ]] && [[ $NEW_PORT -ge 1024 ]] && [[ $NEW_PORT -le 65535 ]]; then
            # 检查端口是否被占用
            if netstat -tuln | grep -q ":$NEW_PORT "; then
                log_warn "端口 $NEW_PORT 已被占用，请选择其他端口"
                continue
            fi
            log_info "将使用端口: $NEW_PORT"
            break
        else
            log_warn "请输入有效的端口号 (1024-65535)"
        fi
    done
}

# 备份SSH配置
backup_ssh_config() {
    log_step "备份SSH配置文件"
    
    BACKUP_FILE="/etc/ssh/sshd_config.backup.$(date +%Y%m%d_%H%M%S)"
    cp /etc/ssh/sshd_config "$BACKUP_FILE"
    
    if [[ $? -eq 0 ]]; then
        log_info "SSH配置已备份到: $BACKUP_FILE"
    else
        log_error "备份SSH配置失败"
        exit 1
    fi
}

# 配置SSH
configure_ssh() {
    log_step "配置SSH服务"
    
    # 修改SSH配置
    sed -i "s/^#*Port.*/Port $NEW_PORT/" /etc/ssh/sshd_config
    sed -i "s/^#*PermitRootLogin.*/PermitRootLogin yes/" /etc/ssh/sshd_config
    sed -i "s/^#*PasswordAuthentication.*/PasswordAuthentication yes/" /etc/ssh/sshd_config
    sed -i "s/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/" /etc/ssh/sshd_config
    
    # 确保配置存在（如果没有则添加）
    if ! grep -q "^Port" /etc/ssh/sshd_config; then
        echo "Port $NEW_PORT" >> /etc/ssh/sshd_config
    fi
    
    if ! grep -q "^PermitRootLogin" /etc/ssh/sshd_config; then
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
    fi
    
    if ! grep -q "^PasswordAuthentication" /etc/ssh/sshd_config; then
        echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
    fi
    
    log_info "SSH配置修改完成"
}

# 配置防火墙
configure_firewall() {
    log_step "配置防火墙"
    
    # 检测防火墙类型并配置
    if command -v ufw >/dev/null 2>&1; then
        log_info "检测到UFW防火墙"
        ufw allow $NEW_PORT/tcp
        log_info "已添加UFW规则允许端口 $NEW_PORT"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        log_info "检测到firewalld防火墙"
        firewall-cmd --permanent --add-port=$NEW_PORT/tcp
        firewall-cmd --reload
        log_info "已添加firewalld规则允许端口 $NEW_PORT"
    elif command -v iptables >/dev/null 2>&1; then
        log_info "检测到iptables防火墙"
        iptables -I INPUT -p tcp --dport $NEW_PORT -j ACCEPT
        # 尝试保存iptables规则
        if command -v iptables-save >/dev/null 2>&1; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        log_info "已添加iptables规则允许端口 $NEW_PORT"
    else
        log_warn "未检测到防火墙或防火墙未启用"
    fi
}

# 重启SSH服务
restart_ssh() {
    log_step "重启SSH服务"
    
    # 测试SSH配置
    sshd -t
    if [[ $? -ne 0 ]]; then
        log_error "SSH配置文件有错误，请检查"
        exit 1
    fi
    
    # 重启SSH服务
    if systemctl is-active --quiet ssh; then
        systemctl restart ssh
        SERVICE_NAME="ssh"
    elif systemctl is-active --quiet sshd; then
        systemctl restart sshd
        SERVICE_NAME="sshd"
    else
        log_error "无法确定SSH服务名称"
        exit 1
    fi
    
    if [[ $? -eq 0 ]]; then
        log_info "SSH服务重启成功"
    else
        log_error "SSH服务重启失败"
        exit 1
    fi
    
    # 检查服务状态
    sleep 2
    if systemctl is-active --quiet $SERVICE_NAME; then
        log_info "SSH服务运行正常"
    else
        log_error "SSH服务启动异常"
        exit 1
    fi
}

# 显示配置信息
show_summary() {
    log_step "配置完成"
    
    echo
    echo "=================================="
    echo -e "${GREEN}配置摘要${NC}"
    echo "=================================="
    echo "SSH端口: $NEW_PORT"
    echo "Root登录: 已启用"
    echo "密码认证: 已启用"
    if [[ $password_choice -eq 1 ]]; then
        echo "Root密码: $NEW_PASSWORD (请妥善保存)"
    else
        echo "Root密码: 已设置自定义密码"
    fi
    echo "配置备份: $BACKUP_FILE"
    echo "=================================="
    echo
    
    log_warn "重要提醒:"
    echo "1. 请立即测试新的SSH连接，确保能正常登录"
    echo "2. 建议使用密钥认证替代密码认证"
    echo "3. 定期更新系统和SSH服务"
    echo "4. 考虑使用fail2ban等工具防止暴力破解"
    echo
    echo "测试连接命令:"
    echo "ssh root@$(hostname -I | awk '{print $1}') -p $NEW_PORT"
}

# 显示使用说明
show_usage() {
    echo "=================================="
    echo -e "${BLUE}一键设置Root密码和SSH端口脚本${NC}"
    echo "=================================="
    echo
    echo "使用方法："
    echo "  方式1（推荐）: ./setup_root_ssh.sh"
    echo "  方式2: sudo ./setup_root_ssh.sh"
    echo "  方式3: sudo -i 然后运行 ./setup_root_ssh.sh"
    echo
    echo "脚本功能："
    echo "  • 设置root密码（随机生成或自定义）"
    echo "  • 自定义SSH端口"
    echo "  • 配置SSH允许root登录"
    echo "  • 自动配置防火墙规则"
    echo "  • 备份原配置文件"
    echo
}

# 主函数
main() {
    show_usage
    check_root
    
    log_info "开始配置过程..."
    echo
    
    set_root_password
    set_ssh_port
    backup_ssh_config
    configure_ssh
    configure_firewall
    restart_ssh
    show_summary
    
    log_info "脚本执行完成！"
}

# 执行主函数
main "$@"