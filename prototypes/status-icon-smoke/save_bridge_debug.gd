extends Control
## Throwaway debug scene, round 3 -- console message capture proved
## unreliable (round 2 lost most log lines), so this writes results directly
## into a Label on screen instead. Same hypotheses as round 2: does a bare
## SceneTreeTimer fire, does FS.syncfs's own JS callback fire at all.

var _label: Label
var _frame_count := 0
var _last_reported := 0

func _process(_delta: float) -> void:
	_frame_count += 1
	if _frame_count - _last_reported >= 60:
		_last_reported = _frame_count
		_append("frame_count=%d ticks=%d" % [_frame_count, Time.get_ticks_msec()])

func _ready() -> void:
	_label = Label.new()
	_label.text = "booting..."
	_label.add_theme_font_size_override("font_size", 20)
	add_child(_label)

	var t := get_tree().create_timer(3.0)
	t.timeout.connect(func():
		_append("TIMER: 3s SceneTreeTimer fired at ticks=%d" % Time.get_ticks_msec()))
	_append("boot: ticks=%d web=%s" % [Time.get_ticks_msec(), OS.has_feature("web")])

	if not OS.has_feature("web"):
		return

	JavaScriptBridge.eval("""
		window.SaveDebugBridge = {};
		window.SaveDebugBridge.setStatus = function(s) {
			var el = document.getElementById('save-debug-status');
			if (!el) {
				el = document.createElement('div');
				el.id = 'save-debug-status';
				el.style = 'position:fixed;top:0;left:0;background:white;color:black;font-size:14px;z-index:9999;white-space:pre;';
				document.body.appendChild(el);
			}
			el.innerText += s + '\\n';
		};
		window.SaveDebugBridge.setStatus('JS: FS=' + (typeof FS) + ' Module=' + (typeof Module) + ' Module.FS=' + (typeof (window.Module && window.Module.FS)) + ' GodotConfig=' + (typeof GodotConfig) + ' Godot=' + (typeof Godot) + ' engine=' + (typeof engine));
		window.SaveDebugBridge.setStatus('JS: window keys with FS/fs: ' + Object.keys(window).filter(function(k){return /fs/i.test(k);}).join(','));
		var fsObj = null;
		if (typeof FS !== 'undefined') fsObj = FS;
		else if (window.Module && window.Module.FS) fsObj = window.Module.FS;
		if (fsObj) {
			try {
				window.SaveDebugBridge.setStatus('JS: calling fsObj.syncfs');
				fsObj.syncfs(false, function(err) {
					window.SaveDebugBridge.setStatus('JS: syncfs callback fired err=' + err);
				});
				window.SaveDebugBridge.setStatus('JS: syncfs call issued');
			} catch (e) {
				window.SaveDebugBridge.setStatus('JS: syncfs threw: ' + e);
			}
		} else {
			window.SaveDebugBridge.setStatus('JS: no FS object found anywhere');
		}
	""", true)
	_append("eval issued")

func _append(s: String) -> void:
	_label.text += "\n" + s
