# OpenCode MoA

> 🌐 Langues : Anglais · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Hot (2026-07) :** la fusion phare mise à niveau vers **Kimi K3** — 2.8T params, 1M contexte, modèle de pointe. Le plafond de qualité de MoA est maintenant à l'avant du peloton.

> **v0.0.15 :** sortie structurée, critères d'acceptation figés, anti-triche, routage automatique. Voir [CHANGELOG](CHANGELOG.md).

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
    ├─ flag-plan (GLM 5.2    )  ─── plan du point de vue du PM
    ├─ flag-eng  (MiniMax M3 )  ─── plan du point de vue de l'implémenteur
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
> Remarque : cette méthode copie le `.opencode/` inclus dans le dépôt tel quel — ses agents ont **des noms d'affichage chinois**. Si vous voulez des agents avec des noms en anglais (pour pouvoir `@english-name`), utilisez plutôt la Méthode 1.

### Personnaliser n'importe quel modèle

MoA est un **modèle générique** — le modèle de chaque agent est juste un ID que vous pouvez changer. Chaque fichier d'agent commence par :

```yaml
model: opencode-go/<model-id>
```

Pour échanger un modèle, éditez cette ligne dans `.opencode/agents/<agent>.md` avec n'importe quel `provider/model-id` auquel vous avez accès (par exemple `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). Pas besoin de réinstaller. Mélangez et associez librement — le modèle ne vous lie à rien.

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
> Remarque : cette méthode copie le `.opencode/` inclus dans le dépôt tel quel — ses agents ont **des noms d'affichage chinois**. Si vous voulez des agents avec des noms en anglais (pour pouvoir `@english-name`), utilisez plutôt la Méthode 1.

### Comment savoir si le déploiement a réussi ?

