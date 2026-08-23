# Constraint Violation Log — <project name>

Classes (`config.json` → `violation_classes`): `harmless_infrastructure_mistake`
/ `potentially_contaminating_scientific_action` / `prohibited_experiment_executed`
/ `fabricated_or_claimed_evidence`. See PROTOCOL.md §21 for the full decision
tree. Record every violation here, even harmless ones — this file existing
and being empty is meaningful (it means no violations occurred), silence
because nothing was logged is not the same thing.

---

## V-001

- **Date:** <YYYY-MM-DD>
- **What happened:** <exact action — command run, tool called, with the
  literal command/arguments>
- **Class:** harmless_infrastructure_mistake / potentially_contaminating_
  scientific_action / prohibited_experiment_executed / fabricated_or_claimed_evidence
- **Affected action/output:** <what this touched, if anything>
- **Contamination assessment:** <did this touch any scientific file, claim,
  hypothesis, or evidence record outside the normal review workflow? name
  which ones, or state "none" explicitly>
- **Response taken:** continue / claims downgraded to UNRESOLVED (list which)
  / record reverted to pre-execution status (cite which) / user notified
  same turn
- **Resolved:** yes / no — <if no, what's still pending>

<!-- Copy the block above for each violation. Increment the ID. Never delete
a prior entry, even after it's resolved -- mark it resolved instead. -->
