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

# 检查并安装sshpass
install_sshpass() {
    # 检查sshpass是否已安装
    if ! command -v sshpass &>/dev/null; then
        echo -e "${YELLOW}正在安装sshpass...${NC}"
        # 根据不同的Linux发行版安装sshpass
        if command -v apt-get &>/dev/null; then
            apt-get update
            apt-get install -y sshpass
        elif command -v yum &>/dev/null; then
            yum install -y sshpass
        elif command -v dnf &>/dev/null; then
            dnf install -y sshpass
        else
            echo -e "${RED}无法确定包管理器，请手动安装sshpass${NC}"
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
    echo "1. 系统管理"
    echo "2. SOCKS5代理连接"
    echo "0. 退出"
    echo ""
    # 提示用户输入选择
    read -p "请输入选项 [0-2]: " choice
}

# 配置SSH密钥认证
setup_ssh_key() {
    # 检查是否已有SSH密钥
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo -e "${YELLOW}正在生成SSH密钥...${NC}"
        # 生成SSH密钥，不设置密码
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    fi
    
    # 显示公钥
    echo -e "${GREEN}您的SSH公钥：${NC}"
    cat ~/.ssh/id_rsa.pub
    echo ""
    
    # 提示用户将公钥添加到远程服务器
    echo -e "${YELLOW}请将上面的公钥添加到远程服务器的 ~/.ssh/authorized_keys 文件中${NC}"
    echo "您可以通过以下命令添加："
    echo "echo '$(cat ~/.ssh/id_rsa.pub)' >> ~/.ssh/authorized_keys"
    read -p "添加完成后按回车继续..."
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
    read -s -p "请输入远程服务器密码: " password
    echo ""  # 换行
    
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
    
    # 安装sshpass
    install_sshpass
    
    # 测试SSH连接
    echo -e "${YELLOW}正在测试SSH连接...${NC}"
    if ! sshpass -p "$password" ssh -p $remote_port -o ConnectTimeout=5 $username@$remote_ip "echo 'SSH连接测试成功'"; then
        echo -e "${RED}SSH连接测试失败，请检查用户名、密码或服务器状态${NC}"
        read -p "按回车键返回主菜单..."
        return
    fi
    
    # 创建SSH隧道
    echo -e "${YELLOW}正在创建SSH隧道...${NC}"
    # 使用screen创建后台会话运行SSH隧道，使用sshpass自动输入密码
    screen -dmS socks_proxy sshpass -p "$password" ssh -v -p $remote_port -D $local_ip:$local_port $username@$remote_ip
    
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
    
    # 清除密码变量
    unset password
    
    # 等待用户确认
    read -p "按回车键返回主菜单..."
}

# 显示系统信息
show_system_info() {
    clear
    echo -e "${GREEN}系统信息：${NC}"
    echo "----------------------------------------"
    echo "操作系统: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"
    echo "内核版本: $(uname -r)"
    echo "主机名: $(hostname)"
    echo "CPU信息: $(lscpu | grep "Model name" | sed -r 's/Model name:\s{1,}//')"
    echo "CPU核心数: $(nproc)"
    echo "内存总量: $(free -h | grep Mem | awk '{print $2}')"
    echo "内存使用: $(free -h | grep Mem | awk '{print $3}')"
    echo "磁盘使用: $(df -h / | tail -1 | awk '{print $5}')"
    echo "系统运行时间: $(uptime -p)"
    echo "----------------------------------------"
    read -p "按回车键返回..."
}

