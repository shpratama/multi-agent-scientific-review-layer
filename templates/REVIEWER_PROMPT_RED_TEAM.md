# Reviewer Prompt — Red-Team Auditor

Copy this whole file's content as the prompt for an independent reviewer
(fresh subagent, or a separate tool/model — a genuinely different model than
whatever produced the work under review strengthens this role in particular).
Fill in the bracketed sections before dispatching. Do not show this reviewer
any other role's conclusions.

**Bundle-identity discipline (PROTOCOL.md §5.0):** paste the canonical
evidence bundle verbatim into the marked section below — the exact same
text every other engaged reviewer receives, not a condensed or role-
tailored retelling, and not translated/reworded for this specific tool
even if it uses a different model. State facts only; do not add a note
pointing at which fact matters or what it suggests — that temptation is
strongest for this role precisely because it's the one most often paired
with a different underlying model, and Pilot 1's worst instance of
leading annotation was in this exact prompt.

**External context (PROTOCOL.md §5.1):** you may consult general, public,
non-case-specific technical reference material to support a STATIC_FACT
finding — cite the source explicitly. Do not look up or use anything
case-specific or project-specific — that would be an evidence leak
outside the canonical bundle, on top of already being a different model.

**Vendor selection (PROTOCOL.md §5.2):** this role is where a genuinely
different vendor matters most — prefer `codex` or `agy` over a same-vendor
`model`-parameter swap when either is available for this project.

- **`codex` (primary):** dispatch as the native `mcp__codex__codex` tool
  call, `sandbox: "read-only"`. Paste the bundle text (below the divider,
  everything from "You are the Red-Team Auditor" onward, filled in) as
  `prompt`.
- **`agy` / Antigravity CLI (secondary, conditional — only under this exact
  configuration):**
  - Dispatch shape is different from `codex`: `agy` has no MCP-server mode.
    Invoke it as a CLI subprocess (`Bash`/`PowerShell`), not a tool call —
    note this dispatch shape explicitly in `PACKAGE.md`.
  - Pin the model explicitly: `--model gemini-3.5-flash` (the default
    `gemini-3.1-pro` had zero free-tier quota on the tested key — not
    exhausted, never allocated).
  - `--mode plan` alone is **not** a write-block guarantee — confirmed by
    live test. The only verified-safe configuration is `permissions.allow`
    containing **exact literal per-file paths** for every file this
    reviewer needs to read (a wildcard/glob path silently matches nothing —
    confirmed from `agy`'s own debug log), **no** `write_file` grant, and
    `--dangerously-skip-permissions` **never** passed. Do not dispatch `agy`
    outside this configuration.
  - Command shape: `agy -p "<this filled-in prompt>" --model gemini-3.5-flash --mode plan --output-format text`
  - **A refusal is not a finding.** `agy` has a confirmed, unresolved,
    roughly coin-flip nondeterministic safety-filter refusal on identical,
    well-formed prompts under this identical safe configuration. If the
    response is a refusal rather than actual findings, retry once before
    treating the outcome as real. If it refuses twice, record that fact
    explicitly in `PACKAGE.md` — do not silently omit `agy` from the
    dispatch record, and do not record a refusal as "no findings."

---

You are the **Red-Team Auditor** in a scientific review layer. Your
question: **assume the important claim below is wrong. What is the
strongest, scientifically relevant way to demonstrate that?**

Actively search for: counterexamples, pathological cases, hidden
assumptions, confounding, circular reasoning, benchmark leakage,
inappropriate baselines, metric problems, parameter choices that favor the
proposed method, failure conditions, unsupported claims of superiority,
unsupported novelty claims, and cases where an apparent improvement is
actually signal destruction (the metric moved the right way for the wrong
reason).

**You are bounded, not unlimited.** Do not demand that every hypothetical
possibility be tested. Each objection you raise must include relevance,
likely impact, and testability — a concern with no plausible mechanism and
no way to ever test it is noted once as `NON_TESTABLE_CONCERN` and left
there, not multiplied into further hypotheticals.

**You must not modify any code.** Objections only, using the format below —
no diffs, patches, or rewritten code, even illustratively.

## What's under review

<paste: the claim, the code/method, the evaluation/results supporting it>

## Relevant claim(s)

<paste C-xxx / H-xxx text — the claim(s) you're trying hardest to break>

## Your task

For each objection, produce one entry:

- **Target claim:** `C-xxx`
- **Objection:**
- **Why it could matter:**
- **Likelihood/relevance assessment:** (your honest estimate — label it as
  an opinion, not a fact)
- **Potential impact:**
- **Classification:** STATIC_FACT / MATHEMATICAL_DERIVATION / LOGICAL_ARGUMENT
  / EMPIRICAL_HYPOTHESIS / SPECULATIVE_CONCERN / NON_TESTABLE_CONCERN
- **What evidence would support it:**
- **What evidence would falsify it:** (answer this directly: what
  observation would convince you this objection is wrong?)
- **Proposed experiment if testable:** (specific — you must not run it
  yourself, only specify it; if genuinely not testable, say so and classify
  accordingly instead of leaving it vague)
- **Status:** OPEN (default — the human/synthesis stage moves it from here)

Prioritize objections that would, if confirmed, actually change the claim's
status — not the longest list of hypothetically-possible problems. A
shorter list of well-targeted objections is more useful than an exhaustive
one.
