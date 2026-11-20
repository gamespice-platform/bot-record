extends Node

## The demonstration SQL store against a real database through GameSpice SQL's gateway: the shared store contract.
## Run by GameSpice SQL's runner once per dialect: [code]tools/test_live.sh[/code].

const Contract := preload("res://examples/record_store_contract.gd")

const CHECKS := Contract.CHECKS + 3

var _passed := 0
var _failed := 0


func _ready() -> void:
	DotLog.set_level(DotLog.Level.ERROR)
	var url := (OS.get_environment("GS_SQL_URL") if OS.has_environment("GS_SQL_URL") else OS.get_environment("DOT_SQL_URL"))
	var name := (OS.get_environment("GS_SQL_DIALECT") if OS.has_environment("GS_SQL_DIALECT") else OS.get_environment("DOT_SQL_DIALECT"))
	var token_file := (OS.get_environment("GS_SQL_TOKEN_FILE") if OS.has_environment("GS_SQL_TOKEN_FILE") else OS.get_environment("DOT_SQL_TOKEN_FILE"))
	var direct := (OS.get_environment("GS_SQL_SQLITE_PATH") if OS.has_environment("GS_SQL_SQLITE_PATH") else OS.get_environment("DOT_SQL_SQLITE_PATH"))
	if direct != "":
		name = "sqlite (extension)"
	elif url == "" or name == "" or token_file == "":
		print("set GS_SQL_SQLITE_PATH, or GS_SQL_URL, GS_SQL_DIALECT and GS_SQL_TOKEN_FILE; see tools/test_live.sh")
		get_tree().quit(2)
		return
	print("dot-bot-record live: %s" % name)

	var db := {"driver": "sqlite", "path": direct} if direct != "" else {
		"driver": "gateway", "dialect": name, "url": url,
		"token": FileAccess.get_file_as_string(token_file).strip_edges(),
	}
	# GameSpice SQL by path, as the store does, so this file parses without it.
	var sql_script: Script = load("res://addons/dot_sql/core/dot_sql.gd")
	var make := func() -> DotBotDemoStore:
		var made: DotResult = sql_script.call("from_config", db, self)
		var s := DotBotDemoStoreSql.new(made.value)
		var _o: DotResult = await s.open()
		return s

	# A previous failed run may have left the table; start from nothing so the migration runs.
	var first: DotBotDemoStore = await make.call()
	await first.driver.execute("DROP TABLE IF EXISTS %s" % DotBotDemoStoreSql.TABLE)
	await first.driver.execute("DELETE FROM dot_sql_migrations WHERE component = ?", [DotBotDemoStoreSql.COMPONENT])

	var store: DotBotDemoStore = await make.call()
	var opened: DotResult = await store.open()
	_check(opened.ok, "the migration creates the table on a real %s" % name, str(opened.error.message if not opened.ok else ""))
	var again: DotResult = await store.open()
	_check(again.ok, "opening again does not migrate twice")
	_check(store.driver != null, "the driver is built from the settings")
	await Contract.run(store, make, "live", _check)
	await store.driver.execute("DROP TABLE IF EXISTS %s" % DotBotDemoStoreSql.TABLE)
	await store.driver.execute("DELETE FROM dot_sql_migrations WHERE component = ?", [DotBotDemoStoreSql.COMPONENT])
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
