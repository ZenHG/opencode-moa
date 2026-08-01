# OpenCode MoA

> 🌐 Langues : Anglais · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Hot (2026-07) :** la fusion phare mise à niveau vers **Kimi K3** — 2.8T params, 1M contexte, modèle de pointe. Le plafond de qualité de MoA est maintenant à l'avant du peloton.

> 🔥 **Hot (2026-07) :** sortie officielle de **DeepSeek-V4-Flash-0731** — capacités d'agent fortement renforcées, surpassant V4-Pro (Preview) avec beaucoup moins de paramètres activés (Terminal Bench 82.7 vs 72.1, DeepSWE 54.4 vs 12.8, Toolathlon 70.3 vs 55.9). La couche Flash de MoA (outils + opinions) bien plus forte au même coût.

> sortie structurée, critères d'acceptation par limites, anti-triche, routage automatique. Voir [CHANGELOG](CHANGELOG.md).

> **Un point d'entrée de conversation, 22 modèles spécialisés collaborant automatiquement. Les tâches simples utilisent Flash (économique), les tâches complexes appellent le modèle phare (coûteux). Réduction des coûts jusqu'à ~90 % (vs tout-phare) lorsque les tâches simples dominent la charge de travail et que les appels au phare sont minimisés — les économies réelles dépendent du mélange des tâches ; qualité du code significativement améliorée.**

