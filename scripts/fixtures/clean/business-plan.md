# Business plan — example product

A rendered document at the vault root, which is where `used_in` resolves against.
Nothing reads its prose: `--used-in` opens it for its headings and for nothing
else, because a scan matching note IDs against this text would report a false
positive on every correctly cited claim.

## Why now

`CLAIM-AS23SD44` is cited here, as `business-plan.md#why-now`. The citation code
in the prose is `[F1]` rather than the note ID, which is exactly why the mode
stops at whether the anchor resolves.

Producers must re-label before the deadline, and the ones without an in-house
regulatory function buy tooling rather than build it. [F1]

## Risks

`CLAIM-RR55TT19` is cited here, as `business-plan.md#risks`.

Producers treat the deadline as optional until a peer is fined. [F1]

## Not a heading

```sh
# This is a comment inside a fenced code block, not a section anyone can jump
# to. A note citing business-plan.md#this-is-a-comment-inside-a-fenced-code
# should fail, which is what skipping fences buys.
grep -rH '^stale_after:' claims/
```
