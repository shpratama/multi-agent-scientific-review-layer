# Multi-Agent Scientific Review Layer

Persistent, global infrastructure for Claude Code: independent, adversarial,
multi-role review of scientific/technical claims before they're accepted,
built alongside (not duplicating) the separate `scientific-debug`
ledger/evidence system. Full reference: [`PROTOCOL.md`](PROTOCOL.md).

This repo is the **reusable framework only** — no real project data. See
`PROTOCOL.md`'s "Deployment note" for what's deliberately excluded and why.

## What's here

- [`PROTOCOL.md`](PROTOCOL.md) — the full protocol: reviewer roles,
  independence rules, risk gates, claim/objection lifecycle, enforcement
  status of every mechanism.
- [`config.json`](config.json) — machine-referenceable policy data read
  alongside `PROTOCOL.md` (risk levels, statuses, vendor options, etc.).
- [`templates/`](templates/) — reviewer prompts and review-package
  templates to copy per real review.
- `SELF_REVIEW*.md`, `PHASE_F_TESTS.md`, `VIOLATIONS_LOG.md`,
  `ANALYSIS/RECONSTRUCTION_INDEPENDENCE_ANALYSIS.md` — the framework's own
  build/validation history. Generic — no client data.
- `PROJECTS.template.md` — copy to `PROJECTS.md` (gitignored) to start
  tracking real projects on your own deployment.

## Not here (gitignored, per-deployment, never committed)

`projects/`, `PROJECTS.md`, `POSTMORTEMS/`, `ANALYSIS/validation-*/` — real
investigation data accumulates locally on each machine this is deployed to
and is never pushed. Pulling framework updates never touches these.

## Setting this up on a new device

1. Clone this repo somewhere stable (any path — nothing in `PROTOCOL.md`
   hardcodes a location).
2. `cp PROJECTS.template.md PROJECTS.md` to get a local, empty project
   index. **Scope, stated plainly:** a `project_key` is assumed to be
   worked on by one person at a time, even across that person's own
   multiple devices/sessions — `PROTOCOL.md` §10's lock file handles the
   ID-allocation race that creates for a single person switching
   devices. There is **no** reconciliation mechanism for genuinely
   concurrent multi-person editing of the same project. If that ever
   becomes a real need, it requires a different design, not an
   extension of this one.
3. Point the global skill entry at this clone: create/edit
   `~/.claude/skills/scientific-review/SKILL.md` (this file lives outside
   the repo, per-device) so its path references point here. There is no
   template for this in the repo yet — write it referencing this clone's
   absolute path, following the pattern `PROTOCOL.md` describes at the top
   ("the short advisory version read at the start of a session").
4. Dependency: the framework's one genuinely `ENFORCED` mechanism (a real
   `PreToolUse` gate blocking a reviewer's writes via `protected_paths`)
   requires the separate `scientific-debug` ledger system to also be set
   up on this device. Without it, the framework still works, but every
   protection is `ADVISORY` rather than `ENFORCED` — see `PROTOCOL.md` §5
   and §22 for exactly what that distinction means in practice.
5. Optional, for cross-vendor Red-Team review (`PROTOCOL.md` §5.2):
   register `codex` as an MCP server (primary) and/or install/configure
   `agy` (Antigravity CLI, secondary — read §5.2 fully before using it,
   the safe configuration is specific and non-obvious).

## Keeping it updated

`git pull` on any device/clone. Framework changes (protocol edits, new
templates, vendor-policy updates) come through normally; local project
data is gitignored and untouched by a pull. To contribute a framework
improvement back, open a PR the normal way — this repo is private, not
public.
