# UI

How interfaces get built here. Framework-agnostic where it can be; the examples are React and
CSS custom properties because that is what these were written against.

| Guide | Covers |
| --- | --- |
| [`atomic-design`](atomic-design.md) | The five tiers, the boundary rule, and where logic lives |
| [`design-tokens`](design-tokens.md) | Three-layer tokens, the capping rule, rationing the expensive things |
| [`component-patterns`](component-patterns.md) | Named patterns, each paid for by something that shipped wrong |
| [`accessibility`](accessibility.md) | WCAG 2.2 AA as a floor, and the ways meeting it is still not enough |

## The three rules that matter most

1. **A component that reads its own data is an organism, not a molecule.** That single test
   settles the taxonomy argument permanently.
2. **A component reads a semantic token — never a primitive, never a literal.** Everything
   about theming follows from this one rule.
3. **A rule living in a `.tsx` is a rule with no test.** Rules go in pure modules; components
   are wiring; hooks are the DOM half and hold no rules.

## A note on generic design advice

The four guides above are written from what these projects actually do. They are **not** a
summary of the third-party design and React skills — those stay upstream, fetched on demand:

```bash
node scripts/sync-skill.mjs      # 153 files: impeccable's ~40 design playbooks, 70 React
                                 # performance rules, composition patterns, view
                                 # transitions, the anti-templated design pack, and the
                                 # Web Interface Guidelines reviewer
```

A vendored or general-purpose design skill does not know this product. It loses to the
project's own design document, every time, without discussion — and the rule families that do
not apply are listed explicitly, in an override table, rather than re-derived on each
encounter. Both the policy and the table live in
[`claude/skills/vendored/README.md`](../claude/skills/vendored/README.md).
