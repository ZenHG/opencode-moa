# OpenCode MoA

> 🌐 Idiomas: Inglés · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Caliente (2026-07):** fusión insignia actualizada a **Kimi K3** — 2.8T parámetros, 1M contexto, modelo de frontera de primer nivel. El techo de calidad de MoA ahora está al frente del grupo.

> 🔥 **Caliente (2026-07):** lanzamiento oficial de **DeepSeek-V4-Flash-0731** — capacidades de agente muy reforzadas, superando al más caro **GLM-5.2** (Terminal Bench 82.7 vs 81.0, DeepSWE 54.4 vs 46.2, Toolathlon 70.3 vs 59.9). Lo barato vence a lo caro — la capa Flash de MoA (herramientas + opiniones) mucho más fuerte al mismo costo.

> 🔄 **Auto-mejora de larga duración (24h sin supervisión):** tu proyecto iterando solo durante días — sin olvidar, sin parar, sin repetir. El portero se activa cada ronda, pasa por toda la tubería MoA y guarda el progreso en disco. Empieza con un comando: **[▶ Empezar →](longloop/docs/LongLoop.md)**

> salida estructurada, criterios de aceptación por límites, anti-trampa, enrutamiento automático. Ver [CHANGELOG](CHANGELOG.md).

> **Un punto de entrada a la conversación, 22 modelos especializados colaborando automáticamente. Tareas simples utilizan Flash (barato), tareas complejas llaman a la insignia (caro). Reducción de costos de hasta ~90% (vs todo-insignia) cuando las tareas simples dominan la carga de trabajo y las llamadas a la insignia se minimizan — los ahorros reales dependen de la mezcla de tareas; calidad del código significativamente mejorada.**

