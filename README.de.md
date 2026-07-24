# OpenCode MoA

> 🌐 Sprachen: Englisch · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![Lizenz: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Willkommen](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Aktuell (2026-07):** Flaggschiff-Fusion auf **Kimi K3** aktualisiert — 2.8T Parameter, 1M Kontext, erstklassiges Frontier-Modell. OpenCode Go Kontingent 2x bis 7/24 (140 → 280 / 5h, dann zurück zu 140). MoA-Qualitätsgrenze jetzt an der Spitze.

> **Ein Einstiegspunkt für Gespräche, 22 spezialisierte Modelle arbeiten automatisch zusammen. Einfache Aufgaben nutzen Flash (günstig), komplexe Aufgaben rufen das Flaggschiff (teuer) auf. Kostenreduktion um bis zu ~90% (im Vergleich zu ausschließlich Flaggschiff), wenn einfache Aufgaben die Arbeitslast dominieren und Flaggschiff-Aufrufe minimiert werden — tatsächliche Einsparungen hängen vom Aufgabenmix ab; Codequalität erheblich verbessert.**

<!-- ARCH-IMG -->
![OpenCode MoA Architektur](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA ist ein Konfigurationspaket für Mixture of Agents für OpenCode. Es ermöglicht mehreren Modellen, **gleichzeitig über dasselbe Problem nachzudenken**, und dann in eine Ausgabequalität zu fusionieren, die ein einzelnes Modell nicht erreichen kann. Sie müssen keine Werkzeuge wechseln, keinen Code schreiben oder ein API-Kontingent haben — legen Sie einfach die Dateien in Ihr Projekt und starten Sie OpenCode neu.

**22 Agenten · 5 Befehle · 3 Fähigkeiten · 30-Sekunden-Bereitstellung**

---


## Warum benötigen Sie das?

Standardmäßig verwendet OpenCode ein einzelnes Modell von Anfang bis Ende. Das Ändern eines Zeichens und das Entwerfen einer Systemarchitektur verwenden dasselbe Prompt, dieselbe Temperatur, denselben Kontext. Keine Arbeitsteilung.

**Drei Probleme:**

1. **Kosten außer Kontrolle** — einfache Aufgaben verwenden ebenfalls das teure Modell, die monatliche Rechnung bleibt hoch
2. **Qualitätsengpass** — ein einzelnes Modell hat nur eine Denkweise, bleibt leicht in blinden Flecken stecken
3. **Keine Fehlertoleranz** — wenn das Modell ausfällt, friert es ein, kein Fallback

**Die Lösung von MoA:**

```

You: help me design a message queue solution

    ┌─ flag-arch (Qwen3.7 Max)  ─── Plan aus der Sicht des Architekten
    ├─ flag-plan (GLM 5.2    )  ─── Plan aus der Sicht des PM
    ├─ flag-eng  (MiniMax M3 )  ─── Plan aus der Sicht des Implementierers
    └─ flag-fuse (Kimi K3    )  ─── das Beste aus jedem nehmen, eine optimale Lösung
```

<!-- COST-IMG -->
![Kostenreduktion um bis zu 90%](.github/moa-cost.png)
<!-- /COST-IMG -->

Drei unabhängige Pläne von drei verschiedenen Modellen bilden natürlich eine Struktur von "Konsens + Divergenz". Das Fusionsmodell identifiziert, was Konsens ist und behält es bei, und nimmt das Beste, wo sie divergieren — etwas, das ein einzelnes Modell nicht tun kann.

---


## Voraussetzungen

### Erforderlich

| Anforderung         | Überprüfungsbefehl             | Hinweise                                                                                                                                                                                                 |
| ------------------- | ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installiert  | `opencode --version`           | **>= 1.3.4** (Agentenebene `reasoningEffort`/`hidden`/`task` Unterstützung; `openai-compatible` Anbieter überträgt das Denken transparent, kein `forceReasoning` nötig), [installieren](https://opencode.ai/install) |
| OpenCode Go Plan    | opencode.ai Konsole            | [Abonnieren](https://opencode.ai/auth), erster Monat $5, dann $10/Monat                                                                                                                                 |
| Git installiert       | `git --version`                | Wird verwendet, um das Repository zu klonen                                                                                                                                                             |
| OpenCode Go API Schlüssel | erstellt in opencode.ai Konsole | Erstellt in der Zen-Konsole (opencode.ai)                                                                                                                                                               |

### Optional (benötigt von Installationsskripten)

| Anforderung     | Überprüfungsbefehl | Hinweise                                                                     |
| --------------- | ------------------ | --------------------------------------------------------------------------- |
| PowerShell Core | `pwsh --version`   | benötigt von install.ps1, gebündelt mit Windows oder `brew install powershell`  |
| jq              | `jq --version`     | benötigt von install.sh für JSON-Zusammenführung, `apt install jq` / `brew install jq` |

> Kein pwsh/jq ist in Ordnung — Sie können Methode 1 (AI-Auto-Bereitstellung) oder Methode 3 (manuelle Zusammenführung) verwenden.

### Desktop vs CLI

- **CLI**: alle Methoden unterstützt
- **Desktop**: Methode 1 (AI-Auto-Bereitstellung) ist am bequemsten; Methoden 2/3 erfordern zuerst eine Terminaloperation

> ⚠️ **Der systemweite Schlüsselpfad ist leicht falsch zu platzieren** — korrekte Schreibweise in "Vor der Bereitstellung lesen" unten. Falscher Pfad führt zu "Bereitstellung erfolgreich, aber alle Agenten können sich nicht verbinden".

> ⚠️ **Vor der Bereitstellung lesen: Schlüsselpfad nicht falsch platzieren**
> Legen Sie den Anbieter + Schlüssel entweder in die **projektbezogene `opencode.json`** (Standard, eigenständig) oder den **systemweiten** gemeinsamen Pfad — wählen Sie **einen**.
> Wenn Sie den systemweiten verwenden, ist der korrekte Pfad:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**nicht** `%APPDATA%\opencode`)
>   Falscher systemweiter Pfad führt zu "Bereitstellung erfolgreich, aber alle Agenten können sich nicht verbinden".

---

## 30-Sekunden-Bereitstellung

### Methode 1: AI-Auto-Bereitstellung (empfohlen)

1. Laden Sie [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md) herunter
2. Laden Sie dieses Dokument in OpenCode hoch und senden Sie:

> Stellen Sie alle 22 Agenten, 5 Befehle und 3 Fähigkeiten aus diesem Handbuch in das aktuelle Projekt bereit

3. Die KI erstellt alle Dateien automatisch. **Starten Sie OpenCode neu**, wenn Sie fertig sind.

> Es ist nicht erforderlich, manuell eine Datei zu erstellen. Das Bereitstellungs-Handbuch ist selbst der Installer.

### Methode 2: Ein-Klick-Installationsskript (Skriptversion · CLI-freundlich)

```bash
# Klonen Sie das Repo
git clone https://github.com/ZenHG/opencode-moa.git

# Wechseln Sie in Ihr Projektverzeichnis
cd your-project

# Kopieren Sie das .opencode-Verzeichnis aus dem Repo
cp -r ../opencode-moa/.opencode/ .

# Führen Sie das Installationsskript aus (automatische Zusammenführung der Konfiguration, behält Ihren API-Schlüssel)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> Das Installationsskript sichert automatisch Ihre ursprüngliche `opencode.json`, während es nur die MoA-Konfiguration zusammenführt und Ihren Anbieter und API-Schlüssel beibehält.
> 
> Hinweis: Diese Methode kopiert das gebündelte `.opencode/` des Repos so wie es ist — seine Agenten haben **chinesische Anzeigenamen**. Wenn Sie Agenten mit englischen Namen möchten (damit Sie `@english-name` verwenden können), verwenden Sie stattdessen Methode 1.

### Passen Sie jedes Modell an

MoA ist eine **generische Vorlage** — das Modell jedes Agenten ist nur eine ID, die Sie ändern können. Jede Agentendatei beginnt mit:

```yaml
model: opencode-go/<model-id>
```

Um ein Modell zu wechseln, bearbeiten Sie diese eine Zeile in `.opencode/agents/<agent>.md` zu jeder `provider/model-id`, auf die Sie Zugriff haben (z. B. `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). Keine Neuinstallation erforderlich. Mischen und kombinieren Sie nach Belieben — die Vorlage bindet Sie an nichts.

### Methode 3: Manuelle Installation

```bash
# 1. Klonen Sie das Repo
git clone https://github.com/ZenHG/opencode-moa.git

# 2. Kopieren Sie das .opencode-Verzeichnis
cp -r opencode-moa/.opencode/ your-project/

# 3. Mergen Sie manuell opencode.json (nicht direkt ersetzen!)
# Öffnen Sie opencode.json, fügen Sie die Abschnitte permission.task und agent von MoA zusammen
# Behalten Sie Ihre vorhandene Anbieter- und Modellkonfiguration
```

> ⚠️ **Verwenden Sie nicht** `cat >>`, um anzuhängen — es beschädigt das JSON-Format. **Ersetzen Sie nicht direkt** — Sie verlieren Ihren API-Schlüssel.
> 
> Hinweis: Diese Methode kopiert das gebündelte `.opencode/` des Repos so wie es ist — seine Agenten haben **chinesische Anzeigenamen**. Wenn Sie Agenten mit englischen Namen möchten (damit Sie `@english-name` verwenden können), verwenden Sie stattdessen Methode 1.

### Wie erkennt man, dass die Bereitstellung erfolgreich war?

1. Nach dem Neustart von OpenCode drücken Sie `Tab`, um die Agenten zu durchlaufen (Windows-Desktop-Client: `Ctrl+.` funktioniert ebenfalls) und sehen Sie "concierge-router"
2. Geben Sie `@tool-handler` ein und es antwortet
3. Führen Sie das Verifizierungsskript aus: `pwsh .opencode/tests/T0-static-verify.ps1` (generiert von manuellem Block 5.5 während der Bereitstellung), erwartet alle PASS (FAIL=0; mit systemweitem Schlüssel zählt WARN ebenfalls als bestanden)

### Ein-Klick-Rollback

```bash
rm -rf your-project/.opencode/
# Stellen Sie manuell Ihre opencode.json wieder her (das Installationsskript sichert automatisch eine .bak-Datei)
```

---


## Wie benutzt man es?

**Lernen Sie nichts — sprechen Sie einfach.** Der concierge-router beurteilt automatisch die Komplexität der Aufgabe und dispatcht die entsprechende Agentenkette.

| Was Sie sagen                          | Was der concierge-router tut                                      | Verwendete Agenten                   |
| --------------------------------------- | ---------------------------------------------------------------- | ------------------------------------ |
| "benenne diese Variable um"            | als einfache Aufgabe beurteilt                                    | swift (Flash)                        |
| "schreibe ein Benutzer-Auth-Modul"     | Werkzeugebene sammelt → 3 mittlere parallel → fusionieren        | tool-handler + mittleres Trio + fusion |
| "entwerfe eine Mikroservice-Architektur"| Werkzeugebene sammelt → 3 Flagship parallel → fusionieren → implementieren → QA | Vollkette 6 Agenten                  |
| "stelle die UI dieses Screenshots wieder her" | 3 Frontend-Experten parallel → Leiter wählt den besten aus      | Frontend-Quartett                   |
| Nachricht mit Screenshot                | vision-translator wandelt in Text um → normale Weiterleitung     | vision-translator                    |
| Nachricht mit Fehlerprotokoll / Diagramm / komplexem Inhalt | vision-translator zerlegt den Inhalt → normale Weiterleitung | vision-translator (Fallback-Rolle)   |

**Direkte `@`-Aufrufe:**

```
@swift hilf mir, ein hello world zu schreiben
@tool-handler suche alle TODOs im Projekt
@flag-arch entwerfe eine Nachrichtenwarteschlangenlösung
```

**Ein-Klick-Befehle:**

| Befehl          | Szenario                                      |
| --------------- | --------------------------------------------- |
| `/moa-quick`    | einfache Aufgabe, Übersetzung, Konfigurationsänderung |
| `/moa-medium`   | Funktionsmodul, Fehlerbehebung, Einzeldatei-Refactoring |
| `/moa-flagship` | Systemarchitektur, großes Refactoring         |
| `/moa-frontend` | UI-Wiederherstellung, CSS, Screenshot-Fix    |
| `/moa-describe` | Screenshot/Bild in Text                       |

---

## Architektur

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Tool-Schicht     Meinungs-Schicht       Fusions-Schicht
             Flash + MiMo      3 parallele Meinungen wählen das Beste
             (~80% Aufrufe)    (~18% Aufrufe)        (~2% Aufrufe)
```

**Tool-Schicht** (Flash + MiMo) — Code lesen, Dateien durchsuchen, Screenshot in Text umwandeln. Günstig und schnell, rufe frei an.

**Meinungs-Schicht** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — Pläne aus verschiedenen Perspektiven. Drei Meinungen bilden natürlich eine Struktur aus "Konsens + Divergenz".

**Fusions-Schicht** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro Fallback) — Konsens beibehalten, das Beste bei Divergenz wählen, mit Rückfall auf DeepSeek V4 Pro, falls die Fusion fehlschlägt. Die Flaggschiff-Fusion läuft jetzt auf **Kimi K3** (2,8T Parameter, 1M Kontext, Spitzenmodell) — hebt die Qualitätsgrenze von MoA an die Spitze.

> ⚠️ Die Aufrufverhältnis unten (~80% / ~18% / ~2%) sind **Designziele**, keine gemessenen Statistiken. Tatsächliche Verhältnisse variieren je nach Komplexität der Aufgabe.

---


## 22 Agenten

> Der englische Name ist die logische Rolle; das Chinesische in Klammern ist der **exakte Dateiname** unter `.opencode/agents/` — du rufst sie mit `@` auf (z.B. `@门童路由员`).

```
concierge-router (门童路由员, Flash)
 │
 ├── Tool-Schicht ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) Code lesen, Dateien durchsuchen [+ Material-Selbstprüfung]
 │   tool-handler-mimo (工具人-mimo, MiMo) zuverlässiges Lesen von Dateien (Fallback + parallel) [versteckt]
 │   swift             (闪电侠, Flash    ) einfache Aufgaben in einem Schritt
 │   vision-translator (视觉翻译官, MiMo ) Screenshot/UI→Text; Protokolle/Dias/Dokumente→Zerlegung
 │
 ├── Residual-Extractor  (残差提取者,  Flash     ) analysiere Divergenz zwischen Plänen
 ├── Confidence-Assessor (置信度评估者, DS Pro    ) bewerte das Vertrauen in das Fusionsergebnis
 │
 ├── Mittlere Meinungs-Schicht ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) Ingenieursansicht
 │   mid-creative (中级·创意, Qwen3.7 Plus) kreative Ansicht
 │   mid-coder    (中级·码农, Flash     ) pragmatische Ansicht
 │   mid-fuse     (中级·融合, Kimi      ) fusioniere drei Pläne [max_tokens: 16384]
 │
 ├── Flaggschiff Meinungs-Schicht ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) Architektur auf höchster Ebene
 │   flag-plan (旗舰·规划, GLM 5.2     ) strukturierte Planung
 │   flag-eng  (旗舰·工程, MiniMax M3  ) großangelegte Implementierung
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusioniere drei Architekturpläne [max_tokens: 16384]
 │   flag-impl (旗舰·实现, Flash       ) implementiere pro fusioniertem Plan [versteckt]
 │   flag-qa   (旗舰·质检, DeepSeek Pro) Planüberprüfung + Codeakzeptanz [max_tokens: 16384]
 │
 └── Frontend Meinungs-Schicht ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo       ) pixelgenaue UI-Wiederherstellung
     fe-logic   (前端·逻辑, Qwen3.7 Plus) Komponentenarchitektur & Zustandsverwaltung
     fe-motion  (前端·动效, MiMo-Pro   ) Interaktion & Bewegung
     fe-lead    (前端·总工, GLM-5.2    ) wähle das Beste aus drei Frontend-Plänen [max_tokens: 16384]
