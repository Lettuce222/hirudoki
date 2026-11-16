---
name: work-log
description: Record elapsed time for every Hirudoki project activity, including planning, decisions, implementation, testing, deployment, documentation, account setup, and submission. Use whenever work starts, changes phase, pauses, or finishes inside this repository. Do not use for unrelated work.
---

# Work Log

Keep the submitted 30-hour accounting complete without double-counting parallel agents.

## Required workflow

Run commands from the application root with `bin/work-log`.

1. Before project work, run `bin/work-log status`.
2. If no session is active, start one:

   ```text
   bin/work-log start --category CATEGORY --summary "WORK" --issues LET-123,LET-456
   ```

3. If a session is already active, do not start another. Add the new or parallel activity:

   ```text
   bin/work-log note --text "Started parallel work on LET-123"
   ```

   If parallel work crosses categories, promote the session to `mixed`:

   ```text
   bin/work-log note --category mixed --text "Parallel testing started"
   ```

4. When sequential work changes phase, stop the current session and start one under the new category. Do not relabel already elapsed work unless parallel activity makes separation impossible.
5. Add a note when the activity or outcome materially changes.
6. The primary agent stops the session before the project work pauses or its final response is sent:

   ```text
   bin/work-log stop --outcome "RESULT"
   ```

7. Run `bin/work-log report` whenever a current submission summary is needed.

## Accounting rules

- Use one global wall-clock session. Never sum overlapping agent durations.
- Parallel agents add notes to the active session; they do not stop it.
- Count research, planning, decisions, environment and account setup, coding, tests, debugging, deployment, documentation, waiting on task operations, and submission checks.
- Stop the clock for genuine breaks or unrelated work.
- Use Linear identifiers when they exist. Add later identifiers with `note` if necessary.
- Use `add` only for a verified or explicitly estimated historical interval. Mark estimates with `--estimated`.
- Historical entries that overlap completed or active time are rejected.
- Do not edit `docs/work-log/work-log.jsonl` by hand. The log is append-only.
- Treat `docs/work-log/summary.md` as generated output.
- Reports contain completed entries only. Stop the active session before producing a final submission total.

Valid categories are `planning`, `decision`, `setup`, `implementation`, `testing`, `ui-ux`, `deployment`, `documentation`, `submission`, and `mixed`.

## Completion check

Before reporting project work complete, confirm that:

- `bin/work-log status` shows whether the clock is intentionally active or stopped;
- the latest result is represented by a note or stopped entry;
- `docs/work-log/summary.md` reflects the latest completed entry;
- elapsed time has not been counted twice because of parallel work.
