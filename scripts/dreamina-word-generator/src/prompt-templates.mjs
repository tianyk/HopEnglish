const GLOBAL_STYLE = `
为一款面向2至5岁幼儿的英语学习 App 制作一张单词认知插画。
统一采用柔和扁平 2.5D 儿童绘本贴纸插画风格，圆润几何造型，清爽、明亮、友好，中高明度和中等偏高饱和度。
仅使用轻微同色系渐变和柔和高光，必要的内部结构细节可以使用暖深灰色细线。
主体外缘添加一圈细而均匀的纯白色贴纸边，宽度约为主体尺寸的3%，边缘圆润平滑；不要粗白边、彩色描边、双层轮廓或外发光。
单一学习主体居中，完整不裁切，主体连同白色贴纸边占正方形画布约60%，四周保留充足且均匀的安全边距，在40像素缩略图下仍能清晰辨认。
主体必须使用该对象最典型、最容易认知的真实固有色。不同单词应有明显不同的主色，颜色可以是蓝、绿、红、黄、棕、灰、白、紫等。
App 的暖橙主题色只属于界面，不属于插画配色；禁止把所有主体统一画成橙色、金黄色或狮子配色。
不要文字、字母、数字、Logo、画布边框、粗白色外轮廓、彩色外轮廓、双层轮廓、装饰图案、复杂背景、无关道具、第二主体、照片效果、写实材质、黏土、水彩、动漫、颗粒噪点、地面、投影或强烈阴影。
`.trim();

export const TEMPLATE_BY_CATEGORY = Object.freeze({
  animals: 'animal',
  foods: 'object',
  vehicles: 'vehicle',
  body: 'person',
  clothes: 'object',
  home: 'object',
  actions: 'person',
  colors: 'symbol',
  nature: 'scene',
  places: 'scene',
  jobs: 'person',
  music: 'object',
});

const TYPE_TEMPLATES = Object.freeze({
  animal: `
展示一只完整动物，全身，正面略微四分之三视角，姿态自然。
头部稍大、身体圆润、表情友好；保留真实物种最关键的识别特征，不穿衣服、不拿道具、不过度拟人。
四肢数量、尾巴、耳朵和身体结构必须正确。
`.trim(),
  object: `
展示一个完整的单体物品，正面略微四分之三视角，悬浮式独立展示。
不放在桌面、房间或复杂容器中；保持真实认知颜色，简化次要结构，但保留关键识别特征。
`.trim(),
  vehicle: `
展示一辆完整交通工具，统一朝向画面右侧，使用侧前方四分之三视角。
轮子、车窗和主要用途结构清晰，不添加驾驶员、乘客、道路、建筑或风景。
`.trim(),
  person: `
使用统一的幼儿绘本人物设计：头部略大、四肢圆润、五官简单友好、手脚结构自然。
动作词使用完整全身姿势；情绪和身体部位允许使用清晰的局部特写；职业词通过制服和最多一个标志性工具表达。
只保留解释单词所必需的人物或道具，不添加场景。
`.trim(),
  scene: `
使用极简绘本场景切片表达概念，最多三个大型视觉元素，形成完整、柔和、清楚的图标轮廓。
主体概念必须明显强于装饰元素，不添加人物、复杂远景、密集植被或无关建筑。
`.trim(),
  symbol: `
使用严格、干净、居中的儿童认知符号构图。
颜色必须准确、均匀，几何轮廓规整，不能添加脸、手脚、纹理、文字、多个符号或装饰。
`.trim(),
  color: `
使用单一、完整、连续的圆润颜料泼墨色块表达颜色，轮廓有四至六个自然且不对称的圆润凸起。
所有凸起必须连成一个整体，不出现脱离主体的小液滴；整体不能是圆形、椭圆形、规则几何图形、物品或角色。
目标颜色占据主体的绝大部分，色彩准确、清楚，允许非常轻微的同色系明暗变化，但不能混入其他颜色。
`.trim(),
});

const PINKISH_IDS = new Set([
  'red',
  'purple',
  'pink',
  'heart',
  'strawberry',
  'watermelon',
  'cherry',
  'apple',
  'tomato',
  'fire_truck',
  'firefighter',
  'rose',
]);

export function chooseChromaKey(task) {
  return PINKISH_IDS.has(task.wordId) ? '#00FF00' : '#FF00FF';
}

export function buildPrompt(task, override = {}) {
  const templateType = override.templateType ?? TEMPLATE_BY_CATEGORY[task.categoryId];
  if (!TYPE_TEMPLATES[templateType]) {
    throw new Error(`没有找到 ${task.jobKey} 的构图模板：${templateType}`);
  }
  const chromaKey = override.chromaKey ?? chooseChromaKey(task);
  const subject = override.subject ??
    `主体表达英文单词 “${task.name}”（中文含义：${task.nameZh || task.name}），必须一眼能理解这个具体含义。`;
  const mustHave = listBlock('必须包含', override.mustHave);
  const forbid = listBlock('特别禁止', override.forbid);
  const meaning = override.meaning ?? task.nameZh ?? task.name;
  const semanticScope =
    `语义限定：这是 ${task.categoryName} 分类中的 ${task.name}，只表现“${meaning}”这一含义，不表现同名的其他含义。`;
  const background = `
背景必须是完全均匀的纯色 ${chromaKey}，画布四角到主体边缘都保持同一纯色。
背景不得有渐变、纹理、噪点、光晕、地面或阴影；主体内部避免使用 ${chromaKey}。
纯色背景仅用于后续抠图，不得影响主体固有颜色。
`.trim();

  return [
    GLOBAL_STYLE,
    TYPE_TEMPLATES[templateType],
    semanticScope,
    subject,
    mustHave,
    forbid,
    background,
  ].filter(Boolean).join('\n\n');
}

function listBlock(label, values) {
  if (!Array.isArray(values) || values.length === 0) return '';
  return `${label}：${values.join('；')}。`;
}