```

Fallback-Agent (nicht in der obigen Router-Kette, wird nur aufgerufen, wenn die Fusion fehlschlägt):

```
fallback (融合·保底, DeepSeek V4 Pro) — dieselbe residual-verbesserte Fusion, verwendet, wenn flag-fuse / mid-fuse / fe-lead fehlschlagen
```

---


## Fehlertoleranzdesign

### Tool-Schicht Fallback-Kette

Das Versagen der Tool-Schicht friert nicht ein — sie wird automatisch herabgestuft:

```
tool-handler (Flash) fehlgeschlagen → sofortiger erneuter Versuch einmal
  → erneuter Versuch erfolgreich → normal zurückgeben
  → erneuter Versuch fehlgeschlagen → tool-handler-mimo (MiMo) fehlgeschlagen → sofortiger erneuter Versuch einmal
    → erneuter Versuch erfolgreich → normal zurückgeben
    → erneuter Versuch fehlgeschlagen → Benutzer fragen:
      A. einige Minuten warten und erneut versuchen
      B. Tool-Schicht überspringen, direkt die Meinungs-Schicht aufrufen (höhere Kosten)
      C. zu kostenlosem Modell wechseln
```

> Die meisten Anbieterfehler (502/503/Timeout) sind vorübergehend; ein schneller erneuter Versuch gelingt normalerweise.

### Fusions-Schicht Fallback

Wenn der primäre Fusions-Agent fehlschlägt (STUCK / ERROR_PROVIDER / Timeout / leeres Ergebnis), fällt der concierge-router automatisch auf `@融合·保底` (DeepSeek V4 Pro, Fallback) zurück:

```
flag-fuse (旗舰·融合, Kimi K3) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe Fallback-Ergebnis
mid-fuse (中级·融合, Kimi) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe Fallback-Ergebnis
fe-lead (前端·总工, GLM-5.2) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe Fallback-Ergebnis
```

Der Fallback-Agent verwendet denselben residual-verbesserten Fusionsprozess.

### Meinungs-Schicht partielle Fehlertoleranz

Einzelne Meinungs-Agenten (Architektur/Planung/Ingenieurwesen, Frontend-Wiederherstellung/Logik/Bewegung, mittlere Ingenieur-/Kreativ-/Kodierungs-Agenten) können leere Ergebnisse zurückgeben oder unabhängig Zeitüberschreitungen haben. Das System behandelt dies elegant:

```
3 parallele Meinungs-Agenten entsandt
  → irgendein Agent gibt leeres Ergebnis zurück → versuche diesen Agenten einmal erneut
    → erneuter Versuch erfolgreich → normal fortfahren
    → erneuter Versuch fehlgeschlagen → als "degradiert" markieren und mit N/3 Eingaben fortfahren
      → 残差提取者 arbeitet nur mit verfügbaren Eingaben
      → 旗舰·融合 wendet degradierte Fusionsregeln an
      → Ausgabe trägt das Label "[Teilweise] N/3 Eingaben"
      → Vertrauenspunkt wird nach unten angepasst
