# Phase F — Static / Synthetic Protocol-Level Tests

No MATLAB/Python executed anywhere in this file. Fixtures live in the
session scratchpad (ephemeral, ordinary temp storage — not part of the
persistent framework): `.../scratchpad/phase-f-tests/`. Tools used: Bash
(`mkdir`, `cp`, `grep`, `cat`, `wc`), PowerShell (`Get-FileHash`,
`ConvertFrom-Json`). Every result below reflects an actual command that was
actually run, not a narrative claim — commands are shown so this is
reproducible.

| Test | Result |
|---|---|
| A — New project | **PASS** |
| B — Continuing project | **PASS** |
| C — Legacy project | **PASS (documentation-level)** |
| D — R0 | **PASS** |
| E — R2 | **PASS** |
| F — R3 | **PASS** |
| G — Unsupported objection stays speculative | **PARTIAL** |
| H — Evidence vs. consensus | **PARTIAL** |
| I — Review invalidation | **PASS (tested end-to-end)** |
| J — Reviewer isolation representation | **PASS** |
| K — Reviewer modification prevention | **PARTIAL — limitation documented, not hidden** |
| L — Constraint violation handling | **PASS** |

## Test A — New project initialization

**Command:** copied the four core templates into a fresh fixture
`projects/TEST--fixture-new/` exactly as `SKILL.md`'s init step instructs
(`cp STATE_TEMPLATE.md STATE.md`, etc.), then checked each file is non-empty
and `STATE.md` contains the `project_key`/`Current mode` fields.

**Result:** all 4 files created (42/33/22/26 lines respectively), both
fields present. **PASS.**

## Test B — Continuing project recovers pending state

**Setup:** wrote a synthetic `STATE.md` pointing at `C-001`/`H-001`/`O-001`/
`E-001`, a synthetic `EXPERIMENTS/E-001.md` with status
`PENDING_HUMAN_EXECUTION`, and a synthetic `REVIEWS/.../red_team.md` with an
`O-001` at status `OPEN`.

**Command:** `grep` for `STATE.md`'s pointers, then `grep -rl` across
`EXPERIMENTS/` and `REVIEWS/` for the statuses the continuing-session
procedure (PROTOCOL.md §17) says to scan for.

**Result:** both scans found exactly the fixture files their `STATE.md`
pointer named. **PASS** — the documented scan procedure actually surfaces
what it claims to, against realistic fixture content, not just in theory.

## Test C — Legacy claims classified historical/UNKNOWN

**Command:** `grep` confirming PROTOCOL.md §15 step 5 literally requires new
candidate claims from a retrospective audit to be recorded with `status
UNKNOWN` and `historical: true` — never a stronger status.

