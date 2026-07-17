# OpenCode MoA

> 🌐 Langues / Languages: [English](README.md) · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · Français · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> **Un point d’entrée conversationnel unique où 22 modèles spécialisés collaborent automatiquement. Les tâches simples utilisent Flash (peu coûteux), tandis que les tâches complexes appellent le flagship (coûteux). Les coûts peuvent baisser jusqu’à ~90% (par rapport au tout-flagship), avec une qualité de code nettement améliorée.**

![OpenCode MoA](.github/opengraph.png)

OpenCode MoA est un paquet de configuration Mixture of Agents pour OpenCode. Il permet à plusieurs modèles de **réfléchir simultanément au même problème**, puis fusionne leurs résultats pour atteindre une qualité difficile à obtenir avec un seul modèle. Inutile de changer d’outil, d’écrire du code ou de prévoir un quota API : place les fichiers dans ton projet et redémarre OpenCode.

**22 agents · 5 commands · 3 skills · déploiement en 30 secondes**

> Note : les noms de commands, agents, modèles, chemins et blocs de code restent en anglais afin de pouvoir être copiés et exécutés directement.

---

## Pourquoi en avez-vous besoin ?

Par défaut, OpenCode utilise un seul modèle du début à la fin. Modifier un caractère et concevoir une architecture système utilisent le même prompt, la même temperature et le même context. Il n’y a pas de division du travail.

**Trois problèmes :**

1. **Coûts difficiles à maîtriser** — les tâches simples utilisent aussi le modèle coûteux, donc la facture mensuelle reste élevée
2. **Goulot d’étranglement de qualité** — un seul modèle n’a qu’une seule manière de raisonner et peut rester coincé dans ses angles morts
3. **Pas de tolérance aux pannes** — si le modèle échoue, tout se bloque; il n’y a pas de fallback

**La solution de MoA :**

```
You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max) ─── plan from the architect's view
    ├─ flag-plan (GLM        ) ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 ) ─── plan from the implementer's view
    └─ flag-fuse (Qwen3.7 Max) ─── take the best of each, one optimal solution
```

Trois plans indépendants issus de trois modèles différents forment naturellement une structure “consensus + divergence”. Le modèle de fusion identifie ce qui fait consensus et le conserve, puis sélectionne le meilleur lorsque les avis divergent — ce qu’un modèle unique ne peut pas faire.

---

## Prérequis

### Obligatoire

| Requirement         | Check command                  | Notes                                                                                                                                                                                                 |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installed  | `opencode --version`           | **>= 1.3.4** (agent-level `reasoningEffort`/`hidden`/`task` support; `openai-compatible` provider transparently passes reasoning, no `forceReasoning` needed), [install](https://opencode.ai/install) |
| OpenCode Go plan    | opencode.ai console            | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                                                                                                                                 |
| Git installed       | `git --version`                | Used to clone the repo                                                                                                                                                                                |
| OpenCode Go API Key | created in opencode.ai console | Created in the Zen console (opencode.ai)                                                                                                                                                              |

### Optionnel (nécessaire pour les scripts d’installation)

| Requirement     | Check command    | Notes                                                                     |
| --------------- | ---------------- | ------------------------------------------------------------------------- |
| PowerShell Core | `pwsh --version` | needed by install.ps1, bundled with Windows or `brew install powershell`  |
| jq              | `jq --version`   | needed by install.sh for JSON merge, `apt install jq` / `brew install jq` |

> No pwsh/jq is fine — you can use Method 1 (AI auto-deploy) or Method 3 (manual merge).

### Desktop vs CLI

- **CLI**: todos los métodos están soportados
- **Desktop**: el Método 1 (despliegue automático con IA) es el más cómodo; los Métodos 2/3 requieren operar primero en la terminal

> ⚠️ **La ruta de la clave a nivel de sistema es fácil de colocar mal** — revisa la escritura correcta en “Leer antes de desplegar”. Una ruta incorrecta provoca “deployment succeeds but all agents can't connect”.

> ⚠️ **Leer antes de desplegar: no coloques mal la ruta de la clave**
> Coloca el provider + key en el **`opencode.json` de nivel proyecto** (por defecto, autocontenido) o en la ruta compartida **de nivel sistema** — elige **una**.
> Si usas nivel sistema, la ruta correcta es:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**not** `%APPDATA%\opencode`)
>   Una ruta de sistema incorrecta provoca “deployment succeeds but all agents can't connect”.

