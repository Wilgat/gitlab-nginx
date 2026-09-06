# gitlab-nginx - GitLab CE with external Nginx and Let's Encrypt

![Version](https://img.shields.io/badge/Version-2.5.3-blue?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)
[![CIAO](https://img.shields.io/badge/Philosophy-CIAO%20(Caution%20%E2%80%A2%20Intentional%20%E2%80%A2%20Anti--fragile%20%E2%80%A2%20Over--engineered)-purple.svg)](https://github.com/cloudgen/ciao)
[![Stars](https://img.shields.io/github/stars/Wilgat/gitlab-nginx?style=flat-square)](https://github.com/Wilgat/gitlab-nginx)
[![Shell](https://img.shields.io/badge/Shell-POSIX%20sh-orange?style=flat-square)]()

You put one program file (`gitlab-nginx`) on a Linux server, then run `sudo gitlab-nginx run` so **GitLab Community Edition** sits behind **Nginx you control**, with free **Let's Encrypt** certificates.

| Who | Meaning | Example |
|-----|---------|---------|
| **You** | A person with a domain pointing at the server. You can install this program as yourself. Full GitLab setup needs a root login. | `curl … \| sh` then `sudo gitlab-nginx run` |
| **The other role** | After setup, dedicated accounts `nginx-adm` and `gitlab-adm` own day-to-day Nginx/GitLab files — not your daily login. | `remove-lpu` tears those accounts down |
| **Not this** | GitLab’s bundled Nginx, a package-manager-only GitLab install, or a numbered main menu. Empty `gitlab-nginx` means **install this program**, not “set up GitLab”. | `gitlab-nginx` with no arguments |

| Includes | Excludes |
|----------|----------|
| External Nginx, Certbot standalone certificates, Cloudflare-aware SSH hostname | Using GitLab’s bundled Nginx as the public server |
| Install for yourself (`~/.local/bin`) or for everyone (`/usr/local/bin`) | Treating empty argv as help or as full GitLab setup |
| Automatic SHA-256 companion check on download | Requiring a `CHECKSUM=` pin for every install |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Install the program | Downloads `gitlab-nginx` and places it on your PATH. Does **not** install GitLab yet. | `curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx \| sh` |
| Set up GitLab | Interactive 13-step host setup (packages, certificates, GitLab, external Nginx). Needs a terminal and root. | `sudo gitlab-nginx run` |
| Inspect later | Show saved domains, email, or diagnostics without re-running setup. | `gitlab-nginx about` · `gitlab-nginx domains` |

This project follows [CIAO](https://github.com/cloudgen/ciao) (Caution • Intentional • Anti-fragile • Over-engineered).

## Features

- **Self-installing program file** — user-local (`~/.local/bin`) or global (`/usr/local/bin`)
- **Automatic SHA-256 companion check** — the program fetches `gitlab-nginx.sha256` itself (no env pin required)
- **Dedicated operator accounts** after setup: `nginx-adm` (external Nginx) and `gitlab-adm` (GitLab config under `/etc/gitlab-adm`)
- **`remove-lpu`** — remove those dedicated accounts (`userdel -r`); this is not “uninstall the CLI”
- **External Nginx** you control (Cloudflare-friendly real-IP map unless `--no-cloudflare`)
- **Let's Encrypt** via standalone mode before GitLab is brought up
- **Separate GitLab SSH hostname** when the web domain is Cloudflare-proxied (port 22)
- **Safe to re-run** install and ensure-style steps
- **Idempotent CLI lifecycle** — `version-check`, `self-update`, `self-uninstall`

## Quick Installation

Install the program (does not install GitLab):

```bash
# For yourself → ~/.local/bin/gitlab-nginx
curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sh
```

```bash
# For everyone → /usr/local/bin/gitlab-nginx
sudo curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sudo sh
```

The channel URL is the product default (`SCRIPT_URL`). Override that env only if you fork the channel.

### Integrity (automatic SHA-256)

When you do **not** set `CHECKSUM`, the program downloads the companion digest itself from `${SCRIPT_URL}.sha256` (in-repo file: `gitlab-nginx.sha256`). Human mode is designed to show the **link** (companion URL), the **value** (expected digest), and the **result**.

| Outcome | What happens |
|---------|----------------|
| Companion found and digest **matches** | Install continues |
| Companion found and digest **mismatches** | Install **aborts** |
| Companion **missing** | **Warning**, then install continues (best-effort) |

Algorithm: **SHA-256** (`sha256sum`). Same-channel companion files prove the two files on that channel match. They are not a substitute for signed releases.

### After install — set up GitLab

Needs an interactive terminal and root:

```bash
sudo gitlab-nginx run
```

Empty `gitlab-nginx` (no arguments) only **installs or re-checks this program**. It does not start GitLab setup.

### Advanced: optional digest pin (CI)

Optional process env — **not** listed in `help` / `about`, **not** the primary newcomer path. Paste the current `gitlab-nginx.sha256` hex (do not copy a stale hash from old docs):

```bash
CHECKSUM=<64-hex-from-gitlab-nginx.sha256> \
  curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sh
```

Regenerate the in-repo companion after editing `./gitlab-nginx`: `sha256sum gitlab-nginx | cut -d' ' -f1 > gitlab-nginx.sha256`. Do not paste a same-origin `CHECKSUM=$(curl …sha256)` as “higher assurance” than automatic mode.

## Usage

```text
gitlab-nginx [command] [options]
```

| Command | Who may run it | What it does |
|---------|----------------|--------------|
| *(no arguments)* | You | Install or re-check this program |
| `install` | You (root → global path) | Place the CLI binary |
| `version` | You | Print version |
| `about` | You | Diagnostics (install + cache/persistence folders + domain files) |
| `help` | You | Full usage |
| `version-check` | You | Compare local vs channel version |
| `self-update` | You | Update this program from the channel |
| `self-uninstall` | You | Remove this program (not GitLab, not `nginx-adm`) |
| `run` (alias `setup`) | Root | Full interactive GitLab + Nginx setup |
| `domains` | You (read) | Show saved domains |
| `email` | You (read) | Show saved Let's Encrypt email |
| `ssh-hostname` | Root | Show or set GitLab SSH hostname |
| `nginx-conf` | Root | Regenerate external Nginx config |
| `remove-lpu` | Root | Remove dedicated `nginx-adm` / `gitlab-adm` accounts (`nginx` \| `gitlab` \| `all`) |

**Global options:** `--quiet` / `-q`, `--json`, `--force`, `--debug`, `--no-cloudflare`

**Environment (listed in help):** `REPO_USER`, `REPO_NAME`, `SCRIPT_URL`. `CHECKSUM` is an install-path pin only — not a help/about field.

There is **no numbered main menu**. Choose a command name (or a number is not offered).

## Examples

```bash
gitlab-nginx version
gitlab-nginx about
gitlab-nginx --json about
sudo gitlab-nginx run
gitlab-nginx domains
sudo gitlab-nginx nginx-conf
sudo gitlab-nginx remove-lpu all --force
gitlab-nginx help
```

Client SSH when the web domain is Cloudflare-proxied: the program prints a `~/.ssh/config` snippet at the end of interactive `run` (use the **SSH hostname**, not the proxied web domain, for `git@…`).

## Platform Compatibility

| Surface | Status |
|---------|--------|
| Ubuntu 20.04 / 22.04 / 24.04 (fresh server) | Supported for full GitLab setup |
| Other Debian-based Linux with `/bin/sh`, `curl` or `wget`, `sha256sum` | CLI install and self-update |
| Ports 80 and 443 reachable; DNS A/AAAA for your domains | Required for certificates + GitLab |
| Termux / Git Bash / Windows Command Prompt | CLI self-install as yourself only — no GitLab host setup, no dedicated system users, no `sudo curl \| sh` |
| macOS / non-Linux as a GitLab host | Not claimed |

Full setup needs a TTY. Non-interactive `run` only does package install + service stop and then tells you to run `sudo gitlab-nginx run` on a terminal.

## Related Projects

- [CIAO](https://github.com/cloudgen/ciao) — defensive programming philosophy this CLI follows
- [selfmanaged](https://github.com/cloudgen/selfmanaged) — Type 0 bootstrap this product specialized from (install / version-check / self-update / self-uninstall)
- Independent review notes: [RECOMMENDATION.md](RECOMMENDATION.md)

## Contributing

Contributions are welcome. Open an issue or a pull request. Keep install, checksum, and privilege behavior honest in `README.md` and `CHANGELOG.md` when you change them.

## License

MIT License. See [LICENSE.md](LICENSE.md).

## Last Update

2026-09-06 — **2.5.3**: `help` is a single live catalog (`app_help`); `setup` alias listed; stale Java/timer help removed.