<!-- ARCH-IMG -->
![OpenCode MoA Architecture](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA est un package de configuration Mixture of Agents pour OpenCode. Il permet à plusieurs modèles **de réfléchir au même problème simultanément**, puis de fusionner en une qualité de sortie qu'un seul modèle ne peut atteindre. Vous n'avez pas besoin de changer d'outils, d'écrire du code ou d'avoir un quota d'API — il suffit de déposer les fichiers dans votre projet et de redémarrer OpenCode.

**22 agents · 5 commandes · 3 compétences · déploiement en 30 secondes**

---


## Pourquoi avez-vous besoin de cela ?

Par défaut, OpenCode utilise un seul modèle du début à la fin. Changer un caractère et concevoir une architecture système utilisent le même prompt, la même température, le même contexte. Pas de division du travail.

**Trois problèmes :**

1. **Coût incontrôlable** — les tâches simples utilisent également le modèle coûteux, la facture mensuelle reste élevée
2. **Goulot d'étranglement de qualité** — un seul modèle a une seule façon de penser, facilement bloqué dans des angles morts
3. **Pas de tolérance aux pannes** — si le modèle meurt, il se fige, pas de solution de secours

**Solution de MoA :**

```

Vous : aidez-moi à concevoir une solution de file d'attente de messages

    ┌─ flag-arch (Qwen3.7 Max)  ─── plan du point de vue de l'architecte
    ├─ flag-plan (DeepSeek V4 Flash    )  ─── plan du point de vue de la planification
    ├─ flag-eng  (DeepSeek V4 Flash)  ─── plan du point de vue de l'implémenteur
    └─ flag-fuse (Kimi K3    )  ─── prendre le meilleur de chacun, une solution optimale
```

<!-- COST-IMG -->
![Coût réduit jusqu'à 90 %](.github/moa-cost.png)
<!-- /COST-IMG -->

Trois plans indépendants de trois modèles différents forment naturellement une structure de "consensus + divergence". Le modèle de fusion identifie ce qui est consensus et le conserve, et prend le meilleur là où ils divergent — quelque chose qu'un seul modèle ne peut pas faire.

---


## Prérequis

### Requis

| Exigence            | Commande de vérification          | Remarques                                                                                                                                                                                                 |
| ------------------- | --------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installé    | `opencode --version`              | **>= 1.3.4** (support `reasoningEffort`/`hidden`/`task` au niveau de l'agent ; le fournisseur `openai-compatible` passe la réflexion de manière transparente, pas besoin de `forceReasoning`), [installer](https://opencode.ai/install) |
| Plan OpenCode Go     | console opencode.ai               | [S'abonner](https://opencode.ai/auth), premier mois 5 $, puis 10 $/mois                                                                                                                                 |
| Git installé         | `git --version`                   | Utilisé pour cloner le dépôt                                                                                                                                                                            |
| Clé API OpenCode Go  | créée dans la console opencode.ai | Créée dans la console Zen (opencode.ai)                                                                                                                                                                  |

### Optionnel (nécessaire pour les scripts d'installation)

| Exigence          | Commande de vérification | Remarques                                                                   |
| ----------------- | ----------------------- | --------------------------------------------------------------------------- |
| PowerShell Core    | `pwsh --version`       | nécessaire par install.ps1, inclus avec Windows ou `brew install powershell`  |
| jq                 | `jq --version`         | nécessaire par install.sh pour la fusion JSON, `apt install jq` / `brew install jq` |

> Pas de pwsh/jq est acceptable — vous pouvez utiliser la Méthode 1 (déploiement automatique par IA) ou la Méthode 3 (fusion manuelle).

### Bureau vs CLI

- **CLI** : toutes les méthodes prises en charge
- **Bureau** : la Méthode 1 (déploiement automatique par IA) est la plus pratique ; les Méthodes 2/3 nécessitent d'abord une opération terminale

> ⚠️ **Le chemin de clé au niveau système est facile à mal placer** — orthographe correcte dans "Lire avant de déployer" ci-dessous. Un chemin incorrect conduit à un déploiement qui semble réussir mais tous les agents échouent à se connecter.

> ⚠️ **Lire avant de déployer : ne pas mal placer le chemin de clé**
> Mettez le fournisseur + clé soit dans le **`opencode.json` au niveau du projet** (par défaut, autonome) soit dans le **chemin partagé au niveau système** — choisissez **un**.
> Si vous utilisez le niveau système, le chemin correct est :
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**pas** `%APPDATA%\opencode`)
>   Un chemin incorrect au niveau système conduit à "le déploiement réussit mais tous les agents ne peuvent pas se connecter".

---


## Déploiement en 30 secondes

### Méthode 1 : déploiement automatique par IA (recommandé)

1. Téléchargez [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Téléchargez ce document dans OpenCode et envoyez :

> Déployer tous les 22 agents, 5 commandes et 3 compétences de ce manuel dans le projet actuel

3. L'IA crée tous les fichiers automatiquement. **Redémarrez OpenCode** une fois terminé.

> Pas besoin de créer manuellement un fichier. Le manuel de déploiement est lui-même l'installateur.

### Méthode 2 : script d'installation en un clic (version script · compatible CLI)

```bash
# cloner le dépôt
git clone https://github.com/ZenHG/opencode-moa.git

# entrer dans votre répertoire de projet
cd your-project

# copier le répertoire .opencode et la configuration .moa depuis le dépôt
cp -r ../opencode-moa/.opencode/ .
cp -r ../opencode-moa/.moa/ .

# exécuter le script d'installation (fusion automatique de la configuration, conserve votre clé API)
# Windows :
pwsh ../opencode-moa/install.ps1
# Linux/macOS :
bash ../opencode-moa/install.sh
```

> Le script d'installation sauvegarde automatiquement votre `opencode.json` d'origine, ne fusionnant que la configuration de MoA tout en conservant votre fournisseur et votre clé API.
> 

### Personnaliser n'importe quel modèle

MoA est un **modèle générique** — le modèle de chaque agent est juste un ID que vous pouvez changer. Chaque fichier d'agent commence par :

```yaml
model: opencode-go/<model-id>
```

Pour échanger un modèle, éditez cette ligne dans `.opencode/agents/<agent>.md` avec n'importe quel `provider/model-id` auquel vous avez accès (par exemple `opencode-go/kimi-k2.7-code`, `opencode-go/deepseek-v4-flash`). Pas besoin de réinstaller. Mélangez et associez librement — le modèle ne vous lie à rien.

### Méthode 3 : installation manuelle

```bash
# 1. cloner le dépôt
git clone https://github.com/ZenHG/opencode-moa.git

# 2. copier le répertoire .opencode et la configuration .moa
cp -r opencode-moa/.opencode/ your-project/
cp -r opencode-moa/.moa/ your-project/

# 3. fusionner manuellement opencode.json (ne PAS remplacer directement !)
# ouvrez opencode.json, fusionnez les sections permission.task et agent de MoA
# conservez votre configuration de fournisseur et de modèle existante
```

> ⚠️ **Ne pas** utiliser `cat >>` pour ajouter — cela corrompt le format JSON. **Ne pas** remplacer directement non plus — vous perdrez votre clé API.
> 

### Comment savoir si le déploiement a réussi ?

1. Après avoir redémarré OpenCode, appuyez sur `Tab` pour faire défiler les agents (client de bureau Windows : `Ctrl+.` fonctionne aussi) et voir "门童"
2. Tapez `@工具人` et il répond
3. Exécutez le script de vérification : `pwsh .opencode/tests/T0-static-verify.ps1` (généré par le Bloc 5.5 manuel lors du déploiement), attendu que tout PASS (FAIL=0 ; avec clé au niveau système, WARN compte également comme un pass)

### Rétrogradation en un clic

```bash
rm -rf your-project/.opencode/
rm -rf your-project/.moa/
# restaurez manuellement votre opencode.json (le script d'installation sauvegarde automatiquement un fichier .bak)
```

---

## Comment utiliser ?

**N'apprenez rien — parlez simplement.** Le concierge-routeur juge automatiquement la complexité des tâches et envoie la chaîne d'agents correspondante.

| Ce que vous dites                     | Ce que fait le concierge-routeur                                   | Agents utilisés                       |
| ------------------------------------- | ----------------------------------------------------------------- | ------------------------------------- |
| "renommer cette variable"             | jugé comme une tâche simple                                       | swift (Flash)                        |
| "écrire un module d'authentification" | la couche d'outils rassemble → 3 intermédiaires parallèles → fusion | gestionnaire d'outils + trio intermédiaire + fusion |
| "concevoir une architecture de microservices" | la couche d'outils rassemble → 3 phares parallèles → fusion → mise en œuvre → QA | chaîne complète de 6 agents          |
| "restaurer l'UI de cette capture d'écran" | 3 experts frontend parallèles → le leader choisit le meilleur      | quatuor frontend                     |
| message avec capture d'écran          | le traducteur visuel convertit en texte → routage normal         | traducteur visuel                    |
| message avec journal d'erreurs / diagramme / contenu complexe | le traducteur visuel décompose le contenu → routage normal  | traducteur visuel (rôle de secours)  |

**Appels directs `@` :**

```
@闪电侠 aide-moi à écrire un hello world
@工具人 recherche tous les TODOs dans le projet
@视觉翻译官 analyse cette capture d'écran
```

**Commandes en un clic :**

| Commande         | Scénario                                       |
| ---------------- | ---------------------------------------------- |
| `/moa-quick`     | tâche simple, traduction, changement de configuration |
| `/moa-medium`    | module fonctionnel, correction de bogue, refactorisation d'un fichier unique |
| `/moa-flagship`  | architecture système, grande refactorisation   |
| `/moa-frontend`  | restauration de l'UI, CSS, correction de capture d'écran |
| `/moa-describe`  | capture d'écran/image en texte                 |

### Auto-routage

Le concierge-routeur détecte désormais automatiquement le type de tâche en fonction de l'analyse des mots-clés :

- **Tâches d'exploration** : "analyser", "comparer", "comprendre", "investiguer" → invite d'exploration + spécifications d'acceptation d'exploration
- **Tâches d'exécution** : "corriger", "ajouter", "implémenter", "déployer" → invite d'exécution + règles de stop-loss
- **Le type de tâche (`taskType=explore|execute`) est intégré aux métadonnées de la couche de fusion**, qui génère les spécifications d'acceptation correspondantes.

---


## Architecture

```
                      concierge-routeur (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Couche d'outils     Couche d'opinion       Couche de fusion
             Flash + MiMo + Qwen3.7 Plus       3 opinions parallèles prennent le meilleur
             (~80% des appels)   (~18% des appels)        (~2% des appels)
```

**Couche d'outils** (Flash + MiMo + Qwen3.7 Plus) — lire le code, rechercher des fichiers, capture d'écran en texte. Pas cher et rapide, appelez librement.

**Couche d'opinion** (Qwen / Kimi / Flash) — plans sous différents angles. Trois opinions forment naturellement une structure de "consensus + divergence".

**Couche de fusion** (Kimi K3 / Kimi K2.7 / Flash lead / DeepSeek V4 Pro en secours) — maintenir le consensus, prendre le meilleur en cas de divergence, avec un retour à DeepSeek V4 Pro si la fusion échoue. La fusion phare fonctionne désormais sur **Kimi K3** (2,8T de paramètres, 1M de contexte, modèle de pointe) — poussant le plafond de qualité de MoA à l'avant du peloton.

> ⚠️ Les ratios de volume d'appels ci-dessous (~80% / ~18% / ~2%) sont **des cibles de conception**, pas des statistiques mesurées. Les ratios réels varient selon la complexité des tâches.

### Sortie structurée

Les agents d'opinion et de fusion utilisent des marqueurs `---nom-section---`. Couche d'opinion : `---記憶層---` + `---方案---` + `---红线---`. Couche de fusion : `---融合方案---` + `---分歧裁决---` + `---白名单---` + `---红线---` + `---验收标准---`. Permet le parsing en aval et la vérification des acceptations par limites.

### Anti-triche

Empêche les agents d'implémentation de contourner les règles : non-régression de base, actions interdites (sauter/moquer/supprimer des tests), contrôles aléatoires cachés, vérification des différences d'implémentation, stop-loss (3 tentatives par élément, retour en arrière en cas de régression). Modèle de critères d'acceptation dans `.moa/界线.json`.


## 22 Agents

> Le nom en anglais est le rôle logique ; le chinois entre parenthèses est le **nom de fichier exact** sous `.opencode/agents/` — vous les appelez avec `@` (par exemple `@门童`).

```
concierge-routeur (门童, Flash)
 │
 ├── Couche d'outils ─────────────────────────────────────────────
 │   gestionnaire d'outils      (工具人, Flash    ) lire le code, rechercher des fichiers
 │   gestionnaire-d'outils-mimo (工具人-mimo, MiMo) [caché]  lecture de fichiers fiable (secours + parallèle)
 │   swift                      (闪电侠, Flash    ) tâches simples en une seule fois
 │   traducteur visuel          (视觉翻译官, Qwen3.7 Plus ) capture d'écran/UI→texte ; journaux/diagrammes/documents→décomposition
 │
 ├── extracteur de résidus  (残差提取者,  Flash     ) analyser la divergence entre les plans
 ├── évaluateur de confiance   (置信度评估者, DeepSeek V4 Flash    ) évaluer la confiance du résultat de fusion
 │
 ├── Couche d'opinion intermédiaire ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) vue d'ingénierie
 │   mid-creative (中级·创意, Qwen3.7 Plus) vue créative
 │   mid-coder    (中级·码农, Flash     ) vue pragmatique
 │   mid-fuse     (中级·融合, Kimi K2.7 Code) fusionner trois plans [max_tokens : 16384]
 │
 ├── Couche d'opinion phare ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) architecture de haut niveau
 │   flag-plan (旗舰·规划, DeepSeek V4 Flash     ) planification structurée
 │   flag-eng  (旗舰·工程, DeepSeek V4 Flash  ) mise en œuvre à grande échelle
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusionner trois plans d'architecture [max_tokens : 16384]
 │   flag-impl (旗舰·执行, Flash) [caché]  mise en œuvre par plan fusionné
 │   flag-qa   (旗舰·质检, DeepSeek Pro) révision de plan + acceptation de code [max_tokens : 16384]
 │
 └── Couche d'opinion frontend ─────────────────────────────────────────────
     fe-restore (前端·还原, Qwen3.7 Plus       ) restauration d'UI pixel-perfect
     fe-logic   (前端·逻辑, Qwen3.7 Plus) architecture de composants & gestion d'état
     fe-motion  (前端·动效, MiMo-Pro   ) interaction & mouvement
     fe-lead    (前端·总工, DeepSeek V4 Flash    ) choisir le meilleur des trois plans frontend [max_tokens : 16384]
```

Agent de secours (non dans la chaîne de routeur ci-dessus, appelé uniquement lorsque la fusion échoue) :

```
fallback (融合·保底, DeepSeek V4 Pro) — même fusion améliorée par résidus, utilisée lorsque flag-fuse / mid-fuse / fe-lead échouent


---
## Vérification
```bash
# Couche 0 — vérification statique (automatique, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# exécuter les trois couches en même temps
pwsh .opencode/tests/run-all.ps1
```

Scripts de vérification dans `.opencode/tests/` : la couche 0 est automatique (T0 statique / T1 cohérence du README / T3 sécurité des permissions) ; les couches 1–2 sont des listes de contrôle guidées dans OpenCode. Détails : [Vérification](docs/README-details.md#verification).

---

## Documentation

| Document | Contenu |
| ---- | ---- |
| [docs/README-details.md](docs/README-details.md) | Conception de tolérance aux pannes · coût · sécurité · vérification · FAQ |
| [docs/opencode-moa.md](docs/opencode-moa.md) | Manuel de déploiement complet — l'installateur lui-même pour le déploiement par IA |

---
## Contribuer

Les PR et les problèmes sont les bienvenus. Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Licence

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

