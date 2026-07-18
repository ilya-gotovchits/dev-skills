# dev-skills

Single source of truth for my Agent Skills — rules/workflows for AI coding agents.
The format is shared by **Claude Code** and **opencode**: each skill is a folder with
a `SKILL.md`, linked into `~/.claude/skills/`, where both tools read it.

## Quick start (set up on a new machine)

Prerequisites: `git`, `bash`, and Claude Code and/or opencode.

```sh
# 1. clone anywhere
git clone git@github.com:ilya-gotovchits/dev-skills.git ~/Projects/dev-skills
cd ~/Projects/dev-skills

# 2. link every skill into ~/.claude/skills/
./install.sh

# 3. verify
ls -l ~/.claude/skills/        # pr-review-comments, self-review, … should appear
```

That's it — the skills are now visible to both Claude Code and opencode (both scan
`~/.claude/skills/`).

**Update:** `git pull` — done. The symlinks point into the repo, so changes apply
immediately; after pulling new skills, run `./install.sh` again to link them
(idempotent).

**Custom skills dir:** `CLAUDE_SKILLS_DIR=/path ./install.sh`.

## How it works

`~/.claude/skills/` is read by both tools — Claude Code (its native skills folder)
and opencode (among other locations it also scans `~/.claude/skills/*/SKILL.md`; the
format is identical). One symlink from the repo wires a skill into both at once:

```
~/Projects/dev-skills/pr-review-comments  ──symlink──▶  ~/.claude/skills/pr-review-comments
                                                         ▲            ▲
                                                    Claude Code    opencode
```

`./install.sh` walks every folder containing a `SKILL.md` and creates/updates a
symlink to each. It is idempotent; `--dry-run` previews without changes; it refuses
to overwrite a real (non-symlink) folder of the same name.

## Repo layout

```
dev-skills/
├── shared/            shared methodology core (symlinked into skills' references/)
│   └── review-core.md
├── contracts/         machine contracts between skills
│   └── pr-review.contract.md
├── <skill>/           each skill: SKILL.md + references/ (some are symlinks into shared|contracts)
└── install.sh
```

- **`shared/`** — tone-agnostic methodology reused by several skills. `review-core.md`:
  Principle #0, find-candidates → verification gate, the 4-level severity scale,
  finding anatomy, and the report format (finding block, `Overview`, `Other`).
- **`contracts/`** — a data-format contract between producer/consumer skills.
  `pr-review.contract.md`: frontmatter + parse fields + the finding → GitHub-comment mapping.
- Shared files are wired into a skill by a **relative symlink** from its `references/`
  (it resolves correctly even through the outer symlink in `~/.claude/skills`). Edit
  once, every skill sees it.

## Skills

- **`pr-review-comments`** — review **someone else's** PR: tentative tone, **never
  posts**, writes a paste-ready `.md` of inline comments (core + `pr-review.contract.md`).
- **`self-review`** — review **your own** code (working diff + branch vs base): same
  format/scale, direct tone, **read-only report** (never edits/commits), written to the
  project root. Core, no publisher contract.
- **`pr-comments-publisher`** — *(planned)* reads a review file and posts the comments to
  GitHub on the user's behalf (a pending review); its contract already exists.

## Add a new skill

1. A `<name>/` folder with `SKILL.md` (frontmatter: `name`, `description` — start the description with "Use when…", triggers only).
2. Wire shared files with a symlink: `ln -s ../../shared/review-core.md <name>/references/review-core.md`.
3. `./install.sh` links it. Commit.

## opencode portability

A skill runs in opencode unchanged **as long as it uses no Anthropic-specific calls**.
Rely on portable tooling (`gh`/`git`, MCP servers, plain shell). References to Claude
slash-commands (`/code-review` etc.) in prose are hints for the human, not
dependencies — they're fine.
