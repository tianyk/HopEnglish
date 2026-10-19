# HopEnglish

**一款面向 2-5 岁幼儿的沉浸式“因果反馈”英语启蒙工具。**

开发从 [AGENTS.md](AGENTS.md) → [文档索引](docs/README.md) → [开发指南](docs/guide/README.md) 开始。当前功能与待实施需求见 [实施状态](docs/product_status.md)，工程优化进度见 [优化规划](docs/engineering_optimization_plan.md)。

## 核心理念

*   **直觉交互**：无需学习，点一点就会玩。
*   **零翻译**：建立“图像=声音”的直接联系，不依赖中文解释。
*   **因果一致**：每一次点击都有即时、愉悦的反馈。

## 学习主题

*   🦁 Animals
*   🍎 Food & Drink
*   🙂 My Body
*   🏃 Actions
*   🚗 Vehicles
*   🏠 Home & Family
*   🎨 Colors & Shapes
*   👕 Clothes
*   😊 Feelings
*   🌤️ Nature & Weather
*   🏫 Places & People
*   🎵 Music & Play

## 技术栈

*   Flutter / Dart，原生 Widget 状态与 Navigator
*   SQLite（sqflite）、audioplayers、flutter_svg、equatable
*   SDK 与依赖约束以 `pubspec.yaml`、`pubspec.lock` 为准；当前锁文件要求 Flutter ≥3.38.4、Dart ≥3.11
*   本次文档核对使用 Flutter 3.41.4 / Dart 3.11.1；仓库尚未固定 SDK，不能把该环境描述为已验证的发布工具链

## 系统要求

### iOS
*   **最低版本**: iOS 15.0
*   **当前工程目标**: iPhone；iPad 支持尚需明确配置并验证
*   **架构**: 以当前 Flutter/Xcode 对目标设备的构建结果为准，模拟器也可能使用 arm64

### 开发环境
*   macOS（用于 iOS 开发）
*   与所用 Flutter 兼容的 Xcode（本次核对环境为 26.3）
*   CocoaPods

## 快速上手与检查

```bash
flutter --version
flutter pub get
flutter run
```

应用主体使用随包词表、图片和音频，学习进度留在本地。当前流程是分类开课 → 图音学习 → 听音选图 → 庆祝；自由点读在 Word Library。首页 Let's Play 与分类轮换仍是 [专项需求](docs/homepage_declassification_prd.md)，尚未实施。

```bash
python3 tool/check_docs.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
node --test scripts/dreamina-word-generator/test/*.test.mjs
```

按变更范围选择检查，详细证据边界和本地代理排查见 [验证指南](docs/guide/verification.md)。iOS 出包见 [发布指南](docs/ios_release.md)。目前尚未配置应用统一验证脚本与 CI。

## 资源

*   图标素材：[Flaticon](https://www.flaticon.com/)

## 语言版本

*   [English](README.en.md) | [中文](README.md)

## 许可证

本项目采用 [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/)（署名-非商业性使用-相同方式共享 4.0 国际）许可证。

### 您可以：
- ✅ **分享**：复制和重新分发本材料
- ✅ **修改**：重新混合、转换和基于本材料创作

### 您必须：
- 📝 **署名**：提供适当的署名，提供指向许可证的链接，并指出是否进行了更改
- 🚫 **非商业性使用**：不得将本材料用于商业目的
- 🔄 **相同方式共享**：如果您重新混合、转换或基于本材料创作，您必须根据与原始材料相同的许可证分发您的贡献

### 完整法律文本
请查看 [LICENSE](LICENSE) 文件或访问 [Creative Commons 网站](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) 获取完整的法律文本。
