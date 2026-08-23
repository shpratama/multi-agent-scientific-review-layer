# Disposition Manifest — <review_id>

Every hypothesis ID and experiment ID the source investigation actually
has (per `get_investigation_state`, called fresh — not from memory)
receives exactly one row. `INCLUDED` means it appears in
`CANONICAL_EVIDENCE.md`; `EXCLUDED` means it doesn't, and requires a real
reason, not a placeholder. This is a coverage check, not a completeness
mandate — a tightly-scoped bundle that excludes irrelevant material is
correct and expected. What's not acceptable is a source ID with no row at
all (PROTOCOL.md §8.1, `config.json` → `disposition_manifest_policy`).

**Check before dispatch** (deterministic, no LLM judgment — a plain
diff/text-search suffices): does every ID from `get_investigation_state`
appear exactly once below? Does every `EXCLUDED` row have non-empty
reason text?

## Hypotheses

| ID | Disposition | Reason (required if EXCLUDED) |
|---|---|---|
| <hypothesis_id or short label> | INCLUDED / EXCLUDED | |

## Experiments

| ID | Disposition | Reason (required if EXCLUDED) |
|---|---|---|
| <experiment_id or short label> | INCLUDED / EXCLUDED | |

## Contradictions

| ID | Disposition | Reason (required if EXCLUDED) |
|---|---|---|
| <contradiction_id> | INCLUDED / EXCLUDED | |

## Source-file scope

<file path(s) examined and the exact line range(s) excerpted into
CANONICAL_EVIDENCE.md, or "full file" if unexcerpted. Anything outside
this range is out of scope for every reviewer, and every reviewer's
prompt should say so — see CANONICAL_EVIDENCE_TEMPLATE.md's Scope
section, which should match this exactly.>