```

Degradierte Fusionsregeln (N < 3):
- Der Nenner der Konsensabdeckung ist N, nicht 3
- Fehlende Perspektiven sind mit `[Missing: Perspektivenname]` gekennzeichnet
- Konsensabdeckung < 50% löst die Warnung "niedriges Vertrauen in degradierte Fusion" aus
- Fusion aus einer Quelle (N=1) wendet einen Vertrauensstrafenfaktor von 0,7 an

> Dies verhindert, dass die Pipeline stagniert (STUCK), wenn ein Meinungs-Agent fehlschlägt — eine häufige Beschwerde der Benutzer.

### Deklarative Agenten-Voraussetzungen

Die Aktivierung von Agenten wird durch deklarative `precondition`-Metadaten geregelt, nicht durch fest codierte Routing-Regeln. Jeder Agent erklärt, wann er aktiv sein sollte:

| Agent | Voraussetzungen |
|-------|----------------|
| 闪电侠 | immer |
| 工具人 | benötigt Kontext des Codes |
| 视觉翻译官 | primär: `screenshot`; fallback: `error_log ODER diagram ODER long_document ODER ambiguous_intent` |
| 中级·工程 | benötigt Ingenieurskomplexität |
| 中级·创意 | benötigt kreative Komplexität |
| 中级·码农 | benötigt Implementierungskomplexität |
| 旗舰·架构/规划/工程 | benötigt Systemdesignkomplexität |
| 前端·还原/逻辑/动效 | benötigt Frontend-Aufgabe |
| 融合·保底 | aktiviert, wenn die Fusions-Schicht fehlschlägt oder die Meinungs-Schicht partielle Ergebnisse zurückgibt |

Die Aktivierungsbedingungen folgen einer Kurzschlusslogik: Voraussetzungen erfüllt → aktivieren; keine erfüllt → Benutzer um Bestätigung bitten. Dies ersetzt fest codierte Auslöse-Regeln (wie "Screenshot verfügbar → @vision-translator") durch agenten-deklarierte, selbstdokumentierende Voraussetzungen.

### Pipeline-Stufenvisualisierung

Jede Routing-Entscheidung gibt eine Stufenkennung aus, damit Benutzer den Fortschritt der Pipeline verfolgen können, ohne die internen Schrittzahlen zu lernen:

```
[Stufe: Tool-Schicht] → [Stufe: Meinungs-Schicht] → [Stufe: Fusions-Schicht] → [Stufe: Implementierungs-Schicht]
```

Stufen-zu-Phase-Zuordnung:
- `Tool-Schicht` — Materialsammlungsphase
- `Meinungs-Schicht` — parallele Planungsphase (mittlere / Flaggschiff / Frontend)
- `Fusions-Schicht` — Planfusion und Verifikationsphase
- `Implementierungs-Schicht` — Codeimplementierungs- und Akzeptanzphase

### Einheitliche Fortschrittsberichterstattung

Sowohl Erfolgs- als auch Fehlerschritte folgen demselben Berichtsformat und geben niemals interne Agentennamen preis:

```
[Pipeline] modus=<lite|balanced|strict>  stufe=<Tool-Schicht|Meinungs-Schicht|Fusions-Schicht|Implementierungs-Schicht>  status=<idle|in_progress|complete|degraded|stuck>
  grund: <warum diese Stufe>
  pfad: <Tool-Schicht|Mittlere Kette|Flaggschiff-Kette|Frontend-Kette>
  fallback: <Wiederherstellungsstrategie>
