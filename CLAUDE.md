# CLAUDE.md — Claude Agent Instructions

@AGENTS.md

---

## Claude-Specific Instructions

**AGENTS.md is the main source of truth.** Follow all rules defined there without exception.

### Using Claude Skills

When working on this project, activate the relevant Claude-installed skill before responding:

| Task Type | Skill to Use |
|---|---|
| Starting any conversation | `start-flutter-craft` |
| Writing or reviewing Dart code | `flutter-dart-specialist` |
| Reviewing code quality | `flutter-code-reviewer` |
| Any Firebase feature or config | `using-firebase` |
| Writing tests | `flutter-testing` |
| Debugging errors or bugs | `flutter-debugging` |

**Rule:** If a skill applies (even 1% chance), read its `SKILL.md` file BEFORE responding.

### Claude Behavior Rules

1. **Ask before acting** on anything listed in Section 10 of AGENTS.md ("Things AI Must NOT Do Without Asking").
2. **Always run `flutter analyze`** before claiming any implementation is correct or complete.
3. **Follow the skill chain** defined in AGENTS.md Section 11 for all feature work.
4. **Reference AGENTS.md** when making architecture or naming decisions — do not invent new patterns.
5. **Be concise.** Prefer bullet points and code blocks over long prose explanations.
