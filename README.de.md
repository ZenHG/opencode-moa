# OpenCode MoA

> 🌐 Sprachen / Languages: [English](README.md) · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · Deutsch

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Neu (2026-07):** Flagship-Fusion auf **Kimi K3** aktualisiert — 2,8T Parameter, 1M Kontext, top-Tier Frontier-Modell. OpenCode Go Kontingent bis 7/24 verdoppelt (140 → 280 / 5h, danach zurück auf 140).

> **Ein einziger Gesprächseinstieg, bei dem 22 spezialisierte Modelle automatisch zusammenarbeiten. Einfache Aufgaben nutzen Flash (günstig), komplexe Aufgaben rufen nur dann das flagship (teuer) auf. Die Kosten sinken um bis zu ~90% (gegenüber durchgehend flagship), während die Codequalität deutlich steigt.**

![OpenCode MoA](.github/opengraph.png)

OpenCode MoA ist ein Mixture-of-Agents-Konfigurationspaket für OpenCode. Es lässt mehrere Modelle **gleichzeitig über dasselbe Problem nachdenken** und fusioniert die Ergebnisse zu einer Qualität, die ein einzelnes Modell kaum erreicht. Du musst kein Tool wechseln, keinen Code schreiben und kein API-Kontingent vorbereiten: Lege die Dateien in dein Projekt und starte OpenCode neu.

**22 agents · 5 commands · 3 skills · 30-Sekunden-Deployment**

> Hinweis: Command-, Agent-, Modellnamen, Pfade und Codeblöcke bleiben absichtlich auf Englisch, damit sie direkt kopiert und ausgeführt werden können.

---

## Warum brauchst du das?

Standardmäßig verwendet OpenCode von Anfang bis Ende ein einziges Modell. Eine Zeichenänderung und der Entwurf einer Systemarchitektur nutzen denselben Prompt, dieselbe Temperature und denselben Context. Es gibt keine Arbeitsteilung.

**Drei Probleme:**

1. **Kosten außer Kontrolle** — einfache Aufgaben nutzen ebenfalls das teure Modell, die Monatskosten bleiben hoch
2. **Qualitätsengpass** — ein einzelnes Modell hat nur eine Denkweise und bleibt leicht in blinden Flecken stecken
3. **Keine Fehlertoleranz** — fällt das Modell aus, bleibt alles hängen; es gibt keinen Fallback

**MoAs Lösung:**

```
You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max) ─── plan from the architect's view
    ├─ flag-plan (GLM        ) ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 ) ─── plan from the implementer's view
    └─ flag-fuse (Kimi K3) ─── take the best of each, one optimal solution
```

Drei unabhängige Pläne von drei verschiedenen Modellen bilden natürlich eine Struktur aus „Konsens + Divergenz“. Das Fusionsmodell erkennt den Konsens und behält ihn bei; bei Abweichungen wählt es die besten Teile — etwas, das ein einzelnes Modell nicht leisten kann.

---

## Voraussetzungen

### Erforderlich

