# OpenCode MoA

> 🌐 Idiomas: Inglés · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Caliente (2026-07):** fusión insignia actualizada a **Kimi K3** — 2.8T parámetros, 1M contexto, modelo de frontera de primer nivel. El techo de calidad de MoA ahora está al frente del grupo.

> **v0.0.15:** salida estructurada, criterios de aceptación congelados, anti-trampa, enrutamiento automático. Ver [CHANGELOG](CHANGELOG.md).

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
    ├─ flag-plan (GLM 5.2    )  ─── plan from the PM's view
    ├─ flag-eng  (MiniMax M3 )  ─── plan from the implementer's view
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
| PowerShell Core   | `pwsh --version`       | necesario para install.ps1, incluido con Windows o `brew install powershell`  |
| jq                | `jq --version`         | necesario para install.sh para fusión JSON, `apt install jq` / `brew install jq` |

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

1. Descarga [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Sube ese documento en OpenCode y envía:

> Desplegar todos los 22 agentes, 5 comandos y 3 habilidades de este manual en el proyecto actual

3. La IA crea todos los archivos automáticamente. **Reinicia OpenCode** cuando termines.

> No es necesario crear manualmente ningún archivo. El manual de despliegue es en sí mismo el instalador.

### Método 2: script de instalación de un clic (versión de script · amigable con CLI)

```bash
# clona el repositorio
git clone https://github.com/ZenHG/opencode-moa.git

# ingresa a tu directorio de proyecto
cd your-project

# copia el directorio .opencode y la configuración .moa del repositorio
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .

# ejecuta el script de instalación (fusión automática de configuración, mantiene tu clave API)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> El script de instalación hace una copia de seguridad automática de tu `opencode.json` original, solo fusionando la configuración de MoA mientras mantiene tu proveedor y clave API.
> 
> Nota: este método copia el `.opencode/` empaquetado del repositorio tal cual — sus agentes tienen **nombres de visualización en chino**. Si deseas agentes con nombres en inglés (para que puedas `@nombre-en-ingles`), utiliza el Método 1 en su lugar.

### Personaliza cualquier modelo

MoA es una **plantilla genérica** — el modelo de cada agente es solo un ID que puedes cambiar. Cada archivo de agente comienza con:

```yaml
model: opencode-go/<model-id>
```

Para cambiar un modelo, edita esa línea en `.opencode/agents/<agent>.md` a cualquier `provider/model-id` al que tengas acceso (por ejemplo, `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). No se necesita reinstalación. Mezcla y combina libremente — la plantilla no te ata a nada.

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
> Nota: este método copia el `.opencode/` empaquetado del repositorio tal cual — sus agentes tienen **nombres de visualización en chino**. Si deseas agentes con nombres en inglés (para que puedas `@nombre-en-ingles`), utiliza el Método 1 en su lugar.

### ¿Cómo saber si el despliegue tuvo éxito?

1. Después de reiniciar OpenCode, presiona `Tab` para ciclar entre agentes (cliente de escritorio de Windows: `Ctrl+.` también funciona) y ver "concierge-router"
2. Escribe `@tool-handler` y responde
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
@swift ayúdame a escribir un hola mundo
@tool-handler busca todos los TODOs en el proyecto
@flag-arch diseña una solución de cola de mensajes
```

**Comandos de un clic:**

| Comando         | Escenario                                       |
| --------------- | ----------------------------------------------- |
| `/moa-quick`    | tarea simple, traducción, cambio de configuración |
| `/moa-medium`   | módulo de función, corrección de errores, refactorización de un solo archivo |
| `/moa-flagship` | arquitectura del sistema, gran refactorización  |
| `/moa-frontend` | restauración de UI, CSS, corrección de captura de pantalla |
| `/moa-describe` | captura de pantalla/imágen a texto             |

### Enrutamiento automático (v0.0.15)

El conserje-enrutador ahora detecta automáticamente el tipo de tarea basado en el análisis de palabras clave:

- **Tareas de exploración**: "analizar", "comparar", "entender", "investigar" → aviso de exploración + criterios de aceptación congelados
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
             Flash + MiMo         3 opiniones en paralelo eligen la mejor
             (~80% llamadas)      (~18% llamadas)    (~2% llamadas)
```