---

## Déploiement en 30 secondes

### Méthode 1 : déploiement automatique par IA (recommandé)

1. Descarga [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Sube ese documento a OpenCode y envía:

> Deploy all 22 agents, 5 commands, and 3 skills from this manual into the current project

3. La IA crea todos los archivos automáticamente. **Reinicia OpenCode** al terminar.

> Aucun fichier n’a besoin d’être créé manuellement. Le manuel de déploiement fait lui-même office d’installateur.

### Méthode 2 : script d’installation en un clic (version script · pratique pour CLI)

```bash
# clone the repo
git clone https://github.com/ZenHG/opencode-moa.git

# enter your project directory
cd your-project

# copy the .opencode directory from the repo
cp -r ../opencode-moa/.opencode/ .

# run the install script (auto-merge config, keeps your API key)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> Le script d’installation sauvegarde automatiquement ton `opencode.json` original et ne fusionne que la configuration MoA, tout en conservant ton provider et ton API key.
> 
> Nota: este método copia tal cual el `.opencode/` incluido en el repo; sus agents tienen **nombres visibles en chino**. Si quieres agents con nombres en inglés (para poder usar `@english-name`), usa el Método 1.

### Méthode 3 : installation manuelle

```bash
# 1. clone the repo
git clone https://github.com/ZenHG/opencode-moa.git

# 2. copy the .opencode directory
cp -r opencode-moa/.opencode/ your-project/

# 3. manually merge opencode.json (do NOT replace directly!)
# open opencode.json, merge MoA's permission.task and agent sections in
# keep your existing provider and model config
```

> ⚠️ **No** uses `cat >>` para añadir contenido: corrompe el formato JSON. **No** reemplaces directamente el archivo: perderás tu API key.
> 
> Nota: este método copia tal cual el `.opencode/` incluido en el repo; sus agents tienen **nombres visibles en chino**. Si quieres agents con nombres en inglés (para poder usar `@english-name`), usa el Método 1.

### Comment vérifier que le déploiement a réussi ?

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "concierge-router"
2. Type `@tool-handler` and confirm it responds
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1` (generated by manual Block 5.5 during deploy), expected all PASS (FAIL=0; with system-level key, WARN also counts as pass)

### Retour arrière en un clic

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

---

## Comment l’utiliser ?

**Rien à apprendre — il suffit de parler.** Le concierge-router évalue automatiquement la complexité de la tâche et déclenche la chaîne d’agents correspondante.

| What you say                         | What the concierge-router does                                   | Agents used                         |
| ------------------------------------ | ---------------------------------------------------------------- | ----------------------------------- |
| "rename this variable"               | judged as a simple task                                          | swift (Flash)                       |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | tool-handler + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents                 |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet                    |
| message with screenshot              | vision-translator converts to text → normal routing              | vision-translator                   |

**Appels directs avec `@` :**

```
@swift help me write a hello world
@tool-handler search all TODOs in the project
@flag-arch design a message queue solution
```

**Commands en un clic :**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

---

## Architecture

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Tool layer     Opinion layer       Fusion layer
             Flash + MiMo   3 parallel opinions take the best
             (~80% calls)   (~18% calls)        (~2% calls)
```

**Tool layer** (Flash + MiMo) — lee código, busca archivos y convierte capturas a texto. Barato y rápido; puedes llamarlo con libertad.

**Opinion layer** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — genera planes desde distintas perspectivas. Tres opiniones forman naturalmente una estructura de “consenso + divergencia”.

**Fusion layer** (Kimi / Qwen-Max / GLM / DeepSeek Pro fallback) — conserva el consenso, toma lo mejor en las divergencias y usa DeepSeek V4 Pro como fallback si la fusión falla.

> ⚠️ Les proportions de volume d’appels (~80% / ~18% / ~2%) sont des **objectifs de conception**, et non des statistiques mesurées. Les proportions réelles varient selon la complexité de la tâche.

---

## 22 Agents

```
concierge-router (门童路由员, Flash)
 │
 ├── Tool layer ─────────────────────────────────────────────
 │   tool-handler      (工具人,      Flash ) read code, search files [+ material self-check]
 │   tool-handler-mimo (工具人-mimo, MiMo  ) reliable file read (fallback + parallel) [hidden]
 │   swift             (闪电侠,      Flash ) simple tasks in one shot
 │   vision-translator (视觉翻译官,  MiMo  ) screenshot/UI/error image to text
 │
 ├── residual-extractor  (残差提取者,  Flash     ) analyze divergence between plans
 ├── confidence-assessor (置信度评估者, DS Pro    ) assess fusion result confidence
 │
 ├── Mid-tier opinion layer ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, MiniMax M3  ) engineering view
 │   mid-creative (中级·创意, DeepSeek Pro) creative view
 │   mid-coder    (中级·码农, Flash       ) pragmatic view
 │   mid-fuse     (中级·融合, Kimi        ) fuse three plans [max_tokens: 16384]
 │
 ├── Flagship opinion layer ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) top-level architecture
 │   flag-plan (旗舰·规划, GLM         ) structured planning
 │   flag-eng  (旗舰·工程, MiniMax M3  ) large-scale implementation
 │   flag-fuse (旗舰·融合, Qwen3.7 Max ) fuse three architecture plans [max_tokens: 16384]
 │   flag-impl (旗舰·实现, Flash       ) implement per fused plan [hidden]
 │   flag-qa   (旗舰·质检, DeepSeek Pro) plan review + code acceptance [max_tokens: 16384]
 │
 └── Frontend opinion layer ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo        ) pixel-perfect UI restore
     fe-logic   (前端·逻辑, Qwen3.7 Plus) component architecture & state mgmt
     fe-motion  (前端·动效, MiMo-Pro     ) interaction & motion
     fe-lead    (前端·总工, GLM-5.2      ) pick best of three frontend plans [max_tokens: 16384]
 ```

Fallback agent (not in the router chain above, called only when fusion fails):
```
fallback (融合·保底, DeepSeek V4 Pro) — same residual-enhanced fusion, used when flag-fuse / mid-fuse / fe-lead fail
 ```

---

## Conception de tolérance aux pannes

### Chaîne de fallback de la couche outils

Si la tool layer falla, no se queda bloqueada: hace downgrade automático:

```
tool-handler (Flash) failed → immediate retry once
  → retry succeeds → return normally
  → retry fails → tool-handler-mimo (MiMo) failed → immediate retry once
    → retry succeeds → return normally
    → retry fails → ask user:
      A. wait a few minutes and retry
      B. skip tool layer, call opinion layer directly (higher cost)
      C. switch to free model
