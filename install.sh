#!/bin/bash
# install.sh — MoA 安装脚本（增量合并 opencode.json）
# 用法: bash ./install.sh
# 兼容: Linux / macOS / Windows (Git Bash / WSL / MSYS2)
# 需要: 先将 .opencode/ 复制到当前目录

set -e

# --install-jq: jq 缺失时自动用系统包管理器安装（apt-get/brew/dnf），先检查再安装
INSTALL_JQ=0
for arg in "$@"; do
    case "$arg" in
        --install-jq) INSTALL_JQ=1 ;;
        *) ;;
    esac
done

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

# 0. 运行环境检查（缺失给指引，不阻断合并——配置可先行，运行时后装）
echo "--- 环境检查 ---"
if ! command -v pwsh >/dev/null 2>&1; then
  echo -e "  ${YELLOW}⚠ 未找到 pwsh（PowerShell 7+）—— run-all 验证 / bootstrap 自举 / long-loop 循环均需 pwsh。${NC}"
  case "$(uname -s)" in
    Darwin)
      echo -e "  ${CYAN}  安装: brew install --cask powershell${NC}" ;;
    MINGW*|MSYS*|CYGWIN*)
      echo -e "  ${CYAN}  安装（Windows 必须官方 MSI）: winget install Microsoft.PowerShell${NC}"
      echo -e "  ${CYAN}  或自动 MSI: powershell -File install.ps1 -InstallPwsh（勿用 zip 解压版）${NC}" ;;
    *)
      echo -e "  ${CYAN}  安装: 见 https://learn.microsoft.com/powershell${NC}" ;;
  esac
fi
if ! command -v opencode >/dev/null 2>&1; then
  echo -e "  ${YELLOW}⚠ 未找到 opencode CLI —— MoA 流水线与 LongLoop 都依赖它驱动每轮会话。${NC}"
  echo -e "  ${CYAN}  安装: npm install -g opencode-ai 或 curl -fsSL https://opencode.ai/install | bash${NC}"
  echo -e "  ${GRAY}  装好后若仍找不到，设置环境变量 OPENCODE_BIN 指向 opencode 可执行文件。${NC}"
fi

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
                "deepseek-v4-pro": {"name": "deepseek-v4-pro"},
                "kimi-k2.6": {"name": "kimi-k2.6"},
                "kimi-k3": {"name": "kimi-k3"}
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
  "default_agent": "门童",
  "permission": {
    "*": "ask",
    "bash": {
      "*": "ask",
      "git status *": "allow",
      "git diff *": "allow",
      "git log *": "allow",
      "grep *": "allow",
      "rg *": "allow",
      "Select-String *": "allow",
      "ls *": "allow",
      "Get-ChildItem *": "allow",
      "Get-Content *": "allow",
      "cd *": "allow",
      "npm run *": "allow",
      "pwsh .opencode/tests/*": "allow",
      "*$env:TEMP*": "allow",
      "*$env:TMP*": "allow",
      "*/tmp/*": "allow",
      "rm *": "deny"
    },
    "task": {
      "*": "deny",
      "工具人": "allow",
      "工具人-mimo": "allow",
      "闪电侠": "allow",
      "视觉翻译": "allow",
      "中级·工程": "allow",
      "中级·创意": "allow",
      "中级·码农": "allow",
      "中级·融合": "allow",
      "旗舰·架构": "allow",
      "旗舰·规划": "allow",
      "旗舰·工程": "allow",
      "旗舰·融合": "allow",
      "旗舰·执行": "allow",
      "旗舰·质检": "allow",
      "前端·还原": "allow",
      "前端·逻辑": "allow",
      "前端·动效": "allow",
      "前端·总工": "allow",
      "融合·保底": "allow",
      "残差提取": "allow",
      "置信度评估": "allow"
    },
    "webfetch": "allow",
    "read": {
      "*": "allow",
      "*.env": "deny",
      "*.env.*": "deny",
      "*.env.example": "allow"
    },
    "todowrite": "allow"
  },
  "agent": {
    "中级·工程": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "中级·创意": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "中级·码农": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "中级·融合": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "旗舰·架构": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "旗舰·规划": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "旗舰·工程": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "旗舰·融合": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "旗舰·执行": { "permission": { "*_*": "deny", "moa-loop_*": "allow" } },
    "旗舰·质检": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "前端·逻辑": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "前端·动效": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "前端·总工": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "融合·保底": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "残差提取": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } },
    "置信度评估": { "permission": { "*_*": "deny", "read": "deny", "bash": "deny", "grep": "deny", "glob": "deny", "list": "deny", "webfetch": "deny", "websearch": "deny", "edit": "deny" } }
  },
  "compaction": { "auto": true, "reserved": 15000 },
  "share": "manual",
  "snapshot": true,
  "mcp": {
    "moa-loop": {
      "type": "local",
      "command": ["node", "longloop/server.js"],
      "enabled": true
    }
  }
}'