**Capa de herramientas** (Flash + MiMo) — leer código, buscar archivos, captura de pantalla a texto. Barato y rápido, llama libremente.

**Capa de opiniones** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — planes desde diferentes perspectivas. Tres opiniones forman naturalmente una estructura de "consenso + divergencia".

**Capa de fusión** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro de respaldo) — mantener el consenso, tomar lo mejor en la divergencia, con respaldo a DeepSeek V4 Pro si la fusión falla. La fusión insignia ahora funciona en **Kimi K3** (2.8T parámetros, 1M contexto, modelo de frontera de primer nivel) — llevando el techo de calidad de MoA a la vanguardia.

> ⚠️ Las proporciones de volumen de llamadas a continuación (~80% / ~18% / ~2%) son **objetivos de diseño**, no estadísticas medidas. Las proporciones reales varían según la complejidad de la tarea.

### Salida estructurada

Los agentes de opinión y fusión utilizan marcadores `---nombre-sección---`. Capa de opiniones: `---memoria---` + `---plan---` + `---NO---`. Capa de fusión: estructura completa con metadatos, consenso, plan, lista de NO y criterios de aceptación. Permite el análisis posterior y la verificación de aceptación congelada.

### Anti-trampa (v0.0.15)

Previene que los agentes de implementación tomen atajos: no regresión base, acciones prohibidas (saltar/burlar/eliminar pruebas), controles ocultos, verificación de diferencias de implementación, stop-loss (3 reintentos por elemento, retroceso en regresión). Plantilla de criterios de aceptación en `.moa/acceptance-template.json`.



## 22 Agentes

> El nombre en inglés es el rol lógico; el chino entre paréntesis es el **nombre de archivo exacto** bajo `.opencode/agents/` — los llamas con `@` (por ejemplo, `@门童路由员`).

```
conserje-enrutador (门童路由员, Flash)
 │
 ├── Capa de herramientas ─────────────────────────────────────────────
 │   manejador de herramientas      (工具人, Flash    ) leer código, buscar archivos
 │   manejador de herramientas-mimo (工具人-mimo, MiMo) [oculto]  lectura de archivos confiable (respaldo + paralelo)
 │   swift             (闪电侠, Flash    ) tareas simples de un solo golpe
 │   traductor de visión (视觉翻译官, MiMo ) captura de pantalla/UI→texto; registros/diagramas/documentos→descomposición
 │
 ├── extractor de residuos  (残差提取者,  Flash     ) analizar divergencia entre planes
 ├── evaluador de confianza (置信度评估者, DS Pro    ) evaluar la confianza en el resultado de la fusión
 │
 ├── Capa de opinión de nivel medio ─────────────────────────────────────────────
 │   medio-ing      (中级·工程, Kimi K2.6 ) vista de ingeniería
 │   medio-creativo (中级·创意, Qwen3.7 Plus) vista creativa
 │   medio-coder    (中级·码农, Flash     ) vista pragmática
 │   medio-fusión     (中级·融合, Kimi      ) fusionar tres planes [max_tokens: 16384]
 │
 ├── Capa de opinión insignia ─────────────────────────────────────────────
 │   insignia-arquitectura (旗舰·架构, Qwen3.7 Max ) arquitectura de alto nivel
 │   insignia-plan (旗舰·规划, GLM 5.2     ) planificación estructurada
 │   insignia-ing  (旗舰·工程, MiniMax M3  ) implementación a gran escala
 │   insignia-fusión (旗舰·融合, Kimi K3     ) fusionar tres planes de arquitectura [max_tokens: 16384]
 │   insignia-impl (旗舰·实现, Flash) [oculto]  implementar según el plan fusionado
 │   insignia-qa   (旗舰·质检, DeepSeek Pro) revisión del plan + aceptación de código [max_tokens: 16384]
 │
 └── Capa de opinión de frontend ─────────────────────────────────────────────
     fe-restaurar (前端·还原, MiMo       ) restauración de UI pixel-perfect
     fe-lógica   (前端·逻辑, Qwen3.7 Plus) arquitectura de componentes y gestión de estado
     fe-moción  (前端·动效, MiMo-Pro   ) interacción y movimiento
     fe-líder    (前端·总工, GLM-5.2    ) elegir el mejor de tres planes de frontend [max_tokens: 16384]
```

