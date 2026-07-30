# OpenCode MoA

> 🌐 Sprachen: Englisch · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Aktuell (2026-07):** Flaggschiff-Fusion auf **Kimi K3** aktualisiert — 2,8T Parameter, 1M Kontext, erstklassiges Frontier-Modell. Die Qualitätsschwelle von MoA liegt jetzt an der Spitze.

> **v0.0.15:** strukturierte Ausgabe, gefrorene Akzeptanzkriterien, Anti-Betrug, Auto-Routing. Siehe [CHANGELOG](CHANGELOG.md).

> **Ein Einstiegspunkt für Gespräche, 22 spezialisierte Modelle, die automatisch zusammenarbeiten. Einfache Aufgaben nutzen Flash (günstig), komplexe Aufgaben rufen das Flaggschiff (teuer) auf. Kostenreduktion um bis zu ~90% (im Vergleich zu allem Flaggschiff), wenn einfache Aufgaben die Arbeitslast dominieren und Flaggschiff-Aufrufe minimiert werden — tatsächliche Einsparungen hängen von der Aufgabenmischung ab; die Codequalität ist signifikant gestiegen.**

<!-- ARCH-IMG -->
![OpenCode MoA Architektur](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA ist ein Konfigurationspaket für Mixture of Agents für OpenCode. Es ermöglicht mehreren Modellen, **gleichzeitig über dasselbe Problem nachzudenken**, und dann in eine Ausgabewertung zu fusionieren, die ein einzelnes Modell nicht erreichen kann. Sie müssen keine Werkzeuge wechseln, keinen Code schreiben oder ein API-Kontingent haben — legen Sie einfach die Dateien in Ihr Projekt und starten Sie OpenCode neu.

**22 Agenten · 5 Befehle · 3 Fähigkeiten · 30-Sekunden-Bereitstellung**

---

## Warum benötigen Sie das?

Standardmäßig verwendet OpenCode ein einzelnes Modell von Anfang bis Ende. Das Ändern eines Zeichens und das Entwerfen einer Systemarchitektur verwenden dasselbe Prompt, dieselbe Temperatur, denselben Kontext. Keine Arbeitsteilung.

**Drei Probleme:**

1. **Kosten außer Kontrolle** — einfache Aufgaben verwenden ebenfalls das teure Modell, die monatliche Rechnung bleibt hoch
2. **Qualitätsengpass** — ein einzelnes Modell hat nur eine Denkweise und bleibt leicht in blinden Flecken stecken
3. **Keine Fehlertoleranz** — wenn das Modell abstürzt, friert es ein, kein Fallback

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

Drei unabhängige Pläne von drei verschiedenen Modellen bilden natürlich eine Struktur von "Konsens + Divergenz". Das Fusionsmodell identifiziert, was Konsens ist, und behält es bei, und nimmt das Beste, wo sie divergieren — etwas, das ein einzelnes Modell nicht tun kann.

---

## Voraussetzungen

### Erforderlich

| Anforderung          | Überprüfungsbefehl                | Hinweise                                                                                                                                                                                                 |
| -------------------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installiert  | `opencode --version`              | **>= 1.3.4** (Agentenebene `reasoningEffort`/`hidden`/`task` Unterstützung; `openai-compatible` Anbieter überträgt das Denken transparent, kein `forceReasoning` nötig), [installieren](https://opencode.ai/install) |
| OpenCode Go-Plan     | opencode.ai Konsole               | [Abonnieren](https://opencode.ai/auth), erster Monat $5, danach $10/Monat                                                                                                                                 |
| Git installiert       | `git --version`                   | Wird verwendet, um das Repository zu klonen                                                                                                                                                             |
| OpenCode Go API Schlüssel | erstellt in opencode.ai Konsole | Erstellt in der Zen-Konsole (opencode.ai)                                                                                                                                                               |

### Optional (benötigt von Installationsskripten)

| Anforderung     | Überprüfungsbefehl | Hinweise                                                                     |
| --------------- | ------------------- | --------------------------------------------------------------------------- |
| PowerShell Core | `pwsh --version`    | benötigt von install.ps1, gebündelt mit Windows oder `brew install powershell`  |
| jq              | `jq --version`      | benötigt von install.sh für JSON-Zusammenführung, `apt install jq` / `brew install jq` |

> Kein pwsh/jq ist in Ordnung — Sie können Methode 1 (AI-Auto-Bereitstellung) oder Methode 3 (manuelle Zusammenführung) verwenden.

### Desktop vs CLI

- **CLI**: alle Methoden unterstützt
- **Desktop**: Methode 1 (AI-Auto-Bereitstellung) ist am bequemsten; Methoden 2/3 erfordern zuerst Terminalbetrieb

> ⚠️ **Der systemweite Schlüsselpfad ist leicht falsch zu platzieren** — korrekte Schreibweise in "Lesen vor der Bereitstellung" unten. Falscher Pfad führt dazu, dass die Bereitstellung erfolgreich erscheint, aber alle Agenten keine Verbindung herstellen können.

> ⚠️ **Lesen vor der Bereitstellung: Platzieren Sie den Schlüsselpfad nicht falsch**
> Legen Sie den Anbieter + Schlüssel entweder in die **projektbezogene `opencode.json`** (Standard, eigenständig) oder den **systemweiten** gemeinsamen Pfad — wählen Sie **einen**.
> Wenn Sie den systemweiten verwenden, ist der korrekte Pfad:
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**nicht** `%APPDATA%\opencode`)
>   Falscher systemweiter Pfad führt dazu, dass "Bereitstellung erfolgreich, aber alle Agenten können keine Verbindung herstellen".

---

## 30-Sekunden-Bereitstellung

### Methode 1: AI-Auto-Bereitstellung (empfohlen)

1. Laden Sie [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md) herunter
2. Laden Sie dieses Dokument in OpenCode hoch und senden Sie:

> Bereitstellen Sie alle 22 Agenten, 5 Befehle und 3 Fähigkeiten aus diesem Handbuch in das aktuelle Projekt

3. Die KI erstellt automatisch alle Dateien. **Starten Sie OpenCode neu**, wenn Sie fertig sind.

> Es ist nicht erforderlich, manuell eine Datei zu erstellen. Das Bereitstellungshandbuch ist selbst der Installer.

### Methode 2: Ein-Klick-Installationsskript (Skriptversion · CLI-freundlich)

```bash
# Klonen Sie das Repository
git clone https://github.com/ZenHG/opencode-moa.git

# Wechseln Sie in Ihr Projektverzeichnis
cd your-project

# Kopieren Sie das .opencode-Verzeichnis und die .moa-Konfiguration aus dem Repository
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .

# Führen Sie das Installationsskript aus (automatische Zusammenführung der Konfiguration, behält Ihren API-Schlüssel)
# Windows:
pwsh ../opencode-moa/install.ps1
# Linux/macOS:
bash ../opencode-moa/install.sh
```

> Das Installationsskript sichert automatisch Ihre ursprüngliche `opencode.json`, während es nur die MoA-Konfiguration zusammenführt und Ihren Anbieter und API-Schlüssel beibehält.
> 
> Hinweis: Diese Methode kopiert das gebündelte `.opencode/` des Repositories so, wie es ist — seine Agenten haben **chinesische Anzeigenamen**. Wenn Sie Agenten mit englischen Namen möchten (damit Sie `@english-name` verwenden können), verwenden Sie stattdessen Methode 1.

### Passen Sie jedes Modell an

MoA ist eine **generische Vorlage** — jedes Modell eines Agenten ist nur eine ID, die Sie ändern können. Jede Agentendatei beginnt mit:

```yaml
model: opencode-go/<model-id>
```

Um ein Modell zu wechseln, bearbeiten Sie diese eine Zeile in `.opencode/agents/<agent>.md` zu einer beliebigen `provider/model-id`, auf die Sie Zugriff haben (z. B. `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). Keine Neuinstallation erforderlich. Mischen und anpassen nach Belieben — die Vorlage bindet Sie an nichts.

### Methode 3: Manuelle Installation

```bash
# 1. Klonen Sie das Repository
git clone https://github.com/ZenHG/opencode-moa.git

# 2. Kopieren Sie das .opencode-Verzeichnis und die .moa-Konfiguration
cp -r opencode-moa/.opencode/ your-project/
cp -r opencode-moa/.moa/ your-project/

# 3. Mergen Sie manuell opencode.json (nicht direkt ersetzen!)
# Öffnen Sie opencode.json, fügen Sie die Abschnitte permission.task und agent von MoA ein
# Behalten Sie Ihre vorhandene Anbieter- und Modellkonfiguration bei
```

> ⚠️ **Verwenden Sie nicht** `cat >>`, um anzuhängen — es beschädigt das JSON-Format. **Ersetzen Sie auch nicht direkt** — Sie verlieren Ihren API-Schlüssel.
> 
> Hinweis: Diese Methode kopiert das gebündelte `.opencode/` des Repositories so, wie es ist — seine Agenten haben **chinesische Anzeigenamen**. Wenn Sie Agenten mit englischen Namen möchten (damit Sie `@english-name` verwenden können), verwenden Sie stattdessen Methode 1.

### Wie erkennt man, dass die Bereitstellung erfolgreich war?

1. Nach dem Neustart von OpenCode drücken Sie `Tab`, um die Agenten zu durchlaufen (Windows-Desktop-Client: `Ctrl+.` funktioniert auch) und sehen Sie "concierge-router"
2. Geben Sie `@tool-handler` ein und es antwortet
3. Führen Sie das Verifizierungsskript aus: `pwsh .opencode/tests/T0-static-verify.ps1` (generiert von manuellem Block 5.5 während der Bereitstellung), erwartet alle PASS (FAIL=0; mit systemweitem Schlüssel zählt WARN ebenfalls als Pass)

### Ein-Klick-Rollback

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
# Stellen Sie manuell Ihre opencode.json wieder her (das Installationsskript sichert automatisch eine .bak-Datei)
```

---

## Wie benutzt man?

**Lerne nichts — sprich einfach.** Der Concierge-Router beurteilt automatisch die Komplexität der Aufgabe und dispatcht die entsprechende Agentenkette.

| Was du sagst                           | Was der Concierge-Router tut                                   | Verwendete Agenten                    |
| -------------------------------------- | ------------------------------------------------------------- | ------------------------------------- |
| "benenne diese Variable um"           | als einfache Aufgabe beurteilt                                 | swift (Flash)                        |
| "schreibe ein Benutzer-Auth-Modul"    | Werkzeugebene sammelt → 3 mittlere parallel → fusionieren     | tool-handler + mittleres Trio + fuse  |
| "entwerfe eine Microservice-Architektur" | Werkzeugebene sammelt → 3 Flagship parallel → fusionieren → implementieren → QA | full-chain 6 agents                  |
| "stelle die UI dieses Screenshots wieder her" | 3 Frontend-Experten parallel → Leiter wählt den besten        | frontend quartet                     |
| Nachricht mit Screenshot                | vision-translator wandelt in Text um → normale Weiterleitung   | vision-translator                    |
| Nachricht mit Fehlerprotokoll / Diagramm / komplexem Inhalt | vision-translator zerlegt den Inhalt → normale Weiterleitung | vision-translator (Fallback-Rolle)   |

**Direkte `@`-Aufrufe:**

```
@swift hilf mir, ein Hello World zu schreiben
@tool-handler suche alle TODOs im Projekt
@flag-arch entwerfe eine Nachrichtenwarteschlangenlösung
```

**Ein-Klick-Befehle:**

| Befehl          | Szenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | einfache Aufgabe, Übersetzung, Konfigurationsänderung |
| `/moa-medium`   | Funktionsmodul, Fehlerbehebung, Refactoring einer Datei |
| `/moa-flagship` | Systemarchitektur, großes Refactoring         |
| `/moa-frontend` | UI-Wiederherstellung, CSS, Screenshot-Reparatur |
| `/moa-describe` | Screenshot/Bild in Text                       |

### Auto-Routing (v0.0.15)

Der Concierge-Router erkennt jetzt automatisch den Aufgabentyp basierend auf der Schlüsselwortanalyse:

- **Erkundungsaufgaben**: "analysieren", "vergleichen", "verstehen", "untersuchen" → Erkundungsaufforderung + eingefrorene Akzeptanzkriterien
- **Ausführungsaufgaben**: "reparieren", "hinzufügen", "implementieren", "bereitstellen" → Ausführungsaufforderung + Stoppverlustregeln
- **Aufgabentyp erscheint in der Pipeline-Ausgabe**: `[Typ: Ausführen]` oder `[Typ: Erkunden]`

---


## Architektur

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Werkzeugebene     Meinungs-Ebene       Fusions-Ebene
             Flash + MiMo       3 parallele Meinungen wählen die beste
             (~80% Aufrufe)     (~18% Aufrufe)       (~2% Aufrufe)
```

**Werkzeugebene** (Flash + MiMo) — Code lesen, Dateien durchsuchen, Screenshot in Text umwandeln. Günstig und schnell, rufe frei an.

**Meinungs-Ebene** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — Pläne aus verschiedenen Perspektiven. Drei Meinungen bilden natürlich eine Struktur von "Konsens + Divergenz".

**Fusions-Ebene** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro Fallback) — Konsens bewahren, das Beste bei Divergenz wählen, mit Fallback auf DeepSeek V4 Pro, wenn die Fusion fehlschlägt. Die Flagship-Fusion läuft jetzt auf **Kimi K3** (2.8T Parameter, 1M Kontext, Top-Tier Frontier-Modell) — hebt die Qualitätsgrenze von MoA an die Spitze.

> ⚠️ Die Aufrufvolumenverhältnisse unten (~80% / ~18% / ~2%) sind **Entwurfsziele**, keine gemessenen Statistiken. Tatsächliche Verhältnisse variieren je nach Aufgabenkomplexität.

### Strukturierte Ausgabe

Meinungs- und Fusionsagenten verwenden `---section-name---`-Marker. Meinungs-Ebene: `---memory---` + `---plan---` + `---NOT---`. Fusions-Ebene: vollständige Struktur mit Metadaten, Konsens, Plan, NOT-Liste und Akzeptanzkriterien. Ermöglicht die nachgelagerte Analyse und die Überprüfung der eingefrorenen Akzeptanz.

### Anti-Betrug (v0.0.15)

Verhindert, dass Implementierungsagenten Abkürzungen nehmen: Baseline-Nicht-Regressions-, verbotene Aktionen (Tests überspringen/mocken/löschen), versteckte Stichprobenkontrollen, Implementierungsdifferenzprüfung, Stoppverlust (3 Versuche pro Element, Rückgängigmachen bei Regression). Akzeptanzkriterien-Vorlage unter `.moa/acceptance-template.json`.



## 22 Agenten

> Der englische Name ist die logische Rolle; das Chinesische in Klammern ist der **exakte Dateiname** unter `.opencode/agents/` — du rufst sie mit `@` auf (z.B. `@门童路由员`).

```
concierge-router (门童路由员, Flash)
 │
 ├── Werkzeugebene ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) Code lesen, Dateien durchsuchen
 │   tool-handler-mimo (工具人-mimo, MiMo) [versteckt]  zuverlässiges Dateilesen (Fallback + parallel)
 │   swift             (闪电侠, Flash    ) einfache Aufgaben in einem Schritt
 │   vision-translator (视觉翻译官, MiMo ) Screenshot/UI→Text; Protokolle/Dokumente→Zerlegung
 │
 ├── Residual-Extractor  (残差提取者,  Flash     ) analysiert die Divergenz zwischen Plänen
 ├── Confidence-Assessor (置信度评估者, DS Pro    ) bewertet das Vertrauen in das Fusionsresultat
 │
 ├── Mittlere Meinungs-Ebene ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) ingenieurtechnische Sicht
 │   mid-creative (中级·创意, Qwen3.7 Plus) kreative Sicht
 │   mid-coder    (中级·码农, Flash     ) pragmatische Sicht
 │   mid-fuse     (中级·融合, Kimi      ) fusioniere drei Pläne [max_tokens: 16384]
 │
 ├── Flagship Meinungs-Ebene ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) Architektur auf höchster Ebene
 │   flag-plan (旗舰·规划, GLM 5.2     ) strukturierte Planung
 │   flag-eng  (旗舰·工程, MiniMax M3  ) großangelegte Implementierung
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusioniere drei Architekturpläne [max_tokens: 16384]
 │   flag-impl (旗舰·实现, Flash) [versteckt]  implementiere gemäß dem fusionierten Plan
 │   flag-qa   (旗舰·质检, DeepSeek Pro) Planüberprüfung + Codeakzeptanz [max_tokens: 16384]
 │
 └── Frontend Meinungs-Ebene ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo       ) pixelgenaue UI-Wiederherstellung
     fe-logic   (前端·逻辑, Qwen3.7 Plus) Komponentenarchitektur & Zustandsmanagement
     fe-motion  (前端·动效, MiMo-Pro   ) Interaktion & Bewegung
     fe-lead    (前端·总工, GLM-5.2    ) wähle den besten von drei Frontend-Plänen [max_tokens: 16384]
