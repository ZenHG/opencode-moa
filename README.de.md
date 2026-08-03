# OpenCode MoA

> 🌐 Sprachen: Englisch · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Aktuell (2026-07):** Flaggschiff-Fusion auf **Kimi K3** aktualisiert — 2,8T Parameter, 1M Kontext, erstklassiges Frontier-Modell. Die Qualitätsschwelle von MoA liegt jetzt an der Spitze.

> 🔥 **Aktuell (2026-07):** **DeepSeek-V4-Flash-0731** offiziell veröffentlicht — Agent-Fähigkeiten stark verbessert, übertrifft das teurere **GLM-5.2** (Terminal Bench 82.7 vs 81.0, DeepSWE 54.4 vs 46.2, Toolathlon 70.3 vs 59.9). Günstig schlägt teuer — MoAs Flash-Ebene (Werkzeuge + Meinungen) wird zum gleichen Preis deutlich stärker.

> 🔄 **Langfristige Selbstverbesserung (24h unbeaufsichtigt):** dein Projekt tagelang automatisch iterieren lassen — ohne Vergessen, ohne Anhalten, ohne Wiederholen. Der Portier wacht jede Runde auf, durchläuft die gesamte MoA-Pipeline und speichert den Fortschritt auf der Festplatte. Ein Befehl zum Starten: **[▶ Loslegen →](longloop/docs/LongLoop.md)**

> strukturierte Ausgabe, Grenz-Akzeptanzkriterien, Anti-Betrug, Auto-Routing. Siehe [CHANGELOG](CHANGELOG.md).

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
    ├─ flag-plan (DeepSeek V4 Flash    )  ─── Plan aus der Sicht der Planung
    ├─ flag-eng  (DeepSeek V4 Flash)  ─── Plan aus der Sicht des Implementierers
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

### Passen Sie jedes Modell an

MoA ist eine **generische Vorlage** — jedes Modell eines Agenten ist nur eine ID, die Sie ändern können. Jede Agentendatei beginnt mit:

```yaml
model: opencode-go/<model-id>
```

Um ein Modell zu wechseln, bearbeiten Sie diese eine Zeile in `.opencode/agents/<agent>.md` zu einer beliebigen `provider/model-id`, auf die Sie Zugriff haben (z. B. `opencode-go/kimi-k2.7-code`, `opencode-go/deepseek-v4-flash`). Keine Neuinstallation erforderlich. Mischen und anpassen nach Belieben — die Vorlage bindet Sie an nichts.

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

### Wie erkennt man, dass die Bereitstellung erfolgreich war?

1. Nach dem Neustart von OpenCode drücken Sie `Tab`, um die Agenten zu durchlaufen (Windows-Desktop-Client: `Ctrl+.` funktioniert auch) und sehen Sie "门童"
2. Geben Sie `@工具人` ein und es antwortet
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
@闪电侠 hilf mir, ein Hello World zu schreiben
@工具人 suche alle TODOs im Projekt
@视觉翻译 analysiere diesen Screenshot
```

**Ein-Klick-Befehle:**

| Befehl          | Szenario                                       |
| --------------- | ---------------------------------------------- |
| `/moa-quick`    | einfache Aufgabe, Übersetzung, Konfigurationsänderung |
| `/moa-medium`   | Funktionsmodul, Fehlerbehebung, Refactoring einer Datei |
| `/moa-flagship` | Systemarchitektur, großes Refactoring         |
| `/moa-frontend` | UI-Wiederherstellung, CSS, Screenshot-Reparatur |
| `/moa-describe` | Screenshot/Bild in Text                       |

### Auto-Routing

Der Concierge-Router erkennt jetzt automatisch den Aufgabentyp basierend auf der Schlüsselwortanalyse:

- **Erkundungsaufgaben**: "analysieren", "vergleichen", "verstehen", "untersuchen" → Erkundungsaufforderung + Erkundungs-Akzeptanzspezifikationen
- **Ausführungsaufgaben**: "reparieren", "hinzufügen", "implementieren", "bereitstellen" → Ausführungsaufforderung + Stoppverlustregeln
- **Der Aufgabentyp (`taskType=explore|execute`) wird als Metadaten in die Fusionsebene eingebettet**, die die passenden Akzeptanzspezifikationen generiert.

---


## Architektur

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Werkzeugebene     Meinungs-Ebene       Fusions-Ebene
             Flash + MiMo + Qwen3.7 Plus       3 parallele Meinungen wählen die beste
             (~80% Aufrufe)     (~18% Aufrufe)       (~2% Aufrufe)
```

**Werkzeugebene** (Flash + MiMo + Qwen3.7 Plus) — Code lesen, Dateien durchsuchen, Screenshot in Text umwandeln. Günstig und schnell, rufe frei an.

**Meinungs-Ebene** (Qwen / Kimi / Flash) — Pläne aus verschiedenen Perspektiven. Drei Meinungen bilden natürlich eine Struktur von "Konsens + Divergenz".

**Fusions-Ebene** (Kimi K3 / Kimi K2.7 / Flash lead / DeepSeek V4 Pro Fallback) — Konsens bewahren, das Beste bei Divergenz wählen, mit Fallback auf DeepSeek V4 Pro, wenn die Fusion fehlschlägt. Die Flagship-Fusion läuft jetzt auf **Kimi K3** (2.8T Parameter, 1M Kontext, Top-Tier Frontier-Modell) — hebt die Qualitätsgrenze von MoA an die Spitze.