Agente de respaldo (no en la cadena de enrutador anterior, llamado solo cuando la fusión falla):

```
respaldo (融合·保底, DeepSeek V4 Pro) — misma fusión mejorada por residuos, utilizada cuando fallan flag-fuse / mid-fuse / fe-lead

## Diseño de tolerancia a fallos

### Cadena de retroceso de la capa de herramientas

El fallo de la capa de herramientas no se congela — se degrada automáticamente:

```
tool-handler (Flash) falló → reintento inmediato una vez
  → reintento tiene éxito → retornar normalmente
  → reintento falla → tool-handler-mimo (MiMo) falló → reintento inmediato una vez
    → reintento tiene éxito → retornar normalmente
    → reintento falla → preguntar al usuario:
      A. esperar unos minutos y reintentar
      B. omitir la capa de herramientas, llamar a la capa de opinión directamente (costo más alto)
      C. cambiar a modelo gratuito
```

> La mayoría de los errores del proveedor (502/503/timeout) son transitorios; un reintento rápido generalmente tiene éxito.

### Retroceso de la capa de fusión

Si el agente de fusión principal falla (ATASCADO / ERROR_PROVEEDOR / timeout / resultado vacío), el concierge-router retrocede automáticamente a `@融合·保底` (DeepSeek V4 Pro, retroceso):

```
flag-fuse (旗舰·融合, Kimi K3) falló
  → tarea(@融合·保底) (DeepSeek V4 Pro) → resultado de retroceso
mid-fuse (中级·融合, Kimi) falló
  → tarea(@融合·保底) (DeepSeek V4 Pro) → resultado de retroceso
fe-lead (前端·总工, GLM-5.2) falló
  → tarea(@融合·保底) (DeepSeek V4 Pro) → resultado de retroceso
```

El agente de retroceso utiliza el mismo proceso de fusión mejorada por residuos.

### Tolerancia a fallos parciales en la capa de opinión

Los agentes de opinión individuales (arquitectura/planificación/ingeniería, restauración de frontend/lógica/movimiento, ingeniería creativa/codificación de nivel medio) pueden devolver resultados vacíos o agotar el tiempo de forma independiente. El sistema maneja esto con gracia:

```
3 agentes de opinión paralelos despachados
  → cualquier agente devuelve resultado vacío → reintentar ese agente una vez
    → reintento tiene éxito → continuar normalmente
    → reintento falla → marcar como "degradado" y proceder con N/3 entradas
      → 残差提取者 trabaja solo con entradas disponibles
      → 旗舰·融合 aplica reglas de fusión degradadas
      → la salida lleva la etiqueta "[Parcial] N/3 entradas"
      → la puntuación de confianza se ajusta hacia abajo