```

Fallback-Agent (nicht in der obigen Router-Kette, wird nur aufgerufen, wenn die Fusion fehlschlägt):

```
fallback (融合·保底, DeepSeek V4 Pro) — dieselbe residual-verbesserte Fusion, verwendet, wenn flag-fuse / mid-fuse / fe-lead fehlschlagen

## Fehlertoleranzdesign

### Fallback-Kette der Werkzeugschicht

Das Versagen der Werkzeugschicht friert nicht ein — es wird automatisch herabgestuft:

```
tool-handler (Flash) fehlgeschlagen → sofortiger erneuter Versuch einmal
  → erneuter Versuch erfolgreich → normal zurückgeben
  → erneuter Versuch fehlgeschlagen → tool-handler-mimo (MiMo) fehlgeschlagen → sofortiger erneuter Versuch einmal
    → erneuter Versuch erfolgreich → normal zurückgeben
    → erneuter Versuch fehlgeschlagen → Benutzer fragen:
      A. einige Minuten warten und erneut versuchen
      B. Werkzeugschicht überspringen, direkt die Meinungs-Schicht aufrufen (höhere Kosten)
      C. auf freies Modell umschalten
```

> Die meisten Anbieterfehler (502/503/Timeout) sind vorübergehend; ein schneller erneuter Versuch schlägt normalerweise nicht fehl.

