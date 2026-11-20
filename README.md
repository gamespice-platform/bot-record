[![Bot Record - GameSpice addon](docs/banner.png)](https://moddingcommunity.com/a/105-gs-bot-record)

A demonstration recorder for Godot 4.7+. A dedicated server records what players do, as episodes in a schema your game declares, so bots can learn from them. Part of the [GameSpice](https://github.com/gamespice-platform) family. It needs only [GameSpice Core](https://github.com/gamespice-platform/core).

Nothing identifying is kept. Recording is on by default and is switched off with `bot_record 0`.

## Install

1. Copy `addons/dot_bot_record/` and `addons/dot_core/` into your project.
2. Enable the plugin in *Project > Project Settings > Plugins*.

## Use

Register a `DotBotDemoSchema` for each kind of episode. Then call `begin`, `sample` and `end` on a `DotBotDemoRecorder`.

The recorder samples fast while a key has few recordings and falls to a base rate once it has enough. Finished episodes are queued and written in time-budgeted batches to a store.

| Store | Use it for |
| --- | --- |
| JSON files (default) | One file per map version and kind. |
| SQL | Through [GameSpice SQL](https://github.com/gamespice-platform/sql), by duck typing. |
| Memory | Tests. |

The settings, the schema and the privacy rules are in [docs/demonstration-recorder.md](docs/demonstration-recorder.md).

## Test

```bash
godot --headless --path . --import
godot --headless --path . res://examples/record_selftest.tscn
```

## Status

Built and maintained with Claude Code. The test suites pass, but little of this has been in front of real players yet. Please report rough edges by opening an issue.

## Licence

MIT. See [LICENSE](LICENSE). Only the TMC back-end web infrastructure is not open source.
