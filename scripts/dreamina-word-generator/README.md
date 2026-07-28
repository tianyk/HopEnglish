# HopEnglish Dreamina 批量配图脚本

临时 Node.js 工具：读取全部单词，通过官方 `dreamina` CLI 文生图并异步轮询，
保存 `submit_id` 以便中断后继续，下载原图、去掉纯色背景，并输出
512 × 512 透明 PNG。

## 使用

```bash
cd scripts/dreamina-word-generator
npm install

# 先试跑 5 张
npm run generate -- --limit=5

# 生成某个分类
npm run generate -- --category=animals

# 生成全部；成功项跳过，没有远端结果的失败项自动重新生成
npm run generate

# 不管原状态，强制重新生成前 5 张
npm run generate -- --limit=5 --force

# 指定多个单词生成到候选目录，不覆盖正式素材
npm run generate -- --words=nature/moon,actions/swim --candidate --force

# 生成中断后续跑候选任务；复用已有提交，不重复扣 credits
npm run generate -- --words=nature/moon,actions/swim --candidate

# 人工验收后采用候选图
npm run generate -- --words=nature/moon,actions/swim --accept-candidates

# 生成全部分类入口图标到候选目录
npm run generate -- --category-icons --candidate --force

# 验收后采用分类图标并写入 categories.json
npm run generate -- --category-icons --accept-candidates
npm run generate -- --category-icons --apply-images

# 全部任务成功后写入 categories.json
npm run generate -- --apply-images
```

可用筛选参数：

```bash
-f
--force
--limit=5
--category=animals
--word=lion
--word=animals/lion
--words=animals/lion,nature/moon
--candidate
--accept-candidates
--apply-images
--category-icons
```

运行状态与 Dreamina 2K 原图保存在 gitignored 的 `.state/` 中。最终图片
写入 `assets/images/words/{category}_{word}.png`。如果脚本在提交阶段中断，
下次启动会从 `dreamina list_task` 查找同提示词任务；无法确认的任务不会
自动重新提交，避免重复扣 credits。已经生成但下载或处理失败的任务会复用
原 `resultUrl`，只有显式使用 `--force` 才会重新提交并再次扣 credits。