### Fallback der Fusionsschicht

Wenn der primäre Fusionsagent fehlschlägt (STUCK / ERROR_PROVIDER / Timeout / leeres Ergebnis), fällt der concierge-router automatisch auf `@融合·保底` (DeepSeek V4 Pro, Fallback) zurück:

```
flag-fuse (旗舰·融合, Kimi K3) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe des Fallback-Ergebnisses
mid-fuse (中级·融合, Kimi) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe des Fallback-Ergebnisses
fe-lead (前端·总工, GLM-5.2) fehlgeschlagen
  → aufgabe(@融合·保底) (DeepSeek V4 Pro) → Ausgabe des Fallback-Ergebnisses
```

Der Fallback-Agent verwendet denselben residual-verbesserten Fusionsprozess.

### Fehlertoleranz bei teilweisem Versagen der Meinungs-Schicht

Einzelne Meinungsagenten (Architektur/Planung/Engineering, Frontend-Wiederherstellung/Logik/Bewegung, Mid-Tier-Engineering/Kreativ/Coding) können unabhängig leere Ergebnisse zurückgeben oder zeitlich auslaufen. Das System geht damit elegant um:

```
3 parallele Meinungsagenten entsandt
  → ein Agent gibt leeres Ergebnis zurück → diesen Agenten einmal erneut versuchen
    → erneuter Versuch erfolgreich → normal fortfahren
    → erneuter Versuch fehlgeschlagen → als "degradiert" markieren und mit N/3 Eingaben fortfahren
      → 残差提取者 arbeitet nur mit verfügbaren Eingaben
      → 旗舰·融合 wendet degradierte Fusionsregeln an
      → Ausgabe trägt das Label "[Teilweise] N/3 Eingaben"
      → der Vertrauensscore wird nach unten angepasst
```

