# External Design Review — 2026-08-29

## Dispatch record

- **Reviewer:** `codex` (OpenAI, via `mcp__codex__codex`), `sandbox: read-only`
- **Context:** Cold dispatch — no prior-phase framing, no summary of what
  earlier hardening passes concluded. Instructed to read
  `PROTOCOL.md`, `config.json`, `SELF_REVIEW.md`, `SELF_REVIEW_PHASE_F.md`
  directly and red-team the framework's own design, not any project's
  science (there was no project claim under review in this task).
- **Recorded here verbatim, unedited** — per the explicit instruction this
  dispatch was made under: no pre-editing, filtering, or paraphrasing of
  the response before recording, including if the result had come back
  clean. It did not come back clean.
- **Not yet triaged.** Nothing below has been agreed, disputed, or acted
  on — that's a separate step.

## Prompt sent (verbatim)

> Red-team this framework's own design. Do not rewrite anything -- report
> findings only.
>
> Read these files directly, in full, before responding:
> - D:\System Scripts\Multi-Agent Scientific Review Layer\PROTOCOL.md
> - D:\System Scripts\Multi-Agent Scientific Review Layer\config.json
> - D:\System Scripts\Multi-Agent Scientific Review Layer\SELF_REVIEW.md
> - D:\System Scripts\Multi-Agent Scientific Review Layer\SELF_REVIEW_PHASE_F.md
>
> This is a persistent, multi-role review framework meant to give
> independent, adversarial review of scientific/technical claims before
> they're accepted. Your job here is not to review any project's science
> -- there is no project claim under review in this task. Instead,
> red-team the framework's own design and reasoning, as if you were a
> skeptical outside engineer evaluating whether to trust and adopt this
> system.
>
> Look specifically for: logical gaps in the design, unstated or shaky
> assumptions, places where the documentation claims more rigor or
> enforcement than the design actually delivers, internal contradictions
> between sections, places where the self-review documents (SELF_REVIEW.md,
> SELF_REVIEW_PHASE_F.md) may be too lenient or too confident about the
> framework's own design, missing or under-considered failure modes, and
> anything that seems weak, hand-wavy, or under-justified anywhere in
> these four files.
>
> Be as adversarial as you would reviewing a stranger's design that you
> have no prior familiarity with and no reason to go easy on. If, after
> genuinely trying, you find nothing seriously wrong, say so plainly and
> explain what you checked -- a clean result is a real, useful finding
> too, not a failure to find something.

## Response (verbatim)

I read all four requested files in full. Findings only.

**Findings**

1. **High: "Validation Mode enforces evidence" is still an overclaim.**
   PROTOCOL.md:73 says this layer "has no enforcement power of its own,"
   and PROTOCOL.md:936 says almost everything new is advisory. But
   PROTOCOL.md:959 still states "Validation Mode enforces evidence." That
   contradicts the enforcement table and weakens the claim in
   SELF_REVIEW_PHASE_F.md:151 that prompt-only controls being mistaken for
   enforcement is "FIXED."

2. **High: Reviewer independence is mostly independence from each other,
   not independence from the evidence curator.** The framework fixed
   role-to-role contamination with byte-identical bundles, but the Primary
   Agent/orchestrator still decides what goes into the canonical bundle.
   PROTOCOL.md:544 adds reconstruction requirements, but PROTOCOL.md:934
   explicitly says fair excerpt/field selection is `UNIMPLEMENTED`. That is
   a central trust gap: reviewers can independently analyze a biased or
   incomplete package.

3. **High: Human decision requirements are internally inconsistent and
   weakly authenticated.** PROTOCOL.md:714 says R3/R4 decisions go in
   `DECISIONS.md`, and PROTOCOL.md:722 says `ESTABLISHED` needs a `D-xxx`
   entry. But config.json:24 gives R3 full review/evidence without
   `requires_human_decision`, while config.json:31 gives that explicit
   flag only to R4. Also, the "human decision" is just editable Markdown;
   PROTOCOL.md:924 admits nothing blocks hand-editing status fields.

4. **High: Risk gates are too dependent on the same agent whose work is
   being reviewed.** R1 review depends on the "author's judgment" per
   config.json:11, Validation Mode starts when a consequential claim is
   "on the table" per PROTOCOL.md:193, and level choice only needs a
   one-sentence rationale per PROTOCOL.md:467. SELF_REVIEW names this risk
   at SELF_REVIEW.md:52, but the mitigation is basically visibility after
   the fact. A motivated or overloaded agent can keep consequential work
   in R1/R2.