1. Après avoir redémarré OpenCode, appuyez sur `Tab` pour faire défiler les agents (client de bureau Windows : `Ctrl+.` fonctionne aussi) et voir "concierge-router"
2. Tapez `@tool-handler` et il répond
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
@swift aide-moi à écrire un hello world
@tool-handler recherche tous les TODOs dans le projet
@flag-arch conçois une solution de file d'attente de messages
```

**Commandes en un clic :**

| Commande         | Scénario                                       |
| ---------------- | ---------------------------------------------- |
| `/moa-quick`     | tâche simple, traduction, changement de configuration |
| `/moa-medium`    | module fonctionnel, correction de bogue, refactorisation d'un fichier unique |
| `/moa-flagship`  | architecture système, grande refactorisation   |
| `/moa-frontend`  | restauration de l'UI, CSS, correction de capture d'écran |
| `/moa-describe`  | capture d'écran/image en texte                 |

### Auto-routage (v0.0.15)

Le concierge-routeur détecte désormais automatiquement le type de tâche en fonction de l'analyse des mots-clés :

- **Tâches d'exploration** : "analyser", "comparer", "comprendre", "investiguer" → invite d'exploration + critères d'acceptation figés
- **Tâches d'exécution** : "corriger", "ajouter", "implémenter", "déployer" → invite d'exécution + règles de stop-loss
- **Le type de tâche apparaît dans la sortie du pipeline** : `[Type : Exécuter]` ou `[Type : Explorer]`

---


## Architecture

```
                      concierge-routeur (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Couche d'outils     Couche d'opinion       Couche de fusion
             Flash + MiMo       3 opinions parallèles prennent le meilleur
             (~80% des appels)   (~18% des appels)        (~2% des appels)
```

**Couche d'outils** (Flash + MiMo) — lire le code, rechercher des fichiers, capture d'écran en texte. Pas cher et rapide, appelez librement.

**Couche d'opinion** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — plans sous différents angles. Trois opinions forment naturellement une structure de "consensus + divergence".

**Couche de fusion** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro en secours) — maintenir le consensus, prendre le meilleur en cas de divergence, avec un retour à DeepSeek V4 Pro si la fusion échoue. La fusion phare fonctionne désormais sur **Kimi K3** (2,8T de paramètres, 1M de contexte, modèle de pointe) — poussant le plafond de qualité de MoA à l'avant du peloton.

> ⚠️ Les ratios de volume d'appels ci-dessous (~80% / ~18% / ~2%) sont **des cibles de conception**, pas des statistiques mesurées. Les ratios réels varient selon la complexité des tâches.

### Sortie structurée

Les agents d'opinion et de fusion utilisent des marqueurs `---nom-section---`. Couche d'opinion : `---mémoire---` + `---plan---` + `---NON---`. Couche de fusion : structure complète avec métadonnées, consensus, plan, liste des NON et critères d'acceptation. Permet le parsing en aval et la vérification des acceptations figées.

### Anti-triche (v0.0.15)

Empêche les agents d'implémentation de contourner les règles : non-régression de base, actions interdites (sauter/moquer/supprimer des tests), contrôles aléatoires cachés, vérification des différences d'implémentation, stop-loss (3 tentatives par élément, retour en arrière en cas de régression). Modèle de critères d'acceptation dans `.moa/acceptance-template.json`.


## 22 Agents

> Le nom en anglais est le rôle logique ; le chinois entre parenthèses est le **nom de fichier exact** sous `.opencode/agents/` — vous les appelez avec `@` (par exemple `@门童路由员`).

```
concierge-routeur (门童路由员, Flash)
 │
 ├── Couche d'outils ─────────────────────────────────────────────
 │   gestionnaire d'outils      (工具人, Flash    ) lire le code, rechercher des fichiers
 │   gestionnaire-d'outils-mimo (工具人-mimo, MiMo) [caché]  lecture de fichiers fiable (secours + parallèle)
 │   swift                      (闪电侠, Flash    ) tâches simples en une seule fois
 │   traducteur visuel          (视觉翻译官, MiMo ) capture d'écran/UI→texte ; journaux/diagrammes/documents→décomposition
 │
 ├── extracteur de résidus  (残差提取者,  Flash     ) analyser la divergence entre les plans
 ├── évaluateur de confiance   (置信度评估者, DS Pro    ) évaluer la confiance du résultat de fusion
 │
 ├── Couche d'opinion intermédiaire ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) vue d'ingénierie
 │   mid-creative (中级·创意, Qwen3.7 Plus) vue créative
 │   mid-coder    (中级·码农, Flash     ) vue pragmatique
 │   mid-fuse     (中级·融合, Kimi      ) fusionner trois plans [max_tokens : 16384]
 │
 ├── Couche d'opinion phare ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) architecture de haut niveau
 │   flag-plan (旗舰·规划, GLM 5.2     ) planification structurée
 │   flag-eng  (旗舰·工程, MiniMax M3  ) mise en œuvre à grande échelle
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusionner trois plans d'architecture [max_tokens : 16384]
 │   flag-impl (旗舰·实现, Flash) [caché]  mise en œuvre par plan fusionné
 │   flag-qa   (旗舰·质检, DeepSeek Pro) révision de plan + acceptation de code [max_tokens : 16384]
 │
 └── Couche d'opinion frontend ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo       ) restauration d'UI pixel-perfect
     fe-logic   (前端·逻辑, Qwen3.7 Plus) architecture de composants & gestion d'état
     fe-motion  (前端·动效, MiMo-Pro   ) interaction & mouvement
     fe-lead    (前端·总工, GLM-5.2    ) choisir le meilleur des trois plans frontend [max_tokens : 16384]
```

Agent de secours (non dans la chaîne de routeur ci-dessus, appelé uniquement lorsque la fusion échoue) :

```
fallback (融合·保底, DeepSeek V4 Pro) — même fusion améliorée par résidus, utilisée lorsque flag-fuse / mid-fuse / fe-lead échouent

## Conception de la tolérance aux pannes

### Chaîne de secours de la couche outil

L'échec de la couche outil ne fige pas — elle rétrograde automatiquement :

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

> La plupart des erreurs de fournisseur (502/503/délai d'attente) sont transitoires ; un rapide nouvel essai réussit généralement.

### Sauvegarde de la couche fusion

Si l'agent de fusion principal échoue (STUCK / ERROR_PROVIDER / délai d'attente / résultat vide), le concierge-routeur rétrograde automatiquement vers `@融合·保底` (DeepSeek V4 Pro, secours) :

```
flag-fuse (旗舰·融合, Kimi K3) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
mid-fuse (中级·融合, Kimi) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
fe-lead (前端·总工, GLM-5.2) failed
  → task(@融合·保底) (DeepSeek V4 Pro) → output fallback result
```

L'agent de secours utilise le même processus de fusion amélioré par résidu.

### Tolérance à l'échec partiel de la couche opinion

Les agents d'opinion individuels (architecture/planification/ingénierie, restauration frontend/logique/mouvement, ingénierie intermédiaire/créatif/codage) peuvent renvoyer des résultats vides ou expirer indépendamment. Le système gère cela avec élégance :

```
3 parallel opinion agents dispatched
  → any agent returns empty result → retry that agent once
    → retry succeeds → continue normally
    → retry fails → mark as "degraded" and proceed with N/3 inputs
      → 残差提取者 works with available inputs only
      → 旗舰·融合 applies degraded fusion rules
      → output carries "[Partial] N/3 inputs" label
      → confidence score is adjusted downward
```

Règles de fusion dégradées (N < 3) :
- Le dénominateur de couverture de consensus est N, pas 3
- Les perspectives manquantes sont étiquetées `[Missing: perspective name]`
- Une couverture de consensus < 50 % déclenche un avertissement de "fusion dégradée à faible confiance"
- La fusion à source unique (N=1) applique un facteur de pénalité de confiance de 0,7

> Cela empêche le pipeline de se bloquer (STUCK) lorsqu'un agent d'opinion échoue — une plainte courante des utilisateurs.

### Préconditions des agents déclaratifs

L'activation des agents est régie par des métadonnées déclaratives `precondition`, et non par des règles de routage codées en dur. Chaque agent déclare quand il doit être actif :

| Agent | préconditions |
|-------|---------------|
| 闪电侠 | toujours |
| 工具人 | nécessite un contexte de code |
| 视觉翻译官 | primaire : `screenshot`; secours : `error_log OR diagram OR long_document OR ambiguous_intent` |
| 中级·工程 | nécessite une complexité d'ingénierie |
| 中级·创意 | nécessite une complexité créative |
| 中级·码农 | nécessite une complexité d'implémentation |
| 旗舰·架构/规划/工程 | nécessite une complexité de conception système |
| 前端·还原/逻辑/动效 | nécessite une tâche frontend |
| 融合·保底 | activé lorsque la couche de fusion échoue ou que la couche d'opinion renvoie des résultats partiels |

L'activation des conditions suit une logique de court-circuit : préconditions remplies → activer ; aucune remplie → demander confirmation à l'utilisateur. Cela remplace les règles de déclenchement codées en dur (comme "screenshot disponible → @vision-translator") par des préconditions déclarées par les agents, auto-documentées.

### Visualisation des étapes du pipeline

Chaque décision de routage produit un identifiant d'étape afin que les utilisateurs puissent suivre les progrès du pipeline sans apprendre les numéros d'étape internes :

```
[Stage: Tool Layer] → [Stage: Opinion Layer] → [Stage: Fusion Layer] → [Stage: Implementation Layer]
```

Mapping étape-phase :
- `Tool Layer` — phase de collecte de matériel
- `Opinion Layer` — phase de conception de plan parallèle (intermédiaire / phare / frontend)
- `Fusion Layer` — phase de fusion et de vérification du plan
- `Implementation Layer` — phase d'implémentation du code et d'acceptation

### Rapport de progression unifié

Les chemins de succès et d'échec suivent le même format de rapport, sans jamais exposer les noms internes des agents :

```
[Pipeline] mode=<lite|balanced|strict>  stage=<Tool Layer|Opinion Layer|Fusion Layer|Implementation Layer>  status=<idle|in_progress|complete|degraded|stuck>
  reason: <why this stage>
  path: <Tool Layer|Mid-tier chain|Flagship chain|Frontend chain>
  fallback: <recovery strategy>
```

Indicateurs de statut :
- `in_progress` — exécution de l'étape actuelle
- `complete` — étape terminée avec succès
- `degraded` — fonctionnement avec des entrées partielles, confiance réduite
- `stuck` — tous les chemins de récupération épuisés, intervention de l'utilisateur nécessaire

### Raccourci parallèle rapide

Lorsque le pipeline principal est en cours d'exécution, swift peut être dispatché en parallèle pour des sous-tâches simples indépendantes :

```
Main pipeline: Tool Layer → Opinion Layer → Fusion Layer → Implementation Layer
Parallel lane: swift (always ready, runs alongside main pipeline)
```

Conditions de déclenchement (n'importe laquelle) :
- L'instruction de l'utilisateur demande explicitement un travail parallèle ("faire X simultanément", "vérifier aussi rapidement Y")
- Une sous-tâche simple émerge pendant l'exécution du pipeline principal (par exemple, rechercher des TODOs pendant que les plans d'architecture sont conçus)
- L'utilisateur appelle directement @swift

Limitations de portée :
- ✅ Tâches indépendantes sans dépendance sur la sortie du pipeline principal
- ✅ Opérations simples : recherche de fichiers, grep, requête de configuration, formatage
- ❌ Tâches qui produisent une entrée pour le pipeline principal
- ❌ Tâches de fusion d'opinion (doivent rester sérielles)
- ❌ Tâches d'implémentation et de QA (doivent rester sérielles)

Si swift termine avant le pipeline principal, les résultats sont conservés et retournés ensemble à la fin. Si le pipeline principal termine en premier, les résultats swift sont retournés immédiatement. L'échec de swift n'affecte pas l'exécution du pipeline principal.

### Isolation des permissions MCP

Les agents de la couche d'opinion sont interdits de lire le code directement (via `read: deny` + `bash: deny`), les empêchant de contourner la couche outil pour récupérer le matériel eux-mêmes :

- Couche outil : peut lire le code, rechercher des fichiers (a accès à `read`/`bash`)
- Couche opinion : `read: deny` + `bash: deny`, ne peut planifier que sur la base du matériel de la couche outil
- Couche fusion : même restriction, ne peut fusionner que sur la base des trois opinions

> Remarque : Ce projet ne configure aucun serveur MCP. Le terme "isolement des permissions MCP" se réfère aux restrictions d'outil au niveau de l'agent (`read: deny` / `bash: deny`), et non à l'isolement au niveau du serveur MCP.

### Défense contre l'imbrication des tâches

Tous les agents non-routiers déclarent `task: deny` pour empêcher les agents enfants d'appeler à nouveau task(), bloquant ainsi l'imbrication récursive :

- **Couche 1 (frontmatter de l'agent)** : chaque fichier d'agent déclare `task: deny`
- **Couche 2 (opencode.json)** : `permission.task` n'autorise que le concierge à appeler des agents ; les agents non-routiers sont globalement interdits d'appeler des travailleurs
- **Couche 3 (garde de prompt)** : le prompt du concierge se termine par une contrainte interdisant de lancer un nouveau pipeline via un sous-agent

> Ajouté le 2026-07 après avoir découvert l'imbrication triple concierge→tool-handler→tool-handler. La redondance à trois couches garantit le blocage même si une couche échoue.

### Sauvegarde sans matériel

Lorsque la couche d'opinion est appelée mais n'a pas de matériel (la couche outil a complètement échoué), elle demande à l'utilisateur :

- Choisissez "donner le plan directement" → raisonnement logique pur basé sur la description de la demande (pas de lecture de code)
- Choisissez "attendre la couche outil" → sortie ATTENTE, nouvel essai après la récupération de la couche outil

### Classification des erreurs

La couche outil produit une catégorie d'erreur claire en cas d'échec, au lieu de réessayer aveuglément :

- `ERROR_PROVIDER` — serveur 502/503/délai d'attente
- `ERROR_AUTH` — échec d'authentification
- `ERROR_UNKNOWN` — autres erreurs

---

## Coût

### Pourquoi ~90% économisé

MoA facture par un mélange pondéré par le volume d'appels : ~80% outil de couche Flash, ~18% intermédiaire, ~2% phare. Estimez le prix unitaire de sortie effectif avec les prix par unité dans le tableau des coûts de cette section :

> **Important** : Les ratios 80/18/2 sont **la distribution de volume d'appels prévue par l'architecture**, pas des proportions de coût mesurées. L'utilisation réelle dépend des types de tâches et de leur complexité.

| Couche      | Part | Prix unitaire de sortie /1M                                                                            | Pondéré |
| ----------- | ---- | ----------------------------------------------------------------------------------------------------- | ------- |
| Couche outil| 80%  | 0,28 $                                                                                                 | 0,224 $ |
| Intermédiaire| 18% | ~2,10 $ (MiniMax 1,20 $ / DeepSeek Pro 3,48 $ / Qwen Plus 1,60 $ / **Kimi K2.7 4,00 $ moyenne mid-fuse**) | 0,378 $ |
| Phare       | 2%   | ~6,00 $ (Qwen/GLM/MiniMax ~4-7 $ + **Kimi K3 15,00 $ flag-fuse**)                                   | 0,12 $  |

Prix unitaire de sortie effectif mélangé ≈ **0,72 $ / 1M**. Comparé à "GLM tout phare 7,50 $" → environ 10% → **~90% économisé** ; comparé à "DeepSeek Pro tout intermédiaire 3,48 $" → environ 21% → **~79% économisé**. La revendication "économiser 90%" est la véritable valeur par rapport à la référence phare.

### Plan OpenCode Go

MoA est basé sur le plan [OpenCode Go](https://opencode.ai/docs/zh-cn/go/), **premier mois 5 $, puis 10 $/mois**.

**Limites d'utilisation :**

| Fenêtre temporelle | Quota |
| ------------------ | ----- |
| Toutes les 5 heures| 12 $  |
| Hebdomadaire       | 30 $  |
| Mensuel            | 60 $  |

Les limites sont définies par la valeur en dollars. Les modèles bon marché (Flash) peuvent être utilisés plus souvent, les modèles coûteux (GLM) moins souvent.

### Quota mensuel par couche

| Couche      | Modèle           | Prix unitaire (entrée/sortie par 1M) | Quota mensuel | Fréquence d'appel      |
| ----------- | ---------------- | ------------------------------------- | ------------- | ----------------------- |
| Couche outil| Flash            | 0,14 $ / 0,28 $                       | 158,150       | ~80%                    |
| Couche outil| MiMo-V2.5       | 0,14 $ / 0,28 $                       | 150,400       | (utiliser librement)    |
| Opinion     | MiniMax M3      | 0,30 $ / 1,20 $                       | 16,000        | ~18%                    |
| Opinion     | DeepSeek V4 Pro | 1,74 $ / 3,48 $                       | 17,150        |                         |
| Opinion     | Qwen3.7 Plus    | 0,40 $ / 1,60 $                       | 21,600        |                         |
| Fusion      | Kimi K2.7 Code  | 0,95 $ / 4,00 $                       | 9,250         | ~2% (fusion intermédiaire)|
| Fusion      | Kimi K3         | 3,00 $ / 15,00 $                      | 280           | ~2% (fusion phare)      |
| Fusion      | GLM-5.2         | 1,40 $ / 4,40 $                       | 4,300         | ~2% (lead frontend)     |

> Tous les identifiants de modèle ne sont que des déclarations ; remplacez par le modèle de votre choix.

![Quota OpenCode Go par 5h](.github/quota-chart-en.svg)

### Après avoir atteint la limite

- **Repli sur modèle gratuit** — après que Go atteigne la limite, vous pouvez continuer à utiliser des modèles gratuits
- **Repli sur solde Zen** — activez "utiliser le solde" dans la console ; après la limite Go, utilisation automatique du solde Zen

### Modèles gratuits

OpenCode Zen fournit des modèles gratuits en dernier recours :

| Modèle                  | Caractéristique                     |
| ----------------------- | ----------------------------------- |
| DeepSeek V4 Flash Free  | rapide, mais contexte limité        |
| MiMo-V2.5 Free          | meilleure qualité, mais peut être lent |
| North Mini Code Free    | fourni par Cohere                  |
| Nemotron 3 Ultra Free   | point de terminaison gratuit NVIDIA |

> ⚠️ Limites des modèles gratuits : fenêtre de contexte plus petite, réponse possiblement plus lente, les données peuvent être utilisées pour l'entraînement, gratuit pour une durée limitée.

---


## Sécurité

| Protection                 | Effet                                                                                                                                                                                         |
| -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Protection globale         | appel d'outil non déclaré → confirmation popup                                                                                                                                               |
| Isolation des permissions de l'agent | chaque agent ne peut utiliser que les outils autorisés                                                                                                                                      |
| Isolation des permissions MCP   | couche d'opinion interdite de lire le code (lire : refuser / bash : refuser), empêche de contourner la couche d'outil (le projet n'a pas de serveur MCP configuré ; "MCP" fait référence ici aux restrictions d'outil au niveau de l'agent) |
| Défense à 3 couches         | agents non routiers refusent la tâche → liste blanche de concierges → garde de prompt, empêche l'imbrication récursive |
| Chaîne de repli            | échec de la couche d'outil → demander à l'utilisateur → attendre/sauter/modèle gratuit                                                                                                       |
| Rétrogradation en un clic   | supprimer `.opencode/` pour restaurer                                                                                                                                                       |

---


## Modèles locaux

Prend en charge le mélange de modèles locaux comme Ollama / LM Studio :

```yaml
# .opencode/agents/mid-coder.md
model: ollama-local/qwen3-coder
```

Voir l'Annexe A de [`docs/opencode-moa.md`](docs/opencode-moa.md).

---


## Vérification

Le dépôt expédie trois scripts de vérification sous `.opencode/tests/`. La couche 0 est entièrement automatique ; les couches 1–2 sont des listes de contrôle guidées que vous parcourez dans OpenCode.

```bash
# Couche 0 — vérification statique (automatique, 0 token)
pwsh .opencode/tests/T0-static-verify.ps1
# attendu : tout PASS / FAIL=0 (avec clé au niveau système, WARN compte également comme un pass)

# exécuter les trois couches en même temps
pwsh .opencode/tests/run-all.ps1
```

| Script                     | Couche | Ce qu'il fait                                                                            | Mode                 |
| -------------------------- | ------ | --------------------------------------------------------------------------------------- | -------------------- |
| `T0-static-verify.ps1`    | 0      | Vérifie la structure des fichiers, les comptes d'agents/commandes/compétences, les ancres README, la correction des chemins clés | Automatique          |
| `T1-behavioral-guide.ps1` | 1      | Imprime une liste de contrôle étape par étape pour le comportement de routage / opinion / fusion | Manuel (dans OpenCode) |
| `T2-moa-smoke-guide.ps1`  | 2      | Imprime une liste de contrôle de test de validation pour les commandes `/moa-*` de bout en bout | Manuel (dans OpenCode) |
| `run-all.ps1`             | 0–2    | Exécute T0 puis imprime les listes de contrôle guidées T1/T2                             | Mixte                |

---

## FAQ

### Installation

**Q: J'ai déjà un opencode.json, sera-t-il écrasé ?**
A: Non. Le script d'installation ne fusionne que les configurations `permission`, `agent`, `default_agent` de MoA, en conservant votre `provider`, `model`, etc. Le fichier original est automatiquement sauvegardé sous le nom `.bak.timestamp`.

**Q: Windows n'a pas de commande `cp`, que dois-je faire ?**
A: Utilisez `Copy-Item` ou `xcopy` :

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q: Puis-je installer sans pwsh/jq ?**
A: Oui. Utilisez la Méthode 1 (déploiement automatique par IA) ou la Méthode 3 (fusion manuelle de configuration).

**Q: Comment installer sur l'application de bureau ?**
A: La Méthode 1 est la plus pratique — faites glisser `docs/opencode-moa.en.md` dans la boîte de chat et laissez l'IA déployer automatiquement. Les Méthodes 2/3 nécessitent d'opérer d'abord dans un terminal (CMD/PowerShell/Terminal).

### Usage

**Q: Je ne vois pas "concierge-router" ?**
A: Consultez les trois vérifications sous "déploiement de 30 secondes → Comment savoir si le déploiement a réussi" : `opencode.json` à la racine du projet, 22 .md sous `.opencode/agents/`, changez avec `Tab` après le redémarrage (client de bureau Windows : `Ctrl+.` fonctionne également).

**Q: `@tool-handler` pas de réponse ?**
A: Confirmez que `.opencode/agents/tool-handler.md` existe et que le format de frontmatter est correct.

**Q: Erreur "modèle non trouvé" ?**
A: Le format de l'ID de modèle doit être `provider/model-id` (par exemple `opencode-go/kimi-k2.7-code`). Enregistrez le fournisseur correspondant dans le fichier de configuration (niveau système `~/.config/opencode/opencode.json` ou projet `opencode.json`), puis utilisez `/models` dans le TUI pour voir les modèles disponibles.

**Q: Comment revenir à l'agent de construction/plan original ?**
A: Appuyez sur `Tab` pour changer (client de bureau Windows : `Ctrl+.` fonctionne également), ou tapez `/build`, `/plan`. MoA n'affecte pas les agents intégrés.

**Q: Je veux utiliser mon propre modèle, pas le plan Go ?**
A: Il suffit de changer le champ `model` de l'agent :

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q: Puis-je supprimer le dépôt après le déploiement ?**
A: Oui. MoA est déjà copié dans le répertoire `.opencode/` de votre projet ; le dépôt original peut être supprimé.

**Q: Comment déployer sur plusieurs projets ?**
A: Déployez chaque projet séparément. `.opencode/` est une configuration au niveau du projet et n'affecte pas les autres projets.

### Fallback

**Q: Toute la couche d'outils est en panne, que faire ?**
A: Consultez "Conception de tolérance aux pannes → Chaîne de secours" ci-dessus : MoA demande à l'utilisateur de choisir A. attendre quelques minutes / B. ignorer la couche d'outils et appeler directement la couche d'opinion (coût plus élevé).

**Q: Où sont les modèles gratuits ?**
A: Consultez "Coût → Modèles gratuits" ci-dessus : utilisez `/models` pour ouvrir la liste des modèles et en choisir un étiqueté "Gratuit" (client de bureau Windows : `Ctrl+'` fonctionne également) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Les modèles gratuits ont un contexte limité, peuvent être plus lents et les données peuvent être utilisées pour l'entraînement.

---


## Outils de maintenance (non nécessaires pour les utilisateurs finaux)

Les fichiers suivants sont destinés aux **mainteneurs de dépôt**, pas pour déployer MoA. Les utilisateurs finaux peuvent les ignorer.

| Fichier                     | But                                                                                                                                               |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `deploy-sync.ps1`           | Réservé aux mainteneurs — synchronise le dépôt avec GitHub et télécharge la compétence `opencode-moa` sur SkillHub. Prend en charge `-SkipGit` / `-SkipSkillHub` / `-DryRun`.   |
| `scripts/hooks/pre-commit`  | Rappel de hook git local : avertit lorsque vous mettez en scène un changement de `CHANGELOG.md` (qui se libère automatiquement lors de l'envoi à `master`).                                   |
| `scripts/hooks/pre-push`    | Rappel de hook git local : confirme la version avant d'envoyer les changements de `CHANGELOG.md` à `master` ; procède automatiquement dans des environnements non interactifs/CI. |

> Ces hooks ne sont pas installés automatiquement. Créez un lien symbolique dans `.git/hooks/` si vous voulez les rappels, par exemple `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---


## Contribuer

Les PR et les problèmes sont les bienvenus. Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Licence

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)
