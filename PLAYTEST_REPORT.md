# Balance Playtest Report — 22 Nov 2026

400 complete games were played by an automated bot using the real game rules (same action, combat and wave code as the game; only animations and sound were skipped). Re-run any time with:

```
"Alien Game.exe" -autotest balance
```

Results are written to `%LOCALAPPDATA%\Alien_Game\autotest\balance.log`.

## How the bot plays

- One operative is the **quartermaster**: sells surplus at Town, buys the best-value blueprint, forges it at the Workshop, makes emergency repairs (tower at 40% HP or less), rebuilds and reinforces.
- Everyone else **gathers** (they stay at the best cave/forest for what the team needs) and fires mounted weapons when standing on an armed tower.
- In combat it shoots Scouts first, then the most dangerous alien; Tesla always discharges.
- Squads are random with unique specialists (Survivor allowed for anyone).

> **Caveat:** this is a decent heuristic player, not an expert. A skilled human will do better — treat these numbers as a *pessimistic baseline* and compare changes against each other, not as absolute win rates.

The rules tested include this session's changes: 20 days, Goliath 6 damage, tower rebuild at 60 Gold, and the deposit fix (see below).

## Baseline results (current rules, 40 games per squad size)

| Squad | Win rate | Avg day reached | First tower lost (avg day) | Blueprints bought / forged | Gold from sales | Peak aliens at walls |
|---|---|---|---|---|---|---|
| 1 player | 0% | 11.1 | 9.9 | 3.0 / 1.2 | 33 | 13.8 |
| 2 players | 0% | 10.4 | 9.2 | 2.0 / 1.5 | 39 | 15.6 |
| 3 players | 0% | 9.7 | 8.2 | 1.4 / 0.8 | 29 | 15.9 |
| 4 players | 0% | 9.7 | 8.5 | 1.3 / 0.9 | 25 | 16.2 |

**Day the base fell:**
- 1 player: most on days 9–13 (13 on day 9).
- 2 players: most on days 9–11 (14 on day 10).
- 3 players: mostly day 9 (20 of 40).
- 4 players: days 8–10 (32 of 40).

### Day-by-day (average across games)

| Day | 3 | 5 | 7 | 8 | 9 | 10 | 12 |
|---|---|---|---|---|---|---|---|
| Total tower HP, 2 players (max 40) | 40 | 35 | 25 | 18 | 11 | 6 | 2 |
| Aliens at the walls, 2 players | 0 | 1.2 | 4.6 | 8.3 | 12.7 | 13.6 | 9.2 |
| Weapons mounted, 2 players | 0 | 0.1 | 0.6 | 1.0 | 1.1 | 0.9 | 1.2 |

**The pattern:** aliens start arriving on Day 4, but the team doesn't get its first weapon until around Day 7–8. Aliens that survive stay at the walls, and Hatchers add 2 Hatchlings a day, so the number at the walls snowballs past 12 by Day 9. One weapon can't keep up, and the towers collapse on Days 9–10.

## Experiments (25 games per squad size each)

| Change | 1P avg day | 2P avg day | 3P avg day | 4P avg day | Wins |
|---|---|---|---|---|---|
| Baseline | 11.1 | 10.4 | 9.7 | 9.7 | 0 |
| +20 starting gold | 13.1 | 12.2 | 12.4 | 11.7 | 0 |
| +2 energy per operative per day | 11.2 | 11.4 | 12.2 | 12.1 | 0 |
| **2 free Turrets at the start** | **16.9** | **16.4** | **15.5** | **14.8** | 0 |

- **Early defense is by far the biggest lever.** Two starting Turrets keep the walls nearly clear until about Day 12, with tower HP still around 38/40 on Day 9 instead of 11.
- **Starting gold helps less** but still adds about 2 days, because the first weapon arrives around Day 5 instead of Day 8.
- **Extra energy barely helps solo play**, which already has 15 energy. It helps bigger squads more, but it mostly turns into more resources than the team can sell.
- **Even the best experiment loses on Days 15–19.** That's where the tier 3 waves arrive (Days 14–20) and the walls end up with 10–20 aliens.

## Findings to plan from

1. **Gold comes in too slowly.** The whole economy runs on selling at Town: 3 units per trade, 1 energy each, plus a 2-move walk each way. Teams earned only 25–40 gold per game from sales, while blueprints cost 6–18 gold plus materials. Resources pile up in storage (one game had 49 Stone sitting unsold).
2. **Bigger squads do worse, not better.** 3–4 player squads lose about 1.5 days earlier than solo. With 4 players everyone gets 4 energy (the −1 penalty) and spends most of it walking, while threats don't scale down.
3. **Aliens snowball.** Survivors stay at the walls forever, and Hatchers add 2 a day. Once the defense falls behind it never catches up.
4. **Rebuild and Reinforce almost never happen.** There was 1 rebuild in 400 games. Power Gems are the bottleneck: only about 1 in 8 cave cards is a gem, so 3–5 gems is a big ask.
5. **The late game (tier 3) is a wall** even with an early lead.

