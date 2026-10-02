# Mode plan sans demandes d'autorisation pour les lectures

En mode plan, Claude Code approuve désormais tout seul les **lectures** faites par vos outils MCP : recherche de mails, lecture d'une page Notion, liste des tickets GitHub, etc. Les **écritures** (envoyer, créer, modifier, supprimer) demandent toujours votre accord.

## 1. Ce que c'est

Le mode plan sert à explorer avant d'agir : Claude lit, cherche, puis propose un plan. Mais dans Claude Desktop, chaque appel à un outil MCP pendant le plan affiche « Autoriser Claude à utiliser … ? », même pour une simple recherche. Un plan qui consulte dix sources vous demande dix validations.

Les réglages habituels n'y changent rien :
- `defaultMode: "bypassPermissions"` ne s'applique pas tant que la session est en mode plan.
- Des règles `permissions.allow` comme `mcp__gmail__search` ne lèvent pas le blocage du mode plan. Testé : l'appel reste refusé avec « Cannot call … while in plan mode ».

Ce qui marche, c'est un hook `PermissionRequest`. Claude Code l'appelle au moment précis où il s'apprête à vous demander l'autorisation, et le hook peut répondre à votre place.

## 2. Comment ça marche

```
Claude veut appeler un outil pendant le plan
        │
        ▼
Claude Code s'apprête à afficher « Autoriser … ? »
        │
        ▼
Hook PermissionRequest (plan-mode-allow-reads.sh)
        │
        ├─ mode ≠ plan ............................ ne fait rien
        ├─ nom d'outil MCP contenant un mot d'écriture
        │  (create, update, delete, send, replace, run,
        │  download…) .............................. demande normale
        ├─ nom d'outil MCP commençant par search_, list_,
        │  get_, read_, find_, fetch_, lookup_, describe_,
        │  show_, view_ ou count_ (ou égal à l'un de ces
        │  verbes), ou WebSearch ................... « allow » : pas de demande
        └─ tout le reste (Bash, Edit, WebFetch…) .. demande normale
```

Le hook ne décide que d'après le **nom de l'outil**, plus précisément la partie après le dernier `__`, mise en minuscules. Par exemple, `mcp__gmail__search_threads` donne `search_threads`, que le hook approuve. `mcp__gmail__send_email` donne `send_email`, qui reste soumis à votre accord. Le refus prime : `get_or_create_user` contient `create`, donc la demande s'affiche.

Les verbes ambigus ne sont volontairement pas approuvés :
- `query`, car une requête SQL peut écrire ;
- `download`, qui écrit sur le disque ;
- les noms en camelCase comme `getContact`.

Il approuve aussi `set_session_title`, l'outil de Claude Desktop qui renomme une session. C'est utile si vous utilisez le hook compagnon [claude-code-emoji-session-titles](https://github.com/Matthieusabourin2/claude-code-emoji-session-titles).

### Les risques, à lire avant d'installer

- **Un outil mal nommé passe sans demande.** Le hook ne lit pas la description des outils ; il fait confiance aux noms choisis par l'auteur du serveur MCP. Un outil `get_stats` qui écrirait en douce serait approuvé. Avant d'installer, parcourez les outils de vos serveurs (`/mcp` dans le terminal). En cas de doute, restreignez le motif (voir « Personnaliser »).
- **Une lecture peut ramener du contenu piégé.** Un mail ou une page lus pendant le plan peuvent contenir des instructions cachées (« prompt injection »). C'est pour cela que **WebFetch n'est pas approuvé** : une injection pourrait sinon envoyer vos données vers une URL quelconque sans que vous le voyiez. WebSearch est approuvé, car il ne fait qu'envoyer une requête à un moteur de recherche.

Les commandes Bash qui ne sont pas en lecture seule demandent toujours votre accord. Les lectures Bash de base (`ls`, `cat`, `grep`…) passent déjà sans demande en mode plan.

## 3. Comment l'utiliser

### Prérequis

- Claude Code : Claude Desktop (onglet Code), extension VS Code ou `claude -p`. Dans le terminal interactif, le mode plan ne bloque déjà rien quand le mode bypass est disponible.
- `jq` (`brew install jq` sur macOS)

### Installation

```bash
git clone https://github.com/Matthieusabourin2/claude-code-plan-mode-auto-reads.git
cd claude-code-plan-mode-auto-reads
./test.sh      # vérifie les décisions sur de faux outils, sans rien toucher
./install.sh
```

`install.sh` copie le hook dans `~/.claude/hooks/` et l'ajoute à `~/.claude/settings.json`. Le fichier est d'abord sauvegardé en `settings.json.bak-<date>`, et vos autres réglages restent tels quels. Relancer le script ne crée pas de doublon.

### Vérification

1. Quittez et relancez Claude Desktop.
2. Ouvrez une nouvelle session et passez en mode plan.
3. Demandez une lecture, par exemple « cherche mon dernier mail de X ».

L'appel doit passer sans fenêtre d'autorisation.

Pour voir les décisions du hook, ajoutez ceci au bloc `env` de `~/.claude/settings.json` :

```json
"env": { "PLAN_MODE_ALLOW_LOG": "/tmp/plan-mode-allow.log" }
```

Chaque appel y est noté avec `allow` ou `ask`.

### Personnaliser

La variable `PLAN_MODE_READ_PATTERN` remplace la liste des verbes approuvés. C'est une expression régulière étendue, appliquée à la partie du nom après le dernier `__`, en minuscules. La liste des mots d'écriture garde la priorité, et `WebSearch` et `set_session_title` ne sont pas concernés. Par exemple, pour n'approuver que les recherches :

```json
"env": { "PLAN_MODE_READ_PATTERN": "^search(_|$)" }
```

Si un serveur que vous connaissez bien utilise `query` en lecture seule, ajoutez-le : `"^(search|list|get|read|find|query)(_|$)"`.

### Désinstaller

```bash
./uninstall.sh
```

Chaque installation ou désinstallation laisse une sauvegarde `~/.claude/settings.json.bak-<date>`. Vous pouvez supprimer ces fichiers quand tout fonctionne.

## Licence

MIT
