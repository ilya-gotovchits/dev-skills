---
name: pr-review-comments
description: Use when asked to draft inline review comments for SOMEONE ELSE'S GitHub pull request WITHOUT posting them — produces a paste-ready .md file of tentative comments a human edits and posts manually. Triggers in any phrasing or language, no slash needed: "look at this PR", "review PR #123", "посмотри ПР 12345", "глянь этот пулл-реквест", reviewing a colleague's/teammate's PR before approving. This skill NEVER posts. NOT for your own working diff or auto-posting/fixing a review — that's /code-review; NOT the built-in review / review-pr commands, which post or run multi-agent reviews.
---

# PR Review Comments

## Overview

Turn "look at this PR" into a `.md` file of **inline** review comments — each anchored to a real file + line, tentatively worded, calibrated to evidence, grouped by severity, ready to paste manually.

**Two rules that override everything else:**

- **This skill never posts.** It writes a file. The human reads, edits, and posts. Do not call any GitHub write API, do not comment on the PR, do not approve/request-changes.
- **Principle #0 — style is mine, substance is the repo's.** Comment *style* (tone, anchors, calibration, severity) comes from this skill and is non-negotiable. Judgements about *the code itself* (what's correct, what's a convention) defer to the repo: read `CLAUDE.md` / `AGENTS.md` / `.cursor/rules` / neighboring code first. No repo rules found → judge more cautiously and say so.

## When to use / not

- **Use when:** reviewing *someone else's* PR, producing paste-ready comments, not applying anything.
- **Do NOT use for** your own working diff or applying fixes — that's `/code-review`. Different job: it edits code, this one drafts comments a human posts.

### Sibling tools — when to use which

Several tools answer "review a PR"; they differ by **what they output** and **whether they post**. This skill wins only for the *draft-and-don't-post* case.

| If you want to… | Use | Not this |
|---|---|---|
| Draft tentative inline comments a human edits + posts by hand, on someone else's PR | **this skill** | — |
| Review your own working diff (bugs / simplify), optionally `--comment` or `--fix` | `/code-review` | this skill never touches your diff |
| Have Claude post a review/comments on a PR automatically | `/code-review` / built-in `review` | this skill never posts |
| Run a comprehensive multi-agent PR audit | `/review-pr` (pr-review-toolkit) | this skill is single-pass, comment-drafting only |

If the human clearly wants *drafted comments they post themselves*, this skill is the match even when they just say "review this PR". If they want it posted or it's their own diff, hand off to the sibling above instead of drafting a file.

## Setup (run at the START of every review — make placement unambiguous)

1. From the input (PR URL / number) resolve `org/repo`, PR number, base branch, **head branch + head sha**, title/body, requested reviewers, and the linked design PR if any. Use `gh` or GitHub MCP **for lightweight metadata only** — never pull file contents or per-file patches through the API (`get_pull_request_files` blows past the token limit on large PRs); the change set and file contents come from the local checkout (steps 3–4).
2. Resolve the Jira ticket `EFF-xxxxx` — from the PR branch name; if absent, from the commit messages. If it still can't be resolved, ask the human once; if unavailable, fall back to a `pr-<PR-number>` folder and flag it in the footer — never silently invent a placeholder ticket.
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
4. Get the change set **from the worktree with a three-dot diff**: `git -C <worktree> diff origin/<base>...HEAD`. `A...B` diffs from the **merge-base**, matching GitHub's "Files changed". **Never a two-dot diff** (`origin/<base>..HEAD`) — it folds in commits that landed on the base *after* the branch forked and inflates the change set. **Sanity-check the `--stat`:** if it shows far more than the PR's scale (its `size/*` label / your expectation), the base ref is stale or the clone is shallow → re-fetch (`--unshallow` / enough depth) until the merge-base resolves. Record the head sha (`git -C <worktree> rev-parse HEAD`) for the frontmatter `head_sha`.
5. Output goes to, and only to:
   ```
   code-review/efficiently-EFF-<ticket>/pr-<PR-number>-review-comments.md
   ```

## Verification before severity (the core — do not skip)

**No severity and no impact claim ships without evidence from the checked-out repo.** Agreement from a second model or a re-run is NOT verification — only grepping/tracing the actual code (ideally a human exercising the change) closes the "did anyone actually check this?" gap. **Overstating impact is the #1 failure mode.**

For each draft comment, pull out its factual claims and verify each against the checkout:

| Claim type | Check | Notes |
|---|---|---|
| blast radius / "used everywhere" | `grep -rn <symbol>` — count real consumers | "shared token" is provable; "breaks half the app" needs the count |
| regression / "this breaks X" | open the consumer, trace the real effect | e.g. a dot that clamps at 8px behaves gentler than it looks |
| "not tested" | grep test files for the case + confirm the spec declares it a contract | separates missing contract from incidental gap |
| "speculative API / no consumer" | grep for consumers of the new input/prop | zero real → holds; any consumer → downgrade/drop |
| "violates convention" | find the actual rule (CLAUDE.md/.cursor/rules) or neighbor pattern, quote it | leans on the repo, not taste |
| "duplicated" | confirm the second copy actually exists | e.g. a doc in both this PR and the design PR |

**Calibrate wording to exactly what the check showed.** Couldn't verify? Downgrade to what's known ("this changes a shared token's semantics", not "this breaks the app") and lower the severity — never assert to fill the gap.

