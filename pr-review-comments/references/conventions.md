# Comment conventions (the style we converged on)

These govern *how* a comment reads. They are the non-negotiable part of the skill (Principle #0: style is mine). Substance about the code still defers to the repo. Read this in full before writing the first comment.

---

## The seven core conventions

### 1. Tentative framing, always

Open with `looks like` / `perhaps` / `I think` / `I wonder if` / `might be worth` / `could we`. No imperatives, no "this is wrong", no "revert this", no "please add", no "you should". You are raising a question for the owner to decide, not issuing an order. The owner has context you don't.

- ❌ "Revert this token and solve the dot locally."
- ✅ "Looks like this redefines a shared `sys` token globally — I wonder if a dedicated token would keep the two intents separate?"

Absolutes read as accusations. Avoid `always` / `never` / `obviously` / `just` ("just do X" implies it's trivial and they missed it).

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

Do NOT assert impact you haven't checked. If a claim needs verification (e.g. "global token, big blast radius") either verify it first (grep the checked-out repo) or downgrade the wording to match what's actually known ("this changes a shared token's semantics", not "this breaks half the app"). Record the check in a collapsible `<details><summary>Checked</summary>` block inside the comment — visible on a click, folded by default so it doesn't clutter. **Overstating is the failure mode to avoid** — an inflated claim that turns out wrong costs you credibility on every later comment.

State the evidence *in* the comment when it strengthens the point: "there are ~14 consumers of this token" lands harder and more honestly than "this is used everywhere".

### 4. Separate altitudes

Code-level nits go inline on the impl PR. Architecture/direction goes on the *design* PR, not the impl PR — an impl PR that faithfully implements an approved design is not the place to relitigate the design. Put cross-PR notes in the footer, named explicitly ("→ design PR #NNNNN").

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
2. **Why it matters** — a visible `**Why it matters:**` paragraph expanding the concern, calibrated to what you checked. "After the `full → 20px` change above, the roundness now depends on the clamp rather than intent, and this token is shared across other consumers." The supporting greps/traces go in the folded `<details><summary>Checked</summary>` block beneath it — evidence stays visible-on-click, not hidden.
3. **Optional path forward, as a question** — never mandated. "Perhaps a dot-specific token would state 'always a circle' more directly?"

Move 3 is optional. Sometimes the best comment just surfaces the observation and asks "is this intended?" — proposing a fix you haven't thought through invites a worse solution than the owner's.

---

## Phrasing bank

**Openers (tentative):** `Looks like…` · `I think…` · `I wonder if…` · `Might be worth…` · `Perhaps…` · `Could we…` · `Small thought:` · `Nit:`

**Soft-question openers (raise it as a question, not a claim):** `Should we maybe…?` · `Would it make sense to…?` · `Do you think it's worth…?` · `Any concern that…?` · `Might it be cleaner to…?` · `Wonder if it's worth …?` · `I might be missing something — is … intended?` · `Would it be safer to…?`

**Surfacing uncertainty / missing context:** `I might be missing context, but…` · `Happy to be told this is already handled.` · `Not sure if this is intentional —` · `Correct me if the design covers this,`

**Asking about intent instead of assuming:** `Is the intent here to…?` · `Was `X` considered?` · `What happens when…?`

**Crediting (specific, not performative):** `Nice — the `it.each` here reads really cleanly.` · `Good call extracting this into `…`.` (Skip empty praise like "LGTM great job".)

**Downgrading an unverified claim:** `this changes a shared token's semantics` (not "breaks the app") · `at minimum this couples X to Y` · `worth confirming the other consumers before merge`

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

A worked example is intentionally left out until we run the skill on a live PR — then the `<!-- checked -->` notes reflect real greps and the line numbers are real, not fabricated. Populate this section from the first real run.