Degradierte Fusionsregeln (N < 3):
- Der Konsensabdeckungsnenner ist N, nicht 3
- Fehlende Perspektiven werden mit `[Missing: Perspektivenname]` gekennzeichnet
- Konsensabdeckung < 50% löst die Warnung "niedriges Vertrauen, degradierte Fusion" aus
- Fusion aus einer Quelle (N=1) wendet einen Vertrauensstrafenfaktor von 0.7 an

> Dies verhindert, dass die Pipeline ins Stocken gerät (STUCK), wenn ein Meinungsagent ausfällt — eine häufige Benutzerbeschwerde.

### Deklarative Agenten-Voraussetzungen

Die Aktivierung von Agenten wird durch deklarative `precondition`-Metadaten geregelt, nicht durch fest kodierte Routing-Regeln. Jeder Agent erklärt, wann er aktiv sein sollte:

| Agent | Voraussetzungen |
|-------|----------------|
| 闪电侠 | immer |
| 工具人 | benötigt Kontext des Codebases |
| 视觉翻译官 | primär: `screenshot`; fallback: `error_log ODER diagram ODER long_document ODER ambiguous_intent` |
| 中级·工程 | benötigt Ingenieurskomplexität |
| 中级·创意 | benötigt kreative Komplexität |
| 中级·码农 | benötigt Implementierungs-Komplexität |
| 旗舰·架构/规划/工程 | benötigt Systemdesign-Komplexität |
| 前端·还原/逻辑/动效 | benötigt Frontend-Aufgabe |
| 融合·保底 | aktiviert, wenn die Fusionsschicht fehlschlägt oder die Meinungs-Schicht teilweise Ergebnisse zurückgibt |

