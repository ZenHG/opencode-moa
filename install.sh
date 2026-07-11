#!/bin/bash
# install.sh — MoA 安装脚本（增量合并 opencode.json）
# 用法: bash ./install.sh
# 兼容: Linux / macOS / Windows (Git Bash / WSL / MSYS2)
# 需要: 先将 .opencode/ 复制到当前目录

set -e

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m'

ok() { echo -e "  ${GREEN}✓ $1${NC}"; }
skip() { echo -e "  ${GRAY}- $1${NC}"; }
fail() { echo -e "  ${RED}✗ $1${NC}"; }

gen_placeholder() {
    if jq -e '.provider["opencode-go"]' "$OPENCODE_JSON" >/dev/null 2>&1; then
        skip "opencode-go provider 已存在，未覆盖"
        return
    fi
    echo "  ⚠ 未提供 key。写入占位符 <YOUR_GO_API_KEY> 到 opencode.json。"
    jq --arg key "<YOUR_GO_API_KEY>" '
        .provider["opencode-go"] = {
            "npm": "@ai-sdk/openai-compatible",
            "name": "OpenCode Go (MoA)",
            "options": { "baseURL": "https://opencode.ai/zen/go/v1", "apiKey": $key },
            "models": {
                "deepseek-v4-flash": {"name": "deepseek-v4-flash"},
                "mimo-v2.5": {"name": "mimo-v2.5"},
                "mimo-v2.5-pro": {"name": "mimo-v2.5-pro"},
                "minimax-m3": {"name": "minimax-m3"},
                "glm-5.2": {"name": "glm-5.2"},
                "qwen3.7-max": {"name": "qwen3.7-max"},
                "qwen3.7-plus": {"name": "qwen3.7-plus"},
                "kimi-k2.7-code": {"name": "kimi-k2.7-code"},
                "deepseek-v4-pro": {"name": "deepseek-v4-pro"}
            }
        } | .model = "opencode-go/deepseek-v4-flash"' "$OPENCODE_JSON" > "${OPENCODE_JSON}.tmp" && mv "${OPENCODE_JSON}.tmp" "$OPENCODE_JSON"
    ok "opencode-go provider 已写入（占位符 key），请替换 <YOUR_GO_API_KEY>"
    echo "  编辑 opencode.json 的 provider.opencode-go.apiKey 填入真实 key，再重启 OpenCode。"
    echo "  OpenCode 仅加载 opencode.json 与系统级 ~/.config/opencode/opencode.json，不加载 user_config.json。"
}

echo ""
echo -e "${CYAN}=== OpenCode MoA 安装 ===${NC}"

PROJECT_DIR=$(pwd)
OPENCODE_JSON="$PROJECT_DIR/opencode.json"
MOA_DIR="$PROJECT_DIR/.opencode"

# 1. 检查 .opencode 目录
echo ""
echo -e "${YELLOW}[1/3] 检查 .opencode/ 目录...${NC}"
if [ -d "$MOA_DIR" ]; then
    AGENT_COUNT=$(ls "$MOA_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
    ok ".opencode/ 存在 ($AGENT_COUNT agents)"
else
    fail ".opencode/ 不存在"
    echo "  请先克隆仓库并复制 .opencode/ 到当前目录"
    echo "  git clone https://github.com/ZenHG/opencode-moa.git tmp"
    echo "  cp -r tmp/.opencode/ ."
    exit 1
fi

# 2. 合并 opencode.json
echo ""
echo -e "${YELLOW}[2/3] 合并 opencode.json...${NC}"

MOA_JSON='{
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
}'

