# Finding — F-xxx

For Code Auditor / Math Auditor / Scientific Auditor findings that are not
adversarial "assume it's wrong" objections (those use `OBJECTION_TEMPLATE.md`
instead — typically Red Team, but any role may raise a genuine objection).

- **Affected claim/change:** `C-xxx` or a description of the code/change
- **Reviewer role:** code_auditor / math_auditor / scientific_auditor
- **Concern:** <what was found>
- **Reasoning:** <why this is a concern — show the work; for the Math
  Auditor this should be an independent derivation, not agreement/disagreement
  with the author's>
- **Evidence currently available:** <what's already known, with citations>
- **Classification:** STATIC_FACT / MATHEMATICAL_DERIVATION / LOGICAL_ARGUMENT
  / EMPIRICAL_HYPOTHESIS / SPECULATIVE_CONCERN / NON_TESTABLE_CONCERN
  (`STATIC_FACT` requires a named, citable source in Reasoning above — see
  `config.json` → `static_fact_policy`; otherwise use LOGICAL_ARGUMENT or
  SPECULATIVE_CONCERN)
- **Severity:** blocking / significant / minor / informational
- **Required experiment or analysis:** `E-xxx` or "none — resolvable by
  inspection" (explain)
- **Status:** OPEN / FALSIFIED / CONFIRMED / BOUNDED / NON-TESTABLE
