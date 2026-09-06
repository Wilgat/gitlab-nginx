# Review: README human readability + requirement / checklist / test coverage

**Date:** 2026-09-06  
**Product:** gitlab-nginx **2.5.2**  
**Claim:** C-full-product (specialized CLI + domain)

## Verdict

**Approve with follow-ups** — human-facing README and all registered requirements now pass the people-and-folders gate; coverage gaps that blocked “full product law” (coding-style REQ, sudo allow table, dual mention, DTV, TP-GLN-11…13) are closed in this change. Host-mutating GitLab setup stays **optional** in CI (honest).

## Human readability (README)

| Finding | Severity | Fix this change |
|---------|----------|-----------------|
| Mandatory product section order missing (no Quick Installation / Usage / Examples / Platform / Related / Last Update) | bug | Rewrote per product README kit |
| Install buried under a long review letter; `CHECKSUM=` presented as the secure primary | bug | Automatic companion is primary; pin is Advanced |
| H1 was not `app-name - short-description` | suggestion | `# gitlab-nginx - GitLab CE with external Nginx and Let's Encrypt` |
| Lead jargon: Type 0 / Type O / LPU as the only words | suggestion | Voice pack: you / dedicated accounts / not empty-argv GitLab setup |
| No numbered main menu claimed | n/a | Empty argv remains install-ensure; README says so |

## Human readability (requirements)

| Finding | Severity | Fix this change |
|---------|----------|-----------------|
| Only storage REQ had **§1.1 Human-facing** (11/11 Fail except one) | bug | §1.1 on all 13 Active files |
| Related shell REQs missing **Under command line for normal user only** | bug | Named section added |
| CLI-interface Purpose led with Type 0-centric catalog | suggestion | People sentence + privilege long form |
| Interactive REQ still taught live `[ -t` inside `prompt_*` | bug | Measure outside functions; helpers consume `TTY` |

## Coverage (requirements / checklists / tests)

### Registry (Step −1)

- Registered ∩ disk: 13 files (was 11). New: `requirement-shell-script-coding`, `requirement-shell-sudo-command`.
- Orphans: none. Ghosts: none.
- Class gate: software-development + Active class file. Residual: dest approver **none**; dest fence **none**; coding-style **points**.

### Sufficiency (C-full-product)

| Surface | Owner | Status |
|---------|-------|--------|
| Lifecycle verbs | CLI + self-management + zero-arg | ok |
| Domain verbs | domain REQ **and** CLI-interface (dual mention) | ok (was Gap) |
| Cache + persistence | storage REQ | ok |
| Automatic checksum | checksum REQ + README | ok |
| POSIX coding specialize-in | **new** coding-style REQ | ok (was Gap) |
| In-tool sudo argv | **new** sudo REQ studied table | ok (was Gap) |
| Numbered main menu | unclaimed | n/a |
| Dest / fence-test | class residual none | n/a |
| Full interactive `run` | TP-GLN-09 | optional (root+TTY+host) |

### Checklists

Filled **genesis/harness** audits under `docs/checklists/` are not product-law evidence (and are gitignored). This product review is the tracked artifact: `reviews/reports/2026-09-06-readme-req-coverage-review.md`. Blank forms remain under `docs/templates/checklists/` (harness).

### Tests

| Gap | Fix |
|-----|-----|
| No `reviews/requirement-test-matrix.md` | added |
| `email` / `ssh-hostname` / `remove-lpu` unproven beyond help text | TP-GLN-11…13 |
| DTV missing on most REQs | Design-time verification tables added (TP-IDs + `tests/*` + `reviews/test-plan.md` only) |

## Follow-ups (not blocking 2.5.2)

| ID | Item |
|----|------|
| P1 | Centralize in-tool `sudo` into `util_sudo` (REQ notes Gap) |
| P1 | Operator-readable `Next:` on root-required fatals (copy still says “use sudo”) |
| P2 | Host harness for TP-GLN-09/10 if CI ever has a disposable VM |

## CIAO

- **Caution:** Non-root domain mutations stay fail-closed; checksum mismatch still aborts.
- **Intentional:** README distinguishes install-the-program vs set-up-GitLab.
- **Anti-fragile:** User-local install + automatic sidecar; Termux-class ceiling documented.
- **Over-protect:** Dual mention + coding-style home so lessons do not arrive raw.
