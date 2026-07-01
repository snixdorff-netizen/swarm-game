# SWARM Engagement Audit

## Target user
**Casual mobile survivor fans** — players who enjoy Vampire Survivors–style games in short sessions (3–8 minutes), one-thumb control, visible power growth, and "one more run" retry loops. They expect auto-attack, escalating hordes, build choices at level-up, and light meta between runs.

## Genre-defining mechanics (baseline)
| Mechanic | SWARM status |
|----------|--------------|
| Drag-to-move joystick | ✅ Floating stick |
| Auto-attacking weapons | ✅ Bolt + unlockable weapons |
| Escalating hordes | ✅ Spawn rate + enemy tiers |
| XP gems → level-up | ✅ Green gems, 1-of-3 picks |
| Death → retry | ✅ Run again + menu |
| Meta between runs | ✅ Cores + permanent shop |
| Milestone drama | ⚠️ Boss only — adding time milestones |
| Build divergence | ⚠️ Similar curves — adding profiles + leech/nova paths |
| Onboarding without README | ⚠️ Hint exists — expanding in-app copy |

## Gaps addressed this pass
1. **Balance formulas extracted** to `BalanceEngine` + `RunSimulator` for tuning confidence.
2. **Build variety** — Vampiric Leech path, expanded meta (XP boost, leech).
3. **Milestone feedback** — 30s / 60s survival banners, richer death motivation.
4. **Onboarding** — First-run card covers cores + upgrades; death screen motivates retry.
5. **Simulation** — Batch autopilot runs with median survival ≥ 30s threshold tests.