# 配置IPv4地址
configure_ipv4() {
    clear
    echo -e "${GREEN}IPv4地址配置${NC}"
    echo "----------------------------------------"
    
    # 获取网络接口列表
    interfaces=($(ip -o link show | awk -F': ' '{print $2}' | grep -v lo))
    
    echo "可用的网络接口："
    for i in "${!interfaces[@]}"; do
        echo "$((i+1)). ${interfaces[$i]}"
    done
    
    read -p "请选择要配置的网络接口 [1-${#interfaces[@]}]: " choice
    if [[ ! $choice =~ ^[0-9]+$ ]] || [ $choice -lt 1 ] || [ $choice -gt ${#interfaces[@]} ]; then
        echo -e "${RED}无效的选择${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    interface=${interfaces[$((choice-1))]}
    
    # 获取当前IP配置
    current_ip=$(ip addr show $interface | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    current_gateway=$(ip route | grep default | grep $interface | awk '{print $3}')
    
    echo "当前IP地址: $current_ip"
    echo "当前网关: $current_gateway"
    
    read -p "请输入新的IP地址 [格式: x.x.x.x]: " new_ip
    read -p "请输入子网掩码 [格式: 24]: " netmask
    read -p "请输入网关地址 [格式: x.x.x.x]: " gateway
    
    # 根据不同的系统配置IP
    if command -v apt-get &>/dev/null; then
        # Ubuntu/Debian
        cat > /etc/netplan/01-netcfg.yaml << EOF
network:
  version: 2
  ethernets:
    $interface:
      dhcp4: no
      addresses: [$new_ip/$netmask]
      gateway4: $gateway
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
EOF
        netplan apply
    elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        # CentOS/RHEL
        cat > /etc/sysconfig/network-scripts/ifcfg-$interface << EOF
DEVICE=$interface
BOOTPROTO=static
IPADDR=$new_ip
PREFIX=$netmask
GATEWAY=$gateway
DNS1=8.8.8.8
DNS2=8.8.4.4
ONBOOT=yes
EOF
        systemctl restart NetworkManager
    fi
    
    echo -e "${GREEN}IP配置已更新${NC}"
    read -p "按回车键返回..."
}

# 管理防火墙
manage_firewall() {
    clear
    echo -e "${GREEN}防火墙管理${NC}"
    echo "----------------------------------------"
    echo "1. 查看防火墙状态"
    echo "2. 停止防火墙"
    echo "3. 禁用防火墙"
    echo "4. 返回上级菜单"
    read -p "请选择操作 [1-4]: " choice
    
    case $choice in
        1)
            if command -v ufw &>/dev/null; then
                ufw status
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --state
            fi
            ;;
        2)
            if command -v ufw &>/dev/null; then
                ufw disable
            elif command -v firewall-cmd &>/dev/null; then
                systemctl stop firewalld
            fi
            echo -e "${GREEN}防火墙已停止${NC}"
            ;;
        3)
            if command -v ufw &>/dev/null; then
                ufw disable
                systemctl disable ufw
            elif command -v firewall-cmd &>/dev/null; then
                systemctl stop firewalld
                systemctl disable firewalld
            fi
            echo -e "${GREEN}防火墙已禁用${NC}"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
    esac
    read -p "按回车键继续..."
}

# 管理SELinux
manage_selinux() {
    clear
    echo -e "${GREEN}SELinux管理${NC}"
    echo "----------------------------------------"
    
    if ! command -v getenforce &>/dev/null; then
        echo -e "${YELLOW}系统未安装SELinux${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    echo "1. 查看SELinux状态"
    echo "2. 临时关闭SELinux"
    echo "3. 永久关闭SELinux"
    echo "4. 返回上级菜单"
    read -p "请选择操作 [1-4]: " choice
    
    case $choice in
        1)
            echo "当前SELinux状态: $(getenforce)"
            ;;
        2)
            setenforce 0
            echo -e "${GREEN}SELinux已临时关闭${NC}"
            ;;
        3)
            sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
            setenforce 0
            echo -e "${GREEN}SELinux已永久关闭，需要重启系统生效${NC}"
            ;;
        4)
            return
            ;;
        *)
            echo -e "${RED}无效的选择${NC}"
            ;;
    esac
    read -p "按回车键继续..."
}

