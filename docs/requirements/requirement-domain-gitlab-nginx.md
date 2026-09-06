**file**: docs/requirements/requirement-domain-gitlab-nginx.md  
**Requirement-ID**: `RQ-DOMAIN-GITLAB-NGINX`  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth for domain product law** of the **gitlab-nginx** POSIX shell CLI: **GitLab CE + external Nginx + Let's Encrypt setup beyond installing this program itself**.

**Specialized from:** bootstrap product **selfmanaged** (Type 0 architecture inheritance: `out_*` / `inst_*` / `app_*`) + legacy gitlab-nginx 2.2.0 domain DNA (13-step setup, nginx-adm / gitlab-adm least privilege, Cloudflare-aware SSH hostname).

It owns the **four domain pillars**:

1. **Specialized CLI subcommands** (verbs, operands, flags, dispatch routing, error codes)  
2. **Specialized features** (setup sequence, persistence, least-privilege users, machine contracts, non-goals)  
3. **Specialized project help items** (what `help` must list for domain)  
4. **Specialized project about items** (what `about` must expose for domain guidance)

**Mandatory peers (fail closed):**

| Peer | Requirement-ID | Owns |
|------|----------------|------|
| CLI interface | **RQ-SHELL-CLI-INTERFACE** | Dispatch, empty argv Type O, help routing |
| Shell CLI storage | **RQ-SHELL-CLI-STORAGE** | Cache folder + persistence folder resolve, isolation, about storage fields |
| Output | **RQ-SHELL-OUTPUT-REQUIREMENTS** | `out_*` channels (domain may use thin shims to `out_*`) |

**Scope:** Domain command surface, host setup semantics, persistence paths, human/JSON domain contracts, help/about domain rows.  
**Out of scope (peer requirements own):** Install / self-update / uninstall / empty-argv install-ensure; full `out_*` catalog; modular prefix system shape; companion-digest integrity; Type 1 host bootstrap as a separate product class.

**Must not confuse with:** Type 0 lifecycle commands (`install`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `help`); empty argv (Type O install-ensure, **not** full domain setup).

**Registry role:** This is the **one Active domain-requirements SSOT** for gitlab-nginx. Parallel Active domain-law files are forbidden.

**Naming law:** Domain SSOT basename is `requirement-domain-gitlab-nginx.md` (subject **gitlab-nginx**).

### 1.1 Human-facing

**In one sentence:** After the program is installed, you run `sudo gitlab-nginx run` on a Linux server so GitLab CE sits behind Nginx you control, with Let's Encrypt certificates.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Operator with DNS pointing at the server; full setup needs root | `sudo gitlab-nginx run` |
| The other role | Dedicated `nginx-adm` / `gitlab-adm` own Nginx/GitLab files after setup | `sudo gitlab-nginx remove-lpu all` |
| Not this file | Installing *this* CLI (`install`, empty argv, `self-update`) | `gitlab-nginx` with no arguments |

| Includes | Excludes |
|----------|----------|
| `run`, `domains`, `email`, `ssh-hostname`, `nginx-conf`, `remove-lpu` | Empty argv starting GitLab setup |
| Let's Encrypt files under `/etc/letsencrypt/` | Moving those files into `${HOME}/.local/gitlab-nginx` |

| Surface | What you open | What for |
|---------|---------------|----------|
| `sudo gitlab-nginx run` | command | 13-step host setup |
| `gitlab-nginx domains` | command | saved domain list |
| `/etc/letsencrypt/domains.conf` | file | persistence |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Set up GitLab | Interactive terminal + root. Non-interactive `run` only does packages/stop, then tells you to re-run on a TTY. | `sudo gitlab-nginx run` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Specialized CLI subcommands (normative catalog)

Domain verbs **MUST** be stable unless this requirement is explicitly revised. Dispatch **MUST** run through the single CLI entry (`app_main`). Domain handlers **MUST NOT** replace Type 0 `inst_*` lifecycle.

| Command | Privilege | Handler family | Operands / flags | Required behavior | Typical non-zero outcomes |
|---------|-----------|----------------|------------------|-------------------|---------------------------|
| `run` (alias `setup`) | root (**both** interactive and non-interactive: `check_root` first) | `run_interactive_setup` / `run_non_interactive_setup` | global `--json` / `--quiet` / `--debug` / `--no-cloudflare` | TTY: full interactive 13-step setup; non-TTY: package/stop-only path with guidance to `sudo ${APP_NAME} run`; **never** mutates host as non-root | not root → fail; partial cert/nginx failure → fail |
| `domains` | invoker (read) | `show_domains` / `load_existing_domains` | `--json` | Show saved domains from `DOMAINS_FILE` | missing file → status/warn, not crash |
| `email` | invoker (read) | `show_email` | `--json` | Show saved Let's Encrypt email from `EMAIL_FILE` | missing/unreadable → status/warn |
| `ssh-hostname` | root | `get_or_set_gitlab_ssh_hostname` | `--json` | Show or set GitLab SSH hostname (Cloudflare port-22 split) | not root → fail |
| `nginx-conf` | root | `deploy_domain_nginx_configs` (+ backups) | `--json` / `--no-cloudflare` | Regenerate external Nginx configs from saved domains | no domains → fail; nginx -t fail → fail |
| `remove-lpu` | root | `remove_least_privilege_operators` → `remove_*_adm_least_privilege` + `lpu_userdel_r` / `lpu_detect_home` | optional target `nginx` \| `gitlab` \| `all` (default `all`); global `--force` | Teardown dual LPU operators per F7: sudoers backup+remove; reverse **affected** ownership / restore `/etc/gitlab` from symlink **before** account delete; **`userdel -r`** (home **auto-detected** from passwd — **no** manual home-path rm). **Does not** uninstall Omnibus packages, wipe `/var/opt/gitlab`, or delete `${NGINX_CONF_ROOT}` site content. Aliases: `remove-nginx-adm`, `remove-gitlab-adm` | not root → fail; non-TTY without `--force` → fail; unknown target → fail |