| Requirement         | Check command                  | Notes                                                                                                                                                                                                 |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installed  | `opencode --version`           | **>= 1.3.4** (agent-level `reasoningEffort`/`hidden`/`task` support; `openai-compatible` provider transparently passes reasoning, no `forceReasoning` needed), [install](https://opencode.ai/install) |
| OpenCode Go plan    | opencode.ai console            | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                                                                                                                                 |
| Git installed       | `git --version`                | Used to clone the repo                                                                                                                                                                                |
| OpenCode Go API Key | created in opencode.ai console | Created in the Zen console (opencode.ai)                                                                                                                                                              |

### Optional (für Installationsskripte erforderlich)

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

## 30-Sekunden-Deployment

### Methode 1: KI-Auto-Deployment (empfohlen)

1. Descarga [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Sube ese documento a OpenCode y envía:

> Deploy all 22 agents, 5 commands, and 3 skills from this manual into the current project

3. La IA crea todos los archivos automáticamente. **Reinicia OpenCode** al terminar.

> Es müssen keine Dateien manuell erstellt werden. Das Deployment-Handbuch ist selbst der Installer.

### Methode 2: Ein-Klick-Installationsskript (Skriptversion · CLI-freundlich)

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

> Das Installationsskript erstellt automatisch ein Backup deiner ursprünglichen `opencode.json` und merged nur die MoA-Konfiguration, während dein provider und dein API key erhalten bleiben.
> 
> Nota: este método copia tal cual el `.opencode/` incluido en el repo; sus agents tienen **nombres visibles en chino**. Si quieres agents con nombres en inglés (para poder usar `@english-name`), usa el Método 1.

### Methode 3: Manuelle Installation

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

### Woran erkennt man ein erfolgreiches Deployment?

1. After restarting OpenCode, press `Tab` to cycle agents (Windows desktop client: `Ctrl+.` also works) and see "concierge-router"
2. Type `@tool-handler` and confirm it responds
3. Run the verification script: `pwsh .opencode/tests/T0-static-verify.ps1` (generated by manual Block 5.5 during deploy), expected all PASS (FAIL=0; with system-level key, WARN also counts as pass)

### Ein-Klick-Rollback

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

---

## Wie benutzt man es?

**Nichts lernen — einfach sprechen.** Der concierge-router bewertet automatisch die Aufgabenkomplexität und dispatcht die passende Agent-Kette.

| What you say                         | What the concierge-router does                                   | Agents used                         |
| ------------------------------------ | ---------------------------------------------------------------- | ----------------------------------- |
| "rename this variable"               | judged as a simple task                                          | swift (Flash)                       |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | tool-handler + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents                 |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet                    |
| message with screenshot              | vision-translator converts to text → normal routing              | vision-translator                   |

**Direkte `@`-Aufrufe:**

```
@swift help me write a hello world
@tool-handler search all TODOs in the project
@flag-arch design a message queue solution
```

**Ein-Klick-Commands:**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

---

## Architektur

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

> ⚠️ Die Call-Volume-Verhältnisse (~80% / ~18% / ~2%) sind **Designziele** und keine gemessenen Statistiken. Die tatsächlichen Verhältnisse hängen von der Aufgabenkomplexität ab.

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
  │   flag-fuse (旗舰·融合, Kimi K3     ) fuse three architecture plans [max_tokens: 16384]
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

## Fehlertoleranzdesign

### Fallback-Kette der Tool-Schicht

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

### Fallback der Fusion-Schicht

Si el agent principal de fusión falla (STUCK / ERROR_PROVIDER / timeout / resultado vacío), concierge-router cae automáticamente a `@融合·保底` (DeepSeek V4 Pro):

```
flag-fuse (旗舰·融合, Kimi K3) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
mid-fuse (中级·融合, Kimi) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
fe-lead (前端·总工, GLM-5.2) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
```

Der Fallback-Agent verwendet denselben residual-enhanced Fusion-Prozess.

### MCP-Berechtigungsisolation

Den Agents der Opinion Layer ist es verboten, Code direkt zu lesen (`read: deny` + `bash: deny`). Dadurch können sie die Tool Layer nicht umgehen, um selbst Material abzurufen:

- Tool layer: puede leer código y buscar archivos (tiene acceso `read`/`bash`)
- Opinion layer: `read: deny` + `bash: deny`; solo puede planificar basándose en material de la tool layer
- Fusion layer: misma restricción; solo puede fusionar basándose en las tres opiniones

> Hinweis: Dieses Projekt konfiguriert keine MCP-Server. Der Begriff „MCP permission isolation“ bezieht sich hier auf Tool-Einschränkungen auf Agent-Ebene (`read: deny` / `bash: deny`), nicht auf Isolation auf MCP-Server-Ebene.

### Fallback ohne Material

Cuando se llama a la opinion layer pero no hay material (la tool layer falló por completo), pregunta al usuario:

- Elegir “give plan directly” → razonamiento lógico puro basado en la descripción del requisito (sin leer código)
- Elegir “wait for tool layer” → salida WAITING y reintento cuando la tool layer se recupere

### Fehlerklassifikation

La tool layer emite una categoría de error clara al fallar, en lugar de reintentar a ciegas:

- `ERROR_PROVIDER` — server 502/503/timeout
- `ERROR_AUTH` — auth failure
- `ERROR_UNKNOWN` — other errors

---

## Kosten

### Warum ~90% gespart werden

MoA wird über einen nach Call-Volume gewichteten Mix betrachtet: ~80% Tool-Layer Flash, ~18% Mid-Tier, ~2% Flagship. Der effektive Output-Stückpreis wird anhand der Stückpreise in der Kostentabelle geschätzt:

> **Wichtig**: Die 80/18/2-Verhältnisse sind eine von der Architektur entworfene **erwartete Call-Volume-Verteilung**, keine gemessenen Kostenanteile. Die tatsächliche Nutzung hängt von Aufgabentypen und Komplexität ab.

| Layer      | Share | Output unit price /1M                                             | Weighted |
| ---------- | ----- | ----------------------------------------------------------------- | -------- |
| Tool layer | 80%   | $0.28                                                             | $0.224   |
| Mid tier   | 18%   | ~$2.10 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 / Kimi K2.7 $4.00 mid-fuse avg) | $0.378   |
| Flagship   | 2%    | ~$6.00 (Qwen/GLM/MiniMax ~$4-7 + Kimi K3 $15.00 flag-fuse)    | $0.12    |

Precio unitario efectivo combinado ≈ **$0.72 / 1M**. Comparado con “all-flagship GLM $7.50” → alrededor del 10% → **~90% de ahorro**; comparado con “all-mid-tier DeepSeek Pro $3.48” → alrededor del 21% → **~79% de ahorro**. La afirmación “save 90%” corresponde al valor real frente al baseline flagship.

### OpenCode-Go-Plan

MoA se basa en el plan [OpenCode Go](https://opencode.ai/docs/zh-cn/go/), **primer mes $5 y después $10/mes**.

**Límites de uso:**

| Time window   | Quota |
| ------------- | ----- |
| Every 5 hours | $12   |
| Weekly        | $30   |
| Monthly       | $60   |

Limits werden als Dollarwert definiert. Günstige Modelle (Flash) können häufiger genutzt werden, teure Modelle (GLM) seltener.

### Monatliches Kontingent pro Schicht

| Layer      | Model           | Unit price (in/out per 1M) | Monthly quota | Call frequency      |
| ---------- | --------------- | -------------------------- | ------------- | ------------------- |
| Tool layer | Flash           | $0.14 / $0.28              | 158,150       | ~80%                |
| Tool layer | MiMo-V2.5       | $0.14 / $0.28              | 150,400       | (use freely)        |
| Opinion    | MiniMax M3      | $0.30 / $1.20              | 16,000        | ~18%                |
| Opinion    | DeepSeek V4 Pro | $1.74 / $3.48              | 17,150        |                     |
| Opinion    | Qwen3.7 Plus    | $0.40 / $1.60              | 21,600        |                     |
| Fusion     | Kimi K2.7 Code  | $0.95 / $4.00              | 9,250         | ~2% (mid-tier fuse) |
| Fusion     | Kimi K3         | $3.00 / $15.00             | 280             | ~2% (flagship fuse) |
| Fusion     | GLM-5.2         | $1.40 / $4.40              | 4,300         | ~2% (frontend lead) |

> Todos los model IDs son solo declaraciones; puedes sustituirlos por cualquier modelo que prefieras.

![OpenCode Go quota per 5h](.github/quota-chart-en.svg)

### Nach Erreichen des Limits

- **Free model fallback** — cuando Go alcanza el límite, puedes seguir usando modelos gratuitos
- **Zen balance fallback** — activa “use balance” en la consola; tras el límite de Go, se usará automáticamente el saldo Zen

### Kostenlose Modelle

OpenCode Zen ofrece modelos gratuitos como último recurso:

| Model                  | Trait                           |
| ---------------------- | ------------------------------- |
| DeepSeek V4 Flash Free | fast, but limited context       |
| MiMo-V2.5 Free         | better quality, but may be slow |
| North Mini Code Free   | provided by Cohere              |
| Nemotron 3 Ultra Free  | NVIDIA free endpoint            |

> ⚠️ Límites de los modelos gratuitos: ventana de contexto menor, respuestas posiblemente más lentas, los datos pueden usarse para entrenamiento y son gratuitos por tiempo limitado.

---

## Sicherheit

| Protection                 | Effect                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                                                                                                                                                          |
| Agent permission isolation | each agent can only use allowed tools                                                                                                                                                         |
| MCP permission isolation   | opinion layer forbidden from reading code (read: deny / bash: deny), prevents bypassing tool layer (project has no MCP server configured; "MCP" here refers to agent-level tool restrictions) |
| Task whitelist             | concierge-router can only call declared agents                                                                                                                                                |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model                                                                                                                                            |
| One-click rollback         | delete `.opencode/` to restore                                                                                                                                                                |

---

## Lokale Modelle

Permite mezclar modelos locales como Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Siehe Anhang A in [`docs/opencode-moa.md`](docs/opencode-moa.md).

---

## Verifizierung

Después del despliegue, ejecuta la comprobación estática (requiere `pwsh`):

```bash
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)
```

---

## FAQ

### Installation

**Q: Ya tengo un opencode.json, ¿se sobrescribirá?**
A: Nein. Das Installationsskript merged nur die MoA-Konfiguration `permission`, `agent`, `default_agent` und behält deine vorhandenen `provider`, `model` usw. bei. Die Originaldatei wird automatisch als `.bak.timestamp` gesichert.

**Q: Windows no tiene el comando `cp`, ¿qué hago?**
A: Verwende `Copy-Item` oder `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: ¿Puedo instalar sin pwsh/jq?**
A: Ja. Verwende Methode 1 (KI-Auto-Deployment) oder Methode 3 (manuelles Zusammenführen der Konfiguration).

**Q: ¿Cómo instalo en la app de escritorio?**
A: Methode 1 ist am bequemsten: Ziehe `docs/opencode-moa.en.md` in das Chatfeld und lasse die KI das Auto-Deployment durchführen. Methoden 2/3 erfordern vorher die Nutzung eines Terminals (CMD/PowerShell/Terminal).

### Nutzung

**Q: ¿No ves “concierge-router”?**
A: Sieh dir die drei Prüfungen unter „30-Sekunden-Deployment → Woran erkennt man ein erfolgreiches Deployment?“ an: `opencode.json` im Projekt-Root, 22 .md-Dateien unter `.opencode/agents/`, und nach dem Neustart mit `Tab` wechseln (im Windows-Desktop-Client funktioniert auch `Ctrl+.`).

**Q: `@tool-handler` no responde?**
A: Confirma que `.opencode/agents/tool-handler.md` existe y que el formato del frontmatter es correcto.

**Q: Error “model not found”?**
A: Das Format der Model ID sollte `provider/model-id` sein (z. B. `opencode-go/kimi-k2.7-code`). Registriere den entsprechenden provider in der Konfigurationsdatei (system-level `~/.config/opencode/opencode.json` oder projektbezogene `opencode.json`) und verwende anschließend `/models` im TUI, um verfügbare Modelle zu sehen.

**Q: ¿Cómo vuelvo al agent build/plan original?**
A: Pulsa `Tab` para cambiar (en Windows desktop también funciona `Ctrl+.`), o escribe `/build`, `/plan`. MoA no afecta a los agents integrados.

**Q: Quiero usar mi propio modelo, no el plan Go.**
A: Solo cambia el campo `model` del agent:

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q: ¿Puedo borrar el repo después de desplegar?**
A: Sí. MoA ya está copiado en el directorio `.opencode/` de tu proyecto; el repo original puede eliminarse.

**Q: ¿Cómo despliego en varios proyectos?**
A: Despliega cada proyecto por separado. `.opencode/` es configuración a nivel de proyecto y no afecta a otros proyectos.

### Fallback

**Q: Was, wenn die gesamte Tool-Layer ausgefallen ist?**
A: Siehe „Fehlertoleranzdesign → Fallback-Kette“: MoA fragt den Nutzer, ob er A. einige Minuten warten oder B. die Tool Layer überspringen und direkt die Opinion Layer aufrufen möchte (höhere Kosten).

**Q: Wo sind die kostenlosen Modelle?**
A: Siehe „Kosten → Kostenlose Modelle“: Verwende `/models`, um die Modellliste zu öffnen, und wähle ein Modell mit dem Label “Free” (im Windows-Desktop-Client funktioniert auch `Ctrl+'`) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free usw.). Kostenlose Modelle haben begrenzten Kontext, können langsamer sein, und Daten können für Training verwendet werden.

---

## Verifikation

Das Repo enthält drei Prüfskripte in `.opencode/tests/`. Layer 0 ist vollständig automatisch; die Layer 1–2 sind geführte Checklisten, die Sie in OpenCode durchgehen.

```bash
# Layer 0 — statische Prüfung (automatisch, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)

# alle drei Layer auf einmal ausführen
pwsh .opencode/tests/run-all.ps1
```

| Script | Layer | Was es tut | Modus |
| ------ | ----- | ------------ | ---- |
| `T0-static-verify.ps1` | 0 | Prüft Dateistruktur, agent/command/skill-Anzahl, README-Anker, Key-Pfad-Korrektheit | Automatisch |
| `T1-behavioral-guide.ps1` | 1 | Druckt eine Schritt-für-Schritt-Checkliste für Routing-/Opinion-/Fusion-Verhalten | Manuell (in OpenCode) |
| `T2-moa-smoke-guide.ps1` | 2 | Druckt eine Smoke-Test-Checkliste für `/moa-*` Befehle end-to-end | Manuell (in OpenCode) |
| `run-all.ps1` | 0–2 | Führt T0 aus und druckt dann die T1/T2-Checklisten | Gemischt |

---

## Maintainer-Tooling (für Endnutzer nicht nötig)

Die folgenden Dateien sind für **Repo-Maintainer**, nicht zum Deployment von MoA. Endnutzer können sie ignorieren.

| Datei | Zweck |
| ---- | ------- |
| `deploy-sync.ps1` | Nur für Maintainer — synchronisiert das Repo zu GitHub und lädt den `opencode-moa`-Skill zu SkillHub hoch. Unterstützt `-SkipGit` / `-SkipSkillHub` / `-DryRun`. |
| `scripts/hooks/pre-commit` | Lokaler git-Hook-Hinweis: warnt beim Stagen einer `CHANGELOG.md`-Änderung (auto-release bei Push auf `master`). |
| `scripts/hooks/pre-push` | Lokaler git-Hook-Hinweis: bestätigt die Version vor Push einer `CHANGELOG.md`-Änderung auf `master`; in nicht-interaktiven/CI-Umgebungen automatisch. |

> Diese Hooks werden nicht automatisch installiert. Wenn Sie Hinweise wollen, symlinken Sie sie nach `.git/hooks/`.

---

## Mitwirken

PRs und Issues sind willkommen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