```

> La mayoría de errores del provider (502/503/timeout) son transitorios; un reintento rápido suele funcionar.

### Fallback de la couche de fusion

Si el agent principal de fusión falla (STUCK / ERROR_PROVIDER / timeout / resultado vacío), concierge-router cae automáticamente a `@融合·保底` (DeepSeek V4 Pro):

```
flag-fuse (旗舰·融合, Qwen3.7 Max) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
mid-fuse (中级·融合, Kimi) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
fe-lead (前端·总工, GLM-5.2) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
```

L’agent de fallback utilise le même processus de fusion amélioré par résidus.

### Isolation des permissions MCP

Les agents de l’opinion layer n’ont pas le droit de lire le code directement (`read: deny` + `bash: deny`), ce qui les empêche de contourner la tool layer pour récupérer eux-mêmes du matériau :

- Tool layer: puede leer código y buscar archivos (tiene acceso `read`/`bash`)
- Opinion layer: `read: deny` + `bash: deny`; solo puede planificar basándose en material de la tool layer
- Fusion layer: misma restricción; solo puede fusionar basándose en las tres opiniones

> Note : ce projet ne configure aucun serveur MCP. Le terme “MCP permission isolation” désigne ici des restrictions d’outils au niveau des agents (`read: deny` / `bash: deny`), et non une isolation au niveau des serveurs MCP.

### Fallback sans matériau

Cuando se llama a la opinion layer pero no hay material (la tool layer falló por completo), pregunta al usuario:

- Elegir “give plan directly” → razonamiento lógico puro basado en la descripción del requisito (sin leer código)
- Elegir “wait for tool layer” → salida WAITING y reintento cuando la tool layer se recupere

### Classification des erreurs

La tool layer emite una categoría de error clara al fallar, en lugar de reintentar a ciegas:

- `ERROR_PROVIDER` — server 502/503/timeout
- `ERROR_AUTH` — auth failure
- `ERROR_UNKNOWN` — other errors

---

## Coût

### Pourquoi économiser ~90%

MoA s’estime avec un mélange pondéré par volume d’appels : ~80% tool-layer Flash, ~18% mid-tier, ~2% flagship. Le prix unitaire effectif en sortie est estimé à partir des prix unitaires du tableau des coûts :

> **Important** : les proportions 80/18/2 sont une **distribution attendue du volume d’appels conçue par l’architecture**, et non des proportions de coût mesurées. L’usage réel dépend des types de tâches et de leur complexité.

| Layer      | Share | Output unit price /1M                                             | Weighted |
| ---------- | ----- | ----------------------------------------------------------------- | -------- |
| Tool layer | 80%   | $0.28                                                             | $0.224   |
| Opinion    | 18%   | ~$2.00 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 avg) | $0.36    |
| Fusion     | 2%    | ~$5.30 (Kimi $4.00 / Qwen Max $7.50 / GLM $4.40 avg)              | $0.106   |

Precio unitario efectivo combinado ≈ **$0.69 / 1M**. Comparado con “all-flagship GLM $7.50” → alrededor del 9% → **~90% de ahorro**; comparado con “all-mid-tier DeepSeek Pro $3.48” → alrededor del 20% → **~80% de ahorro**. La afirmación “save 90%” corresponde al valor real frente al baseline flagship.

### Plan OpenCode Go

MoA se basa en el plan [OpenCode Go](https://opencode.ai/docs/zh-cn/go/), **primer mes $5 y después $10/mes**.

**Límites de uso:**

| Time window   | Quota |
| ------------- | ----- |
| Every 5 hours | $12   |
| Weekly        | $30   |
| Monthly       | $60   |

Les limites sont définies en valeur monétaire. Les modèles peu coûteux (Flash) peuvent être utilisés plus souvent, les modèles coûteux (GLM) moins souvent.

### Quota mensuel par couche

| Layer      | Model           | Unit price (in/out per 1M) | Monthly quota | Call frequency      |
| ---------- | --------------- | -------------------------- | ------------- | ------------------- |
| Tool layer | Flash           | $0.14 / $0.28              | 158,150       | ~80%                |
| Tool layer | MiMo-V2.5       | $0.14 / $0.28              | 150,400       | (use freely)        |
| Opinion    | MiniMax M3      | $0.30 / $1.20              | 16,000        | ~18%                |
| Opinion    | DeepSeek V4 Pro | $1.74 / $3.48              | 17,150        |                     |
| Opinion    | Qwen3.7 Plus    | $0.40 / $1.60              | 21,600        |                     |
| Fusion     | Kimi K2.7 Code  | $0.95 / $4.00              | 9,250         | ~2% (mid-tier fuse) |
| Fusion     | Kimi K3         | $3.00 / $15.00             | 280 (2x from 7/24) | ~2% (flagship fuse) |
| Fusion     | GLM-5.2         | $1.40 / $4.40              | 4,300         | ~2% (frontend lead) |

> Todos los model IDs son solo declaraciones; puedes sustituirlos por cualquier modelo que prefieras.

![OpenCode Go quota per 5h](.github/quota-chart-en.svg)

### Après avoir atteint la limite

- **Free model fallback** — cuando Go alcanza el límite, puedes seguir usando modelos gratuitos
- **Zen balance fallback** — activa “use balance” en la consola; tras el límite de Go, se usará automáticamente el saldo Zen

### Modèles gratuits

OpenCode Zen ofrece modelos gratuitos como último recurso:

| Model                  | Trait                           |
| ---------------------- | ------------------------------- |
| DeepSeek V4 Flash Free | fast, but limited context       |
| MiMo-V2.5 Free         | better quality, but may be slow |
| North Mini Code Free   | provided by Cohere              |
| Nemotron 3 Ultra Free  | NVIDIA free endpoint            |

> ⚠️ Límites de los modelos gratuitos: ventana de contexto menor, respuestas posiblemente más lentas, los datos pueden usarse para entrenamiento y son gratuitos por tiempo limitado.

---

## Sécurité

| Protection                 | Effect                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                                                                                                                                                          |
| Agent permission isolation | each agent can only use allowed tools                                                                                                                                                         |
| MCP permission isolation   | opinion layer forbidden from reading code (read: deny / bash: deny), prevents bypassing tool layer (project has no MCP server configured; "MCP" here refers to agent-level tool restrictions) |
| Task whitelist             | concierge-router can only call declared agents                                                                                                                                                |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model                                                                                                                                            |
| One-click rollback         | delete `.opencode/` to restore                                                                                                                                                                |

---

## Modèles locaux

Permite mezclar modelos locales como Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Consulte l’Annexe A de [`docs/opencode-moa.md`](docs/opencode-moa.md).

---

## Vérification

Le dépôt fournit trois scripts de vérification dans `.opencode/tests/`. La Couche 0 est entièrement automatique ; les Couches 1–2 sont des checklists guidées à suivre dans OpenCode.

```bash
# Couche 0 — vérification statique (automatique, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)

