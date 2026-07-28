# Red team — example product

Violates: red-team-lens-no-rows, red-team-lens-unrostered

Both directions of the roster check, in one document. The `Violates:` line above
is read by `run-fixtures.sh` exactly as it is on a violating note — which mode
reports a check is not the document's business.

This vault is at `schemaVersion` 1, so `red-team-no-roster` cannot fire here even
if the roster were deleted. That case is the whole content of `panel-gap/`.

## Lenses dispatched

| Round | Lens |
|---|---|
| R1 | Capital skeptic |
| R1 | Target customer |

## Objections

| # | Lens | Objection | Severity | Disposition |
|---|---|---|---|---|
| R1-O1 | Capital skeptic | The moat argument names no layer the falling input cost fails to reach. | High | fixed |
| R1-O2 | Operator | An objection from a lens the roster never named as dispatched. | Medium | fixed |

`Target customer` is on the roster and wrote nothing, which is the failure the
mode exists for: a lens whose findings were folded into two documents and never
written down reads exactly like a lens that had no objections.

`Operator` is the reverse. Its row is sitting in the table and the roster does
not name it, so the roster is not the record it claims to be — and without this
direction the cheapest way past the check above is to delete a line rather than
to dispatch a lens.
