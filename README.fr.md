# OpenCode MoA

> 🌐 Langues : Anglais · [中文](README.zh.md) · [日本語](README.ja.md) · [한국어](README.ko.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![OpenCode](https://img.shields.io/badge/OpenCode-%3E%3D1.3.4-orange.svg)](https://opencode.ai)

> 🔥 **Actuel (2026-07) :** modèle phare mis à jour vers **Kimi K3** — 2.8T params, 1M contexte, modèle de pointe. Quota OpenCode Go multiplié par 2 jusqu'au 24/07 (140 → 280 / 5h, puis retour à 140). Le plafond de qualité de MoA est maintenant à la tête du peloton.

> **Un point d'entrée de conversation, 22 modèles spécialisés collaborant automatiquement. Les tâches simples utilisent Flash (économique), les tâches complexes appellent le modèle phare (coûteux). Réduction des coûts jusqu'à ~90% (par rapport à tout phare) lorsque les tâches simples dominent la charge de travail et que les appels au phare sont minimisés — les économies réelles dépendent du mélange des tâches ; qualité du code significativement améliorée.**

<!-- ARCH-IMG -->
![OpenCode MoA Architecture](.github/moa-arch.png)
<!-- /ARCH-IMG -->

OpenCode MoA est un package de configuration de Mélange d'Agents pour OpenCode. Il permet à plusieurs modèles **de réfléchir au même problème simultanément**, puis de fusionner en une qualité de sortie qu'un seul modèle ne peut atteindre. Vous n'avez pas besoin de changer d'outils, d'écrire du code ou d'avoir un quota API — il suffit de déposer les fichiers dans votre projet et de redémarrer OpenCode.

**22 agents · 5 commandes · 3 compétences · déploiement en 30 secondes**

---


## Pourquoi avez-vous besoin de cela ?

Par défaut, OpenCode utilise un seul modèle du début à la fin. Changer un caractère et concevoir une architecture système utilisent le même prompt, la même température, le même contexte. Pas de division du travail.

**Trois problèmes :**

1. **Coût incontrôlable** — les tâches simples utilisent également le modèle coûteux, la facture mensuelle reste élevée
2. **Goulot d'étranglement de qualité** — un seul modèle a seulement une façon de penser, facilement coincé dans des angles morts
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
![Coût réduit jusqu'à 90%](.github/moa-cost.png)
<!-- /COST-IMG -->

Trois plans indépendants de trois modèles différents forment naturellement une structure de "consensus + divergence". Le modèle de fusion identifie ce qui est consensus et le conserve, et prend le meilleur là où ils divergent — quelque chose qu'un seul modèle ne peut pas faire.

---


## Prérequis

### Requis

| Exigence            | Commande de vérification         | Remarques                                                                                                                                                                                                 |
| ------------------- | -------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| OpenCode installé    | `opencode --version`             | **>= 1.3.4** (support `reasoningEffort`/`hidden`/`task` au niveau agent ; le fournisseur `openai-compatible` passe la réflexion de manière transparente, pas besoin de `forceReasoning`), [installer](https://opencode.ai/install) |
| Plan OpenCode Go    | console opencode.ai              | [S'abonner](https://opencode.ai/auth), premier mois 5 $, puis 10 $/mois                                                                                                                                 |
| Git installé        | `git --version`                  | Utilisé pour cloner le dépôt                                                                                                                                                                            |
| Clé API OpenCode Go | créée dans la console opencode.ai | Créée dans la console Zen (opencode.ai)                                                                                                                                                                  |

### Optionnel (nécessaire pour les scripts d'installation)

| Exigence          | Commande de vérification | Remarques                                                                     |
| ----------------- | ----------------------- | ----------------------------------------------------------------------------- |
| PowerShell Core   | `pwsh --version`       | nécessaire pour install.ps1, inclus avec Windows ou `brew install powershell`  |
| jq                | `jq --version`         | nécessaire pour install.sh pour la fusion JSON, `apt install jq` / `brew install jq` |

> Pas de pwsh/jq est acceptable — vous pouvez utiliser la Méthode 1 (déploiement automatique par IA) ou la Méthode 3 (fusion manuelle).

### Bureau vs CLI

- **CLI** : toutes les méthodes prises en charge
- **Bureau** : la Méthode 1 (déploiement automatique par IA) est la plus pratique ; les Méthodes 2/3 nécessitent d'abord une opération terminale

> ⚠️ **Le chemin de clé au niveau système est facile à mal placer** — orthographe correcte dans "Lire avant de déployer" ci-dessous. Un chemin incorrect entraîne "le déploiement réussit mais tous les agents ne peuvent pas se connecter".

> ⚠️ **Lire avant de déployer : ne pas mal placer le chemin de clé**
> Mettez le fournisseur + clé soit dans le **`opencode.json` au niveau projet** (par défaut, autonome) soit dans le **chemin partagé au niveau système** — choisissez **un**.
> Si vous utilisez le niveau système, le chemin correct est :
> 
> - Linux/macOS `~/.config/opencode/opencode.json`
> - Windows `%USERPROFILE%\.config\opencode\opencode.json` (**pas** `%APPDATA%\opencode`)
>   Un chemin incorrect au niveau système entraîne "le déploiement réussit mais tous les agents ne peuvent pas se connecter".

---

## Déploiement en 30 secondes

### Méthode 1 : Déploiement automatique par IA (recommandé)

1. Téléchargez [`docs/opencode-moa.en.md`](https://github.com/ZenHG/opencode-moa/blob/master/docs/opencode-moa.en.md)
2. Téléchargez ce document dans OpenCode et envoyez :

> Déployez tous les 22 agents, 5 commandes et 3 compétences de ce manuel dans le projet actuel

3. L'IA crée tous les fichiers automatiquement. **Redémarrez OpenCode** une fois terminé.

> Pas besoin de créer manuellement un fichier. Le manuel de déploiement est lui-même l'installateur.

### Méthode 2 : script d'installation en un clic (version script · compatible CLI)

```bash
# cloner le dépôt
git clone https://github.com/ZenHG/opencode-moa.git

# entrez dans votre répertoire de projet
cd your-project

# copiez le répertoire .opencode depuis le dépôt
cp -r ../opencode-moa/.opencode/ .

# exécutez le script d'installation (fusion automatique de la configuration, conserve votre clé API)
# Windows :
pwsh ../opencode-moa/install.ps1
# Linux/macOS :
bash ../opencode-moa/install.sh
```

> Le script d'installation sauvegarde automatiquement votre `opencode.json` d'origine, ne fusionnant que la configuration de MoA tout en conservant votre fournisseur et votre clé API.
> 
> Remarque : cette méthode copie le `.opencode/` groupé du dépôt tel quel — ses agents ont des **noms d'affichage en chinois**. Si vous souhaitez des agents avec des noms en anglais (pour pouvoir `@english-name`), utilisez plutôt la Méthode 1.

### Personnalisez n'importe quel modèle

MoA est un **modèle générique** — le modèle de chaque agent est juste un ID que vous pouvez changer. Chaque fichier d'agent commence par :

```yaml
model: opencode-go/<model-id>
```

Pour changer un modèle, modifiez cette ligne dans `.opencode/agents/<agent>.md` avec n'importe quel `provider/model-id` auquel vous avez accès (par exemple `opencode-go/kimi-k2.7-code`, `opencode-go/glm-5.2`). Pas besoin de réinstaller. Mélangez et assortissez librement — le modèle ne vous lie à rien.

### Méthode 3 : installation manuelle

```bash
# 1. cloner le dépôt
git clone https://github.com/ZenHG/opencode-moa.git

# 2. copier le répertoire .opencode
cp -r opencode-moa/.opencode/ your-project/

# 3. fusionner manuellement opencode.json (ne PAS remplacer directement !)
# ouvrez opencode.json, fusionnez les sections permission.task et agent de MoA
# conservez votre configuration de fournisseur et de modèle existante
```

> ⚠️ **Ne pas** utiliser `cat >>` pour ajouter — cela corrompt le format JSON. **Ne pas** remplacer directement — vous perdrez votre clé API.
> 
> Remarque : cette méthode copie le `.opencode/` groupé du dépôt tel quel — ses agents ont des **noms d'affichage en chinois**. Si vous souhaitez des agents avec des noms en anglais (pour pouvoir `@english-name`), utilisez plutôt la Méthode 1.

### Comment savoir si le déploiement a réussi ?

1. Après avoir redémarré OpenCode, appuyez sur `Tab` pour faire défiler les agents (client de bureau Windows : `Ctrl+.` fonctionne aussi) et voir "concierge-router"
2. Tapez `@tool-handler` et il répond
3. Exécutez le script de vérification : `pwsh .opencode/tests/T0-static-verify.ps1` (généré par le Bloc 5.5 manuel lors du déploiement), attendu tout PASS (FAIL=0 ; avec clé de niveau système, WARN compte également comme un pass)

### Rétrogradation en un clic

```bash
rm -rf your-project/.opencode/
# restaurez manuellement votre opencode.json (le script d'installation sauvegarde automatiquement un fichier .bak)
```

---


## Comment utiliser ?

**N'apprenez rien — parlez simplement.** Le concierge-router juge automatiquement la complexité de la tâche et envoie la chaîne d'agents correspondante.

| Ce que vous dites                     | Ce que fait le concierge-router                                   | Agents utilisés                     |
| -------------------------------------- | ---------------------------------------------------------------- | ----------------------------------- |
| "renommez cette variable"              | jugé comme une tâche simple                                      | swift (Flash)                       |
| "écrivez un module d'authentification utilisateur" | la couche d'outils rassemble → 3 intermédiaires en parallèle → fusion | tool-handler + trio intermédiaire + fuse |
| "concevez une architecture de microservices" | la couche d'outils rassemble → 3 phares en parallèle → fusion → mise en œuvre → QA | chaîne complète de 6 agents         |
| "restaurer l'UI de cette capture d'écran" | 3 experts frontend en parallèle → le leader choisit le meilleur  | quatuor frontend                    |
| message avec capture d'écran           | vision-translator convertit en texte → routage normal            | vision-translator                   |
| message avec journal d'erreurs / diagramme / contenu complexe | vision-translator décompose le contenu → routage normal  | vision-translator (rôle de secours) |

**Appels directs `@` :**

```
@swift aidez-moi à écrire un hello world
@tool-handler recherchez tous les TODO dans le projet
@flag-arch concevez une solution de file d'attente de messages
```

**Commandes en un clic :**

| Commande         | Scénario                                       |
| ---------------- | ---------------------------------------------- |
| `/moa-quick`     | tâche simple, traduction, changement de configuration |
| `/moa-medium`    | module de fonction, correction de bogue, refactorisation d'un seul fichier |
| `/moa-flagship`  | architecture système, grande refactorisation  |
| `/moa-frontend`  | restauration de l'UI, CSS, correction de capture d'écran |
| `/moa-describe`  | capture d'écran/image en texte                 |

---

## Architecture

```
                      concierge-router (Flash)
                                 │
                ┌────────────────┼─────────────────┐
                ▼                ▼                 ▼
             Couche outil     Couche opinion       Couche fusion
             Flash + MiMo      3 opinions parallèles prennent le meilleur
             (~80% appels)     (~18% appels)        (~2% appels)
```

**Couche outil** (Flash + MiMo) — lire le code, rechercher des fichiers, capture d'écran en texte. Pas cher et rapide, appelez librement.

**Couche opinion** (MiniMax / DeepSeek Pro / Qwen / MiMo-Pro) — plans de différentes perspectives. Trois opinions forment naturellement une structure de "consensus + divergence".

**Couche fusion** (Kimi K3 / Qwen-Max / GLM / DeepSeek Pro fallback) — maintenir le consensus, prendre le meilleur sur la divergence, avec un retour à DeepSeek V4 Pro si la fusion échoue. La fusion phare fonctionne maintenant sur **Kimi K3** (2.8T params, 1M contexte, modèle de pointe) — poussant le plafond de qualité de MoA à l'avant du peloton.

> ⚠️ Les ratios de volume d'appels ci-dessous (~80% / ~18% / ~2%) sont des **objectifs de conception**, pas des statistiques mesurées. Les ratios réels varient en fonction de la complexité des tâches.

---


## 22 Agents

> Le nom anglais est le rôle logique ; le chinois entre parenthèses est le **nom de fichier exact** sous `.opencode/agents/` — vous les appelez avec `@` (par exemple, `@门童路由员`).

```
concierge-router (门童路由员, Flash)
 │
 ├── Couche outil ─────────────────────────────────────────────
 │   tool-handler      (工具人, Flash    ) lire le code, rechercher des fichiers [+ auto-vérification matérielle]
 │   tool-handler-mimo (工具人-mimo, MiMo) lecture de fichier fiable (fallback + parallèle) [caché]
 │   swift             (闪电侠, Flash    ) tâches simples en une seule fois
 │   vision-translator (视觉翻译官, MiMo ) capture d'écran/UI→texte ; journaux/diagrammes/docs→décomposition
 │
 ├── extracteur-résiduel  (残差提取者,  Flash     ) analyser la divergence entre les plans
 ├── évaluateur-confiance (置信度评估者, DS Pro    ) évaluer la confiance du résultat de fusion
 │
 ├── Couche opinion intermédiaire ─────────────────────────────────────────────
 │   mid-eng      (中级·工程, Kimi K2.6 ) vue d'ingénierie
 │   mid-creative (中级·创意, Qwen3.7 Plus) vue créative
 │   mid-coder    (中级·码农, Flash     ) vue pragmatique
 │   mid-fuse     (中级·融合, Kimi      ) fusionner trois plans [max_tokens: 16384]
 │
 ├── Couche opinion phare ─────────────────────────────────────────────
 │   flag-arch (旗舰·架构, Qwen3.7 Max ) architecture de haut niveau
 │   flag-plan (旗舰·规划, GLM 5.2     ) planification structurée
 │   flag-eng  (旗舰·工程, MiniMax M3  ) mise en œuvre à grande échelle
 │   flag-fuse (旗舰·融合, Kimi K3     ) fusionner trois plans d'architecture [max_tokens: 16384]
 │   flag-impl (旗舰·实现, Flash       ) mettre en œuvre par plan fusionné [caché]
 │   flag-qa   (旗舰·质检, DeepSeek Pro) révision du plan + acceptation du code [max_tokens: 16384]
 │
 └── Couche opinion frontend ─────────────────────────────────────────────
     fe-restore (前端·还原, MiMo       ) restauration UI pixel-perfect
     fe-logic   (前端·逻辑, Qwen3.7 Plus) architecture des composants & gestion des états
     fe-motion  (前端·动效, MiMo-Pro   ) interaction & mouvement
     fe-lead    (前端·总工, GLM-5.2    ) choisir le meilleur des trois plans frontend [max_tokens: 16384]
```

Agent de secours (non dans la chaîne de routeur ci-dessus, appelé uniquement lorsque la fusion échoue) :

```
fallback (融合·保底, DeepSeek V4 Pro) — même fusion améliorée par résidu, utilisée lorsque flag-fuse / mid-fuse / fe-lead échouent
```

---


## Conception de tolérance aux pannes

### Chaîne de secours de la couche outil

L'échec de la couche outil ne fige pas — elle se dégrade automatiquement :

```
tool-handler (Flash) échoué → nouvelle tentative immédiate une fois
  → nouvelle tentative réussie → retour normal
  → nouvelle tentative échouée → tool-handler-mimo (MiMo) échoué → nouvelle tentative immédiate une fois
    → nouvelle tentative réussie → retour normal
    → nouvelle tentative échouée → demander à l'utilisateur :
      A. attendre quelques minutes et réessayer
      B. sauter la couche outil, appeler directement la couche opinion (coût plus élevé)
      C. passer au modèle gratuit
```

> La plupart des erreurs de fournisseur (502/503/délai d'attente) sont transitoires ; une nouvelle tentative rapide réussit généralement.

### Sauvegarde de la couche fusion

Si l'agent de fusion principal échoue (STUCK / ERROR_PROVIDER / délai d'attente / résultat vide), le concierge-router passe automatiquement à `@融合·保底` (DeepSeek V4 Pro, fallback) :

```
flag-fuse (旗舰·融合, Kimi K3) échoué
  → tâche(@融合·保底) (DeepSeek V4 Pro) → sortie du résultat de secours
mid-fuse (中级·融合, Kimi) échoué
  → tâche(@融合·保底) (DeepSeek V4 Pro) → sortie du résultat de secours
fe-lead (前端·总工, GLM-5.2) échoué
  → tâche(@融合·保底) (DeepSeek V4 Pro) → sortie du résultat de secours
```

L'agent de secours utilise le même processus de fusion améliorée par résidu.

### Tolérance à l'échec partiel de la couche opinion

Les agents d'opinion individuels (architecture/planification/ingénierie, restauration frontend/logique/mouvement, ingénierie créative/code intermédiaire) peuvent retourner des résultats vides ou expirer indépendamment. Le système gère cela avec grâce :

```
3 agents d'opinion parallèles dispatchés
  → tout agent retourne un résultat vide → réessayer cet agent une fois
    → nouvelle tentative réussie → continuer normalement
    → nouvelle tentative échouée → marquer comme "dégradé" et procéder avec N/3 entrées
      → 残差提取者 travaille uniquement avec les entrées disponibles
      → 旗舰·融合 applique des règles de fusion dégradées
      → la sortie porte l'étiquette "[Partiel] N/3 entrées"
      → le score de confiance est ajusté à la baisse
```

Règles de fusion dégradées (N < 3) :
- Le dénominateur de couverture du consensus est N, pas 3
- Les perspectives manquantes sont étiquetées `[Missing: nom de la perspective]`
- La couverture du consensus < 50% déclenche un avertissement de "fusion dégradée à faible confiance"
- La fusion à source unique (N=1) applique un facteur de pénalité de confiance de 0.7

> Cela empêche le pipeline de se bloquer (STUCK) lorsqu'un agent d'opinion échoue — une plainte courante des utilisateurs.

### Conditions préalables déclaratives des agents

L'activation des agents est régie par des métadonnées déclaratives `precondition`, pas par des règles de routage codées en dur. Chaque agent déclare quand il doit être actif :

| Agent | préconditions |
|-------|---------------|
| 闪电侠 | toujours |
| 工具人 | nécessite un contexte de code |
| 视觉翻译官 | primaire : `screenshot`; fallback : `error_log OR diagram OR long_document OR ambiguous_intent` |
| 中级·工程 | nécessite une complexité d'ingénierie |
| 中级·创意 | nécessite une complexité créative |
| 中级·码农 | nécessite une complexité de mise en œuvre |
| 旗舰·架构/规划/工程 | nécessite une complexité de conception système |
| 前端·还原/逻辑/动效 | nécessite une tâche frontend |
| 融合·保底 | activé lorsque la couche de fusion échoue ou que la couche d'opinion retourne des résultats partiels |

L'activation des conditions suit une logique de court-circuit : préconditions remplies → activer ; aucune remplie → demander confirmation à l'utilisateur. Cela remplace les règles de déclenchement codées en dur (comme "capture d'écran disponible → @vision-translator") par des préconditions déclarées par l'agent, auto-documentées.

### Visualisation des étapes du pipeline

Chaque décision de routage produit un identifiant d'étape afin que les utilisateurs puissent suivre les progrès du pipeline sans apprendre les numéros d'étape internes :

```
[Étape : Couche Outil] → [Étape : Couche Opinion] → [Étape : Couche Fusion] → [Étape : Couche Mise en œuvre]
```

Mapping étape-phase :
- `Couche Outil` — phase de collecte de matériel
- `Couche Opinion` — phase de conception de plan parallèle (intermédiaire / phare / frontend)
- `Couche Fusion` — phase de fusion et de vérification des plans
- `Couche Mise en œuvre` — phase de mise en œuvre et d'acceptation du code

### Rapport de progrès unifié

Les chemins de succès et d'échec suivent le même format de rapport, n'exposant jamais les noms des agents internes :

```
[Pipeline] mode=<lite|balanced|strict>  stage=<Couche Outil|Couche Opinion|Couche Fusion|Couche Mise en œuvre>  status=<idle|in_progress|complete|degraded|stuck>
  reason: <pourquoi cette étape>
  path: <Couche Outil|Chaîne intermédiaire|Chaîne phare|Chaîne frontend>
  fallback: <stratégie de récupération>
```

Indicateurs de statut :
- `in_progress` — exécution de l'étape actuelle
- `complete` — étape terminée avec succès
- `degraded` — fonctionnement avec des entrées partielles, confiance réduite
- `stuck` — tous les chemins de récupération épuisés, intervention de l'utilisateur nécessaire

### 闪电侠 Raccourci Parallèle

Lorsque le pipeline principal est en cours d'exécution, 闪电侠 peut être dispatché en parallèle pour des sous-tâches simples indépendantes :

```
Pipeline principal : Couche Outil → Couche Opinion → Couche Fusion → Couche Mise en œuvre
Voie parallèle : 闪电侠 (toujours prêt, fonctionne en parallèle avec le pipeline principal)
```

Conditions de déclenchement (n'importe laquelle) :
- L'instruction de l'utilisateur demande explicitement un travail parallèle ("faire X simultanément", "vérifier aussi rapidement Y")
- Une sous-tâche simple émerge pendant l'exécution du pipeline principal (par exemple, rechercher des TODOs pendant que les plans d'architecture sont conçus)
- L'utilisateur appelle directement @闪电侠

Limitations de portée :
- ✅ Tâches indépendantes sans dépendance sur la sortie du pipeline principal
- ✅ Opérations simples : recherche de fichiers, grep, requête de configuration, formatage
- ❌ Tâches qui produisent une entrée pour le pipeline principal
- ❌ Tâches de fusion d'opinion (doivent rester en série)
- ❌ Tâches de mise en œuvre et de QA (doivent rester en série)

Si 闪电侠 termine avant le pipeline principal, les résultats sont conservés et retournés ensemble à la fin. Si le pipeline principal termine en premier, les résultats de 闪电侠 sont retournés immédiatement. L'échec de 闪电侠 n'affecte pas l'exécution du pipeline principal.

### Isolation des permissions MCP

Les agents de la couche opinion sont interdits de lire le code directement (via `read: deny` + `bash: deny`), les empêchant de contourner la couche outil pour récupérer le matériel eux-mêmes :

- Couche outil : peut lire le code, rechercher des fichiers (a accès `read`/`bash`)
- Couche opinion : `read: deny` + `bash: deny`, peut seulement planifier en fonction du matériel de la couche outil
- Couche fusion : même restriction, peut seulement fusionner en fonction des trois opinions

> Remarque : Ce projet ne configure aucun serveur MCP. Le terme "isolement des permissions MCP" fait référence aux restrictions d'outils au niveau des agents (`read: deny` / `bash: deny`), pas à l'isolement au niveau des serveurs MCP.

### Sauvegarde sans matériel

Lorsque la couche opinion est appelée mais n'a pas de matériel (la couche outil a complètement échoué), elle demande à l'utilisateur :

- Choisir "donner le plan directement" → raisonnement logique pur basé sur la description des exigences (pas de lecture de code)
- Choisir "attendre la couche outil" → sortie ATTENTE, réessayer après la récupération de la couche outil

### Classification des erreurs

La couche outil produit une catégorie d'erreur claire en cas d'échec, au lieu de réessayer aveuglément :

- `ERROR_PROVIDER` — serveur 502/503/délai d'attente
- `ERROR_AUTH` — échec d'authentification
- `ERROR_UNKNOWN` — autres erreurs

---

## Coût

### Pourquoi ~90% économisé

MoA facture par un mélange pondéré du volume d'appels : ~80% outil de couche Flash, ~18% intermédiaire, ~2% phare. Estimez le prix unitaire de sortie effectif avec les prix par unité dans le tableau des coûts de cette section :

> **Important** : Les ratios 80/18/2 sont **la distribution de volume d'appels attendue conçue par l'architecture**, pas des proportions de coût mesurées. L'utilisation réelle dépend des types de tâches et de leur complexité.

| Couche      | Part | Prix unitaire de sortie /1M                                                                            | Pondéré |
| ----------- | ----- | ----------------------------------------------------------------------------------------------------- | ------- |
| Couche outil | 80%   | 0,28 $                                                                                                 | 0,224 $ |
| Intermédiaire | 18%   | ~2,10 $ (MiniMax 1,20 $ / DeepSeek Pro 3,48 $ / Qwen Plus 1,60 $ / **Kimi K2.7 4,00 $ moyenne mid-fuse**) | 0,378 $ |
| Phare      | 2%    | ~6,00 $ (Qwen/GLM/MiniMax ~4-7 $ + **Kimi K3 15,00 $ flag-fuse**)                                   | 0,12 $  |

Prix unitaire de sortie effectif mélangé ≈ **0,72 $ / 1M**. Comparé à "GLM tout phare 7,50 $" → environ 10% → **~90% économisé** ; comparé à "DeepSeek Pro tout intermédiaire 3,48 $" → environ 21% → **~79% économisé**. La revendication "économiser 90%" est la véritable valeur par rapport à la référence phare.

### Plan OpenCode Go

MoA est basé sur le plan [OpenCode Go](https://opencode.ai/docs/zh-cn/go/), **premier mois 5 $, puis 10 $/mois**.

**Limites d'utilisation :**

| Fenêtre temporelle | Quota |
| ------------------ | ----- |
| Toutes les 5 heures | 12 $  |
| Hebdomadaire       | 30 $  |
| Mensuel            | 60 $  |

Les limites sont définies par la valeur en dollars. Les modèles bon marché (Flash) peuvent être utilisés plus souvent, les modèles coûteux (GLM) moins souvent.

### Quota mensuel par couche

| Couche      | Modèle           | Prix unitaire (entrée/sortie par 1M) | Quota mensuel | Fréquence d'appel      |
| ----------- | ---------------- | ------------------------------------- | ------------- | ---------------------- |
| Couche outil | Flash           | 0,14 $ / 0,28 $                       | 158,150       | ~80%                  |
| Couche outil | MiMo-V2.5       | 0,14 $ / 0,28 $                       | 150,400       | (utiliser librement)  |
| Opinion     | MiniMax M3      | 0,30 $ / 1,20 $                       | 16,000        | ~18%                  |
| Opinion     | DeepSeek V4 Pro | 1,74 $ / 3,48 $                       | 17,150        |                        |
| Opinion     | Qwen3.7 Plus    | 0,40 $ / 1,60 $                       | 21,600        |                        |
| Fusion      | Kimi K2.7 Code  | 0,95 $ / 4,00 $                       | 9,250         | ~2% (fusion intermédiaire) |
| Fusion      | Kimi K3         | 3,00 $ / 15,00 $                      | 280           | ~2% (fusion phare)    |
| Fusion      | GLM-5.2         | 1,40 $ / 4,40 $                       | 4,300         | ~2% (lead frontend)   |

> Tous les identifiants de modèle ne sont que des déclarations ; remplacez-les par le modèle de votre choix.

![Quota OpenCode Go par 5h](.github/quota-chart-en.svg)

### Après avoir atteint la limite

- **Repli sur modèle gratuit** — après que Go ait atteint la limite, vous pouvez continuer à utiliser des modèles gratuits
- **Repli sur solde Zen** — activez "utiliser le solde" dans la console ; après la limite de Go, utilisation automatique du solde Zen

### Modèles gratuits

OpenCode Zen fournit des modèles gratuits en dernier recours :

| Modèle                  | Caractéristique                     |
| ----------------------- | ----------------------------------- |
| DeepSeek V4 Flash Free  | rapide, mais contexte limité        |
| MiMo-V2.5 Free          | meilleure qualité, mais peut être lent |
| North Mini Code Free    | fourni par Cohere                  |
| Nemotron 3 Ultra Free   | point de terminaison gratuit NVIDIA |

> ⚠️ Limites des modèles gratuits : fenêtre de contexte plus petite, réponse potentiellement plus lente, les données peuvent être utilisées pour l'entraînement, gratuit pour une durée limitée.

---


## Sécurité

| Protection                 | Effet                                                                                                                                                                                        |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Protection globale         | appel d'outil non déclaré → confirmation popup                                                                                                                                              |
| Isolement des permissions d'agent | chaque agent ne peut utiliser que les outils autorisés                                                                                                                                     |
| Isolement des permissions MCP   | couche d'opinion interdite de lire le code (lecture : refuser / bash : refuser), empêche de contourner la couche d'outil (le projet n'a pas de serveur MCP configuré ; "MCP" ici fait référence aux restrictions d'outil au niveau de l'agent) |
| Liste blanche de tâches    | le routeur concierge ne peut appeler que les agents déclarés                                                                                                                                 |
| Chaîne de secours          | échec de la couche d'outil → demander à l'utilisateur → attendre/sauter/modèle gratuit                                                                                                       |
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
# attendu : tout PASS / FAIL=0 (avec clé au niveau système, WARN compte également comme un succès)

# exécutez les trois couches en même temps
pwsh .opencode/tests/run-all.ps1
```

| Script                    | Couche | Ce qu'il fait                                                                            | Mode                 |
| ------------------------- | ----- | --------------------------------------------------------------------------------------- | -------------------- |
| `T0-static-verify.ps1`    | 0     | Vérifie la structure des fichiers, les comptes d'agent/commande/compétence, les ancres README, la correction des chemins clés | Automatique          |
| `T1-behavioral-guide.ps1` | 1     | Imprime une liste de contrôle étape par étape pour le comportement de routage / d'opinion / de fusion                 | Manuel (dans OpenCode) |
| `T2-moa-smoke-guide.ps1`  | 2     | Imprime une liste de contrôle de test de validation pour les commandes `/moa-*` de bout en bout                          | Manuel (dans OpenCode) |
| `run-all.ps1`             | 0–2   | Exécute T0 puis imprime les listes de contrôle guidées T1/T2                                         | Mixte                |

---


## FAQ

### Installation

**Q : J'ai déjà un opencode.json, sera-t-il écrasé ?**
R : Non. Le script d'installation ne fusionne que la configuration `permission`, `agent`, `default_agent` de MoA, en conservant votre `provider`, `model`, etc. Le fichier original est sauvegardé automatiquement sous `.bak.timestamp`.

**Q : Windows n'a pas de commande `cp`, que dois-je faire ?**
R : Utilisez `Copy-Item` ou `xcopy` :

```powershell
# PowerShell
Copy-Item -Recurse -Force opencode-moa\.opencode .\.opencode
# CMD
xcopy opencode-moa\.opencode .\.opencode /E /I /Y
```

**Q : Puis-je installer sans pwsh/jq ?**
R : Oui. Utilisez la Méthode 1 (déploiement automatique par IA) ou la Méthode 3 (fusion manuelle de la configuration).

**Q : Comment installer sur l'application de bureau ?**
R : La Méthode 1 est la plus pratique — faites glisser `docs/opencode-moa.en.md` dans la boîte de chat et laissez l'IA déployer automatiquement. Les Méthodes 2/3 nécessitent d'opérer d'abord dans un terminal (CMD/PowerShell/Terminal).

### Utilisation

**Q : Je ne vois pas "concierge-router" ?**
R : Consultez les trois vérifications sous "déploiement en 30 secondes → Comment savoir si le déploiement a réussi" : `opencode.json` à la racine du projet, 22 .md sous `.opencode/agents/`, changez avec `Tab` après le redémarrage (client de bureau Windows : `Ctrl+.` fonctionne également).

**Q : `@tool-handler` pas de réponse ?**
R : Confirmez que `.opencode/agents/tool-handler.md` existe et que le format du frontmatter est correct.

**Q : Erreur "modèle non trouvé" ?**
R : Le format de l'ID du modèle doit être `provider/model-id` (par exemple `opencode-go/kimi-k2.7-code`). Enregistrez le fournisseur correspondant dans le fichier de configuration (niveau système `~/.config/opencode/opencode.json` ou projet `opencode.json`), puis utilisez `/models` dans le TUI pour voir les modèles disponibles.

**Q : Comment revenir à l'agent de construction/plan original ?**
R : Appuyez sur `Tab` pour changer (client de bureau Windows : `Ctrl+.` fonctionne également), ou tapez `/build`, `/plan`. MoA n'affecte pas les agents intégrés.

**Q : Je veux utiliser mon propre modèle, pas le plan Go ?**
R : Il suffit de changer le champ `model` de l'agent :

```yaml
# .opencode/agents/mid-eng.md
model: opencode-go/glm-5.2
```

**Q : Puis-je supprimer le dépôt après le déploiement ?**
R : Oui. MoA est déjà copié dans le répertoire `.opencode/` de votre projet ; le dépôt original peut être supprimé.

**Q : Comment déployer sur plusieurs projets ?**
R : Déployez chaque projet séparément. `.opencode/` est une configuration au niveau du projet et n'affecte pas les autres projets.

### Repli

**Q : Toute la couche d'outils est en panne, que faire maintenant ?**
R : Consultez "Conception de tolérance aux pannes → Chaîne de repli" ci-dessus : MoA demande à l'utilisateur de choisir A. attendre quelques minutes / B. sauter la couche d'outils et appeler directement la couche d'opinion (coût plus élevé).

**Q : Où sont les modèles gratuits ?**
R : Consultez "Coût → Modèles gratuits" ci-dessus : utilisez `/models` pour ouvrir la liste des modèles et en choisir un étiqueté "Gratuit" (client de bureau Windows : `Ctrl+'` fonctionne également) (DeepSeek V4 Flash Free, MiMo-V2.5 Free, North Mini Code Free, etc.). Les modèles gratuits ont un contexte limité, peuvent être plus lents et les données peuvent être utilisées pour l'entraînement.

---

## Outils de mainteneur (non nécessaires pour les utilisateurs finaux)

Les fichiers suivants sont destinés aux **mainteneurs de repo**, pas pour déployer MoA. Les utilisateurs finaux peuvent les ignorer.

| Fichier                       | Objectif                                                                                                                                           |
| ----------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| `deploy-sync.ps1`            | Réservé aux mainteneurs — synchronise le repo avec GitHub et télécharge la compétence `opencode-moa` sur SkillHub. Prend en charge `-SkipGit` / `-SkipSkillHub` / `-DryRun`.   |
| `scripts/hooks/pre-commit`    | Rappel de hook git local : avertit lorsque vous préparez un changement dans `CHANGELOG.md` (qui se libère automatiquement lors d'un push vers `master`).                                   |
| `scripts/hooks/pre-push`      | Rappel de hook git local : confirme la version avant de pousser les changements de `CHANGELOG.md` vers `master` ; continue automatiquement dans des environnements non interactifs/CI. |

> Ces hooks ne sont pas installés automatiquement. Créez un lien symbolique dans `.git/hooks/` si vous voulez les rappels, par exemple `ln -s ../../scripts/hooks/pre-push .git/hooks/pre-push`.

---


## Contribuer

Les PR et les problèmes sont les bienvenus. Voir [CONTRIBUTING.md](CONTRIBUTING.md).

---


## Licence

[MIT](LICENSE) · [OpenCode MoA](https://github.com/ZenHG/opencode-moa)

<!-- ci-trigger-rate-limit-fix-v2 -->
