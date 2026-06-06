# Tricky Sync Key BL
一个针对 Tricky Store / TEESimulator 开发的辅助模块，集成自动同步 target.txt 包名、在线拉取替换 Keybox 证书，以及隐藏 Bootloader 状态（可选，但不建议用）。
```text
├── Hide_BootLoader.sh   # 属性修改
├── action.sh            # 
├── customize.sh         # 初始化环境
├── key.sh               # 在线密钥获取
├── module.prop          
├── service.sh           
└── sync.sh              # 包名同步

```
## 部署与运行
### 准备环境
 * 设备已刷入 Tricky Store 或 TEESimulator。
 * 保证基本的网络连接。
### 安装方法
 1. 将当前项目根目录下的所有文件打成一个 .zip 压缩包。
或直接https://github.com/lvdao222/Tricky-Sync-Key-BL/releases 下载
 2. 导入 Magisk / KernelSU / APatch 刷入并重启。
 3. **注意**：开机后需等待一段时间后，进程才会启动。
### 触发密钥更新
在ROOT管理器中，点击本模块下方的 **操作 (Action)** 按钮即可触发自动获取一遍keybox.xml。
## 免责声明
本项目仅供底层安全防护测试和学术交流使用。玩机有风险，若因使用本脚本造成设备卡屏、软砖、数据丢失或触发第三方软件风控封号，请自行承担后果。
