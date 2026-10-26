---
name: feature
description: Implement intents from features/*.md that the user names, annotating the entry points that keep them with @intent, writing tests that check each one, and running the checks before finishing. Use when the user invokes /feature with intent references.
argument-hint: <features/x.md#intent-id ...>
disable-model-invocation: true
---

# feature

Build the intents the user names, end to end, so each one can be found from the code that keeps
it and the tests that check it with a text search.

Arguments: $ARGUMENTS

Before writing code, read `tools/speclint/docs/intents.md` for the annotation format. This skill
doesn't repeat it.

## 1. Resolve the intents

The user passes the intents to build. Accept any of these forms:

- `features/job-board.md#move-card-forward`: one intent
- `move-card-forward`: a bare ID. Search `features/` for `@id:move-card-forward`.
- `features/job-board.md`: every `@status:not-implemented` intent in that file

If no arguments were given, list the `@status:not-implemented` intents in `features/`, grouped by
file, and ask which to build. Don't pick for the user.

For each intent, read it and its file's purpose, and check its status:

| Status            | What to do                                                                 |
|-------------------|----------------------------------------------------------------------------|
| `not-implemented` | Build it.                                                                  |
| `implemented`     | Already built. Ask whether the user wants a change; if so, that's a change for the `intent` skill first. |
| `deprecated`      | Don't build on it. Tell the user and skip it.                              |
| `withdrawn`       | Don't build it. Tell the user and skip it.                                 |

If a reference doesn't match any intent, say so and ask. Never guess an ID.

An intent states an obligation, not every detail of the behavior. Fill in reasonable details
yourself, following the codebase's existing patterns and the intent's notes, and list the ones
you chose in the report. Ask first only when a detail changes what the intent promises, or when
two reasonable readings would build different things. Don't edit intent files in this skill,
apart from the status change in step 7.

## 2. Gather context

- **Intents.** Read the whole intent file, not only the intents you're building: the purpose and
  the other intents, especially the **Must not** ones, constrain how you build these.
- **Decisions.** Grep `docs/adr/` for each intent ID and its file, and read the ADRs that come up,
  plus the `universal` ones relevant to the code you'll touch.
- **Existing code.** Grep for the IDs of the file's implemented intents to find the entry points
  and tests already linked to the feature.

## 3. Plan

Before editing, give the user a short plan: for each intent, the entry point that will carry its
`@intent` annotation, and the code it touches. Then proceed unless the plan needs one of the
following, which must be raised and settled first:

- **A new dependency** (a package, module, or tool). Never install one without asking, and say
  why it's worth adding over writing the code ourselves.
- **A decision worth recording**: a real choice between alternatives that later work will build
  on, like picking a library or a data model trade-off that isn't settled by an existing ADR.
  Suggest the user run `/adr`. Don't write ADRs yourself. Building something the usual way, like
  a new table, a read-only view, or a page that follows an existing pattern, isn't a decision, so
  don't suggest one for it, and don't add ADR notes to PR descriptions.

## 4. Implement

Follow the patterns the codebase already uses. Annotate as you write, not at the end:

- `@intent [#<id>]` on each **entry point** that keeps the intent. If the entry point already has
  an `@intent` line, add the new ID to the end of it rather than adding a second line.
- Use the language's comment syntax (see `tools/speclint/docs/intents.md`). Each annotation goes on
  its own comment line.

If an entry point ends up naming more than four intents, speclint warns. Treat that as a design
signal: the entry point may be doing too much. Mention it in the report rather than working around
it.

## 5. Test

Every intent gets at least one test that checks it, with `@intent [#<id>]` on the test function,
or on the subtest or `it` block when one function covers several intents. Write tests the way the
project's existing ones are written.

- **Test the obligation where it's decided.** If the code that decides an outcome is separate from
  the code that shows it, test each one there, and annotate the test that proves the obligation.
- **For a Must not intent,** set up the situation where it could be broken and check that it
  isn't: the cancelled call gets no reminder, the second charge is refused.
- **Test the details too.** The edge cases, validation, and error handling you filled in during
  step 4 get ordinary tests without annotations. The intent names the obligation; these tests
  pin down the rest.

## 6. Verify

Run the project's checks and tests, and fix every failure before finishing. If the project has
`scripts/check.sh`, that runs them all:

```sh
bash scripts/check.sh
```

`speclint` only reports *missing* links for `@status:implemented` intents, so while the intents
are still `not-implemented` it won't notice one you forgot. Check each one with `spectrace`, which
exits 1 with a `MISSING:` line for an intent with no `@intent` link in code or in tests:

```sh
go run -C tools/speclint ./cmd/spectrace -root ../.. <intent-id>
```

Or trace the whole file to see every intent at once:

```sh
go run -C tools/speclint ./cmd/spectrace -root ../.. features/<file>.md
```

Fix every `MISSING:` line for the intents you built.

## 7. Report

Finish with:

- The intents built, each with its entry point and test as `file:line`.
- The details you chose that the intents didn't state, briefly, so the user can push back.
- Test results: the commands run and whether they passed. If something still fails, say so with
  the output rather than finishing quietly.
- Anything skipped or left open: deprecated or withdrawn intents, questions, limit warnings, and
  an `/adr` suggestion only if step 3 raised a real decision.
- A request to the user to confirm the intents are built. Don't change a status to
  `@status:implemented` yourself. When the user confirms, flip the tags, then run
  `go run -C tools/speclint ./cmd/speclint -root ../..` again. With the intents now
  `implemented`, it checks that each one is linked in code and tests.
