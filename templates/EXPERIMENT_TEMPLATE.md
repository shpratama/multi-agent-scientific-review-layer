# Experiment Spec — E-xxx

Write this **before** anything is executed. Claude never runs MATLAB/Python
or any scientific/numerical command — the human executes this and pastes
back the result, or Claude uses the ledger's `execute_experiment` only if
this experiment is a non-scientific check of the review framework's own
files (see `config.json` → `execute_experiment_policy`).

- **Question:** <the discriminating question this experiment answers>
- **Hypothesis:** `H-xxx` or `C-xxx` this tests
- **Competing prediction(s):** <what the alternative hypothesis/claim would
  predict instead — the experiment must be able to tell these apart>
- **Input/data requirements:** <exact data/files needed>
- **Exact procedure:** <step by step — specific enough that two people
  running it would do the same thing>
- **Variables:** <what's held fixed, what's varied>
- **Metrics:** <what's measured>
- **Expected outputs:** <what artifact(s) this produces>
- **Pass/fail or discriminating criteria:** <stated in advance, not after
  seeing the result>
- **Potential confounders:** <what else could produce the same-looking result>
- **Required artifacts:** <what must be saved/pasted back as evidence>
- **Reviewer/claim IDs:** `C-xxx`, `O-xxx`, `F-xxx` this experiment addresses
- **Execution channel:** human (MATLAB/Python/scientific) / ledger
  `execute_experiment` (non-scientific framework check only)
- **Status:** `SPEC_ONLY` / `PENDING_HUMAN_EXECUTION` / `EXECUTED`
- **Result (fill in only after real execution):** <what happened, with a
  pointer to the artifact — never a paraphrase presented as if it were the
  raw result>
- **Ledger cross-reference (if applicable):** `investigation_id` / `event_id`
