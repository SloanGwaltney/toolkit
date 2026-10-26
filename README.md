# toolkit

Starting points for the Claude Code skills I reuse across projects. Nothing here is installed or
synced: copy what a project needs, then edit it to fit. The layout mirrors where each file goes in
a project, so copying is a straight move.

## What's here

| Path | What it is |
|---|---|
| `.claude/skills/intent/` | `/intent`: write a feature's intent file in `features/`: its purpose, and the few things it must and must not do, each with a status and a stable ID. |
| `.claude/skills/feature/` | `/feature`: build named intents end to end, with `@intent` annotations in code and tests. |
| `.claude/skills/adr/` | `/adr`: record a decision in `docs/adr/`, linked to the intents it affects. |
| `.claude/skills/research/` | `/research`: compare options for a technical choice and recommend one. |
| `.claude/skills/retro/` | `/retro`: look back on a task for friction and propose fixes. |
| `scripts/check.sh` | One script for every check, run by the Stop hook and CI. A template. |
| `.claude/hooks/check-stop.sh` | Stop hook: runs `scripts/check.sh --no-tests` after each turn and sends Claude back once to fix failures. |

`research` and `retro` stand alone. The rest work as a set with
[speclint](https://github.com/SloanGwaltney/speclint), added to the project as a submodule at
`tools/speclint`. The skills follow the annotation format in its
`tools/speclint/docs/intents.md`, and `feature` runs `speclint` and `spectrace`.

## The spec workflow

Each feature gets an intent file: a paragraph on what it's for, and a short list of what it must
and must not do. It's there to ground whoever works on the feature next, usually an agent starting
with no context, in what the feature is for. It isn't a full specification; the tests are. Code
and tests name the intents they keep with `@intent [#id]` comments, ADRs name the intents they
affect, and `speclint` checks that every link is right and that intent files stay short.

1. `/intent` to write or update the intent file.
2. `/feature features/x.md` to build its `not-implemented` intents, with annotations and tests.
3. `/adr` when building it involved a real decision.

> **v2 is a breaking change.** v1 used `/bdd-feature` to write Gherkin scenarios and linked every
> step to a test. v2 replaces it with `/intent` and markdown intent files, and needs speclint v2.
> See [Moving from v1](#moving-from-v1).

## Using it in a project

From the project root, clone it next to the project's files:

```sh
git clone --depth 1 https://github.com/SloanGwaltney/toolkit tmp-toolkit
mkdir -p .claude/skills
```

Copy a standalone skill:

```sh
cp -r tmp-toolkit/.claude/skills/research .claude/skills/
```

Or, for the spec workflow, copy all of these and add speclint:

```sh
cp -r tmp-toolkit/.claude/skills/{intent,feature,adr} .claude/skills/
mkdir -p .claude/hooks scripts
cp tmp-toolkit/.claude/hooks/check-stop.sh .claude/hooks/
cp tmp-toolkit/scripts/check.sh scripts/
cp -n tmp-toolkit/.gitattributes .        # keeps .sh files LF on Windows
git submodule add https://github.com/SloanGwaltney/speclint tools/speclint
```

Then delete the clone:

```sh
rm -rf tmp-toolkit
```

For the spec workflow, register the Stop hook in `.claude/settings.json`:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash \"$CLAUDE_PROJECT_DIR/.claude/hooks/check-stop.sh\"",
            "timeout": 120,
            "statusMessage": "Running checks"
          }
        ]
      }
    ]
  }
}
```

speclint needs Go 1.22 or later, even in a project that doesn't use Go. Its README covers
configuration (`.speclint.json`) and updating the submodule.

## Customizing

The skills are generic and work as copied. When a project needs more grounding, add it to that
project's copy or to its `CLAUDE.md`.

`scripts/check.sh` has `CUSTOMIZE` markers for the project's formatters, linters, type checks,
and tests.

If the project keeps specs or ADRs somewhere other than `features/` and `docs/adr/`, set
`featuresDir` and `adrDir` in `.speclint.json` and change the paths in the skills.

## Moving from v1

In a project that copied the v1 skills:

1. Update the speclint submodule to v2 and commit the new pointer:

   ```sh
   git -C tools/speclint pull
   git add tools/speclint
   ```

2. Replace the skills, keeping any project-specific edits you made to the old copies:

   ```sh
   git clone --depth 1 https://github.com/SloanGwaltney/toolkit tmp-toolkit
   rm -rf .claude/skills/bdd-feature
   cp -r tmp-toolkit/.claude/skills/{intent,feature,adr} .claude/skills/
   rm -rf tmp-toolkit
   ```

3. Update the doc path in `scripts/check.sh` and `.claude/hooks/check-stop.sh` from
   `docs/spec-annotations.md` to `docs/intents.md`, or copy the new versions.
4. Convert the specs. Follow "Moving from v1" in the speclint README: each `.feature` file becomes
   an intent file, `@scenario` becomes `@intent`, step annotations go, and speclint reports
   whatever's left. Converting a feature is a good task to hand to `/intent` one file at a time,
   with the old `.feature` file as input.
