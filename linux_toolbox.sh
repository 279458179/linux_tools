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

# 检查并安装Privoxy
install_privoxy() {
    # 检查Privoxy是否已安装
    if ! command -v privoxy &>/dev/null; then
        echo -e "${YELLOW}正在安装Privoxy...${NC}"
        # 根据不同的Linux发行版安装Privoxy
        if command -v apt-get &>/dev/null; then
            apt-get update
            apt-get install -y privoxy
        elif command -v yum &>/dev/null; then
            yum install -y privoxy
        elif command -v dnf &>/dev/null; then
            dnf install -y privoxy
        else
            echo -e "${RED}无法确定包管理器，请手动安装Privoxy${NC}"
            exit 1
        fi
    fi
}

# 配置Privoxy
configure_privoxy() {
    # 备份原始配置文件
    cp /etc/privoxy/config /etc/privoxy/config.bak

    # 添加SOCKS5转发配置
    echo "forward-socks5 / $local_ip:$local_port ." >>/etc/privoxy/config

    # 重启Privoxy服务
    systemctl restart privoxy
    systemctl enable privoxy

    # 检查服务状态
    if systemctl is-active --quiet privoxy; then
        echo -e "${GREEN}Privoxy服务已成功启动${NC}"
        echo "HTTP代理地址: 127.0.0.1:8118"
    else
        echo -e "${RED}Privoxy服务启动失败${NC}"
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
    
    # 测试SSH连接
    echo -e "${YELLOW}正在测试SSH连接...${NC}"
    if ! ssh -p $remote_port -o ConnectTimeout=5 $username@$remote_ip "echo 'SSH连接测试成功'"; then
        echo -e "${RED}SSH连接测试失败，请检查用户名、密码或服务器状态${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 创建SSH隧道
    echo -e "${YELLOW}正在创建SSH隧道...${NC}"
    # 使用screen创建后台会话运行SSH隧道，添加-v参数显示详细连接信息
    screen -dmS socks_proxy ssh -v -p $remote_port -D $local_ip:$local_port $username@$remote_ip
    
    # 等待几秒钟让连接建立
    sleep 3
    
    # 检查screen会话是否创建成功
    if screen -list | grep -q "socks_proxy"; then
        echo -e "${GREEN}SSH隧道创建成功！${NC}"
        echo "本地监听地址: $local_ip:$local_port"
        
        # 安装和配置Privoxy
        install_privoxy
        
        # 配置Privoxy
        echo -e "${YELLOW}正在配置Privoxy...${NC}"
        # 备份原始配置文件
        cp /etc/privoxy/config /etc/privoxy/config.bak
        
        # 添加SOCKS5转发配置
        echo "forward-socks5 / $local_ip:$local_port ." >>/etc/privoxy/config
        
        # 重启Privoxy服务
        systemctl restart privoxy
        systemctl enable privoxy
        
        # 检查服务状态
        if systemctl is-active --quiet privoxy; then
            echo -e "${GREEN}Privoxy服务已成功启动${NC}"
            echo "HTTP代理地址: 127.0.0.1:8118"
            
            # 测试代理连接
            echo -e "${YELLOW}正在测试代理连接...${NC}"
            if curl -x http://127.0.0.1:8118 http://www.google.com &>/dev/null; then
                echo -e "${GREEN}代理连接测试成功！${NC}"
            else
                echo -e "${RED}代理连接测试失败，请检查配置${NC}"
            fi
            
            echo -e "\n${GREEN}代理设置完成！${NC}"
            echo "SOCKS5代理地址: $local_ip:$local_port"
            echo "HTTP代理地址: 127.0.0.1:8118"
            echo -e "\n${YELLOW}使用说明：${NC}"
            echo "1. 在浏览器中设置HTTP代理为 127.0.0.1:8118"
            echo "2. 或在系统网络设置中配置HTTP代理"
        else
            echo -e "${RED}Privoxy服务启动失败${NC}"
        fi
    else
        echo -e "${RED}SSH隧道创建失败！${NC}"
    fi
    
    # 等待用户确认
    read -p "按回车键返回主菜单..."
}

# 主函数
main() {
    # 检查root权限
    check_root
    
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
}

# 确保脚本在非交互式shell中也能运行
if [ -t 0 ]; then
    # 交互式shell
    main
else
    # 非交互式shell，先下载脚本再执行
    echo "正在下载脚本..."
    curl -sL https://raw.githubusercontent.com/279458179/linux_tools/master/linux_toolbox.sh -o /tmp/linux_toolbox.sh
    chmod +x /tmp/linux_toolbox.sh
    exec /tmp/linux_toolbox.sh
fi
