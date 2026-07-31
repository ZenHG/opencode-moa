# OpenCode MoA

> 🌐 언어: 영어 · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **핫 (2026-07):** 플래그십 퓨즈가 **Kimi K3**로 업그레이드됨 — 2.8T 파라미터, 1M 컨텍스트, 최상급 프론티어 모델. MoA 품질 한계가 이제 최전선에 있습니다.

> 구조화된 출력, 라인 수용, 안티 치트, 자동 라우팅. [CHANGELOG](CHANGELOG.md)를 참조하세요.

> **하나의 대화 진입점, 22개의 전문 모델이 자동으로 협력합니다. 간단한 작업은 Flash(저렴)를 사용하고, 복잡한 작업은 플래그십(비쌈)을 호출합니다. 간단한 작업이 작업 부하를 지배하고 플래그십 호출이 최소화될 때 비용이 최대 ~90% 절감됩니다(모든 플래그십 대비) — 실제 절감액은 작업 조합에 따라 다르며; 코드 품질이 크게 향상됩니다.**

<!-- ARCH-IMG -->
![OpenCode MoA Architecture](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA는 OpenCode를 위한 에이전트 혼합 구성 패키지입니다. 여러 모델이 **동시에 같은 문제에 대해 생각**한 다음, 단일 모델이 도달할 수 없는 출력 품질로 융합됩니다. 도구를 전환하거나 코드를 작성하거나 API 할당량을 가질 필요가 없습니다 — 파일을 프로젝트에 드롭하고 OpenCode를 재시작하기만 하면 됩니다.

**22개의 에이전트 · 5개의 명령어 · 3개의 기술 · 30초 배포**

---


## 왜 이게 필요할까요?

기본적으로 OpenCode는 시작부터 끝까지 단일 모델을 사용합니다. 하나의 문자를 변경하고 시스템 아키텍처를 설계하는 데 동일한 프롬프트, 동일한 온도, 동일한 컨텍스트를 사용합니다. 노동 분업이 없습니다.

**세 가지 문제:**

1. **비용 통제 불능** — 간단한 작업도 비싼 모델을 사용하여 월 청구서가 높게 유지됩니다.
2. **품질 병목 현상** — 단일 모델은 사고 방식이 하나뿐이며, 쉽게 맹점에 갇힙니다.
3. **내결함성 없음** — 모델이 죽으면 멈추고, 대체 수단이 없습니다.

**MoA의 해결책:**

```

You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max)  ─── 건축가의 관점에서 계획
    ├─ flag-plan (DeepSeek V4 Flash    )  ─── 계획의 관점에서 계획
    ├─ flag-eng  (DeepSeek V4 Flash)  ─── 구현자의 관점에서 계획
    └─ flag-fuse (Kimi K3    )  ─── 각자의 최선을 취하여 하나의 최적 솔루션
```

<!-- COST-IMG -->
![Cost down up to 90%](.github/moa-cost.png)
<!-- /COST-IMG -->

세 개의 독립적인 계획이 세 개의 서로 다른 모델에서 자연스럽게 "합의 + 분기" 구조를 형성합니다. 융합 모델은 무엇이 합의인지 식별하고 이를 유지하며, 분기된 부분에서 최선을 취합니다 — 단일 모델이 할 수 없는 작업입니다.

---


## 필수 조건

### 필수

| 요구 사항            | 확인 명령어                  | 비고                                                                                                                                                                                                 |
| ------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode 설치됨     | `opencode --version`         | **>= 1.3.4** (에이전트 수준 `reasoningEffort`/`hidden`/`task` 지원; `openai-compatible` 제공자는 추론을 투명하게 전달하며, `forceReasoning` 필요 없음), [설치](https://opencode.ai/install) |
| OpenCode Go 요금제  | opencode.ai 콘솔            | [구독](https://opencode.ai/auth), 첫 달 $5, 이후 $10/월                                                                                                                                         |
| Git 설치됨         | `git --version`              | 레포를 클론하는 데 사용됩니다.                                                                                                                                                                     |
| OpenCode Go API 키  | opencode.ai 콘솔에서 생성됨 | Zen 콘솔(opencode.ai)에서 생성됨                                                                                                                                                                   |

### 선택 사항 (설치 스크립트에서 필요)

| 요구 사항         | 확인 명령어    | 비고                                                                     |
| ----------------- | ---------------- | ------------------------------------------------------------------------- |
| PowerShell Core    | `pwsh --version` | install.ps1에서 필요, Windows에 번들로 포함되거나 `brew install powershell`로 설치  |
| jq                | `jq --version`   | JSON 병합을 위한 install.sh에서 필요, `apt install jq` / `brew install jq` |

> pwsh/jq가 없어도 괜찮습니다 — 방법 1(AI 자동 배포) 또는 방법 3(수동 병합)을 사용할 수 있습니다.

### 데스크탑 vs CLI

- **CLI**: 모든 방법 지원
- **데스크탑**: 방법 1(AI 자동 배포)이 가장 편리합니다; 방법 2/3은 먼저 터미널 작업이 필요합니다.

> ⚠️ **시스템 수준 키 경로를 잘못 배치하기 쉽습니다** — 아래 "배포 전에 읽기"에서 올바른 철자를 확인하세요. 잘못된 경로는 배포가 성공한 것처럼 보이지만 모든 에이전트가 연결되지 못하게 됩니다.

> ⚠️ **배포 전에 읽기: 키 경로를 잘못 배치하지 마세요**
> 제공자 + 키를 **프로젝트 수준 `opencode.json`** (기본값, 독립형) 또는 **시스템 수준** 공유 경로 중 하나에 넣으세요 — **하나**를 선택하세요.
> 시스템 수준을 사용하는 경우, 올바른 경로는:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**아니요** `%APPDATA%\opencode`)
>   잘못된 시스템 수준 경로는 "배포가 성공하지만 모든 에이전트가 연결할 수 없음"으로 이어집니다.

---


## 30초 배포

### 방법 1: AI 자동 배포 (권장)

1. [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md) 다운로드
2. OpenCode에 해당 문서를 업로드하고 전송:

> 현재 프로젝트에 이 매뉴얼에서 22개의 에이전트, 5개의 명령어 및 3개의 기술을 배포합니다.

3. AI가 모든 파일을 자동으로 생성합니다. **완료되면 OpenCode를 재시작하세요.**

> 파일을 수동으로 생성할 필요가 없습니다. 배포 매뉴얼 자체가 설치 프로그램입니다.

### 방법 2: 원클릭 설치 스크립트 (스크립트 버전 · CLI 친화적)

```bash
# 레포 클론
git clone https://github.com/ZenHG/opencode-moa.git

# 프로젝트 디렉토리로 이동
cd your-project

# 레포에서 .opencode 디렉토리와 .moa 구성 복사
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .

# 설치 스크립트 실행 (구성 자동 병합, API 키 유지)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> 설치 스크립트는 원본 `opencode.json`을 자동으로 백업하며, 제공자와 API 키를 유지하면서 MoA 구성을 병합합니다.
> 

### 모델 사용자 정의

MoA는 **일반 템플릿**입니다 — 각 에이전트의 모델은 변경할 수 있는 ID입니다. 각 에이전트 파일은 다음으로 시작합니다:

```yaml
model: opencode-go/<model-id>
```

모델을 교체하려면, `.opencode/agents/<agent>.md`에서 해당 한 줄을 접근할 수 있는 `provider/model-id`로 편집하세요 (예: `opencode-go/kimi-k2.7-code`, `opencode-go/deepseek-v4-flash`). 재설치가 필요 없습니다. 자유롭게 혼합하고 매치하세요 — 템플릿은 여러분을 구속하지 않습니다.

### 방법 3: 수동 설치

```bash
# 1. 레포 클론
git clone https://github.com/ZenHG/opencode-moa.git

# 2. .opencode 디렉토리와 .moa 구성 복사
cp -r opencode-moa/.opencode/ your-project/
cp -r opencode-moa/.moa/ your-project/

# 3. opencode.json 수동 병합 (직접 교체하지 마세요!)
# opencode.json을 열고 MoA의 permission.task 및 agent 섹션을 병합하세요.
# 기존 제공자 및 모델 구성을 유지하세요.
```

> ⚠️ **절대** `cat >>`를 사용하여 추가하지 마세요 — JSON 형식이 손상됩니다. **직접 교체하지 마세요** — API 키를 잃게 됩니다.
> 

### 배포 성공 여부 확인 방법

1. OpenCode를 재시작한 후, `Tab`을 눌러 에이전트를 순환하고 "门童"를 확인하세요.
2. `@工具人`를 입력하면 응답합니다.
3. 검증 스크립트를 실행하세요: `pwsh .opencode/tests/T0-static-verify.ps1` (배포 중 수동 블록 5.5에 의해 생성됨), 예상 결과는 모두 PASS(FAIL=0; 시스템 수준 키가 있는 경우, WARN도 PASS로 간주됨)입니다.

### 원클릭 롤백

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
# 수동으로 opencode.json을 복원하세요 (설치 스크립트가 자동으로 .bak 파일을 백업합니다.)
```

---

## 사용 방법은?

**아무것도 배우지 마세요 — 그냥 이야기하세요.** 컨시어지-라우터는 자동으로 작업 복잡성을 판단하고 해당 에이전트 체인을 배치합니다.

| 당신이 말하는 것                       | 컨시어지-라우터가 하는 일                                        | 사용된 에이전트                     |
| -------------------------------------- | -------------------------------------------------------------- | ----------------------------------- |
| "이 변수를 이름 변경해줘"              | 간단한 작업으로 판단                                          | swift (Flash)                       |
| "사용자 인증 모듈을 작성해줘"           | 도구 계층 수집 → 3 중간 계층 병렬 → 융합                       | tool-handler + mid-tier trio + fuse |
| "마이크로서비스 아키텍처를 설계해줘"   | 도구 계층 수집 → 3 플래그십 병렬 → 융합 → 구현 → QA          | full-chain 6 agents                 |
| "이 스크린샷의 UI를 복원해줘"          | 3 프론트엔드 전문가 병렬 → 리드가 최선 선택                    | frontend quartet                    |
| 스크린샷이 포함된 메시지                | 비전-번역기가 텍스트로 변환 → 일반 라우팅                     | vision-translator                   |
| 오류 로그 / 다이어그램 / 복잡한 콘텐츠가 포함된 메시지 | 비전-번역기가 콘텐츠를 분해 → 일반 라우팅                     | vision-translator (백업 역할)       |

**직접 `@` 호출:**

```
@闪电侠 help me write a hello world
@工具人 search all TODOs in the project
@视觉翻译官 analyze this screenshot
```

**원클릭 명령어:**

| 명령어          | 시나리오                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | 간단한 작업, 번역, 구성 변경                   |
| `/moa-medium`   | 기능 모듈, 버그 수정, 단일 파일 리팩토링      |
| `/moa-flagship` | 시스템 아키텍처, 대규모 리팩토링               |
| `/moa-frontend` | UI 복원, CSS, 스크린샷 수정                    |
| `/moa-describe` | 스크린샷/이미지를 텍스트로 변환               |

### 자동 라우팅

컨시어지-라우터는 이제 키워드 분석을 기반으로 작업 유형을 자동 감지합니다:

- **탐색 작업**: "분석하다", "비교하다", "이해하다", "조사하다" → 탐색 프롬프트 + 탐색형 수용 사양
- **실행 작업**: "수정하다", "추가하다", "구현하다", "배포하다" → 실행 프롬프트 + 손실 방지 규칙
- **작업 유형（`taskType=explore|execute`）은 门童 메타데이터로 통합 계층에 인라인되며, 통합 계층이 유형에 맞는 수용 사양을 생성합니다**

---

## 아키텍처

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Tool layer     Opinion layer       Fusion layer
             Flash + MiMo + Qwen3.7 Plus   3 parallel opinions take the best
             (~80% calls)   (~18% calls)        (~2% calls)
```

**도구 계층** (Flash + MiMo + Qwen3.7 Plus) — 코드 읽기, 파일 검색, 스크린샷을 텍스트로 변환. 저렴하고 빠르며 자유롭게 호출하세요.

**의견 계층** (Qwen / Kimi / Flash) — 다양한 관점에서의 계획. 세 가지 의견이 자연스럽게 "합의 + 분기" 구조를 형성합니다.

**융합 계층** (Kimi K3 / Kimi K2.7 / Flash lead / DeepSeek V4 Pro 백업) — 합의를 유지하고 분기에서 최선을 선택하며, 융합 실패 시 DeepSeek V4 Pro로 백업합니다. 플래그십 융합은 현재 **Kimi K3** (2.8T 파라미터, 1M 컨텍스트, 최상급 프론티어 모델)에서 실행되고 있으며, MoA의 품질 한계를 선두로 끌어올리고 있습니다.

> ⚠️ 아래의 호출-볼륨 비율 (~80% / ~18% / ~2%)는 **설계 목표**이며, 측정된 통계가 아닙니다. 실제 비율은 작업 복잡성에 따라 다릅니다.

### 구조화된 출력

의견 및 융합 에이전트는 `---section-name---` 마커를 사용합니다. 의견 계층: `---記憶層---` + `---方案---` + `---红线---`. 융합 계층: `---融合方案---` + `---分歧裁决---` + `---白名单---` + `---红线---` + `---验收标准---`. 하류 파싱 및 라인 수용 검증을 가능하게 합니다.

### 반부정행위 방지

구현 에이전트가 절차를 간소화하지 못하도록 방지합니다: 기본 비회귀, 금지된 행동 (테스트 건너뛰기/모의/삭제), 숨겨진 점검, 구현 차이 검사, 손실 방지 (항목당 3회 재시도, 비회귀 시 롤백). 수용 기준 템플릿은 `.moa/界线.json`에 있습니다.

## 22 에이전트

> 영어 이름은 논리적 역할을 나타내며; 괄호 안의 중국어는 `.opencode/agents/` 아래의 **정확한 파일 이름**입니다 — `@`로 호출합니다 (예: `@门童`).

```
concierge-router (门童, Flash)
 │
 ├── 도구 계층 ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) 코드 읽기, 파일 검색
 │   tool-handler-mimo (工具人-mimo, MiMo) [숨김] 신뢰할 수 있는 파일 읽기 (백업 + 병렬)
 │   swift             (闪电侠, Flash    ) 간단한 작업을 한 번에
 │   vision-translator (视觉翻译官, Qwen3.7 Plus ) 스크린샷/UI→텍스트; 로그/다이어그램/문서→분해
 │
 ├── 잔여물 추출기  (残差提取者,  Flash     ) 계획 간의 분기를 분석
 ├── 신뢰도 평가자 (置信度评估者, DeepSeek V4 Flash    ) 융합 결과 신뢰도 평가
 │
 ├── 중간 의견 계층 ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) 엔지니어링 관점
 │   mid-creative (中级·创意, Qwen3.7 Plus) 창의적 관점
 │   mid-coder    (中级·码农, Flash     ) 실용적 관점
 │   mid-fuse     (中级·融合, Kimi K2.7 Code) 세 가지 계획 융합 [max_tokens: 16384]
 │
 ├── 플래그십 의견 계층 ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) 최상위 아키텍처
 │   flag-plan (旗舰·规划, DeepSeek V4 Flash     ) 구조화된 계획
 │   flag-eng  (旗舰·工程, DeepSeek V4 Flash  ) 대규모 구현
 │   flag-fuse (旗舰·融合, Kimi K3     ) 세 가지 아키텍처 계획 융합 [max_tokens: 16384]
 │   flag-impl (旗舰·执行, Flash) [숨김] 융합된 계획에 따라 구현
 │   flag-qa   (旗舰·质检, DeepSeek Pro) 계획 검토 + 코드 수용 [max_tokens: 16384]
 │
 └── 프론트엔드 의견 계층 ─────────────────────────────────────────────
     fe-restore (前端·还原, Qwen3.7 Plus       ) 픽셀 완벽 UI 복원
     fe-logic   (前端·逻辑, Qwen3.7 Plus) 컴포넌트 아키텍처 및 상태 관리
     fe-motion  (前端·动效, MiMo-Pro   ) 상호작용 및 모션
     fe-lead    (前端·总工, DeepSeek V4 Flash    ) 세 가지 프론트엔드 계획 중 최선 선택 [max_tokens: 16384]
