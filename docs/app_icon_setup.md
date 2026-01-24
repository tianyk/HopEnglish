# 应用图标配置指南

本文档说明如何为 HopEnglish 应用配置和生成 iOS 应用图标。

## 📋 前置要求

- Flutter SDK 已安装
- 准备一张应用图标源图片（推荐 1024x1024 像素）

## 🎯 快速开始

### 1. 准备图标源文件

将应用图标源文件放置在 `assets/images/icon/` 目录下：

```
assets/images/icon/
├── 1024_1024.png          # 推荐：1024x1024 像素
└── 880_880.png            # 可选：其他尺寸（会自动放大）
```

**图标要求：**
- 格式：PNG 或 JPEG
- 推荐尺寸：1024x1024 像素（App Store 必需）
- 最小尺寸：880x880 像素（会自动放大到 1024x1024）
- 设计规范：
  - 无透明背景（iOS 要求）
  - 无圆角（系统会自动添加）
  - 无边框
  - 高对比度，确保小尺寸下清晰可见

### 2. 配置 pubspec.yaml

在 `pubspec.yaml` 文件中添加以下配置：

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  flutter_launcher_icons: ^0.13.1  # 添加此依赖

# 应用图标配置
flutter_launcher_icons:
  android: false                    # 本项目仅支持 iOS
  ios: true                         # 启用 iOS 图标生成
  image_path: "assets/images/icon/1024_1024.png"  # 源图标路径
  remove_alpha_ios: true            # 自动移除透明通道（App Store 要求）
```

### 3. 安装依赖

```bash
flutter pub get
```

### 4. 生成图标

```bash
flutter pub run flutter_launcher_icons
```

执行成功后，所有 iOS 所需的图标尺寸会自动生成到：
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

## 📐 iOS 图标尺寸要求

`flutter_launcher_icons` 会自动生成以下所有尺寸：

### iPhone 图标
- **20x20** (@2x = 40x40, @3x = 60x60) - 通知图标
- **29x29** (@1x = 29x29, @2x = 58x58, @3x = 87x87) - 设置图标
- **40x40** (@2x = 80x80, @3x = 120x120) - 通知图标
- **60x60** (@2x = 120x120, @3x = 180x180) - 主屏幕图标

### iPad 图标
- **20x20** (@1x = 20x20, @2x = 40x40) - 通知图标
- **29x29** (@1x = 29x29, @2x = 58x58) - 设置图标
- **40x40** (@1x = 40x40, @2x = 80x80) - 通知图标
- **76x76** (@1x = 76x76, @2x = 152x152) - 主屏幕图标
- **83.5x83.5** (@2x = 167x167) - iPad Pro 主屏幕图标

### App Store 图标
- **1024x1024** (@1x = 1024x1024) - **必需**，用于 App Store 展示

## 🔧 使用不同尺寸的源图片

### 情况 1：使用 1024x1024 图片（推荐）

直接配置：

```yaml
flutter_launcher_icons:
  android: false
  ios: true
  image_path: "assets/images/icon/1024_1024.png"
  remove_alpha_ios: true
```

### 情况 2：使用小于 1024x1024 的图片（如 880x880）

**方法 A：直接使用（自动放大）**

```yaml
flutter_launcher_icons:
  android: false
  ios: true
  image_path: "assets/images/icon/880_880.png"
  remove_alpha_ios: true
```

`flutter_launcher_icons` 会自动将图片放大到 1024x1024，但可能会有轻微的质量损失。

**方法 B：先手动放大（推荐，质量更好）**

使用 macOS 自带的 `sips` 工具先放大图片：

```bash
# 将 880x880 放大到 1024x1024
sips -z 1024 1024 assets/images/icon/880_880.png --out assets/images/icon/1024_1024.png
```

然后配置使用放大后的图片：

```yaml
flutter_launcher_icons:
  android: false
  ios: true
  image_path: "assets/images/icon/1024_1024.png"
  remove_alpha_ios: true
