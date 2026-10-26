---
name: intent
description: Write or update a feature's intent file in features/*.md, stating the few things the feature must and must not do, each with a status (not-implemented, implemented, deprecated, withdrawn) and a stable ID. Use when the user describes a feature, behavior, or requirement and wants it written down as intents or a spec, or invokes /intent.
---

# intent

Turn a user's description of a feature into an **intent file**: a short statement of what the
feature is for and what it must and must not do. Code and tests point back at each intent by ID,
and `speclint` checks those links. The full format is in `tools/speclint/docs/intents.md`; read
it before writing.

## What belongs in an intent file

An intent file grounds whoever works on the feature next, usually an agent starting with no
context. It answers: what is this for, and what would make it wrong? It is **not** a list of
every behavior. Tests define behavior in detail; the intent file names the obligations those
tests exist to protect.

An obligation earns an intent when **a reviewer would reject a change that broke it, and you could
explain why to someone who doesn't read code.** Everything else (validation rules, boundary
values, error messages, UI details, retries) belongs in tests, not here.

| Intent                                              | Not an intent (leave it to tests)            |
|-----------------------------------------------------|----------------------------------------------|
| A cancelled call never produces a reminder.         | The lead time can't be negative.             |
| A card can be moved to any status on the board.     | Dragging a card shows a drop shadow.         |
| An order is never charged twice.                    | The card number field rejects letters.       |
| Only the owner of a board can delete it.            | The delete button is red.                    |

Aim for **two to six intents per feature.** If you find yourself writing more than that, you're
listing behaviors: keep the ones the feature would be wrong without, and mention the rest in
notes or leave them to tests. If the feature genuinely has more, it's probably two features;
split the file. speclint warns past 8 intents in a file or 4 on one entry point.

Don't skip **Must not**. Prohibitions ("never charges twice," "never shows another user's
data") are often the most valuable intents, because code rarely says what it's careful not to do.

## Writing an intent

```markdown
- @id:cancelled-no-reminder @status:not-implemented
  A cancelled call never produces a reminder.

  Cancellation can arrive after the reminder is queued, so this has to be
  checked at send time, not schedule time.
```

- **The statement is one sentence** that names when the intent applies and what must (or must
  not) be true. Write it in the domain's language, from the user's point of view, with no UI
  selectors, API calls, or implementation details.
- **Keep it general.** "When a call's lead time arrives, the person is reminded," not "Given a call
  at 3:00 PM, when it's 2:45 PM, then a reminder appears." A specific number belongs in the
  statement only when the number is the requirement ("at least 15 minutes before").
- **Notes go under the statement after a blank line:** why the intent exists, cases that are easy
  to get wrong, decisions that shape it, links to ADRs. Use them freely; they're what makes an
  intent useful to the next reader, and they don't count toward any limit.
- **IDs** are short kebab-case derived from the statement, unique across every file in
  `features/`. Grep `features/` for `@id:<id>` before using one.

## Change rules

Read the file first, every time you edit one.

1. **New intents are `@status:not-implemented`** and can go in any file.
2. **Notes can always change**, on any intent that isn't withdrawn.
3. **An implemented intent's statement can be clarified, not changed.** Rewording for clarity is
   fine. If the request changes what the intent promises, that's a replacement (rule 4).
4. **Changing what's promised means replacing it.** Tag the old intent `@status:deprecated`, and
   write the new one as `@status:not-implemented` with a new ID and `Replaces: @id:<old-id>` in
   its notes.
5. **Deprecated can only move to withdrawn.** Don't edit its statement or build on it.
6. **Withdrawn is final.** Don't edit or un-withdraw it. If the behavior comes back, write a new
   intent. Withdrawn intents can stay as a record.
7. **Status only moves forward:** `not-implemented → implemented → deprecated → withdrawn`. A
   `not-implemented` intent that's dropped before it's built can be deleted outright. Only change
   a status to `implemented` when the user says it's built.

If the user asks for something that breaks a rule, don't do it silently. Say which rule it hits
and propose the compliant alternative.

## Workflow

1. **Understand the request.** If the feature's purpose, who it's for, or what it must never do is
   unclear and you can't infer it, ask a short list of questions before drafting. Don't ask about
   details that belong in tests; state reasonable assumptions instead.
2. **Find existing intents.** Look under `features/` (create it if missing) for a file covering
   the same area. If one exists, you're editing it, so apply the change rules.
3. **Draft.** For a new file:
   - Name it in kebab-case, e.g. `features/call-reminders.md`.
   - Start with `# <Feature name>` and a purpose paragraph: what the feature is for, who it serves,
     and any constraint that shapes every intent in it.
   - List intents under `## Must` and `## Must not`.
   - Add an `## Out of scope` section when there's an obvious neighbor the feature deliberately
     doesn't cover. It isn't checked and can hold plain bullets.
4. **Check the size.** Count the active intents. If there are more than six, go back to "What
   belongs" and cut, move detail to notes, or split the file.
5. **Lint.** Run `go run -C tools/speclint ./cmd/speclint -root ../..` and fix what it reports
   for the files you touched.
6. **Report.** Summarize the files written, each intent added or changed with its ID and status,
   assumptions you made, details you deliberately left to tests, any requests you redirected
   because of the change rules, and open questions.

## Example

```markdown
# Call reminders

Reminds people before a scheduled call so they don't miss it. Reminders are
local to the device; there's no server push, so the app has to be running.

## Must

- @id:default-lead-time @status:implemented
  When a call's reminder lead time arrives, the person is reminded of that call.

  The default lead time is 15 minutes; each call can override it.

- @id:reminder-chosen-sound @status:not-implemented
  A reminder plays the sound chosen in settings.
  Replaces: @id:reminder-default-sound

- @id:reminder-default-sound @status:deprecated
  A reminder plays the default sound.

- @id:sms-reminder @status:withdrawn
  Reminders are sent by SMS.

## Must not

- @id:cancelled-no-reminder @status:implemented
  A cancelled call never produces a reminder.

  Cancellation can arrive after the reminder is queued, so this is checked at
  send time, not schedule time. See docs/adr/0004-queue-reminders.md.

## Out of scope

- Syncing calls from external calendars; that's the calendar feature.
```

A request like "let users snooze reminders" is a new capability, so it's a new intent:
"A reminder can be snoozed and comes back later." The snooze length, the maximum number of
snoozes, and what the button says are details for tests, not more intents.
