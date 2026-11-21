extends RefCounted

## gs-bot-record's API level. The rule for bumping it is on [GSAddonApi].

# 1: the recorder, moved out of gs-bot (its API level 5) with every class name unchanged.
#    GSBotDemoSchema, GSBotDemoEpisode, GSBotDemoRecorder, GSBotDemoConfig (bind_cvars),
#    GSBotDemoStore (from_config), GSBotDemoStoreMemory, GSBotDemoStoreJson, GSBotDemoStoreSql.
const LEVEL := 1
const OLDEST := 1
