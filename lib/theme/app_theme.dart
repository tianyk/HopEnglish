import 'package:flutter/material.dart';

/// HopEnglish 应用主题配置
///
/// 设计理念：专为 2-5 岁幼儿打造的温暖明亮主题
///
/// 核心原则：
/// - 温暖：以橙黄暖色系为主，营造快乐安全的学习氛围
/// - 明亮：奶油白背景配高饱和度色彩，吸引幼儿注意力
/// - 护眼：避免纯白/纯黑的强对比，减少视觉疲劳
/// - 友好：大圆角、柔和阴影，传递亲切感
/// - 清晰：色彩层次分明，便于幼儿识别交互元素
class AppTheme {
  AppTheme._();

  // ==================== 字体 ====================

  /// 单词展示字体（圆润童趣）
  static const String fontFamilyDisplay = 'Fredoka';

  /// 正文字体（简洁易读）
  static const String fontFamilyBody = 'Nunito';

  // ==================== 主色调 ====================

  /// 主色 - 蜜橘橙
  /// 温暖活力，代表快乐与探索，用于主要按钮和核心交互
  static const Color primary = Color(0xFFFF8A50);
  static const Color primaryLight = Color(0xFFFFBB80);
  static const Color primaryDark = Color(0xFFE86A30);

  /// 辅助色 - 薄荷青
  /// 平静信任，用于次要按钮、信息提示等“非奖励/非警示”的状态
  static const Color secondary = Color(0xFF4ECDC4);
  static const Color secondaryLight = Color(0xFF7EEEE6);

  /// 强调色 - 柠檬黄
  /// 阳光正向，用于星星、成就、粒子特效
  static const Color accent = Color(0xFFFFE066);
  static const Color accentLight = Color(0xFFFFF0A0);

  /// 魔法色 - 魔法紫
  /// 用于"属性叠加"魔术棒，代表神奇变化
  static const Color magic = Color(0xFFB388FF);
  static const Color magicLight = Color(0xFFD4BBFF);

  /// 成功色 - 成长绿
  /// 用于完成标记、鼓励反馈
  static const Color success = Color(0xFF7ED957);

  /// 温和提醒 - 珊瑚红
  /// 用于护眼休息提示，温和不刺激
  static const Color warmAlert = Color(0xFFFF6B6B);

  // ==================== 背景色 ====================

  /// 页面背景 - 奶油白
  /// 柔和护眼的主背景色
  static const Color background = Color(0xFFFFF9F0);

  /// 暖色背景 - 暖杏色
  /// 用于卡片悬浮、分区背景
  static const Color backgroundWarm = Color(0xFFFFECD2);

  /// 卡片/表面色 - 纯白
  static const Color surface = Color(0xFFFFFFFF);

  // ==================== 文字色 ====================

  /// 主要文字 - 深灰（避免纯黑）
  static const Color textPrimary = Color(0xFF4A4A4A);

  /// 次要文字
  static const Color textSecondary = Color(0xFF7A7A7A);

  /// 提示文字
  static const Color textHint = Color(0xFFB0B0B0);

  /// 浅色背景上的反色文字
  static const Color textOnColor = Color(0xFFFFFFFF);

  // ==================== 主题配置 ====================

  /// 应用主题
  static ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.light(
      primary: primary,
      primaryContainer: primaryLight,
      secondary: secondary,
      secondaryContainer: secondaryLight,
      tertiary: magic,
      surface: surface,
      error: warmAlert,
      onPrimary: textOnColor,
      onSecondary: textOnColor,
      onSurface: textPrimary,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardTheme(
      color: surface,
      elevation: 4,
      shadowColor: textHint.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: textOnColor,
        elevation: 4,
        shadowColor: primaryDark.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: textOnColor,
      elevation: 6,
      shape: CircleBorder(),
    ),
    iconTheme: const IconThemeData(
      color: textPrimary,
      size: 28,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: primary,
      linearTrackColor: backgroundWarm,
    ),
  );

  // ==================== 文本样式 ====================

  /// 单词展示 - 超大醒目（大图学习仓）
  /// 使用 Fredoka 字体，圆润童趣
  static const TextStyle wordDisplay = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 64,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: 2,
  );

  /// 短语展示
  /// 使用 Fredoka 字体
  static const TextStyle phraseDisplay = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 40,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// 分类标题（英文单词）
  /// 使用 Fredoka 字体
  static const TextStyle categoryTitle = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// 卡片标题（英文单词）
  /// 使用 Fredoka 字体
  static const TextStyle cardTitle = TextStyle(
    fontFamily: fontFamilyDisplay,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  /// 正文（说明文字）
  /// 使用 Nunito 字体，简洁易读
  static const TextStyle body = TextStyle(
    fontFamily: fontFamilyBody,
    fontSize: 14,
    color: textSecondary,
  );

  // ==================== 渐变 ====================

  /// 页面背景渐变
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, backgroundWarm],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// 主色渐变（按钮）
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 魔法渐变（魔术棒激活）
  static const LinearGradient magicGradient = LinearGradient(
    colors: [magicLight, magic, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// 撒花粒子色
  /// 注：使用功能色组合，分类色可通过 CategoryConfig.allColors 获取
  static const List<Color> celebrationColors = [
    accent,
    primary,
    magic,
    success,
    secondary,
    Color(0xFFFF85A2), // 樱花粉
  ];

  // ==================== 阴影 ====================

  /// 卡片阴影
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: textHint.withValues(alpha: 0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  /// 按钮阴影
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primaryDark.withValues(alpha: 0.25),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];

  // ==================== 尺寸常量 ====================

  /// 圆角
  static const double radiusSmall = 8;
  static const double radiusMedium = 16;
  static const double radiusLarge = 24;
  static const double radiusXLarge = 28;

  /// 间距
  static const double spacingSmall = 8;
  static const double spacingMedium = 16;
  static const double spacingLarge = 24;
  static const double spacingXLarge = 32;

  /// 动画时长
  static const Duration durationFast = Duration(milliseconds: 150);
  static const Duration durationNormal = Duration(milliseconds: 300);
  static const Duration durationSlow = Duration(milliseconds: 500);

  /// 按钮冷却（防连点）
  static const Duration buttonCooldown = Duration(milliseconds: 500);
}
