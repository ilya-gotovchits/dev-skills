# PR review file — data contract

The `.md` this skill writes is dual-purpose: a human reads/edits/pastes it, **and** a companion skill (`pr-comments-publisher`) parses it to post the comments. This file is the contract between the two.

Structure below is **required and stable** — a consumer relies on it. *How a comment reads* (tone, calibration, phrasing) lives in `conventions.md`, not here; this file is only *what a comment is made of*.

**Malformed-block rule (applies throughout):** a consumer that finds a block violating this contract MUST skip that block and flag it — never post a half-parsed or wrong-anchored comment. A skipped finding beats a misplaced one.

---

## 1. File-level frontmatter (the "overview")

YAML frontmatter at the top carries review-level metadata:

```yaml
---
pr: 57866                       # PR number (int)
repo: efficiently/efficiently   # owner/repo
ticket: EFF-24180               # Jira ticket, or pr-<N> fallback
base: main                      # base branch
head_sha: a1b2c3d4              # HEAD commit of the PR branch at review time —
                                # the commit inline comments anchor to
counts:                         # findings by severity (derived, human sanity-check)
  blocking: 1
  non_blocking: 2
  nit: 3
---
```

Required: `pr`, `repo`, `base`, `head_sha`. `ticket` falls back to `pr-<N>`.

## 2. Finding block

Body = one block per finding, separated by `---`, grouped under severity headings. Every block has this exact shape.

The file may also carry a leading `## Overview` (whole-PR verdict/credit/framing) and a trailing `## Routed elsewhere` (cross-PR routing) — both are **prose, not findings**. A consumer treats only `### N.` blocks under a severity heading (🔴/🟠/🟡) as findings to post; `Overview` and `Routed elsewhere` are never posted as inline comments.

````md
### <N>. <severity-emoji> <short title>

```
file:   <basename.ext>
path:   <path/from/repo-root>
line:   <NN>
anchor: <exact source line text>
```

> <the ask — ONE tentative sentence; this is what gets skimmed>

<details><summary>Details</summary>

**Why it matters**
- <one distinct point per line; **bold** the key term>
- <another point — keep each to a line>

---

**Checked**
- <evidence: commands run → what was found, one per line>

</details>
````

Two shape rules keep the file scannable instead of a wall of text:

- **The locator is a fenced code block** on purpose: outside a fence, adjacent markdown lines collapse into one paragraph (soft newlines render as spaces), so `file`/`path`/`line`/`anchor` would run together in GitHub's rendered view. A fence keeps them on distinct lines, gives a copy button, and renders the `anchor` text literally even when it contains backticks or markdown. The parser reads each `label:` line inside the fence.
- **Only the ask is visible; the rest folds into one `<details><summary>Details</summary>` block.** The `>` quote is one tentative sentence (what gets skimmed). Inside the block, `**Why it matters**` and `**Checked**` are two sub-sections split by a `---` rule. The visible file reads as title → ask; depth is on demand.

  **Two registers.** The visible ask is telegraphic. Inside `Details` — opt-in reading — write *expansively*: semantic paragraphs (one facet each: observation → impact → context), **bold** the key claim of each, bullets only where genuinely enumerating. `Checked` narrates *what you set out to confirm → how → what it showed → the takeaway*, with the raw commands/results in a code block so they stay reproducible. Two guardrails: (1) structure, never a monolith — paragraphs + emphasis so even long detail reads in steps; (2) **calibration is unchanged by length** — expand the *explanation*, never the *certainty*; every claim still traces to `Checked`, and anything unverified is hedged. `why` is posted (appended to the comment body), so its length reaches the author; `Checked` is not posted.

### Field reference

| Field | Parsed from | Required | Notes |
|---|---|---|---|
| severity | emoji in the `###` line | yes | 🔴 blocking · 🟠 non_blocking · 🟡 nit |
| title | `###` line, after the emoji | yes | short human label |
| path | `path:` line | yes | repo-root-relative → GitHub `path` |
| line | `line:` line | yes | integer (strip a leading `~`) → GitHub line |
| anchor | `anchor:` backticked text | yes | exact source text; used to detect line drift |
| comment | the `>` quote | yes | one-sentence ask; opening of the posted body |
| why | `**Why it matters**` bullets, inside `<details>Details` | yes | bulleted list; appended to the posted body |
| evidence | `**Checked**` sub-section of the `<details>Details` block | optional | context; not posted unless configured |

## 3. Mapping finding → GitHub inline comment (for the publisher)

One finding → one inline review comment:

- `path` → comment `path`
- `line` → comment `line`. **Validate against `anchor`:** if the source at `line` no longer matches `anchor`, the diff moved — skip + flag, do not post to a wrong line.
- body → `comment` + blank line + `why`. Evidence stays in the file, not posted, unless configured otherwise.
- All findings → **one batched PR review**, created as a **pending** review for the human to submit in the GitHub UI. Never auto-submit, approve, or request-changes.

## 4. Versioning

Both skills reference this file (via a symlink in their `references/`). Change the shape here → update both producer and consumer, and bump nothing silently: a field rename is a breaking change to the publisher.