```

Reglas de fusión degradadas (N < 3):
- El denominador de cobertura de consenso es N, no 3
- Las perspectivas faltantes se etiquetan como `[Faltante: nombre de la perspectiva]`
- Cobertura de consenso < 50% activa la advertencia de "fusión degradada de baja confianza"
- La fusión de fuente única (N=1) aplica un factor de penalización de confianza de 0.7

> Esto previene que la canalización se detenga (ATASCADO) cuando un agente de opinión falla — una queja común de los usuarios.

### Precondiciones de activación del agente

La activación del agente está gobernada por metadatos declarativos de `precondición`, no por reglas de enrutamiento codificadas. Cada agente declara cuándo debe estar activo:

| Agente | precondiciones |
|-------|---------------|
| 闪电侠 | siempre |
| 工具人 | requiere contexto de código |
| 视觉翻译官 | principal: `screenshot`; retroceso: `error_log OR diagram OR long_document OR ambiguous_intent` |
| 中级·工程 | requiere complejidad de ingeniería |
| 中级·创意 | requiere complejidad creativa |
| 中级·码农 | requiere complejidad de implementación |
| 旗舰·架构/规划/工程 | requiere complejidad de diseño del sistema |
| 前端·还原/逻辑/动效 | requiere tarea de frontend |
| 融合·保底 | se activa cuando la capa de fusión falla o la capa de opinión devuelve resultados parciales |

La activación de condiciones sigue una lógica de cortocircuito: condiciones preestablecidas cumplidas → activar; ninguna cumplida → preguntar al usuario por confirmación. Esto reemplaza las reglas de activación codificadas (como "screenshot disponible → @vision-translator") con precondiciones declaradas por el agente, auto-documentadas.

### Visualización de etapas de la canalización

Cada decisión de enrutamiento produce un identificador de etapa para que los usuarios puedan rastrear el progreso de la canalización sin aprender los números de paso internos:

```
[Etapa: Capa de Herramientas] → [Etapa: Capa de Opinión] → [Etapa: Capa de Fusión] → [Etapa: Capa de Implementación]
```

Mapeo de etapa a fase:
- `Capa de Herramientas` — fase de recolección de material
- `Capa de Opinión` — fase de diseño de plan paralelo (nivel medio / insignia / frontend)
- `Capa de Fusión` — fase de fusión y verificación de planes
- `Capa de Implementación` — fase de implementación de código y aceptación

### Informe de progreso unificado

Tanto los caminos de éxito como de fallo siguen el mismo formato de informe, sin exponer nunca los nombres internos de los agentes:

```
[Canalización] modo=<lite|balanced|strict>  etapa=<Capa de Herramientas|Capa de Opinión|Capa de Fusión|Capa de Implementación>  estado=<idle|in_progress|complete|degraded|stuck>
  razón: <por qué esta etapa>
  camino: <Capa de Herramientas|Cadena de nivel medio|Cadena insignia|Cadena de frontend>
  retroceso: <estrategia de recuperación>
