extends Node
class_name Sfx

static var live: Node

var sfx_on := true
var amb_on := true
var _player: AudioStreamPlayer
var _gen: AudioStreamGenerator
var _amb_player: AudioStreamPlayer
var _amb_gen: AudioStreamGenerator
var _voice_pool: Array[AudioStreamPlayer] = []
var _voice_i := 0
var _chick_streams: Array[AudioStream] = []
var _hen_streams: Array[AudioStream] = []
var _egg_step := 0
var _hens := 0
var _chicks := 0
var _night := false
var _call_wait := 2.2
var _from_amb := false
var _amb_gain := 0.0
var _brown_l := 0.0
var _brown_r := 0.0
var _lp_l := 0.0
var _lp_r := 0.0
var _wind_t := 0.0
var _wind_t2 := 0.0
var _grass_t := 99.0
var _grass_len := 0.08
var _grass_amp := 0.0
var _grass_bright := 0.45
var _grass_gate := 0.0
var _grass_kind := 0
var _grass_pan := 0.0
var _grass_cut := 0.22
var _grass_hp := 0.0
var _grass_bp := 0.0
var _grass_click_at := 0.35
var _grass_click2 := 0.7
var _surf := 0
var _tap_phase := 0.0
var _tap_freq := 190.0

func _ready() -> void:
	live = self
	_gen = AudioStreamGenerator.new()
	_gen.mix_rate = 22050.0
	_gen.buffer_length = 0.55
	_player = AudioStreamPlayer.new()
	_player.stream = _gen
	_player.volume_db = 0.0
	add_child(_player)
	_amb_gen = AudioStreamGenerator.new()
	_amb_gen.mix_rate = 22050.0
	_amb_gen.buffer_length = 0.22
	_amb_player = AudioStreamPlayer.new()
	_amb_player.stream = _amb_gen
	_amb_player.volume_db = -2.0
	add_child(_amb_player)
	for _i in 4:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		_voice_pool.append(voice)
	_chick_streams = _load_streams([
		"res://assets/sfx/chick_1.wav",
		"res://assets/sfx/chick_2.wav",
		"res://assets/sfx/chick_3.wav",
	])
	_hen_streams = _load_streams([
		"res://assets/sfx/hen_1.wav",
		"res://assets/sfx/hen_2.wav",
	])

func _exit_tree() -> void:
	if live == self:
		live = null

func unlock() -> void:
	if not _player.playing:
		_player.play()
	if not _amb_player.playing:
		_amb_player.play()

func set_sfx(on: bool) -> void:
	sfx_on = on

func set_amb(on: bool) -> void:
	amb_on = on
	if on:
		unlock()

func set_flock(hens: int, chicks: int) -> void:
	_hens = maxi(0, hens)
	_chicks = maxi(0, chicks)

func set_night(night: bool) -> void:
	_night = night
	if night:
		_call_wait = randf_range(3.5, 6.0)

static func grass_step(chick: bool, at: Vector2 = Vector2(48, 62)) -> void:
	if live:
		live._queue_step(chick, at)

func _surface_at(p: Vector2) -> int:
	var dx := p.x - 51.0
	var dy := p.y - 59.0
	var d2 := dx * dx + dy * dy
	if d2 > 16.0 and d2 < 84.0:
		return 4
	if p.x < 31.0 and p.y > 60.5:
		return 3
	if p.x > 63.0 and p.y < 57.5:
		return 3
	if p.x < 34.0 and p.y < 57.0:
		return 2
	if p.x < 22.5 or p.x > 74.0 or p.y < 51.8 or p.y > 68.8:
		return 5
	if p.y > 61.2 and p.y < 65.4 and p.x > 28.0 and p.x < 70.0:
		return 1
	return 0

