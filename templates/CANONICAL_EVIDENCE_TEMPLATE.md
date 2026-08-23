# Canonical Evidence — <review_id>

The single file every engaged reviewer receives — pasted or, preferably,
`Read` directly by path so byte-identity is mechanical rather than
trusted (PROTOCOL.md §5.0). Facts only. No orchestrator-authored
annotation pointing at which fact matters or what it suggests — if you
notice a pattern while writing this, that observation goes to the human
before dispatch, not into this document.

## Scope

<Which file(s)/line-range(s) and which ledger objects are in scope for
this review. Must match `DISPOSITION_MANIFEST.md` exactly — this is the
"selection transparency" half of the pair; the manifest is the coverage
half.>

## Source

Investigation: `<investigation_id>`, title, `event_count`, `pivot_count`,
`escalated`, `chain.valid`, `protected_paths`. State plainly whether this
was read fresh this session (it should be) or reused from an earlier
read (say when, and whether it was re-verified unchanged).

## File fingerprint(s), if any file dependency exists

`<path>` @ sha256:`<hash>` (from `PowerShell Get-FileHash`, file
read-only, never modified) — repeat per dependency.

## Source file excerpt(s), if any

Verbatim, with line numbers, exactly matching the Scope section above.

## Hypotheses (only those marked INCLUDED in the disposition manifest)

Verbatim hypothesis text, falsification criterion, and current status
for each.

## Experiments (only those marked INCLUDED)

For each: `description`, `planned_command`, actual executed `command`,
`exit_code`, and — per `config.json` → `raw_output_retrieval_policy` —
the actual captured stdout/stderr from that experiment's
`RESULT_RECORDED` event in the raw investigation JSONL (read via
`Read`/`Grep` on `scientific-debug/data/<investigation_id>.jsonl`, a
static file read, never execution). If no `RESULT_RECORDED` event exists
for an included, `executed: true` experiment, say so explicitly — do not
omit the field silently.

## Contradictions (only those marked INCLUDED)

Verbatim description and resolution text.

## End of canonical evidence bundle

State plainly that this is the end — a reviewer should never have to
guess whether more follows.
