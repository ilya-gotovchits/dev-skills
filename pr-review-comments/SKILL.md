---
name: pr-review-comments
description: Use when asked to review someone else's GitHub pull request and produce paste-ready inline review comments — "look at this PR", "write review comments for PR #123", reviewing a colleague's/teammate's PR before approving. NOT for reviewing your own working diff (use /code-review for that).
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

## Setup (run at the START of every review — make placement unambiguous)

1. From the input (PR URL / number) resolve `org/repo`, PR number, base branch, title/body, and the linked design PR if any. Use `gh` CLI or GitHub MCP for metadata.
2. Resolve the Jira ticket `EFF-xxxxx` — from the PR branch name; if absent, from the commit messages. If it still can't be resolved, ask the human once; if unavailable, fall back to a `pr-<PR-number>` folder and flag it in the footer — never silently invent a placeholder ticket.
3. **Check out the PR branch into a per-PR folder** so you review *real files with real line numbers*, not the diff's approximate ones:
   ```
   code-review/efficiently-EFF-<ticket>/
   ```
   Clone the repo there and `gh pr checkout <number>` (or reuse/update the folder if it already exists). Working with real files means anchors are exact and you never fetch file contents through separate API calls.
4. Get the change set with `gh pr diff` / `git diff <base>...<pr-branch>` to know *which* files/lines belong to the PR, then map them onto the checked-out files.
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

Record each check as a **hidden note directly above the comment** (invisible when pasted into GitHub):

```md
<!-- checked: grep -rn "eff-sys-shape-pill" → 3 consumers (dot, chip, tag); dot clamps 8px -->
```

## Severity

- 🔴 **blocking** — only with concrete evidence of real breakage/regression/data-loss and confirmed consumers.
- 🟠 **non-blocking** — real but non-critical, evidence-backed.
- 🟡 **nit** — style/clarity; no impact claim required.

Group by severity in the file. Every individual comment still stays humble.

## Output format

```md
# PR #<num> (EFF-<ticket>) — inline review comments

> Anchors point at real files/lines from the checked-out branch. Tone kept tentative on purpose.

<!-- checked: <what you ran → what you found> -->
### N. `path/to/file` — line ~NN
Anchor: `<exact line text>`

> <tentative comment, one concern>
```

End with a **footer** routing anything that belongs on a *different* PR (architecture/direction → the design PR, not the impl PR).

## Conventions (comment style — the non-negotiable part)

Read `references/conventions.md` for the full seven. The essentials:

1. **Tentative framing, always** — open with `looks like` / `perhaps` / `I think` / `I wonder if` / `might be worth`. No imperatives, no "this is wrong", no "revert this".
2. **Anchor precisely** — real `path — line ~N` + quote the anchor line. One concern per comment.
3. **Calibrate to evidence** — see the verification gate above.
4. **Separate altitudes** — code nits on the impl PR; architecture/direction on the design PR.
5. **Faithful-to-spec ≠ defect** — an impl PR matching an approved design isn't the place to relitigate the design.
6. **No slop-shaming** — credit what's done well; judge the code, not the presumed authoring process.
7. **Group by severity, stay humble per comment.**

## Red flags — STOP, you're about to fail

- Writing "revert this" / "you should" / "please add" → imperative. Rewrite tentatively.
- Asserting app-wide impact you haven't grepped → overstatement. Verify or downgrade.
- Pushing a redesign on an impl PR that faithfully follows an approved design → wrong altitude; move it to the footer/design PR.
- No `<!-- checked -->` above a comment carrying a severity → you skipped the gate.
- About to post/approve/request-changes → STOP. You only write the file.

## Rationalization table

| Excuse | Reality |
|---|---|
| "I can't check the repo but the concern is obvious" | Then downgrade the wording and severity. Obvious-feeling ≠ verified. |
| "It's faster to just tell them to revert" | Directives skip the owner's judgement. Frame it as a question. |
| "The design itself is questionable" | Not on the impl PR. Footer → design PR. |
| "A second opinion agrees, so it's confirmed" | Cross-model agreement isn't verification. Grep the code. |
| "Quoting the line is enough, I'll skip the line number" | Real line numbers are cheap now — you have the checkout. Use them. |
