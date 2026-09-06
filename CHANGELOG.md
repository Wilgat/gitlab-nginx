# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.5.2] - 2026-09-06

### Added
- **Human-facing law:** every Active `requirement-*.md` now has **§1.1 Human-facing** (who / other role / not this; includes/excludes; practice command).
- **`requirement-shell-script-coding`** — POSIX `/bin/sh` coding specialize-in home (without it, portable lessons arrive raw).
- **`requirement-shell-sudo-command`** — studied in-tool sudo allow table (`systemctl stop nginx`; `sudo -u nginx-adm nginx -t`).
- Product **`reviews/requirement-test-matrix.md`** (requirement → TP families).
- Tests **TP-GLN-11…13**: `email` routed; `ssh-hostname` / `remove-lpu` non-root fail-closed. Help lists `remove-lpu`.

### Changed
- **Product README** rewritten for people: install vs GitLab setup, automatic SHA-256 as primary integrity, no Type-N lead, mandatory section order.
- **Storage law:** `requirement-shell-cli-storage` owns **cache folder** *and* **persistence folder** (`${HOME}/.local/gitlab-nginx`). `about` human labels **Cache folder (preferred)/(fallback)** and **Persistence folder**; JSON adds `cache_preferred`, `cache_fallback`, `persistence_storage`. Persistence is not `${HOME}/.local/bin` and not domain `/etc/letsencrypt/*`.
- CLI `help` copy: self-management as any login; `remove-lpu` described as dedicated `nginx-adm` / `gitlab-adm` accounts (not “LPU” as the only words).
- Dual mention: domain verbs named on **both** `requirement-shell-cli-interface` and `requirement-domain-gitlab-nginx`.
- Related shell REQs include **Under command line for normal user only** (Termux / Git Bash / Windows cmd: no host setup, no dedicated accounts, no `sudo curl | sh`).

## [2.5.1] - 2026-08-12

### Changed
- **LPU glossary dual structure (portable + product):** teach least-privilege system users as portable patterns with nested product specialization (not pure product silos).
  - `least-privilege-model` promoted to **portable** multi-surface architecture + dual (`nginx-adm` / `gitlab-adm`) product specialization.
  - `user-nginx-adm` / `user-gitlab-adm` / `sudoers-nginx-adm` / `sudoers-gitlab-adm`: portable pattern sections + product F1–F7 / Cmnd SSOT.
  - Parents (`least-privilege-user`, `system-user`, `least-privilege-user-sudoers`, `system-user-home`, `least-privilege`) and index aligned; `terminology-portability` dual-structure rule.
  - Skill **`SK-CREATE-LEAST-PRIVILEGE-USER-TERMINOLOGY`** v1.3.0: §3.3 dual structure mandatory.
  - **H1** dual-structure LPU knowledge synced to `genesis-template` (2026-08-12).
- **`remove-lpu` F7 path:** home is **auto-detected** from passwd (`lpu_detect_home`); account+home removed with **`userdel -r`** (`lpu_userdel_r`) — **no** manual home-path `rm` in the remove path.
  - Order: sudoers backup+remove → reverse **affected** ownership / restore `/etc/gitlab` from symlink (before account delete) → `userdel -r`.
  - Glossary F7, domain REQ, molds, and LPU terminology skill aligned.
- **Housekeeping (2.5.1 product surfaces):** README version badge + install `CHECKSUM=` pin + commands/`remove-lpu`; SECURITY supported versions; reviews test-plan ship version; domain registry row title.

## [2.5.0] - 2026-08-12

### Changed
- **`gitlab-adm` system-user home → `/etc/gitlab-adm`** (**preferred-/etc**, aligned with LPU default and `nginx-adm`).
  - Real config (affected): `/etc/gitlab-adm/gitlab`; public path `/etc/gitlab` → symlink.
  - Setup migrates legacy `/home/gitlab-adm/gitlab` and rewrites home via `usermod -d` when the account already exists.
  - `remove-lpu gitlab` restores config from new or legacy symlink targets before account removal.

## [2.4.0] - 2026-08-11

### Added
- **`remove-lpu [nginx|gitlab|all]`** domain command (root; `--force` for non-interactive): implements terminology F7 teardown for dual least-privilege operators.
  - Aliases: `remove-nginx-adm`, `remove-gitlab-adm`.
  - Handlers: `remove_nginx_adm_least_privilege`, `remove_gitlab_adm_least_privilege`, orchestrator `remove_least_privilege_operators`.
  - nginx-adm: backup/remove sudoers, drop home site symlinks, reverse `${NGINX_CONF_ROOT}` ownership to `root:root`, `userdel`/`groupdel`, remove `/etc/nginx-adm`.
  - gitlab-adm: backup/remove sudoers, restore `/etc/gitlab` from symlink (preserve config), `root:root` ownership, account/group/home cleanup.
  - Does **not** uninstall Omnibus packages, wipe `/var/opt/gitlab`, or delete Nginx site file contents.
- Domain requirement + help/about notes for `remove-lpu`; glossary F7 on `user-nginx-adm` / `user-gitlab-adm` marked implemented.

## [2.3.1] - 2026-08-11

### Fixed
- **`run` non-interactive requires root** (`check_root` at start of `run_non_interactive_setup`) — prevents partial host mutations and false success as non-root.
- Non-interactive completion message points to `sudo gitlab-nginx run` (not bare command).
- CI tests isolate `GLOBAL_BIN` so host `/usr/local/bin/gitlab-nginx` cannot shadow local install lifecycle tests.

