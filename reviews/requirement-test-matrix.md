# Requirement ↔ test matrix — gitlab-nginx

Maps live `RQ-*` to **TP** families. Status SSOT for individual TP-IDs: `reviews/test-plan.md`.

| Requirement-ID | Key | TP families | Suite | Notes |
|----------------|-----|-------------|-------|-------|
| `RQ-CLASS-SOFTWARE-DEV` | requirement-class-software-dev | TP-CLI-01 | `tests/test_cli.sh` | Class residual; syntax/companion |
| `RQ-SHELL-CLI-INTERFACE` | requirement-shell-cli-interface | TP-CLI · TP-GLN-01 | `tests/test_cli.sh` · `tests/test_domain.sh` | Dual mention of domain verbs |
| `RQ-SHELL-CLI-STORAGE` | requirement-shell-cli-storage | TP-CLI-04,05 | `tests/test_cli.sh` | Cache + persistence folders |
| `RQ-SHELL-CLI-ZERO-ARGUMENTS` | requirement-shell-cli-zero-arguments | TP-CLI-08 · TP-LC-03 · TP-GLN-04 | CLI + lifecycle + domain | Empty argv ≠ GitLab setup |
| `RQ-SHELL-OUTPUT-REQUIREMENTS` | requirement-shell-output-requirements | TP-CLI-02,04,07 | `tests/test_cli.sh` | quiet / json |
| `RQ-SHELL-SELF-MANAGEMENT` | requirement-shell-self-management | TP-LC-04…09 · TP-CLI-09 | lifecycle + CLI | |
| `RQ-SHELL-AUTOMATIC-CHECKSUM` | requirement-shell-automatic-checksum | TP-LC-06,08 · TP-CLI-03 | lifecycle + CLI | help/about omit CHECKSUM |
| `RQ-SHELL-IDEMPOTENCY` | requirement-shell-idempotency | TP-LC-01,02 | `tests/test_install_lifecycle.sh` | |
| `RQ-SHELL-INTERACTIVE-VS-NONINTERACTIVE` | requirement-shell-interactive-vs-noninteractive | TP-CLI-07,09 · TP-GLN-08 | CLI + domain | TTY measured outside functions |
| `RQ-SHELL-MODULAR-FUNCTION-DESIGN` | requirement-shell-modular-function-design | TP-CLI-01 | `tests/test_cli.sh` | `sh -n` |
| `RQ-SHELL-SCRIPT-CODING` | requirement-shell-script-coding | TP-CLI-01 | `tests/test_cli.sh` | POSIX ship unit |
| `RQ-SHELL-SUDO-COMMAND` | requirement-shell-sudo-command | TP-GLN-07,08,12,13 | `tests/test_domain.sh` | Non-root fail-closed |
| `RQ-DOMAIN-GITLAB-NGINX` | requirement-domain-gitlab-nginx | TP-GLN-01…13 | `tests/test_domain.sh` | 09–10 optional (host) |

**Last update:** 2026-09-06 (2.5.2)