```

Statusindikatoren:
- `in_progress` — aktuelle Stufe wird ausgeführt
- `complete` — Stufe erfolgreich abgeschlossen
- `degraded` — läuft mit teilweisen Eingaben, niedriges Vertrauen
- `stuck` — alle Wiederherstellungspfade erschöpft, Benutzerintervention erforderlich

### 闪电侠 Parallel Shortcut

Wenn die Hauptpipeline ausgeführt wird, kann 闪电侠 parallel für unabhängige einfache Unteraufgaben entsandt werden:

```
Hauptpipeline: Tool-Schicht → Meinungs-Schicht → Fusions-Schicht → Implementierungs-Schicht
Parallele Spur: 闪电侠 (immer bereit, läuft neben der Hauptpipeline)
```

Auslösebedingungen (irgendeine):
- Benutzeranweisung fordert ausdrücklich paralleles Arbeiten an ("mache X gleichzeitig", "prüfe auch schnell Y")
- Eine einfache Unteraufgabe tritt während der Ausführung der Hauptpipeline auf (z.B. TODOs durchsuchen, während Architekturpläne entworfen werden)
- Benutzer ruft direkt @闪电侠 auf

Einschränkungen des Umfangs:
- ✅ Unabhängige Aufgaben ohne Abhängigkeit von den Ausgaben der Hauptpipeline
- ✅ Einfache Operationen: Dateisuche, grep, Konfigurationsabfrage, Formatierung
- ❌ Aufgaben, die Eingaben für die Hauptpipeline erzeugen
- ❌ Meinungsfusionsaufgaben (müssen seriell bleiben)
- ❌ Implementierungs- und QA-Aufgaben (müssen seriell bleiben)

Wenn 闪电侠 vor der Hauptpipeline fertig ist, werden die Ergebnisse gehalten und am Ende zusammen zurückgegeben. Wenn die Hauptpipeline zuerst fertig ist, werden die Ergebnisse von 闪电侠 sofort zurückgegeben. Das Versagen von 闪电侠 hat keinen Einfluss auf die Ausführung der Hauptpipeline.

### MCP-Berechtigungsisolierung

Meinungs-Schicht-Agenten ist es untersagt, Code direkt zu lesen (über `read: deny` + `bash: deny`), um zu verhindern, dass sie die Tool-Schicht umgehen, um Material selbst abzurufen:

- Tool-Schicht: kann Code lesen, Dateien durchsuchen (hat `read`/`bash`-Zugriff)
- Meinungs-Schicht: `read: deny` + `bash: deny`, kann nur auf Material aus der Tool-Schicht planen
- Fusions-Schicht: dieselbe Einschränkung, kann nur basierend auf den drei Meinungen fusionieren

> Hinweis: Dieses Projekt konfiguriert keine MCP-Server. Der Begriff "MCP-Berechtigungsisolierung" bezieht sich auf die agentenbezogenen Tool-Beschränkungen (`read: deny` / `bash: deny`), nicht auf die Isolierung auf Serverebene.

### Kein-Material-Fallback

Wenn die Meinungs-Schicht aufgerufen wird, aber kein Material hat (Tool-Schicht vollständig fehlgeschlagen), fragt sie den Benutzer:

- Wähle "Plan direkt geben" → reine logische Argumentation basierend auf der Anforderungsbeschreibung (kein Code lesen)
- Wähle "auf Tool-Schicht warten" → Ausgabe WARTEN, erneut versuchen, nachdem die Tool-Schicht sich erholt hat

### Fehlerklassifizierung

Die Tool-Schicht gibt eine klare Fehlerkategorie bei einem Fehler aus, anstatt blind erneut zu versuchen:

- `ERROR_PROVIDER` — Server 502/503/Timeout
- `ERROR_AUTH` — Authentifizierungsfehler
- `ERROR_UNKNOWN` — andere Fehler

---

## Kosten

### Warum ~90% gespart

MoA berechnet nach einem anrufvolumen-gewichteten Mix: ~80% Tool-Schicht Flash, ~18% Mid-Tier, ~2% Flaggschiff. Schätzen Sie den effektiven Ausgabepreis pro Einheit mit den Preisen pro Einheit in der Kostentabelle dieses Abschnitts:

> **Wichtig**: Die 80/18/2-Verhältnisse sind **erwartete Anrufvolumensverteilung, die von der Architektur entworfen wurde**, nicht gemessene Kostenanteile. Die tatsächliche Nutzung hängt von den Aufgabentypen und der Komplexität ab.

| Schicht      | Anteil | Ausgabepreis pro Einheit /1M                                                                            | Gewichtet |
| ------------ | ------ | ------------------------------------------------------------------------------------------------------ | --------- |
| Tool-Schicht | 80%    | $0.28                                                                                                  | $0.224    |
| Mid-Tier     | 18%    | ~$2.10 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 / **Kimi K2.7 $4.00 mid-fuse** Durchschnitt) | $0.378    |
| Flaggschiff  | 2%     | ~$6.00 (Qwen/GLM/MiniMax ~$4-7 + **Kimi K3 $15.00 flag-fuse**)                                       | $0.12     |

Gemischter effektiver Ausgabepreis pro Einheit ≈ **$0.72 / 1M**. Im Vergleich zu "all-flagship GLM $7.50" → etwa 10% → **~90% gespart**; im Vergleich zu "all-mid-tier DeepSeek Pro $3.48" → etwa 21% → **~79% gespart**. Die Behauptung "90% sparen" ist der reale Wert im Vergleich zur Flaggschiff-Basislinie.

### OpenCode Go-Plan

MoA basiert auf dem [OpenCode Go](https://opencode.ai/docs/zh-cn/go/) Plan, **erster Monat $5, dann $10/Monat**.

**Nutzungsgrenzen:**

| Zeitfenster   | Kontingent |
| ------------- | ---------- |
| Alle 5 Stunden | $12       |
| Wöchentlich    | $30       |
| Monatlich      | $60       |

Die Grenzen sind durch den Dollarwert definiert. Günstige Modelle (Flash) können häufiger verwendet werden, teurere Modelle (GLM) seltener.

### Monatliches Kontingent pro Schicht

| Schicht      | Modell           | Einheitspreis (in/out pro 1M) | Monatliches Kontingent | Anrufhäufigkeit      |
| ------------ | ---------------- | ------------------------------- | ---------------------- | --------------------- |
| Tool-Schicht | Flash            | $0.14 / $0.28                  | 158,150                | ~80%                  |
| Tool-Schicht | MiMo-V2.5        | $0.14 / $0.28                  | 150,400                | (frei verwenden)      |
| Meinung      | MiniMax M3       | $0.30 / $1.20                  | 16,000                 | ~18%                  |
| Meinung      | DeepSeek V4 Pro  | $1.74 / $3.48                  | 17,150                 |                       |
| Meinung      | Qwen3.7 Plus     | $0.40 / $1.60                  | 21,600                 |                       |
| Fusion       | Kimi K2.7 Code   | $0.95 / $4.00                  | 9,250                  | ~2% (mid-tier fuse)   |
| Fusion       | Kimi K3          | $3.00 / $15.00                 | 280                    | ~2% (flagship fuse)   |
| Fusion       | GLM-5.2          | $1.40 / $4.40                  | 4,300                  | ~2% (frontend lead)   |

> Alle Modell-IDs sind nur Deklarationen; ersetzen Sie sie durch jedes Modell, das Sie bevorzugen.

![OpenCode Go Kontingent pro 5h](.github/quota-chart-en.svg)

### Nach Erreichen der Grenze

- **Fallback auf kostenlose Modelle** — nachdem Go die Grenze erreicht hat, können Sie weiterhin kostenlose Modelle verwenden.
- **Fallback auf Zen-Guthaben** — aktivieren Sie "Guthaben verwenden" in der Konsole; nach der Go-Grenze wird automatisch das Zen-Guthaben verwendet.

### Kostenlose Modelle

OpenCode Zen bietet kostenlose Modelle als letzte Möglichkeit:

| Modell                    | Merkmal                           |
| ------------------------- | --------------------------------- |
| DeepSeek V4 Flash Free    | schnell, aber begrenzter Kontext  |
| MiMo-V2.5 Free            | bessere Qualität, kann aber langsam sein |
| North Mini Code Free      | bereitgestellt von Cohere         |
| Nemotron 3 Ultra Free     | NVIDIA kostenloser Endpunkt       |

> ⚠️ Grenzen für kostenlose Modelle: kleinerer Kontext, möglicherweise langsamere Antwort, Daten können für das Training verwendet werden, kostenlos für eine begrenzte Zeit.

---


## Sicherheit

| Schutz                     | Wirkung                                                                                                                                                                                        |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Globaler Auffangmechanismus | undeclared tool call → Popup-Bestätigung                                                                                                                                                      |
| Agentenberechtigungsisolierung | Jeder Agent kann nur erlaubte Werkzeuge verwenden                                                                                                                                           |
| MCP-Berechtigungsisolierung | Meinungs-Schicht darf keinen Code lesen (lesen: verweigern / bash: verweigern), verhindert das Umgehen der Tool-Schicht (Projekt hat keinen MCP-Server konfiguriert; "MCP" bezieht sich hier auf agentenbezogene Werkzeugbeschränkungen) |
| Aufgaben-Whitelist         | Concierge-Router kann nur deklarierte Agenten anrufen                                                                                                                                         |
| Fallback-Kette             | Tool-Schicht schlägt fehl → Benutzer fragen → warten/überspringen/kostenloses Modell                                                                                                          |
| Ein-Klick-Rollback        | Löschen von `.opencode/`, um wiederherzustellen                                                                                                                                               |

---

## Lokale Modelle

Unterstützt das Mischen von lokalen Modellen wie Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Siehe Anhang A von [`docs/opencode-moa.md`](docs/opencode-moa.md).

---


## Überprüfung

Das Repository enthält drei Prüfskripte unter `.opencode/tests/`. Schicht 0 ist vollständig automatisch; Schichten 1–2 sind geführte Checklisten, die Sie innerhalb von OpenCode durchgehen.

```bash
# Schicht 0 — statische Überprüfung (automatisch, 0 Token)
pwsh .opencode/tests/T0-static-verify.ps1
# erwartet: alle PASS / FAIL=0 (mit systemweitem Schlüssel, WARN zählt ebenfalls als bestanden)

