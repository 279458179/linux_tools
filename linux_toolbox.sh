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

# 自动拷贝脚本到系统目录
auto_copy_script() {
    # 获取脚本的绝对路径
    SCRIPT_PATH=$(readlink -f "$0")
    
    # 检查是否已经存在于系统目录
    if [ "$SCRIPT_PATH" != "/usr/sbin/cytool" ]; then
        # 如果脚本不在系统目录，则拷贝过去
        if [ -f "$SCRIPT_PATH" ]; then
            echo -e "${YELLOW}正在将脚本拷贝到系统目录...${NC}"
            cp "$SCRIPT_PATH" /usr/sbin/cytool
            chmod +x /usr/sbin/cytool
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}脚本已成功拷贝到 /usr/sbin/cytool${NC}"
                echo -e "${YELLOW}现在您可以使用 'cytool' 命令来运行此脚本${NC}"
                # 重新执行系统目录中的脚本
                exec /usr/sbin/cytool
            else
                echo -e "${RED}拷贝脚本到系统目录失败${NC}"
            fi
        fi
    fi
}

# 配置脚本别名
setup_alias() {
    # 获取脚本的绝对路径
    SCRIPT_PATH=$(readlink -f "$0")
    
    # 确保脚本具有执行权限
    if [ ! -x "$SCRIPT_PATH" ]; then
        echo -e "${YELLOW}正在设置脚本执行权限...${NC}"
        chmod +x "$SCRIPT_PATH"
        if [ $? -ne 0 ]; then
            echo -e "${RED}设置执行权限失败，请手动执行：chmod +x $SCRIPT_PATH${NC}"
            return 1
        fi
        echo -e "${GREEN}已设置脚本执行权限${NC}"
    fi
    
    # 获取用户的shell类型
    USER_SHELL=$(basename "$SHELL")
    
    # 根据不同的shell类型选择配置文件
    case $USER_SHELL in
        "bash")
            SHELL_RC="$HOME/.bashrc"
            ;;
        "zsh")
            SHELL_RC="$HOME/.zshrc"
            ;;
        *)
            echo -e "${YELLOW}未识别的shell类型，将使用.bashrc${NC}"
            SHELL_RC="$HOME/.bashrc"
            ;;
    esac
    
    # 检查别名是否已存在
    if ! grep -q "alias i='$SCRIPT_PATH'" "$SHELL_RC"; then
        # 添加别名配置
        echo -e "\n# Linux工具箱快捷命令" >> "$SHELL_RC"
        echo "alias i='$SCRIPT_PATH'" >> "$SHELL_RC"
        echo -e "${GREEN}已添加快捷命令 'i'${NC}"
        echo -e "${YELLOW}请执行 'source $SHELL_RC' 或重新登录以使配置生效${NC}"
    fi
}

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
    echo "1. 系统管理合集"
    echo "2. 安装Hysteria2客户端"
    echo "3. 安装Ollama"
    echo "4. 一键安装Miniconda虚拟环境"
    echo "5. 集成KejiLION脚本"
    echo "6. 八合一singbox脚本"
    echo "7. YGKKK-warp解锁脚本"
    echo "0. 退出"
    echo ""
    # 提示用户输入选择
    read -p "请输入选项 [0-7]: " choice
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

# 修改SSH端口
change_ssh_port() {
    clear
    echo -e "${GREEN}修改SSH端口${NC}"
    echo "----------------------------------------"
    
    read -p "请输入新的SSH端口号 (1024-65535): " new_port
    
    # 验证端口号
    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1024 ] || [ "$new_port" -gt 65535 ]; then
        echo -e "${RED}无效的端口号，请输入1024-65535之间的数字${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 检测系统版本
    detect_os
    
    echo "正在修改SSH端口..."
    
    # 检查是否为Ubuntu 24.04及以上版本 (Systemd Socket Activation)
    is_socket_activation=false
    if [ "$OS" == "Ubuntu" ]; then
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            # 简单检查 socket 是否激活
            if systemctl is-active --quiet ssh.socket; then
                is_socket_activation=true
            fi
        fi
    fi
    
    if [ "$is_socket_activation" = true ]; then
        echo "检测到 Systemd Socket 激活模式 (Ubuntu 24.04+ 特性)..."
        
        # 创建 override 目录
        mkdir -p /etc/systemd/system/ssh.socket.d
        
        # 创建 override 配置
        cat > /etc/systemd/system/ssh.socket.d/listen.conf <<EOF
