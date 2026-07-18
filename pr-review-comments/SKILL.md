---
name: pr-review-comments
description: Use when asked to review SOMEONE ELSE'S GitHub PR and draft inline comments a human edits and posts by hand — this skill NEVER posts. Triggers, any language/phrasing: "look at this PR", "review PR #123", "посмотри ПР 12345", "глянь пулл-реквест". NOT your own working diff or an auto-posted/auto-fixed review (that's /code-review); NOT the built-in review / review-pr (they post or run multi-agent reviews).
---

# PR Review Comments

Turn "look at this PR" into a `.md` file of **inline** review comments — anchored to a real file + line, tentatively worded, calibrated to evidence, grouped by severity, ready to paste manually.

**REQUIRED CORE:** the review methodology — Principle #0, the find-candidates → verification gate, the 4-level severity taxonomy, and the report-body format (finding block, `Overview`, `Other`, scannability) — lives in **`references/review-core.md`**. Read it. This skill is the *someone-else's-PR shell* over that core: it adds tone (tentative), the never-posts rule, PR checkout mechanics, and the publisher-ready output.

**Two rules that override everything else:**

- **This skill never posts.** It writes a file. The human reads, edits, and posts. Do not call any GitHub write API, do not comment on the PR, do not approve/request-changes.
- **Principle #0 — style is mine, substance is the repo's** (core). Comment *style* (tone, calibration, severity) is non-negotiable here; judgements about the code defer to the repo (`CLAUDE.md` / `AGENTS.md` / `.cursor/rules` / neighbors).

## When to use / not

- **Use when:** reviewing *someone else's* PR, producing paste-ready comments, not applying anything.
- **Do NOT use for** your own working diff — that's `self-review` (report) or `/code-review` (fix). This skill drafts comments a human posts on another author's PR.

### Sibling tools — when to use which

| If you want to… | Use |
|---|---|
| Draft tentative inline comments a human posts by hand, on **someone else's** PR | **this skill** |
| A structured, calibrated report on **your own** diff (same taxonomy/format, direct tone) | `self-review` |
| Review your own working diff and optionally `--comment` / `--fix` it | `/code-review` |
| Post a review automatically, or run a multi-agent PR audit | built-in `review` / `/review-pr` |

If the human wants *drafted comments they post themselves*, this skill is the match even when they just say "review this PR".

## Setup (run at the START of every review — make placement unambiguous)

1. From the input (PR URL / number) resolve `org/repo`, PR number, base branch, **head branch + head sha**, title/body, requested reviewers, and the linked design PR if any. Use `gh` or GitHub MCP **for lightweight metadata only** — never pull file contents or per-file patches through the API (`get_pull_request_files` blows past the token limit on large PRs); the change set and file contents come from the local checkout (steps 3–4).
2. Resolve the Jira ticket `EFF-xxxxx` — from the PR branch name; if absent, from the commit messages. If it still can't be resolved, ask the human once; if unavailable, fall back to a `pr-<PR-number>` folder and flag it in the `Overview` — never silently invent a placeholder ticket.
3. **Check the PR out into a per-PR folder as a `git worktree`** so you review *real files with real line numbers*, not the diff's approximate ones:
   ```
   code-review/efficiently-EFF-<ticket>/
   ```
   - **Prefer an existing local clone** of the repo (look for a sibling checkout first). Into it, **fetch both the base and head refs fresh** — so `origin/<base>` is the real remote tip, not a stale one — then add a **detached** worktree pinned to the PR head sha:
     ```
     git -C <clone> fetch origin <headRef>:refs/remotes/origin/<headRef> <baseRef>:refs/remotes/origin/<baseRef>
     git -C <clone> worktree add --detach code-review/efficiently-EFF-<ticket> <head_sha>
     ```
     The worktree is detached at the head sha — independent of whatever branch the clone sits on, and it never disturbs the clone's working tree. A husky / `post-checkout` hook may exit non-zero on checkout — the checkout still succeeded; don't treat it as a failure.
   - **Fallback if no local clone exists — use git, not the API.** `git clone <clone_url>` (prefer `--filter=blob:none`: keeps full history so the merge-base resolves, skips unneeded blobs), then fetch refs + worktree as above. `gh pr checkout` is fine when `gh` is installed, but `gh` is optional — plain `git` is the baseline; never reconstruct the tree from `get_pull_request_files` / `get_file_contents`.
   - Reuse/update the folder if it already exists.

   Working with real files means anchors are exact and you never fetch file contents through the API.
