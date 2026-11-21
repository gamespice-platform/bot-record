class_name GSBotDemoStoreMemory
extends GSBotDemoStore

## Episodes held in memory, for suites and for hosts that only want a tally.

## Every episode held, oldest first.
var episodes: Array = []

var _next_id: int = 1


func append(batch: Array) -> GSResult:
	for item: Variant in batch:
		var e := item as GSBotDemoEpisode
		if e == null:
			return GSResult.fail(GSError.CODE_INVALID, "A store holds GSBotDemoEpisode, not %s." % type_string(typeof(item)))
		e.id = _next_id
		_next_id += 1
		episodes.append(e)
	return GSResult.success(batch.size())


func counts(map_id: String, map_version: String, kind: String) -> GSResult:
	var out := {}
	for e: GSBotDemoEpisode in episodes:
		if e.map_id == map_id and e.map_version == map_version and e.kind == kind:
			out[e.key] = int(out.get(e.key, 0)) + (1 if e.verified else 0)
	return GSResult.success(out)


func load(map_id: String, map_version: String, kind: String, key: String, limit: int) -> GSResult:
	var found: Array = []
	for e: GSBotDemoEpisode in episodes:
		if e.map_id == map_id and e.map_version == map_version and e.kind == kind and e.key == key:
			found.append(e)
	found.sort_custom(_better)
	if limit > 0 and found.size() > limit:
		found.resize(limit)
	return GSResult.success(found)


func mark(ids: Array, verified: bool, score: float) -> GSResult:
	var changed := 0
	for e: GSBotDemoEpisode in episodes:
		if ids.has(e.id):
			e.verified = verified
			e.score = score
			changed += 1
	return GSResult.success(changed)


func remove(ids: Array) -> GSResult:
	var kept: Array = []
	for e: GSBotDemoEpisode in episodes:
		if not ids.has(e.id):
			kept.append(e)
	var gone := episodes.size() - kept.size()
	episodes = kept
	return GSResult.success(gone)


func prune(map_id: String, keep_version: String) -> GSResult:
	var kept: Array = []
	for e: GSBotDemoEpisode in episodes:
		if e.map_id != map_id or e.map_version == keep_version:
			kept.append(e)
	var dropped := episodes.size() - kept.size()
	episodes = kept
	return GSResult.success(dropped)


func describe_lines() -> PackedStringArray:
	return PackedStringArray(["store memory: %d episodes" % episodes.size()])


static func _better(a: GSBotDemoEpisode, b: GSBotDemoEpisode) -> bool:
	return a.score > b.score