**Dispatch rules:**

1. Domain commands **MUST** be recognized in the same global flag parse pass as Type 0 lifecycle commands.  
2. Empty argv **MUST NOT** run domain setup — empty argv is Type O install-ensure (**RQ-SHELL-CLI-ZERO-ARGUMENTS**). Full setup is **`run` / `setup`**.  
3. Flag `--no-cloudflare` **MUST** set `USE_CLOUDFLARE=0` for config generation paths.  
4. All user-facing domain messages **MUST** go through centralized `out_*` (directly or via documented shims `info`/`success`/`die`/`output_json` → `out_*`).  
5. Type 0 routes (`install`, `version`, `about`, `version-check`, `self-update`, `self-uninstall`, `help`) **MUST** remain available after domain specialization.  
6. **`remove-lpu` is not** Type 0 `self-uninstall` — self-uninstall removes only the CLI binary; remove-lpu reverses host LPU operators.

### 2.2 Specialized features (normative)

#### 2.2.1 Persistence

| Artifact | Path (default) | Meaning |
|----------|----------------|---------|
| Domains | `/etc/letsencrypt/domains.conf` | Space/line list; first = primary/main domain |
| Email | `/etc/letsencrypt/email.conf` | Let's Encrypt registration email |
| SSH hostname | product file under letsencrypt tree (e.g. `gitlab-ssh-hostname.conf`) | Separate GitLab SSH host when web is Cloudflare-proxied |

#### 2.2.2 Setup sequence (interactive `run`)

The interactive path **MUST** preserve the defensive order:

1. Ensure letsencrypt structure  
2. Install Certbot  
3. Install Nginx; stop nginx early  
4. Handle email + main domain + SANs (main domain chosen interactively, not “first of list”)  
5. Obtain certificates (standalone) **before** GitLab external_url finalize  
6. Install GitLab CE (Omnibus)  
7. Stop GitLab early; configure `gitlab.rb` with external nginx mode  
8. Dual least-privilege: **nginx-adm** (home `/etc/nginx-adm`, shell `/bin/bash`) + **gitlab-adm** (UID/GID 1888, home `/etc/gitlab-adm`, shell `/bin/bash`, real config `/etc/gitlab-adm/gitlab`, `/etc/gitlab` symlink; migrate legacy `/home/gitlab-adm` on setup)  
9. Deploy external Nginx GitLab proxy configs  
10. Client SSH config guidance for Cloudflare port 22  

Non-interactive `run` **MUST NOT** claim full setup success; it may install packages / stop services and require TTY for the rest.

#### 2.2.3 Architecture inheritance notes

| Layer | Required |
|-------|----------|
| Output | Domain uses `out_*` SSOT (shims allowed) |
| Lifecycle | Type 0 `inst_*` from bootstrap unchanged in contract |
| Dispatch | Single `app_main` |
| Identity | `APP_NAME=gitlab-nginx`, channel `Wilgat/gitlab-nginx` (or env override) |

#### 2.2.4 Non-goals

- Replacing Omnibus GitLab with source installs  
- Using GitLab bundled Nginx as the external-facing server in this product mode  
- Empty argv domain setup (forbidden under Type O inheritance)

### 2.3 Specialized project help items

`help` **MUST** list domain rows:

- `run` / setup  
- `domains`  
- `email`  
- `ssh-hostname`  
- `nginx-conf`  
- `remove-lpu` / `remove-nginx-adm` / `remove-gitlab-adm`  
- `--no-cloudflare`  

Plus full Type 0 self-management table.

### 2.4 Specialized project about items

`about` **MUST** expose domain diagnostics when available:

- domains file path + count  
- main domain (if known)  
- email file path + email (if known)  
- useful domain command reminders  

CLI lifecycle fields (version, install path, channel, cache folder, persistence folder) remain required by shell law.

---

## 3. Acceptance criteria (summary)

| ID | Criterion |
|----|-----------|
| AC-D1 | `gitlab-nginx version` / `help` / `about` work under Type 0 + domain |
| AC-D2 | Empty argv does **not** start full host setup (install-ensure only) |
| AC-D3 | `domains` / `email` read persistence without requiring full reinstall |
| AC-D4 | `run` is the documented path for full interactive setup |
| AC-D5 | Bootstrap **selfmanaged** ship unit is never overwritten by this product |

---

## 4. Notes

- Bootstrap origin A = **selfmanaged** 1.2.1 architecture.  
- Pre-specialize B body archived under `.bootstrap-archive/pre-specialize-*`.  
- Version at specialize apply: **2.3.0** (architecture re-base + domain graft).

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. Do not wrap `sudo`, do not wrap Linux `apt`/`dnf`, do not create `nginx-adm` / `gitlab-adm`, and do not recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** `run`, `nginx-conf`, `ssh-hostname`, and `remove-lpu` are unused on that class. Read-only `domains` / `email` may still run if those files exist and are readable.

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-GLN-01…08** | `tests/test_domain.sh` | have |
| **TP-GLN-11…13** | `tests/test_domain.sh` | have |
| **TP-GLN-09…10** | host-mutating | optional |

**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-06  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
