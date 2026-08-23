# Self-Review — Adversarial Read of This Framework

Static review only (no experiments run). Written against the framework as
implemented in `PROTOCOL.md`, `SKILL.md`, `config.json`, and `templates/` as
of 2026-08-19. Each item: the honest risk, then the mitigation actually
built in, then what's left unmitigated.

## 1. Could the system create false scientific confidence?

**Risk:** real. A project with a full `REVIEWS/` tree, populated `CLAIMS.md`,
and neat status labels *looks* rigorous regardless of whether the underlying
review was any good — the paperwork itself can read as evidence.

**Mitigation:** `ESTABLISHED` requires a `DECISIONS.md` entry citing
empirical evidence, never reviewer agreement alone (§10, §14, config.json
`claim_status_notes`); every status has a written definition; `SYNTHESIS.md`'s
template ends with an explicit line that agreement is not evidence.

**Unmitigated:** nothing stops a `SUPPORTED` or `PLAUSIBLE` label from being
over-read by someone skimming `CLAIMS.md` without reading the rationale
field. This is a documentation-discipline problem this MVP cannot close
mechanically (see §9 of this review).

## 2. Could reviewers become correlated or anchored?

**Risk:** real, and structural. Even with independent dispatch and no shared
conclusions (§5), four Claude-model reviewers share the same training-derived
blind spots. "Logical independence" (no cross-contamination of conclusions)
is not the same as "model diversity."

**Mitigation:** §5 explicitly recommends a genuinely different model/tool
(e.g. `codex`) for at least the Red Team; reviewer prompts are self-contained
so no conclusion leaks between roles even when same-model.

**Unmitigated:** if a project has no second model/tool configured, all four
roles will in practice be Claude subagents, and correlated blind spots are
a real, named residual risk — flag it in `PACKAGE.md`'s dispatch record
rather than pretending independence is stronger than it is.

## 3. Could the red team suppress novel ideas?

**Risk:** real. If every R2+ idea triggers a four-role gauntlet, researchers
may stop proposing new approaches informally, or dress up new work as R1 to
avoid review.

**Mitigation:** R0/routine and ordinary R1 fixes are explicitly exempt
(§6); Research Mode (§3) is explicitly protected — brainstorming does not
require a `C-xxx`/`H-xxx` record at all; the red team is bounded (§11, and
the reviewer prompt itself instructs prioritizing objections that would
change status over exhaustive lists).

**Unmitigated:** the boundary between "still Research Mode" and "now a
consequential claim" is a judgment call, made by the same agent motivated to
avoid overhead. No external check on that judgment exists in this MVP.

## 4. Could objections become endless?

**Risk:** real. Unlike the ledger's `pivot_threshold` (a hard, configured,
mechanically-enforced cap), nothing here numerically caps how many new
objections a red team can keep raising against the same claim.

**Mitigation:** the stopping-rule vocabulary (§11) gives every objection a
terminal state including `NON-TESTABLE`, so *individual* objections cannot
stay open forever by design; the red-team prompt instructs prioritizing
objections that would change status.

**Unmitigated:** there is no cap on the *count* of new objections raised
per review round. This is a genuine gap relative to the ledger's
pivot-threshold pattern. Left unmitigated deliberately for this MVP (adding
a hard numeric threshold now would be inventing enforcement machinery ahead
of evidence it's needed — see task constraint against over-automating the
MVP) but it is the top candidate for a v2 addition if it proves to be a
real problem in practice.

## 5. Could speculative objections be mistaken for facts?

**Risk:** real. The six-way classification (§9) is a required field, but
nothing checks that a reviewer picked the right label — a `SPECULATIVE_CONCERN`
mislabeled `STATIC_FACT` would look authoritative.

**Mitigation:** the field is structurally mandatory (every template has it);
the reviewer prompts define each classification narrowly enough to make
mislabeling harder to do by accident.

