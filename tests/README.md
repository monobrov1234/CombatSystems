# CombatSystems tests

The test project is separate from the game project, so the game's module loaders do not require the test files.

## First-time setup

Run these commands from the repository root:

```powershell
aftman install
cd tests
wally install
```

## Build and run

From the repository root, build the test place:

```powershell
rojo build tests/default.project.json -o tests/build.rbxlx
```

Open `tests/build.rbxlx` in Roblox Studio. Open **Script → Output**, and run:

```lua
require(game.ReplicatedStorage.runner).run()
```

Check the Studio Output for the Jest results.
