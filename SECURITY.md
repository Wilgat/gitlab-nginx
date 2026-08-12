# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| **2.5.1** (current) | Yes — full support |
| **2.5.0** / **2.4.x** | Superseded; upgrade to current when possible |
| **2.3.x** | Security fixes only; upgrade recommended |
| **2.2.x** and older | Best-effort only; upgrade recommended |

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports when a private channel is available.

**Maintainer contact (email):** `wilgat.wong@gmail.com`

- Source of contact: product **author-email** SSOT in [`LICENSE.md`](./LICENSE.md) (Copyright line).
- Prefer email for vulnerability details, reproduction steps, and impact.
- You should receive an acknowledgment when the report is received and actionable.
- Do not include exploit weaponization guides in public channels.

For non-sensitive questions or general bugs, use normal project channels (for example public issues on the project repository when available).

## Security Design Principles (CIAO)

This project follows **[CIAO](https://github.com/cloudgen/ciao)** / **CIAO-Lite** defensive design. Security-relevant intent:

| Letter | Principle | Security application |
|--------|-----------|----------------------|
| **C** | **Caution** | Assume hostile input, hostile networks, and misconfiguration. Validate install paths and privilege boundaries; fail closed on integrity **mismatch** when a companion digest is present. Domain host setup requires root deliberately. |
| **I** | **Intentional** | Type 0 self-management, channel URL (`SCRIPT_URL`), automatic companion-checksum, and domain verbs (`run`, `nginx-conf`, `remove-lpu`, …) are deliberate. Prefer clear “why” over silent magic. |
| **A** | **Anti-fragile** | Survive harsh environments (minimal containers, non-interactive `curl \| sh`). Prefer transparent automatic SHA-256 sidecar checks, least privilege for day-to-day CLI use, and recoverable failure over brittle trust. |
| **O** | **Over-protect** | Defense in depth on critical paths (integrity verify before install/update when designed, dual least-privilege `nginx-adm` / `gitlab-adm` models, loud failure). Do not “simplify away” safety for brevity. |

Full principles: [CIAO Defensive Programming](https://github.com/cloudgen/ciao) · agent contract: [CIAO-Lite](https://github.com/cloudgen/ciao-lite).

This section describes **design posture**. It is **not** a claim of third-party certification (ISO, OWASP “compliant”, etc.).

## Install integrity and trust

`gitlab-nginx` implements the **automatic checksum mechanism**: when `CHECKSUM` is unset, install/self-update attempts to fetch a companion digest next to the install artifact (`${SCRIPT_URL}.sha256`).

| Mode | Behavior (summary) |
|------|--------------------|
| Automatic (default) | Fetch companion SHA-256; on **match** proceed; on **mismatch** fail closed; if sidecar **missing**, warn and continue (channel consistency only) |
| Strict pin | `CHECKSUM=<64-hex>` env forces equality with downloaded bytes; mismatch aborts |

Trust bounds: same-channel companion digests prove **consistency** of the two files on that channel. They are **not** a substitute for signed releases or out-of-band verification of the channel itself.

Optional CI / operator pin:

```bash
CHECKSUM=<sha256-of-script> curl -fsSL https://raw.githubusercontent.com/Wilgat/gitlab-nginx/main/gitlab-nginx | sh
```

## Domain / host setup privilege

Commands that mutate the host (`run`, `nginx-conf`, `ssh-hostname`, `remove-lpu`, and related paths) **require root**. Non-root invocation must fail closed (not partially reconfigure the system). Type 0 lifecycle (`install`, `version`, `about`, `self-update`, `self-uninstall`) remains usable without root for user-local installs. `remove-lpu` is **not** Type 0 self-uninstall (CLI binary only).

## Scope notes

- This product installs and configures **GitLab CE**, **Certbot**, and **external Nginx** when domain setup is run — treat those ecosystems’ own advisories as applicable.
- Report security issues in **this** script’s install, integrity, privilege, or configuration generation paths to the maintainer contact above.
