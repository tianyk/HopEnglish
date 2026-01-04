# 图片资源目录说明

## 📁 目录结构

```
assets/images/
├── categories/          # 分类主题图标
│   ├── animals.svg     # 动物世界
│   ├── foods.svg       # 美味食物
│   ├── vehicles.svg    # 交通工具
│   ├── actions.svg     # 动作状态
│   ├── home.svg        # 居家生活
│   ├── instruments.svg # 乐器声音
│   └── nature.svg      # 天气自然
│
└── words/              # 单词插画
    ├── animals/        # 动物类单词
    │   ├── lion.png
    │   ├── lion_angry.png      # 属性叠加状态
    │   ├── dog.png
    │   ├── dog_running.png
    │   └── ...
    ├── foods/          # 食物类单词
    │   ├── apple.png
    │   ├── apple_big.png       # 属性叠加状态
    │   └── ...
    ├── vehicles/       # 交通工具类单词
    ├── actions/        # 动作类单词
    ├── home/           # 居家生活类单词
    ├── instruments/    # 乐器类单词
    └── nature/         # 天气自然类单词
```

## 🎨 图片规范

### 1. 分类图标 (categories/)
- **格式**：SVG（推荐）或 PNG
- **尺寸**：200x200 px（SVG 可任意缩放）
- **风格**：温暖、明亮、圆润
- **背景**：透明
- **命名**：小写英文 + 下划线，如 `animals.svg`

### 2. 单词插画 (words/)
- **格式**：PNG（透明背景）
- **尺寸**：
  - @2x: 800x800 px
  - @3x: 1200x1200 px
- **风格要求**：
  - 高饱和度色彩
  - 清晰易识别
  - 无背景（透明 PNG）
  - 适合 2-5 岁幼儿认知
- **命名规范**：
  - 基础单词：`lion.png`
  - 属性叠加：`lion_angry.png`（下划线连接）

## 📝 命名规范

### 基础单词
```
apple.png          # 苹果
dog.png            # 狗
car.png            # 汽车
```

### 属性叠加（短语状态）
```
apple_big.png      # 大苹果
apple_red.png      # 红苹果
lion_angry.png     # 生气的狮子
dog_running.png    # 跑步的狗
car_fast.png       # 快速的车
door_open.png      # 打开的门
light_on.png       # 亮着的灯
```

## 🔍 资源获取推荐

### 免费插画库
1. **Storyset** (https://storyset.com/)
   - 可编辑颜色的 SVG
   - 风格统一、质量高
   
2. **OpenMoji** (https://openmoji.org/)
   - 开源 emoji 风格
   - 可下载 SVG/PNG
   
3. **Blush** (https://blush.design/)
   - 多种插画风格
   - 可自定义组合

### 图片处理工具
- **压缩**：TinyPNG (https://tinypng.com/)
- **编辑**：Figma / Canva
- **格式转换**：CloudConvert

## ⚙️ 使用方式

### 在 pubspec.yaml 中声明
```yaml
flutter:
  assets:
    - assets/images/categories/
    - assets/images/words/animals/
    - assets/images/words/foods/
    - assets/images/words/vehicles/
    - assets/images/words/actions/
    - assets/images/words/home/
    - assets/images/words/instruments/
    - assets/images/words/nature/
```

### 在代码中引用
```dart
// 分类图标
Image.asset('assets/images/categories/animals.svg')

// 单词图片
Image.asset('assets/images/words/animals/lion.png')

// 属性叠加状态
Image.asset('assets/images/words/animals/lion_angry.png')
```

## 📋 待办事项

- [ ] 准备 7 个分类图标
- [ ] 准备动物类 5 个核心词 + 属性叠加
- [ ] 准备食物类 5 个核心词 + 属性叠加
- [ ] 准备交通工具类 5 个核心词 + 属性叠加
- [ ] 优化图片压缩
- [ ] 添加 @3x 高清版本

## 🎯 优先级

**MVP 阶段（第一批）：**
1. 动物世界：Lion, Dog, Cat, Bird, Fish + 各自属性叠加
2. 美味食物：Apple, Banana, Milk, Cookie, Water + 各自属性叠加

**后续扩展：**
3. 交通工具、动作状态、居家生活等

