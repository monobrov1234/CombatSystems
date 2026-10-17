# CombatSystems tests

The test project is separate from the game project, so the game's module loaders do not require the test files.

## First-time setup

Run these commands from the repository root:

```powershell
aftman install
Push-Location tests
wally install
Pop-Location
```

## Build and run

From the repository root, build the test place:

```powershell
rojo build tests/default.project.json -o tests/build.rbxlx
```

Open `tests/build.rbxlx` in Roblox Studio. Stay in edit mode (do not press **F8**), open **View → Command Bar**, and run:

```lua
require(game.ServerScriptService.TestRunner.RunTests)()
```

Check the Studio Output for the Jest results and `CombatSystems tests passed`.

Jest reads test ModuleScript source while discovering and loading suites. Roblox only permits that from Studio's Command Bar or Open Cloud, so the runner cannot run as a normal server Script in Play/Run mode.

The current placeholder test intentionally contains no assertions. Replace or supplement it with real tests as coverage is added.
