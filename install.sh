#!/bin/bash
# install.sh — MoA 安装脚本（增量合并 opencode.json）
# 用法: bash ./install.sh
# 会在当前目录下创建 .opencode/ 并合并 opencode.json

set -e

echo ""
echo "=== OpenCode MoA 安装 ==="

# 检测项目目录
PROJECT_DIR=$(pwd)
OPENCODE_JSON="$PROJECT_DIR/opencode.json"
MOA_DIR="$PROJECT_DIR/.opencode"

# 1. 检查 .opencode 目录
echo ""
echo "[1/3] 检查 .opencode/ 目录..."
if [ -d "$MOA_DIR" ]; then
    echo "  .opencode/ 已存在"
else
    echo "  .opencode/ 不存在，请先从仓库复制"
    echo "  运行: git clone https://github.com/ZenHG/opencode-moa.git tmp && cp -r tmp/.opencode/ ."
    exit 1
fi

# 2. 合并 opencode.json
echo ""
echo "[2/3] 合并 opencode.json..."

if [ -f "$OPENCODE_JSON" ]; then
    echo "  已有 opencode.json，备份原文件"
    BACKUP="$OPENCODE_JSON.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$OPENCODE_JSON" "$BACKUP"
    echo "  已备份到 $BACKUP"
    
    # 检查是否有 jq
    if command -v jq &> /dev/null; then
        echo "  使用 jq 合并配置"
        # 保留用户配置，合并 MoA 配置
        jq -s '.[0] * .[1]' "$OPENCODE_JSON" <(cat <<'EOF'
{
  "default_agent": "门童路由员",
  "permission": {
    "*": "ask",
    "bash": {
      "*": "ask",
      "git *": "allow",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "grep *": "allow",
      "ls *": "allow",
      "cat *": "allow",
      "cd *": "allow",
      "npm run *": "allow",
      "rm *": "deny",
      "del *": "deny"
    },
    "task": {
      "*": "deny",
      "工具人": "allow",
      "工具人-mimo": "allow",
      "闪电侠": "allow",
      "视觉翻译官": "allow",
      "中级·工程": "allow",
      "中级·创意": "allow",
      "中级·码农": "allow",
      "中级·融合": "allow",
      "旗舰·架构": "allow",
      "旗舰·规划": "allow",
      "旗舰·工程": "allow",
      "旗舰·融合": "allow",
      "旗舰·实现": "allow",
      "旗舰·质检": "allow",
      "前端·还原": "allow",
      "前端·逻辑": "allow",
      "前端·动效": "allow",
      "前端·总工": "allow"
    },
    "webfetch": "allow",
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow"
    }
  },
  "agent": {
    "中级·工程": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "中级·创意": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "中级·码农": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "旗舰·架构": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "旗舰·规划": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "旗舰·工程": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "前端·逻辑": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } },
    "前端·动效": { "permission": { "*": "ask", "task": "allow", "*_*": "deny" } }
  },
  "instructions": ["AGENTS.md"],
  "compaction": { "auto": true, "reserved": 10000 },
  "share": "manual",
  "snapshot": true
}
EOF
        ) > "$OPENCODE_JSON.tmp" && mv "$OPENCODE_JSON.tmp" "$OPENCODE_JSON"
        echo "  配置已合并（保留用户 provider）"
    else
        echo "  未安装 jq，请手动合并 opencode.json"
        echo "  参考: https://github.com/ZenHG/opencode-moa#方式二手动安装"
    fi
else
    echo "  opencode.json 不存在，请先配置 OpenCode"
    echo "  运行: /connect 配置 provider，然后重新运行此脚本"
    exit 1
fi

# 3. 验证
echo ""
echo "[3/3] 验证部署..."
AGENT_COUNT=$(ls "$MOA_DIR/agents/"*.md 2>/dev/null | wc -l)
CMD_COUNT=$(ls "$MOA_DIR/commands/"*.md 2>/dev/null | wc -l)
SKILL_COUNT=$(find "$MOA_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l)

echo "  Agents: $AGENT_COUNT"
echo "  Commands: $CMD_COUNT"
echo "  Skills: $SKILL_COUNT"
echo "  Config: ok"

echo ""
echo "=== 安装完成 ==="
echo "重启 OpenCode 使配置生效。"
echo "按 Ctrl+. 切换到「门童路由员」开始使用。"
