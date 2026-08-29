# Multi-Agent Scientific Review Layer — Protocol

Global infrastructure, installed the same way as the `scientific-debug` ledger
system: it lives under `~/.claude/`, is not tied to any one repository, and
applies to whichever project a Claude Code session is currently working in.
This document is the full reference. `~/.claude/skills/scientific-review/SKILL.md`
is the short advisory version read at the start of a session.

**Deployment note:** this repository is the reusable framework only.
`projects/`, `PROJECTS.md`, `POSTMORTEMS/`, and dated subfolders under
`ANALYSIS/` hold real, per-engagement investigation data (claims,
findings, sometimes client-identifying detail) and are deliberately kept
local-only per deployment (`.gitignore`), never committed. A few places
below cite a specific postmortem or project by name as the evidence
behind a protocol change — that citation is accurate for the deployment
where the finding originated; a fresh clone won't have that specific file
locally unless it's been carried over separately, but the protocol change
itself still applies.

**Revision history:** built 2026-08-19 (Phase A–E). Hardened 2026-08-19
(Phase F — adversarial validation of the infrastructure itself, before any
real pilot): corrected an overclaim about reviewer tool-level isolation
(§5), added risk escalation via claim dependencies (§6.1), review
freshness/`STALE` status (§10.1), a non-scientific-project guard (§16.1),
constraint-violation handling (§21), and an explicit enforcement-status
table (§22). See `SELF_REVIEW_PHASE_F.md` and `PHASE_F_TESTS.md` for what
was actually verified versus merely documented. **Empirically validated
2026-08-19 (same day, separate pass):** the §5/§22 reviewer-isolation claims
were converted into explicit ledger hypotheses and tested via a real
dispatched subagent rather than left as documentation-inference — see
`scientific-debug-ledger` investigation `review-layer-enforcement-claims-2026-08-19`
(H1/H2/H3) — confirming the tool-restriction and gate-blocks-subagent-writes
claims hold in practice, with one named ledger-coverage gap (H1 could not be
formally promoted past `UNTESTED` — the ledger's experiment model captures
OS-subprocess results only, not Agent-dispatch transcripts). **Hardened
2026-08-20 after Pilot 1's postmortem** (`POSTMORTEMS/PILOT1_POSTMORTEM.md`):
Pilot 1 itself violated §5's "same underlying evidence package, no leaked
conclusions" principle — the orchestrator hand-authored four non-identical,
role-tailored evidence bundles, and wrote explicit interpretive annotations
into every one of them naming the pilot's two headline findings before any
reviewer looked at anything. §5 now states bundle-identity discipline as an
explicit rule (below), not an assumed practice. A follow-up pilot run
2026-08-20 (postmortem kept locally per-deployment under `POSTMORTEMS/`,
not part of this shared template — see the deployment note above)
confirmed bundle-identity discipline holds when reviewers `Read` one
literal file rather than receiving retyped text, and produced 4/4
independent reviewer convergence on a new structural gap — evidence
bundles built from `get_investigation_state` never included captured
experiment output. **Hardened again 2026-08-20** (after a design analysis
in `ANALYSIS/RECONSTRUCTION_INDEPENDENCE_ANALYSIS.md`, not a pilot):
added §8.1 (disposition manifest, scope declaration, raw output
retrieval — closing the Pilot 2 gap directly) and §5.1 (external context
policy, closing an asymmetry where one Pilot 2 reviewer used external
documentation others weren't offered). Deliberately **not** added yet:
an Evidence/Package Auditor role, dual reconstruction, or typed file-vs-
investigation dependencies — reserved as open design questions, not
implemented without further evidence they're needed.

## 0. What this is (and isn't), and how it relates to `scientific-debug`

Two systems now coexist, with a clean division of labor:

- **`scientific-debug`** (ledger + PreToolUse gate + `SKILL.md`) owns
  **experimental/evidence integrity for a single debugging investigation**:
  hypothesis → falsification criterion → registered/executed experiment →
  machine-captured result → hypothesis status. It is the only thing in this
  stack with real enforcement power (the PreToolUse gate blocks
  `Edit`/`Write`/`Bash`/etc. against `protected_paths`), and it is authoritative
  for that narrow question: *did some real investigation work happen before
  this file was touched?*
- **`scientific-review`** (this system) owns **claims, hypotheses at the
  project/methodology level, independent multi-role review, objections, risk
  classification, and the human-decision record**. It has no enforcement power
  of its own — it is advisory, like `scientific-debug`'s `SKILL.md` half. It
  does not run experiments and does not maintain a second evidence store.

**Relationship between the two "hypothesis" concepts.** The ledger's
`add_hypothesis` is scoped to one investigation and one pivot counter — it is
about "what's making this specific symptom happen." This layer's `H-xxx`
hypotheses (§10) are broader scientific/methodological hypotheses that can
outlive and span several ledger investigations. A single `H-xxx` here often
motivates one or more `start_investigation` calls in the ledger when it needs
disciplined experimental debugging; the review-layer hypothesis record should
then cite those `investigation_id`s.

**Evidence stays in one place.** This layer never stores raw experiment
stdout/stderr as its own source of truth. For anything executed through the
ledger, the source of truth is the ledger event (`investigation_id` +
`event_id`) — cite it, don't copy it. For anything a human runs (all
MATLAB/Python/scientific work — see §2), the source of truth is the artifact
the human produces (a file, a pasted console log with a timestamp); this
layer's `EXPERIMENTS/E-xxx.md` records point at that artifact rather than
re-deriving it.

### 0.1 Enforcement-floor check (added 2026-08-29)

§22's only unconditionally `ENFORCED` row — the `PreToolUse` gate blocking
a reviewer's writes to `protected_paths` — is entirely imported from
`scientific-debug`. This repo does not ship that system and does not
check for it. On a machine where it isn't installed, or isn't registered,
every `ENFORCED` claim in §22 silently degrades to `ADVISORY` with no
warning to the Primary Agent or the human.

**Fires at three points, not one** (the first version of this section
only had the third — caught during review, before this ever reached a
public commit): §16 step 0
(new investigation, before initializing `projects/<project_key>/`), §17
step 0 (continuing investigation, before reading anything else), and
before dispatching any review (§8, via `REVIEW_PACKAGE_TEMPLATE.md`'s
checklist). The first two matter specifically because Research Mode work
can run an entire session without ever creating a review package — a
check that only fired at dispatch would show nothing for that whole
class of session, silently.