4. Get the change set **from the worktree with a three-dot diff**: `git -C <worktree> diff origin/<base>...HEAD`. `A...B` diffs from the **merge-base**, matching GitHub's "Files changed". **Never a two-dot diff** (`origin/<base>..HEAD`) — it folds in commits that landed on the base *after* the branch forked and inflates the change set. **Per-file inspection is three-dot too:** `git diff origin/<base>...HEAD -- <file>`, never `git diff origin/<base> -- <file>` — against an advanced base tip, two-dot shows post-fork base commits *as if this PR deleted them* (phantom deletions that read as a scary 🔴; on the EFF-22950 run this faked a whole `eff-status` removal). If a "deletion" looks surprising, re-check three-dot before believing it. **Sanity-check the `--stat`:** if it shows far more than the PR's scale (its `size/*` label / your expectation), the base ref is stale or the clone is shallow → re-fetch (`--unshallow` / enough depth) until the merge-base resolves. Record the head sha (`git -C <worktree> rev-parse HEAD`) for the frontmatter `head_sha`.
5. Output goes to, and only to:
   ```
   code-review/efficiently-EFF-<ticket>/pr-<PR-number>-review-comments.md
   ```

## Find candidates → verify → severity → format

All four are **defined in `references/review-core.md`** (find-candidates→gate, the verification table, the 4-level severity, the report-body format). Read it and follow it. Only the PR-specific wiring lives here:

- **Diff exposure for the `/code-review` finder.** The finder reviews a *working diff*, but the PR is committed. Reset **to the merge-base, not the base tip**: `git -C <worktree> reset --soft "$(git -C <worktree> merge-base origin/<base> HEAD)"` — stages the whole PR (new files included) as the working diff without touching file contents or line numbers. **Soft, and merge-base, matter:** `--mixed`/`--hard`, or resetting to `origin/<base>` (an advanced tip), makes `/code-review` review a stale two-dot diff full of *phantom deletions*. Treat its output as candidates regardless (core's gate).
- **Frontmatter + publisher mapping** are the PR-specific contract in **`references/pr-review.contract.md`** — the file the `pr-comments-publisher` skill parses. The report *body* format is core; the frontmatter (`pr`/`repo`/`ticket`/`base`/`head_sha`/`counts`) and the finding→GitHub-inline-comment mapping are there. Follow it.

## Conventions (comment style — the non-negotiable tone layer)

The core sets *how you judge*; this shell sets *how the comment reads to another author*. Read `references/conventions.md` for the full seven and `references/phrasing.dictionary.md` for the bank of openers/framings. The essentials:

1. **Tentative framing, always** — the visible lead is a *question*, opened with a phrasing from the dictionary; never an imperative or accusation (its *Avoid* list). (In `self-review` this flips to a direct statement — same finding, different shell.)
2. **Anchor precisely** — labeled `file` / `path` / `line` / `anchor` (core's locator block). One concern per comment.
3. **Separate altitudes** — code nits on the impl PR; architecture/direction → the design PR (route via `Other`).
4. **Faithful-to-spec ≠ defect** — an impl PR matching an approved design isn't the place to relitigate the design.
5. **No slop-shaming** — credit what's done well; judge the code, not the presumed authoring process.

## Red flags — STOP, you're about to fail

- Writing "revert this" / "you should" / "please add" → imperative on someone else's PR. Rewrite tentatively.
- Pushing a redesign on an impl PR that faithfully follows an approved design → wrong altitude; move it to `Other` / the design PR.
- About to post/approve/request-changes → STOP. You only write the file.
- (Plus the core's gate red flags — no `Checked`, unverified impact claims, trusting a finder's severity, surprising diffs.)

## Rationalization table

| Excuse | Reality |
|---|---|
| "I can't check the repo but the concern is obvious" | Then downgrade the wording and severity. Obvious-feeling ≠ verified. |
| "It's faster to just tell them to revert" | Directives skip the owner's judgement. Frame it as a question. |
| "The design itself is questionable" | Not on the impl PR. Route it → design PR (`Other`). |
| "A second opinion agrees, so it's confirmed" | Cross-model agreement isn't verification. Grep the code. |
