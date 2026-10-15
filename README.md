# toolkit

Starting points for the Claude Code skills I reuse across projects. Nothing here is installed or
synced: copy what a project needs, then edit it to fit. The layout mirrors where each file goes in
a project, so copying is a straight move.

## What's here

| Path | What it is |
|---|---|
| `.claude/skills/bdd-feature/` | `/bdd-feature`: write Gherkin-like specs in `features/`, each scenario with a status and a stable ID. |
| `.claude/skills/feature/` | `/feature`: build named scenarios end to end, with spec annotations in code and tests. |
| `.claude/skills/adr/` | `/adr`: record a decision in `docs/adr/`, linked to the scenarios it affects. |
| `.claude/skills/research/` | `/research`: compare options for a technical choice and recommend one. |
| `.claude/skills/retro/` | `/retro`: look back on a task for friction and propose fixes. |
| `scripts/check.sh` | One script for every check, run by the Stop hook and CI. A template. |
| `.claude/hooks/check-stop.sh` | Stop hook: runs `scripts/check.sh --no-tests` after each turn and sends Claude back once to fix failures. |

`research` and `retro` stand alone. The rest work as a set with
[speclint](https://github.com/SloanGwaltney/speclint), added to the project as a submodule at
`tools/speclint`. The skills follow the annotation format in its
`tools/speclint/docs/spec-annotations.md`, and `feature` runs `speclint` and `spectrace`.

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
cp -r tmp-toolkit/.claude/skills/{bdd-feature,feature,adr} .claude/skills/
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