if [ -f "$OPENCODE_JSON" ]; then
    skip "已有 opencode.json，备份原文件"
    BACKUP="$OPENCODE_JSON.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$OPENCODE_JSON" "$BACKUP"
    ok "已备份到 $(basename "$BACKUP")"
    
    if command -v jq &> /dev/null; then
        # 提取用户配置（provider, model, small_model）
        USER_PROVIDER=$(jq '.provider // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
        USER_MODEL=$(jq '.model // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
        USER_SMALL=$(jq '.small_model // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
        
        # 合并：MoA 配置 + 用户配置
        echo "$MOA_JSON" | jq \
            --argjson provider "${USER_PROVIDER:-null}" \
            --argjson model "${USER_MODEL:-null}" \
            --argjson small "${USER_SMALL:-null}" \
            '. + (if $provider != null then {provider: $provider} else {} end) +
             (if $model != null then {model: $model} else {} end) +
             (if $small != null then {small_model: $small} else {} end)' \
            > "$OPENCODE_JSON"
        ok "配置已合并（保留用户 provider/model）"
    else
        fail "未安装 jq，无法自动合并"
        echo "  请手动合并 opencode.json，或安装 jq："
        echo "  apt install jq / brew install jq / choco install jq"
        echo "  参考: https://github.com/ZenHG/opencode-moa#方式三手动安装"
        exit 1
    fi
else
    skip "opencode.json 不存在，请先配置 OpenCode"
    echo "  请先在 opencode.json 中配置 Go provider，然后重新运行此脚本"
    exit 1
fi

# 2.5 检查 opencode-go provider，交互环境提示输入 key
HAS_GO=$(jq '.provider["opencode-go"] // empty' "$OPENCODE_JSON" 2>/dev/null)
if [ -z "$HAS_GO" ]; then
    echo ""
    echo -e "${YELLOW}⚠️ 未检测到 opencode-go provider。19 个 agent 全部使用 opencode-go/<model>，需要 Go API Key。${NC}"
    if [ -t 0 ]; then
        echo "  可以在 opencode.ai/auth 创建后输入（直接回车跳过）："
        printf "  Go API Key: "
        read API_KEY
        if [ -n "$API_KEY" ]; then
            jq --arg key "$API_KEY" '.provider["opencode-go"] = {
                "npm": "@ai-sdk/openai-compatible",
                "name": "OpenCode Go (MoA)",
                "options": {
                    "baseURL": "https://opencode.ai/zen/go/v1",
                    "apiKey": $key
                },
                "models": {
                    "deepseek-v4-flash": {"name": "deepseek-v4-flash"},
                    "mimo-v2.5": {"name": "mimo-v2.5"},
                    "mimo-v2.5-pro": {"name": "mimo-v2.5-pro"},
                    "minimax-m3": {"name": "minimax-m3"},
                    "glm-5.2": {"name": "glm-5.2"},
                    "qwen3.7-max": {"name": "qwen3.7-max"},
                    "qwen3.7-plus": {"name": "qwen3.7-plus"},
                    "kimi-k2.7-code": {"name": "kimi-k2.7-code"},
                    "deepseek-v4-pro": {"name": "deepseek-v4-pro"}
                }
            } | .model = "opencode-go/deepseek-v4-flash"' "$OPENCODE_JSON" > "${OPENCODE_JSON}.tmp" && mv "${OPENCODE_JSON}.tmp" "$OPENCODE_JSON"
            ok "opencode-go provider 已配置"
        else
            echo "  ⚠ 跳过交互输入，生成占位符文件。" 
            gen_placeholder
        fi
    else
        echo "  ⚠ 非交互环境，生成占位符文件。"
        gen_placeholder
    fi
fi

# 3. 验证
echo ""
echo -e "${YELLOW}[3/3] 验证部署...${NC}"

AGENT_COUNT=$(ls "$MOA_DIR/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
CMD_COUNT=$(ls "$MOA_DIR/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$(find "$MOA_DIR/skills" -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')

[ "$AGENT_COUNT" -eq 19 ] && ok "Agents: 19" || fail "Agents: $AGENT_COUNT (期望 19)"
[ "$CMD_COUNT" -eq 5 ] && ok "Commands: 5" || fail "Commands: $CMD_COUNT (期望 5)"
[ "$SKILL_COUNT" -eq 3 ] && ok "Skills: 3" || fail "Skills: $SKILL_COUNT (期望 3)"
ok "Config: ok"

echo ""
echo -e "${CYAN}=== 安装完成 ===${NC}"
echo -e "${YELLOW}重启 OpenCode 使配置生效。${NC}"
echo -e "${YELLOW}按 Tab 循环切换 agent（Win 桌面端亦可用 Ctrl+.）切换到「门童路由员」开始使用。${NC}"
