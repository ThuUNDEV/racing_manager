extends Node
## Optional local audio helper. Adds missing buses without replacing the game's layout.
## Stream looping is configured from the catalog, including in a clean import.
const ROOT := "res://assets/workshop_gp/audio/"
var music_enabled := true
var sfx_enabled := true
var _players: Array[AudioStreamPlayer] = []
var _catalog: Array = []


func _ready() -> void:
	_catalog = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "catalog.json")) as Array
	for entry: Array in [["Music", -10.0], ["SFX", -6.0], ["Engine", -15.0]]:
		if AudioServer.get_bus_index(entry[0]) < 0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, entry[0])
			AudioServer.set_bus_send(index, "Master")
			AudioServer.set_bus_volume_db(index, entry[1])


func play(cue: String) -> AudioStreamPlayer:
	var is_music := cue.begins_with("music_")
	if (is_music and not music_enabled) or (not is_music and not sfx_enabled):
		return null
	var path := ROOT + cue + ".wav"
	if not ResourceLoader.exists(path):
		push_warning("Unknown Workshop GP audio cue: " + cue)
		return null
	var stream := (load(path) as AudioStreamWAV).duplicate() as AudioStreamWAV
	for record: Dictionary in _catalog:
		if record.path == "audio/" + cue + ".wav" and bool(record.loop):
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(round(float(record.duration) * stream.mix_rate))
	var player := AudioStreamPlayer.new()
	player.bus = "Music" if is_music else ("Engine" if cue.begins_with("engine_") else "SFX")
	player.stream = stream
	add_child(player)
	_players.append(player)
	player.finished.connect(func():
		_players.erase(player)
		player.queue_free()
	)
	player.play()
	return player


func stop_all() -> void:
	for player in _players:
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_players.clear()
