class_name GSBotDemoStore
extends RefCounted

## Where recorded episodes go. Every method returns a [GSResult] and may be a coroutine, so always await.
##
## The base refuses what it does not implement; a store overrides what it can do.

func open() -> GSResult:
	return GSResult.success(null)


func close() -> GSResult:
	return GSResult.success(null)


## Stores one batch; the value is how many were kept.
func append(_episodes: Array) -> GSResult:
	return _unsupported("append")


## The value is {key: verified count} for a map version and kind.
func counts(_map_id: String, _map_version: String, _kind: String) -> GSResult:
	return _unsupported("counts")


## The value is an Array of episodes, best score first.
func load(_map_id: String, _map_version: String, _kind: String, _key: String, _limit: int) -> GSResult:
	return _unsupported("load")


## Records a consumer's verdict on [param ids].
func mark(_ids: Array, _verified: bool, _score: float) -> GSResult:
	return _unsupported("mark")


## Deletes the episodes with these ids; the value is how many were there.
func remove(_ids: Array) -> GSResult:
	return _unsupported("remove")


## Drops the episodes of every other version of [param map_id]; the value is how many.
func prune(_map_id: String, _keep_version: String) -> GSResult:
	return _unsupported("prune")


func describe_lines() -> PackedStringArray:
	return PackedStringArray()


## The store [param config] names, not yet open; null for "off". A database setting without GameSpice SQL installed is said at ERROR and the JSON store is used.
static func from_config(config: GSBotDemoConfig, host: Node = null) -> GSResult:
	match config.store:
		"off":
			return GSResult.success(null)
		"memory":
			return GSResult.success(GSBotDemoStoreMemory.new())
		"json":
			return GSResult.success(GSBotDemoStoreJson.new(config.path))
	# GameSpice SQL is reached by path: naming GSSql would make a pack fail to parse on a host without it.
	var script_path := "res://addons/gs_sql/core/gs_sql.gd"
	if not ResourceLoader.exists(script_path):
		GSLog.error("bot.demo.store", "bot_record_store is %s but gs-sql is not installed; recording to files" % config.store)
		return GSResult.success(GSBotDemoStoreJson.new(config.path))
	var db := {"driver": "sqlite", "dialect": "sqlite", "path": config.path}
	if config.store == "sqlite":
		if config.path.get_extension() == "":
			db["path"] = config.path.path_join("demos.db")
		var made_dir := GSPaths.ensure_parent_dir(db["path"])
		if not made_dir.ok:
			return made_dir
	else:
		db = {"driver": "gateway", "dialect": config.store, "url": config.url, "token": config.token}
	var sql_script: Script = load(script_path)
	var made: GSResult = sql_script.call("from_config", db, host)
	if not made.ok or made.value == null:
		GSLog.error("bot.demo.store", "the demonstration database settings are not usable; recording to files")
		return GSResult.success(GSBotDemoStoreJson.new(config.path))
	return GSResult.success(GSBotDemoStoreSql.new(made.value))


func _unsupported(what: String) -> GSResult:
	return GSResult.fail(GSError.CODE_UNSUPPORTED, "This store does not support %s." % what)
