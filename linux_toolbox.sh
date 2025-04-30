#!/bin/bash

# Linux万能工具箱
# 版本: 1.0.0
# 作者: Your Name
# 描述: 集成多种Linux系统工具的万能工具箱

# 定义颜色变量，用于终端输出美化
RED='\033[0;31m'    # 红色，用于错误信息
GREEN='\033[0;32m'  # 绿色，用于成功信息
YELLOW='\033[0;33m' # 黄色，用于警告信息
BLUE='\033[0;34m'   # 蓝色，用于提示信息
NC='\033[0m'        # 无颜色，用于重置颜色

# 检查是否以root权限运行
check_root() {
    # 检查当前用户是否为root
    if [ "$EUID" -ne 0 ]; then
        # 如果不是root用户，显示错误信息并退出
        echo -e "${RED}请使用root权限运行此脚本${NC}"
        exit 1
    fi
}

# 显示欢迎信息
show_welcome() {
    # 清屏
    clear
    # 显示欢迎界面
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}      Linux万能工具箱 v1.0.0${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${YELLOW}请选择要执行的功能：${NC}"
    echo ""
}

# 显示主菜单
show_menu() {
    # 显示所有可用的功能选项
    echo "1. SOCKS5代理连接"
    echo "0. 退出"
    echo ""
    # 提示用户输入选择
    read -p "请输入选项 [0-1]: " choice
}

# SOCKS5代理连接功能
setup_socks5_proxy() {
    # 清屏
    clear
    echo -e "${GREEN}SOCKS5代理连接设置${NC}"
    echo "----------------------------------------"
    
    # 提示用户输入远程服务器信息
    while true; do
        read -p "请输入远程服务器IP地址: " remote_ip
        # 验证IP地址格式
        if [[ $remote_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}IP地址格式不正确，请重新输入${NC}"
        fi
    done
    
    # 提示用户输入远程服务器端口
    while true; do
        read -p "请输入远程服务器端口: " remote_port
        # 验证端口号是否在有效范围内
        if [[ $remote_port =~ ^[0-9]+$ ]] && [ $remote_port -ge 1 ] && [ $remote_port -le 65535 ]; then
            break
        else
            echo -e "${RED}端口号必须在1-65535之间，请重新输入${NC}"
        fi
    done
    
    # 提示用户输入本地监听信息
    read -p "请输入本地监听IP地址 [默认127.0.0.1]: " local_ip
    read -p "请输入本地监听端口 [默认1080]: " local_port
    read -p "请输入远程服务器用户名: " username
    
    # 设置默认值
    local_ip=${local_ip:-127.0.0.1}
    local_port=${local_port:-1080}
    
    # 显示确认信息
    echo -e "\n${YELLOW}连接信息确认：${NC}"
    echo "远程服务器: $remote_ip:$remote_port"
    echo "本地监听: $local_ip:$local_port"
    echo "用户名: $username"
    
    # 确认是否继续
    read -p "是否继续？(y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}已取消操作${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 创建SSH隧道
    echo -e "${YELLOW}正在创建SSH隧道...${NC}"
    # 使用screen创建后台会话运行SSH隧道
    screen -dmS socks_proxy ssh -p $remote_port -D $local_ip:$local_port $username@$remote_ip
    
    # 检查screen会话是否创建成功
    if screen -list | grep -q "socks_proxy"; then
        echo -e "${GREEN}SSH隧道创建成功！${NC}"
        echo "本地监听地址: $local_ip:$local_port"
    else
        echo -e "${RED}SSH隧道创建失败！${NC}"
    fi
    
    # 等待用户确认
    read -p "按回车键返回主菜单..."
}

# 主循环
while true; do
    # 显示欢迎界面
    show_welcome
    # 显示主菜单
    show_menu
    
    # 根据用户选择执行相应功能
    case $choice in
        1) 
            # 调用SOCKS5代理连接功能
            setup_socks5_proxy
            ;;
        0) 
            # 退出程序
            echo -e "${GREEN}感谢使用！再见！${NC}"
            exit 0
            ;;
        *)
            # 处理无效输入
            echo -e "${RED}无效选项，请重新选择${NC}"
            sleep 1
            ;;
    esac
done 