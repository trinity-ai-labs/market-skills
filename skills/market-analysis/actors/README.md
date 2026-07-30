# The actor corpus — companies already profiled, held as notes rather than re-discovered

An **actor** is a company in the tech space, held as a persistent entity. Its founding date, funding
rounds, dated traction points, pricing model, positioning claim and corporate events are true
regardless of who is asking, so an engagement that re-derives them from zero pays the expensive half
of the research twice. Discovery is where the tokens go — a multi-modal finder sweep to learn the
company exists at all, then its pricing page, then its funding history, then its traction
disclosures. Verification is one fetch against a URL a record already carries.

This file is the rule about **what may be in a record**. The note schema — the fields, the field
classes, the shelf lives and the six checks that read them — is
[the vault schema](../../business-plan/references/vault.md#an-actor-record-is-source-and-fact-notes-with-four-more-fields-not-an-eighth-note-type),
which is authoritative for everything this file does not decide.

## Contents

- [This directory is the one place shipped state lives inside a skill](#this-directory-is-the-one-place-shipped-state-lives-inside-a-skill)
- [What ships is public company fact; what stays in the vault is the judgement about the subject](#what-ships-is-public-company-fact-what-stays-in-the-vault-is-the-judgement-about-the-subject)
- [A record is a directory of notes, so seeding is a copy and never a transform](#a-record-is-a-directory-of-notes-so-seeding-is-a-copy-and-never-a-transform)
- [The roster is the directory listing, because an index would drift from the notes](#the-roster-is-the-directory-listing-because-an-index-would-drift-from-the-notes)
- [A leading underscore marks format documentation that is never seeded](#a-leading-underscore-marks-format-documentation-that-is-never-seeded)
- [Contribution is manual, because every automatic path leaks which actors an engagement looked at](#contribution-is-manual-because-every-automatic-path-leaks-which-actors-an-engagement-looked-at)
- [The corpus is shaped by whoever contributed to it, and a reader in an uncovered category hears it here](#the-corpus-is-shaped-by-whoever-contributed-to-it-and-a-reader-in-an-uncovered-category-hears-it-here)

## This directory is the one place shipped state lives inside a skill

`AGENTS.md` rule 2 says state lives outside the skill: the skills read and write
`~/Documents/go-to-market/<product-slug>/`, and this repo holds method and tools only. **This
directory is the deliberate exception, and a reader hits it here rather than discovering it.** What
rule 2 keeps out is *user data* — a corpus of claims about someone's business, which is private, and
which a user must be able to keep across an upgrade of the skills. What is here is the opposite kind
of thing: public fact about third-party companies, identical for every install, versioned with the
plugin, and reviewed in a pull request like every other file in the repo.

**The property that keeps the exception from widening is that a run never writes here.** A run reads
this directory and seeds a copy into its own vault; a contribution back is a pull request a person
opens. So no engagement data can reach the repo through a run's own action, which is the direction of
rule 2 that actually protects anybody. The alternative — holding the corpus in the engagement folder
where state belongs — puts it somewhere the *next* engagement cannot read, which is the entire
purpose it exists for.

## What ships is public company fact; what stays in the vault is the judgement about the subject

This seam is the whole design, and it is also the privacy seam — which is what makes shipping a
corpus consistent with rule 1's ban on engagement specifics.

**Ships — properties of the company.** Each row is a `field_class`, and the shelf life each one
carries is the schema's table rather than a second copy here:

| what ships | `field_class` |
|---|---|
| the name, the canonical URL, the founding date | `identity` |
| what it does, in the company's own one paragraph | `description` |
| one funding round: date, stage, amount, named investors | `funding` |
| one dated corporate event — acquisition, shutdown, pivot, rename | `corporate-event` |
| one dated traction point — ARR, users, downloads | `traction` |
| the pricing model, a tier name, a price point | `pricing` |
| the pricing-page CTA verbatim, and the GTM motion it maps to | `cta` |
| the positioning claim in their own words | `positioning` |
| how it got from zero to its first revenue threshold | `mechanism` |

**Does not ship — recomputed every engagement.** Five members, and each one is keyed to *this*
dossier's jobs and target segment:

- **The bucket** — direct, indirect or adjacent. The competitive playbook's own rule already makes
  this subject-dependent: a platform offering the identical capability but requiring the buyer to
  migrate their stack is *adjacent for buyers who won't migrate and direct for buyers who would*,
  picked per the dossier's target segment. A shipped bucket would be one engagement's segment
  answering a different engagement's question.
- **The wedge line** — what a competitor structurally does not cover is relative to this dossier's
  jobs. Change the jobs and the same company's gap stops being a gap.
- **`## Capability matrix` cells** — and this one needs its argument stated rather than assumed,
  because a single cell can look like a plain observation: *supports SSO — yes* is a fact about the
  company, and shipping it looks harmless. What is not harmless is the **row set**, which is this
  dossier's own job decomposition. Ship the cells and the jobs come with them, because a column of
  answers only means anything against the questions it answers — so the leak here is the private
  taxonomy, not the individual cell.
- **`## Threat ranking`** — impact and probability are measured against this product.
- **The adoption candidate** — what this competitor does better, and what adopting it would cost.
  This is the least obvious entry on the list and the one a future contributor will be tempted to
  ship, so it gets the argument in full. It is engagement-keyed for the wedge line's reason: what to
  adopt is relative to this dossier's jobs, this product's current gaps and this founder's resource,
  so the same candidate is a roadmap item for one subject and irrelevant to the next. **And it leaks
  harder than the wedge line does.** A wedge says what a *competitor* fails to cover. An adoption
  candidate says what **the subject was behind on** — a fact about the subject wearing a competitor's
  name. Rolled up, `## Adoption candidates` is a ranked account of a private product's gaps, and it
  would be readable by anyone who cloned the repo.

**The mechanism record is the opposite case, and it ships.** How a company got from zero to its first
$1M — the launch motion, the first channel that produced paying customers, what the founder did
personally that did not scale, what compounded, what was tried and abandoned — is a dated, durable
property of *that company*, and it is the growth-curve reference class this corpus exists to
accumulate, one field further on. It is also the only evidence available in the lowest ARR bucket,
which is the bucket the indexed series cannot see and the one a pre-revenue product is in.
`## Comparable growth curves` in [templates.md](../references/templates.md) carries its current
shape.

**One half of it does not ship**, and the split runs exactly where every other one here does: the
dated account and its verbatim quote are fact, while the filter *policy or structural for THIS
founder at their grilled hours, channels and capital* is a judgement about the subject's resource.
Ship the account; leave the filter in the engagement.

**Next-move prediction does not ship either, and the seam decides it without a new rule.** A
prediction is an inference rather than an observation, so it can only be a `claim` — and no `claim`
may appear in a record. That is the same test the whole seam runs on: **every one of the five
engagement-keyed outputs is a judgement, so every one of them would have to be a `claim`, and a
corpus holding no `CLAIM-*` file cannot carry any of them.** That makes the seam checkable rather than
trusted, on two surfaces: a grep over this repo's filenames, and `actor-type-not-shippable` inside a
vault, which fails a note carrying `actor` whose `type` is neither `source` nor `fact`. Both
directions are load-bearing — with only the repo-side grep, the cheapest way past the seam is to
author the judgement as an actor note directly in a vault, where no filename here can see it.

## A record is a directory of notes, so seeding is a copy and never a transform

```
skills/market-analysis/actors/
  README.md                     this file — the seam rule
  _example/                     format documentation, never seeded
    SOURCE-5ObFcX8P.md          the vendor's own pricing page, with its quote
    FACT-DnMvSnbz.md            identity — permanent
    FACT-qr6hgnix.md            pricing — three months
    FACT-sqeVaGdE.md            cta — six months
  <canonical-host>/             one directory per actor
    SOURCE-xxxxxxxx.md          the material, with its quote
    FACT-xxxxxxxx.md            one value each, with its field class and shelf life
```

**One file per note, named exactly the ID plus `.md`** — the vault's own filename rule, so seeding is
a file copy into `sources/` and `facts/` and nothing has to be parsed, split or renamed. A record
bundled as one file per actor would have to be split on copy, and the split would have to invent each
destination filename from the note's `id:` field: a transform, and a transform that goes wrong
silently produces a note whose filename and `id` disagree — the exact mismatch the type-stated-three-times
rule exists to catch, introduced by the tool meant to respect it. **Each file routes by its ID
prefix**, which is already the type stated in the filename.

**The IDs are allocated once, when the record is authored, and seeding copies them unchanged.** Two
engagements that seed the same actor hold notes with the same IDs, which is correct — it is the same
note — and it is what lets a re-verification in one engagement be offered back as a supersession
naming the ID the corpus ships. There is still no registry and no sequential allocation, so the
collision argument in the vault schema is untouched.

**The directory name is the company's canonical host with each `.` mapped to a `-`, and it is never
renamed.** A company name has punctuation, casing, legal-suffix and abbreviation variants, so two
contributors working independently produce two directories for one company — the duplicate the
corpus exists to remove, and the same failure `url_canonical` exists to remove one level down. Every
note in the record carries that directory name as its `actor` value, and those values are already
copied into vaults, so renaming the directory would strand them. A company that renamed or moved its
domain gets a `corporate-event` note recording the move, and the directory keeps the name it was
created under.

## The roster is the directory listing, because an index would drift from the notes

There is no index file, and that is a decision rather than an omission. A table of actor, canonical
URL and last pull date would be a second copy of the identity notes, so it can carry a name or a URL
the notes do not — and nothing in the corpus could say which side is right. That is the same drift a
backlink field causes in the vault, refused here for the same reason. `ls` over this directory is the
roster; the identity notes inside each one are the detail.

**The roster is a floor for discovery and never a substitute for it** — the finder sweep still runs
every engagement, seeded with the roster rather than replaced by it. Without that the corpus ossifies
around whoever mattered when it was written, and a new entrant is structurally never found. The
protocol that states it is the competitive-landscape playbook's.

## A leading underscore marks format documentation that is never seeded

`_example/` demonstrates the record format with an invented company on an IANA-reserved domain — four
notes, one source and three facts across three shelf lives, of which
[`FACT-qr6hgnix.md`](_example/FACT-qr6hgnix.md) is the rotting one. It is not an actor, and a seeding
step that copied it would put a fabricated company into a real engagement where every downstream
consumer reads it as a profiled competitor. **A directory whose name begins
with `_` is skipped by anything that seeds or enumerates actors.** It is also why the example is
invented rather than a real company: a real pricing page's figures rot on a schedule this repo does
not control, and *which* companies a corpus contains is engagement signal even when every fact in it
is public — so an illustrative record is chosen to demonstrate the format and never harvested from an
engagement.

## Contribution is manual, because every automatic path leaks which actors an engagement looked at

An engagement that re-verifies an actor's figures has fresher notes than the corpus does, and
contributing them back is what keeps the corpus alive without a maintainer. **The engagement writes
back only when the founder says so, and the write-back is a pull request.** An automatic path
publishes which actors a private engagement examined; an opt-in prompt leaks the same thing on the
first yes. Manual has no leakage surface at all and costs one instruction in the playbook.

**A corpus nobody refreshes still fails closed**, which is what makes that cheap answer safe: a fact
past its `stale_after` is a lint failure rather than a figure that quietly ships, so the cost of
staleness is a wasted fetch and never a wrong number.

## The corpus is shaped by whoever contributed to it, and a reader in an uncovered category hears it here

Every actor here arrived because somebody profiled it and chose to contribute it. There is no sweep
that keeps the corpus representative of any market, so **coverage is uneven by construction and the
gaps are not evidence that a category is empty.** A run that finds no actor in its category has
learned nothing about that category — it has learned that nobody has contributed one yet, and its
finder sweep is the thing that answers the actual question. Stating that here rather than leaving it
to be discovered is what stops an absent roster being read as a competitive finding.
