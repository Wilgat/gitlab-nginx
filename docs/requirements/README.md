# Requirements

Authoritative product and engineering requirements for this project live here.

**Current state (2026-09-06 — gitlab-nginx specialized):** **13** Active `requirement-*.md` — class `requirement-class-software-dev`, **eleven** `requirement-shell-*.md` (automatic-checksum, CLI interface, cli-storage, CLI zero-arguments, idempotency, interactive vs noninteractive, modular design, output, self-management, **script-coding**, **sudo-command**), and domain SSOT `requirement-domain-gitlab-nginx`. Registry: `index.md` (must stay in sync). Self-install/self-maintenance + GitLab/Nginx domain. Class residual: dest approver **none**; dest fence conditions **none**; ship `VERSION` **2.5.2**. Do **not** invent additional requirement paths without a real ownership gap — verify on disk and register new files in `index.md` in the same change. Do **not** empty this registry to match genesis.

## Purpose

- **Plan mode** designs work by reading and **updating** these docs — not only the session `plan.md`.
- **Implement** delivers code and docs that **trace** to requirement IDs.
- **Review** verifies delivery against requirements **and** defensive (CIAO) checklists.

## Layout

| Path | Role |
|------|------|
| `docs/requirements/index.md` | Registry of all requirements (IDs, status, owners) — keep in sync with files |
| `docs/requirements/requirement-*.md` | CIAO-style project requirements (flat; primary live convention) |
| `docs/requirements/<area>/<REQ-ID>.md` | Optional council-style `REQ-<AREA>-<NNN>` files |

Suggested areas (if using subdirs): `product/`, `platform/`, `security/`, `ops/` — create as needed.

## ID scheme

- **Primary live convention:** `requirement-<topic>.md` or `requirement-<language>-<topic>.md` (e.g. `requirement-shell-cli-interface.md`, `requirement-class-software-dev.md`).
- Optional council-style: `REQ-<AREA>-<NNN>` (example: `REQ-PLAT-001`) if using area subdirs.
- IDs/keys are stable. Prefer status/`supersedes` over renumbering.
- Record every key in `index.md` when created or status changes.

## Status values

Live product law on this project uses the **file header Status** (and matching registry **Status** column):

| Status | Meaning |
|--------|---------|
| `Active` | Normative product law — implement and review against it |
| `Draft` | Proposed; not yet approved as binding law |
| `Deprecated` | No longer active; keep file for history |
| `Superseded` | Replaced by another requirement key (link it) |

Legacy/council synonyms sometimes seen in older docs (`approved`, `in-progress`, `done`) map to **Active** when the file is registered and binding. Prefer **Active** for this registry.

## Plan-mode rules (mandatory)

When planning non-trivial work:

1. Search `docs/requirements/` (and `index.md`) for related requirements.
2. Decide: **new requirement**, **update existing**, or **no requirements impact** (state why).
3. Apply requirement file changes **before** or as part of finishing the plan.
4. Session plan (`plan.md`) must list affected REQ-IDs and whether each is create / update / no-change.
5. Do not implement against unstated intent — if behavior is required, it belongs in a requirement file.

## Implementation rules

- Every non-trivial PR/change set cites one or more REQ-IDs in commit/PR/summary when requirements exist.
- Do not invent requirements only in code comments; promote durable intent here.
- **No placeholders** in requirement files: no `TBD`/`TODO` acceptance criteria, hollow sections, or stub “later” text. See `AGENTS.md` → **No-placeholder policy**.
- Product source comments cite only **live** `requirement-*.md` files (never invent basenames).

## Review rules

- Requirements changes and code/docs delivery use the project’s plan/implement/code-review/security checklist process.
- Empty registry is valid for genesis; do not invent requirements to “fill” the index.
- Software-development class requires Active `requirement-class-software-dev.md` in the registry.
