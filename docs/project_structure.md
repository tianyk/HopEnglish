# 项目结构说明

## 📁 目录结构

```
lib/
├── main.dart                              # 应用入口
│
└── src/                                   # 源代码目录
    ├── config/                            # 配置文件
    │   └── category_config.dart           # 分类配置
    │
    ├── constants/                         # 常量定义
    │   └── app_strings.dart               # 字符串常量
    │
    ├── libs/                              # 工具库
    │   ├── logger.dart                    # 日志工具
    │   └── utils.dart                     # 通用工具函数
    │
    ├── models/                            # 数据模型
    │   ├── category.dart                  # 分类模型
    │   ├── word.dart                      # 单词模型
    │   └── models.dart                    # 模型导出
    │
    ├── pages/                             # 页面（路由入口）
    │   ├── home_page.dart                 # 首页：分类画廊
    │   ├── word_learning_page.dart        # 单词学习页
    │   └── celebration_page.dart          # 完成庆祝页
    │
    ├── services/                          # 服务层
    │   └── category_service.dart          # 分类数据服务
    │
    ├── theme/                             # 主题样式
    │   └── app_theme.dart                 # 应用主题
    │
    └── widgets/                           # 可复用组件
        ├── category_card.dart             # 分类卡片
        └── word_directory_sheet.dart      # 单词目录弹窗
```

## 🏗️ 架构说明

### 1. main.dart - 应用入口
- **职责**：应用初始化、屏幕方向设置、应用启动
- **内容**：只包含 `main()` 函数和 `HopEnglishApp` 根组件
- **原则**：保持简洁，不包含任何业务逻辑

### 2. src/ - 源代码目录
所有业务代码放在 `src/` 目录下，`main.dart` 是唯一在 `lib/` 根目录的文件。

### 3. config/ - 配置模块
存放业务配置数据：
- 分类配置（`category_config.dart`）

**特点**：配置数据，可被任何模块引用

### 4. constants/ - 常量模块
存放全局常量：
- 字符串常量（`app_strings.dart`）
- 数值常量（如时长、尺寸等）
- 枚举定义

**特点**：纯常量，不包含逻辑

### 5. libs/ - 工具库
存放通用工具：
- 日志工具（`logger.dart`）
- 通用函数（`utils.dart`）

**特点**：纯函数/工具类，无业务依赖

### 6. models/ - 数据模型
存放数据模型定义：
- `Category` - 分类模型
- `Word` - 单词模型

**特点**：使用 `Equatable`，支持 JSON 序列化

### 7. pages/ - 页面模块
存放页面级组件（路由入口）：
- `home_page.dart` - 首页分类画廊
- `word_learning_page.dart` - 单词学习页
- `celebration_page.dart` - 完成庆祝页

**命名规范**：文件名以 `_page.dart` 结尾

### 8. services/ - 服务层
存放业务服务：
- `category_service.dart` - 分类数据加载

**特点**：封装数据获取逻辑，支持本地/网络切换

### 9. theme/ - 主题模块
存放 UI 样式定义：
- 颜色系统
- 字体样式
- 间距、圆角、阴影等
- 渐变定义

**特点**：全局样式，遵循设计系统规范

### 10. widgets/ - 可复用组件
存放跨页面复用的 UI 组件：
- `category_card.dart` - 分类卡片
- `word_directory_sheet.dart` - 单词目录弹窗

**命名规范**：组件名称描述其功能

## 📋 文件命名规范

### 1. 文件名
- 使用 **snake_case**（小写 + 下划线）
- 文件名应描述其内容/功能
- 示例：
  - `home_page.dart`（页面）
  - `category_card.dart`（组件）
  - `category_service.dart`（服务）

### 2. 类名
- 使用 **PascalCase**（大驼峰）
- 组件类名应包含组件类型后缀
- 示例：
  - `HomePage`（页面）
  - `CategoryCard`（组件）
  - `CategoryService`（服务）

### 3. 私有组件（页面内组件）
- 如果组件仅在单个页面内使用，直接写在页面文件内作为私有类
- 使用下划线前缀：`_CategoryCard`

### 4. 公共组件（跨页面组件）
- 如果组件在多个页面复用，提取到 `widgets/` 目录
- 使用公开类名：`CategoryCard`

## 🔗 导入规范

### 1. 导入顺序
```dart
// 1. Dart SDK
import 'dart:async';
import 'dart:math';

// 2. Flutter SDK
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. 第三方包（按字母排序）
import 'package:audioplayers/audioplayers.dart';
import 'package:equatable/equatable.dart';

// 4. 项目内部导入（使用 package 路径，按字母排序）
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/pages/home_page.dart';
import 'package:hopenglish/src/theme/app_theme.dart';
```

### 2. 路径规范
- **使用 package 路径**（推荐）：`package:hopenglish/src/...`
- **避免相对路径**：`../../models/...`（容易出错）

**示例：**
```dart
// ✅ 正确
import 'package:hopenglish/src/models/category.dart';
import 'package:hopenglish/src/theme/app_theme.dart';

// ❌ 错误
import '../../models/category.dart';
import '../theme/app_theme.dart';
```

## 🎯 代码组织原则

### 1. 单一职责
- 每个文件只做一件事
- 每个类/组件只有一个变化的理由

### 2. 依赖方向
```
pages/ widgets/ (页面和组件)
    ↓ 可以引用
services/ models/ (服务和模型)
    ↓ 可以引用
config/ constants/ theme/ libs/ (基础模块)
```

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

## 📦 模块间通信

### 1. 导航
使用 Navigator 管理路由：
```dart
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => WordLearningPage(category: category)),
);
```

### 2. 数据传递
通过构造函数传递数据：
```dart
WordLearningPage(category: category, initialIndex: 0)
```

### 3. 回调通信
通过回调函数通信：
```dart
CategoryCard(
  category: category,
  onTap: () => handleTap(category),
)
```

## ✅ 重构检查清单

每次添加新功能时，检查：
- [ ] 文件是否放在 `lib/src/` 的正确子目录下？
- [ ] 文件名是否遵循 snake_case？
- [ ] 类名是否遵循 PascalCase？
- [ ] 导入是否使用 package 路径？
- [ ] 导入是否按正确顺序排列？
- [ ] 组件是否足够小（< 100 行）？
- [ ] 是否遵循单一职责原则？
- [ ] 依赖方向是否正确？

---

*最后更新：2026-01-05*