<!-- ARCH-IMG -->
![OpenCode MoA Architecture](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA es un paquete de configuración de Mezcla de Agentes para OpenCode. Permite que múltiples modelos **piensen sobre el mismo problema simultáneamente**, luego se fusionen en una calidad de salida que un solo modelo no puede alcanzar. No necesitas cambiar de herramientas, escribir código o tener un cupo de API — solo coloca los archivos en tu proyecto y reinicia OpenCode.

**22 agentes · 5 comandos · 3 habilidades · despliegue en 30 segundos**

---


## ¿Por qué necesitas esto?

Por defecto, OpenCode utiliza un solo modelo de principio a fin. Cambiar un carácter y diseñar una arquitectura de sistema utilizan el mismo aviso, misma temperatura, mismo contexto. Sin división del trabajo.

**Tres problemas:**

1. **Costo fuera de control** — las tareas simples también utilizan el modelo caro, la factura mensual se mantiene alta
2. **Cuello de botella de calidad** — un solo modelo tiene solo una forma de pensar, fácilmente atrapado en puntos ciegos
3. **Sin tolerancia a fallos** — si el modelo falla, se congela, sin respaldo

**Solución de MoA:**

```

You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max)  ─── plan from the architect's view
    ├─ flag-plan (DeepSeek V4 Flash    )  ─── plan from the planning view
    ├─ flag-eng  (DeepSeek V4 Flash)  ─── plan from the implementer's view
    └─ flag-fuse (Kimi K3    )  ─── take the best of each, one optimal solution
```

<!-- COST-IMG -->
![Cost down up to 90%](.github/moa-cost.png)
<!-- /COST-IMG -->

Tres planes independientes de tres modelos diferentes forman naturalmente una estructura de "consenso + divergencia". El modelo de fusión identifica qué es consenso y lo mantiene, y toma lo mejor donde divergen — algo que un solo modelo no puede hacer.

---


## Requisitos previos

### Requerido

| Requisito            | Comando de verificación         | Notas                                                                                                                                                                                                  |
| -------------------- | ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode instalado    | `opencode --version`            | **>= 1.3.4** (soporte a nivel de agente `reasoningEffort`/`hidden`/`task`; el proveedor `openai-compatible` pasa razonamiento de forma transparente, no se necesita `forceReasoning`), [instalar](https://opencode.ai/install) |
| Plan OpenCode Go      | consola opencode.ai             | [Suscribirse](https://opencode.ai/auth), primer mes $5, luego $10/mes                                                                                                                                  |
| Git instalado         | `git --version`                 | Utilizado para clonar el repositorio                                                                                                                                                                   |
| Clave API OpenCode Go | creada en consola opencode.ai    | Creada en la consola Zen (opencode.ai)                                                                                                                                                                 |

### Opcional (necesario para scripts de instalación)

| Requisito         | Comando de verificación | Notas                                                                     |
| ----------------- | ----------------------- | ------------------------------------------------------------------------- |
| PowerShell Core   | `pwsh --version`       | necesario para LongLoop e install.ps1 — **el 5.1 incluido con Windows no basta** (instala PS7: `winget install Microsoft.PowerShell`, o MSI automático: `powershell -File install.ps1 -InstallPwsh`), macOS `brew install powershell`, Linux ver [docs de LongLoop](longloop/docs/LongLoop.md) |
| jq                | `jq --version`         | necesario para install.sh para fusión JSON, `apt install jq` / `brew install jq` |
| Node.js >= 14     | `node --version`       | necesario para el servidor MCP moa-loop (`longloop/server.js`) |

> No hay problema si no tienes pwsh/jq — puedes usar el Método 1 (despliegue automático de IA) o el Método 3 (fusión manual).

### Escritorio vs CLI

- **CLI**: todos los métodos soportados
- **Escritorio**: el Método 1 (despliegue automático de IA) es el más conveniente; los Métodos 2/3 requieren operación de terminal primero

> ⚠️ **La ruta de clave a nivel del sistema es fácil de colocar incorrectamente** — ortografía correcta en "Leer antes de desplegar" a continuación. Una ruta incorrecta lleva a que el despliegue parezca exitoso pero todos los agentes no logran conectarse.

> ⚠️ **Leer antes de desplegar: no coloques incorrectamente la ruta de clave**
> Coloca el proveedor + clave en el **`opencode.json` a nivel del proyecto** (por defecto, auto-contenido) o en la **ruta compartida a nivel del sistema** — elige **una**.
> Si usas a nivel del sistema, la ruta correcta es:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**no** `%APPDATA%\opencode`)
>   Una ruta incorrecta a nivel del sistema lleva a "el despliegue tiene éxito pero todos los agentes no pueden conectarse".

---


## Despliegue en 30 segundos

### Método 1: Despliegue automático de IA (recomendado)

1. Clona el repositorio: `git clone https://github.com/ZenHG/opencode-moa.git`
2. En OpenCode (abierto en tu proyecto), envía:

> Desplegar todos los 22 agentes, 5 comandos y 3 habilidades del repositorio opencode-moa en el proyecto actual

3. La IA lee los archivos fuente reales (`.opencode/`, `opencode.json`) y crea todos los archivos automáticamente. **Reinicia OpenCode** cuando termines.

> El repositorio en sí es el instalador — la IA despliega desde los archivos fuente reales, sin manual que descargar ni mantener.

### Método 2: script de instalación de un clic (versión de script · amigable con CLI)

```bash
# clona el repositorio
git clone https://github.com/ZenHG/opencode-moa.git

# ingresa a tu directorio de proyecto
cd your-project

# copia el directorio .opencode, la configuración .moa y el directorio longloop del repositorio
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .
cp -r ../opencode-moa/longloop/ .

# ejecuta el script de instalación (fusión automática de configuración, mantiene tu clave API)
# Windows（instala automáticamente dependencias faltantes: -InstallPwsh / -InstallNode / -InstallDeps todo a la vez）:
pwsh ../opencode-moa/install.ps1
# Linux/macOS（si falta jq, usa --install-jq para instalarlo）:
bash ../opencode-moa/install.sh --install-jq
```

> El script de instalación hace una copia de seguridad automática de tu `opencode.json` original, solo fusionando la configuración de MoA mientras mantiene tu proveedor y clave API.
> 

### Personaliza cualquier modelo

MoA es una **plantilla genérica** — el modelo de cada agente es solo un ID que puedes cambiar. Cada archivo de agente comienza con:

```yaml
model: opencode-go/<model-id>
```

Para cambiar un modelo, edita esa línea en `.opencode/agents/<agent>.md` a cualquier `provider/model-id` al que tengas acceso (por ejemplo, `opencode-go/kimi-k2.7-code`, `opencode-go/deepseek-v4-flash`). No se necesita reinstalación. Mezcla y combina libremente — la plantilla no te ata a nada.

### Método 3: instalación manual

```bash
# 1. clona el repositorio
git clone https://github.com/ZenHG/opencode-moa.git

# 2. copia el directorio .opencode y la configuración .moa
cp -r opencode-moa/.opencode/ your-project/
cp -r opencode-moa/.moa/ your-project/

# 3. fusiona manualmente opencode.json (¡NO reemplaces directamente!)
# abre opencode.json, fusiona las secciones permission.task y agent de MoA
# mantén tu configuración de proveedor y modelo existente
```

> ⚠️ **No** uses `cat >>` para agregar — corrompe el formato JSON. **No** reemplaces directamente tampoco — perderás tu clave API.
> 

### ¿Cómo saber si el despliegue tuvo éxito?

1. Después de reiniciar OpenCode, presiona `Tab` para ciclar entre agentes (cliente de escritorio de Windows: `Ctrl+.` también funciona) y ver "门童"
2. Escribe `@工具人` y responde
3. Ejecuta el script de verificación: `pwsh .opencode/tests/T0-static-verify.ps1` (generado por el Bloque manual 5.5 durante el despliegue), se espera que todos PASEN (FAIL=0; con clave a nivel del sistema, WARN también cuenta como pase)

### Retroceso de un clic

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
# restaura manualmente tu opencode.json (el script de instalación hace una copia de seguridad automática de un archivo .bak)
```

---

## ¿Cómo usar?

**No aprendas nada — solo habla.** El conserje-enrutador juzga automáticamente la complejidad de la tarea y despacha la cadena de agentes correspondiente.

| Lo que dices                          | Lo que hace el conserje-enrutador                                   | Agentes utilizados                     |
| -------------------------------------- | ------------------------------------------------------------------ | -------------------------------------- |
| "renombrar esta variable"              | juzgado como una tarea simple                                      | swift (Flash)                          |
| "escribir un módulo de autenticación de usuario" | la capa de herramientas reúne → 3 paralelos de nivel medio → fusionar | manejador de herramientas + trío de nivel medio + fusión |
| "diseñar una arquitectura de microservicios" | la capa de herramientas reúne → 3 paralelos insignia → fusionar → implementar → QA | 6 agentes de cadena completa            |
| "restaurar la interfaz de usuario de esta captura de pantalla" | 3 expertos en frontend en paralelo → el líder elige el mejor       | cuarteto de frontend                   |
| mensaje con captura de pantalla        | el traductor de visión convierte a texto → enrutamiento normal     | traductor de visión                    |
| mensaje con registro de errores / diagrama / contenido complejo | el traductor de visión descompone el contenido → enrutamiento normal | traductor de visión (rol de respaldo)  |

**Llamadas directas `@`:**

```
@闪电侠 ayúdame a escribir un hola mundo
@工具人 busca todos los TODOs en el proyecto
@视觉翻译 analiza esta captura de pantalla
```

**Comandos de un clic:**

| Comando         | Escenario                                       |
| --------------- | ----------------------------------------------- |
| `/moa-quick`    | tarea simple, traducción, cambio de configuración |
| `/moa-medium`   | módulo de función, corrección de errores, refactorización de un solo archivo |
| `/moa-flagship` | arquitectura del sistema, gran refactorización  |
| `/moa-frontend` | restauración de UI, CSS, corrección de captura de pantalla |
| `/moa-describe` | captura de pantalla/imágen a texto             |

### Enrutamiento automático

El conserje-enrutador ahora detecta automáticamente el tipo de tarea basado en el análisis de palabras clave:

- **Tareas de exploración**: "analizar", "comparar", "entender", "investigar" → aviso de exploración + especificaciones de aceptación de exploración
- **Tareas de ejecución**: "arreglar", "agregar", "implementar", "desplegar" → aviso de ejecución + reglas de stop-loss
- **El tipo de tarea aparece en la salida de la tubería**: `[Tipo: Ejecutar]` o `[Tipo: Explorar]`

---


## Arquitectura

```
                      conserje-enrutador (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Capa de herramientas  Capa de opiniones  Capa de fusión
             Flash + MiMo + Qwen3.7 Plus         3 opiniones en paralelo eligen la mejor
             (~80% llamadas)      (~18% llamadas)    (~2% llamadas)
```

**Capa de herramientas** (Flash + MiMo + Qwen3.7 Plus) — leer código, buscar archivos, captura de pantalla a texto. Barato y rápido, llama libremente.

**Capa de opiniones** (Qwen / Kimi / Flash) — planes desde diferentes perspectivas. Tres opiniones forman naturalmente una estructura de "consenso + divergencia".

**Capa de fusión** (Kimi K3 / Kimi K2.7 / Flash lead / DeepSeek V4 Pro de respaldo) — mantener el consenso, tomar lo mejor en la divergencia, con respaldo a DeepSeek V4 Pro si la fusión falla. La fusión insignia ahora funciona en **Kimi K3** (2.8T parámetros, 1M contexto, modelo de frontera de primer nivel) — llevando el techo de calidad de MoA a la vanguardia.

> ⚠️ Las proporciones de volumen de llamadas a continuación (~80% / ~18% / ~2%) son **objetivos de diseño**, no estadísticas medidas. Las proporciones reales varían según la complejidad de la tarea.

### Salida estructurada

Los agentes de opinión y fusión utilizan marcadores `---nombre-sección---`. Capa de opiniones: `---記憶層---` + `---方案---` + `---红线---`. Capa de fusión: `---融合方案---` + `---分歧裁决---` + `---白名单---` + `---红线---` + `---验收标准---`. Permite el análisis posterior y la verificación de aceptación por límites.

### Anti-trampa

Previene que los agentes de implementación tomen atajos: no regresión base, acciones prohibidas (saltar/burlar/eliminar pruebas), controles ocultos, verificación de diferencias de implementación, stop-loss (3 reintentos por elemento, retroceso en regresión). Plantilla de criterios de aceptación en `.moa/界线.json`.



## 22 Agentes

> El nombre en inglés es el rol lógico; el chino entre paréntesis es el **nombre de archivo exacto** bajo `.opencode/agents/` — los llamas con `@` (por ejemplo, `@门童`).

```
conserje-enrutador (门童, Flash)
 │
 ├── Capa de herramientas ─────────────────────────────────────────────
 │   manejador de herramientas      (工具人, Flash    ) leer código, buscar archivos
 │   manejador de herramientas-mimo (工具人-mimo, MiMo) [oculto]  lectura de archivos confiable (respaldo + paralelo)
 │   swift             (闪电侠, Flash    ) tareas simples de un solo golpe
 │   traductor de visión (视觉翻译, Qwen3.7 Plus ) captura de pantalla/UI→texto; registros/diagramas/documentos→descomposición
 │
 ├── extractor de residuos  (残差提取,  Flash     ) analizar divergencia entre planes
 ├── evaluador de confianza (置信度评估, DeepSeek V4 Flash    ) evaluar la confianza en el resultado de la fusión
 │
 ├── Capa de opinión de nivel medio ─────────────────────────────────────────────
 │   medio-ing      (中级·工程, Kimi K2.6 ) vista de ingeniería
 │   medio-creativo (中级·创意, Qwen3.7 Plus) vista creativa
 │   medio-coder    (中级·码农, Flash     ) vista pragmática
 │   medio-fusión     (中级·融合, Kimi K2.7 Code) fusionar tres planes [max_tokens: 16384]
 │
 ├── Capa de opinión insignia ─────────────────────────────────────────────
 │   insignia-arquitectura (旗舰·架构, Qwen3.7 Max ) arquitectura de alto nivel
 │   insignia-plan (旗舰·规划, DeepSeek V4 Flash     ) planificación estructurada
 │   insignia-ing  (旗舰·工程, DeepSeek V4 Flash  ) implementación a gran escala
 │   insignia-fusión (旗舰·融合, Kimi K3     ) fusionar tres planes de arquitectura [max_tokens: 16384]
 │   insignia-impl (旗舰·执行, Flash) [oculto]  implementar según el plan fusionado
 │   insignia-qa   (旗舰·质检, DeepSeek Pro) revisión del plan + aceptación de código [max_tokens: 16384]
 │
 └── Capa de opinión de frontend ─────────────────────────────────────────────
     fe-restaurar (前端·还原, Qwen3.7 Plus       ) restauración de UI pixel-perfect
     fe-lógica   (前端·逻辑, Qwen3.7 Plus) arquitectura de componentes y gestión de estado
     fe-moción  (前端·动效, MiMo-Pro   ) interacción y movimiento
     fe-líder    (前端·总工, DeepSeek V4 Flash    ) elegir el mejor de tres planes de frontend [max_tokens: 16384]
```

Agente de respaldo (no en la cadena de enrutador anterior, llamado solo cuando la fusión falla):

```
respaldo (融合·保底, DeepSeek V4 Pro) — misma fusión mejorada por residuos, utilizada cuando fallan flag-fuse / mid-fuse / fe-lead

---
## Verificación
```bash
# Capa 0 — verificación estática (automática, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# ejecutar las tres capas a la vez
pwsh .opencode/tests/run-all.ps1
```

Scripts de verificación en `.opencode/tests/`: la Capa 0 es automática (T0 estático / T1 coherencia del README / T3 seguridad de permisos); las Capas 1–2 son listas de verificación guiadas dentro de OpenCode. Detalles: [Verificación](docs/README-details.md#verification).

---

## Documentación

| Documento | Contenido |
| ---- | ---- |
| [docs/README-details.md](docs/README-details.md) | Diseño de tolerancia a fallos · costo · seguridad · verificación · FAQ |

---
## Contribuyendo

Se aceptan PRs e Issues. Consulta [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Licencia

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