```

Indicadores de estado:
- `in_progress` — ejecutando la etapa actual
- `complete` — etapa finalizada con éxito
- `degraded` — funcionando con entradas parciales, menor confianza
- `stuck` — todos los caminos de recuperación agotados, intervención del usuario necesaria

### Atajo paralelo rápido

Cuando la canalización principal está en ejecución, swift puede ser despachado en paralelo para subtareas simples independientes:

```
Canalización principal: Capa de Herramientas → Capa de Opinión → Capa de Fusión → Capa de Implementación
Carril paralelo: swift (siempre listo, se ejecuta junto a la canalización principal)
```

Condiciones de activación (cualquiera de las siguientes):
- La instrucción del usuario solicita explícitamente trabajo paralelo ("hacer X simultáneamente", "también revisar rápidamente Y")
- Surge una subtarea simple durante la ejecución de la canalización principal (por ejemplo, buscar TODOs mientras se diseñan los planes de arquitectura)
- El usuario llama directamente a @swift

Limitaciones de alcance:
- ✅ Tareas independientes sin dependencia de la salida de la canalización principal
- ✅ Operaciones simples: búsqueda de archivos, grep, consulta de configuración, formateo
- ❌ Tareas que producen entrada para la canalización principal
- ❌ Tareas de fusión de opinión (deben permanecer en serie)
- ❌ Tareas de implementación y QA (deben permanecer en serie)

Si swift termina antes que la canalización principal, los resultados se retienen y se devuelven juntos al final. Si la canalización principal termina primero, los resultados de swift se devuelven inmediatamente. El fallo de swift no afecta la ejecución de la canalización principal.

### Aislamiento de permisos MCP

Se prohíbe a los agentes de la capa de opinión leer código directamente (a través de `read: deny` + `bash: deny`), impidiendo que eludan la capa de herramientas para obtener material ellos mismos:

- Capa de herramientas: puede leer código, buscar archivos (tiene acceso `read`/`bash`)
- Capa de opinión: `read: deny` + `bash: deny`, solo puede planificar basado en material de la capa de herramientas
- Capa de fusión: misma restricción, solo puede fusionar basado en las tres opiniones

> Nota: Este proyecto no configura ningún servidor MCP. El término "aislamiento de permisos MCP" se refiere a las restricciones de herramienta a nivel de agente (`read: deny` / `bash: deny`), no al aislamiento a nivel de servidor MCP.

### Defensa contra anidamiento de tareas

Todos los agentes que no son de enrutamiento declaran `task: deny` para evitar que los agentes hijos llamen a task() nuevamente, bloqueando el anidamiento recursivo:

- **Capa 1 (frontmatter del agente)**: cada archivo de agente declara `task: deny`
- **Capa 2 (opencode.json)**: `permission.task` solo permite al concierge llamar a agentes; los agentes que no son de enrutamiento se les niega globalmente la llamada a trabajadores
- **Capa 3 (guardia de prompt)**: el prompt del concierge termina con una restricción que prohíbe lanzarse a sí mismo una nueva canalización a través de un sub-agente

> Agregado en 2026-07 después de descubrir el anidamiento triple concierge→tool-handler→tool-handler. La redundancia de tres capas asegura el bloqueo incluso si una capa falla.

### Retroceso sin material

Cuando se llama a la capa de opinión pero no hay material (la capa de herramientas ha fallado completamente), pregunta al usuario:

- Elegir "dar plan directamente" → razonamiento lógico puro basado en la descripción del requisito (sin lectura de código)
- Elegir "esperar a la capa de herramientas" → salida ESPERANDO, reintentar después de que la capa de herramientas se recupere

### Clasificación de errores

La capa de herramientas produce una categoría de error clara en caso de fallo, en lugar de reintentar ciegamente:

- `ERROR_PROVEEDOR` — servidor 502/503/timeout
- `ERROR_AUTH` — fallo de autenticación
- `ERROR_UNKNOWN` — otros errores

---

## Costo

### Por qué se ahorra ~90%

MoA factura por una mezcla ponderada por volumen de llamadas: ~80% capa de herramienta Flash, ~18% de gama media, ~2% insignia. Estime el precio unitario de salida efectivo con los precios por unidad en la tabla de costos de esta sección:

> **Importante**: Las proporciones 80/18/2 son **distribuciones de volumen de llamadas esperadas diseñadas por la arquitectura**, no proporciones de costo medidas. El uso real depende de los tipos de tareas y su complejidad.

| Capa        | Participación | Precio unitario de salida /1M                                                                            | Ponderado |
| ----------- | ------------- | ------------------------------------------------------------------------------------------------------- | --------- |
| Capa de herramienta | 80%         | $0.28                                                                                                   | $0.224   |
| Gama media  | 18%           | ~$2.10 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 / **Kimi K2.7 $4.00 promedio de fusión media**) | $0.378   |
| Insignia    | 2%            | ~$6.00 (Qwen/GLM/MiniMax ~$4-7 + **Kimi K3 $15.00 fusión insignia**)                                   | $0.12    |

El precio unitario de salida efectivo combinado ≈ **$0.72 / 1M**. Comparado con "GLM todo insignia $7.50" → alrededor del 10% → **~90% ahorrado**; comparado con "DeepSeek Pro todo gama media $3.48" → alrededor del 21% → **~79% ahorrado**. La afirmación de "ahorrar 90%" es el valor real contra la línea base insignia.

### Plan OpenCode Go

MoA se basa en el plan [OpenCode Go](https://opencode.ai/docs/zh-cn/go/), **primer mes $5, luego $10/mes**.

**Límites de uso:**

| Ventana de tiempo | Cuota |
| ----------------- | ----- |
| Cada 5 horas      | $12   |
| Semanal           | $30   |
| Mensual           | $60   |

Los límites se definen por valor en dólares. Los modelos baratos (Flash) se pueden usar con más frecuencia, los modelos caros (GLM) con menos frecuencia.

### Cuota mensual por capa

| Capa        | Modelo           | Precio unitario (entrada/salida por 1M) | Cuota mensual | Frecuencia de llamadas |
| ----------- | ---------------- | ---------------------------------------- | ------------- | ---------------------- |
| Capa de herramienta | Flash           | $0.14 / $0.28                            | 158,150       | ~80%                  |
| Capa de herramienta | MiMo-V2.5       | $0.14 / $0.28                            | 150,400       | (usar libremente)     |
| Opinión     | MiniMax M3      | $0.30 / $1.20                            | 16,000        | ~18%                  |
| Opinión     | DeepSeek V4 Pro | $1.74 / $3.48                            | 17,150        |                        |
| Opinión     | Qwen3.7 Plus    | $0.40 / $1.60                            | 21,600        |                        |
| Fusión      | Kimi K2.7 Code  | $0.95 / $4.00                            | 9,250         | ~2% (fusión gama media) |
| Fusión      | Kimi K3         | $3.00 / $15.00                           | 280           | ~2% (fusión insignia)  |
| Fusión      | GLM-5.2         | $1.40 / $4.40                            | 4,300         | ~2% (líder de frontend) |

> Todos los IDs de modelo son solo declaraciones; reemplácelos con cualquier modelo que prefiera.

![Cuota OpenCode Go por 5h](.github/quota-chart-en.svg)

### Después de alcanzar el límite

- **Retroceso a modelo gratuito** — después de que Go alcance el límite, puede seguir usando modelos gratuitos
- **Retroceso a saldo Zen** — habilitar "usar saldo" en la consola; después del límite de Go, usar automáticamente el saldo Zen

### Modelos gratuitos

OpenCode Zen proporciona modelos gratuitos como último recurso:

| Modelo                     | Característica                       |
| -------------------------- | ------------------------------------ |
| DeepSeek V4 Flash Free     | rápido, pero con contexto limitado   |
| MiMo-V2.5 Free             | mejor calidad, pero puede ser lento  |
| North Mini Code Free       | proporcionado por Cohere             |
| Nemotron 3 Ultra Free      | punto final gratuito de NVIDIA       |

> ⚠️ Límites de modelos gratuitos: ventana de contexto más pequeña, posible respuesta más lenta, los datos pueden ser utilizados para entrenamiento, gratuito por tiempo limitado.

---


## Seguridad

| Protección                 | Efecto                                                                                                                                                                                            |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Captura global             | llamada de herramienta no declarada → confirmación emergente                                                                                                                                     |
| Aislamiento de permisos de agente | cada agente solo puede usar herramientas permitidas                                                                                                                                               |
| Aislamiento de permisos de MCP   | capa de opinión prohibida de leer código (leer: denegar / bash: denegar), previene el eludir la capa de herramienta (el proyecto no tiene un servidor MCP configurado; "MCP" aquí se refiere a restricciones de herramientas a nivel de agente) |
| Defensa de 3 capas de tarea     | agentes no enrutadores deniegan tarea → lista blanca de conserjería → guardia de aviso, previene la anidación recursiva                                                                 |
| Cadena de retroceso        | falla de capa de herramienta → preguntar al usuario → esperar/saltar/modelo gratuito                                                                                                               |
| Retroceso de un clic       | eliminar `.opencode/` para restaurar                                                                                                                                                              |

---


## Modelos locales

Soporta la mezcla de modelos locales como Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Consulte el Apéndice A de [`docs/opencode-moa.md`](docs/opencode-moa.md).

---


## Verificación

El repositorio incluye tres scripts de verificación bajo `.opencode/tests/`. La Capa 0 es completamente automática; las Capas 1–2 son listas de verificación guiadas que se recorren dentro de OpenCode.

```bash
# Capa 0 — verificación estática (automática, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# esperado: todo PASS / FAIL=0 (con clave a nivel de sistema, WARN también cuenta como pass)