## Suggested changes to try (most impactful first)

1. **Start every mission with one weapon:** a free Turret on Tower 1, or about 20 starting gold.
2. **Speed up the economy**, using one of these:
   - Allow up to 5 units per trade.
   - Make the second and third trade on the same visit free of energy.
   - Cut blueprint gold costs by about 30%.
3. **Fix squad scaling:** remove the −1 energy penalty at 4 players, or scale wave size with squad size.
4. **Tame the snowball:** Hatchers spawn 1 Hatchling (not 2), or only for their first 2 days.
5. **Make Power Gems easier to get:** add 2–3 more gem cards to Cave 2 and Cave 3, or drop Rebuild to 3 gems and Reinforce to 2.
6. **Tier 3 tuning:** after the changes above, re-run the playtest and look at Days 14–20 again before touching individual tier 3 aliens.

Each change can be checked by re-running `-autotest balance` and comparing the summary lines against the tables above.

## Bugs found during the playtest (fixed)

- **No random seed.** The game never called `randomize()`, so every launch dealt identical decks, shop offers and aliens.
- **Resources were double-counted.** Gathering credits team storage immediately, and walking into the Main Base then added the backpack to storage *again*. Fixed: the pack is now only a tally.

> **Note:** the deposit fix makes the economy noticeably harsher than what you've been playing, because base trips used to double your haul. If you preferred that pace, the cleanest replacement is to send gathered loot only to the backpack and make players bring it home.

---

# Round 2 — after starting gold, sell cart and cheaper rebuild (22 Nov 2026)

**Changes tested**
- Starting gold by squad size: solo 0, duo 5, trio 10, squad of four 15.
- The Market now uses a sell cart: each trade sells up to 3 items of any mix. The bot fills whole trades with its most valuable surplus.
- Tower rebuild now costs 4 Power Gems (was 5), plus 60 Gold and 15 Metal.

**400 games** (100 per squad size), same bot as before.

| Squad | Win rate | Avg day reached (before → now) | First tower lost (before → now) | Blueprints bought / forged (now) | Gold from sales (before → now) |
|---|---|---|---|---|---|
| 1 player | 0% | 11.1 → 11.0 | 9.9 → 9.9 | 3.2 / 1.1 | 33 → 36 |
| 2 players | 0% | 10.4 → 11.0 | 9.2 → 9.5 | 2.9 / 2.0 | 39 → 62 |
| 3 players | 0% | 9.7 → 10.9 | 8.2 → 9.5 | 2.5 / 1.9 | 29 → 44 |
| 4 players | 0% | 9.7 → 10.7 | 8.5 → 9.3 | 2.0 / 1.6 | 25 → 32 |

**Day the base fell:**
- 1 player: most on day 9 (28 games), then days 10–13.
- 2 players: days 9–11 (69 games).
- 3 players: mostly day 10 (32 games).
- 4 players: mostly day 10 (35 games).
- 3 solo games reached Day 20 and lost on the final wave.

Rebuilds went from 0 to 4 in 400 games.

## What changed
- **Squad sizes are now even.** Before, 3–4 player squads fell about 1.5 days earlier than solo. Now every size reaches about day 11, and bigger squads gained more than a full day.
- **Multiplayer economy improved.** Duos earned 62 gold from sales (was 39) and forged twice as many weapons as before, though that's still only about 2 per game.
- **Solo is unchanged** (no starting gold) and still mostly falls on Days 9–13. A few solo runs now reach the final day.
- **Still no wins.** The core problem from round 1 hasn't changed: by Day 9, 10–12 aliens are at the walls while only 1–1.5 weapons are mounted. The day-by-day tables show weapons peaking at about 2, while aliens peak at 12–16.

## Recommended next steps (unchanged priority)
1. **A starting weapon** (free Turret on Tower 1). In round 1 this was worth +5–6 days on its own.
2. **Hatchers make 1 Hatchling, not 2.** This slows the snowball after Day 8.
3. **Cheaper blueprints (about -30% gold),** so 3–4 weapons are online by Day 10.
4. Re-run `-autotest balance` and compare against the table above.

---

# Round 3 — Makeshift Cannon, 1 Hatchling, cheaper rebuild (22 Nov 2026)

**Changes tested**
- **Makeshift Cannon:** every mission starts with this permanent, reusable blueprint (5 damage, 4 HP, 3 Stone + 2 Wood + 1 Scrap). It's never sold in the shop.
- **Hatchers** now spawn 1 Hatchling (was 2).
- **Tower rebuild** now costs 10 Metal (was 15), plus 60 Gold and 4 Power Gems.
- The bot forges bought blueprints first, uses the Makeshift on empty towers, and dismantles a Makeshift to make room for a better gun.

**400 games** (100 per squad size).

