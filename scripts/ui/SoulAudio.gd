extends Node
class_name SoulAudio

const SAMPLE_RATE: int = 22050

var random := RandomNumberGenerator.new()

func _ready() -> void:
	random.randomize()

func play_sfx(event_name: String) -> void:
	var profile: Dictionary = _get_profile(event_name)
	if profile.is_empty():
		return
	var player := AudioStreamPlayer.new()
	player.stream = _create_tone(profile)
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()

func _get_profile(event_name: String) -> Dictionary:
	match event_name:
		"shuffle":
			return {"duration": 0.28, "start_hz": 520.0, "end_hz": 260.0, "noise": 0.44, "harmonics": 0.18, "decay": 3.0}
		"summon":
			return {"duration": 0.24, "start_hz": 300.0, "end_hz": 720.0, "noise": 0.04, "harmonics": 0.48, "decay": 2.8}
		"damage":
			return {"duration": 0.17, "start_hz": 190.0, "end_hz": 82.0, "noise": 0.32, "harmonics": 0.22, "decay": 4.8}
		"destroy":
			return {"duration": 0.34, "start_hz": 260.0, "end_hz": 48.0, "noise": 0.62, "harmonics": 0.3, "decay": 5.2}
		"discard":
			return {"duration": 0.19, "start_hz": 680.0, "end_hz": 250.0, "noise": 0.34, "harmonics": 0.1, "decay": 4.2}
		"effect":
			return {"duration": 0.3, "start_hz": 540.0, "end_hz": 1040.0, "noise": 0.03, "harmonics": 0.52, "decay": 3.4}
		"coin_flip":
			return {"duration": 0.16, "start_hz": 1180.0, "end_hz": 540.0, "noise": 0.05, "harmonics": 0.38, "decay": 2.4}
		"coin_land":
			return {"duration": 0.25, "start_hz": 240.0, "end_hz": 860.0, "noise": 0.08, "harmonics": 0.62, "decay": 4.0}
		_:
			return {}

func _create_tone(profile: Dictionary) -> AudioStreamWAV:
	var sample_count: int = int(SAMPLE_RATE * float(profile["duration"]))
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var phase: float = 0.0
	var start_hz: float = float(profile["start_hz"])
	var end_hz: float = float(profile["end_hz"])
	var noise_amount: float = float(profile["noise"])
	var harmonic_amount: float = float(profile["harmonics"])
	var decay: float = float(profile["decay"])
	for sample_index in range(sample_count):
		var progress: float = float(sample_index) / float(sample_count)
		var frequency: float = lerpf(start_hz, end_hz, progress)
		phase += TAU * frequency / float(SAMPLE_RATE)
		var envelope: float = sin(PI * progress) * exp(-decay * progress)
		var tone: float = sin(phase) + sin(phase * 2.0) * harmonic_amount + sin(phase * 3.0) * harmonic_amount * 0.22
		var noise: float = random.randf_range(-1.0, 1.0) * noise_amount
		var value: float = clampf((tone + noise) * envelope * 0.58, -1.0, 1.0)
		data.encode_s16(sample_index * 2, int(value * 32767.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
