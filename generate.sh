#!/bin/bash
# AI Daily Report Generator

set -e

REPO_DIR="/root/.openclaw/workspace/ai-daily"
DATE=$(date +%Y-%m-%d)
YEAR=$(date +%Y)
FILENAME="${YEAR}/${DATE}.md"

cd "$REPO_DIR"

# Create year directory if not exists
mkdir -p "$YEAR"

# Generate daily report
cat > "$FILENAME" << 'EOF'
---

任务：生成 ${DATE} 的 AI 日报

1. 搜索以下平台昨天的大模型/AGI/AI 新闻：
   - Twitter/X (搜索: "LLM OR "large language model" OR AGI OR "artificial intelligence" OR GPT OR Claude OR Gemini)
   - Reddit (r/MachineLearning, r/LocalLLaMA, r/artificial)
   - Hacker News (AI 相关热门)
   - Product Hunt (AI 产品发布)
   - arXiv (cs.AI, cs.CL, cs.LG 昨日论文)
   - 机器之心、量子位等中文 AI 媒体

2. 整理格式：
   - 分类：大模型更新、产品发布、研究论文、行业动态
   - 每条包含：标题、一句话摘要、来源链接
   - 按重要性排序

3. 保存到文件：${FILENAME}

4. Git 操作：
   - git add ${FILENAME}
   - git commit -m "Add daily report for ${DATE}"
   - git push origin main

5. 发送飞书通知给用户

---
EOF

echo "Template created at $FILENAME"
