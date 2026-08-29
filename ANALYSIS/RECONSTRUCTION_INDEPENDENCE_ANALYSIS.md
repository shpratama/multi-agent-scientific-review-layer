# Reconstruction Independence / Evidence Completeness — Design Analysis

Not a pilot. Not an implementation. No framework files (`PROTOCOL.md`,
`config.json`, templates) touched by this document — it's an analysis to
reach agreement on before anything gets built. No MATLAB/Python, no
scientific code touched. Grounded in what Pilot 1 and Pilot 2 actually
showed, not in abstract design preference.

## Starting position

Both pilots converge on the same unresolved structural fact: the
orchestrator that builds the evidence bundle is a single point of
epistemic failure that bundle-identity discipline does not address,
because bundle-identity discipline only constrains what happens *after*
the bundle exists (no re-authoring, no leading annotations). It says
nothing about what goes *into* the bundle in the first place. Everything
below is about that earlier stage.

## 1. Is an independent Evidence/Package Auditor actually sufficient?

**No — and it's worth being precise about why, not just asserting it.**
An Evidence/Package Auditor is itself dispatched by, and (in the obvious
design) receives its task framing from, the same orchestrator whose
output it's meant to check. That's the identical structural problem one
level up: nothing stops the orchestrator from writing a leading or
narrow *audit* prompt the same way it could write a leading *review*
prompt. This is a regress, not a fix — "who audits the auditor" doesn't
terminate by adding one more role, and trying to terminate it by adding
another auditor-of-the-auditor is exactly the bureaucracy Q10 asks about.

What actually makes an auditor role *worth adding* despite this is
narrower and more defensible than "sufficiency": it converts a **silent,
undetectable failure mode** into a **disclosed, checkable one**. Right
now, if the orchestrator omits something, nothing distinguishes that from
an evidence base that was genuinely complete — the omission is invisible
by construction. An independent auditor — even an imperfect,
same-orchestrator-dispatched one — at minimum produces a second,
separately-timestamped opinion that can *disagree* with the bundle's
completeness, the same way a second reviewer's disagreement is valuable
even though neither reviewer is infallible. That's real value. It is not
"sufficiency."

**A genuine tension worth stating rather than smoothing over:** Pilot 2's
strongest result — the missing-stdout finding — was discovered by 4/4
*specialized* reviewers converging independently, which is much stronger
evidence than one auditor role catching it upfront would have been. If an
Evidence/Package Auditor exists and does its job well, it will often
catch exactly this class of gap *before* dispatch — which means future
pilots will have fewer opportunities to demonstrate multi-reviewer
convergence on evidence-quality issues, because the auditor will have
already fixed them. That's a good outcome for real investigations (catch
problems earlier) and a genuine loss for *this project's own ability to
keep measuring whether independent review adds value* the way Pilot 2
just did. Worth having eyes open about that trade before deciding how
much auditing to front-load.

## 2. Should it see the raw investigation before the canonical bundle is finalized?

**Yes, and specifically in this order: raw investigation first, bundle
second — never the reverse.** This mirrors the same process-isolation
principle that already governs the four specialized reviewers (§5 of the
protocol): a party that forms its own understanding *before* seeing
someone else's framing of the same material can meaningfully disagree
with that framing; a party shown the framing first will tend to anchor on
it even when told not to (this is not a novel claim about this framework
— it's the ordinary anchoring-bias reason review protocols in general
ask reviewers to form independent judgments before reading a summary).

Concretely: the auditor should independently call `get_investigation_state`
(and, per §5 below, independently read the raw JSONL for cited experiment
IDs) on its own, form a private inventory of what exists, and *only then*
be given the canonical bundle to diff against that inventory. If it's
given the bundle first "for context," its diff becomes a confirmation
exercise, not an independent check.

## 3. One reconstruction or two independent reconstructions?

**Neither as a blanket rule — tie it to the existing risk gate, don't add
a new orthogonal one.** Dual reconstruction (two independently-built
bundles, compared) is a stronger check than a single bundle plus an
auditor's review of it, for the same reason two independent reviewers
beat one reviewer plus a second pass by the same author: independent
*construction* surfaces different omissions than independent *checking*
of one construction does. But it roughly doubles the cost of the most
expensive part of the whole pipeline (finding, excerpting, and framing
the evidence), and Q10 is explicit that this system can become too
bureaucratic to use.