# 合并 MoA 配置 + 用户配置 + 平台删除禁令（jq 就绪后调用）
merge_config() {
    if uname -s | grep -qiE 'mingw|msys|cygwin'; then
        DENY_EXTRA='["del *","Remove-Item *","rd *","rmdir *"]'
    else
        DENY_EXTRA='[]'
    fi
    USER_PROVIDER=$(jq '.provider // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
    USER_MODEL=$(jq '.model // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
    USER_SMALL=$(jq '.small_model // empty' "$OPENCODE_JSON" 2>/dev/null || echo "")
    echo "$MOA_JSON" | jq \
        --argjson extra "$DENY_EXTRA" \
        --argjson provider "${USER_PROVIDER:-null}" \
        --argjson model "${USER_MODEL:-null}" \
        --argjson small "${USER_SMALL:-null}" \
        '.permission.bash = (reduce $extra[] as $k (.permission.bash; .[$k] = "deny")) |
         . + (if $provider != null then {provider: $provider} else {} end) +
         (if $model != null then {model: $model} else {} end) +
         (if $small != null then {small_model: $small} else {} end)' \
        > "$OPENCODE_JSON"
    ok "配置已合并（保留用户 provider/model）"
}

if [ -f "$OPENCODE_JSON" ]; then
    skip "已有 opencode.json，备份原文件"
    BACKUP="$OPENCODE_JSON.bak.$(date +%Y%m%d-%H%M%S)"
    cp "$OPENCODE_JSON" "$BACKUP"
    ok "已备份到 $(basename "$BACKUP")"
    
    if command -v jq &> /dev/null; then
        merge_config
    else
        if [ "$INSTALL_JQ" = "1" ]; then
            echo -e "  ${YELLOW}jq 未安装，自动安装...${NC}"
            if command -v apt-get &> /dev/null; then
                (sudo apt-get install -y jq 2>/dev/null || apt-get install -y jq 2>/dev/null) || true
            elif command -v brew &> /dev/null; then
                brew install jq 2>/dev/null || true
            elif command -v dnf &> /dev/null; then
                (sudo dnf install -y jq 2>/dev/null || dnf install -y jq 2>/dev/null) || true
            else
                fail "未找到支持的包管理器（apt-get/brew/dnf），请手动安装 jq"
                exit 1
            fi
        fi
        if command -v jq &> /dev/null; then
            merge_config
        else
            fail "未安装 jq，无法自动合并"
            echo "  请手动合并 opencode.json，或安装 jq："
            echo "  apt install jq / brew install jq / choco install jq"
            echo "  或加 --install-jq 自动安装"
            echo "  参考: https://github.com/ZenHG/opencode-moa#方式三手动安装"
            exit 1
        fi
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
    echo -e "${YELLOW}⚠️ 未检测到 opencode-go provider。22 个 agent 全部使用 opencode-go/<model>，需要 Go API Key。${NC}"
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
                    "deepseek-v4-pro": {"name": "deepseek-v4-pro"},
                    "kimi-k2.6": {"name": "kimi-k2.6"},
                    "kimi-k3": {"name": "kimi-k3"}
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

[ "$AGENT_COUNT" -gt 0 ] && ok "Agents: $AGENT_COUNT" || fail "Agents: $AGENT_COUNT"
[ "$CMD_COUNT" -gt 0 ] && ok "Commands: $CMD_COUNT" || fail "Commands: $CMD_COUNT"
[ "$SKILL_COUNT" -gt 0 ] && ok "Skills: $SKILL_COUNT" || fail "Skills: $SKILL_COUNT"
ok "Config: ok"
if [ -f "$PROJECT_DIR/longloop/server.js" ]; then
    ok "LongLoop MCP: ok"
else
    echo -e "  ${YELLOW}⚠ longloop/ 未复制 —— moa-loop MCP（长程自完善状态工具）将不可用${NC}"
    echo -e "  ${GRAY}-> 从仓库复制: cp -r <opencode-moa 路径>/longloop/ .${NC}"
fi
if command -v node &> /dev/null; then
    NODE_VER=$(node --version 2>/dev/null)
    NODE_MAJOR=$(echo "$NODE_VER" | sed -E 's/v([0-9]+).*/\1/')
    if [ -n "$NODE_MAJOR" ] && [ "$NODE_MAJOR" -ge 14 ] 2>/dev/null; then
        ok "Node.js: ok ($NODE_VER)"
    else
        echo -e "  ${YELLOW}⚠ node $NODE_VER < 14 —— moa-loop MCP 需要 >= 14${NC}"
    fi
else
    echo -e "  ${YELLOW}⚠ node 未安装 —— moa-loop MCP（长程自完善状态工具）不可用${NC}"
    echo -e "  ${GRAY}-> 安装: https://nodejs.org （LTS 版）${NC}"
fi

echo ""
echo -e "${CYAN}=== 安装完成 ===${NC}"
echo -e "${YELLOW}重启 OpenCode 使配置生效。${NC}"
echo -e "${YELLOW}按 Tab 循环切换 agent（Win 桌面端亦可用 Ctrl+.）切换到「门童」开始使用。${NC}"