**What this still doesn't reach:** a session doing genuinely R0-only
work in a project that correctly never gets a `projects/<project_key>/`
entry at all (§16.1) never touches §16 or §17 either — there is currently
no point inside this repo's own control where the check would fire for
that case. Closing that fully needs the check to live in `SKILL.md`
itself (the actual session-start file), which this repo doesn't ship
(it's per-device — see `README.md`). Arguably this residual gap matters
less than it sounds: `ENFORCED` claims were never claimed to apply to R0
work in the first place (§6 — R0 gets no review, by design), so there's
no protection silently missing there, only the banner. Noted rather than
silently accepted — revisit if a `SKILL.md` template is ever added to
this repo (a separate, already-discussed, not-yet-authorized item).

**Search command**, run at each of the three points above: the gate's
actual hook registration —

```bash
grep -l "hook_gate.py" "$HOME/.claude/settings.json" "$HOME/.claude/settings.local.json" ./.claude/settings.json ./.claude/settings.local.json 2>/dev/null
```
```powershell
Select-String -Path "$env:USERPROFILE\.claude\settings.json","$env:USERPROFILE\.claude\settings.local.json",".claude\settings.json",".claude\settings.local.json" -Pattern "hook_gate.py" -ErrorAction SilentlyContinue
```

**What this check actually proves, stated honestly** (an external design
review flagged this precisely — see `ANALYSIS/EXTERNAL_DESIGN_REVIEW_2026-08-29.md`
finding #11): a match
confirms the hook is registered *somewhere* in a settings file. It does
**not** confirm the hook is currently active, that its script is
up to date, that it's reachable (the referenced Python interpreter/script
path still exists), or that its `matcher` actually covers the paths in
play for this specific review. A passing check is weaker evidence than
§0.1's banner text alone might imply — treat it as "the dependency hasn't
been obviously skipped," not as "the gate is confirmed working for this
review."

If this finds nothing in any of those files, state plainly and loudly to
the user, before proceeding:

> ⚠ **No `scientific-debug` PreToolUse hook registration found. This
> session is running in ADVISORY-ONLY mode — none of §22's `ENFORCED`
> rows are actually enforced on this machine.** Reviewer tool-isolation,
> `protected_paths` write-blocking, and every other claim in this
> document that depends on that gate are documentation, not protection,
> until `scientific-debug` is installed and its hook is registered.

This is a real checklist item in `REVIEW_PACKAGE_TEMPLATE.md`'s own
"Enforcement-floor check" section (right after risk classification), not
just prose here — a review package cannot be filled out without
confronting it.

Category: **`MECHANICALLY-VERIFIABLE`** (§22) — the check itself is a
deterministic string search, no judgment call — but nothing forces it to
actually run before a session proceeds; it depends on the template being
followed, same as everything else not covered by the gate itself.

## 1. Core principle

Agents (Claude Code and the reviewer roles below) generate hypotheses,
objections, interpretations, and proposed experiments. **Experimental
execution and empirical evidence are a separate category.**

- LLM consensus is not scientific evidence. Four agents agreeing does not
  establish a claim.
- A reviewer saying something "seems wrong" does not establish that it is
  wrong.
- Every substantive objection gets classified (§9) so speculation cannot
  silently read as fact.

## 2. Hard operating constraints (apply in every session)

- Never run MATLAB, Python, MATLAB/Python scripts, scientific experiments,
  numerical simulations, or data-processing pipelines from a `scientific-review`
  session activity. Static inspection, text/markdown editing, and repository
  inspection are fine.
- `execute_experiment` (ledger tool) may be used only for non-scientific
  verification of this framework's own files — never for anything tied to an
  `E-xxx` spec. See `config.json` → `execute_experiment_policy`.
- Never fabricate an experimental result. If a result hasn't been run yet,
  the record says `PENDING_HUMAN_EXECUTION`, not a guess.
- Reviewers (§4) never modify production/scientific code. They write
  findings/objections. Only the Primary Agent (Claude Code), through the
  normal controlled workflow, implements a fix — and only after review →
  investigation → evidence → decision, never review → automatic fix.

## 3. Two modes

**Research Mode** (default for exploration): brainstorming, speculation,
generating hypotheses, unconventional approaches — all fine, and undocumented
scratch reasoning does not need a `C-xxx`/`H-xxx` record. The one rule:
nothing produced here is recorded as an established fact.

**Validation Mode**: entered when a consequential scientific claim or
methodological change is on the table (i.e. it would classify as R2 or above,
§6). From this point: the claim is named (`C-xxx`), assumptions are written
down, the right reviewers are engaged, objections are recorded, required
experiments are specified, and any empirical conclusion needs empirical
evidence — not more discussion.

Validation Mode applies to *the specific claim/change*, not to the whole
session — other exploratory work in the same session can stay in Research
Mode.

## 4. Reviewer roles

All four are logically independent (§5). None of them edit production code.

### 4.1 Primary Agent — Claude Code
Understands the task, inspects the project, develops hypotheses, proposes
methods, implements approved changes, analyzes reviewer feedback, designs
experiments, maintains project state. Primary worker, not the scientific
authority — its own conclusions about its own code are exactly what the other
three roles exist to check.

### 4.2 Code Auditor
*Does the implementation actually implement the stated specification?*
Algorithm implementation, indexing, dimensions, units, normalization,
numerical stability, edge cases, test validity, implementation/spec
mismatches, unintended behavioral changes.

### 4.3 Mathematical Auditor
*Is the mathematical formulation correct, independent of the implementation?*
Equations, derivations, assumptions, objective functions, estimators,
optimization formulation, identifiability, bias/variance reasoning, limiting
cases, degeneracies. Should independently re-derive important results rather
than checking the author's derivation for plausibility.

### 4.4 Scientific / Signal-Processing Auditor
*Even if internally consistent, is the method scientifically appropriate?*
Where relevant: spectral leakage, finite-window effects, stationarity,
sidebands, harmonics, phase behavior, amplitude distortion, neighboring-
frequency preservation, reference assumptions, sampling, filtering,
STFT/WOLA behavior, realistic EEG conditions, evaluation methodology. Must
distinguish established facts from hypotheses that need an experiment.

### 4.5 Red-Team Auditor
*Assume the important claim is wrong — what's the strongest way to show that?*
Counterexamples, pathological cases, hidden assumptions, confounding,
circular reasoning, benchmark leakage, inappropriate baselines, metric
problems, favorable parameter choices, failure conditions, unsupported
superiority/novelty claims, "improvement" that's actually signal destruction.
Must not demand every hypothetical be tested — each objection needs
relevance, likely impact, testability, and a suggested resolution (§9, §11).

## 5. Reviewer independence — what's actually enforced (revised after Phase F investigation)

Initial pass: each reviewer gets the *same underlying evidence* (code diff,
derivation, relevant data/description) but not other reviewers' conclusions.
Do not let one reviewer anchor another. A synthesis stage (§13) may compare
reviews only after all independent passes are recorded.

### 5.0 Bundle-identity discipline (added 2026-08-20, after Pilot 1)

"Same underlying evidence" means **byte-identical**, not "the same facts
retold." Pilot 1 violated this without anyone noticing until a dedicated
postmortem looked for it: the orchestrator hand-authored four different
renderings of one reconstruction — role-tailored (the Math Auditor got a
formula the Code Auditor didn't; Codex got a full rewrite) and, worse,
each one carried an orchestrator-written interpretive note naming the
pilot's two headline findings before any reviewer had looked at anything.
The reviewers' agreement on those two findings was real agreement on
*severity*, not independent *discovery* — and the original pilot report
did not disclose this clearly enough to tell the difference.

Two hard rules going forward:

1. **One canonical bundle file, referenced or pasted verbatim into every
   reviewer prompt — never re-authored per role.** If a role genuinely
   needs less detail than another (e.g. Code Auditor doesn't need a
   derivation the Math Auditor does), that is a decision to make
   explicitly and disclose in `PACKAGE.md`'s dispatch record ("role X
   received the full bundle minus section Y, because Z") — not something
   to do silently by writing a shorter prompt.
2. **The bundle presents facts; it does not flag which facts matter.**
   Neutral statements of what's in the record ("event E4 has no
   `EXPERIMENT_EXECUTED` counterpart") are fine and necessary — omitting
   them would be worse. Interpretive framing ("notice that...", "this
   suggests...", a named "STRUCTURAL NOTE" paragraph pointing at the
   answer) is not. If the orchestrator notices a pattern while building
   the bundle, that observation goes to the human before dispatch (as
   happened, correctly, in Pilot 1) — it does not get written into the
   reviewer-facing document.

Category: **ADVISORY** — nothing mechanically stops an orchestrator from
violating this again; it depends on the practice being followed, the same
as everything else in this framework not covered by the ledger gate (§22).

### 5.1 External context policy (added 2026-08-20, after Pilot 2)

Canonical evidence (the investigation's own record) and **permitted
external context** are two distinct categories, never merged:

- **External context** is general, public, non-case-specific reference
  material — language/library documentation, published standards,
  textbook results. It is legitimate, and specifically the kind of
  citable source `config.json`'s `static_fact_policy` (§9) already
  requires for a `STATIC_FACT` classification — the policy previously had
  no stated legitimate source for one.
- It is **uniformly permitted to every reviewer role** — not incidental
  to whichever one happens to reach for it, which is what actually
  happened in Pilot 2 (the Code Auditor cited MathWorks documentation;
  no other reviewer was offered the same option).
- It must be **explicitly cited** (source name/URL) wherever used, and
  **never silently folded into what reads as canonical evidence**.
- **Case-specific or project-specific external material is not
  permitted** under this policy (a GitHub issue about this exact bug, an
  internal wiki page) — that would recreate the evidence-selection
  problem bundle-identity discipline (§5.0) exists to prevent, just
  through a side channel instead of a re-authored bundle.

Category: **ADVISORY** — reviewer prompts state the permission and the
citation requirement; nothing mechanically prevents a reviewer from
looking up case-specific material or citing it improperly. See
`config.json` → `external_context_policy`.

### 5.2 Red-Team vendor options — Codex vs. Antigravity CLI (`agy`) (added 2026-08-22)

Codex was, until this date, the only genuinely-different-vendor option for
Red Team (§4.5, category D below). Quota limits on Codex prompted checking
whether Google's **Antigravity CLI** (`agy` — the successor to Gemini CLI,
which was retired 2026-06-18) is a viable second vendor. Investigated the
same way §5's B_tool_level claim was — dispatched and observed, not read
from vendor docs and trusted.

**Structural difference from Codex:** `agy` has no MCP-server mode (`agy
mcp` only lets it *consume* other MCP servers, not expose itself as one).
It is invoked as a CLI subprocess via `Bash`/`PowerShell`
(`agy -p "<prompt>" --model gemini-3.5-flash --mode plan`), not as a native
`mcp__agy__*` tool call the way `codex` is. This is a real difference in
dispatch shape, not just a naming detail — document which shape was used
in any `PACKAGE.md` dispatch record that includes `agy`.

**Model pinning is mandatory.** The default model (`gemini-3.1-pro`) had a
literal `limit: 0` free-tier quota on the tested key — not "exhausted,"
zero allocated. `gemini-3.5-flash` is the model with real usable free
quota. Any dispatch must pin `--model gemini-3.5-flash` (or whatever is
confirmed to have quota at dispatch time) explicitly.

**Write-block claim — initially false, then verified true under a specific
configuration, found by live testing, not by trusting the docs:**
- `--mode plan` is documented as "read-only mode." A live dispatch proved
  this false on its own: combined with `--dangerously-skip-permissions`
  (needed at the time to get any output at all — see next point), a
  requested file write **succeeded**, confirmed by independently re-reading
  the target file afterward. Do not describe `--mode plan` alone as a
  write-block guarantee.
- Root cause of needing `--dangerously-skip-permissions` in the first
  place: `agy`'s `permissions.allow` list does **not** support wildcard/
  glob paths (`agent-study\*`) — such a rule silently matches nothing,
  confirmed from `agy`'s own debug log showing the exact permission string
  requested vs. the rule that failed to match it. This had been
  misdiagnosed as general flakiness before the log was actually read.
- **Verified-safe configuration:** `permissions.allow` containing only
  **exact literal per-file paths** (never a wildcard), no `write_file`
  grant, and `--dangerously-skip-permissions` never passed. Under this
  exact configuration, a live dispatch: (a) succeeded at reading the
  target file, (b) had a requested write denied — whichever write-capable
  tool the model reached for (`write_file` or a shell `command` were both
  observed, both denied the same way) — with the target file independently
  confirmed unchanged, and (c) still produced a full, real review on a
  separate run under the identical configuration. Category for the
  write-block guarantee itself: **PARTIAL, empirically confirmed 2026-08-22
  — conditional on exact-literal-path configuration**, matching the
  qualified phrasing already used for B_tool_level above. Never describe
  `agy` as read-only without stating this exact-path requirement.

**Reliability defect — found, not resolved:** the identical prompt, under
the identical verified-safe configuration, produced a complete review on
one run and a flat safety-filter refusal ("Sorry, I cannot fulfill your
request to red-team...") on the next, with no configuration difference
between the two. Roughly coin-flip in the small samples run so far. This
is independent of the write-block finding above (verified/fixed) and of
the quota finding (verified/fixed) — it is a separate, unresolved
nondeterminism in the model's own safety filter.

**On content quality when it does answer:** one fixture (a seeded-bug
Python file with a deliberate false-positive trap and a hidden answer
key, not a real project claim), one trial each — `agy`/`gemini-3.5-flash`
found all 6 seeded bugs including one Codex missed (an off-by-one loop
bound); Codex found 4–5 of 6 but surfaced legitimate findings outside the
seeded set that `agy` didn't. This is a genuinely promising data point,
**not a benchmark** — n=1, single prompt, single fixture. By this
framework's own evidentiary bar (an `EMPIRICAL_HYPOTHESIS` needs more
than one trial before being treated as more than provisional — §9), any
comparative reading of this ("`agy` performs comparably to Codex") is
`PLAUSIBLE` at most, explicitly not `SUPPORTED` — cite this as "a
promising result exists," not as a settled comparison between the two.
The `policy` field/paragraph below is unaffected and needs no such
caveat — it's a procedural hedge (retry once on refusal), not a
comparative claim about which vendor performs better.

**Policy going forward:** Codex remains the default Red-Team vendor —
deterministic, MCP-native, no known refusal nondeterminism. `agy` may be
used as a **documented secondary/fallback** Red-Team route, only under the
exact-literal-path configuration above, and **a refusal must never be
recorded as a clean "no findings" pass** — retry once before treating the
outcome as real; if it refuses twice, record that fact rather than
silently falling back to Codex without noting `agy` was attempted and
declined to answer. See `config.json` → `red_team_vendor_options` for the
structured version of this entry.

There are four distinct kinds of "independence" this section used to blur
together. Phase F investigated each one concretely against this environment
(not assumed) — full detail in `config.json` →
`reviewer_independence.isolation_categories_investigated_2026-08-19`. Using
the terminology from §22:

- **A. Prompt-level isolation** ("don't modify code," stated in the prompt) —
  **ADVISORY**. Always true, never sufficient alone.
- **B. Tool-level isolation** (reviewer technically cannot modify code) —
  **PARTIAL, and empirically confirmed 2026-08-19** (not merely inferred
  from reading agent-type definitions — see `scientific-debug-ledger`
  investigation `review-layer-enforcement-claims-2026-08-19`). A real
  `Explore`-type subagent was dispatched and instructed to attempt writes;
  its actual tool list and actual attempted writes were observed and
  independently re-verified by re-reading the target files afterward, not
  taken on the subagent's word alone:
  - The subagent reported no `Write`/`Edit` tool existed in its tool set at
    all (H1) — real, first-hand evidence, but the ledger's experiment model
    only captures OS-subprocess results, not Agent-dispatch transcripts, so
    this specific finding could not be promoted past `UNTESTED` in the
    ledger's own formal state despite being true — a named ledger scope
    limitation, not a weaker finding.
  - `Bash` **is** available to it and a Bash-issued write to an
    *unprotected* scratch file **succeeded** (H2) — formally `SUPPORTED` in
    the ledger, evidence event `d13da492-31b2-4261-8266-ea20f97204c6`.
  - Do not describe `Explore` as "read-only" without this caveat — it is
    read-only by convention/naming, not by enforced tool restriction, for
    the write channels that matter here.
  **Strongest available mechanism — empirically confirmed, not just read
  from source (H3, formally `SUPPORTED`, evidence event
  `2d8d95e9-3e6d-43e2-ac89-e91a6aee3fc9`):** register the files under review
  as `protected_paths` on an open `scientific-debug-ledger` investigation
  *before* dispatching reviewers. The same dispatched subagent's Bash-issued
  write to a file registered this way (with the investigation's gate
  preconditions deliberately left unmet) was denied, verbatim, by the real
  `hook_gate.py` — `[scientific-debug gate] blocked write to '...': no
  hypothesis registered yet` — and the target file was independently
  confirmed unchanged afterward. This reuses existing infrastructure; no new
  hook was added. It is conditional on the Primary Agent actually doing this
  before dispatch — that step itself remains advisory.
- **C. Process/context isolation** (reviewer doesn't see other reviewers'
  conclusions) — **ENFORCED** at the mechanism level: a fresh `Agent` call
  starts with no shared conversation. **ADVISORY** at the orchestrator level:
  nothing stops the dispatching agent from pasting one reviewer's findings
  into another's prompt by hand — don't.
- **D. Model-level independence** (different underlying model) — **PARTIALLY
  AVAILABLE**. The `Agent` tool's `model` parameter can vary the Claude
  generation per role (real, same-vendor diversity). A genuinely different
  vendor is available if `codex` is configured for the project (primary,
  MCP-native, no known reliability defect) or, as a documented secondary/
  fallback under specific conditions, `agy`/Antigravity CLI — see §5.2 for
  what's actually verified about each.

**Recommended dispatch, given the above:** `Explore` or `Plan` agent type +
an open ledger investigation with `protected_paths` covering the reviewed
files + vary `model` and/or use `codex` (primary) / `agy` under §5.2's
exact-configuration requirement (secondary) for at least the Red Team. This
combination is the strongest practical mechanism available in this
environment — still not an absolute guarantee (see `SELF_REVIEW.md` and
`SELF_REVIEW_PHASE_F.md` §13).

## 6. Risk gates (R0–R4)

See `config.json` → `risk_levels` for the canonical, editable table. Summary:

| Level | What | Review required |
|---|---|---|
| R0 Routine | formatting, comments, docs, harmless refactor | none |
| R1 Implementation | indexing, data handling, ordinary bug fixes | Code Auditor, if scientifically consequential |
| R2 Methodological | new estimator, changed filtering/optimization/STFT-WOLA/artifact-removal | Math and/or Scientific Auditor |
| R3 Scientific Claim | "reduces bias", "preserves signal", "outperforms X", "more robust" | full review incl. red team + empirical evidence |
| R4 Major Conclusion | superiority/novelty/publication-level claims | full review + evidence package + recorded human decision |

Classification is not rigid — document *why* a level was chosen in the review
package's `PACKAGE.md` (§8). When in doubt between two adjacent levels, pick
the higher one and say why in one sentence; that sentence is the audit trail,
not a bureaucratic gate.

### 6.1 Risk escalation via claim dependencies (two-axis note, Phase F)

R0–R4 above is a single axis: how much the implementation/method itself is
changing (axis A). It says nothing about a second, separate axis: how much a
change could affect a scientific conclusion that already relies on it
(axis B). A one-line WOLA-normalization edit is axis-A-small — it looks like
ordinary R1/R2 work — but if an `ESTABLISHED` or `SUPPORTED` claim already
cites that exact normalization as part of its supporting evidence, the same
edit is axis-B-large: it could silently invalidate a conclusion someone is
already relying on, while being locally classified as routine.

**Phase F analysis:** a full second 0–4 scale (a 5×5 risk matrix) would be
disproportionate bureaucracy for the specific gap the task named. The
minimum fix is a single dependency-triggered escalation rule, reusing the
claim registry that already exists rather than adding new machinery:

> Before finalizing a risk level for any R1+ change, check whether the
> changed file/method appears in any claim's **Depends on** field
> (§10, `CLAIM_REGISTRY_TEMPLATE.md`). If it does, treat the change as **at
> least R3** for gating purposes — full review + human decision — regardless
> of how small it looks by axis A, and mark the dependent claim(s) `STALE`
> (§10.1) pending re-validation. A dependency match is not itself evidence
> the claim is wrong — do not set `REFUTED` from this alone.

This rule only fires when a change touches a file a claim already depends
on. It never fires for Research Mode exploration that hasn't touched such a
file — brainstorming and novel formulations remain unaffected (§3, §10 of
this section's parent list, and see the check performed in
`SELF_REVIEW_PHASE_F.md` §10).

Category: **ADVISORY** — this is a procedural check the Primary Agent
performs, not something a hook enforces. Enforcement status glossary: §22.

## 7. Reviewers do not fix the code

A reviewer may write: "The synthesis-window normalization appears
inconsistent with the stated overlap-add reconstruction." It must not edit
the code. It produces a finding (`FINDING.md`, §8) or objection
(`OBJECTION.md`, §9) with: finding ID, affected claim, reviewer role, concern,
reasoning, evidence currently available, classification, severity, required
experiment/analysis, status. The Primary Agent investigates and implements
any resulting fix afterward, through the normal workflow (including, for
R2+, a `scientific-debug` investigation over the affected files).

Sequence is always: **review → investigation → evidence → decision →
implementation**, never review → automatic fix.

## 8. Review packages

For any change/claim classified R1(conditional)+ through R4, create
`projects/<project_key>/REVIEWS/<review_id>/`:

- `PACKAGE.md` — what's under review, risk level + rationale, which reviewer
  roles are engaged and why, the underlying evidence bundle every reviewer
  will see (diff, derivation excerpt, relevant claim/hypothesis IDs).
- One file per engaged reviewer role (`code_auditor.md`, `math_auditor.md`,
  `scientific_auditor.md`, `red_team.md`) — the reviewer's filled-in findings/
  objections, produced independently (§5).
- `SYNTHESIS.md` — written only after all engaged reviews exist. Compares
  them, notes agreement/disagreement, and is explicit that agreement is not
  proof (see the closing line of `SYNTHESIS_TEMPLATE.md`).

Templates: `templates/REVIEW_PACKAGE_TEMPLATE.md`,
`templates/CANONICAL_EVIDENCE_TEMPLATE.md`,
`templates/DISPOSITION_MANIFEST_TEMPLATE.md`,
`templates/REVIEWER_PROMPT_CODE_AUDITOR.md` (and `_MATH_AUDITOR`,
`_SCIENTIFIC_AUDITOR`, `_RED_TEAM`), `templates/FINDING_TEMPLATE.md`,
`templates/SYNTHESIS_TEMPLATE.md`.

`review_id` format: `<risk-level>-<short-slug>-<YYYY-MM-DD>`, e.g.
`R2-wola-normalization-2026-08-19`.

### 8.1 Reconstruction requirements (added 2026-08-20, after Pilot 2)

Bundle-identity discipline (§5.0) governs what happens once the canonical
evidence bundle exists. These three rules govern how it gets built in the
first place — the earlier, previously-unaddressed stage both pilots'
postmortems converged on as the harder remaining problem.

1. **Disposition manifest** (`DISPOSITION_MANIFEST.md`, `config.json` →
   `disposition_manifest_policy`). Every hypothesis/experiment ID the
   source investigation actually has (per `get_investigation_state`) gets
   exactly one row: `INCLUDED` (appears in the bundle) or `EXCLUDED`
   (doesn't, with a stated reason). This is *coverage*, not *inclusion* —
   a tightly-scoped bundle that excludes irrelevant material is fine and
   expected; a silent omission with no disposition at all is not. The
   check itself ("does every source ID have exactly one disposition, does
   every EXCLUDED row have a non-empty reason") is deterministic — a
   plain diff/text-search, no LLM judgment needed — but running it before
   dispatch remains a procedural discipline: there is no hook on `Agent`/
   `codex` calls, and none is being added. Category:
   **MECHANICALLY-VERIFIABLE, not ENFORCED** (§22) — precise, not a
   downgrade in substance from what a coverage check buys, just an
   honest label for what actually prevents a skipped check versus what
   makes a skipped check *detectable after the fact*.
2. **Scope declaration.** The bundle states near its top which
   file(s)/line-ranges and which ledger objects were in scope, with a
   pointer to the disposition manifest for what wasn't. A reviewer must
   never have to guess whether an excerpt is the whole record — Pilot 2's
   Code Auditor correctly treated its 40-line excerpt as bounded only
   because the bundle said so.
3. **Raw output retrieval.** For every `INCLUDED` experiment with
   `executed: true`, the reconstruction locates that experiment's
   `RESULT_RECORDED` event in the investigation's raw JSONL
   (`scientific-debug/data/<investigation_id>.jsonl`, read via `Read`/
   `Grep` — a static file read, never execution) and includes its
   captured stdout/stderr, truncated per the ledger's own existing
   8000/4000-char convention if needed. If no `RESULT_RECORDED` event
   exists, the bundle says so explicitly rather than omitting the field.
   This closes Pilot 2's strongest finding: `get_investigation_state`'s
   derived summary never surfaces captured output, only `exit_code` —
   true for every investigation, confirmed to also affect Pilot 1's
   bundle retroactively.

Templates: `templates/DISPOSITION_MANIFEST_TEMPLATE.md`,
`templates/CANONICAL_EVIDENCE_TEMPLATE.md`.

## 9. Objection classification and format

Every substantive objection (from any reviewer, most often Red Team) is
classified as exactly one of:

`STATIC_FACT` · `MATHEMATICAL_DERIVATION` · `LOGICAL_ARGUMENT` ·
`EMPIRICAL_HYPOTHESIS` · `SPECULATIVE_CONCERN` · `NON_TESTABLE_CONCERN`

and recorded with: objection ID (`O-xxx`), target claim, objection, why it
could matter, likelihood/relevance assessment, potential impact,
classification, what evidence would support it, what evidence would falsify
it, proposed experiment if testable, current status. The reviewer must be
able to answer: *what observation would convince you this objection is
wrong?* If nothing feasible does, classify it `NON_TESTABLE_CONCERN` /
status `NON-TESTABLE` rather than leaving it open forever. Template:
`templates/OBJECTION_TEMPLATE.md`.

**`STATIC_FACT` requires a citable source** (textbook, paper, spec, standard,
or an inline static/logical proof) — `config.json` → `static_fact_policy`.
An assertion with no source does not qualify for this classification;
reclassify as `LOGICAL_ARGUMENT` (reasoning shown) or `SPECULATIVE_CONCERN`
(not). This closes the cheapest version of "reviewer hallucination presented
as fact" — it does not verify the cited source is real (still **ADVISORY**),
but it forecloses the unsourced-assertion case by construction of the
template.

## 10. Claim registry and hypotheses

`projects/<project_key>/CLAIMS.md` holds consequential scientific claims,
each `C-xxx`: claim, context, assumptions, **Depends on** (files/methods this
claim's validity rests on — see §10.1), supporting evidence, relevant
experiments, objections, limitations, current status (§ statuses in
`config.json`). **Reviewer consensus never sets a claim to `ESTABLISHED`** —
only a recorded human decision citing empirical evidence does (§14).

**Supporting evidence must be a citation, not free text**
(`config.json` → `evidence_field_policy`): a ledger citation
(`investigation_id` + `event_id`) or an experiment citation (`E-xxx` +
artifact pointer). Prose may accompany the citation but cannot substitute
for it — this closes the "evidence laundering" failure mode where a
speculative or unexecuted claim gets worded to read like evidence.

`projects/<project_key>/HYPOTHESES.md` holds broader scientific/methodological
hypotheses, each `H-xxx`: statement, motivation, predicted observation,
competing hypotheses, experiment needed, current status. See §0 for how these
relate to the ledger's per-investigation hypotheses.

ID allocation (manual, deterministic, no script): to mint the next ID of a
given prefix in a project, list existing IDs of that prefix in the relevant
file and use `max + 1`, zero-padded to 3 digits. IDs are per-project and
per-prefix, and are never reused, including for refuted/closed/superseded
records.

**Lock file around the allocation sequence (added 2026-08-29).** The
read-max+1-write sequence above is a real race between two sessions
touching the same `project_key` at once — confirmed as a live risk in
this environment (a near-miss with two concurrent sessions on the same
project actually happened during this framework's own development,
independent of this specific ID mechanism). Given the single-user,
multi-device scope this framework assumes (README.md), that race is
between a person's own sessions/devices, not between different people —
but it's still real and worth closing cheaply:

1. Before listing existing IDs to compute `max + 1`, check for
   `projects/<project_key>/.ids.lock`.
2. If it exists, **do not proceed and do not silently retry-loop** —
   surface a clear conflict to the user: *"Another session may be
   allocating an ID in this project (lock file present). If you know no
   other session is active, this is likely a stale lock left by an
   interrupted session — confirm with the user before removing it,
   rather than removing it automatically."*
3. If absent, create it (its content doesn't matter — presence is the
   signal; a timestamp inside helps a human judge staleness later), do
   the read/allocate/write sequence, then remove it.

**What this is, stated honestly, same standard as everywhere else in
this document:** a real mutex for any session that follows this
protocol — it actually prevents the race, stronger than a passive
warning. It is **not** a technical block against a session that skips
the lock-check entirely; nothing enforces that a session looks for the
lock before writing. Category: closer to the ledger's own real
concurrency handling in spirit, but unlike the ledger's `PreToolUse`
gate, nothing hooks this — it depends on the protocol being followed,
same as almost everything else not covered by that gate (§22).

*Not built this pass, flagged as an optional future refinement:*
routing all ID allocation through one small helper (a script, or a
single documented procedure) rather than three manual steps a session
has to remember correctly every time would reduce the chance of the
lock step itself being forgotten — deliberately left out here rather
than expanding this pass's scope.

### 10.1 Review freshness and staleness (Phase F)

A review is a statement about a claim's dependencies *as they were at review
time*. If a dependency changes afterward, the review may no longer apply —
this is distinct from the claim being wrong.

**Mechanism** (`config.json` → `review_freshness`): every claim's **Depends
on** entry and every review package's `PACKAGE.md` record a **fingerprint**
for each file/method they depend on — a SHA-256 hash computed with
`PowerShell Get-FileHash -Algorithm SHA256` (never MATLAB/Python) at the
time the claim or review was written. To check freshness, re-hash the same
file and compare. A mismatch means the dependency changed since the
fingerprint was recorded.

This was tested end-to-end against a synthetic fixture in Phase F (see
`PHASE_F_TESTS.md`, Test I): an unchanged file correctly reproduces the same
hash (no false staleness), a changed file correctly produces a different
hash. It's a content-identity check, not a semantic diff — it will also flag
comment-only or formatting-only edits. That's accepted deliberately:
over-flagging is safe, under-flagging is the actual danger.

**On mismatch:** set the claim's/review's status to `STALE` (§ in
`config.json` → `claim_status_notes`). This does not erase or downgrade the
claim's substantive status — a `STALE` `ESTABLISHED` claim is still
`ESTABLISHED`, flagged as needing re-validation, not reset to `UNKNOWN`.
Re-validation (a fresh, possibly abbreviated, review pass confirming the
dependency's current state still supports the claim) clears the flag.

**When this is checked:** when resuming a project session (§17) and
whenever an R1+ change is about to touch a fingerprinted file (§6.1). Not
checked automatically — no hook computes or compares fingerprints. Category:
**ADVISORY** (the check itself is a documented procedure); the fingerprint
comparison, when actually performed, is a deterministic fact, not an opinion
— but nothing forces the comparison to be performed.

## 11. Objection stopping rule

An objection reaches exactly one of: `FALSIFIED`, `CONFIRMED`, `BOUNDED`,
`NON-TESTABLE`, `OPEN` (definitions in `config.json` →
`objection_status_notes`). Do not require every conceivable hypothetical to
be eliminated before proceeding — `NON-TESTABLE` is a legitimate, permanent
resting state that gets preserved as a documented limitation, not treated as
a blocking defect.

## 12. Experiment specifications

When a reviewer or the Primary Agent identifies an empirical question, write
`projects/<project_key>/EXPERIMENTS/E-xxx.md` **before** anything is executed:
question, hypothesis, competing prediction(s), input/data requirements, exact
procedure, variables, metrics, expected outputs, pass/fail or discriminating
criteria, potential confounders, required artifacts, reviewer/claim IDs.
Template: `templates/EXPERIMENT_TEMPLATE.md`.

Execution:
- If the experiment is a real MATLAB/Python/numerical run: the human runs it.
  The record stays `PENDING_HUMAN_EXECUTION` until the human pastes back the
  result (console output, output file, or a description of what to look at),
  at which point the record is updated with that evidence and a pointer to
  the artifact — not a Claude-authored paraphrase presented as the result.
- If the experiment is a non-scientific check of this framework's own state
  (e.g. "does this markdown table parse", "does this JSON validate"): may use
  `execute_experiment` per the policy in `config.json`.

## 13. Synthesis

Only after all engaged reviewers' independent passes are recorded, write
`SYNTHESIS.md` (§8) comparing them. Explicitly note points of agreement,
disagreement, and — critically — that agreement across reviewers is not by
itself evidence. Synthesis produces *recommendations*, not decisions (§14).

## 14. Human decision layer

For R3/R4, `projects/<project_key>/DECISIONS.md` records the actual decision
separately from any reviewer's recommendation:

- `D-xxx`, related claim(s)/review package, risk level, one-line summary of
  each engaged reviewer's recommendation (proceed / investigate / reject /
  accept with limitation), the empirical evidence cited (ledger event or
  human-run artifact), **the decision**, **who made it**, date, rationale.

Reviewers recommend; they do not decide. A claim cannot move to `ESTABLISHED`
without a `D-xxx` entry. If the human hasn't weighed in yet, the claim stays
at whatever status the evidence alone supports (`PLAUSIBLE`/`SUPPORTED`/
`UNRESOLVED`), and the review package notes "awaiting human decision."

## 15. Legacy / pre-protocol projects

When a Claude Code session starts in a scientific project with no
`projects/<project_key>/` entry yet:

1. Do not assume historical conclusions were validated.
2. Do not try to reconstruct every prior conversation.
3. Offer (don't silently start) a **retrospective audit**: read the project's
   own docs/READMEs, its `scientific-debug` ledger history if any
   (`list_investigations`, `get_investigation_state` — read-only), and its
   code/comments for stated methods and conclusions.
4. Extract into `RETROSPECTIVE.md` (template: `templates/
   RETROSPECTIVE_TEMPLATE.md`): major methods, major scientific claims,
   assumptions, important decisions, existing evidence, known limitations,
   unresolved questions.
5. Identify consequential claims lacking clear evidence or independent
   challenge; add them to `CLAIMS.md` as candidates, status `UNKNOWN`, tagged
   `historical: true`.
6. Never rewrite scientific history. Every claim record distinguishes
   `historical claim` (pre-existing, found during audit), `newly reviewed
   claim` (a historical claim that has since gone through §8), and `newly
   generated evidence` (produced after this framework was applied).

## 16. New investigations

0. Run the enforcement-floor check (§0.1) before anything else below. If
   it fails, surface the `ADVISORY-ONLY` banner now — do not wait until a
   review package is created, since Research Mode work in this project
   may never reach one.
1. Initialize `projects/<project_key>/` if it doesn't exist (STATE.md,
   CLAIMS.md, HYPOTHESES.md, DECISIONS.md, REVIEWS/, EXPERIMENTS/ — copy from
   `templates/`).
2. Record the research question in STATE.md.
3. Start in Research Mode.
4. Record important hypotheses (`H-xxx`) as they firm up — not every
   passing thought.
5. Transition to Validation Mode (§3) and invoke the right risk gate (§6)
   the moment a consequential claim or methodological change is on the table.

Do not force full red-teaming of ordinary exploratory brainstorming — that's
exactly the failure mode this system exists to avoid (see also
`SELF_REVIEW.md` §9).

### 16.1 Non-scientific projects — do not initialize (Phase F)

This skill's description gates on relevance ("a scientific/technical project
has a consequential claim..."), but that's a soft trigger, not a hard one —
an eager session could still reach for this framework in an ordinary
software project just because a variable is named `estimator` or a comment
says "optimize." Explicit rule: **do not create `projects/<project_key>/`
and do not add a `PROJECTS.md` row unless one of these is true**:

- a consequential scientific/methodological claim or change is actually on
  the table for *this* project (R1-conditional and above, §6), or
- the user explicitly asks to set up scientific review for this project.

Reading `PROTOCOL.md`/`SKILL.md`, or this skill being invoked/considered for
a turn, does **not** by itself warrant initialization. A project with no
scientific claims ever gets no entry, ever — that's the correct, permanent
outcome for it, not a gap to fill in. `D:\System Scripts` (the project this
framework was originally built from) is the running example: it has no
`projects/D--System-Scripts/` entry and should not get one unless someone
starts making a scientific claim about it, which is not expected.

## 17. Continuing investigations

At the start of a session working in a project that already has a
`projects/<project_key>/` directory:

0. Run the enforcement-floor check (§0.1) before anything else below —
   same reasoning as §16 step 0: this session may do nothing but
   Research Mode work and never create a review package, and the banner
   still needs to fire if so.
1. Read this PROTOCOL.md (or trust the cached summary in `SKILL.md`).
2. Read `STATE.md` — current mode, current stage, active ledger
   `investigation_id`s.
3. Read `CLAIMS.md`, `HYPOTHESES.md` for open items.
4. Scan `REVIEWS/*/` for objections/findings still `OPEN`.
5. Scan `EXPERIMENTS/*` for anything `PENDING_HUMAN_EXECUTION`.
6. Resume from that state. Do not infer scientific truth solely from
   conversation history — the files in `projects/<project_key>/` are the
   authoritative project-level record, conversation history is not.

## 18. `project_key`

`project_key` = the project's absolute root path with every `\`, `/`, `:`,
and space replaced by `-`. This is the same slugification Claude Code's own
`~/.claude/projects/<slug>/` directories already use, so the two trees line
up visually (e.g. a project at `D:\Foo Bar\baz` becomes `D--Foo-Bar-baz` in
both places). No script computes this — it's a one-line deterministic
transform, and PROJECTS.md (§19) records the mapping explicitly so it never
needs to be recomputed from memory.

## 19. `PROJECTS.md`

A flat index at `D:\System Scripts\Multi-Agent Scientific Review Layer\PROJECTS.md`: one row per known
project — project root path, `project_key`, whether a retrospective audit has
been done, last-touched date, current mode. Update it whenever a
`projects/<project_key>/` directory is created or its STATE.md changes mode.
This is what makes "does this project already have review state" a lookup
instead of a filesystem guess.

## 20. File layout

```
D:\System Scripts\Multi-Agent Scientific Review Layer\
├── PROTOCOL.md              (this file)
├── SELF_REVIEW.md           (Phase E adversarial self-review)
├── SELF_REVIEW_PHASE_F.md   (Phase F 15-point adversarial self-review)
├── PHASE_F_TESTS.md         (Phase F static/synthetic protocol-level test results)
├── VIOLATIONS_LOG.md        (framework-infrastructure-level constraint violations, not tied to one project)
├── config.json              (risk levels, statuses, classifications, escalation/freshness/violation policy)
├── PROJECTS.md              (project index)
├── templates/                (canonical record templates, copied per project)
└── projects/
    └── <project_key>/
        ├── STATE.md
        ├── CLAIMS.md
        ├── HYPOTHESES.md
        ├── DECISIONS.md
        ├── VIOLATIONS.md          (only if a constraint violation occurred while working in this project)
        ├── RETROSPECTIVE.md      (only if a legacy audit was done)
        ├── REVIEWS/<review_id>/
        └── EXPERIMENTS/E-xxx.md
```

## 21. Constraint violation handling (Phase F)

The primary agent can violate this framework's own operating constraints
(most concretely: running MATLAB/Python despite the prohibition). What
happens next depends on classification — see `config.json` →
`violation_classes` for the canonical, editable definitions:

1. **Harmless infrastructure mistake** — no scientific code/data/claim/
   hypothesis/evidence touched, no result produced or claimed (e.g. a
   trivial non-scientific `python3 -c` one-liner validating this
   framework's own JSON). → Record in `VIOLATIONS.md` (or the global
   `VIOLATIONS_LOG.md` if not tied to a project). No rollback. Continue.
2. **Potentially-contaminating scientific action** — a scientific file,
   claim, or hypothesis was read/touched/reasoned about outside the normal
   review workflow. → Record it. Identify every claim/hypothesis/review
   touched since. Downgrade those to `UNRESOLVED` until a human confirms no
   contamination. Unaffected work may continue.
3. **Prohibited experiment executed** — MATLAB/Python/any scientific or
   data-processing command actually ran. → Record as **CRITICAL**. Any
   output must not enter `CLAIMS.md`/`EXPERIMENTS.md` as evidence; if it
   already did, revert that record to its pre-execution status. Surface to
   the user in the same turn — do not silently continue Validation Mode
   work until acknowledged (mirrors the ledger's `acknowledge_escalation`:
   a logged, visible checkpoint, not a silent one).
4. **Fabricated/claimed evidence** — a result recorded as real without
   actual execution. → Record as **CRITICAL**, the single worst failure
   mode this framework exists to prevent. Immediately revert the specific
   record to its pre-fabrication status (not "pending" — reverted
   outright). Mark the fabricated content retracted rather than deleted
   (append-only in spirit, matching the ledger's own ethos — correct
   forward, don't erase). Tell the user directly in the same turn.

Template: `templates/VIOLATIONS_TEMPLATE.md`. Worked example (not
hypothetical): the Phase D `python3` incident from this framework's own
build is logged in `VIOLATIONS_LOG.md` under class 1, since it read only
this framework's own `config.json` to validate JSON syntax — no scientific
file, claim, or evidence was involved. Category: **ADVISORY** — nothing
mechanically forces this classify-and-record step to happen; it's a
documented procedure the primary agent is expected to follow, same as every
other advisory rule in this framework.

## 22. Enforcement status glossary and table (Phase F)

Terminology (`config.json` → `enforcement_status_glossary`):

- **ENFORCED** — a technical mechanism prevents the forbidden action;
  verified to actually behave this way in this environment.
- **MECHANICALLY-VERIFIABLE** (added 2026-08-20) — the check itself is
  deterministic and needs no LLM judgment to evaluate (a plain diff/
  text-search suffices), but nothing technically prevents skipping the
  check itself. Not `ENFORCED` (the underlying omission isn't prevented)
  and not quite `ADVISORY` either (once run, the check has one correct
  answer, not a judgment call). Reserve this label for checks that
  genuinely reduce to deterministic comparison — don't stretch it to
  cover anything requiring interpretation.
- **ADVISORY** — the agent is instructed to behave correctly, but nothing
  technically prevents violation.
- **HUMAN-CONTROLLED** — the framework requires the human to decide; no
  agent can substitute for it.
- **UNIMPLEMENTED** — the capability does not currently exist here.

Every meaningful control this framework describes, honestly labeled:

| Control | Category | Why |
|---|---|---|
| `scientific-debug` enforcement-floor presence is checked (§0.1) | **MECHANICALLY-VERIFIABLE** | Deterministic grep, no judgment call. Fires at §16/§17 session-start steps and before dispatch — covers Research Mode work that never reaches a package. Does not fire for R0-only sessions where no project is ever initialized (§16.1) — no `SKILL.md` in this repo to anchor that case; not currently claimed to matter since R0 has no `ENFORCED` claims to protect anyway |
| Reviewers can't run `Edit`/`Write`/`NotebookEdit` | **ENFORCED** (partial — see §5) | `Explore`/`Plan` agent types genuinely lack these tools |
| Reviewers can't write via `Bash`/`PowerShell`/`mcp__filesystem__*` | **ADVISORY** by default; **ENFORCED** on the specific reviewed files *if* `protected_paths` was set on an open ledger investigation before dispatch | Depends on the Primary Agent actually doing the ledger step (§5) |
| Reviewer doesn't see other reviewers' conclusions | **ENFORCED** (mechanism) / **ADVISORY** (orchestrator discipline) | Fresh `Agent` calls share no context by construction; nothing stops manually pasting content across prompts |
| Reviewer uses a genuinely different model | **ADVISORY** / opportunistic | `model` param and `codex` availability vary by project |
| Experiment result is real, not fabricated | **ADVISORY** for human-run experiments; **ENFORCED** for anything routed through the ledger's `execute_experiment` (it mechanically cannot accept a claimed result) — but that tool is itself policy-restricted away from scientific use (§ `execute_experiment_policy`) | No hook watches this framework's own markdown files |
| `ESTABLISHED` requires a human decision | **ADVISORY** (nothing blocks hand-editing a status field) | Markdown records have no schema enforcement |
| Claim `Supporting evidence` is a real citation, not prose | **ADVISORY** (§10, `evidence_field_policy`) | Same reason |
| `STATIC_FACT` requires a citable source | **ADVISORY** (§9, `static_fact_policy`) | Same reason |
| Code changes to protected scientific files require a completed ledger investigation | **ENFORCED** | This is the pre-existing `scientific-debug` `PreToolUse` gate, unmodified, reused |
| Objection count is bounded | **UNIMPLEMENTED** | No cap exists, unlike the ledger's `pivot_threshold` — see `SELF_REVIEW_PHASE_F.md` §6 |
| Non-scientific projects don't get initialized | **ADVISORY** (§16.1) | Depends on the Primary Agent's judgment call about relevance |
| Stale reviews get flagged | **ADVISORY** (the fingerprint check itself, when performed, is deterministic — §10.1) | No hook computes fingerprints automatically |
| Every source hypothesis/experiment ID gets a disposition (§8.1) | **MECHANICALLY-VERIFIABLE** | A plain diff against `get_investigation_state`'s ID list settles it with no judgment call — but nothing forces the diff to be run before dispatch |
| Bundle includes captured experiment output, not just `exit_code` (§8.1) | **ADVISORY** | Reconstruction-step requirement; not checked automatically |
| External context is cited and uniformly available, never case-specific (§5.1) | **ADVISORY** | Reviewer-prompt instruction only |
| Reconstruction's excerpt/field selection reflects the investigation fairly | **UNIMPLEMENTED** | Named as the open architectural question in `ANALYSIS/RECONSTRUCTION_INDEPENDENCE_ANALYSIS.md` §1 — no Evidence/Package Auditor role exists yet, deliberately |

The pattern across this table: **almost everything this new layer adds is
advisory**, same as `scientific-debug`'s own `SKILL.md` half. The only row
that is unconditionally `ENFORCED` — the ledger's `PreToolUse` gate on
protected paths — was not built by this framework; it is reused,
unmodified, from `scientific-debug`. That remains the honest ceiling of
this MVP's *enforcement*, and it is deliberate (§20 of the task this
framework was built from: a manual, auditable MVP, not new hooks). What's
new as of 2026-08-20 is a second, distinct category —
`MECHANICALLY-VERIFIABLE` — for checks that need no LLM judgment even
though nothing forces them to run. That's a real, useful property short
of enforcement, and it's the direction future hardening should prefer
over adding more `ADVISORY` rules whenever a check is genuinely
reducible to deterministic comparison (§8.1's disposition manifest is
the first instance; more may exist).

## 23. Final principles

1. LLM consensus is not evidence.
2. Reviewers criticize; they do not silently fix.
3. Hypotheses are not facts.
4. Empirical claims require empirical evidence.
5. Disagreement should produce a discriminating experiment where possible.
6. Research Mode preserves creativity.
7. Validation Mode requires evidence.
8. Red-teaming is adversarial but bounded (§11).
9. Old work is not automatically validated merely because it is old (§15).
10. Human-run experiments remain the empirical authority (§12).
11. The existing `scientific-debug` ledger is not duplicated (§0).
12. This framework is itself open to red-teaming — see `SELF_REVIEW.md` and
    `SELF_REVIEW_PHASE_F.md`.
13. Every control this framework claims is labeled by its actual
    enforcement category (§22) — an advisory rule is never described as
    enforcement.
14. A consequential change to a reviewed dependency can invalidate the
    review that depended on the prior state (§10.1, §6.1).
