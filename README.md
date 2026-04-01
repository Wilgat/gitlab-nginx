
# GitLab + External Nginx + Let's Encrypt Setup Script

A powerful, self-installing Bash script that sets up **GitLab CE** with **external Nginx** and **free Let's Encrypt SSL certificates** on a fresh Ubuntu/Debian server.

Perfect for production deployments where you want full control over Nginx (e.g. multiple domains, custom configs, Cloudflare proxy, etc.).

---

## ✨ One-Command Installation

Run this single command as root (or with `sudo`) for the first basic setup:

```bash
curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sudo bash
```

Then you need to run in interactive mode for the final setup, you can simply run:

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