func _queue_step(chick: bool, at: Vector2) -> void:
	if not amb_on or _night or _grass_gate > 0.0:
		return
	_surf = _surface_at(at)
	var skip: float = [0.55, 0.38, 0.3, 0.26, 0.28, 0.34][_surf]
	if chick:
		skip += 0.08
	if randf() < skip:
		_grass_gate = randf_range(0.1, 0.32)
		return
	_grass_gate = randf_range(0.42, 1.2) if chick else randf_range(0.5, 1.45)
	_grass_t = 0.0
	_grass_kind = randi() % 3
	_grass_pan = randf_range(-0.6, 0.6)
	_grass_hp = 0.0
	_grass_bp = 0.0
	_tap_phase = 0.0
	_grass_click_at = randf_range(0.16, 0.4)
	_grass_click2 = randf_range(0.52, 0.82)
	match _surf:
		1:
			_grass_len = randf_range(0.05, 0.09)
			_grass_amp = randf_range(0.04, 0.068)
			_grass_bright = randf_range(0.08, 0.2)
			_grass_cut = randf_range(0.05, 0.09)
		2:
			_grass_len = randf_range(0.08, 0.15)
			_grass_amp = randf_range(0.038, 0.062)
			_grass_bright = randf_range(0.55, 0.88)
			_grass_cut = randf_range(0.2, 0.34)
		3:
			_grass_len = randf_range(0.06, 0.11)
			_grass_amp = randf_range(0.036, 0.06)
			_grass_bright = randf_range(0.12, 0.28)
			_grass_cut = randf_range(0.06, 0.12)
			_tap_freq = randf_range(148.0, 240.0) if chick else randf_range(110.0, 175.0)
		4:
			_grass_len = randf_range(0.12, 0.22)
			_grass_amp = randf_range(0.04, 0.07)
			_grass_bright = randf_range(0.04, 0.14)
			_grass_cut = randf_range(0.03, 0.06)
		5:
			_grass_len = randf_range(0.04, 0.08)
			_grass_amp = randf_range(0.042, 0.072)
			_grass_bright = randf_range(0.72, 0.98)
			_grass_cut = randf_range(0.3, 0.48)
		_:
			_grass_len = randf_range(0.07, 0.15)
			_grass_amp = randf_range(0.026, 0.05)
			_grass_bright = randf_range(0.22, 0.7)
			_grass_cut = randf_range(0.08, 0.24)
	if chick:
		_grass_len *= randf_range(0.7, 0.88)
		_grass_amp *= randf_range(0.7, 0.88)
		_tap_freq *= 1.22

func _process(delta: float) -> void:
	_amb_gain = move_toward(_amb_gain, 1.0 if amb_on else 0.0, delta * 1.35)
	_grass_gate = maxf(0.0, _grass_gate - delta)
	_fill_amb()
	if not amb_on or _night:
		return
	var n := _hens + _chicks
	if n < 1:
		return
	_call_wait -= delta
	if _call_wait > 0.0:
		return
	var crowd := clampf(sqrt(float(n)), 1.0, 2.8)
	var has_samples := not _chick_streams.is_empty() or not _hen_streams.is_empty()
	_call_wait = (randf_range(2.8, 5.4) if has_samples else randf_range(2.1, 4.4)) / crowd
	if not has_samples and not _buffer_free(0.28):
		_call_wait = randf_range(0.4, 0.9)
		return
	_from_amb = true
	var chick_p := float(_chicks) / float(n)
	if _chicks > 0 and (_hens < 1 or randf() < chick_p):
		if not _play_sample(_chick_streams, -16.5, 0.9, 1.18):
			_peep(0.03)
	else:
		if not _play_sample(_hen_streams, -14.5, 0.88, 1.1):
			_cluck(0.034)
	_from_amb = false