5. **Medium: R2 gates look underpowered for methodological changes.**
   config.json:17 requires Math and/or Scientific Auditor for R2, but not
   necessarily Code Auditor, Red Team, empirical evidence, or human
   decision. Many "changed filtering/optimization/STFT-WOLA" changes are
   exactly where implementation correctness and adversarial counterexamples
   matter. SELF_REVIEW acknowledges R2 "reviewer theater" at
   SELF_REVIEW.md:102 but leaves it largely accepted.

6. **Medium: "Evidence stays in one place" conflicts with raw-output
   bundle requirements.** PROTOCOL.md:86 says this layer never stores raw
   experiment stdout/stderr as its own source of truth. Later,
   PROTOCOL.md:573 requires canonical bundles to include captured
   stdout/stderr for included executed experiments. That may be intended
   as a copied excerpt, but it undercuts the clean "cite, don't copy"
   boundary and creates stale/truncated duplicate evidence risk.

7. **Medium: Staleness mitigation is narrower than the self-review
   implies.** The SHA-256 freshness check in PROTOCOL.md:648 only covers
   recorded file/method dependencies, and PROTOCOL.md:670 says it is not
   automatic. It misses data files, parameters, environment versions,
   external references, unlisted dependencies, and semantic drift outside
   hashed files. Calling it "MITIGATED (tested)" in
   SELF_REVIEW_PHASE_F.md:104 is too confident; the test proves hashing
   works, not that review staleness is reliably caught.

8. **Medium: External-context policy may exclude highly relevant adverse
   evidence.** PROTOCOL.md:305 forbids case-specific/project-specific
   external material, such as a GitHub issue about the exact bug or an
   internal wiki page. For adversarial scientific review, that can
   suppress the most probative evidence. Disclosure and uniform
   availability would address anchoring better than prohibition.

9. **Medium: Non-testable objections can become a sink for hard
   limitations.** PROTOCOL.md:601 says objections with no feasible
   falsifier become `NON_TESTABLE_CONCERN`, and PROTOCOL.md:679 treats
   `NON-TESTABLE` as a permanent non-blocking limitation. Some
   non-testable assumptions should block strong claims, not merely be
   documented. The current status vocabulary lacks a clear "non-testable
   but claim-limiting/blocking" path.

10. **Medium: Human-run experiment provenance is weak.** PROTOCOL.md:695
    says the human runs scientific experiments and pastes back
    results/artifact pointers. SELF_REVIEW.md:210 correctly admits this is
    behavioral, not mechanical. For adoption, this is a major trust
    boundary: no required checksum, immutable artifact capture,
    environment capture, or independent reproduction is specified in these
    four files.

11. **Low/Medium: The enforcement-floor check can false-positive.**
    PROTOCOL.md:127 checks for the string `hook_gate.py` in settings
    files. That proves a substring exists, not that the hook is active,
    correct, current, reachable, or configured for the relevant paths. Yet
    PROTOCOL.md:918 treats the check as the enforcement-floor presence
    check. It is mechanically verifiable as a grep, not as a meaningful
    enforcement guarantee.

12. **Low/Medium: Project keys and manual IDs are collision/error-prone.**
    PROTOCOL.md:810 replaces slashes, colons, and spaces with `-`.
    Different paths can collapse to the same slug. PROTOCOL.md:636 also
    uses manual max-plus-one ID allocation. For a persistent multi-role
    system, this invites duplicate IDs and project-state collision unless
    humans are very careful.

**Overall Assessment**

The framework is unusually candid about many limitations, which is a
strength. But the main weakness remains structural: it presents a
rigorous review workflow while most controls are advisory, many trust
boundaries depend on the Primary Agent's discipline, and the strongest
"independence" claim does not solve biased evidence-package construction.
I would treat this as a useful audit scaffold, not as a system that
independently establishes trust in scientific claims.

---

## Triage (added after the response above, not part of it)

Nothing above this line was edited. This section records what's actually
been done with four of the twelve findings so far — not a full triage of
all twelve, which remains open.

