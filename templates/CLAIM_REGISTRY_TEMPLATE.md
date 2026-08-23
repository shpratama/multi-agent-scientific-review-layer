# Claim Registry — <project name>

Statuses: `ESTABLISHED` `SUPPORTED` `PLAUSIBLE` `UNRESOLVED` `REFUTED`
`UNKNOWN` `STALE` (see `config.json` → `claim_status_notes`). **Reviewer
consensus never sets `ESTABLISHED`** — only a `DECISIONS.md` entry citing
empirical evidence does. `STALE` is additive, not a replacement — a `STALE
ESTABLISHED` claim is still `ESTABLISHED`, flagged as needing re-validation
(PROTOCOL.md §10.1).

Provenance tag on every claim: `historical` (found during a legacy
retrospective audit, not yet reviewed) / `newly-reviewed` (has been through
a review package) / `new` (arose after this framework was in use).

---

## C-001

- **Claim:** <the claim, stated precisely and falsifiably>
- **Provenance:** historical / newly-reviewed / new
- **Context:** <where/why this claim arose>
- **Assumptions:** <list>
- **Depends on:** <file/method this claim's validity rests on> @
  sha256:`<hash from PowerShell Get-FileHash -Algorithm SHA256>` (repeat per
  dependency; leave "none recorded" only if the claim genuinely has no code
  dependency, e.g. a pure literature claim — see PROTOCOL.md §6.1, §10.1.
  This field is what lets a later methodological change automatically
  qualify for risk escalation and staleness detection.)
- **Supporting evidence:** <MUST be a citation, not free text: a ledger
  citation (`investigation_id`+`event_id`) or an experiment citation
  (`E-xxx` + artifact pointer). Explanatory prose may accompany it but
  cannot replace it — see `config.json` → `evidence_field_policy`. "none
  yet" is a valid value; a paraphrase of what you expect the evidence to
  show is not.>
- **Relevant experiments:** `E-xxx, ...`
- **Objections:** `O-xxx, ...`
- **Limitations:** <known scope limits, even if the claim is otherwise
  supported>
- **Risk level:** R0–R4 (see PROTOCOL.md §6; check §6.1's escalation rule
  before finalizing)
- **Review package:** `REVIEWS/<review_id>/` or "none"
- **Decision:** `D-xxx` in DECISIONS.md, or "none — reviewer recommendation
  only"
- **Status:** ESTABLISHED / SUPPORTED / PLAUSIBLE / UNRESOLVED / REFUTED /
  UNKNOWN [+ STALE]
- **Last updated:** <YYYY-MM-DD>

<!-- Copy the block above for each new claim. Increment the ID: next free
C-xxx = max existing + 1, zero-padded to 3 digits. -->
