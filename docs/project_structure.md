# 项目结构说明

## 📁 目录结构

```
lib/
├── main.dart                          # 应用入口，只负责初始化和启动
│
├── config/                            # 配置文件
│   └── category_config.dart           # 分类配置
│
├── constants/                         # 常量定义
│   └── app_strings.dart               # 字符串常量
│
├── theme/                             # 主题样式
│   └── app_theme.dart                 # 应用主题
│
├── pages/                             # 页面（路由入口）
│   └── home_page.dart                 # 首页：分类画廊
│
└── widgets/                           # 可复用组件
    └── category_card.dart             # 分类卡片组件
```

## 🏗️ 架构说明

### 1. main.dart - 应用入口
- **职责**：应用初始化、屏幕方向设置、应用启动
- **内容**：只包含 `main()` 函数和 `HopEnglishApp` 根组件
- **原则**：保持简洁，不包含任何业务逻辑

### 2. config/ - 配置模块
存放业务配置数据：
- 分类配置（`category_config.dart`）
- 单词配置（后续添加）
- 音频资源配置（后续添加）

**特点**：配置数据，可被任何模块引用

### 3. constants/ - 常量模块
存放全局常量：
- 字符串常量（`app_strings.dart`）
- 数值常量（如时长、尺寸等）
- 枚举定义

**特点**：纯常量，不包含逻辑

### 4. theme/ - 主题模块
存放 UI 样式定义：
- 颜色系统
- 字体样式
- 间距、圆角、阴影等
- 渐变定义

**特点**：全局样式，遵循设计系统规范

### 5. pages/ - 页面模块
存放页面级组件（路由入口）：
- 每个页面一个文件
- 页面名称以 `_page.dart` 结尾
- 示例：`home_page.dart`、`gallery_page.dart`、`learning_page.dart`

### 6. widgets/ - 可复用组件
存放跨页面复用的 UI 组件：
- 小型、独立、可复用的组件
- 组件名称描述其功能
- 示例：`category_card.dart`、`word_card.dart`、`magic_wand_button.dart`

### 7. 后续扩展目录（按需创建）
```
lib/
├── models/          # 数据模型
├── controllers/     # 业务逻辑控制器（Riverpod）
├── services/        # 服务层（API 调用、音频播放等）
├── repositories/    # 数据仓库（数据持久化）
└── utils/           # 工具函数
```

## 📋 文件命名规范

### 1. 文件名
- 使用 **snake_case**（小写 + 下划线）
- 文件名应描述其内容/功能
- 示例：
  - `home_page.dart`（页面）
  - `category_card.dart`（组件）
  - `word_controller.dart`（控制器）

### 2. 类名
- 使用 **PascalCase**（大驼峰）
- 组件类名应包含组件类型后缀
- 示例：
  - `HomePage`（页面）
  - `CategoryCard`（组件）
  - `WordController`（控制器）

### 3. 私有组件（页面内组件）
- 如果组件仅在单个页面内使用，直接写在页面文件内作为私有类
- 使用下划线前缀：`_CategoryCard`
- 示例：`home_page.dart` 中的 `_CategoryCard`

### 4. 公共组件（跨页面组件）
- 如果组件在多个页面复用，提取到 `widgets/` 目录
- 使用公开类名：`CategoryCard`
- 示例：`widgets/category_card.dart` 中的 `CategoryCard`

## 🔗 导入规范

### 1. 导入顺序
```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. 第三方包（按字母排序）
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. 项目内部导入（使用 package 路径，按字母排序）
import 'package:hopenglish/config/category_config.dart';
import 'package:hopenglish/constants/app_strings.dart';
import 'package:hopenglish/pages/home_page.dart';
import 'package:hopenglish/theme/app_theme.dart';
import 'package:hopenglish/widgets/category_card.dart';
```

### 2. 路径规范
- **使用 package 路径**（推荐）：`package:hopenglish/...`
- **避免相对路径**：`../../core/...`（容易出错）

**示例：**
```dart
// ✅ 正确
import 'package:hopenglish/config/category_config.dart';
import 'package:hopenglish/constants/app_strings.dart';
import 'package:hopenglish/pages/home_page.dart';
import 'package:hopenglish/theme/app_theme.dart';
import 'package:hopenglish/widgets/category_card.dart';

// ❌ 错误
import '../../config/category_config.dart';
import '../pages/home_page.dart';
```

## 🎯 代码组织原则

### 1. 单一职责
- 每个文件只做一件事
- 每个类/组件只有一个变化的理由

### 2. 依赖方向
```
pages/ widgets/ (页面和组件)
    ↓ 可以引用
config/ constants/ theme/ (基础模块)
```
- ✅ pages/widgets 可以引用 config/constants/theme
- ❌ config/constants/theme 不能引用 pages/widgets
- ✅ widgets 可以被 pages 引用

### 3. 组件拆分原则
**何时提取为独立文件？**
- 组件代码超过 50-100 行
- 组件在多个页面被复用
- 组件有独立的业务逻辑
- 便于单独测试

**何时保持在页面内？**
- 组件仅在单个页面使用
- 组件代码少于 50 行
- 组件与页面逻辑紧密耦合

## 📦 模块间通信（未来扩展）

### 1. 导航
使用 AutoRoute 管理路由：
```dart
context.router.push(GalleryRoute(categoryId: 'animals'));
```

### 2. 状态管理
使用 Riverpod 管理跨页面状态：
```dart
final wordProvider = StateNotifierProvider<WordController, WordState>(...);
```

### 3. 事件通信
通过 Controller 层处理事件：
```dart
ref.read(wordControllerProvider.notifier).playSound(word);
```

## ✅ 重构检查清单

每次添加新功能时，检查：
- [ ] 文件是否放在正确的目录下？
- [ ] 文件名是否遵循 snake_case？
- [ ] 类名是否遵循 PascalCase？
- [ ] 导入是否使用 package 路径？
- [ ] 导入是否按正确顺序排列？
- [ ] 组件是否足够小（< 100 行）？
- [ ] 是否遵循单一职责原则？
- [ ] 依赖方向是否正确？

---

*最后更新：2026-01-04*