# alle drei Schichten auf einmal ausführen
pwsh .opencode/tests/run-all.ps1
```

| Skript                     | Schicht | Was es tut                                                                            | Modus                 |
| -------------------------- | ------- | ------------------------------------------------------------------------------------- | --------------------- |
| `T0-static-verify.ps1`    | 0       | Überprüft die Dateistruktur, Agenten-/Befehls-/Fähigkeitsanzahl, README-Anker, Schlüsselpfad-Korrektheit | Automatisch           |
| `T1-behavioral-guide.ps1` | 1       | Druckt eine Schritt-für-Schritt-Checkliste für Routing / Meinung / Fusion Verhalten   | Manuell (in OpenCode) |
| `T2-moa-smoke-guide.ps1`  | 2       | Druckt eine Smoke-Test-Checkliste für `/moa-*` Befehle End-to-End                     | Manuell (in OpenCode) |
| `run-all.ps1`             | 0–2     | Führt T0 aus und druckt die geführten Checklisten T1/T2                              | Gemischt              |

---


## FAQ

### Installation

**F: Ich habe bereits eine opencode.json, wird sie überschrieben?**
A: Nein. Das Installationsskript fügt nur die `permission`, `agent`, `default_agent` Konfiguration von MoA hinzu und behält Ihre vorhandenen `provider`, `model` usw. bei. Die ursprüngliche Datei wird automatisch als `.bak.timestamp` gesichert.

**F: Windows hat keinen `cp` Befehl, was soll ich tun?**
A: Verwenden Sie `Copy-Item` oder `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**F: Kann ich ohne pwsh/jq installieren?**
A: Ja. Verwenden Sie Methode 1 (AI-Auto-Deployment) oder Methode 3 (manuelle Konfigurationszusammenführung).

