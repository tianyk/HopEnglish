# 学习进度数据（vNext）——本地存储与计数口径（SQLite + sqflite）

> 本文档定义 HopEnglish vNext “学习数据记录与自适应排序”的技术实现规格，用于落地 `viewCount/playCount/lastSeenAt` 等数据，并为后续算法迭代提供稳定的数据层接口。

---

## 一、设计目标

| 目标 | 说明 |
|------|------|
| **口径稳定** | 数据含义与触发条件明确，避免“技术事件”污染学习数据 |
| **可持续迭代** | 未来会频繁调整排序算法，存储层必须可迁移、可查询、可维护 |
| **不改变孩子交互** | 仅做系统内部记录与调度，不对孩子展示统计数据 |
| **会话内固定** | 进入主题生成本次会话顺序，会话内不改变，保证规则感 |

---

## 二、核心概念与标识

### 2.1 学习项（Learning Item）

在本产品里，“学习”的最小单位是 **图像/emoji + 声音** 的组合，而不是单词拼写本身。因此同形同音但不同意义（如 `Orange` 橘子/橘色）应被视作不同学习项，按不同记录统计。

### 2.2 稳定 ID 与主键

内容数据来源：`assets/data/categories.json`

- **categoryId**：`Category.id`
- **wordId**：`Word.id`（在同一 `Category` 内必须唯一；允许跨分类重复）
- **wordKey（推荐主键）**：`$categoryId:$wordId`（例如：`foods:orange`、`colors:orange`）

> 注意：如果未来出现“同一分类内两个不同意义的 Orange”，必须使用不同的 `wordId`（如 `orange_fruit` / `orange_color`）。

---

## 三、计数口径（系统内部记录）

### 3.1 看到次数（viewCount）

**定义：** 某学习项成为“当前展示词”的次数。

**触发时机：**
- 进入主题学习页后展示第一个词
- 点击 Next 切换到新词
- 从目录跳转到某词

**防误触建议：**
- 若展示停留时间过短（建议阈值 300–500ms），可不计入，避免连点 Next 造成虚高。

### 3.2 听到次数（playCount）

**定义：** 某学习项的音频被触发播放的次数。

**触发时机：**
- 进入主题后自动播放
- 点击卡片触发重播
- 切换到新词后的自动播放

**防连点噪声建议：**
- 同一个 `wordKey` 在很短时间内重复触发（建议 800–1200ms），合并计 1 次。

### 3.3 时间字段

| 字段 | 含义 | 更新时机 |
|------|------|----------|
| `lastSeenAt` | 最近一次“看到”时间（epoch ms） | `viewCount` +1 时更新 |
| `lastPlayedAt` | 最近一次“听到”时间（epoch ms） | `playCount` +1 时更新（可选） |

---

## 四、会话（session）与时间分档

### 4.1 会话定义

| 规则 | 定义 |
|------|------|
| 会话范围 | 从进入某主题学习页开始，到离开该页结束 |
| 中断恢复 | 切后台/锁屏后 **≤2 分钟** 返回仍算同一会话；超过阈值视为新会话 |

### 4.2 时间分档（主题维度）

进入某主题时，用该主题的上次学习时间判定策略模式：

| 距离上次学习该主题间隔 | 模式 |
|------------------------|------|
| < 2 天 | 日常巩固 |
| 2–7 天 | 复习加强 |
| ≥ 7 天 | 久别重启（先熟后新） |

> 这些模式只影响“进入主题时生成顺序”，不会在会话内动态改变顺序。

---

## 五、存储方案：SQLite + sqflite

### 5.1 为什么选 SQLite + sqflite

- **稳定性强**：SQLite 长期验证；数据可迁移、可调试。
- **查询友好**：分桶（Overdue/Warm/Favorite）、按时间筛选、按计数排序、聚合统计更直接。
- **迭代成本可控**：sqflite 直接使用 SQL，便于调试与迁移；通过集中管理建表/升级脚本保持可维护性。

### 5.2 表结构

#### 5.2.1 word_progress（按学习项）

| 字段 | 类型 | 说明 |
|------|------|------|
| `wordKey` | TEXT PK | `$categoryId:$wordId` |
| `categoryId` | TEXT | 主题 ID |
| `wordId` | TEXT | 单词/学习项 ID（分类内唯一） |
| `wordName` | TEXT | 冗余字段，调试友好 |
| `viewCount` | INTEGER | 看到次数（默认 0） |
| `playCount` | INTEGER | 听到次数（默认 0） |
| `lastSeenAt` | INTEGER? | epoch ms |
| `lastPlayedAt` | INTEGER? | epoch ms（可选） |

#### 5.2.2 category_progress（按主题）

| 字段 | 类型 | 说明 |
|------|------|------|
| `categoryId` | TEXT PK | 主题 ID |
| `lastSessionAt` | INTEGER? | 上次进入该主题学习页时间（epoch ms） |
| `lastExitedAt` | INTEGER? | 上次离开时间（epoch ms，可选） |

