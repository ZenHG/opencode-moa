# Translation Governance / 翻译治理规范

> Scope: README and user-facing documentation for OpenCode MoA.  
> Goal: keep multilingual docs useful without letting translations drift from the runnable configuration.

---

## 1. Source of truth

- Primary source for product facts: repository files, not prose.
  - Agents: `.opencode/agents/*.md`
  - Commands: `.opencode/commands/*.md`
  - Core skills: `.opencode/skills/*/SKILL.md` (3 core skills)
  - Static verification: `.opencode/tests/T0-static-verify.ps1`
  - Installation behavior: `install.ps1` and `install.sh`
- Primary README source for wording: `README.md` and `README.zh.md`.
- Other README files are full localized versions and must preserve the same technical facts.

---

## 2. Supported README languages

| Language | File |
| --- | --- |
| English | `README.md` |
| 中文 | `README.zh.md` |
| 日本語 | `README.ja.md` |
| 한국어 | `README.ko.md` |
| Español | `README.es.md` |
| Français | `README.fr.md` |
| Deutsch | `README.de.md` |

Policy:

- README files are maintained as complete language-specific entry points.
- Deep implementation docs do **not** need to be translated into all languages by default.
- Core deployment manuals should stay at least bilingual: Chinese + English.

Recommended coverage:

```text
README: 7 languages
Core deploy docs: zh + en
Internal/evaluation docs: source language only
Release notes: bilingual when practical
```

---

## 3. Terms that should usually remain unchanged

Do not translate command names, model IDs, file paths, agent IDs used for invocation, or code blocks.

Examples:

- `opencode --version`
- `opencode.json`
- `.opencode/agents`
- `pwsh .opencode/tests/T0-static-verify.ps1`
- `/moa-quick`, `/moa-medium`, `/moa-flagship`, `/moa-frontend`, `/moa-describe`
- `opencode-go/deepseek-v4-flash`
- `reasoningEffort`
- `ERROR_PROVIDER`, `ERROR_AUTH`, `ERROR_UNKNOWN`
- `concierge-router`, `tool-handler`, `flag-qa` when used as English aliases

Chinese display names may be localized in Chinese docs, but English aliases should be preserved when they help cross-language comparison.

---

## 4. Glossary

| Concept | Preferred wording / notes |
| --- | --- |
| MoA | Keep as `MoA` or expand once as `Mixture of Agents` |
| agent | Keep `agent` in technical contexts; localized prose may use equivalent words |
| command | Keep command names unchanged |
| skill | Keep `skill` in OpenCode-specific contexts |
| concierge-router / 门童路由员 | Default routing agent; preserve alias where useful |
| Doorman / Gatekeeper | Routing/governance concept; avoid inventing new names per language |
| Flagship QA / 旗舰·质检 | Quality gate; preserve QA meaning |
| confidence threshold | Use one shared definition across router, QA, and confidence assessor |
| fallback | Keep as `fallback` in technical prose or translate with the original in parentheses |
| (reserved for future product modes) | Not yet introduced; do not add to READMEs until finalized |

---

## 5. Synchronization rules

When any of the following changes, all README files must be checked:

- Agent count
- Command count
- Skill count
- Installation command
- Verification command
- Rollback instruction
- Free model list
- Cost claim
- FAQ answer
- Language navigation
- Model/provider naming
- Permission or security description

Minimum check after README updates:

```powershell
pwsh .opencode/tests/T0-static-verify.ps1
```

Recommended manual checks:

```cmd
findstr /n /c:"22 agents" README.md README.es.md README.fr.md README.de.md README.ja.md README.ko.md
findstr /n /c:"22 个" README.zh.md
findstr /n /c:"T0-static-verify.ps1" README*.md
```

---

## 6. Visual alignment rules

ASCII diagrams must be visually aligned across all language READMEs.

### 6.1 First diagram (top of README)

- Left side: `┌─` / `├─` / `└─` with agent name, flush left
- Right side: `───` with description, flush right
- Model name in parentheses must be padded to uniform display width
- `───` must start at the same column in all 4 lines
- CJK characters count as 2 display columns; ASCII as 1
- Use programmatic alignment (not manual spacing) to avoid drift

Example (English):

```text
    ┌─ flag-arch (Qwen3.7 Max)  ─── plan from the architect's view
    ├─ flag-plan (GLM 5.2    )  ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 )  ─── plan from the implementer's view
    └─ flag-fuse (Kimi K3    )  ─── take the best of each, one optimal solution
```

### 6.2 22 Agents section (Flagship / Tool / Mid-tier / Frontend)

- Each line: ` │   <role> (<display-name>, <model>) <description>`
- The closing `)` must align at the same column within each sub-section
- Pad `<display-name>, <model>` with spaces to achieve alignment
- Left `│` must have exactly 1 leading space in all lines

### 6.3 Table alignment

- Markdown tables: pad column cells so `|` aligns vertically
- Header separator `| --- |` must match column count
- CJK content in cells counts as 2 display columns

### 6.4 Verification

After any diagram or table edit, verify alignment programmatically:

```text
- First diagram: all `───` at same column
- 22 Agents flagship: all `)` at same column
- Tool / Mid-tier / Frontend: all `)` at same column
- Tables: all `|` at same column
```

---

## 7. Pull request checklist for documentation changes

- [ ] Did agent / command / skill counts change? If yes, update README, install scripts, T0, and CHANGELOG.
- [ ] Did installation steps change? If yes, sync all README files.
- [ ] Did FAQ change? If yes, sync all README files or explicitly document why not.
- [ ] Did model IDs or provider names change? If yes, update docs and T0 expectations.
- [ ] Did confidence threshold wording change? If yes, sync router, QA, confidence assessor, and docs.
- [ ] Did you run `pwsh .opencode/tests/T0-static-verify.ps1`?
- [ ] Did you ensure `.agnes/` and session summaries are not accidentally committed?

---

## 8. Translation quality bar

A localized README is acceptable only if:

1. It has the same major sections as the source README.
2. Code blocks are balanced and copyable.
3. Commands, paths, model IDs, and agent identifiers remain executable.
4. It does not contain large residue from another non-target language.
5. It preserves warnings about key paths, install scripts, fallback behavior, and free-model limitations.
6. It links to other language versions correctly.

---

## 9. Maintenance principle

Prefer fewer, reliable translated surfaces over many stale translations.

The README is the international entry point. Deeper docs should be translated only when they are user-facing and stable enough to maintain.