**F: Wie installiere ich die Desktop-App?**
A: Methode 1 ist am bequemsten — ziehen Sie `docs/opencode-moa.en.md` in das Chatfenster und lassen Sie die AI automatisch bereitstellen. Methoden 2/3 erfordern zunächst die Arbeit in einem Terminal (CMD/PowerShell/Terminal).

### Nutzung

**F: Kann "concierge-router" nicht sehen?**
A: Siehe die drei Überprüfungen unter "30-Sekunden-Bereitstellung → Wie man erkennt, dass die Bereitstellung erfolgreich war": `opencode.json` im Projektstamm, 22 .md unter `.opencode/agents/`, mit `Tab` nach dem Neustart wechseln (Windows-Desktop-Client: `Ctrl+.` funktioniert ebenfalls).

**F: `@tool-handler` keine Antwort?**
A: Bestätigen Sie, dass `.opencode/agents/tool-handler.md` existiert und das Frontmatter-Format korrekt ist.

**F: Fehler "Modell nicht gefunden"?**
A: Das Format der Modell-ID sollte `provider/model-id` sein (z.B. `opencode-go/kimi-k2.7-code`). Registrieren Sie den entsprechenden Anbieter in der Konfigurationsdatei (systemweite `~/.config/opencode/opencode.json` oder Projekt `opencode.json`), und verwenden Sie dann `/models` innerhalb der TUI, um verfügbare Modelle zu sehen.

