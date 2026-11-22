extends Node

## The demonstration SQL store against a real database through GameSpice SQL's gateway: the shared store contract.
## Run by GameSpice SQL's runner once per dialect: [code]tools/test_live.sh[/code].

const Contract := preload("res://examples/record_store_contract.gd")

const CHECKS := Contract.CHECKS + 3

var _passed := 0
var _failed := 0


func _ready() -> void:
	GSLog.set_level(GSLog.Level.ERROR)
	var url := OS.get_environment("GS_SQL_URL")
	var name := OS.get_environment("GS_SQL_DIALECT")
	var token_file := OS.get_environment("GS_SQL_TOKEN_FILE")
	var direct := OS.get_environment("GS_SQL_SQLITE_PATH")
	if direct != "":
		name = "sqlite (extension)"
	elif url == "" or name == "" or token_file == "":
		print("set GS_SQL_SQLITE_PATH, or GS_SQL_URL, GS_SQL_DIALECT and GS_SQL_TOKEN_FILE; see tools/test_live.sh")
		get_tree().quit(2)
		return
	print("gs-bot-record live: %s" % name)

	var db := {"driver": "sqlite", "path": direct} if direct != "" else {
		"driver": "gateway", "dialect": name, "url": url,
		"token": FileAccess.get_file_as_string(token_file).strip_edges(),
	}
	# GameSpice SQL by path, as the store does, so this file parses without it.
	var sql_script: Script = load("res://addons/gs_sql/core/gs_sql.gd")
	var make := func() -> GSBotDemoStore:
		var made: GSResult = sql_script.call("from_config", db, self)
		var s := GSBotDemoStoreSql.new(made.value)
		var _o: GSResult = await s.open()
		return s

	# A previous failed run may have left the table; start from nothing so the migration runs.
	var first: GSBotDemoStore = await make.call()
	await first.driver.execute("DROP TABLE IF EXISTS %s" % GSBotDemoStoreSql.TABLE)
	await first.driver.execute("DELETE FROM gs_sql_migrations WHERE component = ?", [GSBotDemoStoreSql.COMPONENT])

	var store: GSBotDemoStore = await make.call()
	var opened: GSResult = await store.open()
	_check(opened.ok, "the migration creates the table on a real %s" % name, str(opened.error.message if not opened.ok else ""))
	var again: GSResult = await store.open()
	_check(again.ok, "opening again does not migrate twice")
	_check(store.driver != null, "the driver is built from the settings")
	await Contract.run(store, make, "live", _check)
	await store.driver.execute("DROP TABLE IF EXISTS %s" % GSBotDemoStoreSql.TABLE)
	await store.driver.execute("DELETE FROM gs_sql_migrations WHERE component = ?", [GSBotDemoStoreSql.COMPONENT])
	await store.close()

	print("")
	print("%d passed, %d failed" % [_passed, _failed])
	if _failed > 0 or _passed != CHECKS:
		print("FAILED: expected %d checks" % CHECKS)
		get_tree().quit(1)
	else:
		get_tree().quit(0)


func _check(ok: bool, what: String, detail: String = "") -> void:
	if ok:
		_passed += 1
		print("  ok    %s" % what)
	else:
		_failed += 1
		print("  FAIL  %s" % (what if detail == "" else "%s (%s)" % [what, detail]))