[Socket]
ListenStream=
ListenStream=$new_port
EOF
        
        # 停止服务和Socket以确保彻底重载
        echo "正在重载 SSH Socket 配置..."
        systemctl stop ssh.service
        systemctl stop ssh.socket
        systemctl daemon-reload
        systemctl start ssh.socket
        
        echo -e "${GREEN}SSH端口已通过Socket配置修改为 $new_port${NC}"
        
        # 验证端口是否监听
        sleep 2
        if ss -tuln | grep -q ":$new_port "; then
            echo -e "${GREEN}验证成功：端口 $new_port 正在监听中${NC}"
        else
            echo -e "${RED}警告：未检测到端口 $new_port 在监听，可能配置未生效或启动失败${NC}"
            echo "尝试查看状态："
            systemctl status ssh.socket --no-pager
        fi
        
        # 同时修改 sshd_config 以保持一致性
        if [ -f /etc/ssh/sshd_config ]; then
            sed -i "s/^#\?Port .*/Port $new_port/" /etc/ssh/sshd_config
        fi
        
    else
        # 标准 sshd_config 方式
        echo "使用标准 sshd_config 配置模式..."
        
        if [ -f /etc/ssh/sshd_config ]; then
            sed -i "s/^#\?Port .*/Port $new_port/" /etc/ssh/sshd_config
            
            # 重启 SSH 服务
            if systemctl list-unit-files | grep -q sshd.service; then
                systemctl restart sshd
            else
                systemctl restart ssh
            fi
            echo -e "${GREEN}SSH端口已修改为 $new_port${NC}"
        else
            echo -e "${RED}未找到 /etc/ssh/sshd_config 文件${NC}"
        fi
    fi
    
    # 配置防火墙
    echo "正在配置防火墙..."
    if command -v ufw &>/dev/null && ufw status | grep -q "Status: active"; then
        ufw allow $new_port/tcp
        echo -e "${GREEN}已添加UFW防火墙规则放行端口 $new_port${NC}"
    elif command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        firewall-cmd --permanent --add-port=$new_port/tcp
        firewall-cmd --reload
        echo -e "${GREEN}已添加Firewalld防火墙规则放行端口 $new_port${NC}"
    else
        echo -e "${YELLOW}未检测到活动的防火墙或无法自动配置，请手动放行端口 $new_port${NC}"
    fi
    
    echo -e "${YELLOW}重要提示：请务必在断开当前连接前，新开一个终端测试新端口是否可用！${NC}"
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
        echo "8. 配置YUM/APT源"
        echo "9. 安装Docker"
        echo "10. 配置SSH互信"
        echo "11. 部署VSFTPD服务"
        echo "12. 磁盘挂载LVM"
        echo "13. 编译安装Python3.12"
        echo "14. 修改SSH端口"
        echo "0. 返回主菜单"
        echo "----------------------------------------"
        read -p "请选择操作 [0-14]: " choice
        
        case $choice in
            1) show_system_info ;;
            2) configure_ipv4 ;;
            3) manage_firewall ;;
            4) manage_selinux ;;
            5) configure_dns ;;
            6) mount_disk ;;
            7) resize_disk ;;
            8) configure_source ;;
            9) install_docker ;;
            10) configure_ssh_trust ;;
            11) deploy_vsftpd ;;
            12) lvm_partition_and_mount ;;
            13) install_python3_12 ;;
            14) change_ssh_port ;;
            0) return ;;
            *)
                echo -e "${RED}无效的选择${NC}"
                sleep 1
                ;;
        esac
    done
}

# 检测操作系统类型
detect_os() {
    if grep -q "AlmaLinux" /etc/os-release; then
        OS="AlmaLinux"
    elif grep -q "CentOS" /etc/os-release; then
        OS="CentOS"
    elif grep -q "Ubuntu" /etc/os-release; then
        OS="Ubuntu"
    else
        echo "Unsupported OS."
        exit 1
    fi
}