func _fill_amb() -> void:
	if _amb_gain < 0.008:
		return
	unlock()
	var pb := _amb_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var rate := _amb_gen.mix_rate
	var avail := mini(pb.get_frames_available(), 1800)
	var night_mul := 0.55 if _night else 1.0
	var white_amt := (0.011 if _night else 0.016) * _amb_gain
	var wind_amt := (0.11 if _night else 0.155) * _amb_gain * night_mul
	for _i in avail:
		var n_l := randf() * 2.0 - 1.0
		var n_r := randf() * 2.0 - 1.0
		_brown_l = clampf(_brown_l + n_l * 0.018, -0.85, 0.85)
		_brown_r = clampf(_brown_r + n_r * 0.018, -0.85, 0.85)
		_wind_t += TAU * 0.07 / rate
		_wind_t2 += TAU * 0.031 / rate
		var gust := 0.7 + 0.3 * sin(_wind_t) * (0.55 + 0.45 * sin(_wind_t2 + 0.6))
		var cut := 0.016 + 0.028 * (0.5 + 0.5 * sin(_wind_t * 0.85 + 0.2))
		_lp_l += cut * (_brown_l - _lp_l)
		_lp_r += cut * 0.94 * (_brown_r - _lp_r)
		var s_l := _lp_l * wind_amt * gust + n_l * white_amt
		var s_r := _lp_r * wind_amt * gust + n_r * white_amt
		if _grass_t < _grass_len:
			var u := _grass_t / _grass_len
			var env := sin(u * PI)
			if _surf == 1:
				env = 1.0 - u
				env *= env * (1.0 if u < 0.35 else 0.55)
			elif _surf == 2:
				env = sin(u * PI) * (0.55 + 0.45 * sin(u * TAU * 3.0))
			elif _surf == 3:
				env = 1.0 if u < 0.12 else exp(-((u - 0.12) * 7.2))
			elif _surf == 4:
				env = u / 0.18 if u < 0.18 else 1.0 - (u - 0.18) / 0.82
			elif _surf == 5:
				env = 1.0 - u
				env *= env
			env = clampf(env, 0.0, 1.0)
			_grass_hp += _grass_cut * (n_l - _grass_hp)
			var air := n_l - _grass_hp
			_grass_bp += 0.18 * (air - _grass_bp)
			var body := _grass_bp * (1.0 - _grass_bright) + air * _grass_bright
			match _surf:
				1:
					body = _lp_l * 0.78 + n_l * 0.12 + air * 0.08
				2:
					if randf() < 0.38:
						body *= randf_range(0.05, 0.25)
					body = air * 0.72 + _grass_bp * 0.28
				3:
					_tap_phase += TAU * _tap_freq / rate
					body = sin(_tap_phase) * exp(-u * 9.0) * 0.85 + air * 0.14 + _lp_l * 0.18
				4:
					body = _brown_l * 0.52 + _lp_l * 0.4 + air * 0.08
				5:
					var hit := absf(u - _grass_click_at) < 0.035 or absf(u - _grass_click2) < 0.028
					body = n_l * 0.95 if hit else air * 0.18
				_:
					if _grass_kind == 1 and absf(u - _grass_click_at) < 0.04:
						body += n_r * 0.4
			var rustle := body * env * _grass_amp
			var pan_l := 1.0 - maxf(0.0, _grass_pan)
			var pan_r := 1.0 + minf(0.0, _grass_pan)
			s_l += rustle * pan_l
			s_r += rustle * 0.92 * pan_r + (n_r - _lp_r) * env * _grass_amp * 0.1
			_grass_t += 1.0 / rate
		s_l = clampf(s_l, -0.35, 0.35)
		s_r = clampf(s_r, -0.35, 0.35)
		if not pb.can_push_buffer(1):
			break
		pb.push_frame(Vector2(s_l, s_r))

func _load_streams(paths: Array[String]) -> Array[AudioStream]:
	var out: Array[AudioStream] = []
	for path in paths:
		var stream := load(path)
		if stream is AudioStream:
			out.append(stream)
	return out

func _play_sample(streams: Array[AudioStream], vol_db: float, pitch_lo: float, pitch_hi: float) -> bool:
	if streams.is_empty() or _voice_pool.is_empty():
		return false
	if not _voice_ok():
		return true
	var voice := _voice_pool[_voice_i]
	_voice_i = (_voice_i + 1) % _voice_pool.size()
	voice.stream = streams[randi() % streams.size()]
	voice.pitch_scale = randf_range(pitch_lo, pitch_hi)
	voice.volume_db = vol_db
	voice.play()
	return true

func _voice_ok() -> bool:
	return amb_on if _from_amb else sfx_on

func _buffer_free(need: float) -> bool:
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		unlock()
		pb = _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return false
	return pb.get_frames_available() >= int(_gen.mix_rate * need)

func _beep(freq: float, dur := 0.08, vol := 0.08) -> void:
	if not sfx_on:
		return
	_push_chirp(freq, freq, dur, vol, 0.0, 0.0)