**When the PR is a design / spec doc (not code):** verification maps onto the doc's *factual claims* — the cited paths/files exist, the referenced symbols / types / directives are as described, internal counts reconcile, links resolve, and any stated prerequisite is actually true today (grep for it). And the **altitude inverts**: on a design-doc PR, architecture/direction **is** on-topic — engage it here, don't route it away, because this *is* the design PR (conventions §4/§5 assume a code impl PR sitting downstream of an approved design).

Record each check under the **`Checked`** sub-section of the finding's collapsible `<details><summary>Details</summary>` block — visible to the author on a click, but folded so it doesn't clutter the main text (GitHub renders `<details>` in PR comments). The `Details` block holds both `**Why it matters**` and `**Checked**`, split by a `---` rule (see Output format):

```md
**Checked**
- grep -rn "eff-sys-shape-pill" → 3 consumers (dot, chip, tag); dot clamps 8px
```

## Severity

- 🔴 **blocking** — only with concrete evidence of real breakage/regression/data-loss and confirmed consumers.
- 🟠 **non-blocking** — real but non-critical, evidence-backed.
- 🟡 **nit** — style/clarity; no impact claim required.

Group by severity in the file. Every individual comment still stays humble.

## Output format

**The file's exact structure — frontmatter fields and the finding block — is defined in `references/pr-review.contract.md`. Follow it precisely: that file is the contract the `pr-comments-publisher` skill parses to post the comments.** This section is the quick view; the contract is authoritative.

Open the file with **YAML frontmatter** carrying review-level metadata (`pr`, `repo`, `ticket`, `base`, `head_sha`, `counts`), then a short human note:

```md
---
pr: <num>
repo: <owner/repo>
ticket: EFF-<ticket>
base: <base-branch>
head_sha: <pr-head-sha>
counts: { blocking: 0, non_blocking: 0, nit: 0 }
---

# PR #<num> (EFF-<ticket>) — inline review comments

> Anchors point at real files/lines from the checked-out branch. Tone kept tentative on purpose.
```

Then group comments under severity headings (🔴 / 🟠 / 🟡), with a `---` rule between every comment so each block is visually separate. One comment block:

````md
---

### N. <🔴|🟠|🟡> <short concern title>

```
file:   <basename.ext>
path:   <path/from/repo-root/to/file.ext>
line:   <NN>
anchor: <exact line text>
```

> <the ask — one tentative sentence; this is what gets skimmed>

<details><summary>Details</summary>

**Why it matters**
- <one distinct point per line; **bold** the key term>
- <another point — keep each to a line; only what the evidence supports>

---

**Checked**
- <what you ran → what you found, one per line>

</details>
````

Two things keep the file scannable, not a wall of text:

- **The locator is a fenced code block on purpose.** Outside a fence, GitHub collapses the adjacent `file`/`path`/`line`/`anchor` lines into one run-on paragraph; the fence keeps them on separate lines, adds a copy button, and renders the `anchor` literally even when it holds backticks or markdown. Each field on its own line lets the author copy the full `path` (open/search the file) or the `anchor` (jump to the line) alone; `file` (basename) is the fast visual scan.
- **Only the ask is visible; everything else folds into one `<details><summary>Details</summary>` block.** The `>` quote is one tentative sentence. Inside `Details`, `**Why it matters**` and `**Checked**` are split by a `---` rule. **Two registers:** the visible ask is telegraphic; inside the fold (opt-in reading) write *expansively* — semantic paragraphs (one facet each), **bold** the key claim, bullets only for real enumeration; `Checked` narrates what you set out to confirm → how → what it showed, with raw commands in a code block. Guardrails: structure it (paragraphs + emphasis, never a monolith), and **length never inflates certainty** — expand the explanation, keep every claim tied to `Checked`, hedge the unverified.

End with a **footer** routing anything that belongs on a *different* PR (architecture/direction → the design PR, not the impl PR).

## Conventions (comment style — the non-negotiable part)

Read `references/conventions.md` for the full seven, and `references/phrasing.dictionary.md` for the bank of openers/framings to draw tone from. The essentials:

1. **Tentative framing, always** — open with a phrasing from `references/phrasing.dictionary.md`; never an imperative or accusation (its *Avoid* category lists them).
2. **Anchor precisely** — labeled `file` / `path` / `line` / `anchor`, each on its own line (see the contract). One concern per comment.
3. **Calibrate to evidence** — see the verification gate above.
4. **Separate altitudes** — code nits on the impl PR; architecture/direction on the design PR.
5. **Faithful-to-spec ≠ defect** — an impl PR matching an approved design isn't the place to relitigate the design.
6. **No slop-shaming** — credit what's done well; judge the code, not the presumed authoring process.
7. **Group by severity, stay humble per comment.**

## Red flags — STOP, you're about to fail

- Writing "revert this" / "you should" / "please add" → imperative. Rewrite tentatively.
- Asserting app-wide impact you haven't grepped → overstatement. Verify or downgrade.
- Pushing a redesign on an impl PR that faithfully follows an approved design → wrong altitude; move it to the footer/design PR.
- No `Checked` section in the `<details>Details</details>` block on a comment carrying a severity → you skipped the gate.
- About to post/approve/request-changes → STOP. You only write the file.

## Rationalization table

| Excuse | Reality |
|---|---|
| "I can't check the repo but the concern is obvious" | Then downgrade the wording and severity. Obvious-feeling ≠ verified. |
| "It's faster to just tell them to revert" | Directives skip the owner's judgement. Frame it as a question. |
| "The design itself is questionable" | Not on the impl PR. Footer → design PR. |
| "A second opinion agrees, so it's confirmed" | Cross-model agreement isn't verification. Grep the code. |
| "Quoting the line is enough, I'll skip the line number" | Real line numbers are cheap now — you have the checkout. Use them. |
