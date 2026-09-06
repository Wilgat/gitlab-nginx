**file**: docs/requirements/requirement-shell-sudo-command.md  
**Requirement-ID**: `RQ-SHELL-SUDO-COMMAND`  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth for in-tool `sudo`** in `./gitlab-nginx`: every wrap, the **studied** allow table (binary, verb, operand, dest, NOPASSWD), and check-before-sudo.

**Scope:** Call sites inside the ship unit that invoke `sudo`; argv they may pass; fail-closed when not permitted.  
**Out of scope:** Writing `/etc/sudoers.d/*` fragments for `nginx-adm` / `gitlab-adm` (domain setup owns those files); operator typing `sudo gitlab-nginx run` in a shell (that is the human prefix, not an in-tool wrap).

### 1.1 Human-facing

**In one sentence:** When this program itself runs `sudo`, it may only run the commands in the table below — not a free-form root shell.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | You already started setup as root (`sudo gitlab-nginx run`) | root session |
| The other role | Dedicated `nginx-adm` runs `nginx -t` via `sudo -u` | config test |
| Not this file | The sudoers **files** created for those dedicated accounts | domain requirement |

| Includes | Excludes |
|----------|----------|
| `sudo systemctl stop nginx`; `sudo -u nginx-adm nginx -t` | Guessing `/etc/{{username}}/{{service}}` as dest |
| Check before sudo | `sudo true` / `sudo mkdir` as grant proof |
| Fail closed if wrap is needed and not root | Treating `sudo gitlab-nginx` in help text as an in-tool wrap |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-nginx` | program file | live `sudo` lines |
| `sudo gitlab-nginx run` | command | host setup that reaches those lines |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Run full setup | The program may stop nginx via `systemctl` and test nginx **as** `nginx-adm`. It must not invent extra sudo argv. | `sudo gitlab-nginx run` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Wrap discipline

1. **MUST** treat every in-tool `sudo` as a wrap: check identity/need first; then invoke only an allow-listed argv.  
2. **MUST NOT** probe `sudo true`, `sudo mkdir`, or `sudo cp` as proof of a grant.  
3. **MUST NOT** guess dest or argv. Fill the allow table from ship-unit study (this product does not ship a `print-sudoers` CLI).  
4. Help text that tells a **human** to type `sudo gitlab-nginx …` is **not** an in-tool wrap.

### 2.2 Studied sudo allow table (this product)

Study evidence: `./gitlab-nginx` functions `stop_nginx_early` and the nginx test/start step of interactive `run` (grep `sudo systemctl` / `sudo -u nginx-adm`). No `print-sudoers` verb. No `/etc/sudoers.d/gitlab-nginx-*` fragment for the **invoking** operator — setup is already root. Dedicated-account fragments are domain-owned.

| Binary | Verb / argv | Operand | Runas | Fragment dest | NOPASSWD? | This wrap? | Study evidence |
|--------|-------------|---------|-------|---------------|-----------|------------|----------------|
| `systemctl` (PATH) | `stop` | `nginx` | root (already) | none for this wrap — invoker is root | n/a | **yes** | `stop_nginx_early`: `sudo systemctl stop nginx` |
| `nginx` (PATH) | `-t` | none | `nginx-adm` | `/etc/sudoers.d` fragment for `nginx-adm` (domain) | yes on that fragment when installed | **yes** | `sudo -u nginx-adm nginx -t` |

**MUST NOT** add `backup *`, restore, chmod of unrelated trees, or a harness dest `/etc/{{username}}/{{service}}` for these wraps.

### 2.3 Check before sudo

1. Domain mutating commands **MUST** `check_root` (or equivalent) before host mutation.  
2. `sudo -u nginx-adm` **MUST** run only after that account exists (setup sequence).  
3. Non-root `nginx-conf` / `run` / `remove-lpu` / `ssh-hostname` **MUST** fail closed without partial sudo.

### 2.4 Implementation Notes (this project)

| Item | Value |
|------|--------|
| `util_sudo` helper | **Gap** — live sites call `sudo` directly; future wrap **SHOULD** centralize without changing argv |
| Operator prefix in help | Human `sudo gitlab-nginx run` — not a wrap |
| Dedicated sudoers files | Owned by `requirement-domain-gitlab-nginx` (nginx-adm / gitlab-adm) |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. **MUST NOT** implement or enable in-tool `sudo`, wrap `apt`/`dnf`, create dedicated system users, or recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** both rows in the allow table are unused on that class (no `systemctl`, no `nginx-adm`).

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Fail closed; never probe random sudo.  
- **Intentional:** Closed argv table from disk study.  
- **Anti-fragile:** Root check happens even if sudo is a no-op under uid 0.  
- **Over-protect:** Do not widen argv because “we are already root.”

## 4. Protection Rule (Sacred)

**MUST NOT:**

1. Guess dest or argv.  
2. Treat harness `/etc/{{username}}/{{service}}` as this product’s wrap dest.  
3. Mark sibling verbs this CLI does not invoke as **This wrap? = yes**.  
4. Keep wrap bodies only on the coding-style requirement.  
5. Enable these wraps on Termux / Git Bash / Windows cmd.

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GLN-07** | `tests/test_domain.sh` | have |
| **TP-GLN-08** | `tests/test_domain.sh` | have |
| **TP-GLN-12** | `tests/test_domain.sh` | have |
| **TP-GLN-13** | `tests/test_domain.sh` | have |

**Map:** `reviews/test-plan.md`.

## 5. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-domain-gitlab-nginx.md` | Host setup + dedicated-account sudoers |
| `docs/requirements/requirement-shell-script-coding.md` | Coding-style pointer |
| `./gitlab-nginx` | Implementation under test |

**Last Updated**: 2026-09-06  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