**F: Wie wechsle ich zurück zum ursprünglichen Build-/Plan-Agenten?**
A: Drücken Sie `Tab`, um zu wechseln (Windows-Desktop-Client: `Ctrl+.` funktioniert ebenfalls), oder geben Sie `/build`, `/plan` ein. MoA hat keinen Einfluss auf integrierte Agenten.

**F: Ich möchte mein eigenes Modell verwenden, nicht den Go-Plan?**
A: Ändern Sie einfach das `model` Feld des Agenten:

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**F: Kann ich das Repository nach der Bereitstellung löschen?**
A: Ja. MoA ist bereits in das `.opencode/` Verzeichnis Ihres Projekts kopiert worden; das ursprüngliche Repository kann gelöscht werden.

**F: Wie stelle ich über mehrere Projekte bereit?**
A: Stellen Sie jedes Projekt separat bereit. `.opencode/` ist eine projektbezogene Konfiguration und hat keinen Einfluss auf andere Projekte.

### Fallback

**F: Die gesamte Tool-Schicht ist ausgefallen, was jetzt?**
A: Siehe "Fehlertoleranzdesign → Fallback-Kette" oben: MoA fragt den Benutzer, ob er A. ein paar Minuten warten oder B. die Tool-Schicht überspringen und direkt die Meinungsschicht aufrufen möchte (höhere Kosten).

