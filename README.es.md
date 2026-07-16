# OpenCode MoA

> 🌐 Idiomas / Languages: [English](README.md) · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · Español · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> **Un único punto de conversación donde 22 modelos especializados colaboran automáticamente. Las tareas simples usan Flash (barato) y las tareas complejas llaman al flagship (caro). Coste reducido hasta ~90% (frente a usar flagship en todo) cuando las tareas simples dominan y las llamadas flagship se minimizan — el ahorro real depende del tipo de tareas, con una mejora notable de la calidad del código.**

![OpenCode MoA](.github/opengraph.png)

OpenCode MoA es un paquete de configuración Mixture of Agents para OpenCode. Permite que varios modelos **piensen sobre el mismo problema simultáneamente** y luego fusiona sus resultados en una calidad difícil de alcanzar con un único modelo. No necesitas cambiar de herramienta, escribir código ni preparar una cuota de API: coloca los archivos en tu proyecto y reinicia OpenCode.

**22 agents · 5 commands · 3 skills · despliegue en 30 segundos**

> Nota: los nombres de comandos, agents, modelos, rutas y bloques de código se conservan en inglés para que puedan copiarse y ejecutarse directamente.

---

## ¿Por qué lo necesitas?

Por defecto, OpenCode usa un único modelo de principio a fin. Cambiar un carácter y diseñar una arquitectura de sistema usan el mismo prompt, la misma temperature y el mismo context. No hay división del trabajo.

**Tres problemas:**

1. **Coste fuera de control** — las tareas simples también usan el modelo caro y la factura mensual se mantiene alta
2. **Cuello de botella de calidad** — un único modelo tiene una sola forma de pensar y puede quedarse en puntos ciegos
3. **Sin tolerancia a fallos** — si el modelo falla, todo se bloquea; no hay fallback

**La solución de MoA:**

```
You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max) ─── plan from the architect's view
    ├─ flag-plan (GLM        ) ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 ) ─── plan from the implementer's view
    └─ flag-fuse (Qwen3.7 Max) ─── take the best of each, one optimal solution
```

Tres planes independientes de tres modelos diferentes forman de manera natural una estructura de “consenso + divergencia”. El modelo de fusión identifica qué es consenso y lo conserva, y toma lo mejor allí donde hay divergencias; algo que un único modelo no puede hacer.

---

## Requisitos previos

### Obligatorio