# ejecutar las tres capas a la vez
pwsh .opencode/tests/run-all.ps1
```

| Script                     | Capa | Lo que hace                                                                              | Modo                 |
| -------------------------- | ----- | --------------------------------------------------------------------------------------- | -------------------- |
| `T0-static-verify.ps1`    | 0     | Verifica la estructura de archivos, cuentas de agente/comando/habilidad, anclajes de README, corrección de rutas clave | Automático           |
| `T1-behavioral-guide.ps1` | 1     | Imprime una lista de verificación paso a paso para el comportamiento de enrutamiento / opinión / fusión | Manual (en OpenCode) |
| `T2-moa-smoke-guide.ps1`  | 2     | Imprime una lista de verificación de prueba de humo para comandos `/moa-*` de extremo a extremo | Manual (en OpenCode) |
| `run-all.ps1`             | 0–2   | Ejecuta T0 y luego imprime las listas de verificación guiadas T1/T2                      | Mixto                |

---

## FAQ

### Instalación

**Q: Ya tengo un opencode.json, ¿se sobrescribirá?**
A: No. El script de instalación solo fusiona la configuración de `permission`, `agent`, `default_agent` de MoA, manteniendo tu `provider`, `model`, etc. El archivo original se respalda automáticamente como `.bak.timestamp`.

**Q: Windows no tiene el comando `cp`, ¿qué hago?**
A: Usa `Copy-Item` o `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: ¿Puedo instalar sin pwsh/jq?**
A: Sí. Usa el Método 1 (despliegue automático de IA) o el Método 3 (fusión manual de configuración).

