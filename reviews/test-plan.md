# Test plan — gitlab-nginx

Maps **portable TP families** (proof molds) and product domain cases to product-root `tests/`.

| Field | Value |
|-------|--------|
| **Product** | gitlab-nginx |
| **Ship unit** | `./gitlab-nginx` · `VERSION=2.5.1` |
| **Companion** | `./gitlab-nginx.sha256` |
| **Suite entry** | `./tests/run.sh` |
| **Live law** | **11** Active REQs — `docs/requirements/index.md` |
| **Bootstrap origin** | selfmanaged 1.2.1 (A→B specialize) |
| **Last update** | 2026-08-12 (2.5.1: dual LPU home `/etc/*-adm`, `remove-lpu` + `userdel -r`; docs version align) |

Status: **have** = automated · **todo** = needed · **n/a** = not applicable · **optional** = gated (root/host)

---

## Proof molds (cite by PM-ID)

| Family | Proof mold-ID | Suite file(s) | Primary product law |
|--------|---------------|---------------|---------------------|
| **TP-CLI** | `PM-SHELL-CLI-TEST-PLAN` | `tests/test_cli.sh` | RQ-SHELL-CLI-INTERFACE · RQ-SHELL-CLI-STORAGE · RQ-SHELL-OUTPUT-REQUIREMENTS |
| **TP-LC** | `PM-INSTALL-LIFECYCLE-TEST-PLAN` | `tests/test_install_lifecycle.sh` | RQ-SHELL-SELF-MANAGEMENT · RQ-SHELL-IDEMPOTENCY · RQ-SHELL-AUTOMATIC-CHECKSUM |
| **TP-CSUM** | `PM-CHECKSUM-TEST-PLAN` | CLI + lifecycle | RQ-SHELL-AUTOMATIC-CHECKSUM |
| **TP-GLN** | `PM-DOMAIN-TEST-PLAN` (domain subject) | `tests/test_domain.sh` | **RQ-DOMAIN-GITLAB-NGINX** (`remove-lpu` catalog; host teardown optional/root) |
| Umbrella | `PM-SHELL-CLI-SUITE-TEST-PLAN` | `tests/run.sh` | full Type 0 + domain surface |

**Storage split:** shell scratch / about fields → **RQ-SHELL-CLI-STORAGE** (TP-CLI). Domain host paths (`/etc/letsencrypt/*`) → **RQ-DOMAIN-GITLAB-NGINX** (TP-GLN about fields; host-mutating ops optional).

---

## Baseline result

| Date | Result | Notes |
|------|--------|-------|
| 2026-08-11 | PASS=108 FAIL=25 | Initial suite; host `/usr/local/bin/gitlab-nginx` shadowed installs; `run` non-root false success |
| 2026-08-11 | **PASS=133 FAIL=0 SKIP=0** | 2.3.1 + GLOBAL_BIN isolation + `check_root` on non-interactive run |

**How to re-baseline:** `cd` product root → `./tests/run.sh` → paste summary into this table when law/suite changes.

---

## TP-CLI — CLI surface

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-CLI-01 | Syntax + companion digest | **have** | `sh -n`; `gitlab-nginx.sha256` |
| TP-CLI-02 | Version human + JSON | **have** | app/version fields |
| TP-CLI-03 | Help Type 0; no CHECKSUM | **have** | test_cli |
| TP-CLI-04 | About JSON + storage fields | **have** | effective_storage / storage_dir |
| TP-CLI-05 | Storage isolation under HOME | **have** | GLOBAL_BIN + USER_BIN isolate |
| TP-CLI-06 | Unknown command fail-closed | **have** | exit 1 + out_error |
| TP-CLI-07 | quiet / env -u HOME | **have** | test_cli |
| TP-CLI-08 | Zero-arg failed install non-zero | **have** | bad SCRIPT_URL + isolate |
| TP-CLI-09 | self-uninstall --json confirm_required | **have** | test_cli |

---

## TP-LC — Install lifecycle (local HTTP channel)

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-LC-01 | install --json to USER_BIN | **have** | local channel |
| TP-LC-02 | Idempotent re-install | **have** | already installed |
| TP-LC-03 | Zero-arg Type O when installed | **have** | local + global path cases |
| TP-LC-04 | version-check schema | **have** | ver_check keys |
| TP-LC-05 | self-update already-latest | **have** | lifecycle |
| TP-LC-06 | Human companion transparency | **have** | PASS digest lines |
| TP-LC-07 | Uninstall refuse / force | **have** | lifecycle |
| TP-LC-08 | CHECKSUM pin match/mismatch | **have** | lifecycle |
| TP-LC-09 | Downgrade blocked / --force | **have** | lifecycle |

---

## TP-GLN — Domain surface (`RQ-DOMAIN-GITLAB-NGINX`)

| TP-ID | Intent | Status | Evidence |
|-------|--------|--------|----------|
| TP-GLN-01 | Help lists domain verbs + Type 0 | **have** | run/domains/email/nginx-conf/ssh-hostname/--no-cloudflare |
| TP-GLN-02 | Help --json notes domain | **have** | test_domain |
| TP-GLN-03 | About domain fields | **have** | domains_file / email_file / domain_count |
| TP-GLN-04 | Empty argv ≠ domain setup | **have** | Type O only; no certbot/GitLab text |
| TP-GLN-05 | `domains` routed | **have** | not unknown |
| TP-GLN-06 | `domains --json` type | **have** | JSON or honest permission |
| TP-GLN-07 | `nginx-conf` non-root fail-closed | **have** | exit 1 + root message |
| TP-GLN-08 | `run` non-root fail-closed | **have** | `check_root` (2.3.1) |
| TP-GLN-09 | Full interactive host setup | **optional** | requires root + TTY + host packages |
| TP-GLN-10 | `nginx-conf` regenerate on live host | **optional** | root + saved domains |

---

## Rules

1. Closing a bug updates the matching TP to **have** only with a suite assertion (or documented static fix).  
2. Host-mutating domain paths stay **optional** unless a safe CI harness is added.  
3. Do not reverse-copy bootstrap selfmanaged suite without retargeting `APP_NAME` / channel / GLOBAL_BIN isolation.  
