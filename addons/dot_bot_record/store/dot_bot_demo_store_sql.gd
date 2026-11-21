class_name GSBotDemoStoreSql
extends GSBotDemoStore

## Episodes in a database through a GameSpice SQL driver, held untyped so GameSpice Bot Record does not need GameSpice SQL.
## The column is [code]edge_key[/code] because [code]key[/code] is reserved in one dialect.

const COMPONENT := "dot-bot:demos"
const TABLE := "dot_bot_demos"
const COLUMNS := "id, map_id, map_version, schema_id, kind, edge_key, day, rate, frame_size, outcome, verified, score, start, ticks"

## The GameSpice SQL driver, not yet open.
var driver = null

var _last_id: int = 0


func _init(p_driver: Variant = null) -> void:
	driver = p_driver


## The migration steps; append a step, never edit one.
static func migration_steps() -> Array:
	return [[{
		"name": TABLE,
		"columns": [
			{"name": "id", "type": "bigint", "null": false},
			{"name": "map_id", "type": "key", "null": false},
			{"name": "map_version", "type": "key", "null": false},
			{"name": "schema_id", "type": "key", "null": false},
			{"name": "kind", "type": "key", "null": false},
			{"name": "edge_key", "type": "key", "null": false},
			{"name": "day", "type": "key", "null": false},
			{"name": "rate", "type": "real", "null": false, "default": 0},
			{"name": "frame_size", "type": "int", "null": false, "default": 0},
			{"name": "outcome", "type": "key", "null": false},
			{"name": "verified", "type": "int", "null": false, "default": 0},
			{"name": "score", "type": "real", "null": false, "default": 0},
			{"name": "start", "type": "json"},
			{"name": "ticks", "type": "text"},
		],
		"primary_key": ["id"],
		"indexes": [{"name": "dot_bot_demos_by_edge", "columns": ["map_id", "map_version", "kind", "edge_key", "score"]}],
	}]]


func open() -> GSResult:
	if driver == null:
		return GSResult.fail(GSError.CODE_STATE, "No SQL driver.")
	var available: GSResult = driver.is_available()
	if not available.ok:
		return available
	var opened: GSResult = await driver.open()
	if not opened.ok:
		return opened
	var migrated: GSResult = await driver.migrate(COMPONENT, migration_steps())
	if not migrated.ok:
		return migrated.wrap("Could not prepare the demonstration table.")
	return GSResult.success(true)


func close() -> GSResult:
	if driver != null:
		driver.close()
	return GSResult.success(null)


func append(batch: Array) -> GSResult:
	var statements: Array = []
	var sql := "INSERT INTO %s (%s) VALUES (%s)" % [TABLE, COLUMNS, ", ".join(_marks(14))]
	for item: Variant in batch:
		var e := item as GSBotDemoEpisode
		if e == null:
			return GSResult.fail(GSError.CODE_INVALID, "A store holds GSBotDemoEpisode, not %s." % type_string(typeof(item)))
		e.id = _new_id()
		statements.append([sql, [
			e.id, e.map_id, e.map_version, e.schema_id, e.kind, e.key, e.day, e.rate, e.frame_size,
			e.outcome, 1 if e.verified else 0, e.score, JSON.stringify(e.start),
			Marshalls.raw_to_base64(e.ticks.to_byte_array()),
		]])
	var res: GSResult = await driver.batch(statements)
	if not res.ok:
		return res.wrap("Could not store %d episodes." % batch.size())
	return GSResult.success(batch.size())


func counts(map_id: String, map_version: String, kind: String) -> GSResult:
	var res: GSResult = await driver.query(
		"SELECT edge_key, verified, COUNT(*) AS n FROM %s WHERE map_id = ? AND map_version = ? AND kind = ? GROUP BY edge_key, verified" % TABLE,
		[map_id, map_version, kind])
	if not res.ok:
		return res
	var out := {}
	for row: Dictionary in res.value:
		var key := str(row["edge_key"])
		out[key] = int(out.get(key, 0)) + (int(row["n"]) if int(row["verified"]) != 0 else 0)
	return GSResult.success(out)


func load(map_id: String, map_version: String, kind: String, key: String, limit: int) -> GSResult:
	var sql := "SELECT %s FROM %s WHERE map_id = ? AND map_version = ? AND kind = ? AND edge_key = ? ORDER BY score DESC, id" % [COLUMNS, TABLE]
	var params: Array = [map_id, map_version, kind, key]
	if limit > 0:
		sql += " LIMIT ?"
		params.append(limit)
	var res: GSResult = await driver.query(sql, params)
	if not res.ok:
		return res
	var out: Array = []
	for row: Dictionary in res.value:
		out.append(_episode(row))
	return GSResult.success(out)


func mark(ids: Array, verified: bool, score: float) -> GSResult:
	var changed := 0
	for i in range(0, ids.size(), 50):
		var part: Array = ids.slice(i, i + 50)
		var params: Array = [1 if verified else 0, score]
		params.append_array(part)
		var res: GSResult = await driver.execute(
			"UPDATE %s SET verified = ?, score = ? WHERE id IN (%s)" % [TABLE, ", ".join(_marks(part.size()))], params)
		if not res.ok:
			return res
		changed += part.size()
	return GSResult.success(changed)


func remove(ids: Array) -> GSResult:
	var gone := 0
	for i in range(0, ids.size(), 50):
		var part: Array = ids.slice(i, i + 50)
		var res: GSResult = await driver.execute(
			"DELETE FROM %s WHERE id IN (%s)" % [TABLE, ", ".join(_marks(part.size()))], part)
		if not res.ok:
			return res
		gone += part.size()
	return GSResult.success(gone)


func prune(map_id: String, keep_version: String) -> GSResult:
	var seen: GSResult = await driver.query_value(
		"SELECT COUNT(*) FROM %s WHERE map_id = ? AND map_version <> ?" % TABLE, [map_id, keep_version], 0)
	if not seen.ok:
		return seen
	var res: GSResult = await driver.execute(
		"DELETE FROM %s WHERE map_id = ? AND map_version <> ?" % TABLE, [map_id, keep_version])
	if not res.ok:
		return res
	return GSResult.success(int(seen.value))


func describe_lines() -> PackedStringArray:
	var name := str(driver.driver_name()) if driver != null else "none"
	return PackedStringArray(["store sql: driver %s, table %s" % [name, TABLE]])


## Unique across restarts and servers sharing a database, without a round trip.
func _new_id() -> int:
	_last_id = maxi(_last_id + 1, int(Time.get_unix_time_from_system() * 1000.0))
	return _last_id


static func _marks(n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append("?")
	return out


static func _episode(row: Dictionary) -> GSBotDemoEpisode:
	var e := GSBotDemoEpisode.new()
	e.id = int(row["id"])
	e.map_id = str(row["map_id"])
	e.map_version = str(row["map_version"])
	e.schema_id = str(row["schema_id"])
	e.kind = str(row["kind"])
	e.key = str(row["edge_key"])
	e.day = str(row["day"])
	e.rate = float(row["rate"])
	e.frame_size = int(row["frame_size"])
	e.outcome = str(row["outcome"])
	e.verified = int(row["verified"]) != 0
	e.score = float(row["score"])
	var parsed: Variant = JSON.parse_string(str(row.get("start", "")))
	e.start = parsed if parsed is Dictionary else {}
	e.ticks = Marshalls.base64_to_raw(str(row.get("ticks", ""))).to_float32_array()
	return e