| Requirement         | Check command                  | Notes                                                                                                                                                                                                 |
| ------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installed  | `opencode --version`           | **>= 1.3.4** (agent-level `reasoningEffort`/`hidden`/`task` support; `openai-compatible` provider transparently passes reasoning, no `forceReasoning` needed), [install](https://opencode.ai/install) |
| OpenCode Go plan    | opencode.ai console            | [Subscribe](https://opencode.ai/auth), first month $5, then $10/month                                                                                                                                 |
| Git installed       | `git --version`                | Used to clone the repo                                                                                                                                                                                |
| OpenCode Go API Key | created in opencode.ai console | Created in the Zen console (opencode.ai)                                                                                                                                                              |

### Opcional (necesario para los scripts de instalación)

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

## Despliegue en 30 segundos

### Método 1: despliegue automático con IA (recomendado)

1. Descarga [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Sube ese documento a OpenCode y envía:

> Deploy all 22 agents, 5 commands, and 3 skills from this manual into the current project

3. La IA crea todos los archivos automáticamente. **Reinicia OpenCode** al terminar.

> No necesitas crear archivos manualmente. El manual de despliegue es el instalador.

### Método 2: script de instalación de un clic (versión script · cómodo para CLI)

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

> El script de instalación hace una copia de seguridad automática de tu `opencode.json` original y solo fusiona la configuración de MoA, conservando tu provider y API key.
> 
> Nota: este método copia tal cual el `.opencode/` incluido en el repo; sus agents tienen **nombres visibles en chino**. Si quieres agents con nombres en inglés (para poder usar `@english-name`), usa el Método 1.

### Método 3: instalación manual

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

### ¿Cómo saber si el despliegue funcionó?

1. Después de reiniciar OpenCode, pulsa `Tab` para recorrer los agents (en el cliente desktop de Windows también funciona `Ctrl+.`) y verifica que aparece “concierge-router”
2. Escribe `@tool-handler` y confirma que responde
3. Ejecuta el script de verificación: `pwsh .opencode/tests/T0-static-verify.ps1` (generado por el Block 5.5 manual durante el despliegue); se espera all PASS (FAIL=0; con key de nivel sistema, WARN también cuenta como pass)

### Reversión con un clic

```bash
rm -rf your-project/.opencode/
# manually restore your opencode.json (the install script auto-backs up a .bak file)
```

---

## ¿Cómo se usa?

**No tienes que aprender nada: simplemente habla.** El concierge-router juzga automáticamente la complejidad de la tarea y despacha la cadena de agents correspondiente.

| What you say                         | What the concierge-router does                                   | Agents used                         |
| ------------------------------------ | ---------------------------------------------------------------- | ----------------------------------- |
| "rename this variable"               | judged as a simple task                                          | swift (Flash)                       |
| "write a user auth module"           | tool layer gathers → 3 mid-tier parallel → fuse                  | tool-handler + mid-tier trio + fuse |
| "design a microservice architecture" | tool layer gathers → 3 flagship parallel → fuse → implement → QA | full-chain 6 agents                 |
| "restore this screenshot's UI"       | 3 frontend experts parallel → lead picks best                    | frontend quartet                    |
| message with screenshot              | vision-translator converts to text → normal routing              | vision-translator                   |

**Llamadas directas con `@`:**

```
@swift help me write a hello world
@tool-handler search all TODOs in the project
@flag-arch design a message queue solution
```

**Commands de un clic:**

| Command         | Scenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | simple task, translation, config change        |
| `/moa-medium`   | function module, bug fix, single-file refactor |
| `/moa-flagship` | system architecture, large refactor            |
| `/moa-frontend` | UI restore, CSS, screenshot fix                |
| `/moa-describe` | screenshot/image to text                       |

---

## Arquitectura

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

> ⚠️ Las proporciones de volumen de llamadas (~80% / ~18% / ~2%) son **objetivos de diseño**, no estadísticas medidas. Las proporciones reales varían según la complejidad de la tarea.

---

## 22 Agents

```
concierge-router (Flash)
 │
 ├── Tool layer ─────────────────────────────────────────────
 │   tool-handler     (Flash       ) read code, search files [+ material self-check]
 │   tool-handler-mimo (MiMo        ) reliable file read (fallback + parallel) [hidden]
 │   swift            (Flash       ) simple tasks in one shot
 │   vision-translator (MiMo        ) screenshot/UI/error image to text
 │
 ├── Residual extractor (Flash)    NEW: analyze divergence between plans
 ├── Confidence assessor (DS Pro)  NEW: assess fusion result confidence
 │
 ├── Mid-tier opinion layer ─────────────────────────────────────────────
 │   mid-eng          (MiniMax M3  ) engineering view
 │   mid-creative     (DeepSeek Pro) creative view
 │   mid-coder        (Flash       ) pragmatic view
 │   mid-fuse         (Kimi        ) fuse three plans [max_tokens: 16384]
 │
 ├── Flagship opinion layer ─────────────────────────────────────────────
 │   flag-arch        (Qwen3.7 Max ) top-level architecture
 │   flag-plan        (GLM         ) structured planning
 │   flag-eng         (MiniMax M3  ) large-scale implementation
 │   flag-fuse        (Qwen3.7 Max ) fuse three architecture plans [max_tokens: 16384]
 │   flag-impl        (Flash       ) implement per fused plan [hidden]
 │   flag-qa          (DeepSeek Pro) plan review + code acceptance [max_tokens: 16384]
 │
 └── Frontend opinion layer ─────────────────────────────────────────────
     fe-restore       (MiMo        ) pixel-perfect UI restore
     fe-logic         (Qwen3.7 Plus) component architecture & state mgmt
     fe-motion        (MiMo-Pro    ) interaction & motion
     fe-lead          (GLM-5.2     ) pick best of three frontend plans [max_tokens: 16384]
```

---

## Diseño de tolerancia a fallos

### Cadena de fallback de la capa de herramientas

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

### Fallback de la capa de fusión

Si el agent principal de fusión falla (STUCK / ERROR_PROVIDER / timeout / resultado vacío), concierge-router cae automáticamente a `@融合·保底` (DeepSeek V4 Pro):

```
旗舰·融合 (Qwen3.7 Max) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
中级·融合 (Kimi) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
前端·总工 (GLM-5.2) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
```

El agent de fallback usa el mismo proceso de fusión mejorado con residuales.

### Aislamiento de permisos MCP

Los agents de la opinion layer tienen prohibido leer código directamente (`read: deny` + `bash: deny`), lo que evita que eludan la tool layer para obtener material por su cuenta:

- Tool layer: puede leer código y buscar archivos (tiene acceso `read`/`bash`)
- Opinion layer: `read: deny` + `bash: deny`; solo puede planificar basándose en material de la tool layer
- Fusion layer: misma restricción; solo puede fusionar basándose en las tres opiniones

> Nota: este proyecto no configura servidores MCP. El término “MCP permission isolation” se refiere a restricciones de herramientas a nivel de agent (`read: deny` / `bash: deny`), no a aislamiento a nivel de servidor MCP.

### Fallback sin material

Cuando se llama a la opinion layer pero no hay material (la tool layer falló por completo), pregunta al usuario:

- Elegir “give plan directly” → razonamiento lógico puro basado en la descripción del requisito (sin leer código)
- Elegir “wait for tool layer” → salida WAITING y reintento cuando la tool layer se recupere

### Clasificación de errores

La tool layer emite una categoría de error clara al fallar, en lugar de reintentar a ciegas:

- `ERROR_PROVIDER` — server 502/503/timeout
- `ERROR_AUTH` — auth failure
- `ERROR_UNKNOWN` — other errors

---

## Coste

### Por qué se ahorra ~90%

MoA se estima con una mezcla ponderada por volumen de llamadas: ~80% tool-layer Flash, ~18% mid-tier, ~2% flagship. El precio unitario efectivo de salida se estima con los precios por unidad de la tabla de costes:

> **Importante**: Las proporciones 80/18/2 son una **distribución esperada del volumen de llamadas diseñada por la arquitectura**, no proporciones de coste medidas. El uso real depende del tipo y complejidad de las tareas.

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

Los límites se definen por valor en dólares. Los modelos baratos (Flash) pueden usarse más a menudo; los caros (GLM), menos.

### Cuota mensual por capa

| Layer      | Model           | Unit price (in/out per 1M) | Monthly quota | Call frequency      |
| ---------- | --------------- | -------------------------- | ------------- | ------------------- |
| Tool layer | Flash           | $0.14 / $0.28              | 158,150       | ~80%                |
| Tool layer | MiMo-V2.5       | $0.14 / $0.28              | 150,400       | (use freely)        |
| Opinion    | MiniMax M3      | $0.30 / $1.20              | 16,000        | ~18%                |
| Opinion    | DeepSeek V4 Pro | $1.74 / $3.48              | 17,150        |                     |
| Opinion    | Qwen3.7 Plus    | $0.40 / $1.60              | 21,600        |                     |
| Fusion     | Kimi K2.7 Code  | $0.95 / $4.00              | 9,250         | ~2% (mid-tier fuse) |
| Fusion     | Qwen3.7 Max     | $2.50 / $7.50              | 4,770         | ~2% (flagship fuse) |
| Fusion     | GLM-5.2         | $1.40 / $4.40              | 4,300         | ~2% (frontend lead) |

> Todos los model IDs son solo declaraciones; puedes sustituirlos por cualquier modelo que prefieras.

### Después de alcanzar el límite

- **Free model fallback** — cuando Go alcanza el límite, puedes seguir usando modelos gratuitos
- **Zen balance fallback** — activa “use balance” en la consola; tras el límite de Go, se usará automáticamente el saldo Zen

### Modelos gratuitos

OpenCode Zen ofrece modelos gratuitos como último recurso:

| Model                  | Trait                           |
| ---------------------- | ------------------------------- |
| DeepSeek V4 Flash Free | fast, but limited context       |
| MiMo-V2.5 Free         | better quality, but may be slow |
| North Mini Code Free   | provided by Cohere              |
| Nemotron 3 Ultra Free  | NVIDIA free endpoint            |

> ⚠️ Límites de los modelos gratuitos: ventana de contexto menor, respuestas posiblemente más lentas, los datos pueden usarse para entrenamiento y son gratuitos por tiempo limitado.

---

## Seguridad

| Protection                 | Effect                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Global catch-all           | undeclared tool call → popup confirm                                                                                                                                                          |
| Agent permission isolation | each agent can only use allowed tools                                                                                                                                                         |
| MCP permission isolation   | opinion layer forbidden from reading code (read: deny / bash: deny), prevents bypassing tool layer (project has no MCP server configured; "MCP" here refers to agent-level tool restrictions) |
| Task whitelist             | concierge-router can only call declared agents                                                                                                                                                |
| Fallback chain             | tool layer fails → ask user → wait/skip/free model                                                                                                                                            |
| One-click rollback         | delete `.opencode/` to restore                                                                                                                                                                |

---

## Modelos locales

Permite mezclar modelos locales como Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Consulta el Apéndice A de [`docs/opencode-moa.md`](docs/opencode-moa.md).

---

## Verificación

Después del despliegue, ejecuta la comprobación estática (requiere `pwsh`):

```bash
pwsh .opencode/tests/T0-static-verify.ps1
# expected: all PASS / FAIL=0 (with system-level key, WARN also counts as pass)
```

---

## FAQ

### Instalación

**Q: Ya tengo un opencode.json, ¿se sobrescribirá?**
A: No. El script de instalación solo fusiona la configuración `permission`, `agent`, `default_agent` de MoA y conserva tus `provider`, `model`, etc. El archivo original se guarda automáticamente como `.bak.timestamp`.

**Q: Windows no tiene el comando `cp`, ¿qué hago?**
A: Usa `Copy-Item` o `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: ¿Puedo instalar sin pwsh/jq?**
A: Sí. Usa el Método 1 (despliegue automático con IA) o el Método 3 (merge manual de configuración).

**Q: ¿Cómo instalo en la app de escritorio?**
A: El Método 1 es el más cómodo: arrastra `docs/opencode-moa.en.md` al cuadro de chat y deja que la IA haga el despliegue automático. Los Métodos 2/3 requieren usar antes una terminal (CMD/PowerShell/Terminal).

### Uso

**Q: ¿No ves “concierge-router”?**
A: Revisa las tres comprobaciones en “Despliegue en 30 segundos → ¿Cómo saber si el despliegue funcionó?”: `opencode.json` en la raíz del proyecto, 22 archivos .md en `.opencode/agents/`, y cambiar con `Tab` tras reiniciar (en Windows desktop también funciona `Ctrl+.`).

**Q: `@tool-handler` no responde?**
A: Confirma que `.opencode/agents/tool-handler.md` existe y que el formato del frontmatter es correcto.

**Q: Error “model not found”?**
A: El formato de Model ID debe ser `provider/model-id` (por ejemplo `opencode-go/kimi-k2.7-code`). Registra el provider correspondiente en el archivo de configuración (system-level `~/.config/opencode/opencode.json` o `opencode.json` del proyecto), y luego usa `/models` dentro del TUI para ver los modelos disponibles.

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
A: Consulta “Diseño de tolerancia a fallos → Cadena de fallback”: MoA pide elegir A. esperar unos minutos / B. saltar la tool layer y llamar directamente a la opinion layer (mayor coste).

**Q: ¿Dónde están los modelos gratuitos?**
A: Consulta “Coste → Modelos gratuitos”: usa `/models` para abrir la lista de modelos y elige uno con etiqueta “Free” (en Windows desktop también funciona `Ctrl+'`) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Los modelos gratuitos tienen contexto limitado, pueden ser más lentos y los datos pueden usarse para entrenamiento.

---

## Contribuir

PRs e Issues son bienvenidos. Consulta [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
