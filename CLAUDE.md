# GameSpice Bot Record

**A demonstration recorder.** A host declares a schema (a kind of episode, its observation and action fields); the recorder samples what players do at an adaptive rate, queues finished episodes and writes them in budgeted batches to a store. Extracted from GameSpice Bot, which keeps the consumers (ride harvest, ride book) and uses this addon optionally.

Read the family [CLAUDE.md](../../CLAUDE.md) first; this file is only what is specific to the recorder.

**Depends on GameSpice Core alone.** GameSpice SQL is reached by duck typing (`GSBotDemoStoreSql` holds an untyped driver), so a game without it gets the JSON store. Keep it that way.

## Read before

| Read | Before |
| --- | --- |
| [docs/demonstration-recorder.md](docs/demonstration-recorder.md) | anything here: the schema, rate, privacy rules, stores. Its later stages (harvest, heatmap, aim stats, cloning) are GameSpice Bot's |

## Layout

| Path | What |
| --- | --- |
| `addons/dot_bot_record/core/` | `GSBotDemoSchema` (host-declared fields), `GSBotDemoEpisode`, `GSBotDemoRecorder` (begin/sample/end/cancel, adaptive rate, queue, budgeted writes via `process`), `GSBotDemoConfig` (`bot_record*`, ON by default) |
| `addons/dot_bot_record/store/` | `GSBotDemoStore` (base, `from_config`), `GSBotDemoStoreMemory`, `GSBotDemoStoreJson`, `GSBotDemoStoreSql` |
| `examples/record_selftest.tscn` | the suite |
| `examples/record_live.tscn`, `tools/test_live.sh` | the SQL store against a real database through the GameSpice SQL gateway (SQLite and the extension here; PostgreSQL and MariaDB when `GS_SQL_PG_DSN` / `GS_SQL_MYSQL_DSN` are set) |

## Rules that bite

- **The class names kept their `GSBotDemo*` prefix, the cvars their `bot_record*` names, the SQL table `dot_bot_demos` and its migration component `gs-bot:demos`.** Renaming any of them orphans saved data or breaks games; a rename is an API-level bump (`OLDEST`) with every game edited in the same pass.
- Nothing identifying is kept: no names, no ids, a day and nothing finer. The suite checks it.
- Consumers (GameSpice Bot) type a store, schema or episode as `Variant`/`Object`, never by these class names, so they compile without this addon.
- Link `addons/dot_core` (and optionally `dot_sql`, `godot-sqlite`) from their repos; both gitignored.

## Running and testing

The family's two steps ([family CLAUDE.md](../../CLAUDE.md#validating-anything)) and `timeout 180 godot --headless --path . res://examples/record_selftest.tscn`.
