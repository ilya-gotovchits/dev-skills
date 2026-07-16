# Phrasing dictionary — review-comment openers & framings

A growable bank of phrasings the drafting model picks from to keep comments tentative and humble. **Extend and edit freely** — adding a phrase here changes tone across every review without touching the skill's logic. Categories are just for browsing; order doesn't matter. The *rules* for when a tentative tone is required live in `conventions.md`; this file is only the raw material.

---

## Tentative openers
`Looks like…` · `I think…` · `I wonder if…` · `Might be worth…` · `Perhaps…` · `Could we…` · `Small thought:` · `Nit:`

## Soft-question openers (raise it as a question, not a claim)
`Should we maybe…?` · `Would it make sense to…?` · `Do you think it's worth…?` · `Any concern that…?` · `Might it be cleaner to…?` · `Wonder if it's worth …?` · `I might be missing something — is … intended?` · `Would it be safer to…?`

## Surfacing uncertainty / missing context
`I might be missing context, but…` · `Not sure if this is intentional —` · `Correct me if the design covers this,`

## Asking about intent instead of assuming
`Is the intent here to…?` · "Was `X` considered?" · `What happens when…?`

## Crediting (specific, not performative)
"Nice — the `it.each` here reads really cleanly." · "Good call extracting this into `…`."
Skip empty praise like "LGTM great job".

## Downgrading an unverified claim
`this changes a shared token's semantics` (not "breaks the app") · `at minimum this couples X to Y` · `worth confirming the other consumers before merge`

## Avoid (anti-phrases — never open or frame a comment this way)
- **Imperatives / orders:** `revert this` · `you should` · `please add` · `change this to …` · `just do X` ("just" implies it's trivial and they missed it)
- **Accusations / absolutes:** `this is wrong` · `obviously` · `always` · `never` — absolutes read as accusations
- **Process guesses:** anything about *how* the code was written (`looks AI-generated`, `rushed`, `copy-pasted`) — judge the code, not the author
- **Empty praise:** `LGTM` · `great job` with nothing specific
