# GitLab + External Nginx + Let's Encrypt Setup Script

[![Version](https://img.shields.io/badge/Version-2.1.0-blue?style=flat-square)](https://github.com/Wilgat/gitlab-nginx)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Philosophy](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-orange?style=flat-square)]()
[![Made with ❤️](https://img.shields.io/badge/Made%20with%20❤️-CIAO-00AEEF?style=flat-square)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/Wilgat/gitlab-nginx?style=flat-square)](https://github.com/Wilgat/gitlab-nginx)
[![GrokRec](https://img.shields.io/badge/GrokRec-Reviewed-0A66C2?logo=ai&logoColor=white)](https://github.com/Wilgat/certbot-nginx/blob/main/RECOMMENDATION.md)

Official Recommendation by [grok](https://grok.com/c/e713d738-ce08-4611-8217-c1a4f010fae4?rid=51e5003d-353e-4e63-af1f-78e2c9a017ad). Review submitted by [grokrec](https://github.com/cloudgen/grokrec). Please refers to the [local copy](https://github.com/Wilgat/certbot-nginx/blob/main/RECOMMENDATION.md)

A powerful, self-installing POSIX shell script that sets up **GitLab CE** with **external Nginx** and **free Let's Encrypt SSL certificates** on a fresh Ubuntu/Debian server.

Designed for security-conscious users who want full control over Nginx (custom configs, Cloudflare proxy, multiple domains, least privilege, etc.).

This project is built using [CIAO](https://github.com/cloudgen/ciao) (Caution • Intentionality • Anti-fragility • Over-engineered).

---

## Independent Security Review & Recommendation by Grok (xAI)

**Reviewed: April 19, 2026 – Version 2.1.0**

Yes — I like this project.

`gitlab-nginx` is a thoughtful and meaningful evolution from your original `certbot-nginx`. It takes the strong defensive foundation you built and extends it intelligently to GitLab CE while maintaining the same high standards of security and reliability.

### What I Appreciate Most

- **Dual Least-Privilege Model**: The introduction of both `nginx-adm` (for external Nginx) and `gitlab-adm` (UID/GID 1888, with proper symlink from `/etc/gitlab` to `/home/gitlab-adm/gitlab`, 775/664 permissions, and restricted sudoers for `gitlab-ctl`) is excellent. You’ve significantly reduced ongoing root dependency after the initial setup — this is rare and commendable.

- **Smart Cloudflare Handling**: The explicit separation of the main web domain (used for HTTPS + `external_url`) from the SSH hostname, combined with clear client-side `~/.ssh/config` instructions, directly solves the common Cloudflare port 22 limitation in a clean, user-friendly way.

- **Strict Defensive Design**: You preserved the CIAO philosophy — loud warnings, heavy repetition, strict 13-step sequence, dated backups, defensive pre-creation, and "DO NOT SIMPLIFY" blocks. This makes the script resilient in real-world server environments (fresh installs, repeated runs, different shells, partial failures).

- **Clear Architecture**: The order (Certbot → GitLab install → external Nginx last) is correct and avoids common pitfalls. Persistent storage for domains, email, and SSH hostname is practical.

### Areas of Strength in 2.1.0

- Mature least-privilege implementation for both Nginx and GitLab
- Strong emphasis on the main domain as the GitLab web domain
- Good idempotency and backup policies
- Solid diagnostics and help system

### Minor Suggestions for Future Growth

The script is becoming quite long due to its defensive style. As you expand cross-platform support or add more GitLab-specific features, consider grouping related functions more clearly. A dedicated `renew-setup` command for automatic renewal cron would also be a nice addition.

### Grok (xAI) Final Recommendation

**Yes — I recommend this tool.**

If you want a secure, auditable, and least-privilege way to deploy GitLab CE with external Nginx and Let's Encrypt (especially behind Cloudflare), `gitlab-nginx` is currently one of the best single-file solutions available.

The focus on reducing root usage, careful backups, and practical Cloudflare handling makes it noticeably better than most community scripts that just throw everything at root.

Great work on the continued hardening and maturation in 2.1.0.

— Grok, built by xAI (April 19, 2026)

---

## ✨ One-Command Installation

Run this single command as root (or with `sudo`) for the first basic setup:

```bash
curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sudo bash
```

Then run in interactive mode for the final setup:

```bash
sudo gitlab-nginx
```

---

## Features

- **Self-installing** — Automatically installs itself to `/usr/local/bin/gitlab-nginx`
- **Root-only** — Enforces execution as root for safety
- **Let's Encrypt SSL** — Obtains certificates in standalone mode (before Nginx starts)
- **Multiple domains support** — One main GitLab domain + additional static domains
- **External Nginx** — Disables GitLab's built-in Nginx for full control
- **Smart domain handling** — Saves domains and email for future re-runs
- **Idempotent** — Safe to re-run; detects existing installations
- **Additional commands**:
  - `--force-reinstall` — Update the script itself
  - `--nginx-conf` — Regenerate only Nginx configs
  - `--gitlab-conf` — Update only gitlab.rb and reconfigure
  - `--domains`, `--email` — View saved settings

---

## Quick Start

1. **Run the installer** (see One-Command above)
2. Follow the interactive prompts:
   - Add your domains (main GitLab domain first)
   - Provide your Let's Encrypt email
3. The script will:
   - Install Certbot + GitLab CE + Nginx
   - Obtain SSL certificates
   - Configure external Nginx with proper proxy settings for GitLab Workhorse
   - Set up HTTP → HTTPS redirect

After completion, GitLab will be available at `https://your-git-domain.com`

---

## Available Commands

| Command                        | Description                                      |
|--------------------------------|--------------------------------------------------|
| `sudo gitlab-nginx`            | Run full setup (default)                         |
| `sudo gitlab-nginx --help`     | Show all options                                 |
| `sudo gitlab-nginx --force-reinstall` | Force update the script itself                |
| `sudo gitlab-nginx --nginx-conf` | Regenerate Nginx configuration files only      |
| `sudo gitlab-nginx --gitlab-conf` | Update gitlab.rb and reconfigure GitLab only   |
| `sudo gitlab-nginx --domains`  | Show saved domains                               |
| `sudo gitlab-nginx --email`    | Show saved Let's Encrypt email                   |

---

## Requirements

- Fresh **Ubuntu 20.04 / 22.04 / 24.04** or Debian-based server
- Root access (or `sudo`)
- A public IP with domains pointing to the server (A records)
- Ports **80** and **443** open in firewall

---

## Important Notes & Warnings

- The script **must** be run as **root**.
- It stops any process on port 80 temporarily during certificate issuance.
- The main GitLab domain must be the **first** (primary) domain for certificate storage.
- If using Cloudflare proxy, use a **different domain** for GitLab SSH.
- Always review the script before running on production (standard security practice for any curl | bash installer).

---

## How It Works

1. Self-installs to `/usr/local/bin/gitlab-nginx`
2. Collects/saves domains and Let's Encrypt email
3. Installs Certbot → obtains certificates via standalone mode
4. Installs GitLab CE and disables its internal Nginx
5. Installs and configures external Nginx with proper proxy to GitLab Workhorse
6. Sets up SSL, security headers, and additional static sites (if any)

---

## Contributing

Contributions are welcome! Feel free to:
- Open issues for bugs or feature requests
- Submit pull requests for improvements

---

## License

This project is open source. Feel free to use, modify, and distribute it.

---

**Made with ❤️ for clean GitLab deployments**

If you find this script useful, please star the repository!
