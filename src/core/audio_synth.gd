class_name AudioSynth
extends RefCounted
## Procedural 8-bit-style tone generator. design/gdd/오디오.md calls for
## "미니멀 8비트 SFX" / "차분하고 신비로운 칩튠 BGM" -- square/triangle/sine
## synthesis delivers that without authoring or generating any audio assets.
## Waveform choice is deliberate per-GDD signal: square = combat SFX,
## triangle/sine = calmer BGM and the hidden-discovery stinger.

const _MIX_RATE := 44100
const _FADE_SEC := 0.006 ## per-note fade in/out, avoids waveform-boundary clicks/pops

static func _sample(waveform: String, phase: float) -> float:
	var frac := fposmod(phase, 1.0)
	match waveform:
		"square":
			return 1.0 if frac < 0.5 else -1.0
		"triangle":
			return 4.0 * absf(frac - 0.5) - 1.0
		_: # "sine"
			return sin(frac * TAU)

## notes: Array of [freq_hz, duration_sec]. freq <= 0.0 is a rest (silence).
## Returns per-sample float amplitude in [-1,1] (pre-quantization) so
## mix_tracks() can sum multiple voices before rounding to int16 once --
## summing already-quantized PCM would double-round and add noise.
static func _voice_samples(notes: Array, waveform: String, volume: float) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	for note in notes:
		var freq: float = note[0]
		var dur: float = note[1]
		var frame_count := int(dur * _MIX_RATE)
		var fade_frames := maxi(1, int(_FADE_SEC * _MIX_RATE))
		var phase := 0.0
		var phase_step := freq / _MIX_RATE
		for i in frame_count:
			var amp := volume
			if i < fade_frames:
				amp *= float(i) / fade_frames
			elif i > frame_count - fade_frames:
				amp *= float(frame_count - i) / fade_frames
			samples.append(0.0 if freq <= 0.0 else _sample(waveform, phase) * amp)
			phase += phase_step
	return samples

static func _build_stream(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var pcm := PackedByteArray()
	pcm.resize(samples.size() * 2)
	for i in samples.size():
		var sample_i16 := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		pcm[i * 2] = sample_i16 & 0xFF
		pcm[i * 2 + 1] = (sample_i16 >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _MIX_RATE
	stream.stereo = false
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(pcm.size() / 2)
	return stream

## notes: Array of [freq_hz, duration_sec]. freq <= 0.0 is a rest (silence).
## loop: sets AudioStreamWAV.loop_mode over the full generated buffer.
static func sequence(notes: Array, waveform: String, volume: float, loop: bool = false) -> AudioStreamWAV:
	return _build_stream(_voice_samples(notes, waveform, volume), loop)

## Mixes simultaneous voices (e.g. melody + bass) into one stream -- single
## chiptune channel reads thin/monotone (2026-08-23 user feedback: BGM too
## flat). tracks: Array of {"notes": [[freq,dur],...], "waveform": String,
## "volume": float}. Voices are summed in float space (not per-voice PCM) to
## avoid double-quantization noise, then clamped once. Callers should keep
## each track's total duration equal so the loop point stays musically
## aligned -- audio_manager.gd's BGM tracks are authored that way.
static func mix_tracks(tracks: Array, loop: bool = false) -> AudioStreamWAV:
	var voice_buffers: Array = []
	var max_len := 0
	for track in tracks:
		var buf := _voice_samples(track["notes"], track["waveform"], track["volume"])
		voice_buffers.append(buf)
		max_len = maxi(max_len, buf.size())
	var mixed := PackedFloat32Array()
	mixed.resize(max_len)
	for buf in voice_buffers:
		for i in buf.size():
			mixed[i] += buf[i]
	return _build_stream(mixed, loop)

static func tone(freq: float, duration: float, waveform: String = "square", volume: float = 0.5) -> AudioStreamWAV:
	return sequence([[freq, duration]], waveform, volume)
