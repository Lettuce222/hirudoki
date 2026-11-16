# Project agent rules

## Mandatory work logging

Every activity that contributes to this technical assignment counts toward its 30-hour limit. This includes planning, research, decisions, account and environment setup, implementation, tests, debugging, UI/UX, deployment, documentation, waiting for task operations, and submission checks.

Before doing project work, read and follow `.agents/skills/work-log/SKILL.md`.

- Run `bin/work-log status` before starting.
- Start the global clock when none is active.
- When work is already active, including work performed by a parallel agent, add a note instead of starting an overlapping timer.
- The primary agent stops the clock before work pauses or the final response is sent.
- Never add parallel agent durations together. The submitted total is elapsed project wall time.
- Do not edit `docs/work-log/work-log.jsonl` or its generated summary manually.
- Include relevant Linear issue identifiers in the log.

## Decisions and progress

- Record significant technical and process decisions in `docs/adr/`.
- Keep implementation progress, time budgets, dependencies, and pending decisions in the Linear project `ひるどき 技術試験`.
- An accepted decision is not complete until its ADR and Linear issue agree.
- Keep `docs/requirements/traceability.md` aligned with PDF requirements and their Linear tickets. When completing a slice, record the covered requirement IDs, spec paths/results, and production verification evidence in the ticket and the document's evidence table. Ticket creation alone is not evidence of implementation.
