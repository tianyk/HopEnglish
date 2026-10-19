# iOS 构建、Archive 与发布验证

适用范围：当前 iOS 工程、插件、依赖和发布任务。商店材料见 [上架清单](app_store_submission_checklist.md)，本页不代表任何产物已完成发布验证。

## 1. 环境和输入核对

- SDK 同时满足 `pubspec.yaml` 与 `pubspec.lock`；本次文档核对环境为 Flutter 3.41.4、Dart 3.11.1、Xcode 26.3，尚未固定为仓库工具链。
- 当前锁文件最低要求 Flutter 3.38.4、Dart 3.11；不能按旧 README 的 3.27.4 直接安装并重解析依赖。
- 应用版本从 `pubspec.yaml` 读取，原生 Info.plist 使用 Flutter 构建变量；不要在多个文档手填永久“已完成版本”。
- iOS 最低版本核对 Podfile、工程和 AppFrameworkInfo；当前为 15.0。Runner 目标当前按 iPhone 配置，iPad 不能由项目级 device family 或截图目录存在推定。
- 使用 `ios/Runner.xcworkspace`；依赖按 `pubspec.lock`、`ios/Podfile.lock` 安装，不为了出包随意 `pod update`。

## 2. 本地验证顺序

1. 核对 Git 差异、实际 SDK/Xcode、依赖锁文件和生成配置；记录本次产物对应的源代码状态。
2. 运行 [验证指南](guide/verification.md) 中受影响的检查；既有 analyzer 问题需如实处理或记录，不能写为通过。
3. 按任务需要构建模拟器或真机 Release；只需编译证据时可以 `flutter build ios --release --no-codesign`，但它不验证签名与上传。
4. 在设备或 TestFlight 验证开课、正常/慢速、快速连点、答错/重试、最后一题、More、Home 和前后台切换。
5. 用 Xcode Archive 或已配置签名的 `flutter build ipa --release` 生成归档；核对目标平台、framework、dSYM 与版本，再按已有授权执行上传/提交。

构建命令会产生生成文件和本地构建产物，执行前确认没有与其他正在进行的构建争用目录。自动化或签名不可用时，继续可执行验证并列出未验证范围。

## 3. 当前 native assets 处理

Xcode Build Phase 当前引用：

- `ios/Flutter/prepare_native_assets.sh`：只在 `ACTION=install` 且 `PLATFORM_NAME=iphoneos` 时检查 `build/native_assets/ios/objective_c.framework`；发现 IOSSIMULATOR 平台才清理该生成目录。
- `ios/Flutter/verify_archive_native_assets.sh`：同一 Archive 条件下，检查已嵌入的 objective_c framework 平台为 IOS，调用 dsymutil 并核对 UUID。

脚本和 pbxproj 在首次核对时已有未提交改动；本轮没有执行 Archive 来验证它们。脚本在 framework 不存在时直接退出，退出成功不证明该 framework 已嵌入；需要结合当前依赖和实际归档内容判断是否应有该资产。

回归重点包括“先运行模拟器，再做真机 Archive”，因为同为 arm64 不代表目标平台相同。不能只用 `lipo` 架构名称证明平台正确。

## 4. 交付与故障定位

| 证据 | 能得出的结论 | 不能外推 |
|---|---|---|
| Flutter analyze/test | 静态与已覆盖业务行为 | 插件真机正确、Archive 可用 |
| 无签名 Release | 对应目标编译/部分打包完成 | 签名、dSYM、上传成功 |
| Archive 内容检查 | 该归档中的平台、版本与适用符号对应 | 已通过 TestFlight/App Store 审核 |
| 设备/测试渠道 | 已实际操作的场景结果 | 所有设备、所有系统中断时序 |

记录版本/构建号、源代码版本与相关工作区差异、环境、产物位置、实际场景和未跑项。不要将 API Key、证书内容或个人学习库写进报告。

出现 native assets 问题时先回查脚本条件、Build Phase 顺序、实际二进制平台和符号 UUID，再决定是否清理特定生成产物；不把 `flutter clean` 或重生成整个 ios 工程作为无条件第一步。