- **#1 ("Validation Mode enforces evidence" contradicts §22/§23-point-13):
  CONFIRMED independently**, not just on Codex's citation — the same
  tension was independently spotted by the human reviewing this thread
  before Codex was even dispatched. §23 point 7 read *"Validation Mode
  enforces evidence"* six lines above point 13's own rule that an
  advisory control is never described using enforcement language.
  **Fixed**: point 7 now reads "Validation Mode requires evidence."
- **#11 (enforcement-floor check proves registration, not active/correct/
  scoped coverage): CONFIRMED, not disputed.** §0.1 now states this
  limitation explicitly — a passing check means "the dependency hasn't
  been obviously skipped," not "the gate is confirmed working for this
  review." The check's mechanism itself is unchanged; only the claim
  about what it proves was corrected. A real fix to the check's scoping
  power (if one is wanted) is a separate, not-yet-started design pass.
- **#2: CONFIRMED duplicate of an already-tracked gap, not new
  information.** `PROTOCOL.md` §22 already lists reconstruction fairness
  as `UNIMPLEMENTED`, citing `ANALYSIS/RECONSTRUCTION_INDEPENDENCE_ANALYSIS.md`
  §1 by name — the exact gap #2 describes. Cross-referenced there. Note:
  Codex read `PROTOCOL.md` directly per its instructions, so this is
  "correctly re-cited an already-documented gap," not independent
  discovery — real corroboration of visibility, not of novelty.
- **#4: CONFIRMED duplicate of an already-tracked risk, different theme
  from #2 (correctly not the same point).** `SELF_REVIEW.md:52` already
  names this exact risk (self-assessed risk level, no external check).
  Cross-referenced there, not in `RECONSTRUCTION_INDEPENDENCE_ANALYSIS.md`
  — #2 is about bundle-construction fairness, #4 is about risk-level
  self-assessment; conflating them would have been the wrong call. Same
  read-the-file-directly caveat as #2.
- **#3: two distinct halves, triaged separately, different outcomes.**
  - **(a) `config.json`'s R3/R4 `requires_human_decision` asymmetry:
    CONFIRMED real, FIXED.** `PROTOCOL.md` §14 says "for R3/R4" together;
    `config.json` had the flag on R4 only. Added `"requires_human_decision":
    true"` to R3 to match §14's own stated intent.
  - **(b) `D-xxx` "who made it" as unverified freeform text: judgment
    call, NO ACTION.** Confirmed the field has no authentication
    mechanism. Given the single-user-per-`project_key` scope already
    settled (this thread's earlier #7 discussion), there's no adversarial
    multi-party scenario this needs to guard against currently. Revisit
    only if that scope answer ever changes.
- **Methodology note for a future second cold-vendor pass (not this one —
  this dispatch is done, don't redo it):** this dispatch handed Codex
  `SELF_REVIEW.md`/`SELF_REVIEW_PHASE_F.md` alongside `PROTOCOL.md`/
  `config.json`. Both files already name several of the gaps Codex then
  "found" (#2, #4 confirmed above), which makes those specific findings
  a comprehension check on documents that already spell the risk out,
  not a test of independent discovery — still a real, useful signal
  (confirms the risk is legible to an outside reader, not buried), just
  a meaningfully weaker one than rediscovery would be. If a second cold
  pass is ever run, dispatch with only `PROTOCOL.md` and `config.json`,
  deliberately withholding the self-review files — that turns it into an
  actual independent-discovery test.
- **Findings #5–#10: surfaced 2026-08-29, deliberately left
  untriaged — queued for a dedicated pass, not resolved here and not
  lost.** Titles, for reference: #5 R2 gates underpowered for
  methodological changes; #6 raw-output bundle requirement vs.
  "evidence stays in one place"; #7 staleness mitigation narrower than
  self-review implies; #8 external-context policy may exclude relevant
  adverse evidence; #9 non-testable objections as a sink for hard
  limitations; #10 human-run experiment provenance is weak.
- **#12, checked and split — it's two things, not one:** *"Project keys
  and manual IDs are collision/error-prone... Different paths can
  collapse to the same slug... manual max-plus-one ID allocation...
  invites duplicate IDs and project-state collision."* (a) The manual
  ID-allocation race (`PROTOCOL.md:636`) is exactly what item 4's lock
  file fixes — folded into that build, not queued separately. (b)
  `project_key` slugification collisions (`PROTOCOL.md:810` — distinct
  absolute paths could collapse onto the same slug string) is a
  different problem a lock file does nothing for — **queued here,
  unresolved, alongside #5–#10.**
