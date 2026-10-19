# 图片资源入口

当前图片为透明 PNG，词表入口 `assets/data/categories.json`。字段与路径约定统一见 [内容 Schema](../../docs/data_schema.md)，生产和验收见 [内容资源指南](../../docs/guide/content-assets.md)，视觉语义见 [设计系统](../../docs/design_system.md)。

```text
assets/images/
  categories/animals.png      分类图标：{category}.png
  words/animals_dog.png       单词图：{category}_{word}.png
  icons/solid-slow.svg        功能图标
  icon/1024_1024.png          应用图标源
```

配图工具当前输出 512×512，原图、候选和状态在工具 `.state/`，不随应用打包。图片/emoji 优先与错误回退能力见 [组件指南](../../docs/guide/components.md)。

更新时核对透明边缘、主体含义、幼儿辨识度与目标页面布局；图片存在不等于语义正确。历史的分类子目录、属性叠加素材和 7 分类待办不作为当前路径/功能要求。
