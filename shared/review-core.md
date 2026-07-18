# Review core — shared review methodology

Tone-agnostic core shared by the review skills. `pr-review-comments` (someone
else's PR — tentative, never posts, paste-ready) and `self-review` (your own
diff — direct, a punch-list for yourself) both build on this. **The shell skill
owns tone, target, output destination, and frontmatter; this file owns *how you
judge* and *how a finding reads*.** Read it in full before producing findings.

---

## Principle #0 — substance is the repo's

Judgements about the code (what's correct, what's a convention) defer to the
repo: read `CLAUDE.md` / `AGENTS.md` / `.cursor/rules` (auto-attached by `globs:`)
and neighboring code before asserting. No repo rule found → judge more cautiously
and say so. Severity and taxonomy are yours (this file); correctness is the repo's.

## Find candidates → gate

Gather *candidate* findings from two sources:

- **Your own read** of the change set.
- **The built-in `/code-review` as a READ-ONLY finder** — default ON for changes
  that touch code, skipped for docs-only (it's a code reviewer; note the skip).
  Run it **read-only — never `--comment` / `--fix`**; it only surfaces candidates
  (correctness, simplification, efficiency). *Pointing it at the right change set
  is the shell's job* — a PR is a committed branch (expose it as a working diff via
  a merge-base reset), your own work is already the working diff.

**Everything a finder returns is an UNVERIFIED candidate**, exactly like your own
drafts. Cross-model output is not verification. Run every candidate through the
gate below, assign severity + wording yourself, then **dedupe** — one calibrated
finding per issue. Never write "code-review agrees, so it's real."

## Verification before severity (the core — do not skip)

**No severity and no impact claim ships without evidence from the actual code.**
Agreement from a second model (including `/code-review`) or a re-run is NOT
verification — only grepping/tracing the real code (ideally exercising the change)
closes the "did anyone actually check this?" gap. **Overstating impact is the #1
failure mode.**

For each candidate, pull out its factual claims and verify each:

| Claim type | Check | Notes |
|---|---|---|
| blast radius / "used everywhere" | `grep -rn <symbol>` — count real consumers | "shared token" is provable; "breaks half the app" needs the count |
| regression / "this breaks X" | open the consumer, trace the real effect | e.g. a dot that clamps at 8px behaves gentler than it looks |
| "not tested" | grep test files for the case + confirm the spec declares it a contract | separates missing contract from incidental gap |
| "speculative API / no consumer" | grep for consumers of the new input/prop | zero real → holds; any consumer → downgrade/drop |
| "violates convention" | find the actual rule (CLAUDE.md/.cursor/rules) or neighbor pattern, quote it | leans on the repo, not taste |
| "duplicated" | confirm the second copy actually exists | check both locations |

**Calibrate wording to exactly what the check showed.** Couldn't verify? Downgrade
to what's known ("this changes a shared token's semantics", not "this breaks the
app") and lower the severity — never assert to fill the gap.

**When the change is a design / spec doc (not code):** verification maps onto the
doc's *factual claims* — cited paths/files exist, referenced symbols/types/directives
are as described, internal counts reconcile, links resolve, any stated prerequisite
is true today (grep it). Skip the `/code-review` finder (nothing to find in prose).

## Severity (4 levels)

- 🔴 **Critical** — bugs, security, broken behavior, hard `CLAUDE.md`-rule violations. Only with concrete evidence of real breakage/regression/data-loss and confirmed consumers.
- 🟠 **Important** — likely real problems: Nx structure/boundary/tag/naming violations, blast-radius concerns. Evidence-backed.
- 🟡 **Minor** — style, small structural notes, minor improvements. No impact claim required.
- 🔵 **Suggestion** — library extraction, optional refactors — take-it-or-leave-it, explicitly optional.

Group by severity (🔴 → 🟠 → 🟡 → 🔵). Severity ranks the *concern*, never licenses a harsher *tone*.

## Finding anatomy

A finding has three moves: **observation** (what you see) → **why it matters**
(impact, calibrated to what you checked) → **evidence** (the greps/traces that
back it). An optional path-forward is a bonus, never mandated.

## Report format (the artifact)

The value of these skills is a **structured, calibrated, scannable report** — not
a fix. The shell owns the frontmatter (its own metadata) and the visible lead's
*tone*; the body format below is shared.

Open with a short **`## Overview`** — the whole-change read: a one-line verdict
(anything 🔴, or just 🟠/🟡/🔵?), any specific credit, scope/framing notes.
Recommended; skip only if there's genuinely nothing at the whole-change level.

Group findings under severity headings (🔴 / 🟠 / 🟡 / 🔵), a `---` rule between
each. One finding block:

````md
### N. <🔴|🟠|🟡|🔵> <short concern title>

```
file:   <basename.ext>
path:   <path/from/repo-root/to/file.ext>
line:   <NN>
anchor: <exact line text>
```

> <the lead — ONE sentence; this is what gets skimmed. The shell sets tone:
>  a tentative question for someone else's PR, a direct statement for your own.>

<details><summary>Details</summary>

**Why it matters**
- <one distinct point per line; **bold** the key term>

---

**Checked**
- <what you ran → what you found, one per line>

</details>
````

**Two things keep it scannable, not a wall of text:**

- **The locator is a fenced code block on purpose.** Outside a fence, GitHub
  collapses the adjacent `file`/`path`/`line`/`anchor` lines into one run-on
  paragraph; the fence keeps them on separate lines, adds a copy button, and
  renders the `anchor` literally even when it holds backticks/markdown. Each field
  on its own line → copy the full `path` (open/search) or the `anchor` (jump) alone;
  `file` (basename) is the fast scan.
- **Only the lead is visible; everything else folds into one `<details>Details</details>`.**
  Inside, `**Why it matters**` and `**Checked**` are split by a `---` rule. **Two
  registers:** the visible lead is telegraphic; inside the fold (opt-in reading)
  write *expansively* — semantic paragraphs (one facet each), **bold** the key
  claim, bullets only for real enumeration; `Checked` narrates what you set out to
  confirm → how → what it showed, raw commands in a code block. Guardrails: structure
  it (paragraphs + emphasis, never a monolith), and **length never inflates
  certainty** — expand the explanation, keep every claim tied to `Checked`, hedge
  the unverified.

Anything that isn't a line-anchored finding and isn't part of `Overview` goes in an
optional trailing **`## Other`** — cross-cutting/routing notes (e.g. "belongs on a
different PR → design PR #NNNN", off-diff or tooling notes). Omit it when empty.
(`Overview` = the overall read; `Other` = strays that are neither a finding nor part
of that read.)

## The gate as red flags

- Asserting impact you haven't grepped → overstatement. Verify or downgrade.
- No `Checked` section on a finding carrying a severity → you skipped the gate.
- Trusting a finder's severity → cross-model agreement isn't verification. Re-check.
- A surprising "deletion" in a diff → re-check three-dot/merge-base before believing it.
