# HopEnglish

**An immersive English learning app for children aged 2-5, using intuitive interactions and direct sound-image connections.**

Start development with [AGENTS.md](AGENTS.md), the [documentation index](docs/README.md), and the [engineering guides](docs/guide/README.md). The [implementation status](docs/product_status.md) distinguishes current behavior from planned features. Engineering guidance is maintained in Chinese.

## Core Philosophy

*   **Intuitive Interaction**: No learning required, just tap and play.
*   **Zero Translation**: Build direct "image = sound" connections without relying on Chinese explanations.
*   **Consistent Causality**: Every tap provides instant, delightful feedback.

## Learning Topics

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

## Tech Stack

*   Flutter / Dart, native Widget state and Navigator
*   SQLite (sqflite), audioplayers, flutter_svg, equatable
*   Read `pubspec.yaml` and `pubspec.lock` for constraints; the current lockfile requires Flutter ≥3.38.4 and Dart ≥3.11
*   The documentation review used Flutter 3.41.4 / Dart 3.11.1; an SDK version is not yet pinned, and the release toolchain has not been validated in this review

## System Requirements

### iOS
*   **Minimum Version**: iOS 15.0
*   **Current app target**: iPhone; iPad support requires explicit configuration and validation
*   **Architecture**: determined by the selected Flutter/Xcode target; simulators can also use arm64

### Development Environment
*   macOS (for iOS development)
*   Xcode compatible with the selected Flutter SDK (26.3 in this review)
*   CocoaPods

## Getting Started and Verification

```bash
flutter --version
flutter pub get
flutter run
```

The current flow is category selection → image/audio study → listening quiz → celebration. Word Library provides free exploration. Let's Play and category rotation remain [planned requirements](docs/homepage_declassification_prd.md).

```bash
python3 tool/check_docs.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub
flutter test --no-pub
node --test scripts/dreamina-word-generator/test/*.test.mjs
```

Choose checks appropriate to the change. See [verification](docs/guide/verification.md) for scope and local proxy issues, and [iOS release](docs/ios_release.md) for build and archive requirements. A combined application verification script and CI are not yet configured.

## Resources

*   Icon Assets: [Flaticon](https://www.flaticon.com/)

## Language Versions

*   [English](README.en.md) | [中文](README.md)

## License

This project is licensed under [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) (Attribution-NonCommercial-ShareAlike 4.0 International).

### You are free to:
- ✅ **Share**: Copy and redistribute the material
- ✅ **Adapt**: Remix, transform, and build upon the material

### You must:
- 📝 **Attribution**: Give appropriate credit, provide a link to the license, and indicate if changes were made
- 🚫 **NonCommercial**: Not use the material for commercial purposes
- 🔄 **ShareAlike**: If you remix, transform, or build upon the material, you must distribute your contributions under the same license as the original

### Full Legal Text
Please see the [LICENSE](LICENSE) file or visit the [Creative Commons website](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode) for the full legal text.
