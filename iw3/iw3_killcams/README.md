# IW3 Final Killcams

Final-killcam support for Call of Duty 4 multiplayer servers running CoD4X/CodXE-style GSC scripting.

The mod displays a cinematic replay of the last valid player kill when a round or game ends. The implementation is kept in its own script file and included by the multiplayer global-logic script.

## Features
- Works with both team-based and free-for-all scoring logic.
- Skips the killcam when there was no valid player kill.
- Skips suicides, world/environmental deaths, and invalid or disconnected attackers.
- Uses the normal game-end flow when no killcam is available.

## Requirements

- A CoD4X/CodXE-compatible game with GSC script support.
- A multiplayer setup that uses `maps/mp/gametypes/_globallogic.gsc`.
- The `white` shader and `mp_global_intermission` spawnpoint available to the map.

## Installation

The repository package is located under `iw3/iw3_killcams/`. Copy its contents into a mod directory, not the outer `iw3` directory.

Your setup should look similar to this:

```text
Call of Duty 4/
└── mods/
    └── iw3_killcams/
        ├── maps/
        │   └── mp/
        │       └── gametypes/
        │           └── _globallogic.gsc
        └── scripts/
            └── _finalkillcam.gsc
```

1. Unload the mod.
2. Back up your existing `maps/mp/gametypes/_globallogic.gsc`.
3. Copy the repository's `maps/mp/gametypes/_globallogic.gsc` and `scripts/_finalkillcam.gsc` into the matching paths inside your mod.
4. Start the match with the mod enabled.

### Installing into an existing mod

This mod replaces the multiplayer global-logic script. If your existing mod already changes `_globallogic.gsc`, merge the killcam changes into that file instead of blindly overwriting it.

The required integration is:

At the top of `_globallogic.gsc`:

```gsc
#include scripts\_finalkillcam;
```

Inside the global `init()` function:

```gsc
init_kc();
```

Inside `Callback_PlayerKilled()`, after the normal player-killed callback is started:

```gsc
onPlayerKilledHook(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon,
                   vDir, sHitLoc, psOffsetTime, deathAnimDuration);
```

The endgame logic must call these included functions without a script namespace:

```gsc
canStartFK( true );
startFK( winner, true );
canStartFK( false );
startFK( winner, false );
resetFinalKillcam();
```

Do not use `scripts\_finalkillcam::startFK()` after adding the `#include`. The include keeps the files separate on disk while making their functions available to `_globallogic.gsc` during compilation.

## Game-mode behavior

The script is designed around the stock global endgame flow, so it can be used by any gametype that uses the normal `_globallogic.gsc` callbacks.

| Mode type | Behavior |
| --- | --- |
| Round-based modes such as Search and Destroy/Sabatage/Headquarters | Shows the last valid kill as a round-winning kill before the next round. |
| Team-based score/time modes such as Team Deathmatch | Shows a game-winning kill when the match fully ends. |
| Free-for-all modes such as Deathmatch | Uses the last valid player kill and the normal free-for-all winner. |
| Games with no valid player kill | Skips the replay and continues through the normal game or round end. |

The exact result depends on the gametype's existing round-limit, score-limit, time-limit, and winner logic. The killcam does not decide who wins; it only displays the final valid kill after the game has already selected a winner.

## How it works

1. `init_kc()` initializes the killcam state and starts a connection watcher.
2. `onPlayerKilledHook()` records the latest valid player-versus-player kill.
3. When global logic reaches a round or game-ending point, `canStartFK()` checks whether usable kill data exists.
4. `startFK()` notifies every connected player.
5. Each player's `beginFK()` thread enters spectator mode and replays the attacker's archived view.
6. The replay HUD is created by `CreateFKMenu()` and cleaned up by `CleanFK()`.
7. If there is no valid kill, the normal endgame flow continues without waiting for a killcam.

The replay currently uses approximately five seconds of camera footage followed by a two-second end delay. These values can be adjusted in `scripts/_finalkillcam.gsc`:

```gsc
camtime = 5;
postdelay = 2;
```

## Troubleshooting

### `unknown function`

Check that:

- `_finalkillcam.gsc` exists at `scripts/_finalkillcam.gsc` inside the active mod.
- `_globallogic.gsc` contains `#include scripts\_finalkillcam;`.
- Included functions are called without `scripts\_finalkillcam::`.
- The game was fully restarted after changing the scripts.
- A `.gsx` version is not overriding the `.gsc` file unexpectedly.

### The killcam never appears

Confirm that the kill was caused by another connected player. Suicides, grenade/world deaths, killstreak deaths, and disconnected attackers are intentionally ignored. Also verify that the game is actually loading this `_globallogic.gsc` override.

### The game does not end when nobody got a kill

The no-kill path is intentional: no final-killcam wait is performed. The game proceeds through its normal round-end or post-round delay and then restarts or exits according to the gametype limits.

### The replay spawn fails

The replay cleanup expects a map entity named `mp_global_intermission`. Custom maps without that spawnpoint may need one added or may require a custom fallback in `finalkillcam()`.

## Notes for maintainers

Keep the implementation in `scripts/_finalkillcam.gsc`. `_globallogic.gsc` should contain only the include, initialization call, player-killed hook, and endgame integration. This makes future updates easier and avoids maintaining two copies of the killcam code.

## Notes for bugs
If any bugs or issues happen, contact me or make a bug report on github.

See [LICENSE](LICENSE) for licensing information.