**Q: ¿Cómo instalo en la aplicación de escritorio?**
A: El Método 1 es el más conveniente: arrastra `docs/opencode-moa.en.md` a la caja de chat y deja que la IA lo despliegue automáticamente. Los Métodos 2/3 requieren operar en una terminal (CMD/PowerShell/Terminal) primero.

### Uso

**Q: ¿No puedo ver "concierge-router"?**
A: Consulta las tres verificaciones bajo "despliegue de 30 segundos → Cómo saber si el despliegue fue exitoso": `opencode.json` en la raíz del proyecto, 22 .md bajo `.opencode/agents/`, cambia con `Tab` después de reiniciar (cliente de escritorio de Windows: `Ctrl+.` también funciona).

**Q: ¿`@tool-handler` sin respuesta?**
A: Confirma que `.opencode/agents/tool-handler.md` existe y que el formato del frontmatter es correcto.

**Q: ¿Error "modelo no encontrado"?**
A: El formato del ID del modelo debe ser `provider/model-id` (por ejemplo, `opencode-go/kimi-k2.7-code`). Registra el proveedor correspondiente en el archivo de configuración (nivel de sistema `~/.config/opencode/opencode.json` o proyecto `opencode.json`), luego usa `/models` dentro del TUI para ver los modelos disponibles.

**Q: ¿Cómo vuelvo al agente de construcción/plan original?**
A: Presiona `Tab` para cambiar (cliente de escritorio de Windows: `Ctrl+.` también funciona), o escribe `/build`, `/plan`. MoA no afecta a los agentes integrados.

**Q: Quiero usar mi propio modelo, ¿no el plan Go?**
A: Simplemente cambia el campo `model` del agente:

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q: ¿Puedo eliminar el repositorio después de desplegar?**
A: Sí. MoA ya está copiado en el directorio `.opencode/` de tu proyecto; el repositorio original se puede eliminar.

**Q: ¿Cómo despliego en múltiples proyectos?**
A: Despliega cada proyecto por separado. `.opencode/` es la configuración a nivel de proyecto y no afecta a otros proyectos.

### Recaída

**Q: ¿Toda la capa de herramientas está caída, ¿qué hago ahora?**
A: Consulta "Diseño de tolerancia a fallos → Cadena de recaída" arriba: MoA le pide al usuario que elija A. esperar unos minutos / B. omitir la capa de herramientas y llamar a la capa de opinión directamente (costo más alto).

**Q: ¿Dónde están los modelos gratuitos?**
A: Consulta "Costo → Modelos gratuitos" arriba: usa `/models` para abrir la lista de modelos y elige uno etiquetado como "Gratis" (cliente de escritorio de Windows: `Ctrl+'` también funciona) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Los modelos gratuitos tienen contexto limitado, pueden ser más lentos y los datos pueden ser utilizados para entrenamiento.

---


## Herramientas para mantenedores (no necesarias para usuarios finales)

Los siguientes archivos son para **mantenedores de repositorios**, no para desplegar MoA. Los usuarios finales pueden ignorarlos.

| Archivo                    | Propósito                                                                                                                                          |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `deploy-sync.ps1`          | Solo para mantenedores: sincroniza el repositorio con GitHub y sube la habilidad `opencode-moa` a SkillHub. Soporta `-SkipGit` / `-SkipSkillHub` / `-DryRun`.   |
| `scripts/hooks/pre-commit` | Recordatorio de gancho git local: advierte cuando registras un cambio en `CHANGELOG.md` (que se libera automáticamente al hacer push a `master`).                                   |
| `scripts/hooks/pre-push`   | Recordatorio de gancho git local: confirma la versión antes de hacer push de cambios en `CHANGELOG.md` a `master`; procede automáticamente en entornos no interactivos/CI. |

> Estos ganchos no se instalan automáticamente. Crea un enlace simbólico en `.git/hooks/` si deseas los recordatorios, por ejemplo, `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---


## Contribuyendo

Se aceptan PRs e Issues. Consulta [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Licencia

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