# 配置YUM或APT源
configure_source() {
    clear
    echo -e "${GREEN}配置YUM/APT源${NC}"
    echo "----------------------------------------"
    
    # 检测操作系统类型
    detect_os
    
    echo "正在配置软件源..."
    if [ "$OS" == "CentOS" ]; then
        # CentOS YUM源配置为阿里云镜像源
        echo "正在配置CentOS YUM源..."
        sudo mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
        sudo curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
        sudo yum clean all && sudo yum makecache
        echo -e "${GREEN}CentOS YUM源配置完成${NC}"
        
    elif [ "$OS" == "AlmaLinux" ]; then
        # AlmaLinux 8 YUM源配置为阿里云镜像源
        echo "正在配置AlmaLinux YUM源..."
        sed -e 's|^mirrorlist=|#mirrorlist=|g' \
            -e 's|^# baseurl=https://repo.almalinux.org|baseurl=https://mirrors.aliyun.com|g' \
            -i.bak \
            /etc/yum.repos.d/almalinux*.repo
        dnf makecache
        echo -e "${GREEN}AlmaLinux YUM源配置完成${NC}"
        
    elif [ "$OS" == "Ubuntu" ]; then
        # Ubuntu APT源配置为阿里云镜像源
        echo "正在配置Ubuntu APT源..."
        sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak
        sudo bash -c 'cat > /etc/apt/sources.list <<EOF
deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc) main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ $(lsb_release -sc)-backports main restricted universe multiverse
EOF'
        sudo apt update
        echo -e "${GREEN}Ubuntu APT源配置完成${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 安装Docker
