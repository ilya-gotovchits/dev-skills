# Comment conventions (the style we converged on)

These govern *how* a comment reads. They are the non-negotiable part of the skill (Principle #0: style is mine). Substance about the code still defers to the repo. Read this in full before writing the first comment.

---

## The seven core conventions

### 1. Tentative framing, always

Open with a tentative phrasing from the **[`phrasing.dictionary.md`](./phrasing.dictionary.md)** — never an imperative or an accusation (its *Avoid* category lists the ones to stay away from). You are raising a question for the owner to decide, not issuing an order. The owner has context you don't.

- ❌ "Revert this token and solve the dot locally."
- ✅ "Looks like this redefines a shared `sys` token globally — I wonder if a dedicated token would keep the two intents separate?"

Absolutes read as accusations — the dictionary's *Avoid* category names them.

### 2. Anchor precisely (on real files)

Because the PR branch is checked out, anchor to the **real file + real line number**, verified against the file on disk — not the diff's approximate numbering. Still quote the exact anchor line as double insurance. One concern per comment; split a multi-concern draft into separate anchored comments so each can be resolved independently.

Format — put each locator field on its own line so the author can select/copy any one alone (full `path` → open or search the file; `anchor` → jump to the exact line). `file` is the basename for a fast scan; `path` is repo-root-relative and copy-ready:

```md
file:
    shape.ts
path:
    src/tokens/shape.ts
line: ~42
anchor: `--eff-sys-shape-pill: 20px;`
```

### 3. Calibrate claims to evidence

Do NOT assert impact you haven't checked. If a claim needs verification (e.g. "global token, big blast radius") either verify it first (grep the checked-out repo) or downgrade the wording to match what's actually known ("this changes a shared token's semantics", not "this breaks half the app"). Record the check under the **Checked** sub-section of the finding's collapsible `<details><summary>Details</summary>` block — folded by default, visible on a click, so it doesn't clutter the main text. **Overstating is the failure mode to avoid** — an inflated claim that turns out wrong costs you credibility on every later comment.

State the evidence *in* the comment when it strengthens the point: "there are ~14 consumers of this token" lands harder and more honestly than "this is used everywhere".

### 4. Separate altitudes

Code-level nits go inline on the impl PR. Architecture/direction goes on the *design* PR, not the impl PR — an impl PR that faithfully implements an approved design is not the place to relitigate the design. Put cross-PR notes in the trailing `Other` section, named explicitly ("→ design PR #NNNNN").

### 5. Faithful-to-spec ≠ defect

"1:1 with the spec" is the job of an impl ticket. Flag real concerns (blast radius, missing edge tests, speculative API), not fidelity itself. If something *looks* wrong but matches the approved design, say so and route the question to the design PR rather than flagging it as a code defect.

### 6. No slop-shaming

Credit what's done well, specifically. Judge the code, not the presumed authoring process — never speculate about whether it was AI-generated, rushed, or copy-pasted. Cross-model agreement is NOT human verification — the only thing that closes a "did anyone actually check this?" gap is a human exercising the change.

### 7. Group by severity, stay humble

Group by 🔴 blocking / 🟠 non-blocking / 🟡 nit in the file, but keep every individual comment humble regardless of severity. Severity ranks the *concern*; it never licenses a harsher *tone*.

---

## Anatomy of a good comment

A strong comment usually has three moves, in order:

1. **Observation** — the one-line `> …` comment: what you see, neutrally, in a soft framing. "Looks like the dot points at the shared pill token."
2. **Why it matters** — bulleted reasoning inside the folded `<details><summary>Details</summary>` block (`**Why it matters**` sub-section), calibrated to what you checked: one point per line, e.g. "After the `full → 20px` change above, roundness depends on the clamp, not intent" / "the token is shared across other consumers." The supporting greps/traces sit in the `**Checked**` sub-section of the same block, split off by a `---` rule — folded, visible on a click, never hidden.
3. **Optional path forward, as a question** — never mandated. "Perhaps a dot-specific token would state 'always a circle' more directly?"

Move 3 is optional. Sometimes the best comment just surfaces the observation and asks "is this intended?" — proposing a fix you haven't thought through invites a worse solution than the owner's.

---

## Phrasing bank

The bank of openers, soft-question framings, intent phrasings, crediting lines, downgrade wordings, and anti-phrases-to-avoid lives in its own growable dictionary: **`references/phrasing.dictionary.md`**. Pull tone from there; extend that file when you find a phrasing worth reusing.

---

## What to prioritize, what to skip

Spend attention where it matters; a pile of trivial nits buries the one comment that counts.

| Prioritize | Go easy / skip |
|---|---|
| Correctness, data loss, security, regressions | Formatting a linter/formatter already owns |
| Missing tests for **declared** contracts | Personal style preferences with no rule behind them |
| Public API surface (speculative/unused inputs) | Bikeshedding names that are merely "not what I'd pick" |
| Blast radius of shared/global changes | Pre-existing issues unrelated to this diff |
| Breaking changes to consumers | Restating what the diff already makes obvious |

- **Batch trivial style** into a single low-priority note rather than ten separate nits.
- **Scope to the diff.** If you must mention pre-existing code, label it: "not introduced by this PR, but while we're here —" so it's clearly optional.
- **Defer to tooling.** If a linter/formatter/type-checker would catch it, let it — don't hand-review what a machine enforces.

---

## Pitfalls (the things that make reviews land badly)

- **The confident-wrong claim.** Asserting impact you didn't check. One of these and the author discounts the rest. Verify or downgrade.
- **The nit pile-on.** Twenty 🟡 comments drown the one 🔴. Batch or cut.
- **The redesign in disguise.** "Have you considered rewriting this as…" on an impl PR that follows an approved design. Route to the design PR.
- **The imperative slip.** "Please add a test" / "change this to 50%". Rephrase as a question.
- **The vague ask.** "This feels off" with no anchor or evidence gives the author nothing to act on. Anchor + say what specifically and why.
- **The process guess.** Any comment about *how* the code was written rather than *what* it does.

---

## Canonical example

The first block from the EFF-24181 live run (PR #57943, a design-doc PR) — real anchors, real greps. It shows the whole shape: a telegraphic ask visible, expansive `Why`/`Checked` folded under one `Details`, evidence kept reproducible.

````md
### 1. 🟠 Does `max` overflow apply to `role="grid"` / `listbox`?

```
file:   chip-design.md
path:   libs/client/shared/ui-kit/docs/design/chip-design.md
line:   60
anchor: <eff-chip-set role="grid" [max]="5">
```

> I wonder if `max` is meant for `role="grid"` / `listbox` too — or should it be scoped to `role="list"`?

<details><summary>Details</summary>

**Why it matters**

**The §7 overflow model is designed for static collections.** `max` renders the first *N* chips and drops the rest — §7 is explicit that hidden chips are *not rendered* (an `@for` slice, not `display: none`) and that the `+N` badge is non-interactive in v1. For a `role="list"` tag bar that's exactly right.

**It gets shaky on the interactive roles.** In a `role="grid"` of input tokens (email-pills, image tags) a chip past the cap isn't in the DOM at all, so there's no keyboard or AT path to it — the user can't reach or remove a token they just added. In a `role="listbox"` filter, a chip that is *selected* but past the cap disappears from AT while still affecting the filter — a silent selection.

**The migration map already seems to assume list-only.** `[max]` shows up only in §14.4 (Pattern D, static tags); §14.1 (grid) and §14.2 (listbox) don't mention overflow. So list-only may be the intent — it just isn't stated as a constraint, and the §4 example (`role="grid" [max]="5"`) points the other way.

---

**Checked**

Confirmed two things: that hidden chips really leave the DOM, and which roles the migration map pairs with `max`.

```
§4 (line 60):  <eff-chip-set role="grid" [max]="5">        # grid + max, in the arch example
§7 (~280):     "Hidden chips are not rendered (@for slice)"; "+N non-interactive in v1"
§14.1 grid: no [max] · §14.2 listbox: no [max] · §14.4 list: role="list" [max]
```

So the contradiction is internal to the doc: the architecture sketch shows `grid + max`, but every migration site that uses `max` is a `list`.

</details>
````

What it demonstrates: tentative one-sentence ask · labeled locator in a fenced block (copy-ready, renders on distinct lines) · `Why` as semantic paragraphs with a bolded lead each · `Checked` narrating the verification with reproducible output · calibrated wording (a doc-internal contradiction, not "this breaks the app").

*(More examples — a nit, the `Overview`, an `Other` note — to be added from later runs.)*