**Unmitigated:** correctness of classification is unverified, same class of
limitation the ledger itself already accepts for `reconcile_contradiction`
("recorded but not independently verified for relevance" — see
`SCIENTIFIC_DEBUGGING_PILOT_GUIDE.md` §7). A second reviewer or the
synthesis stage is the only check, and that's advisory too.

## 6. Could Claude learn to satisfy the review process without improving the science?

**Risk:** real — classic Goodhart failure. Filling out templates convincingly
and getting same-model reviewers to converge is cheaper than actually fixing
a problem.

**Mitigation:** independent dispatch (§5) with a same-model-weakness caveat
already flagged in #2 above; the Math Auditor is explicitly instructed to
re-derive, not agree-check; `ESTABLISHED` requires human decision +
empirical evidence, closing the loop for the claims that matter most (R3/R4).

**Unmitigated:** R2 changes never reach the mandatory human-decision gate
(only R3/R4 require it per config.json) — a run of R2-classified "reviewer
theater" is possible without ever tripping the one hard requirement in this
system. Mitigation for now: the risk-classification rationale in
`PACKAGE.md` is deliberately visible and dated, so a human skimming
`CLAIMS.md`/`REVIEWS/` later can catch a pattern of consistently-low
self-assigned risk levels; there's no automatic detector for it.

## 7. Could the framework duplicate or conflict with the existing debugging system?

