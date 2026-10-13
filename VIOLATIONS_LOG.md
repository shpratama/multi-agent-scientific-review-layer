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

## Note: documented command shipped without being run (not a constraint violation)

Same status as the two notes above: not a `violation_classes` entry, logged
because this file is the home for "things that went wrong while building it".
This one is the third of its family, which is why it is worth stating as a
pattern and not only as an incident.

- **Date:** 2026-10-13
- **What happened:** `PROTOCOL.md` §0.1 (added 2026-08-29) gave the
  enforcement-floor check in two shells, side by side, as if equivalent. Only
  the Bash form was ever run; the 2026-08-30 "live-tested" note was scoped to
  Bash and did not claim otherwise, but nothing marked the PowerShell form as
  untested. Run for the first time, it returned **no match whenever any one
  listed path did not exist, even though a listed file contained the
  registration** — and one path is almost always absent, since
  `settings.local.json` is optional. `Select-String -Path` raises a
  statement-terminating `PathNotFound` error during path resolution, so
  `-ErrorAction` cannot suppress it. Both forms also used working-directory-
  relative paths for project-level settings, so a project registration was
  missed whenever the shell was in a subfolder.
- **Found by:** an independent claims audit run on a different device against
  a fresh clone, then reproduced here before anything was changed. Not
  self-caught.
- **Effect:** on a correctly configured Windows machine the check would have
  shown the `ADVISORY-ONLY` banner (§0.1), i.e. a warning that fires
  everywhere and so carries no information. I have no evidence either way on
  whether it misled a real review; the banner's conclusion on a machine with
  no gate installed happened to be right by accident.
- **The pattern:** this is the third logged instance of a documented step
  getting ahead of its execution — a commit citing a file that did not exist
  yet (`26e173b`), a "separately tested" claim for a half that had not been
  run (`3f95cd8`), and now a command never run in one of its two shells. The
  same audit found two nearby claims stronger than what had been exercised:
  that `project_key` matches Claude Code's own directory slug (false for 7 of
  17 directories on the machine checked; §18) and that the fingerprint check
  was validated (one fixture, one machine, unchanged line endings; §10.1,
  Phase F Test I). Each earlier response ("no mechanism change needed") was
  fair for its own instance; three instances say per-incident fixes are not
  enough.
- **Response:** fix-forward (branch + PR). The new part is `tests/`: each test
  **extracts the documented code block from `PROTOCOL.md` and runs it**, so a
  command that does not run, or a recipe that drifts from its text, fails a
  test. Each test was also checked against the old text or a deliberately
  degraded recipe to confirm it can fail. **What this does not do:** nothing
  runs these tests automatically (there is no CI), so a green run means
  someone ran it on a named host; and PowerShell 7, Linux and macOS remain
  unrun. A CI workflow on Windows, Linux and macOS runners (including `pwsh`)
  would close those gaps and make an unrunnable documented command fail a PR
  check; it was not added here because it is persistent automation the owner
  has not asked for.
- **Resolved:** the specific defects, yes, on the hosts tested. The pattern,
  no — open until the tests run somewhere other than the machine that wrote
  them.