**Result:** confirmed present, unambiguous. **PASS at the documentation
level** — no live retrospective audit was performed in Phase F (that's
explicitly out of scope; the real EEG pilot hasn't started), so this
verifies the rule exists and is unambiguous, not that an agent will follow
it under real conditions. That behavioral question is deferred to the
actual pilot.

## Test D — R0 requires no review

**Command:** `grep -A3 '"R0"' config.json | grep review_required`

**Result:** `"review_required": false`. **PASS.**

## Test E — R2 triggers appropriate (not full) review

**Command:** `grep -A5 '"R2"' config.json`

**Result:** `"review_required": true`, `"reviewers":
["math_auditor_or_scientific_auditor"]` — engages the relevant auditor(s),
not the full four-role panel. **PASS.**

## Test F — R3 triggers full review including red team

**Command:** `grep -A5 '"R3"' config.json`

**Result:** `"review_required": true`, `"reviewers": ["code_auditor",
"math_auditor", "scientific_auditor", "red_team"]`. **PASS.**

## Test G — Speculative concern doesn't silently become a confirmed defect

**Command:** `grep` confirming `OBJECTION_TEMPLATE.md` requires a
`Resolution` field, populated only "when status changes from OPEN," citing
evidence, before a status other than `OPEN` is meaningful.

**Result:** the field exists and is structured to require evidence for any
status transition. **PARTIAL, not PASS** — honestly: these are hand-edited
markdown files with no schema validation. Nothing mechanically stops an
agent (or a human) from directly writing `Status: CONFIRMED` on a
`SPECULATIVE_CONCERN` objection with an empty or hand-waved `Resolution`
field. The template *guides* correct behavior; it does not *enforce* it.
Marking this PASS would be exactly the kind of overclaim Phase F exists to
catch.

## Test H — Evidence-backed claim distinguishable from reviewer consensus

**Command:** `grep` confirming `DECISIONS_TEMPLATE.md` has a `Reviewer
recommendations` field structurally separate from an `Empirical evidence
cited` field, both separate from `Decision`; and confirming
`evidence_field_policy` in `config.json` requires `CLAIMS.md`'s `Supporting
evidence` to be a citation, not prose.

**Result:** both structural separations confirmed present. **PARTIAL, not
PASS** — same reason as Test G: nothing validates that a `Supporting
evidence` citation actually resolves to a real ledger event or artifact, or
that `ESTABLISHED` wasn't hand-set without a corresponding `D-xxx` entry.
The structure makes the distinction representable and makes shortcuts
visible to a human reviewer skimming the file; it does not make shortcuts
impossible.

## Test I — Review invalidation on consequential dependency change

**Setup:** a fixture stand-in code file (`wola_synth.m.txt`, never executed
— MATLAB syntax as inert text) representing a WOLA synthesis function.

**Commands (all PowerShell, no MATLAB/Python):**
1. `Get-FileHash -Algorithm SHA256` on the original content → recorded as
   the claim's dependency fingerprint.
2. Modified the file's normalization line (simulating exactly the kind of
   methodological change §6.1 is about), re-hashed, compared to the
   recorded fingerprint.
3. Reverted the file to its original content (control case), re-hashed,
   compared again.

**Result:**
- Step 2 (real change): recorded `C46E2C54...`, current
  `6DA77679...` → **mismatch, correctly flagged STALE.**
- Step 3 (control, no change): hashes matched → **correctly stayed CURRENT,
  no false positive on an unmodified file.**

Both directions verified with real command output, not asserted. **PASS —
this is the one mechanism in Phase F that was built and tested
end-to-end, not just documented.**

## Test J — Independent reviews representable without conclusion exposure

**Command:** `grep -l` across all four `REVIEWER_PROMPT_*.md` files for any
of the other three roles' output filenames (`code_auditor.md`,
`math_auditor.md`, `scientific_auditor.md`, `red_team.md`).

**Result:** zero matches — no reviewer prompt references another role's
output file. **PASS** — confirms the prompts are self-contained by
construction, consistent with the process-isolation mechanism (fresh
`Agent` calls share no context) documented in PROTOCOL.md §5.

## Test K — Strongest available mechanism against reviewer code modification

**Evidence (not fixture-based — drawn from this environment's actual,
live configuration, inspected directly):**
- This session's available agent types (from the harness's own
  system-provided listing): `Explore` and `Plan` are defined as "All tools
  except Agent, Artifact, ExitPlanMode, Edit, Write, NotebookEdit" — i.e.
  `Bash`/`PowerShell`/`mcp__filesystem__*` remain available to them.
  `claude-code-guide` is the only listed type with zero write-capable tools
  (`Glob, Grep, Read, WebFetch, WebSearch`), but is scoped to a different
  task (Claude Code product questions).
- `grep -n "tool_name\|agent_type\|agent_id" hook_gate.py` confirms the
  existing `scientific-debug` gate's hook input carries `agent_type`/
  `agent_id` and evaluates them identically to the main agent — i.e. a
  `protected_paths` block genuinely applies to subagent tool calls too.

**Result: PARTIAL, explicitly not a clean PASS.** Dispatching reviewers via
`Explore`/`Plan` **does** technically prevent `Edit`/`Write`/`NotebookEdit`
(ENFORCED). It does **not** technically prevent `Bash`/`PowerShell`/
`mcp__filesystem__*` writes (still ADVISORY) unless combined with an active
ledger investigation whose `protected_paths` cover the exact files under
review (ENFORCED, conditional on that step being taken). No available
mechanism in this environment provides unconditional, always-on tool-level
write prevention for a reviewer role that also needs read/search tools.
Documented as a limitation in `SELF_REVIEW_PHASE_F.md` items 1 and 13,
not silently treated as solved.

## Test L — Constraint violation handling is defined and demonstrated

**Command:** confirmed PROTOCOL.md §21 exists (grep, 1 match), confirmed
`templates/VIOLATIONS_TEMPLATE.md` exists, confirmed `VIOLATIONS_LOG.md`
contains a real (not hypothetical) `V-001` entry — the Phase D `python3`
incident, classified and logged using the taxonomy this section defines.

**Result: PASS** — the protocol defines the four violation classes and
their responses, and a real prior incident from this framework's own build
was retroactively classified and logged as the worked example, not a
synthetic one.