**F: Wo sind die kostenlosen Modelle?**
A: Siehe "Kosten → Kostenlose Modelle" oben: Verwenden Sie `/models`, um die Modellliste zu öffnen und eines mit dem Tag "Kostenlos" auszuwählen (Windows-Desktop-Client: `Ctrl+'` funktioniert ebenfalls) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free usw.). Kostenlose Modelle haben einen begrenzten Kontext, können langsamer sein und Daten können für das Training verwendet werden.

---

## Wartungstools (nicht benötigt von Endbenutzern)

Die folgenden Dateien sind für **Repo-Wartende**, nicht für die Bereitstellung von MoA. Endbenutzer können sie ignorieren.

| Datei                       | Zweck                                                                                                                                           |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `deploy-sync.ps1`          | Nur für Wartende — synchronisiert das Repo mit GitHub und lädt die `opencode-moa`-Fähigkeit zu SkillHub hoch. Unterstützt `-SkipGit` / `-SkipSkillHub` / `-DryRun`.   |
| `scripts/hooks/pre-commit` | Lokale Git-Hook-Erinnerung: warnt, wenn Sie eine Änderung an `CHANGELOG.md` festlegen (die automatisch bei einem Push zu `master` veröffentlicht wird).                                   |
| `scripts/hooks/pre-push`   | Lokale Git-Hook-Erinnerung: bestätigt die Version, bevor Änderungen an `CHANGELOG.md` zu `master` gepusht werden; fährt automatisch in nicht-interaktiven/CI-Umgebungen fort. |

> Diese Hooks werden nicht automatisch installiert. Erstellen Sie einen Symlink in `.git/hooks/`, wenn Sie die Erinnerungen möchten, z. B. `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---


## Mitwirken

PRs und Issues sind willkommen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Lizenz

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

<!-- ci-trigger-rate-limit-fix-v2 -->