> ⚠️ Die Aufrufvolumenverhältnisse unten (~80% / ~18% / ~2%) sind **Entwurfsziele**, keine gemessenen Statistiken. Tatsächliche Verhältnisse variieren je nach Aufgabenkomplexität.

### Strukturierte Ausgabe

Meinungs- und Fusionsagenten verwenden `---section-name---`-Marker. Meinungs-Ebene: `---記憶層---` + `---方案---` + `---红线---`. Fusions-Ebene: `---融合方案---` + `---分歧裁决---` + `---白名单---` + `---红线---` + `---验收标准---`. Ermöglicht die nachgelagerte Analyse und die Überprüfung der Grenz-Akzeptanz.

### Anti-Betrug

Verhindert, dass Implementierungsagenten Abkürzungen nehmen: Baseline-Nicht-Regressions-, verbotene Aktionen (Tests überspringen/mocken/löschen), versteckte Stichprobenkontrollen, Implementierungsdifferenzprüfung, Stoppverlust (3 Versuche pro Element, Rückgängigmachen bei Regression). Akzeptanzkriterien-Vorlage unter `.moa/界线.json`.



## 22 Agenten

> Der englische Name ist die logische Rolle; das Chinesische in Klammern ist der **exakte Dateiname** unter `.opencode/agents/` — du rufst sie mit `@` auf (z.B. `@门童`).

```
concierge-router (门童, Flash)
 │
 ├── Werkzeugebene ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) Code lesen, Dateien durchsuchen
 │   tool-handler-mimo (工具人-mimo, MiMo) [versteckt]  zuverlässiges Dateilesen (Fallback + parallel)
 │   swift             (闪电侠, Flash    ) einfache Aufgaben in einem Schritt
 │   vision-translator (视觉翻译, Qwen3.7 Plus ) Screenshot/UI→Text; Protokolle/Dokumente→Zerlegung
 │
 ├── Residual-Extractor  (残差提取,  Flash     ) analysiert die Divergenz zwischen Plänen
 ├── Confidence-Assessor (置信度评估, DeepSeek V4 Flash    ) bewertet das Vertrauen in das Fusionsresultat
 │
 ├── Mittlere Meinungs-Ebene ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) ingenieurtechnische Sicht
 │   mid-creative (中级·创意, Qwen3.7 Plus) kreative Sicht
 │   mid-coder    (中级·码农, Flash     ) pragmatische Sicht
 │   mid-fuse     (中级·融合, Kimi K2.7 Code) fusioniere drei Pläne [max_tokens: 16384]
 │
 ├── Flagship Meinungs-Ebene ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) Architektur auf höchster Ebene
 │   flag-plan (旗舰·规划, DeepSeek V4 Flash     ) strukturierte Planung
 │   flag-eng  (旗舰·工程, DeepSeek V4 Flash  ) großangelegte Implementierung
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusioniere drei Architekturpläne [max_tokens: 16384]
 │   flag-impl (旗舰·执行, Flash) [versteckt]  implementiere gemäß dem fusionierten Plan
 │   flag-qa   (旗舰·质检, DeepSeek Pro) Planüberprüfung + Codeakzeptanz [max_tokens: 16384]
 │
 └── Frontend Meinungs-Ebene ─────────────────────────────────────────────
     fe-restore (前端·还原, Qwen3.7 Plus       ) pixelgenaue UI-Wiederherstellung
     fe-logic   (前端·逻辑, Qwen3.7 Plus) Komponentenarchitektur & Zustandsmanagement
     fe-motion  (前端·动效, MiMo-Pro   ) Interaktion & Bewegung
     fe-lead    (前端·总工, DeepSeek V4 Flash    ) wähle den besten von drei Frontend-Plänen [max_tokens: 16384]
```

Fallback-Agent (nicht in der obigen Router-Kette, wird nur aufgerufen, wenn die Fusion fehlschlägt):

```
fallback (融合·保底, DeepSeek V4 Pro) — dieselbe residual-verbesserte Fusion, verwendet, wenn flag-fuse / mid-fuse / fe-lead fehlschlagen

## Fehlertoleranzdesign


---
## Verifikation
```bash
# Schicht 0 — statische Überprüfung (automatisch, 0 Token)
pwsh .opencode/tests/T0-static-verify.ps1
# alle drei Schichten auf einmal ausführen
pwsh .opencode/tests/run-all.ps1
```

Prüfskripte unter `.opencode/tests/`: Schicht 0 automatisch (T0 statisch / T1 README-Konsistenz / T3 Berechtigungssicherheit); Schichten 1–2 sind geführte Checklisten in OpenCode. Details: [Verifikation](docs/README-details.md#verification).

---

## Dokumentation

| Dokument | Inhalt |
| ---- | ---- |
| [docs/README-details.md](docs/README-details.md) | Ausfalltoleranz-Design · Kosten · Sicherheit · Verifikation · FAQ |
| [docs/opencode-moa.md](docs/opencode-moa.md) | Vollständiges Bereitstellungshandbuch — der Installer für die KI-Bereitstellung selbst |

---
## Contributing

PRs und Issues sind willkommen. Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

---


## License

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