## [2.3.0] - 2026-08-11

### Changed
- **Bootstrap re-specialize from selfmanaged 1.2.1** (A→B only):
  - Type 0 architecture inheritance: central `out_*` output SSOT, `inst_*` lifecycle, single `app_main` dispatcher, Type O empty-argv install-ensure.
  - Channel identity retained: `Wilgat/gitlab-nginx`, companion `gitlab-nginx.sha256`.
  - Domain DNA (GitLab CE + external Nginx + Certbot, nginx-adm / gitlab-adm, 13-step setup) grafted with `out_*` compatibility shims.
- **CLI contract**: full host setup is now `sudo gitlab-nginx run` (alias `setup`). Empty argv is **install-ensure only** (no longer starts interactive domain setup).
- Product law registered under `docs/requirements/` (class + shell + **`requirement-domain-gitlab-nginx`**).

### Fixed
- Missing `deploy_gitlab_nginx_config` compatibility wrapper → `deploy_domain_nginx_configs`.

## [2.2.0] - 2026-04-20

### Added
- **Self-install security upgrade (v2)**:
  - New function `perform_self_install_v2()` with layered checksum verification.
  - If `CHECKSUM=<sha256>` environment variable is set, the downloaded script is strictly verified against it before installation.
  - If no `CHECKSUM` is provided, the script automatically attempts to fetch and verify `${SCRIPT_URL}.sha256` (when available).
  - On checksum mismatch → immediate `die()` with clear security error (prevents tampered downloads).
  - Full defensive comment block documenting the v2 procedure, rationale, and upgrade from previous version.
- Support for `--no-cloudflare` flag to disable Cloudflare IP restriction during setup.

### Changed
- `perform_self_install()` renamed to `perform_self_install_v2()` (old name preserved in comments for clarity).
- `self_update()` and `maybe_install()` now call the new v2 function.
- Improved domain handling logic in interactive mode (main domain is now explicitly chosen by the user and always placed first).

### Fixed
- **Critical fix for certificate expansion**: When adding new domains to an existing Let's Encrypt certificate, Certbot no longer fails with the "expand" confirmation prompt in non-interactive mode.
  - Added `--expand` + `--cert-name` to the primary `certbot certonly` call.
  - Added safe fallback for first-time certificate issuance.
  - Added detailed "LESSON LEARNED" comment block in `apply_letsencrypt_standalone()`.

## [2.1.0] - 2026-04-19

### Added
- Support for `--no-cloudflare` flag to disable Cloudflare IP restriction during setup.
- **gitlab-adm least-privilege model** (parallel to nginx-adm):
  - Dedicated `gitlab-adm` user (fixed UID/GID 1888, home `/home/gitlab-adm`)
  - Real GitLab configuration moved to `/home/gitlab-adm/gitlab`
  - Symlink `/etc/gitlab` → `/home/gitlab-adm/gitlab`
  - Ownership: `gitlab-adm:root` with 775 directories and 664 files
  - `gitlab-adm` added to all relevant `gitlab-*` groups
  - Restricted sudoers allowing `gitlab-ctl` commands without password
- Persistent storage for GitLab SSH hostname (`/etc/letsencrypt/gitlab-ssh-hostname.conf`)
- `get_or_set_gitlab_ssh_hostname()` with clear Cloudflare port 22 warning
- `deploy_gitlab_nginx_config()` – dedicated GitLab-specific Nginx server block (reuses Cloudflare map)
- New functions: `create_gitlab_adm_user()`, `setup_gitlab_adm_ownership_and_symlinks()`, `setup_gitlab_restricted_sudoers()`, `backup_gitlab_rb()`, `stop_gitlab_early()`, `configure_gitlab_rb()`, `show_ssh_config_instructions()`
- `ensure_gitlab_structure()` for defensive pre-creation of GitLab directories
- `write_file_atomic()` for safe editing of `gitlab.rb`

### Changed
- Improved domain handling logic in interactive mode (main domain is now explicitly chosen by the user and always placed first).
- Updated project to version 2.1.0 with full GitLab CE + external nginx integration
- Strengthened header with detailed 13-step sequence and gitlab-adm section
- `run_interactive_setup()` now strictly follows the documented 13-step sequence
- Improved `show_system_diagnostics()` to display both nginx-adm and gitlab-adm status
- Better separation of concerns: Certbot → GitLab → external Nginx

### Fixed
- Critical fix for certificate expansion when adding new domains to an existing certificate.
- Corrected backup logic for both nginx and gitlab.rb (dated backups with incrementing counter)
- Fixed ownership and symlink handling for gitlab-adm model
- Improved idempotency in user creation and setup functions
- Better error handling and defensive checks throughout

## [2.0.0] - 2026-04 (Initial GitLab Port)

### Added
- Full integration of GitLab CE (Omnibus) with external nginx mode
- Separation of web domain and SSH hostname to solve Cloudflare port 22 limitations
- Clear client-side `~/.ssh/config` instructions at the end of setup

### Changed
- Major evolution from certbot-nginx to gitlab-nginx
- Extended least-privilege model with gitlab-adm user

---

**Previous versions** (before 2.0.0) were based on certbot-nginx and not tracked under this changelog.