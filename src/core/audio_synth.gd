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
## loop: sets AudioStreamWAV.loop_mode over the full generated buffer.
static func sequence(notes: Array, waveform: String, volume: float, loop: bool = false) -> AudioStreamWAV:
	var pcm := PackedByteArray()
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
			var s := 0.0 if freq <= 0.0 else _sample(waveform, phase)
			var sample_i16 := int(clampf(s * amp, -1.0, 1.0) * 32767.0)
			pcm.append(sample_i16 & 0xFF)
			pcm.append((sample_i16 >> 8) & 0xFF)
			phase += phase_step
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = _MIX_RATE
	stream.stereo = false
	stream.data = pcm
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(pcm.size() / 2)
	return stream

static func tone(freq: float, duration: float, waveform: String = "square", volume: float = 0.5) -> AudioStreamWAV:
	return sequence([[freq, duration]], waveform, volume)