func _push_chirp(f0: float, f1: float, dur: float, vol: float, noise := 0.0, harm := 0.0) -> void:
	if not _voice_ok():
		return
	unlock()
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var rate := _gen.mix_rate
	var n := int(rate * dur)
	var phase := 0.0
	var phase2 := 0.0
	for i in n:
		var u := float(i) / float(maxi(1, n - 1))
		var env := 1.0
		if u < 0.1:
			env = u / 0.1
		elif u > 0.58:
			env = 1.0 - (u - 0.58) / 0.42
		env = clampf(env, 0.0, 1.0)
		var f := lerpf(f0, f1, u)
		phase += TAU * f / rate
		var s := sin(phase)
		if harm > 0.01:
			phase2 += TAU * f * 2.12 / rate
			s += sin(phase2) * harm
		if noise > 0.01:
			s += (randf() * 2.0 - 1.0) * noise
		s *= vol * env
		if not pb.can_push_buffer(1):
			break
		pb.push_frame(Vector2(s, s))

func _gap(dur: float) -> void:
	var pb := _player.get_stream_playback() as AudioStreamGeneratorPlayback
	if pb == null:
		return
	var n := int(_gen.mix_rate * dur)
	for _i in n:
		if not pb.can_push_buffer(1):
			break
		pb.push_frame(Vector2.ZERO)

func _peep(vol: float) -> void:
	var count := 2 + randi() % 2
	for i in count:
		var hi := randf_range(1980.0, 2680.0)
		_push_chirp(hi, hi * randf_range(0.70, 0.82), randf_range(0.026, 0.046), vol, 0.05, 0.1)
		if i < count - 1:
			_gap(randf_range(0.032, 0.065))

func _cluck(vol: float) -> void:
	var count := 2 + randi() % 3
	for i in count:
		var last := i == count - 1 and randf() < 0.38
		if last:
			_push_chirp(randf_range(640.0, 780.0), randf_range(230.0, 310.0), randf_range(0.13, 0.2), vol * 1.12, 0.2, 0.48)
		else:
			_push_chirp(randf_range(460.0, 620.0), randf_range(290.0, 380.0), randf_range(0.042, 0.07), vol, 0.15, 0.42)
		if i < count - 1:
			_gap(randf_range(0.038, 0.08))

func egg() -> void:
	var scale := [392.0, 440.0, 494.0, 587.0, 659.0, 784.0]
	_beep(scale[_egg_step % scale.size()], 0.09, 0.06)
	_egg_step += 1

func chick() -> void:
	if not _play_sample(_chick_streams, -7.5, 0.92, 1.14):
		_peep(0.055)

func hen() -> void:
	if not _play_sample(_hen_streams, -5.5, 0.9, 1.08):
		_cluck(0.062)

func hatch() -> void:
	_beep(247.0, 0.16, 0.05)
	_gap(0.04)
	_from_amb = false
	if sfx_on and not _play_sample(_chick_streams, -9.0, 1.02, 1.2):
		_peep(0.045)

func bake_start() -> void:
	_beep(330.0, 0.1, 0.03)

func bake_done() -> void:
	_beep(784.0, 0.14, 0.05)

func coin() -> void:
	_beep(880.0, 0.1, 0.055)

func spend() -> void:
	_beep(392.0, 0.1, 0.04)

func buy_share() -> void:
	_beep(294.0, 0.16, 0.045)

func sell_share() -> void:
	_beep(659.0, 0.14, 0.05)

func deny() -> void:
	_beep(147.0, 0.14, 0.04)

func dusk() -> void:
	_beep(247.0, 0.22, 0.04)

func dawn() -> void:
	_beep(494.0, 0.18, 0.045)

func price(up: bool, big: bool) -> void:
	_beep(784.0 if up else 294.0, 0.18 if big else 0.12, 0.05)

func shatter() -> void:
	_beep(196.0, 0.2, 0.05)

func warn() -> void:
	_beep(988.0, 0.08, 0.045)

func stamp() -> void:
	_beep(196.0, 0.12, 0.05)

func quest() -> void:
	_beep(659.0, 0.16, 0.055)

func egg_ready() -> void:
	_beep(587.0, 0.08, 0.03)

func ending(_tone: String) -> void:
	_beep(392.0, 0.22, 0.05)