Die Aktivierung der Bedingungen folgt der Kurzschlusslogik: Voraussetzungen erfüllt → aktivieren; keine erfüllt → Benutzer um Bestätigung bitten. Dies ersetzt fest kodierte Auslöse-Regeln (wie "Screenshot verfügbar → @vision-translator") durch von Agenten erklärte, selbstdokumentierende Voraussetzungen.

### Visualisierung der Pipeline-Phase

Jede Routing-Entscheidung gibt eine Phasenkennung aus, damit Benutzer den Fortschritt der Pipeline verfolgen können, ohne interne Schrittzahlen lernen zu müssen:

```
[Phase: Werkzeugschicht] → [Phase: Meinungs-Schicht] → [Phase: Fusionsschicht] → [Phase: Implementierungsschicht]
```

Zuordnung von Phase zu Phase:
- `Werkzeugschicht` — Materialsammlungsphase
- `Meinungs-Schicht` — parallele Planungsdesignphase (Mid-Tier / Flagship / Frontend)
- `Fusionsschicht` — Planfusion und Verifizierungsphase
- `Implementierungsschicht` — Codeimplementierungs- und Akzeptanzphase

### Einheitliche Fortschrittsberichterstattung

Sowohl Erfolgs- als auch Fehlerschritte folgen demselben Berichtsformat und geben niemals interne Agentennamen preis:

```
[Pipeline] modus=<lite|balanced|strict>  phase=<Werkzeugschicht|Meinungs-Schicht|Fusionsschicht|Implementierungsschicht>  status=<idle|in_progress|complete|degraded|stuck>
  grund: <warum diese Phase>
  pfad: <Werkzeugschicht|Mid-Tier-Kette|Flagship-Kette|Frontend-Kette>
  fallback: <Wiederherstellungsstrategie>
```

Statusindikatoren:
- `in_progress` — aktuelle Phase wird ausgeführt
- `complete` — Phase erfolgreich abgeschlossen
- `degraded` — läuft mit teilweisen Eingaben, geringeres Vertrauen
- `stuck` — alle Wiederherstellungspfade erschöpft, Benutzerintervention erforderlich

### Schneller paralleler Shortcut

Wenn die Hauptpipeline ausgeführt wird, kann swift parallel für unabhängige einfache Unteraufgaben entsandt werden:

```
Hauptpipeline: Werkzeugschicht → Meinungs-Schicht → Fusionsschicht → Implementierungsschicht
Parallele Spur: swift (immer bereit, läuft neben der Hauptpipeline)
```

Auslösebedingungen (irgendeine):
- Benutzeranweisung fordert ausdrücklich paralleles Arbeiten an ("X gleichzeitig tun", "auch schnell Y überprüfen")
- Eine einfache Unteraufgabe entsteht während der Ausführung der Hauptpipeline (z. B. TODOs suchen, während Architekturpläne entworfen werden)
- Benutzer ruft direkt @swift auf

Einschränkungen des Umfangs:
- ✅ Unabhängige Aufgaben ohne Abhängigkeit von den Ausgaben der Hauptpipeline
- ✅ Einfache Operationen: Dateisuche, grep, Konfigurationsabfrage, Formatierung
- ❌ Aufgaben, die Eingaben für die Hauptpipeline erzeugen
- ❌ Meinungsfusionsaufgaben (müssen seriell bleiben)
- ❌ Implementierungs- und QA-Aufgaben (müssen seriell bleiben)

Wenn swift vor der Hauptpipeline abgeschlossen ist, werden die Ergebnisse gehalten und am Ende zusammen zurückgegeben. Wenn die Hauptpipeline zuerst abgeschlossen ist, werden die swift-Ergebnisse sofort zurückgegeben. Ein swift-Fehler hat keinen Einfluss auf die Ausführung der Hauptpipeline.

### MCP-Berechtigungsisolierung

Meinungs-Schicht-Agenten ist es untersagt, Code direkt zu lesen (über `read: deny` + `bash: deny`), um zu verhindern, dass sie die Werkzeugschicht umgehen, um Material selbst abzurufen:

