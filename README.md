# Alien Game (v2.1)

A tactical co-op sci-fi defense game built in GameMaker. Hold the outpost for 20 days: gather resources, trade for gold, buy weapon blueprints, forge them onto your four towers, and survive the alien waves that hit the walls at the end of every day.

---

## Quick Play (Downloadable Build)

1. Download **[`Alien_Game_v2.1_Windows.zip`](./Alien_Game_v2.1_Windows.zip)**.
2. Extract it anywhere.
3. Run **`Alien Game.exe`**.

---

## How a Day Works

- **Planning:** every operative has energy. Walk the map (1–2 energy per move), gather at the Forest and Caves, sell in Town, buy blueprints at the Shop and forge them onto towers at the Workstation.
- **Defense:** when the squad is out of energy (or you press **Defend**), arm a tower weapon and click an alien to fire. Survivors strike back at your towers — mounted weapons absorb hits first.
- Survive Day 20 and clear the final wave to win, or keep going in Endless Mode.
- Each morning a banner warns you about anything that just reached the walls — it attacks at the end of that day.
- **Workshop extras:** Forge Metal (1 Stone + 1 Scrap), reinforce a tower (+5 max HP for 45 Gold, 3 Power Gems, 10 Metal), and rebuild a fallen tower once (50 Gold, 4 Power Gems, 10 Metal).
- **Gatling Gun:** 5 shots of 1 damage, 12 HP (6 Gold, 2 Metal, 3 Scrap). Great against swarms of small aliens and with Overcharge Pylons.
- **Starter weapon:** every mission begins with the **Makeshift Cannon** blueprint (3 Stone, 2 Wood, 1 Scrap; 5 damage, 4 HP). It's never used up, so you can always forge one onto an empty tower.
- **Starting gold:** solo 0, duo 5, trio 10, squad of four 15.
- **Market:** pick items with + / - (mix any resources); each trade sells up to 3 items for one action's energy, and the total gold and energy are shown before you sell.
- **Energy Pylon:** solo +5 energy per day; duo +2 each; trio +1 each with one operative (rotating daily) getting +2; squad of 4 +1 each.

## Controls

| Key | Action |
| --- | --- |
| `W A S D` / Arrows | Move to a connected location (press two together for diagonals) |
| Click a location | Move there, or interact if you're standing on it |
| `E` | Interact with your current location |
| `G` | Gather |
| `C` / `X` | Forge Metal (in the Workshop) / Demolish a tower weapon (get up to 75% of its materials back) |
| `S` `R` `T` | Shop, Workshop, Market |
| `F` | Fire the tower weapon you're standing on |
| `Space` | End turn (online: Ready Up) |
| `B` | Start the defense phase (local play) |
| `Tab` / `1`–`4` | Switch operative (local play) |
| `Enter` | Chat / add a note to the log |
| `Esc` | Pause menu · `F1` / `H` How to Play · `F11` Fullscreen |

The action bar shows two buttons for wherever you're standing (e.g. Gather in the Forest, Fire/Demolish on a tower) plus End Turn and Defend.

In the defense view: `1`–`4` arm a weapon, click an alien to fire, `Space` ends the volley / continues, `Tab` toggles 2x speed.

## Multiplayer (Local Network, 2–4 Players)

- **Host:** Play on LAN → Create Room. Your IP is shown in the lobby header.
- **Join:** Play on LAN → rooms on the same Wi-Fi appear automatically, or click the Direct IP box, type the host's IP and press Enter.
- The host runs the game simulation; everyone else sends their actions to the host and receives live state updates, so every screen stays in sync. Each player controls only their own operative. If someone disconnects mid-mission, their operative stands by so the squad isn't blocked.
- Ports: TCP 6510 (game), UDP 6511 (room discovery). Allow the game through Windows Firewall when prompted.

## Roles

Each squad can have at most one of each specialist (`Scout`, `Combat Engineer`, `Cavern Miner`, `Gunner`, `Pathfinder`); `Survivor` can be picked by anyone.

---

## AI Usage

- AI tools were used to assist in the coding process. No AI assets are used.

## Building from Source

- **Engine:** GameMaker 2026.1+
- Open `Alien Game.yyp` and press **Run**.
- Automated test scenarios can be run by launching the game with `-autotest ui_tour`, or two copies with `-autotest net_host` and `-autotest net_client`. Results and screenshots are written to `%LOCALAPPDATA%\Alien_Game\autotest\`.