# lance les trois couches d'un coup
pwsh .opencode/tests/run-all.ps1
```

| Script | Couche | What it does | Mode |
| ------ | ----- | ------------ | ---- |
| `T0-static-verify.ps1` | 0 | Checks file structure, agent/command/skill counts, README anchors, key-path correctness | Automatic |
| `T1-behavioral-guide.ps1` | 1 | Prints a step-by-step checklist for routing / opinion / fusion behavior | Manual (in OpenCode) |
| `T2-moa-smoke-guide.ps1` | 2 | Prints a smoke-test checklist for `/moa-*` commands end-to-end | Manual (in OpenCode) |
| `run-all.ps1` | 0–2 | Runs T0 then prints the T1/T2 guided checklists | Mixed |

---

## FAQ

### Installation

**Q: Ya tengo un opencode.json, ¿se sobrescribirá?**
A : Non. Le script d’installation ne fusionne que la configuration `permission`, `agent`, `default_agent` de MoA et conserve tes `provider`, `model`, etc. Le fichier original est automatiquement sauvegardé sous `.bak.timestamp`.

**Q: Windows no tiene el comando `cp`, ¿qué hago?**
A : Utilise `Copy-Item` ou `xcopy` :

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: ¿Puedo instalar sin pwsh/jq?**
A : Oui. Utilise la Méthode 1 (déploiement automatique par IA) ou la Méthode 3 (fusion manuelle de configuration).

**Q: ¿Cómo instalo en la app de escritorio?**
A : La Méthode 1 est la plus pratique : fais glisser `docs/opencode-moa.en.md` dans la zone de chat et laisse l’IA effectuer le déploiement automatique. Les Méthodes 2/3 nécessitent d’utiliser d’abord un terminal (CMD/PowerShell/Terminal).

### Utilisation

**Q: ¿No ves “concierge-router”?**
A : Consulte les trois vérifications dans « Déploiement en 30 secondes → Comment vérifier que le déploiement a réussi ? » : `opencode.json` à la racine du projet, 22 fichiers .md sous `.opencode/agents/`, puis bascule avec `Tab` après redémarrage (sur le client desktop Windows, `Ctrl+.` fonctionne aussi).

**Q: `@tool-handler` no responde?**
A: Confirma que `.opencode/agents/tool-handler.md` existe y que el formato del frontmatter es correcto.

**Q: Error “model not found”?**
A : Le format du Model ID doit être `provider/model-id` (par exemple `opencode-go/kimi-k2.7-code`). Enregistre le provider correspondant dans le fichier de configuration (system-level `~/.config/opencode/opencode.json` ou `opencode.json` du projet), puis utilise `/models` dans le TUI pour voir les modèles disponibles.

**Q: ¿Cómo vuelvo al agent build/plan original?**
A: Pulsa `Tab` para cambiar (en Windows desktop también funciona `Ctrl+.`), o escribe `/build`, `/plan`. MoA no afecta a los agents integrados.

**Q: Quiero usar mi propio modelo, no el plan Go.**
A: Solo cambia el campo `model` del agent:

```yaml
# .opencode/agents/mid-eng.md
model: anthropic/claude-sonnet-4-20250514
```

**Q: ¿Puedo borrar el repo después de desplegar?**
A: Sí. MoA ya está copiado en el directorio `.opencode/` de tu proyecto; el repo original puede eliminarse.

**Q: ¿Cómo despliego en varios proyectos?**
A: Despliega cada proyecto por separado. `.opencode/` es configuración a nivel de proyecto y no afecta a otros proyectos.

### Fallback

**Q: Toda la tool layer está caída, ¿qué hago?**
A : Voir « Conception de tolérance aux pannes → Chaîne de fallback » : MoA demande à l’utilisateur de choisir A. attendre quelques minutes / B. ignorer la tool layer et appeler directement l’opinion layer (coût plus élevé).

**Q: ¿Dónde están los modelos gratuitos?**
A : Consulte « Coût → Modèles gratuits » : utilise `/models` pour ouvrir la liste des modèles et choisis-en un avec l’étiquette “Free” (sur le client desktop Windows, `Ctrl+'` fonctionne aussi) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Les modèles gratuits ont un contexte limité, peuvent être plus lents et les données peuvent être utilisées pour l’entraînement.

---


## Outils de maintenance (inutiles pour les utilisateurs finaux)

Les fichiers suivants sont pour les **mainteneurs du dépôt**, pas pour déployer MoA. Les utilisateurs finaux peuvent les ignorer.

| Fichier | Objectif |
| ---- | ------- |
| `deploy-sync.ps1` | Réservé aux mainteneurs — synchronise le dépôt avec GitHub et publie le skill `opencode-moa` sur SkillHub. Supporte `-SkipGit` / `-SkipSkillHub` / `-DryRun`. |
| `scripts/hooks/pre-commit` | Rappel de hook git local : avertit quand vous stagez un changement `CHANGELOG.md` (auto-release au push sur `master`). |
| `scripts/hooks/pre-push` | Rappel de hook git local : confirme la version avant de pusher des changements `CHANGELOG.md` vers `master` ; proceed automatiquement en environnement non interactif/CI. |

> Ces hooks ne s'installent pas automatiquement. Pour les rappels, créez un symlink dans .git/hooks/.

---
## Contribuer

Les PRs et Issues sont les bienvenues. Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