- Werkzeugschicht: kann Code lesen, Dateien durchsuchen (hat `read`/`bash`-Zugriff)
- Meinungs-Schicht: `read: deny` + `bash: deny`, kann nur auf Basis von Material aus der Werkzeugschicht planen
- Fusionsschicht: dieselbe Einschränkung, kann nur auf Basis der drei Meinungen fusionieren

> Hinweis: Dieses Projekt konfiguriert keine MCP-Server. Der Begriff "MCP-Berechtigungsisolierung" bezieht sich auf die agentenbezogenen Werkzeugbeschränkungen (`read: deny` / `bash: deny`), nicht auf die Isolierung auf MCP-Server-Ebene.

### Verteidigung gegen Aufgabenverschachtelung

Alle nicht-Routing-Agenten erklären `task: deny`, um zu verhindern, dass untergeordnete Agenten task() erneut aufrufen, wodurch rekursive Verschachtelungen blockiert werden:

- **Ebene 1 (Agenten-Frontmatter)**: Jede Agentendatei erklärt `task: deny`
- **Ebene 2 (opencode.json)**: `permission.task` erlaubt nur dem Concierge, Agenten aufzurufen; nicht-Routing-Agenten wird global das Aufrufen von Arbeitern verweigert
- **Ebene 3 (Prompt-Schutz)**: Der Concierge-Prompt endet mit einer Einschränkung, die es ihm verbietet, eine neue Pipeline über einen Unteragenten zu starten

> Hinzugefügt am 2026-07 nach Entdeckung der dreifachen Verschachtelung concierge→tool-handler→tool-handler. Die Dreischicht-Redundanz stellt sicher, dass auch dann blockiert wird, wenn eine Schicht ausfällt.

### Kein-Material-Fallback

Wenn die Meinungs-Schicht aufgerufen wird, aber kein Material hat (Werkzeugschicht vollständig fehlgeschlagen), fragt sie den Benutzer:

- Wählen Sie "Plan direkt geben" → reine logische Argumentation basierend auf der Anforderungsbeschreibung (kein Code lesen)
- Wählen Sie "auf Werkzeugschicht warten" → Ausgabe WARTEN, erneut versuchen, nachdem die Werkzeugschicht sich erholt hat

### Fehlerklassifizierung

Die Werkzeugschicht gibt bei einem Fehler eine klare Fehlerkategorie aus, anstatt blind erneut zu versuchen:

- `ERROR_PROVIDER` — Server 502/503/Timeout
- `ERROR_AUTH` — Authentifizierungsfehler
- `ERROR_UNKNOWN` — andere Fehler

---

## Kosten

### Warum ~90% gespart

MoA berechnet die Kosten nach einem volumengewichteten Mix: ~80% Tool-Schicht Flash, ~18% Mid-Tier, ~2% Flaggschiff. Schätzen Sie den effektiven Ausgabepreis pro Einheit mit den Preisen pro Einheit in der Kostentabelle dieses Abschnitts:

> **Wichtig**: Die 80/18/2-Verhältnisse sind **erwartete Anrufvolumenverteilung, die von der Architektur entworfen wurde**, nicht gemessene Kostenanteile. Die tatsächliche Nutzung hängt von den Aufgabentypen und der Komplexität ab.

| Schicht      | Anteil | Ausgabepreis pro Einheit /1M                                                                            | Gewichtet |
| ------------ | ------ | ----------------------------------------------------------------------------------------------------- | --------- |
| Tool-Schicht | 80%    | $0.28                                                                                                 | $0.224   |
| Mid-Tier     | 18%    | ~$2.10 (MiniMax $1.20 / DeepSeek Pro $3.48 / Qwen Plus $1.60 / **Kimi K2.7 $4.00 mid-fuse** Durchschnitt) | $0.378   |
| Flaggschiff  | 2%     | ~$6.00 (Qwen/GLM/MiniMax ~$4-7 + **Kimi K3 $15.00 flag-fuse**)                                      | $0.12    |

Gemischter effektiver Ausgabepreis pro Einheit ≈ **$0.72 / 1M**. Im Vergleich zu "all-flagship GLM $7.50" → etwa 10% → **~90% gespart**; im Vergleich zu "all-mid-tier DeepSeek Pro $3.48" → etwa 21% → **~79% gespart**. Die Behauptung "90% sparen" ist der tatsächliche Wert im Vergleich zur Flaggschiff-Basislinie.

### OpenCode Go-Plan

