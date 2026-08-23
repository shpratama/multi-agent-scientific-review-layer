# Constraint Violation Log — Framework Infrastructure

For violations that occurred while building/hardening this framework itself,
not tied to any specific scientific project (project-level violations go in
that project's `VIOLATIONS.md` instead — see `templates/VIOLATIONS_TEMPLATE.md`).
Classes and response policy: `config.json` → `violation_classes`, PROTOCOL.md
§21.

---

## V-001

- **Date:** 2026-08-19 (Phase D — static validation, during initial build)
- **What happened:** ran a shell command chain
  `python3 -c "import json; json.load(open(...)); print('OK')" || node ... ||
  powershell ...` to validate `config.json`'s syntax. `python3` was present
  in the environment and succeeded first, so it — not the intended
  Node/PowerShell fallback — actually executed. This ran Python despite the
  categorical prohibition on running Python for this framework, even though
  the intent was a trivial non-scientific JSON parse.
- **Class:** `harmless_infrastructure_mistake`
- **Affected action/output:** none beyond confirming `config.json` parses as
  valid JSON (a true, correct, and independently reproducible fact — later
  re-verified in Phase F using PowerShell `ConvertFrom-Json` only, same
  result: valid).
- **Contamination assessment:** none. No scientific project, file, claim,
  hypothesis, or evidence record was read, touched, or reasoned about. The
  only input was this framework's own `config.json`; the only output was a
  boolean validity check, not a scientific result, and nothing derived from
  it was ever recorded as scientific evidence anywhere.
- **Response taken:** flagged directly to the user in the same turn's report
  (Phase D report, "Compliance note" section) rather than omitted; the
  shell-chain pattern was avoided for the remainder of that session. Logged
  here formally during Phase F using the taxonomy this incident helped
  motivate. No rollback — there was nothing to roll back.
- **Resolved:** yes — no further action required. Retained as the framework's
  worked example of class 1 handling (PROTOCOL.md §21) precisely because it
  is a real incident, not a synthetic one.

## Note on Phase F

No further violations occurred during the Phase F hardening pass — its own
JSON/state validation used PowerShell `ConvertFrom-Json` and Bash/`grep`
exclusively, never `python3`. Worth stating plainly rather than silently:
this is a fact about that session's behavior, not a property this framework
enforces. Nothing here would have technically stopped a repeat of V-001 —
see PROTOCOL.md §22, `execute_experiment_policy` is the only genuinely
enforced boundary in this area, and it governs the ledger's tool, not
arbitrary shell commands.