**Risk:** addressed at the design level (§0): distinct ID namespaces
(`C-xxx`/`H-xxx` here vs. ledger's per-investigation hypotheses), no second
evidence store (`execute_experiment_policy` explicitly forbids using the
ledger's execution tool for anything this layer would need to store as
evidence), explicit cross-referencing instructions instead of copying.

**Unmitigated:** nothing stops a future session from pasting raw ledger
`stdout`/`stderr` into a `CLAIMS.md` "supporting evidence" field "for
convenience," informally recreating a duplicate copy. `PROTOCOL.md` §0
instructs against this ("cite, don't copy") but has no enforcement.

## 8. Could an old project be incorrectly treated as validated?

**Risk:** real, and specifically named in the task. Two sub-risks: (a) a
legacy claim actually gets marked validated without review, (b) a legacy
project's audit gets silently skipped and the project proceeds as if it had
been reviewed.

**Mitigation:** §15 defaults every historical claim to `UNKNOWN` with
`provenance: historical`; the retrospective audit is a distinct, explicit
step that must be offered (not silently run, and not silently skipped) at
first contact with an unregistered project (`SKILL.md` session-start
checklist).

**Unmitigated:** if a user repeatedly answers "defer" to the retrospective-
audit offer, the project can persist indefinitely in `PROJECTS.md` with
`retrospective audit done: no` and no forcing function ever runs it. That's
intentional (deferring is a legitimate choice, not a bug) but worth naming:
this system cannot force an audit to happen, only make it visible that one
hasn't.

## 9. Could the system become so burdensome that it stops being used?

**Risk:** real and, honestly, the most likely failure mode of this whole
design. Four reviewer roles, five ID-series, per-project directories, and a
risk-classification step for every R1+ change is a lot of process for an
active research codebase mid-iteration.

**Mitigation:** R0/ordinary-R1 exemption is the main release valve; §6 notes
classification "is not rigid" and a one-sentence rationale is enough;
`SKILL.md` repeats "most work should stay in normal mode."

**Unmitigated:** no built-in lightweight mode for R2 exists beyond "engage
whichever of Math/Scientific Auditor is relevant" — even that is real
overhead for, say, a minor filter-parameter change during active
exploration. If this proves too heavy in practice, the intended fix is to
retune `config.json`'s risk-level review requirements for the specific
project, not to add new machinery — that file is deliberately editable
project-by-project guidance, not a fixed law.

## 10. Are there mechanisms that accidentally let reviewers modify scientific code?

**Risk:** real before this self-review; addressed during it. Reviewer
prompts forbid code edits in text, but text-only instructions are not a
boundary — a reviewer dispatched via a general-purpose agent (with
Edit/Write/Bash) could still make an edit if it chose to.

**Mitigation applied (as of Phase E, this document's original text):**
`PROTOCOL.md` §5 and `SKILL.md` were made to instruct dispatching reviewers
via a "read-only agent type (no Edit/Write)... so 'reviewers don't edit
code' is backed by tool availability, not just instruction-following."

**Correction (Phase F, 2026-08-19): this was an overclaim, found on
investigation rather than assumption.** `Explore`/`Plan` do lack
`Edit`/`Write`/`NotebookEdit` (that part holds), but they retain `Bash`,
`PowerShell`, and `mcp__filesystem__*` — all genuine file-write channels —
so "backed by tool availability" was true only for three of the relevant
tools, not for write access in general. See `PROTOCOL.md` §5/§22 and
`SELF_REVIEW_PHASE_F.md` items 1 and 13 for the corrected, investigated
boundary, including the actually-strongest mechanism found (registering
reviewed files as `protected_paths` on an open `scientific-debug-ledger`
investigation, which does mechanically block every write channel — but only
when that step is actually taken). Left here, struck through in substance
but not deleted, as the framework's own worked example of correcting a
prompt-only control that had been mistaken for enforcement (Phase F item
15) — the exact failure mode this question was originally asking about.

**Unmitigated (still true):** where no ledger `protected_paths` step is
taken, the boundary remains advisory-only for `Bash`/`PowerShell`/MCP-write
tools — the same category of limitation `scientific-debug`'s own `SKILL.md`
half already has, and consistent with this being an MVP without its own
enforcement layer (§20 of the task this framework was built from explicitly
asks for a manual, auditable MVP, not new hooks).

## 11. Are empirical results clearly separated from LLM-generated reasoning?

**Risk:** real if unmitigated — an experiment record's "Result" field could
be filled in with a plausible-sounding fabrication before anything actually
ran.

**Mitigation:** `EXPERIMENT_TEMPLATE.md` has an explicit `SPEC_ONLY` /
`PENDING_HUMAN_EXECUTION` / `EXECUTED` status gate, and the result field
instruction is explicit: "never a paraphrase presented as if it were the raw
result." `config.json`'s `execute_experiment_policy` bans the ledger's
`execute_experiment` for anything scientific, so there's no tool-mediated
path to a real-looking-but-fabricated result for scientific experiments
specifically.

**Unmitigated:** for the human-execution path, correctness ultimately rests
on Claude actually waiting for and transcribing a real human-provided
result rather than pre-filling one — a behavioral commitment, not a
mechanical one. No hook enforces this (consistent with the MVP being purely
advisory/manual for this layer, unlike the ledger's `execute_experiment`
which mechanically cannot accept a claimed result).

## 12. Can a reviewer distinguish "not demonstrated" from "false"?

**Risk:** the two are easy to conflate informally ("we don't have evidence
this works" vs. "we have evidence this doesn't work").

**Mitigation:** status vocabularies keep them structurally distinct —
`UNRESOLVED`/`PLAUSIBLE` (not demonstrated) vs. `REFUTED` (evidence against);
`NON-TESTABLE` (can't be demonstrated either way) vs. `FALSIFIED` (evidence
shows the objection doesn't apply). All four templates require picking one
of these, not free text.

**Unmitigated:** same as #5 — correct application of the vocabulary is
unverified by anything mechanical.

## Overall assessment

The structural risks this framework can close by design — duplicate
evidence stores, reviewer-consensus-as-fact, fabricated results via the
ledger's execution tool, unbounded individual objections, silent legacy
validation — are closed. The risks it cannot close without becoming a second
enforcement layer (which the task this was built from explicitly asked this
MVP not to build) are named above rather than hidden: correctness of
reviewer classification, actual model diversity in practice, honest
risk-level self-assessment, and process burden. All four are exactly the
kind of thing a human periodically re-reading `CLAIMS.md`/`REVIEWS/` across
a project is positioned to catch, which is the intended check for this MVP —
consistent with §14's principle that reviewers recommend and humans decide.