### 5.3 迁移策略

- **version=1**：创建 `word_progress`、`category_progress`
- 后续新增字段（如更细的会话统计、兴趣指标）通过 `onUpgrade` 增量迁移，不丢历史数据。

**代码位置（当前实现）：**

- 数据库与建表/迁移：`lib/src/data/app_database.dart`
- DAO（读写 SQL）：`lib/src/data/learning_progress_dao.dart`
- Service（口径与节流）：`lib/src/services/learning_progress_service.dart`
- 写入点位（UI）：`lib/src/pages/word_learning_page.dart`

---

## 六、写入点位（与现有页面逻辑对接）

以 `WordLearningPage` 为主：

- **进入页面**：
  - 记录 `category_progress.lastSessionAt = now`
  - 对首个展示词记 `viewCount +1`
  - 自动播放时记 `playCount +1`
- **切换单词（Next / 目录跳转）**：
  - 新词展示后（满足停留阈值）记 `viewCount +1`
  - 自动播放时记 `playCount +1`
- **点击卡片重播**：
  - 触发播放即记 `playCount +1`（带短时间合并）

---

## 七、为自适应排序提供的查询接口（DAO 层建议）

- `getCategoryProgress(categoryId)`：获取 `lastSessionAt` 判断模式
- `getWordProgressByCategory(categoryId)`：获取该主题全部学习项的 `view/play/lastSeen`
- `incrementView(wordKey, nowMs)` / `incrementPlay(wordKey, nowMs)`：原子更新

> 排序算法（分桶 + 混排）应放在 Service/UseCase 层，不应散落在 UI 层。

---

## 八、与多义词/多读音的兼容

当同一个英文单词在不同主题表示不同意义（如 `foods:orange` 与 `colors:orange`）：
- 使用不同的 `wordKey` 存储与调度
- 统计与复习在学习项粒度上独立进行

当同一主题内出现同形不同义/不同读音：
- 必须使用不同 `wordId`（如 `orange_fruit` / `orange_color`），保证 `wordKey` 唯一。

---

## 九、数据库文件位置、初始化与表结构变更（sqflite）

### 9.1 iOS / Android：数据库文件放在哪里？

使用 `sqflite` 时，SQLite 文件存放在**应用私有沙盒目录**中（用户不可直接访问；卸载 App 会删除）。

- **iOS**：通常位于 App 沙盒的 `Application Support/`（或同级别的私有目录），文件名由你在 DB 构造时指定（如 `hopenglish.sqlite`）。
- **Android**：通常位于应用私有目录的 `app_flutter/`（或同级别的私有目录），同样由你指定文件名。

> sqflite 会基于系统数据库目录创建文件；不建议自行硬编码绝对路径。

### 9.2 什么时候初始化数据库表结构？

sqflite 的建表发生在**第一次打开数据库连接**时（`openDatabase` 的 `onCreate` 回调）：

- **懒加载**：第一次需要读写学习数据时创建 `AppDatabase` 实例（首次开库时自动建表）。
- **启动预热（推荐）**：在 `main()` 启动后创建 DB 单例，让首次进入学习页时不承担“第一次开库”的延迟。

建议原则：**学习页进入即写入**，为了体验稳定，优先选择“启动预热 + 单例注入”。

**当前实现：**

- 在 `lib/main.dart` 中调用 `LearningProgressService.instance.ping()` 进行预热。

### 9.3 表结构需要变更时怎么处理？

使用 sqflite 的 **version + onUpgrade**：

- **新增列/新表/新索引**：通过 migration 增量升级
- **重命名/删除列**：使用“新建列/新表 → 迁移数据 → 替换旧表”的方式（避免 SQLite 限制导致的不确定行为）
- **兼容原则**：尽量保证升级不丢统计数据，否则算法会“失忆”

#### 9.3.1 version 约定

- **每次结构变更必须 +1**：`version` 单调递增
- **只要影响表结构就必须迁移**：新增字段、改默认值、改索引、拆表合表都算

#### 9.3.2 迁移代码模板（可复制）

以下模板用于 `AppDatabase` 中的升级逻辑（示意，字段与表名按实际工程替换）：

```dart
static const int version = 1;

static Future<void> onCreate(Database db) async {
  await db.execute('CREATE TABLE ...');
}

static Future<void> onUpgrade(Database db, int from, int to) async {
  if (from < 2) {
    // 示例：给 word_progress 新增一列
    // await db.execute('ALTER TABLE word_progress ADD COLUMN last_played_at INTEGER NULL');
  }
  if (from < 3) {
    // 示例：新增一个新表
    // await db.execute('CREATE TABLE category_progress (...)');
  }
  // 如有复杂变更（重命名/删除列），建议走“新表 + 拷贝数据 + 替换旧表”的方案
}
```
