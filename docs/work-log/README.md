# Work log

This directory contains the append-only time record required for submission.

- `work-log.jsonl`: source-of-truth completed intervals
- `summary.md`: generated human-readable report
- active state: `tmp/work-log/active.json` and intentionally untracked

Use `bin/work-log`; do not edit the data files manually.

## Examples

```text
bin/work-log status
bin/work-log start --category implementation --summary "Implement manual ordering" --issues LET-32,LET-33
bin/work-log note --text "Deployed the first Green version to Render"
bin/work-log note --category mixed --text "Ran parallel system tests"
bin/work-log stop --outcome "Manual order happy path works in development and production"
bin/work-log report
```

For parallel work, keep one active session and add notes describing every concurrent activity. This preserves wall-clock accounting and prevents double-counting.

Stop and restart the session when sequential work changes category. When parallel work crosses categories, promote the active session to `mixed` with `note --category mixed`. Historical entries that overlap an existing or active interval are rejected. Reports contain completed entries only, so stop the clock before generating the final submission total.
