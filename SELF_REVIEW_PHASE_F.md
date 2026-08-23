# Self-Review — Phase F Adversarial Red-Team of the Architecture

Extends `SELF_REVIEW.md` (Phase E, 12 questions) rather than repeating it.
This pass asks the sharper question the task posed: *how could this
framework create false confidence while appearing scientifically rigorous?*
Each item classified `FIXED` / `MITIGATED` / `ACCEPTED LIMITATION` /
`REQUIRES FUTURE WORK` — `FIXED` is used only where the implementation
actually enforces the fix, not where it's merely better-documented.

## 1. False independence

Original Phase E design implied "read-only agent type" enforcement that,
investigated in Phase F, turned out to be real only for `Edit`/`Write`/
`NotebookEdit`, not for `Bash`/`PowerShell`/`mcp__filesystem__*`. That
overclaim itself was an instance of the exact failure mode this item asks
about — a prompt-level control described as if it were tool-level.
**Status: MITIGATED.** PROTOCOL.md §5/§22 now state the true, investigated
boundary (ENFORCED for three specific tools; ADVISORY for the rest unless
combined with an active ledger `protected_paths` investigation, which is
genuinely ENFORCED when invoked). Not `FIXED`, because full write-channel
tool-level isolation independent of the ledger workflow still does not
exist.

## 2. Correlated model errors

**Status: ACCEPTED LIMITATION**, unchanged from Phase E #2. Phase F added
the `model` parameter and `codex` as partial, opportunistic mitigations
(config.json → `reviewer_independence`), but four same-family-model
reviewers remain the likely default in any project without a second tool
configured.

## 3. Reviewer anchoring

**Status: MITIGATED**, unchanged mechanism from Phase E (fresh contexts,
self-contained prompts) — Phase F re-confirmed the mechanism (Agent tool
contract: "a new Agent call starts fresh") rather than merely asserting it.
Still relies on the orchestrator not manually cross-pasting conclusions
(ADVISORY, §22).

## 4. Reviewer hallucinations

**Status: MITIGATED (new this phase).** Not previously addressed explicitly.
`static_fact_policy` (config.json) now requires a named, citable source for
any `STATIC_FACT` classification, applied in both `OBJECTION_TEMPLATE.md`
and `FINDING_TEMPLATE.md`. This closes the cheapest version — an unsourced
assertion no longer qualifies for the strongest classification by
construction. It does **not** verify the cited source is real; a reviewer
could still cite a real-sounding but wrong or fabricated source. **Residual:
REQUIRES FUTURE WORK** if this proves to matter in practice (e.g. spot-check
a sample of STATIC_FACT citations during synthesis).

## 5. Review theater

**Status: ACCEPTED LIMITATION**, unchanged substance from Phase E #6. Phase
F's dependency-escalation rule (§6.1) closes one specific sub-case (a
consequential change hiding behind a low self-assigned risk level when it
touches an existing claim's dependency) but does not address theater within
a single review pass that never touches a prior claim's dependency at all.

## 6. Endless objections

