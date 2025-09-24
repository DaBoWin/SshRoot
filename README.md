# 一键设置Root密码和SSH端口脚本

这是一个安全、易用的Linux系统管理脚本，用于快速配置root用户密码和SSH服务设置。

## 功能特性

- 🔐 **密码管理**: 支持随机生成强密码或设置自定义密码
- 🚪 **端口配置**: 自定义SSH端口，提高安全性
- 🛡️ **安全配置**: 自动配置SSH允许root登录和密码认证
- 🔥 **防火墙**: 自动检测并配置防火墙规则（UFW/firewalld/iptables）
- 💾 **备份保护**: 自动备份原始配置文件
- ✅ **验证检查**: 配置语法验证和服务状态检查

## 快速开始

### 一键执行命令

**方式1: 使用wget（推荐）**
```bash
wget -O setup_root_ssh.sh https://raw.githubusercontent.com/DaBoWin/SshRoot/main/setup_root_ssh.sh && chmod +x setup_root_ssh.sh && ./setup_root_ssh.sh
```

**方式2: 使用curl**
```bash
curl -o setup_root_ssh.sh https://raw.githubusercontent.com/DaBoWin/SshRoot/main/setup_root_ssh.sh && chmod +x setup_root_ssh.sh && ./setup_root_ssh.sh
```

**方式3: 使用安装脚本**
```bash
curl -s https://raw.githubusercontent.com/DaBoWin/SshRoot/main/install.sh | bash
```

### 分步执行（可选）

```bash
# 下载脚本
wget https://raw.githubusercontent.com/DaBoWin/SshRoot/main/setup_root_ssh.sh

# 或者使用curl
curl -O https://raw.githubusercontent.com/DaBoWin/SshRoot/main/setup_root_ssh.sh

# 给予执行权限
chmod +x setup_root_ssh.sh

# 运行脚本（推荐方式，脚本会自动处理权限）
./setup_root_ssh.sh
```

### 其他运行方式

```bash
# 方式1: 直接使用sudo
sudo ./setup_root_ssh.sh

# 方式2: 切换到root用户后运行
sudo -i
./setup_root_ssh.sh

# 方式3: 使用su切换
su -
./setup_root_ssh.sh
```

## 使用说明

### 1. 权限检查
脚本会自动检查并处理权限问题：
- 如果不是root用户，会尝试使用sudo提升权限
- 如果sudo不可用，会提示手动切换到root用户

### 2. 密码设置
脚本提供两种密码设置方式：
- **随机密码**: 自动生成16位强密码
- **自定义密码**: 手动输入密码（最少8位）

### 3. SSH端口配置
- 显示当前SSH端口
- 支持设置1024-65535范围内的端口
- 自动检查端口占用情况
- 可选择保持当前端口

### 4. 防火墙配置
脚本会自动检测系统防火墙类型并配置：
- **UFW**: Ubuntu/Debian系统常用
- **firewalld**: CentOS/RHEL/Fedora系统常用  
- **iptables**: 传统Linux防火墙

## 安全特性

- ✅ Root权限验证
- ✅ SSH配置语法检查
- ✅ 端口占用检测
- ✅ 密码强度验证
- ✅ 配置文件自动备份
- ✅ 服务状态监控
- ✅ 错误处理和回滚

## 配置文件备份

脚本会自动备份原始SSH配置文件到：
```
/etc/ssh/sshd_config.backup.YYYYMMDD_HHMMSS
```

如需恢复原始配置：
```bash
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 完成后测试

脚本执行完成后，请立即测试新的SSH连接：

```bash
# 使用新端口连接
ssh root@your_server_ip -p new_port

# 示例
ssh root@192.168.1.100 -p 2222
```

## 安全建议

1. **立即测试**: 完成配置后立即测试SSH连接
2. **密钥认证**: 建议后续配置SSH密钥认证
3. **定期更新**: 保持系统和SSH服务更新
4. **防护工具**: 考虑安装fail2ban防止暴力破解
5. **监控日志**: 定期检查SSH登录日志

## 故障排除

### 无法连接SSH
1. 检查防火墙规则是否正确
2. 确认SSH服务是否正常运行
3. 验证端口是否被其他服务占用

### 权限问题
1. 确保当前用户有sudo权限
2. 或直接使用root用户运行脚本

### 配置恢复
如果配置出现问题，可以恢复备份：
```bash
sudo cp /etc/ssh/sshd_config.backup.* /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## 系统兼容性

- ✅ Ubuntu/Debian
- ✅ CentOS/RHEL/Rocky Linux
- ✅ Fedora
- ✅ Amazon Linux
- ✅ 其他主流Linux发行版

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request来改进这个脚本。

---

**⚠️ 重要提醒**: 修改SSH配置具有一定风险，请确保在安全的环境下操作，并保持至少一个可用的管理连接。
