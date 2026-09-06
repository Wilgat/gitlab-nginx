**file**: docs/requirements/requirement-shell-script-coding.md  
**Requirement-ID**: `RQ-SHELL-SCRIPT-CODING`  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth for POSIX `/bin/sh` coding style** of `./gitlab-nginx`. **Without this file, portable learned lessons arrive raw** — agents would treat coding skills as product law. This file is the specialize-in home.

**Scope:** POSIX subset, function headers, safe defaults, `set -u` without `set -e`, no-capture of `read` helpers, check-before-sudo (bodies live on `requirement-shell-sudo-command`), product-source cites live requirements only.  
**Out of scope (own-or-point):** Full `out_*` catalog (`requirement-shell-output-requirements`); prefix table (`requirement-shell-modular-function-design`); TTY mode matrix (`requirement-shell-interactive-vs-noninteractive`); cache/persistence roots (`requirement-shell-cli-storage`).

### 1.1 Human-facing

**In one sentence:** Maintainers write `./gitlab-nginx` in portable `/bin/sh` so a person can install and run it on a thin Linux box without bash-only tricks.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | You edit the one program file people install | `./gitlab-nginx` |
| The other role | Reviewers check headers, defaults, and “no `$()` around prompts” | `gitlab-nginx help` still works after a surgical edit |
| Not this file | Command names, checksum algorithm, GitLab setup steps | peer requirements |

| Includes | Excludes |
|----------|----------|
| POSIX `/bin/sh`, function headers, `: "${VAR:=…}"` defaults | Treating bash arrays / `[[` as product law |
| Ban `$()` of `prompt_*` | Re-owning the `out_*` catalog |
| Point sudo wraps at the sudo requirement | Guessing sudoers dest/argv here |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-nginx` | program file people install | live coding |
| `gitlab-nginx help` | command | listed verbs still match dispatch |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Change a helper | Keep the defensive header, set defaults first, talk to people through `out_*`. Do not wrap `prompt_ask` in `$()`. | edit `./gitlab-nginx` then `sh -n ./gitlab-nginx` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Language and interpreter

1. **MUST** target POSIX `/bin/sh` (dash / busybox ash / bash-as-sh subset that `tests/` pass).  
2. **MUST NOT** require bash arrays, `[[ ]]`, process substitution, or `source` of bash-only files as product law.  
3. **MUST** keep a `#!/bin/sh` (or equivalent POSIX) shebang on the ship unit.

### 2.2 Shell options

1. **MUST** run under `set -u` (nounset) with a default for every variable the function reads.  
2. **MUST NOT** enable `set -e` as the global product policy (fail closed via `out_die` / checked status instead).  
3. **MUST** use `: "${VAR:=default}"` (or `${VAR:?}`) at the top of each function body for variables that function uses.

### 2.3 Function shape (own)

1. **MUST** give every new function a categorized prefix (table owned by `requirement-shell-modular-function-design` — do not fork).  
2. **MUST** keep a defensive header (purpose, CIAO mapping, “do not simplify” when the block is a Protection Zone, last reviewed).  
3. **MUST NOT** add bare functions named `main`, `help`, `install`, `about`.

### 2.4 Output and prompts (point)

1. User-facing messages **MUST** go through `out_*` (`requirement-shell-output-requirements`).  
2. Interactive capability (`[ -t 0 ]` / `[ -t 1 ]`) **MUST** be measured **outside** functions; `prompt_*` **MUST** consume `TTY` (detail on `requirement-shell-interactive-vs-noninteractive`).  
3. **MUST NOT** capture `prompt_yes_no` / `prompt_ask` with `$()` (the `read` would run in a subshell). Call them in the current shell and use the documented return variable.

### 2.5 Sudo (point)

In-tool `sudo` **MUST** go through the wrap and allow table on `requirement-shell-sudo-command`. This file **MUST NOT** keep sudo argv bodies as its only home. **MUST** check before sudo.

### 2.6 Product-source comments

Comments in `./gitlab-nginx` that claim law **MUST** cite live `requirement-*.md` files registered in `docs/requirements/index.md` — never templates or skills as authority.

### 2.7 Implementation Notes (this project)

| Item | Value |
|------|--------|
| Ship unit | `./gitlab-nginx` |
| Interpreter | `/bin/sh` |
| Nounset | `set -u` with Config defaults at file top and function-local `: "${…:=}"` |
| Global `set -e` | not used |
| Prefixes | `out_` `inst_` `app_` `util_` `ver_` `path_` `prompt_` plus domain helpers already in the file |
| Prompt capture | `prompt_ask` is a data-return helper (class B stdout) **and** prints prompt text via `out_*`; callers **MUST NOT** `_x=$(prompt_ask …)` for the **choice** of a `read` helper |
| Sudo sites | `sudo systemctl stop nginx`; `sudo -u nginx-adm nginx -t` — see `requirement-shell-sudo-command` |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. Do not wrap `sudo`, do not wrap Linux `apt`/`dnf`, do not create dedicated system users, and do not recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** coding helpers stay POSIX and Type 0-capable; do not add bash-only or sudo-required helpers as the default path.

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Assume a thin `/bin/sh` and missing bash.  
- **Intentional:** Headers and prefixes make ownership obvious.  
- **Anti-fragile:** Survives dash, busybox, `curl | sh`.  
- **Over-protect:** Do not strip headers or introduce `$()` around `read` for speed.

## 4. Protection Rule (Sacred)

**MUST NOT:**

1. Delete this file while the workspace remains software-development.  
2. Tell agents to follow coding skills as product law instead of this file + pointed peers.  
3. Enable global `set -e` as a “cleanup.”  
4. Capture `prompt_*` with `$()`.  
5. Duplicate full `out_*` / prefix / TTY tables here.

## 5. Definition of done

1. Ship unit stays POSIX `/bin/sh` and `sh -n` clean.  
2. New helpers use a defined prefix, defaults, and `out_*` for people-facing text.  
3. Sudo argv lives on `requirement-shell-sudo-command`.  
4. `tests/test_cli.sh` syntax case stays green.

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-01** | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`.

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-modular-function-design.md` | Prefix table |
| `docs/requirements/requirement-shell-output-requirements.md` | `out_*` |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | TTY / prompts |
| `docs/requirements/requirement-shell-sudo-command.md` | In-tool sudo allow table |
| `./gitlab-nginx` | Implementation under test |

**Last Updated**: 2026-09-06  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
