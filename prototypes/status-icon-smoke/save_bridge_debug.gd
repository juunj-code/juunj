extends Control
## Throwaway debug scene -- directly exercises SaveManager.save() (the same
## call ProgressManager.commit_run_end() makes) without grinding through a
## full dungeon run, to see the real FS.syncfs() round trip in an actual web
## export. See prototypes/status-icon-smoke/README.md.

func _ready() -> void:
	SaveManager.save_succeeded.connect(func():
		print("SAVE_BRIDGE_DEBUG: save_succeeded fired"))
	SaveManager.save_failed.connect(func(reason):
		print("SAVE_BRIDGE_DEBUG: save_failed fired reason=%s" % reason))

	print("SAVE_BRIDGE_DEBUG: calling save() -- OS.has_feature(web)=%s" % OS.has_feature("web"))
	SaveManager.save_section("smoke_test", {"ts": Time.get_ticks_msec()})
	var ok := SaveManager.save()
	print("SAVE_BRIDGE_DEBUG: save() returned %s (stage 1 only, see save_manager.gd)" % ok)
