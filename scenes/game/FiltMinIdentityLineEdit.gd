extends LineEdit

signal min_match_pc_id_changed

var min_id = Globals.match_min_show_pc_id

func _ready():
	text = str(min_id)

func _on_text_submitted(new_text):
	if new_text.is_valid_float():
		min_id = float(new_text)
		if min_id < 0:
			min_id = 0
		elif min_id > 100:
			min_id = 100
		min_match_pc_id_changed.emit(min_id)
	text = str(min_id)
	release_focus()


func _on_focus_exited():
	_on_text_submitted(text)
