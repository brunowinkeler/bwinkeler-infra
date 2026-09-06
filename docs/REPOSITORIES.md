# Repositories and local workspace

How the `bwinkeler.com` repositories are laid out on a workstation, and why the
folder that holds them is deliberately not a Git repository.

The authoritative rule is [`ARCHITECTURE.md`](../ARCHITECTURE.md) §4 and ADR 010.
The clone list is [`../scripts/repos.json`](../scripts/repos.json); what is
actually deployed is in [`inventory.md`](./inventory.md).

## Layout

```text
bwinkeler/                     # aggregator folder — NOT a Git repository
├── bwinkeler-infra/           # this repository (private, canonical contract)
├── bwinkeler-portfolio/
├── bwinkeler-lists/
├── bwinkeler-physics/
├── cpp-physics-simulation/
├── bwinkeler-keyplay/
└── bwinkeler-practice/
```

The aggregator folder holds nothing of its own. Every document belongs to the
repository it describes; cross-project notes belong here, in `bwinkeler-infra/docs/`.

## Bootstrap on a new machine

```powershell
git clone git@github.com:brunowinkeler/bwinkeler-infra.git C:\dev\web\bwinkeler\bwinkeler-infra
pwsh C:\dev\web\bwinkeler\bwinkeler-infra\scripts\bootstrap-workspace.ps1
```

The script clones every missing repository as a sibling and never touches an
existing clone. Then open
[`../bwinkeler.code-workspace`](../bwinkeler.code-workspace) — do not open the
aggregator folder itself, and do not add both a parent folder and its child as
workspace roots.

## Naming

`service_id` is the stable identifier once published; repository and directory
names are not. Two intentional mismatches exist:

| Directory | Repository | Reason |
| --- | --- | --- |
| `bwinkeler-practice` | `bwinkeler-music-practice` | Service id, npm package, Pages project, IndexedDB database, and backup format keep the `practice` identifiers; only the Git repository was created under the longer name. |
| `cpp-physics-simulation` | `cpp-physics-simulation` | Also vendored as a pinned submodule inside `bwinkeler-physics/vendor/`. Land source changes in the sibling clone, then move the submodule pointer — never edit the submodule working tree. |

## Why not submodules

A super-repository aggregating these repositories through Git submodules was
evaluated and rejected:

- no application builds from another application's source, so a pinned pointer
  would carry no build guarantee — only bookkeeping;
- every child push would leave the parent stale and demand an empty
  "bump pointer" commit, which rots within weeks;
- `cpp-physics-simulation` would gain a third checkout with no rule saying which
  one is editable;
- this repository is private while the others are not, so a single parent would
  either leak its existence or break cloning for everyone else;
- each application's CI would need `submodules: recursive`, and AI-assisted work
  is scoped to one repository by contract (ARCHITECTURE.md §4.1).

The one legitimate use stays: `bwinkeler-physics` pins `cpp-physics-simulation`
because its build compiles that source (physics ADR 002).

Revisit the decision if a real shared package appears between applications, if
releases ever need a reproducible platform-wide snapshot, or if the clone list
grows beyond what `bootstrap-workspace.ps1` handles comfortably.
