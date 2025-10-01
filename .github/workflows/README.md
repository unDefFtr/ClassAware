# GitHub Actions 工作流

## Android Release 构建

### 文件: `android-release.yml`

这个工作流用于自动构建电子班牌应用的 Android Release 版本，支持多个平台架构。

### 触发条件

1. **标签推送**: 当推送以 `v` 开头的标签时（如 `v1.0.0`）
2. **手动触发**: 通过 GitHub Actions 页面手动运行

### 构建平台

- **android-arm**: 32位 ARM 架构（适用于较老的 Android 设备）
- **android-arm64**: 64位 ARM 架构（推荐，适用于现代 Android 设备）
- **android-x64**: x86_64 架构（适用于模拟器和 x86 设备）

### 构建产物

每个平台会生成两种格式的安装包：

1. **APK 文件** (`*.apk`): 
   - 直接安装包
   - 适用于侧载安装
   - 文件名格式: `classaware-{platform}-release.apk`

2. **AAB 文件** (`*.aab`):
   - Android App Bundle
   - 适用于 Google Play 商店发布
   - 文件名格式: `classaware-{platform}-release.aab`

### 使用方法

#### 自动发布 Release

1. 创建并推送标签:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. GitHub Actions 会自动:
   - 构建所有平台的 APK 和 AAB
   - 创建 GitHub Release
   - 上传构建产物到 Release

#### 手动构建

1. 访问 GitHub Actions 页面
2. 选择 "Android Release Build" 工作流
3. 点击 "Run workflow"
4. 输入版本号并运行

### 构建环境

- **运行环境**: Ubuntu Latest
- **Java 版本**: 17 (Zulu)
- **Flutter 版本**: 3.24.0 (Stable)
- **构建类型**: Release

### 注意事项

1. 确保 `pubspec.yaml` 中的版本号正确设置
2. 构建前会自动运行测试，测试失败会中止构建
3. 所有构建产物会保留 30 天
4. Release 只在推送标签时创建，手动运行不会创建 Release