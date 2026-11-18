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

## Design rules

Decided by the author on 2026-11-18. Sources: the author's design policy, texta.fm episode 3 "Low-Code Development", and 『パーフェクト Ruby on Rails』 Part 5. The acceptance bar for this assignment is that the author can explain every line of the final code. Prefer simple code over clever code; if a line cannot be explained plainly, simplify or rewrite it.

- Model facts, not procedures. Represent an operation as creating a domain record (for example, a payment is a Payment record that gets created, not a payment service that runs).
- Fat Model, Skinny Controller. Express queries as model scopes and class methods. Put validations in the model and duplicate them with DB constraints.
- The tools from Part 5 are normal tools, not exceptions: value objects, models not backed by a database table, form objects, concerns, and callback objects. Form objects are models and live in `app/models`.
- Tests: write each `it` description as a simple sentence that reads as the specification. Keep the test pyramid in mind.
- Writing split (t-wada): How goes in code, What goes in tests, Why goes in commit messages, Why not goes in code comments.
- コードの説明コメントは日本語で書く。新規・変更されたRubyのコメントは `bin/check-ruby-comments` で確認する。
- ADRs sparingly: only for architecture-wide decisions, decisions not tied to a specific file, and library adoption. The latest decision must be understandable from the latest code alone.
- Verification: verify through correct linters and tests, not through adversarial review of generated code. When a rule can be enforced by RuboCop or a spec, enforce it there instead of relying on review.

Run `bin/rubocop` and `bundle exec rspec`. Machine-checkable design rules live in `.rubocop.yml` and `spec/design_rules_spec.rb`.

## Interface design

Follow the visual design guidance in [unslop by Damir Sokolovsky](https://github.com/heydamir/unslop) for prototypes and product screens. Give the next input or action visual priority. Keep labels, status and instructions that help people act. Omit slogans, decorative badges and headings that repeat what the form already says.

## Decisions and progress

- Before implementing a UX change, prepare a simple interactive HTML prototype for the affected ticket, with brief explanations and one main successful journey. Align on the screen order, inputs, and destination; do not turn the prototype into an exhaustive error or boundary-case simulator. Work out detailed validation and error conditions with TDD when implementing the product.
- Link the prototype from Linear and obtain the user's explicit review approval before implementing the production flow. Record the approval and prototype revision. If the agreed experience changes, review that change before implementation. Prototype preparation and time passing are not approval. Internal changes without a UX change do not need this gate; Markdown/Mermaid may accompany the HTML as supporting material.
- Treat discussion questions as requests for explanation, not as rejection, approval, or instructions to change a decision. Explain the rationale and options; change an agreed policy only when the user explicitly requests or approves the change. Mark unresolved proposals clearly.

- Record significant technical and process decisions in `docs/adr/`.
- Keep implementation progress, time budgets, dependencies, and pending decisions in the Linear project `ひるどき 技術試験`.
- An accepted decision is not complete until its ADR and Linear issue agree.
- Keep `docs/requirements/traceability.md` aligned with PDF requirements and their Linear tickets. When completing a slice, record the covered requirement IDs, spec paths/results, and production verification evidence in the ticket and the document's evidence table. Ticket creation alone is not evidence of implementation.
