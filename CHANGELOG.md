# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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