install_docker() {
    clear
    echo -e "${GREEN}安装Docker${NC}"
    echo "----------------------------------------"
    
    # 检测操作系统类型
    detect_os
    
    echo "正在安装Docker..."
    if [ "$OS" == "CentOS" ]; then
        # CentOS 的 Docker 安装步骤
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        echo -e "${GREEN}Docker已安装在CentOS上${NC}"
        
    elif [ "$OS" == "AlmaLinux" ]; then
        # AlmaLinux 的 Docker 安装步骤
        sudo dnf install -y dnf-utils
        sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
        sudo dnf install -y docker-ce docker-ce-cli containerd.io
        echo -e "${GREEN}Docker已安装在AlmaLinux上${NC}"
        
    elif [ "$OS" == "Ubuntu" ]; then
        # Ubuntu 的 Docker 安装步骤
        sudo apt update
        sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io
        echo -e "${GREEN}Docker已安装在Ubuntu上${NC}"
    fi
    
    # 启动并设置 Docker 开机自启
    sudo systemctl enable docker
    sudo systemctl start docker
    
    # 验证安装
    if docker --version &>/dev/null; then
        echo -e "${GREEN}Docker安装成功！${NC}"
        docker --version
    else
        echo -e "${RED}Docker安装失败${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 配置SSH互信
configure_ssh_trust() {
    clear
    echo -e "${GREEN}配置SSH互信${NC}"
    echo "----------------------------------------"
    
    # 检查本地是否已经生成了 SSH 密钥
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "正在生成SSH密钥..."
        ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
    else
        echo "SSH密钥已存在"
    fi
    
    # 提示用户输入目标机器的 IP 地址
    read -p "请输入目标机器的IP地址: " target_ip
    
    # 将 SSH 公钥拷贝到目标机器
    ssh-copy-id -i ~/.ssh/id_rsa.pub "$USER@$target_ip"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSH互信配置成功！${NC}"
    else
        echo -e "${RED}SSH互信配置失败${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 部署VSFTPD服务
deploy_vsftpd() {
    clear
    echo -e "${GREEN}部署VSFTPD服务${NC}"
    echo "----------------------------------------"
    
    # 检测操作系统类型
    detect_os
    
    echo "正在部署vsftpd服务..."
    if [ "$OS" == "CentOS" ] || [ "$OS" == "AlmaLinux" ]; then
        sudo yum install -y vsftpd
    elif [ "$OS" == "Ubuntu" ]; then
        sudo apt update
        sudo apt install -y vsftpd
    fi
    
    # 启动并设置 vsftpd 开机自启
    sudo systemctl start vsftpd
    sudo systemctl enable vsftpd
    
    # 配置 vsftpd
    sudo sed -i 's/anonymous_enable=YES/anonymous_enable=NO/' /etc/vsftpd/vsftpd.conf
    sudo sed -i 's/#local_enable=YES/local_enable=YES/' /etc/vsftpd/vsftpd.conf
    sudo sed -i 's/#write_enable=YES/write_enable=YES/' /etc/vsftpd/vsftpd.conf
    sudo sed -i 's/listen=NO/listen=YES/' /etc/vsftpd/vsftpd.conf
    sudo sed -i 's/listen_ipv6=YES/listen_ipv6=NO/' /etc/vsftpd/vsftpd.conf
    
    # 配置被动模式和指定端口范围
    echo "pasv_enable=YES" | sudo tee -a /etc/vsftpd/vsftpd.conf
    echo "pasv_min_port=30000" | sudo tee -a /etc/vsftpd/vsftpd.conf
    echo "pasv_max_port=31000" | sudo tee -a /etc/vsftpd/vsftpd.conf
    echo "pasv_address=$(ip a |grep "inet " |grep brd |awk '{print $2}' |cut -d / -f 1)" | sudo tee -a /etc/vsftpd/vsftpd.conf
    
    # 配置 vsftpd 使用 22001 端口
    echo "listen_port=22001" | sudo tee -a /etc/vsftpd/vsftpd.conf
    
    # 创建并配置 ftpuser 用户
    if ! id "ftpuser" &>/dev/null; then
        sudo useradd -m -d /home/ftpuser ftpuser
        echo "ftpuser:ftpuser" | sudo chpasswd
        echo "已创建ftpuser用户"
    fi
    
    # 设置用户家目录权限
    sudo chown ftpuser:ftpuser /home/ftpuser
    
    # 配置 vsftpd 允许用户登录
    echo "userlist_enable=YES" | sudo tee -a /etc/vsftpd/vsftpd.conf
    echo "userlist_deny=NO" | sudo tee -a /etc/vsftpd/vsftpd.conf
    echo "ftpuser" | sudo tee -a /etc/vsftpd/user_list
    
    # 重启 vsftpd
    sudo systemctl restart vsftpd
    
    echo -e "${GREEN}VSFTPD服务部署完成！${NC}"
    echo "FTP服务器信息："
    echo "地址: $(hostname -I | awk '{print $1}')"
    echo "端口: 22001"
    echo "用户名: ftpuser"
    echo "密码: ftpuser"
    
    read -p "按回车键返回..."
}

# 磁盘挂载LVM
lvm_partition_and_mount() {
    clear
    echo -e "${GREEN}磁盘挂载LVM${NC}"
    echo "----------------------------------------"
    
    # 提示用户输入磁盘名称和挂载点
    read -p "请输入要分区的磁盘（例如：/dev/sdb）: " disk
    read -p "请输入挂载点目录（例如：/mnt/data）: " mount_point
    
    # 检查磁盘是否存在
    if [ ! -b "$disk" ]; then
        echo -e "${RED}磁盘 $disk 不存在${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 创建物理卷 (PV)
    echo "正在创建物理卷..."
    sudo pvcreate "$disk"
    
    # 创建卷组 (VG)
    echo "正在创建卷组 lvm_vg..."
    sudo vgcreate lvm_vg "$disk"
    
    # 创建逻辑卷 (LV)
    echo "正在创建逻辑卷 lvm_lv..."
    sudo lvcreate -l 100%FREE -n lvm_lv lvm_vg
    
    # 格式化逻辑卷
    echo "正在格式化逻辑卷为ext4..."
    sudo mkfs.ext4 /dev/lvm_vg/lvm_lv
    
    # 创建挂载点目录
    if [ ! -d "$mount_point" ]; then
        sudo mkdir -p "$mount_point"
    fi
    
    # 挂载逻辑卷
    echo "正在挂载逻辑卷..."
    sudo mount /dev/lvm_vg/lvm_lv "$mount_point"
    
    # 添加到 /etc/fstab
    UUID=$(sudo blkid -s UUID -o value /dev/lvm_vg/lvm_lv)
    echo "UUID=$UUID $mount_point ext4 defaults 0 0" | sudo tee -a /etc/fstab
    
    echo -e "${GREEN}磁盘挂载LVM完成！${NC}"
    echo "挂载信息："
    df -h "$mount_point"
    
    read -p "按回车键返回..."
}

# 安装Python3.12
install_python3_12() {
    clear
    echo -e "${GREEN}安装Python 3.12${NC}"
    echo "----------------------------------------"
    
    # 检测操作系统类型
    detect_os
    
    echo "正在安装Python 3.12..."
    if [ "$OS" == "CentOS" ] || [ "$OS" == "AlmaLinux" ]; then
        # 启用 EPEL 和 CRB 源
        sudo yum install -y epel-release
        sudo yum config-manager --set-enabled crb
        
        # 安装依赖包
        sudo yum install -y gcc make wget openssl-devel bzip2-devel libffi-devel zlib-devel
        
        # 下载并编译 Python 3.12
        cd /usr/src
        sudo wget https://www.python.org/ftp/python/3.12.0/Python-3.12.0.tgz
        sudo tar xzf Python-3.12.0.tgz
        cd Python-3.12.0
        sudo ./configure --enable-optimizations
        sudo make altinstall
        
        # 配置 Python 3.12 环境变量
        sudo ln -sf /usr/local/bin/python3.12 /usr/bin/python3
        sudo ln -sf /usr/local/bin/pip3.12 /usr/bin/pip3
        
    elif [ "$OS" == "Ubuntu" ]; then
        # 更新包管理器
        sudo apt update
        
        # 安装依赖
        sudo apt install -y software-properties-common build-essential libssl-dev zlib1g-dev libncurses5-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        
        # 添加 Python 3.12 PPA 源并安装
        sudo add-apt-repository ppa:deadsnakes/ppa
        sudo apt update
        sudo apt install -y python3.12 python3.12-dev python3.12-venv python3.12-distutils
        
        # 配置 Python 3.12 环境变量
        sudo ln -sf /usr/bin/python3.12 /usr/bin/python3
        sudo ln -sf /usr/bin/pip3.12 /usr/bin/pip3
    fi
    
    # 验证安装
    if python3 --version &>/dev/null; then
        echo -e "${GREEN}Python 3.12安装成功！${NC}"
        python3 --version
    else
        echo -e "${RED}Python 3.12安装失败${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 安装Ollama
install_ollama() {
    clear
    echo -e "${GREEN}安装Ollama${NC}"
    echo "----------------------------------------"
    
    # 检查是否安装了Docker
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}正在安装Docker...${NC}"
        # 安装Docker
        curl -fsSL https://get.docker.com | sh
        if [ $? -ne 0 ]; then
            echo -e "${RED}Docker安装失败${NC}"
            read -p "按回车键返回..."
            return
        fi
        # 启动Docker服务
        systemctl start docker
        systemctl enable docker
    fi
    
    # 检查Docker服务状态
    if ! systemctl is-active --quiet docker; then
        echo -e "${YELLOW}正在启动Docker服务...${NC}"
        systemctl start docker
        if [ $? -ne 0 ]; then
            echo -e "${RED}Docker服务启动失败${NC}"
            read -p "按回车键返回..."
            return
        fi
    fi
    
    # 检查端口占用
    if netstat -tuln | grep -q ":11434 "; then
        echo -e "${YELLOW}检测到端口11434已被占用，正在清理...${NC}"
        # 查找占用端口的进程
        pid=$(netstat -tuln | grep ":11434 " | awk '{print $7}' | cut -d'/' -f1)
        if [ ! -z "$pid" ]; then
            echo -e "${YELLOW}正在停止占用端口的进程 (PID: $pid)...${NC}"
            kill -9 $pid
        fi
    fi
    
    # 检查并清理已存在的Ollama容器
    if docker ps -a | grep -q ollama; then
        echo -e "${YELLOW}发现已存在的Ollama容器，正在清理...${NC}"
        docker stop ollama 2>/dev/null
        docker rm ollama 2>/dev/null
        echo -e "${GREEN}已清理旧的Ollama容器${NC}"
    fi
    
    # 创建Ollama数据目录
    mkdir -p /opt/ollama
    
    # 拉取Ollama镜像
    echo -e "${YELLOW}正在拉取Ollama镜像...${NC}"
    docker pull ollama/ollama:latest
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ollama镜像拉取失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 检查NVIDIA GPU支持
    gpu_support=false
    if command -v nvidia-smi &>/dev/null; then
        if nvidia-smi &>/dev/null; then
            gpu_support=true
            echo -e "${GREEN}检测到NVIDIA GPU，将启用GPU支持${NC}"
        fi
    fi
    
    # 运行Ollama容器
    echo -e "${YELLOW}正在启动Ollama服务...${NC}"
    if [ "$gpu_support" = true ]; then
        # 使用GPU支持启动
        docker run -d \
            --name ollama \
            --restart always \
            -v /opt/ollama:/root/.ollama \
            -p 11434:11434 \
            --gpus all \
            ollama/ollama:latest
    else
        # 不使用GPU启动
        echo -e "${YELLOW}未检测到GPU支持，将使用CPU模式运行${NC}"
        docker run -d \
            --name ollama \
            --restart always \
            -v /opt/ollama:/root/.ollama \
            -p 11434:11434 \
            ollama/ollama:latest
    fi
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Ollama服务启动失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 等待服务启动
    echo -e "${YELLOW}等待服务启动...${NC}"
    sleep 10
    
    # 检查服务状态
    if docker ps | grep -q ollama; then
        echo -e "${GREEN}Ollama安装成功！${NC}"
        echo "服务信息："
        docker ps | grep ollama
        echo -e "\n${YELLOW}使用说明：${NC}"
        echo "1. Ollama服务已启动在端口11434"
        echo "2. 可以通过以下命令测试服务："
        echo "   curl http://localhost:11434/api/tags"
        echo "3. 数据存储在 /opt/ollama 目录"
        echo "4. 使用以下命令拉取模型："
        echo "   docker exec -it ollama ollama pull llama2"
        if [ "$gpu_support" = true ]; then
            echo "5. 当前运行模式：GPU加速"
        else
            echo "5. 当前运行模式：CPU模式"
        fi
    else
        echo -e "${RED}Ollama服务启动失败${NC}"
    fi
    
    read -p "按回车键返回..."
}

# 安装Hysteria2客户端
setup_hysteria2_client() {
    clear
    echo -e "${GREEN}安装Hysteria2客户端${NC}"
    echo "----------------------------------------"
    
    # 提示用户输入Hysteria2链接
    read -p "请输入Hysteria2连接链接: " hysteria_link
    
    # 检查链接格式
    if [[ ! $hysteria_link =~ ^hysteria2:// ]]; then
        echo -e "${RED}无效的Hysteria2链接格式${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 使用官方一键脚本安装（自动选用国内源）
    echo -e "${YELLOW}正在使用官方一键脚本安装Hysteria2客户端...${NC}"
    bash <(curl -fsSL https://get.hy2.sh/)
    if [ $? -ne 0 ]; then
        echo -e "${RED}Hysteria2客户端自动安装失败，请检查网络或手动安装${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 查找hysteria2可执行文件路径
    if [ -f /usr/local/bin/hysteria ]; then
        HYSTERIA_BIN="/usr/local/bin/hysteria"
    elif [ -f /usr/bin/hysteria ]; then
        HYSTERIA_BIN="/usr/bin/hysteria"
    else
        echo -e "${RED}未找到hysteria2可执行文件，请检查安装${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    mkdir -p /etc/hysteria2
    
    # 解析链接
    PASSWORD=$(echo $hysteria_link | sed -n 's/.*:\/\/\([^@]*\)@.*/\1/p')
    SERVER=$(echo $hysteria_link | sed -n 's/.*@\([^:]*\):.*/\1/p')
    PORT=$(echo $hysteria_link | sed -n 's/.*:\([0-9]*\).*/\1/p')
    SNI=$(echo $hysteria_link | sed -n 's/.*sni=\([^&]*\).*/\1/p')
    
    # 创建配置文件
    cat > /etc/hysteria2/config.yaml << EOF
server: $SERVER:$PORT
auth: $PASSWORD
tls:
  sni: $SNI
  insecure: false
  alpn: [h3]
socks5:
  listen: 127.0.0.1:1080
http:
  listen: 127.0.0.1:8080
EOF
    
    # 创建systemd服务文件
    cat > /etc/systemd/system/hysteria2.service << EOF
[Unit]
Description=Hysteria2 Client Service
After=network.target

[Service]
Type=simple
ExecStart=$HYSTERIA_BIN -c /etc/hysteria2/config.yaml
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 启动Hysteria2服务
    echo -e "${YELLOW}正在启动Hysteria2服务...${NC}"
    systemctl enable hysteria2
    systemctl restart hysteria2
    
    # 检查服务状态
    if systemctl is-active --quiet hysteria2; then
        echo -e "${GREEN}Hysteria2服务已成功启动${NC}"
        echo -e "\n${YELLOW}代理信息：${NC}"
        echo "SOCKS5代理: 127.0.0.1:1080"
        echo "HTTP代理: 127.0.0.1:8080"
        
        # 将代理设置添加到.bashrc
        echo -e "\n${YELLOW}正在配置代理设置...${NC}"
        echo 'export http_proxy="http://127.0.0.1:8080"' >> ~/.bashrc
        echo 'export https_proxy="http://127.0.0.1:8080"' >> ~/.bashrc
        
        echo -e "${GREEN}代理配置已完成！${NC}"
        echo -e "\n${YELLOW}使用说明：${NC}"
        echo "1. 代理设置已添加到 ~/.bashrc"
        echo "2. 请执行 'source ~/.bashrc' 使配置生效"
        echo "3. 或重新登录系统使配置生效"
    else
        echo -e "${RED}Hysteria2服务启动失败${NC}"
        echo "请检查配置和日志: journalctl -u hysteria2"
    fi
    
    read -p "按回车键返回..."
}

# 一键安装Miniconda虚拟环境
setup_miniconda_env() {
    clear
    echo -e "${GREEN}一键安装Miniconda虚拟环境${NC}"
    echo "----------------------------------------"
    
    # 检查是否已安装conda
    if command -v conda &>/dev/null; then
        echo -e "${YELLOW}已检测到conda，无需重复安装${NC}"
        conda --version
        read -p "按回车键返回..."
        return
    fi
    
    # 检测系统架构
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            MINICONDA=Miniconda3-latest-Linux-x86_64.sh
            ;;
        aarch64)
            MINICONDA=Miniconda3-latest-Linux-aarch64.sh
            ;;
        *)
            echo -e "${RED}不支持的系统架构: $ARCH${NC}"
            read -p "按回车键返回..."
            return
            ;;
    esac
    
    # 下载Miniconda安装脚本
    echo -e "${YELLOW}正在下载Miniconda安装脚本...${NC}"
    wget -O /tmp/$MINICONDA https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/$MINICONDA
    if [ $? -ne 0 ]; then
        echo -e "${RED}Miniconda下载失败，请检查网络${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 安装Miniconda
    echo -e "${YELLOW}正在安装Miniconda...${NC}"
    bash /tmp/$MINICONDA -b -p $HOME/miniconda3
    if [ $? -ne 0 ]; then
        echo -e "${RED}Miniconda安装失败${NC}"
        read -p "按回车键返回..."
        return
    fi
    
    # 初始化conda
    $HOME/miniconda3/bin/conda init bash
    source ~/.bashrc
    
    # 显示conda版本
    conda --version
    echo -e "${GREEN}Miniconda安装完成！${NC}"
    echo -e "${YELLOW}如需新建虚拟环境，可执行: conda create -n myenv python=3.10${NC}"
    read -p "按回车键返回..."
}

# 集成KejiLION脚本功能
run_kejilion_script() {
    clear
    echo -e "${GREEN}正在一键执行KejiLION脚本...${NC}"
    bash <(curl -sL kejilion.sh)
    echo -e "${GREEN}KejiLION脚本执行完毕！${NC}"
    read -p "按回车键返回..."
}

# 安装八合一singbox脚本
install_singbox_script() {
    clear
    echo -e "${GREEN}正在安装八合一singbox脚本...${NC}"
    echo -e "${YELLOW}此脚本由mack-a提供${NC}"
    
    # 下载并执行脚本
    wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
    
    echo -e "${GREEN}脚本执行完毕！${NC}"
    read -p "按回车键返回..."
}

# 集成YGKKK-warp脚本功能
run_ygkkk_warp_script() {
    clear
    echo -e "${GREEN}正在执行YGKKK-warp脚本...${NC}"
    echo -e "${YELLOW}此脚本由yonggekkk提供${NC}"
    
    # 下载并执行脚本
    bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh)
    
    echo -e "${GREEN}YGKKK-warp脚本执行完毕！${NC}"
    read -p "按回车键返回..."
}

# 主函数
main() {
    # 检查root权限
    check_root
    
    # 自动拷贝脚本到系统目录
    auto_copy_script
    
    # 配置别名
    setup_alias
    
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
                # 调用安装Hysteria2客户端功能
                setup_hysteria2_client
                ;;
            3)
                # 调用安装Ollama功能
                install_ollama
                ;;
            4)
                # 一键安装Miniconda虚拟环境
                setup_miniconda_env
                ;;
            5)
                # 集成KejiLION脚本
                run_kejilion_script
                ;;
            6)
                # 安装八合一singbox脚本
                install_singbox_script
                ;;
            7)
                # 集成YGKKK-warp脚本
                run_ygkkk_warp_script
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