MoA basiert auf dem [OpenCode Go](https://opencode.ai/docs/zh-cn/go/) Plan, **erster Monat $5, dann $10/Monat**.

**Nutzungsgrenzen:**

| Zeitfenster   | Kontingent |
| ------------- | ---------- |
| Alle 5 Stunden | $12       |
| Wöchentlich    | $30       |
| Monatlich      | $60       |

Die Grenzen sind durch den Dollarwert definiert. Günstige Modelle (Flash) können häufiger verwendet werden, teure Modelle (GLM) seltener.

### Monatliches Kontingent pro Schicht

| Schicht      | Modell           | Einheitspreis (in/out pro 1M) | Monatliches Kontingent | Anrufhäufigkeit      |
| ------------ | ---------------- | ------------------------------- | ---------------------- | -------------------- |
| Tool-Schicht | Flash            | $0.14 / $0.28                  | 158,150                | ~80%                 |
| Tool-Schicht | MiMo-V2.5        | $0.14 / $0.28                  | 150,400                | (frei verwenden)     |
| Meinung      | MiniMax M3       | $0.30 / $1.20                  | 16,000                 | ~18%                 |
| Meinung      | DeepSeek V4 Pro  | $1.74 / $3.48                  | 17,150                 |                      |
| Meinung      | Qwen3.7 Plus     | $0.40 / $1.60                  | 21,600                 |                      |
| Fusion       | Kimi K2.7 Code   | $0.95 / $4.00                  | 9,250                  | ~2% (mid-tier fuse)  |
| Fusion       | Kimi K3          | $3.00 / $15.00                 | 280                    | ~2% (flagship fuse)  |
| Fusion       | GLM-5.2          | $1.40 / $4.40                  | 4,300                  | ~2% (frontend lead)  |

> Alle Modell-IDs sind nur Deklarationen; ersetzen Sie sie durch jedes Modell, das Sie bevorzugen.

![OpenCode Go Kontingent pro 5h](.github/quota-chart-en.svg)

### Nach Erreichen des Limits

- **Fallback auf kostenlose Modelle** — nachdem Go das Limit erreicht hat, können Sie weiterhin kostenlose Modelle verwenden
- **Fallback auf Zen-Balance** — aktivieren Sie "Balance verwenden" in der Konsole; nach dem Go-Limit wird automatisch die Zen-Balance verwendet

### Kostenlose Modelle

OpenCode Zen bietet kostenlose Modelle als letzte Möglichkeit:

| Modell                  | Merkmal                           |
| ----------------------- | --------------------------------- |
| DeepSeek V4 Flash Free  | schnell, aber begrenzter Kontext   |
| MiMo-V2.5 Free          | bessere Qualität, kann aber langsam sein |
| North Mini Code Free    | bereitgestellt von Cohere         |
| Nemotron 3 Ultra Free   | NVIDIA kostenloser Endpunkt       |

> ⚠️ Grenzen für kostenlose Modelle: kleinerer Kontext, möglicherweise langsamere Antwort, Daten können für das Training verwendet werden, kostenlos für eine begrenzte Zeit.

---


## Sicherheit

| Schutz                    | Effekt                                                                                                                                                                                         |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Globaler Auffangmechanismus | nicht deklarierter Toolaufruf → Popup-Bestätigung                                                                                                                                             |
| Agentenberechtigungsisolierung | Jeder Agent kann nur erlaubte Tools verwenden                                                                                                                                                  |
| MCP-Berechtigungsisolierung   | Meinungs-Schicht darf keinen Code lesen (lesen: verweigern / bash: verweigern), verhindert Umgehung der Tool-Schicht (Projekt hat keinen MCP-Server konfiguriert; "MCP" bezieht sich hier auf agentenbezogene Toolbeschränkungen) |
| Aufgaben 3-Schichten-Verteidigung | Nicht-Routing-Agenten verweigern Aufgabe → Concierge-Whitelist → Eingabeaufforderungsschutz, verhindert rekursive Verschachtelung                                                                 |
| Fallback-Kette            | Tool-Schicht schlägt fehl → Benutzer fragen → warten/überspringen/kostenloses Modell                                                                                                           |
| Ein-Klick-Rollback       | Löschen von `.opencode/`, um wiederherzustellen                                                                                                                                               |

---


## Lokale Modelle

Unterstützt das Mischen von lokalen Modellen wie Ollama / LM Studio:

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Siehe Anhang A von [`docs/opencode-moa.md`](docs/opencode-moa.md).

---


## Verifizierung

Das Repository enthält drei Prüfskripte unter `.opencode/tests/`. Schicht 0 ist vollständig automatisiert; Schichten 1–2 sind geführte Checklisten, die Sie in OpenCode durchlaufen.

```bash
# Schicht 0 — statische Überprüfung (automatisch, 0 Token)
pwsh .opencode/tests/T0-static-verify.ps1
# erwartet: alle PASS / FAIL=0 (mit systemweitem Schlüssel zählt WARN ebenfalls als bestanden)

# alle drei Schichten auf einmal ausführen
pwsh .opencode/tests/run-all.ps1
```

| Skript                     | Schicht | Was es tut                                                                            | Modus                 |
| -------------------------- | ------- | ------------------------------------------------------------------------------------- | --------------------- |
| `T0-static-verify.ps1`     | 0       | Überprüft die Dateistruktur, Agenten-/Befehls-/Fähigkeitsanzahl, README-Anker, Schlüsselpfadkorrektheit | Automatisch           |
| `T1-behavioral-guide.ps1`  | 1       | Gibt eine Schritt-für-Schritt-Checkliste für Routing / Meinung / Fusion Verhalten aus | Manuell (in OpenCode) |
| `T2-moa-smoke-guide.ps1`   | 2       | Gibt eine Smoke-Test-Checkliste für `/moa-*` Befehle End-to-End aus                  | Manuell (in OpenCode) |
| `run-all.ps1`              | 0–2     | Führt T0 aus und gibt dann die geführten Checklisten für T1/T2 aus                   | Gemischt              |

---

## FAQ

### Installation

**Q: Ich habe bereits eine opencode.json, wird sie überschrieben?**
A: Nein. Das Installationsskript fügt nur die `permission`, `agent`, `default_agent` Konfiguration von MoA zusammen und behält Ihre vorhandenen `provider`, `model` usw. Die Originaldatei wird automatisch als `.bak.timestamp` gesichert.

**Q: Windows hat keinen `cp` Befehl, was soll ich tun?**
A: Verwenden Sie `Copy-Item` oder `xcopy`:

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: Kann ich ohne pwsh/jq installieren?**
A: Ja. Verwenden Sie Methode 1 (AI Auto-Deployment) oder Methode 3 (manuelle Konfigurationszusammenführung).

**Q: Wie installiere ich die Desktop-App?**
A: Methode 1 ist am bequemsten — ziehen Sie `docs/opencode-moa.en.md` in das Chatfeld und lassen Sie die KI automatisch bereitstellen. Methoden 2/3 erfordern zunächst die Arbeit in einem Terminal (CMD/PowerShell/Terminal).

### Usage

**Q: Kann "concierge-router" nicht sehen?**
A: Überprüfen Sie die drei Prüfungen unter "30-Sekunden-Bereitstellung → Wie man erkennt, dass die Bereitstellung erfolgreich war": `opencode.json` im Projektstamm, 22 .md unter `.opencode/agents/`, wechseln Sie mit `Tab` nach dem Neustart (Windows-Desktop-Client: `Ctrl+.` funktioniert auch).

**Q: `@tool-handler` keine Antwort?**
A: Bestätigen Sie, dass `.opencode/agents/tool-handler.md` existiert und das Frontmatter-Format korrekt ist.

**Q: Fehler "Modell nicht gefunden"?**
A: Das Modell-ID-Format sollte `provider/model-id` sein (z.B. `opencode-go/kimi-k2.7-code`). Registrieren Sie den entsprechenden Anbieter in der Konfigurationsdatei (systemweite `~/.config/opencode/opencode.json` oder Projekt `opencode.json`), und verwenden Sie dann `/models` im TUI, um verfügbare Modelle anzuzeigen.

**Q: Wie wechsle ich zurück zum ursprünglichen Build-/Plan-Agenten?**
A: Drücken Sie `Tab`, um zu wechseln (Windows-Desktop-Client: `Ctrl+.` funktioniert auch), oder geben Sie `/build`, `/plan` ein. MoA beeinflusst keine integrierten Agenten.

**Q: Ich möchte mein eigenes Modell verwenden, nicht den Go-Plan?**
A: Ändern Sie einfach das `model` Feld des Agenten:

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q: Kann ich das Repo nach der Bereitstellung löschen?**
A: Ja. MoA ist bereits in das `.opencode/` Verzeichnis Ihres Projekts kopiert worden; das ursprüngliche Repo kann gelöscht werden.

**Q: Wie stelle ich über mehrere Projekte bereit?**
A: Stellen Sie jedes Projekt separat bereit. `.opencode/` ist eine projektbezogene Konfiguration und beeinflusst andere Projekte nicht.

### Fallback

**Q: Die gesamte Tool-Schicht ist ausgefallen, was jetzt?**
A: Siehe "Fehlertoleranzdesign → Fallback-Kette" oben: MoA fragt den Benutzer, ob er A. ein paar Minuten warten oder B. die Tool-Schicht überspringen und direkt die Meinungs-Schicht aufrufen möchte (höhere Kosten).

**Q: Wo sind die kostenlosen Modelle?**
A: Siehe "Kosten → Kostenlose Modelle" oben: Verwenden Sie `/models`, um die Modellliste zu öffnen und eines, das mit "Kostenlos" gekennzeichnet ist, auszuwählen (Windows-Desktop-Client: `Ctrl+'` funktioniert auch) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free usw.). Kostenlose Modelle haben einen begrenzten Kontext, können langsamer sein und Daten können für das Training verwendet werden.

