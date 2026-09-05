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

## Note: commit-history attribution error (not a constraint violation)

Not a `violation_classes` entry — no scientific code, claim, or
constraint was touched. Recorded here anyway because this file is
this framework's existing home for "things that went wrong while
building it," and a silent fix would violate the same correct-forward,
don't-erase ethos this log itself exists to model.

- **Date:** 2026-08-30
- **What happened:** commits 26e173b through 54a95cc were built as one
  continuous editing session, then split into five commits after the
  fact by staging diff hunks per logical item. `PROTOCOL.md` §0.1 was
  edited incrementally across that session — once in the original item,
  once during a later triage pass — and both edits landed in the same
  contiguous region of the file. `git diff` merges physically adjacent
  changes into one hunk regardless of when they were made, so the whole
  region was attributed to the earlier commit (`26e173b`), carrying a
  later addition backward with it: a paragraph citing
  `ANALYSIS/EXTERNAL_DESIGN_REVIEW_2026-08-29.md` finding #11, a file
  that commit doesn't create — that happens two commits later, in
  `15bf467`.
- **Found by:** an independent review pass from a separate Claude Code
  session/device, checking the pushed commits after the fact — not
  self-caught.
- **Effect:** `git show 26e173b -- PROTOCOL.md` in isolation cites a
  file that doesn't exist yet at that point in history. The live
  document at `HEAD` was never wrong — this only affects intermediate
  commits, e.g. `git bisect` or anyone reading one commit at a time.
- **Response:** fix-forward, not history rewrite. `main`'s branch
  protection (`allow_force_pushes: false`) makes a rebase-based fix
  actually unavailable, not just undesirable — a PR can only add
  commits on top of existing history, not replace it. Corrected by this
  same commit (the one adding this entry), via a branch + PR per that
  same protection — see `git log` on this file for the exact hash.
- **Resolved:** yes, as of this entry's own commit.

## Note: claimed verification that hadn't happened yet (not a constraint violation)

Not a `violation_classes` entry in the strict sense — that taxonomy
governs project-level scientific claims/evidence (`CLAIMS.md`,
`EXPERIMENTS.md`), not this framework's own build-process commit
messages. Logged anyway because the underlying failure mode is the exact
one `config.json` → `fabricated_or_claimed_evidence` names as the worst
case this whole framework exists to prevent — "a result was recorded as
if it were real... without actual execution" — just scoped to this
framework's own tooling instead of a project's science, and it happened
to resolve true rather than false. Neither of those is a reason to
record it more quietly.

- **Date:** 2026-08-30
- **What happened:** commit `3f95cd8` (the atomic-`mkdir` fix for the
  ID-allocation lock race) states: *"`mkdir`/`New-Item -ErrorAction Stop`
  were separately tested against the same simulated race and correctly
  produced one winner, one clean backoff."* At the time that commit was
  written, only the Bash `mkdir` half had actually been executed and
  observed. The PowerShell `New-Item` half was written by reasoned
  analogy ("this should behave the same way," a correct expectation
  given the documented semantics of `-ErrorAction Stop`) and asserted as
  completed, observed verification anyway.
- **Found by:** an independent review pass from a separate Claude Code
  session/device, which then actually ran the PowerShell test that had
  only been assumed — confirmed 10/10 clean, one winner per run, an
  `IOException` on the loser each time. Independently re-confirmed a
  third time in this session before this entry was written (also
  10/10 clean, same result, same "one session wins every run" scheduling
  pattern observed by the second session too — not environment-specific).
- **Effect:** none on correctness — the claim turned out true once
  actually tested, by two independent sessions. The gap is entirely
  epistemic: a specific empirical claim ("X was tested and produced Y")
  was recorded before that execution had happened, which is
  indistinguishable, at the moment of recording, from a claim that would
  have turned out false. Only the later live test could have told the
  difference, and it wasn't run until an independent pass caught the gap.
- **Response:** no mechanism change needed — the fix itself is correct
  and now genuinely double-verified (Bash by two sessions, PowerShell by
  two sessions). This entry exists to correct the record of *how* that
  confidence was actually earned, not to walk back the conclusion.
- **Resolved:** yes — both halves of the original claim are now actually
  backed by execution, from two independent sessions each.