| Squad | Win rate | Avg day reached (round 2 → now) | First tower lost (round 2 → now) | Weapons forged | Peak aliens at walls (round 2 → now) |
|---|---|---|---|---|---|
| 1 player | 0% | 11.0 → **12.2** | 9.9 → **11.3** | 1.1 → 2.0 | 14.3 → 11.1 |
| 2 players | 0% | 11.0 → **11.7** | 9.5 → **10.2** | 2.0 → 2.8 | 15.0 → 12.6 |
| 3 players | 0% | 10.9 → **11.9** | 9.5 → **10.5** | 1.9 → 3.5 | 14.4 → 12.1 |
| 4 players | 0% | 10.7 → **11.7** | 9.3 → **10.2** | 1.6 → 3.5 | 13.9 → 12.1 |

**Day the base fell:** most games now end on Days 10–12, and more of them stretch into Days 15–20.
- 2 players: one run made it to Day 20.
- 3 players: one run each made it to Days 19 and 20.

## What changed
- **Every squad lasts about a day longer.** The first tower falls about a day later, and fewer aliens pile up at the walls.
- **Weapons come online earlier:** about 1 weapon by Day 6 (was by Day 8). The weapon count still tops out at about 2 because Makeshift Cannons (4 HP) die quickly when they absorb hits.
- **Still no wins.** Aliens reach 8–9 at the walls by Day 9 against 2 weapons, and the tier 3 waves (Days 14+) finish the runs that make it that far.

## Next levers (by expected impact)
1. **More, sturdier weapons:**
   - Give the Makeshift Cannon 6–8 HP, or let it skip hits like a Shield.
   - Or make bought blueprints about 30% cheaper.
2. **Thin out the walls:** aliens that survive 3 days could retreat, or lower the tier 2 HP a bit.
3. **Look at tier 3 waves on Days 14–20** once mid-game survival improves.


---

# Round 4: Gatling Gun, Resource Drone buff, 2 Hatchlings, 50-gold rebuild (22 Nov 2026)

**Changes tested**
- **Hatchers** spawn 2 Hatchlings again (round 3 used 1).
- **New Gatling Gun:** 5 shots of 1 damage, 12 HP, for 6 Gold + 2 Metal + 3 Scrap.
- **Resource Drone buff:** 3 free resource cards every morning (one each from the Forest, Cave 1 and Cave 2). It now costs 10 Gold + 3 Scrap + 1 Crystal, with no Power Gem, and has 7 HP.
- **Tower rebuild** now costs 50 Gold, plus 4 Power Gems and 10 Metal.
- **Manual fire** now opens the attack screen. The bot uses the instant version, which resolves shots with the same rules.
- The bot now values the Drone more highly early on (days 1–10) and knows about the Gatling Gun.

**400 games** (100 per squad size).

| Squad | Win rate | Avg day reached (round 3 → now) | First tower lost (round 3 → now) | Weapons forged | Peak aliens at walls (round 3 → now) |
|---|---|---|---|---|---|
| 1 player | 0% | 12.2 → **11.5** | 11.3 → **10.6** | 1.6 | 11.1 → **13.5** |
| 2 players | 0% | 11.7 → **11.5** | 10.2 → **10.0** | 2.8 | 12.6 → **15.3** |
| 3 players | 0% | 11.9 → **11.8** | 10.5 → **10.4** | 3.3 | 12.1 → **13.9** |
| 4 players | 0% | 11.7 → **10.8** | 10.2 → **9.6** | 2.6 | 12.1 → **13.8** |

**Day the base fell:**
- Most games still end on Days 9–11.
- 2 players: two runs reached the final day (Day 20).
- 3 players: 8 games fell on Day 17.

**Weapons forged per game (2 players):**

| Weapon | Per game |
|---|---|
| Makeshift Cannon | 0.96 |
| Turret | 0.40 |
| Cannon | 0.37 |
| Plasma Mortar | 0.26 |
| Shield Generator | 0.22 |
| Tesla | 0.17 |
| Cryo Emitter | 0.16 |
| Gatling Gun | 0.06 |
| Resource Drone | 0.02 |

## What changed
- **Slightly harder overall** (−0.1 to −0.9 days). The main cause is the return to 2 Hatchlings: peak aliens at the walls rose by about 2–3 in every squad size. That is what round 1 predicted.
- **The Gatling Gun and Resource Drone barely show up in bot games** (under 0.1 per game). The shop deals 3 random blueprints, and the team can only afford 1–2 purchases, so these two rarely get chosen. The bot can't tell yet whether they're good, so this isn't a verdict on their strength.
- **The core problem is unchanged:** about 2 weapons are online by Day 9–10, against 9–11 aliens at the walls.

## Next levers (by expected impact)
1. **More weapons online by Day 8.** For example:
   - one free blueprint purchase per day at Town,
   - blueprints about 30% cheaper, or
   - shop offers that refresh every day.
2. **Handle the Hatcher snowball differently:** keep 2 Hatchlings but only for the Hatcher's first 2 days, or make Hatchlings die after 2 days.
3. **Sturdier Makeshift Cannon (6 HP).** It's the most-forged weapon by far and dies quickly.