The framework already has a mechanism for exactly this cost/rigor
trade-off: R0–R4. Recommend treating "single bundle + independent
auditor" as the R1–R2 default, and "dual independent reconstruction" as
something reserved for R3/R4 claims specifically — the same claims that
already require the full four-role panel and a recorded human decision.
This doesn't invent new bureaucracy; it extends bureaucracy the framework
already accepted is worth the cost at that risk tier, and nowhere else.

## 4. How to measure evidence omission without a complete copy of the investigation?

Don't try to prove completeness in the absolute sense — that requires the
full copy this question is explicitly trying to avoid, and "did I
include everything relevant" is a judgment call with no ground truth to
check it against anyway. Two things are checkable without that:

**A. A mechanical, non-judgment ID-coverage check.** `get_investigation_state`
returns an exact, enumerable list of hypothesis IDs and experiment IDs.
Whether every one of those IDs appears as a literal string somewhere in
the canonical bundle is a deterministic yes/no fact — checkable by a
`grep`/text-search, not by an LLM's judgment about relevance. This is
the single most tractable, cheapest, most trustworthy check available,
and notably it's the kind of check that doesn't need an LLM auditor role
at all — see §9.

**B. Explicit, disclosed scope boundaries instead of implied
completeness.** Pilot 2's `CANONICAL_EVIDENCE.md` excerpted lines
115–154 of a longer file and said so explicitly; the Code Auditor
correctly treated everything outside that range as an acknowledged,
unauditable gap rather than assuming the excerpt was the whole file. That
worked *because the boundary was disclosed*, not because the excerpt was
complete. Generalize this: a reconstruction should always state what it
deliberately left out and why (a file excerpt's line range, a decision
not to include an unrelated closed contradiction, etc.), rather than
presenting itself as if it were the full record. "Selection transparency"
(the user's property B) is achievable this way without needing "prove
nothing is missing," which isn't achievable at all.

## 5. How should raw experiment stdout/stderr enter the evidence model?

`get_investigation_state`'s derived summary — confirmed directly this
session — does not include captured stdout/stderr; only `exit_code` and
the `command` text. The actual content lives in each experiment's
`RESULT_RECORDED` event, in the raw per-investigation JSONL file. This is
readable today with a plain static file read (`Read`/`Grep`, exactly how
the C-002 tamper test read raw ledger JSONL earlier this session) — no
new tool or ledger change is required to fix this specific gap.

Recommend: when building a canonical bundle, for every experiment ID
mentioned, the reconstruction step must locate that experiment's
`RESULT_RECORDED` event in the raw JSONL and include its (possibly
truncated, per the ledger's own existing 8000/4000-char truncation
convention) stdout/stderr — or explicitly state "captured output not
retrievable" if that event genuinely doesn't exist (as it wouldn't for an
`executed: false` experiment). This closes Pilot 2's F1 specifically, and
retroactively flags Pilot 1's bundle as having the same gap for the same
reason.

## 6. How should file dependencies and ledger-investigation dependencies coexist?

They're not competing mechanisms — they answer different questions and a
single claim can genuinely have both. A claim like Pilot 2's C-P2-001
depends on *(a)* a specific file's current content (`join_labels_to_features.m`,
checkable by SHA-256 fingerprint, per PROTOCOL.md §10.1's existing
mechanism) and *(b)* a ledger investigation's current state (checkable by
`event_count`/`chain.valid`, per the practical signal both pilots used
but never formalized).

Design direction (not implemented here, per the "don't build yet"
instruction): the `Depends on:` field should support both kinds of entry
explicitly typed, e.g. `file: <path> @ sha256:<hash>` and
`investigation: <investigation_id> @ event_count:<N>`, checked by their
respective, already-existing mechanisms. Nothing new needs to be
invented — both fingerprinting mechanisms already exist and were both
exercised (separately) this session; what's missing is a template field
that lets a claim declare it has one, the other, or both, instead of the
current template only having room for one file-shaped kind.