```

## 🔄 更新图标

如果需要更换应用图标：

1. 替换源图标文件（保持文件名不变）或更新 `image_path` 配置
2. 重新运行生成命令：

```bash
flutter pub run flutter_launcher_icons
```

## ✅ 验证图标

### 方法 1：检查生成的文件

```bash
ls -lh ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

应该看到所有尺寸的图标文件都已更新。

### 方法 2：在 Xcode 中查看

1. 打开 `ios/Runner.xcworkspace`
2. 在项目导航器中找到 `Runner` > `Assets.xcassets` > `AppIcon`
3. 查看所有图标槽位是否已填充

### 方法 3：运行应用

```bash
flutter run
```

在设备或模拟器上查看应用图标是否已更新。

## 📝 配置说明

### flutter_launcher_icons 配置参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `android` | boolean | 是否生成 Android 图标（本项目设为 `false`） |
| `ios` | boolean | 是否生成 iOS 图标 |
| `image_path` | string | 源图标文件路径（相对于项目根目录） |
| `remove_alpha_ios` | boolean | 是否移除 iOS 图标的透明通道（App Store 要求） |

## ⚠️ 常见问题

### Q1: 图标生成失败，提示找不到 AndroidManifest.xml

**原因：** 项目中没有 Android 目录，但配置中启用了 Android 图标生成。

**解决：** 将配置中的 `android: false` 设置为 `false`。

### Q2: 生成的图标有透明背景

**原因：** iOS 应用图标不能有透明通道。

**解决：** 确保配置中 `remove_alpha_ios: true`，工具会自动移除透明通道。

### Q3: 图标在小尺寸下不清晰

**原因：** 源图片尺寸太小或设计细节过多。

**解决：**
- 使用 1024x1024 的源图片
- 简化图标设计，避免细线条和复杂细节
- 使用高对比度颜色

### Q4: 如何查看图标文件大小

```bash
# 查看源图标
ls -lh assets/images/icon/1024_1024.png

# 查看生成的 iOS 图标
ls -lh ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
```

## 📚 参考资源

- [flutter_launcher_icons 包文档](https://pub.dev/packages/flutter_launcher_icons)
- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [Flutter iOS 部署文档](https://docs.flutter.dev/deployment/ios)

## 📌 当前配置

项目当前使用的配置：

```yaml
flutter_launcher_icons:
  android: false
  ios: true
  image_path: "assets/images/icon/1024_1024.png"
  remove_alpha_ios: true
```

源图标文件：`assets/images/icon/1024_1024.png`

## 🛠️ 图片处理工具

### macOS 系统工具（sips）

macOS 系统自带 `sips`（Scriptable Image Processing System）工具，可以用于图片缩放：

```bash
# 查看图片信息
sips -g pixelWidth -g pixelHeight assets/images/icon/880_880.png

# 缩放图片（保持宽高比）
sips -z 1024 1024 assets/images/icon/880_880.png --out assets/images/icon/1024_1024.png

# 缩放图片（指定宽度和高度）
sips -Z 1024 assets/images/icon/880_880.png --out assets/images/icon/1024_1024.png
```

**参数说明：**
- `-z height width`: 设置图片的高度和宽度（像素）
- `-Z size`: 按比例缩放，保持宽高比，最大边为指定尺寸
- `--out`: 指定输出文件路径

### 其他图片处理工具

如果需要在其他平台处理图片，可以使用：

- **ImageMagick**（跨平台）：
  ```bash
  convert assets/images/icon/880_880.png -resize 1024x1024 assets/images/icon/1024_1024.png
  ```

- **在线工具**：
  - [Squoosh](https://squoosh.app/) - Google 的在线图片压缩和调整工具
  - [TinyPNG](https://tinypng.com/) - 在线图片压缩工具

---

**最后更新：** 2026-01-24