**Status: ACCEPTED LIMITATION**, explicitly named in Phase E #4 and left
unmitigated there by design (no numeric cap, unlike the ledger's
`pivot_threshold`). Phase F re-examined this and made the same call: a hard
cap would be inventing enforcement machinery ahead of evidence it's needed,
which the task instructed against ("do not overengineer," "smaller ...
over ... larger + automated"). **REQUIRES FUTURE WORK** if a real review
round demonstrates unbounded objection growth in practice.

## 7. Excessive conservatism

**Status: ACCEPTED LIMITATION (new this phase).** The dependency-escalation
rule (§6.1) is deliberately one-directional — it only ever escalates,
never de-escalates. A project with many claims that share common
dependencies (e.g. one shared normalization routine cited by ten claims)
could see every future edit to that routine forced to R3+ treatment even
for genuinely low-consequence changes, creating exactly the friction Phase
E #9 already named as the most likely failure mode. Mitigation available but
not built: allow a claim's `Depends on` entry to be annotated
"low-consequence dependency, does not trigger escalation" with a one-line
justification — deliberately not added now, since it would be adding a
second escalation-override mechanism before the first one has been used
once in practice. **REQUIRES FUTURE WORK**, contingent on real friction
being observed.

## 8. Suppression of novel ideas

**Status: MITIGATED**, unchanged from Phase E #3, and explicitly re-checked
in Phase F item "Preserve exploration/validation distinction" below — the
new mechanisms (escalation, staleness, violation handling) were audited and
confirmed not to fire on Research Mode work that touches no claim
dependency.

## 9. Evidence laundering

**Status: MITIGATED (new this phase).** `evidence_field_policy`
(config.json) now requires a claim's `Supporting evidence` field to be a
real citation (ledger event or `E-xxx`+artifact), not free text —
`CLAIM_REGISTRY_TEMPLATE.md` updated accordingly. Same caveat as item 4:
this is a template-structure fix (**ADVISORY** enforcement category, §22),
not a validator — nothing stops someone from writing a citation-shaped
string that doesn't actually resolve to a real event or artifact.

## 10. Stale reviews

**Status: MITIGATED (new this phase, tested).** The SHA-256 fingerprint
mechanism (§10.1) was built and verified end-to-end against a synthetic
fixture, not just documented — see `PHASE_F_TESTS.md` Test I: an unchanged
file correctly reproduced its recorded hash (no false positive), a modified
file correctly produced a different hash (true positive), using only
PowerShell `Get-FileHash`. Not `FIXED`, because the check is procedural —
nothing runs it automatically.

## 11. Accidental duplication of the scientific-debug ledger

**Status: MITIGATED**, unchanged substance from Phase E #7 / original §0
design. Phase F re-verified (§11 of the task, addressed in the final report)
that no ledger file, hook, or config was touched, and that the new
fingerprint mechanism is a distinct primitive (static content-identity hash)
from ledger experiment evidence (executed command output) — not a second
copy of the same thing.

## 12. Incorrect legacy migration

**Status: MITIGATED**, unchanged from Phase E #8. Phase F added Test C
(`PHASE_F_TESTS.md`) as a concrete structural check rather than leaving this
as a documentation-only claim.

## 13. Reviewer permission leakage

**Status: ACCEPTED LIMITATION (new this phase, but really a restatement of
item 1 from a different angle).** Confirmed in the Issue-1 investigation:
`Explore`/`Plan` agent types retain `mcp__filesystem__*` tools (write-capable
MCP tools are not excluded by those agent-type definitions, only the three
named built-ins are). A reviewer dispatched this way could, in principle,
still write a file via an MCP filesystem tool even with Edit/Write/
NotebookEdit blocked. The `protected_paths` ledger mechanism (§5) closes
this for the *specific reviewed files* when actually invoked, since
`hook_gate.py`'s matcher explicitly includes `mcp__filesystem__.*`. Global
permission leakage beyond those specific files remains open.

## 14. Unnecessary review overhead

**Status: ACCEPTED LIMITATION**, unchanged from Phase E #9, compounded by
item 7 above (escalation rule can only add overhead, never remove it). The
release valve is the same: `config.json` is project-editable, and R0/R1
exemption remains the default for most work.

## 15. Prompt-only controls mistaken for actual enforcement

**Status: FIXED, as a documentation/process matter — this is what the
enforcement-status glossary and table (PROTOCOL.md §22) exist to prevent
going forward.** Every control this framework describes is now labeled
ENFORCED / ADVISORY / HUMAN-CONTROLLED / UNIMPLEMENTED, and the Phase E → F
correction of the "read-only agent" overclaim (item 1 above) is the concrete
proof this matters — it is exactly the mistake item 15 warns about, made
once, by this framework's own construction, and corrected on adversarial
review. The underlying gap the overclaim was covering for (item 1, item 13)
remains an accepted limitation; what's fixed is that it's no longer
mislabeled.

## Overall Phase F assessment

Two structural risks named in Phase E as unmitigated (stale reviews;
evidence-field looseness enabling laundering) are now genuinely mitigated
with tested mechanisms, not just better prose. One real overclaim
(reviewer tool-level isolation) was found and corrected — found *by*
following this task's instruction to investigate rather than assume, which
is itself evidence the self-review process does something real. The
irreducible list going into a pilot: correlated same-model reviewers,
unbounded objection count, no de-escalation path for shared low-consequence
dependencies, and reviewer MCP-tool write access beyond ledger-protected
files. None of these are hidden in this document; all four are named again
in the final Phase F report's "Remaining limitations" section.