# 修改本地DNS
configure_dns() {
    clear
    echo -e "${GREEN}修改本地DNS${NC}"
    echo "----------------------------------------"
    
    # 获取当前DNS配置
    echo "当前DNS配置："
    if [ -f /etc/resolv.conf ]; then
        cat /etc/resolv.conf | grep "nameserver"
    fi
    
    echo -e "\n${YELLOW}将设置以下DNS服务器：${NC}"
    echo "1. Cloudflare DNS (1.1.1.1)"
    echo "2. Google DNS (8.8.8.8)"
    
    read -p "是否继续？(y/n): " confirm
    if [[ $confirm != "y" && $confirm != "Y" ]]; then
        echo -e "${YELLOW}已取消操作${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 备份原始DNS配置
    if [ -f /etc/resolv.conf ]; then
        cp /etc/resolv.conf /etc/resolv.conf.bak
    fi
    
    # 根据不同的系统配置DNS
    if command -v apt-get &>/dev/null; then
        # Ubuntu/Debian
        cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
        # 防止resolv.conf被覆盖
        chattr +i /etc/resolv.conf 2>/dev/null
    elif command -v yum &>/dev/null || command -v dnf &>/dev/null; then
        # CentOS/RHEL
        cat > /etc/resolv.conf << EOF
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
        # 防止resolv.conf被覆盖
        chattr +i /etc/resolv.conf 2>/dev/null
    fi
    
    echo -e "${GREEN}DNS配置已更新${NC}"
    echo "新的DNS配置："
    cat /etc/resolv.conf
    
    # 测试DNS解析
    echo -e "\n${YELLOW}正在测试DNS解析...${NC}"
    if ping -c 1 google.com &>/dev/null; then
        echo -e "${GREEN}DNS解析测试成功！${NC}"
    else
        echo -e "${RED}DNS解析测试失败，请检查网络连接${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 在线挂载磁盘
mount_disk() {
    clear
    echo -e "${GREEN}在线挂载磁盘${NC}"
    echo "----------------------------------------"
    
    # 显示当前磁盘信息
    echo -e "${YELLOW}当前磁盘信息：${NC}"
    lsblk
    echo "----------------------------------------"
    
    # 获取磁盘设备
    read -p "请输入要挂载的磁盘设备（例如：/dev/vdb）: " disk_device
    
    # 检查磁盘设备是否存在
    if [ ! -b "$disk_device" ]; then
        echo -e "${RED}错误：磁盘设备 $disk_device 不存在${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 获取挂载点
    read -p "请输入挂载点（例如：/mnt/data）: " mount_point
    
    # 检查挂载点是否存在，不存在则创建
    if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point"
        echo -e "${GREEN}已创建挂载点目录：$mount_point${NC}"
    fi
    
    # 检查磁盘是否已经挂载
    if mount | grep -q "$disk_device"; then
        echo -e "${YELLOW}警告：磁盘 $disk_device 已经挂载${NC}"
        read -p "是否卸载后重新挂载？(y/n): " remount
        if [[ $remount != "y" && $remount != "Y" ]]; then
            echo -e "${YELLOW}已取消操作${NC}"
            read -p "按回车键返回..."
            return
        fi
        umount "$disk_device"
    fi
    
    # 检查磁盘是否已格式化
    if ! blkid "$disk_device" &>/dev/null; then
        echo -e "${YELLOW}磁盘未格式化，是否现在格式化？(y/n): ${NC}"
        read -p "请选择 (y/n): " format_choice
        if [[ $format_choice == "y" || $format_choice == "Y" ]]; then
            echo -e "${YELLOW}正在格式化磁盘...${NC}"
            mkfs.ext4 "$disk_device"
            if [ $? -ne 0 ]; then
                echo -e "${RED}格式化失败${NC}"
                read -p "按回车键返回..."
                return
            fi
            echo -e "${GREEN}格式化完成${NC}"
        else
            echo -e "${YELLOW}已取消操作${NC}"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    # 获取磁盘UUID
    disk_uuid=$(blkid -s UUID -o value "$disk_device")
    
    # 挂载磁盘
    echo -e "${YELLOW}正在挂载磁盘...${NC}"
    mount "$disk_device" "$mount_point"
    if [ $? -ne 0 ]; then
        echo -e "${RED}挂载失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 检查是否已经在fstab中
    if grep -q "$disk_uuid" /etc/fstab; then
        echo -e "${YELLOW}该磁盘已在fstab中配置${NC}"
    else
        # 添加到fstab
        echo "UUID=$disk_uuid $mount_point ext4 defaults 0 0" >> /etc/fstab
        echo -e "${GREEN}已添加到fstab${NC}"
    fi
    
    # 显示挂载结果
    echo -e "\n${GREEN}挂载完成！${NC}"
    echo "磁盘信息："
    df -h "$mount_point"
    
    read -p "按回车键返回..."
}

# 在线扩容磁盘
resize_disk() {
    clear
    echo -e "${GREEN}在线扩容磁盘${NC}"
    echo "----------------------------------------"
    
    # 检查是否安装了lvm2
    if ! command -v pvcreate &>/dev/null; then
        echo -e "${YELLOW}正在安装LVM工具...${NC}"
        if command -v apt-get &>/dev/null; then
            apt-get update
            apt-get install -y lvm2
        elif command -v yum &>/dev/null; then
            yum install -y lvm2
        elif command -v dnf &>/dev/null; then
            dnf install -y lvm2
        else
            echo -e "${RED}无法安装LVM工具，请手动安装lvm2包${NC}"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    # 显示当前磁盘信息
    echo -e "${YELLOW}当前磁盘信息：${NC}"
    lsblk
    echo "----------------------------------------"
    
    # 显示当前LVM信息
    echo -e "${YELLOW}当前LVM信息：${NC}"
    vgs
    echo "----------------------------------------"
    lvs
    echo "----------------------------------------"
    
    # 获取要添加的磁盘设备
    read -p "请输入要添加的磁盘设备（例如：/dev/sdb）: " new_disk
    
    # 检查磁盘设备是否存在
    if [ ! -b "$new_disk" ]; then
        echo -e "${RED}错误：磁盘设备 $new_disk 不存在${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 获取目标逻辑卷
    read -p "请输入目标逻辑卷（例如：/dev/mapper/ubuntu--vg-ubuntu--lv）: " target_lv
    
    # 检查逻辑卷是否存在
    if ! lvs "$target_lv" &>/dev/null; then
        echo -e "${RED}错误：逻辑卷 $target_lv 不存在${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 获取卷组名称
    vg_name=$(lvs --noheadings -o vg_name "$target_lv" | tr -d ' ')
    
    # 检查磁盘是否已经是物理卷
    if ! pvs "$new_disk" &>/dev/null; then
        echo -e "${YELLOW}正在将磁盘 $new_disk 初始化为物理卷...${NC}"
        pvcreate "$new_disk"
        if [ $? -ne 0 ]; then
            echo -e "${RED}创建物理卷失败${NC}"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    # 扩展卷组
    echo -e "${YELLOW}正在将物理卷添加到卷组 $vg_name...${NC}"
    vgextend "$vg_name" "$new_disk"
    if [ $? -ne 0 ]; then
        echo -e "${RED}扩展卷组失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 获取逻辑卷的当前大小
    current_size=$(lvs --noheadings -o lv_size --units g "$target_lv" | tr -d ' ')
    
    # 扩展逻辑卷
    echo -e "${YELLOW}正在扩展逻辑卷...${NC}"
    lvextend -l +100%FREE "$target_lv"
    if [ $? -ne 0 ]; then
        echo -e "${RED}扩展逻辑卷失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 获取文件系统类型
    fs_type=$(blkid -s TYPE -o value "$target_lv")
    
    # 调整文件系统大小
    echo -e "${YELLOW}正在调整文件系统大小...${NC}"
    case $fs_type in
        ext4|ext3|ext2)
            resize2fs "$target_lv"
            ;;
        xfs)
            xfs_growfs "$target_lv"
            ;;
        *)
            echo -e "${RED}不支持的文件系统类型：$fs_type${NC}"
            read -p "按回车键返回..."
            return
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}调整文件系统大小失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 显示扩容结果
    echo -e "\n${GREEN}扩容完成！${NC}"
    echo "扩容后的逻辑卷信息："
    lvs "$target_lv"
    echo -e "\n文件系统信息："
    df -h "$target_lv"
    
    read -p "按回车键返回..."
}

# 系统管理菜单
system_management_menu() {
    while true; do
        clear
        echo -e "${GREEN}系统管理${NC}"
        echo "----------------------------------------"
        echo "1. 查看系统信息"
        echo "2. 配置IPv4地址"
        echo "3. 防火墙管理"
        echo "4. SELinux管理"
        echo "5. 修改本地DNS"
        echo "6. 在线挂载磁盘"
        echo "7. 在线扩容磁盘"
        echo "0. 返回主菜单"
        echo "----------------------------------------"
        read -p "请选择操作 [0-7]: " choice
        
        case $choice in
            1) show_system_info ;;
            2) configure_ipv4 ;;
            3) manage_firewall ;;
            4) manage_selinux ;;
            5) configure_dns ;;
            6) mount_disk ;;
            7) resize_disk ;;
            0) return ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
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
                # 调用系统管理菜单
                system_management_menu
                ;;
            2) 
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