---


## Maintainer tooling (nicht benötigt von Endbenutzern)

Die folgenden Dateien sind für **Repo-Maintainer**, nicht für die Bereitstellung von MoA. Endbenutzer können sie ignorieren.

| Datei                       | Zweck                                                                                                                                              |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `deploy-sync.ps1`          | Nur für Maintainer — synchronisiert das Repo mit GitHub und lädt die `opencode-moa` Fähigkeit zu SkillHub hoch. Unterstützt `-SkipGit` / `-SkipSkillHub` / `-DryRun`.   |
| `scripts/hooks/pre-commit` | Lokale Git-Hook-Erinnerung: warnt, wenn Sie eine Änderung an `CHANGELOG.md` vornehmen (die beim Push auf `master` automatisch veröffentlicht wird).                                   |
| `scripts/hooks/pre-push`   | Lokale Git-Hook-Erinnerung: bestätigt die Version, bevor Änderungen an `CHANGELOG.md` auf `master` gepusht werden; fährt in nicht-interaktiven/CI-Umgebungen automatisch fort. |

> Diese Hooks werden nicht automatisch installiert. Erstellen Sie einen Symlink in `.git/hooks/`, wenn Sie die Erinnerungen möchten, z.B. `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---


## Contributing

PRs und Issues sind willkommen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

---


## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