```

백업 에이전트 (위의 라우터 체인에 포함되지 않으며, 융합 실패 시에만 호출됨):

```
fallback (融合·保底, DeepSeek V4 Pro) — 동일한 잔여물 강화 융합, flag-fuse / mid-fuse / fe-lead 실패 시 사용

## 내결함성 설계


---
## 검증
```bash
# Layer 0 — 정적 체크 (자동, 0 토큰)
pwsh .opencode/tests/T0-static-verify.ps1
# 세 개의 레이어를 동시에 실행
pwsh .opencode/tests/run-all.ps1
```

`.opencode/tests/` 아래에 체크 스크립트: Layer 0 자동（T0 정적 / T1 README 일관성 / T3 권한 보안）, Layer 1–2는 OpenCode 내 수동 가이드 체크리스트입니다. 자세히: [검증](docs/README-details.md#verification).

---

## 문서

| 문서 | 내용 |
| ---- | ---- |
| [docs/README-details.md](docs/README-details.md) | 내결함성 설계 · 비용 · 보안 · 검증 · FAQ |
| [docs/opencode-moa.md](docs/opencode-moa.md) | 전체 배포 매뉴얼 — AI 자동 배포 설치 프로그램 본체 |

---
## 기여

PR 및 이슈를 환영합니다. [CONTRIBUTING.md](CONTRIBUTING.md)를 참조하세요.

---


## 라이센스

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

