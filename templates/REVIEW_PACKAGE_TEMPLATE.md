# Review Package — <review_id>

`review_id` format: `<risk-level>-<short-slug>-<YYYY-MM-DD>`

## What's under review

<the change, claim, or methodological decision, stated precisely>

## Risk classification

- **Level:** R0 / R1 / R2 / R3 / R4
- **Rationale:** <one or two sentences — why this level, not the one above
  or below it>
- **Dependency-escalation check (PROTOCOL.md §6.1):** does any changed
  file/method appear in an existing claim's `Depends on` list? <yes -> C-xxx,
  escalate to R3+ and mark that claim STALE / no>

## Enforcement-floor check (PROTOCOL.md §0.1)

- [ ] Ran the check: `grep -l "hook_gate.py" ~/.claude/settings.json
  ~/.claude/settings.local.json ./.claude/settings.json
  ./.claude/settings.local.json` (or the PowerShell equivalent in §0.1) —
  found in at least one file.
- If **not found**, this review proceeds `ADVISORY-ONLY` — say so
  explicitly here, don't silently continue as if §22's `ENFORCED` rows
  apply: <state which reviewer-isolation guarantees are therefore not
  actually protected on this machine>

## Reviewed target fingerprint(s) (PROTOCOL.md §10.1)

<file path> @ sha256:`<hash>` (computed with `PowerShell Get-FileHash
-Algorithm SHA256`, never MATLAB/Python) — repeat per file this review's
conclusions depend on. Re-hash and compare before relying on this review
later; a mismatch means re-validate (§10.1), not "still valid."

**Validity:** CURRENT / STALE

## Engaged reviewers

- [ ] Code Auditor — `code_auditor.md`
- [ ] Math Auditor — `math_auditor.md`
- [ ] Scientific Auditor — `scientific_auditor.md`
- [ ] Red Team — `red_team.md`

(Check only the roles actually relevant/required for this risk level per
PROTOCOL.md §6; explain any omission below.)

## Reconstruction (PROTOCOL.md §8.1, added after Pilot 2)

- [ ] `DISPOSITION_MANIFEST.md` exists, and every hypothesis/experiment/
  contradiction ID from a fresh `get_investigation_state` call has
  exactly one disposition, with a real reason on every `EXCLUDED` row.
- [ ] `CANONICAL_EVIDENCE.md`'s Scope section matches the manifest's
  source-file scope exactly.
- [ ] Every `INCLUDED`, `executed: true` experiment's captured
  stdout/stderr (from its `RESULT_RECORDED` event in the raw JSONL) is
  present in `CANONICAL_EVIDENCE.md`, or explicitly marked unretrievable.

## Evidence bundle every reviewer receives

**Bundle-identity attestation (PROTOCOL.md §5.0, config.json →
`bundle_identity_policy`, added after Pilot 1's postmortem):**
Canonical bundle file: `CANONICAL_EVIDENCE.md`. Prefer every reviewer
`Read`-ing this exact file by path over pasting text — mechanical
byte-identity, not a promise (PROTOCOL.md §5.0, validated in Pilot 2).
- [ ] Every engaged reviewer received this exact file/text, unedited —
  no role-tailoring.
- [ ] If any role received a subset/superset of it, that deviation is
  disclosed here explicitly: <role> received <what was added/removed>
  because <reason> — never a silent difference.
- [ ] The bundle contains no orchestrator-authored interpretive
  annotation pointing at which fact matters or what it suggests (neutral
  fact statements are fine and expected; "notice that..."/"this
  suggests..." framing is not). Any pattern the orchestrator noticed
  while building the bundle was reported to the human before dispatch,
  separately from this document.

## External context (PROTOCOL.md §5.1, config.json → `external_context_policy`)

State here whether any reviewer is expected to need general/public
reference material (language docs, standards) to reach a `STATIC_FACT`
finding — if so, note that the permission is uniform across all engaged
roles, not offered to one. Case-specific external material (a GitHub
issue about this exact bug, etc.) is never permitted.

## Related claims / hypotheses

`C-xxx`, `H-xxx`

## Dispatch record

| role | dispatched via | date | file |
|---|---|---|---|
| code_auditor | fresh subagent / codex / other | | `code_auditor.md` |
| math_auditor | | | `math_auditor.md` |
| scientific_auditor | | | `scientific_auditor.md` |
| red_team | codex (primary) / agy via CLI subprocess (secondary, PROTOCOL.md §5.2) / fresh subagent | | `red_team.md` |

If `red_team` was dispatched via `agy`: note here whether it answered on
the first attempt or needed the one permitted retry, and if it refused
twice, say so explicitly (PROTOCOL.md §5.2 — a refusal is never recorded
as "no findings").

## Status

`drafted` / `dispatched` / `reviews in` / `synthesis done` / `awaiting
decision` / `decided` — see `SYNTHESIS.md` and, for R3/R4, `DECISIONS.md`.
