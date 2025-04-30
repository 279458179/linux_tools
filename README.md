# Linux万能工具箱

一个功能强大的Linux系统管理工具集合，提供多种系统管理、网络配置和AI服务部署功能。

## 功能特点

### 1. 系统管理合集
- **系统信息查看**
  - 操作系统版本
  - 内核版本
  - CPU信息
  - 内存使用情况
  - 磁盘使用情况
  - 系统运行时间

- **IPv4地址配置**
  - 支持Ubuntu/Debian和CentOS/RHEL系统
  - 自动检测网络接口
  - 支持静态IP配置
  - 自动配置DNS服务器

- **防火墙管理**
  - 支持UFW（Ubuntu/Debian）
  - 支持firewalld（CentOS/RHEL）
  - 查看防火墙状态
  - 停止/禁用防火墙

- **SELinux管理**
  - 查看SELinux状态
  - 临时关闭SELinux
  - 永久关闭SELinux

- **DNS配置**
  - 设置Cloudflare DNS (1.1.1.1)
  - 设置Google DNS (8.8.8.8)
  - 自动备份原始配置
  - DNS解析测试

- **磁盘管理**
  - 在线挂载磁盘
  - 自动格式化
  - 自动配置fstab
  - 支持多种文件系统

- **LVM扩容**
  - 在线扩容磁盘
  - 自动检测GPU支持
  - 支持ext2/3/4和XFS文件系统
  - 自动调整文件系统大小

### 2. SOCKS5代理
- 自动安装和配置Privoxy
- 支持SSH密钥认证
- 自动配置代理转发
- 支持后台运行
- 自动测试代理连接

### 3. Ollama部署
- 自动安装Docker
- 支持GPU加速
- 自动端口管理
- 数据持久化存储
- 支持模型管理

## 系统要求
- Linux操作系统（支持Ubuntu、CentOS、Debian等主流发行版）
- root权限
- 网络连接

## 安装方法
```bash
# 下载脚本
curl -sL https://raw.githubusercontent.com/279458179/linux_tools/master/linux_toolbox.sh -o linux_toolbox.sh

# 添加执行权限
chmod +x linux_toolbox.sh

# 运行脚本
sudo ./linux_toolbox.sh
```

## 使用说明
1. 运行脚本后，会显示主菜单
2. 选择需要的功能模块
3. 按照提示进行操作
4. 每个功能都有详细的操作指引

## 注意事项
- 请确保使用root权限运行脚本
- 部分功能可能需要重启系统才能生效
- 建议在执行重要操作前备份数据
- 某些功能可能需要特定的系统环境支持

## 常见问题
1. **Q: 为什么需要root权限？**
   A: 脚本需要修改系统配置和安装软件包，因此需要root权限。

2. **Q: 支持哪些Linux发行版？**
   A: 支持主流的Linux发行版，包括Ubuntu、CentOS、Debian等。

3. **Q: 如何卸载已安装的服务？**
   A: 可以使用系统自带的包管理器卸载，如apt、yum等。

## 贡献指南
欢迎提交Issue和Pull Request来帮助改进这个工具。

## 许可证
MIT License

## 作者
Your Name

## 更新日志
### v1.0.0
- 初始版本发布
- 添加系统管理功能
- 添加SOCKS5代理功能
- 添加Ollama部署功能

## 🌟 主要特点

- 一键式执行各种系统工具
- 模块化设计，易于扩展
- 支持主流Linux发行版
- 详细的帮助文档
- 持续更新和维护

## 🚀 快速开始

1. 克隆仓库：
```bash
git clone https://github.com/279458179/linux_tools.git
cd linux_tools
```

2. 添加执行权限：
```bash
chmod +x linux_toolbox.sh
./linux_toolbox.sh
```

快速运行工具：
```bash
bash <(curl -sL https://raw.githubusercontent.com/279458179/linux_tools/master/linux_toolbox.sh)
```

## 📋 功能列表

- 系统信息查看
- 网络诊断工具
- 文件管理工具
- 进程管理工具
- 系统优化工具
- 安全检测工具
- 更多功能持续更新中...

## 🤝 贡献指南

欢迎提交Issue和Pull Request来帮助改进这个项目！

## 📝 许可证

MIT License

## 🔍 SEO优化关键词

Linux工具, 系统管理, 命令行工具, 系统优化, 网络诊断, 文件管理, 进程管理, 安全检测, 系统维护, 自动化脚本 