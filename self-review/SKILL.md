---
name: self-review
description: Use when asked to review YOUR OWN uncommitted work or branch and produce a structured report — "review my code", "review my diff", "check my changes", "before I push", "отревьюй мой код", "проверь мои изменения". Produces a calibrated report only — it NEVER edits, fixes, commits, or posts. For someone else's PR use pr-review-comments; to auto-fix your diff use /code-review.
---

# Self Review

Review your own changes — uncommitted work and/or your branch vs its base — into a structured, calibrated report you act on. Same taxonomy and report format as a PR review, but a **direct tone** (it's your code) and **your working repo** (not a throwaway PR checkout).

**REQUIRED CORE:** the review methodology — Principle #0, find-candidates → verification gate, the 4-level severity taxonomy, finding anatomy, and the report-body format (finding block, `Overview`, `Other`, scannability) — lives in **`references/review-core.md`**. Read it. This skill is the *own-code shell* over that core.

**Two rules that override everything else:**

- **This skill NEVER mutates the repo and NEVER fixes.** Report only. No edits, no `git commit` / `reset` / `stash` / `checkout` / `add` on the working repo, no posting. You produce a `.md` punch-list; the human (or `/code-review --fix`) acts on it. The one exception is an *isolated throwaway worktree* for the finder (see below) — never the real branch/tree/index.
- **Principle #0 — style is mine, substance is the repo's** (core). Severity/taxonomy are this skill's; correctness/conventions defer to the repo (`CLAUDE.md` / `AGENTS.md` / `.cursor/rules` / neighbors).

## When to use / not

- **Use when:** reviewing *your own* changes and you want a structured report to understand what to fix — not an auto-fix.
- **Not this skill:** someone else's PR → `pr-review-comments`; auto-fix your working diff → `/code-review` (this skill's value is the *report*, which `/code-review` doesn't leave behind).

## Setup

1. **Scope = everything that differs from the base** (both parts):
   - **Committed on branch:** `git diff <base>...HEAD` (three-dot, from the merge-base — never two-dot; a surprising "deletion" usually means the base advanced past your fork, re-check three-dot).
   - **Uncommitted:** `git diff HEAD` (staged + unstaged) + untracked files.
   - **Base inference:** the branch's fork point from the main integration branch (`git merge-base HEAD origin/<default-or-integration>`). If the base is ambiguous, ask once.
2. **Record** the repo, branch, `base`, and `head_sha` (`git rev-parse HEAD`) for the report frontmatter. Read files at their real paths for exact line numbers — never mutate to inspect.
3. **Output** goes to the repo root: `self-review-<branch>.md`. Keep it **untracked** — suggest the human add `self-review-*.md` to `.gitignore` once. (Alt: the scratchpad, if they'd rather keep it out of the repo entirely.)

## Find candidates → verify → severity → format

The gate, taxonomy, and report-body format are **in `references/review-core.md`** — follow it. Own-code specifics:

- **Finder (`/code-review`), read-only, no `--comment`/`--fix`.**
  - **Default (A):** run it on the **uncommitted working diff** as-is — no reset needed, it's already the working tree. The **committed-on-branch** part I review by my own read + the gate (nothing goes unreviewed; it just doesn't get the extra `/code-review` opinion).
  - **Deep (B) — opt-in, or automatic when the tree is clean** (all changes are committed, so there's no working diff for the finder to see): spin an **isolated detached `git worktree`** at `HEAD`, `git reset --soft "$(git merge-base <base> HEAD)"` **inside that throwaway worktree**, run `/code-review` there, then remove it. The real branch/tree/index are never touched.
  - Everything a finder returns is an **unverified candidate** (core's gate) — assign severity/wording yourself, dedupe.
- **Tone: direct, not tentative.** The visible lead is a **statement**, not a question ("`block-size` clips the label under text-spacing" — not "I wonder if…"). Same finding block, severity, and folded `Details` (Why / Checked) from the core; just drop the diplomatic framing — it's your own code.
- **Report frontmatter** (lighter than a PR — no publisher, no ticket needed):
  ```yaml
  ---
  repo: <owner/repo>
  branch: <your-branch>
  base: <base-branch>
  head_sha: <sha>
  counts: { critical: 0, important: 0, minor: 0, suggestion: 0 }
  ---
  ```
  Then `# Self-review — <branch>`, the `## Overview`, severity groups, and (if any) `## Other` — all per the core.
- **Fix handoff:** report only. Note in the `Overview` that 🔴/🟠 items can be handed to `/code-review --fix` or fixed deliberately — this skill doesn't touch code.

## Red flags — STOP

- About to edit / `git reset` / `commit` / `stash` a file to "make the diff reviewable" → STOP. Only the throwaway worktree may be reset; the real repo is read-only.
- About to auto-fix a finding → STOP. This skill reports; it never fixes.
- Plus the core's gate red flags — no `Checked`, unverified impact claims, trusting a finder's severity, surprising diffs (re-check three-dot).