## 7. Where should external documentation be allowed?

Pilot 2 surfaced this as an accidental asymmetry (one reviewer used it,
others weren't offered it). On reflection this shouldn't be an asymmetry
*or* a prohibition — it should be an explicit, uniform permission,
because it's exactly what the framework's own `STATIC_FACT` classification
already requires and currently has no legitimate source for. `config.json`'s
`static_fact_policy` says a `STATIC_FACT` finding needs "a citable
source" or it should be reclassified as `LOGICAL_ARGUMENT` or
`SPECULATIVE_CONCERN" — but nothing currently tells reviewers *where*
such a source may legitimately come from. General, public, non-case-specific
technical reference material (language/library documentation, published
standards, textbook results) is precisely that legitimate source.

Recommend the boundary be: general/public reference material — yes,
uniformly available to every reviewer role, cited explicitly (so it's
checkable) — versus anything project-specific, case-specific, or
proprietary — no, that would be an evidence leak outside the canonical
bundle, exactly what bundle-identity discipline exists to prevent. This
distinction is drawable and enforceable in the templates without new
tooling; it just needs to be stated rather than left implicit.

## 8. What should remain human-controlled?

Everything the framework already assigns there, unchanged, plus new items
this analysis surfaces:

- The claim-status decision itself (`ESTABLISHED` etc.) — already
  human-controlled, held in both pilots, no reason to revisit.
- **Whether a given claim escalates to dual reconstruction** (§3) — a
  cost/rigor trade-off, not something that should auto-trigger, the same
  way risk-level classification itself is currently a documented judgment
  call rather than an automatic function of file size or hypothesis
  count.
- **Whether external documentation is permitted for a specific
  investigation** (§7) — the general/public default is reasonable, but
  some engagements may have reasons (confidentiality, a client's explicit
  preference) to forbid even public lookups, and that override should sit
  with a human, not be inferred.
- **Whether to accept an Evidence/Package Auditor's clearance as
  sufficient**, given §1's finding that the auditor is not itself
  sufficient — its output is a recommendation a human weighs, exactly
  like every other reviewer's output already is.

## 9. What's worth enforcing versus advisory?

Applying the framework's own glossary (`ENFORCED`/`ADVISORY`/
`HUMAN-CONTROLLED`/`UNIMPLEMENTED`) to what this analysis proposes, rather
than leaving it unstated the way Pilot 1 originally did:

- **§4.A (mechanical ID-coverage check) is the one genuinely `ENFORCED`-grade
  candidate here.** It requires no LLM judgment — a deterministic
  string-presence check over a known ID list is exactly the kind of thing
  that can gate dispatch mechanically (refuse to proceed to reviewer
  dispatch if any known hypothesis/experiment ID is absent from the
  bundle), the same category of determinism the `scientific-debug` gate's
  own precondition checks already have. This is the strongest, cheapest,
  least bureaucratic thing this whole analysis can recommend, and it's
  worth building before anything involving another LLM role.
- Raw-first-then-bundle ordering for an Evidence Auditor (§2): **ADVISORY**
  — a dispatch-order discipline, not something a tool enforces, same
  category as bundle-identity discipline itself.
- Stdout retrieval into bundles (§5): **ADVISORY** as a reconstruction-step
  requirement, though it could be tightened toward the §4.A pattern later
  (a mechanical check: "does every `executed: true` experiment ID
  mentioned in the bundle have accompanying stdout text nearby" is
  almost as checkable as ID-coverage itself).
- External-documentation citation requirement (§7): **ADVISORY**.
- Everything under §8: **HUMAN-CONTROLLED** by design, not a gap to close.

## 10. At what point does the system become too bureaucratic to be useful?

Direct answer: **when the machinery built to verify a finding costs more
than a human would have spent just reading the raw investigation
themselves.** Two real pilots' worth of infrastructure (dispatch records,
permission tables, synthesis tables, independence coding, two
postmortems) has now been built to review two moderately-scoped bugs.
That overhead was worth it *as a one-time proof that the mechanism
works* — it would not be worth repeating at this depth for every future
R1/R2 finding.

The concrete guardrail this analysis recommends: tie new machinery's cost
to the existing risk gate, not to a flat requirement applied everywhere.
§4.A's mechanical ID-check is cheap enough to run always. An Evidence/
Package Auditor role, and especially dual reconstruction, should be
reserved for R3/R4 — claims that already justify the full four-role panel
and a human decision. For R1/R2 work, the two structural fixes worth
keeping unconditionally are the cheap, mechanical one (§4.A) and the
disclosed-scope-boundary convention (§4.B), both of which cost
approximately nothing beyond what reconstruction already does.

## Summary recommendation (design position, not an implementation)

Keep the architecture the user sketched — `scientific-debug` (did an
experiment run, what did it capture) → reconstruction/evidence layer
(what's being shown, is the showing faithful) → specialized reviewers
(what does this evidence imply) → red team (what could be wrong with the
whole framing) → synthesis (agreement/disagreement/genuine novelty) →
human (accept/reject/investigate) — but scope the new evidence-layer
machinery narrowly:

1. Build the mechanical ID-coverage check first (§4.A, §9) — cheapest,
   least bureaucratic, most trustworthy, no new LLM role required.
2. Add the disclosed-scope-boundary convention to reconstruction practice
   (§4.B) — a documentation habit, not new infrastructure.
3. Fix stdout retrieval into bundles (§5) as a reconstruction-step
   requirement — directly closes Pilot 2's strongest finding.
4. Define the external-documentation policy (§7) explicitly in the
   reviewer-prompt templates.
5. Reserve the full Evidence/Package Auditor role and dual reconstruction
   (§1–§3) for R3/R4 claims specifically, not as a blanket requirement —
   and go in with eyes open about §1's regress problem and the
   convergent-discovery trade-off named there, not as a solved problem.
6. Leave the dependency-typing design (§6) as a template change to make
   later, once #2–4 above are settled and there's a real R2+ claim with a
   genuine file-and-investigation dependency to test it against.

Nothing above has been implemented. This is the analysis to react to,
adjust, or reject before any of it becomes a framework change.

## Revisit, 2026-08-29

Recommendation 5's deferral condition ("reserve... for R3/R4 claims
specifically") was checked against the one real R4 case that exists
(`REVIEWS/R4-sjsso-mc-v2-benchmark-2026-08-22`) as part of a discussion
pass reacting to an outside reviewer's pushback. Finding: that review did
have a genuine evidentiary weakness (benchmark numbers existed only as
human-pasted session output, n=1 subject, n=1 seed, no permanent
artifact) — but it was caught twice over without any Package Auditor: the
orchestrator self-disclosed it in `PACKAGE.md` before dispatch, and all
three non-code reviewer roles raised it independently anyway
(`SYNTHESIS.md`'s H3). The specific failure mode this role/check exists
to catch — a bundle problem invisible to reviewers because they only see
what the orchestrator hands them — did not actually occur in the one
real case checked.

**Decision (human-made, 2026-08-29):** defer the interim length/parity
check discussed alongside the full role, matching the existing deferral
of the full role itself. Not because the underlying need is proven
absent — one clean case doesn't prove that — but because it wasn't
demonstrated present either. Revisit if a future case shows the
disclosure-and-convergent-catch pattern failing (a bundle problem that
reviewers miss and the orchestrator doesn't disclose).

**Corroboration, 2026-08-29:** a cold external design review (`codex`,
no prior-phase context — `ANALYSIS/EXTERNAL_DESIGN_REVIEW_2026-08-29.md`,
finding #2) independently cited this exact gap. Worth noting precisely
what kind of evidence this is: Codex was instructed to read `PROTOCOL.md`
directly, which already states this as `UNIMPLEMENTED` in §22 — so this
is "an outside reviewer correctly found and re-cited an already-named
gap," not "an outside reviewer surfaced an undocumented one." Real
corroboration that the gap is genuine and visible, not evidence of
independent discovery. Doesn't change the 2026-08-29 revisit decision
above.
