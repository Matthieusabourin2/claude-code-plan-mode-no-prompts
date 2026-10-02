# Mode plan sans aucune demande d'autorisation

En mode plan, Claude Code ne vous demande plus jamais « Autoriser Claude à utiliser … ? ». Tous les appels d'outils sont approuvés automatiquement, **écritures comprises**.

> ⚠️ **À lire avant d'installer.** Ce hook supprime le filet de sécurité du mode plan. Pendant la phase de plan, Claude peut, sans vous demander :
> - envoyer un mail (`send_email`), répondre, transférer ;
> - créer, modifier, remplacer ou supprimer des données dans vos outils MCP (`create_*`, `update_*`, `replace_*`, `delete_*`, `query` SQL, etc.) ;
> - télécharger des fichiers sur votre disque (`download_*`) ;
> - exécuter n'importe quelle commande Bash, éditer ou écrire des fichiers ;
> - appeler n'importe quelle URL avec WebFetch.
>
> Claude reste *instruit* de ne rien modifier avant que vous ayez validé le plan, et il respecte en général cette consigne. Mais plus rien ne l'y *oblige*. Si vous voulez garder l'accord pour les écritures, utilisez le mode lecture seule (voir plus bas).

## 1. Ce que c'est

Le mode plan sert à explorer avant d'agir : Claude lit, cherche, puis propose un plan. Mais dans Claude Desktop, chaque appel à un outil MCP pendant le plan affiche une demande d'autorisation, même pour une simple recherche dans vos mails. Un plan qui consulte dix sources vous demande dix validations.

Les réglages habituels n'y changent rien :
- `defaultMode: "bypassPermissions"` ne s'applique pas tant que la session est en mode plan.
- Des règles `permissions.allow` comme `mcp__gmail__search` ne lèvent pas le blocage du mode plan. Testé : l'appel reste refusé avec « Cannot call … while in plan mode ».

Ce qui marche, c'est un hook `PermissionRequest`. Claude Code l'appelle au moment précis où il s'apprête à vous demander l'autorisation, et le hook répond « oui » à votre place.

## 2. Comment ça marche

```
Claude veut appeler un outil pendant le plan
        │
        ▼
Claude Code s'apprête à afficher « Autoriser … ? »
        │
        ▼
Hook PermissionRequest (plan-mode-no-prompts.sh)
        │
        ├─ mode ≠ plan ...................... ne fait rien (comportement normal)
        ├─ ExitPlanMode, AskUserQuestion .... ne fait rien (voir ci-dessous)
        └─ tout autre outil ................. « allow » : pas de demande
```

Deux outils restent volontairement en dehors, car ce ne sont pas des autorisations :
- **ExitPlanMode**, la validation du plan. Si elle était approuvée automatiquement, Claude passerait à l'exécution sans que vous ayez relu son plan, et le mode plan n'aurait plus de raison d'être.
- **AskUserQuestion**, quand Claude vous pose une question à choix.

### Les risques en clair

- **Écritures sans accord.** Tout ce qui est listé dans l'encadré ci-dessus peut se produire pendant le plan sans que vous le voyiez venir.
- **Contenu piégé.** Un mail ou une page web lus pendant le plan peuvent contenir des instructions cachées (« prompt injection »). Sans demande d'autorisation, une telle injection pourrait déclencher un envoi de mail ou un appel WebFetch qui fait sortir vos données.
- **Ce qui peut encore demander.** Le hook répond aux demandes que Claude Code lui transmet. Les écritures dans certains chemins protégés (`.git`, `.claude`…) et les outils MCP qui exigent explicitement une interaction (`requiresUserInteraction`) peuvent encore afficher une demande.

### Mode lecture seule (optionnel)

Avec `PLAN_MODE_READS_ONLY=1`, le hook n'approuve que :
- les outils MCP dont le nom commence par `search_`, `list_`, `get_`, `read_`, `find_`, `fetch_`, `lookup_`, `describe_`, `show_`, `view_` ou `count_`, sans aucun mot d'écriture (`create`, `delete`, `send`, `replace`, `download`…) ;
- WebSearch ;
- le renommage de session de Claude Desktop.

Tout le reste (Bash, Edit, WebFetch, `query`, écritures MCP) redemande votre accord. Le tri se fait uniquement sur le nom de l'outil : un outil mal nommé par l'auteur de son serveur MCP pourrait passer.

```json
"env": { "PLAN_MODE_READS_ONLY": "1" }
```

La variable `PLAN_MODE_READ_PATTERN` remplace la liste des verbes de lecture. C'est une expression régulière étendue, appliquée à la partie du nom après le dernier `__`, en minuscules.

## 3. Comment l'utiliser

### Prérequis

- Claude Code : Claude Desktop (onglet Code), extension VS Code ou `claude -p`. Dans le terminal interactif, le mode plan ne bloque déjà rien quand le mode bypass est disponible.
- `jq` (`brew install jq` sur macOS)

### Installation

```bash
git clone https://github.com/Matthieusabourin2/claude-code-plan-mode-no-prompts.git
cd claude-code-plan-mode-no-prompts
./test.sh      # vérifie les décisions sur de faux outils, sans rien toucher
./install.sh
```

`install.sh` copie le hook dans `~/.claude/hooks/` et l'ajoute à `~/.claude/settings.json`. Le fichier est d'abord sauvegardé en `settings.json.bak-<date>`, et vos autres réglages restent tels quels. Relancer le script ne crée pas de doublon.

### Vérification

1. Quittez et relancez Claude Desktop.
2. Ouvrez une nouvelle session et passez en mode plan.
3. Demandez une recherche, par exemple « cherche mon dernier mail de X ».

Aucune fenêtre d'autorisation ne doit apparaître.

Pour voir les décisions du hook, ajoutez ceci au bloc `env` de `~/.claude/settings.json` :

```json
"env": { "PLAN_MODE_ALLOW_LOG": "/tmp/plan-mode.log" }
```

Chaque demande y est notée avec `allow` ou `ask`.

Ce hook va bien avec [claude-code-emoji-session-titles](https://github.com/Matthieusabourin2/claude-code-emoji-session-titles) : le renommage automatique de session passe lui aussi sans demande en mode plan.

### Désinstaller

```bash
./uninstall.sh
```

Chaque installation ou désinstallation laisse une sauvegarde `~/.claude/settings.json.bak-<date>`. Vous pouvez supprimer ces fichiers quand tout fonctionne.

## Licence

MIT
