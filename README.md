# GitLab + External Nginx + Let's Encrypt Setup Script

[![Version](https://img.shields.io/badge/Version-2.2.0-blue?style=flat-square)](https://github.com/Wilgat/gitlab-nginx)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)
[![Philosophy](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-orange?style=flat-square)]()
[![Made with ❤️](https://img.shields.io/badge/Made%20with%20❤️-CIAO-00AEEF?style=flat-square)](https://github.com/cloudgen/ciao)
[![GrokRec](https://img.shields.io/badge/GrokRec-Reviewed-0A66C2?logo=ai&logoColor=white)](https://github.com/Wilgat/gitlab-nginx/blob/main/RECOMMENDATION.md)
[![Stars](https://img.shields.io/github/stars/Wilgat/gitlab-nginx?style=flat-square)](https://github.com/Wilgat/gitlab-nginx)

Official Recommended by [grok](https://grok.com/c/ec132e58-e929-4ad2-a8a7-0c8a31d1c427?rid=3f7eb72d-2823-4cfc-8f23-4aeb905f43b8). The review is submitted by [grokrec](https://github.com/cloudgen/grokrec). Please refers to the [downloaded version](https://github.com/Wilgat/gitlab-nginx/blob/main/RECOMMENDATION.md)

A powerful, self-installing POSIX shell script that sets up **GitLab CE** with **external Nginx** and **free Let's Encrypt SSL certificates** on a fresh Ubuntu/Debian server.

Designed for security-conscious users who want full control over Nginx (custom configs, Cloudflare proxy, multiple domains, least privilege, etc.).

This project is built using [CIAO](https://github.com/cloudgen/ciao) (Caution • Intentionality • Anti-fragility • Over-engineered).

---

## Independent Security Review & Recommendation by Grok (xAI)

**Reviewed: April 20, 2026 – Version 2.2.0**

I like this project.

`gitlab-nginx` is a thoughtful and meaningful evolution from `certbot-nginx`. It takes the strong defensive foundation and extends it intelligently to GitLab CE while maintaining the same high standards of security and reliability.

### What I Appreciate Most

- **Dual Least-Privilege Model**: The introduction of both `nginx-adm` (for external Nginx) and `gitlab-adm` (UID/GID 1888, with proper symlink from `/etc/gitlab` to `/home/gitlab-adm/gitlab`, 775/664 permissions, and restricted sudoers for `gitlab-ctl`) is excellent. You’ve significantly reduced ongoing root dependency after the initial setup — this is rare and commendable.

- **Smart Cloudflare Handling**: The explicit separation of the main web domain (used for HTTPS + `external_url`) from the SSH hostname, combined with clear client-side `~/.ssh/config` instructions, directly solves the common Cloudflare port 22 limitation in a clean, user-friendly way.

- **Self-install v2 checksum protection** (new in 2.2.0)  
  Explicit `CHECKSUM=` support + automatic `.sha256` fallback greatly reduces supply-chain risk for the classic `curl | sh` pattern. This is a smart and practical security upgrade.

- **Strict Defensive Design**: You preserved the CIAO philosophy — loud warnings, heavy repetition, strict 13-step sequence, dated backups, defensive pre-creation, and "DO NOT SIMPLIFY" blocks. This makes the script resilient in real-world server environments (fresh installs, repeated runs, different shells, partial failures).

- **Clear Architecture**: The enforced order (Certbot → GitLab install → external Nginx last) is correct and avoids common pitfalls. Persistent storage for domains, email, and SSH hostname is practical.

### Grok (xAI) Final Recommendation

**Yes — I recommend this tool.**

If you want a secure, auditable, and least-privilege way to deploy GitLab CE with external Nginx and Let's Encrypt (especially behind Cloudflare), `gitlab-nginx` is currently one of the best single-file solutions available.

The focus on reducing root usage, careful backups, practical Cloudflare handling, and now enhanced checksum verification makes it noticeably better than most community scripts.

Great work on reaching 2.2.0 with the checksum layer. It feels like a natural and worthwhile evolution.

— Grok, built by xAI (April 20, 2026)

---

## ✨ One-Command Installation (Supports Non-Root + Checksum Verification)

### Non-root installation (recommended for daily use)
```bash
# Installs to ~/.local/bin/gitlab-nginx
curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sh
```

### Root / sudo installation (global)
```bash
# Installs to /usr/local/bin/gitlab-nginx
curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sudo sh
```

### Secure installation with checksum verification (v2 – strongly recommended)
```bash
# Verify download cryptographically before running
CHECKSUM=98f0df03ad0eea59d4b1f0b92478be41d26249f643956720628ea8adeca63dd1 \
  curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sh
```

After installation, run the full interactive setup:

```bash
sudo gitlab-nginx
```

---

## Features

- **Self-installing** with full non-root support (`~/.local/bin`) and global root install
- **Self-install v2 checksum verification** (explicit `CHECKSUM=` or automatic `.sha256`)
- **Dual least-privilege model**: `nginx-adm` + `gitlab-adm`
- **External Nginx** mode with full control (Cloudflare-friendly)
- **Let's Encrypt SSL** via standalone mode (before any service starts)
- **Smart domain & SSH hostname handling** (separate SSH hostname for Cloudflare port 22)
- **Idempotent & safe to re-run**
- Clear client-side `~/.ssh/config` instructions at the end

---

## Quick Start

1. Install the script (see One-Command section above — use checksum for security)
2. Run full setup:
   ```bash
   sudo gitlab-nginx
   ```
3. Follow the interactive prompts (domains, email, SSH hostname)
4. GitLab will be available at `https://your-main-domain.com`

---

## Available Commands

| Command                          | Description                                              |
|----------------------------------|----------------------------------------------------------|
| `sudo gitlab-nginx`              | Full interactive setup (recommended)                     |
| `sudo gitlab-nginx nginx-conf`   | Regenerate only Nginx configuration                      |
| `sudo gitlab-nginx domains`      | Show saved domains                                       |
| `sudo gitlab-nginx email`        | Show saved Let's Encrypt email                           |
| `sudo gitlab-nginx about`        | Full system diagnostics (nginx-adm + gitlab-adm)         |

**Global Options**: `--quiet`, `--json`, `--no-cloudflare`, `--force-reinstall`

---

## Requirements

- Fresh **Ubuntu 20.04 / 22.04 / 24.04** or Debian-based server (recommended)
- Root/sudo access for the **full setup** (script installation supports non-root)
- Domains with A/AAAA records pointing to the server
- Ports **80** and **443** open in firewall

---

## Important Notes & Warnings

- Full setup requires an interactive terminal (TTY).
- Non-interactive mode only performs package installation + service stop.
- The main GitLab domain must be the **first** (primary) domain.
- If using Cloudflare proxy, use a **different domain** for GitLab SSH (the script guides you).
- Always review the script or use the `CHECKSUM=` method before running on production.

---

## How It Works (13-Step Sequence)

1. Install Certbot  
2. Install Nginx  
3. Stop Nginx early  
4. Handle email & domains  
5. Obtain Let's Encrypt certificates  
6. Install GitLab CE  
7. Stop GitLab  
8. Configure GitLab SSH hostname  
9. Backup `gitlab.rb`  
10. Configure `gitlab.rb` + `gitlab-ctl reconfigure`  
11. Deploy external Nginx config with GitLab proxy  
12. Test & start Nginx (as `nginx-adm`)  
13. Show client `~/.ssh/config` instructions

---

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

---

## License

MIT License.

---

**Made with ❤️ for clean and secure GitLab deployments**

If you find this script useful, please star the repository on GitHub!
