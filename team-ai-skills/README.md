# Team AI Skills

This repository packages the Firebase skills your team uses into one shareable bundle.

## Included Skills

- `firebase-basics`
- `firebase-auth-basics`
- `firebase-firestore`
- `firebase-security-rules-auditor`

## Layout

- `plugins/firebase-team-skills/` contains the actual shared plugin and skill folders.
- `.claude-plugin/marketplace.json` lets Claude Code treat this repo as a marketplace.
- `.agents/plugins/marketplace.json` gives Codex a repo-local marketplace entry.

## Team Use

### Claude Code

1. Push this folder to its own GitHub repository.
2. Run `/plugin marketplace add <owner>/<repo>`.
3. Run `/plugin install firebase-team-skills@team-ai-skills`.

To make it project-wide in Claude Code, install with project scope:

```text
/plugin install firebase-team-skills@team-ai-skills --scope project
```

### Codex

Use the plugin at `plugins/firebase-team-skills/`, or copy the folders inside `plugins/firebase-team-skills/skills/` into `~/.codex/skills/`.

### Antigravity

Copy or symlink the folders inside `plugins/firebase-team-skills/skills/` into `~/.gemini/antigravity/skills/`, or into a project-level skills folder if your team uses one.
