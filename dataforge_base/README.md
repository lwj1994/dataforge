# Dataforge Base

Shared resolved-generation core for Dataforge v1.

> `1.0.0-dev.0` is a preview, not the 1.0 GA release. Public APIs and generated
> output may still change in later preview versions.

Most applications should depend on `dataforge` or `dataforge_cli`, not call this
package directly.

```yaml
dependencies:
  dataforge_base: ^1.0.0-dev.0
```

## Public surface

The supported public API contains:

- resolved generation diagnostics;
- the resolved generation facade used by adapters;
- `SchemaId`, for stable schema identity where required by public results.

Raw schemas, schema builders and renderers stay internal. An adapter must start
from a resolved Analyzer element and use the facade so it cannot bypass
cross-model validation, witness arity checks or type-tree invariants.

## Core invariants

- Public models and diagnostics are immutable snapshots.
- Collection inputs are defensively copied before being exposed.
- Freeze, equality and hash traverse the same complete semantic type tree.
- Exact witnesses form explicit semantic boundaries for custom values.
- Generation diagnostics use stable codes and source locations.

The build_runner and CLI packages are intentionally thin adapters over this
shared core.
