#!/bin/bash

# 一键安装和运行脚本
# 自动下载、授权并执行setup_root_ssh.sh

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 脚本URL
SCRIPT_URL="https://raw.githubusercontent.com/DaBoWin/SshRoot/main/setup_root_ssh.sh"
SCRIPT_NAME="setup_root_ssh.sh"

echo -e "${BLUE}=== 一键Root密码和SSH端口配置工具 ===${NC}"
echo

# 检查网络连接
echo -e "${YELLOW}[1/4]${NC} 检查网络连接..."
if ! ping -c 1 github.com >/dev/null 2>&1; then
    echo -e "${RED}错误: 无法连接到GitHub，请检查网络连接${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 网络连接正常${NC}"

# 下载脚本
echo -e "${YELLOW}[2/4]${NC} 下载脚本..."
if command -v wget >/dev/null 2>&1; then
    wget -q -O "$SCRIPT_NAME" "$SCRIPT_URL"
elif command -v curl >/dev/null 2>&1; then
    curl -s -o "$SCRIPT_NAME" "$SCRIPT_URL"
else
    echo -e "${RED}错误: 系统中没有wget或curl命令${NC}"
    exit 1
fi

if [[ ! -f "$SCRIPT_NAME" ]]; then
    echo -e "${RED}错误: 脚本下载失败${NC}"
    exit 1
fi
echo -e "${GREEN}✓ 脚本下载成功${NC}"

# 设置执行权限
echo -e "${YELLOW}[3/4]${NC} 设置执行权限..."
chmod +x "$SCRIPT_NAME"
echo -e "${GREEN}✓ 权限设置完成${NC}"

# 执行脚本
echo -e "${YELLOW}[4/4]${NC} 启动配置脚本..."
echo
./"$SCRIPT_NAME"

# 清理
echo
echo -e "${BLUE}清理临时文件...${NC}"
read -p "是否删除下载的脚本文件? (y/N): " cleanup
if [[ "$cleanup" =~ ^[Yy]$ ]]; then
    rm -f "$SCRIPT_NAME"
    echo -e "${GREEN}✓ 清理完成${NC}"
else
    echo -e "${YELLOW}脚本文件保留: $SCRIPT_NAME${NC}"
fi