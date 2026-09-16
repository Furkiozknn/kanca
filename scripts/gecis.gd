extends CanvasLayer
## Sahne gecisi: kararma -> sahne degistir -> acilma. Otomatik yuklenen tekil.
## Duraklatma sirasinda da calisir (PROCESS_MODE_ALWAYS).

const SURE := 0.22

var _perde: ColorRect
var _mesgul := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_perde = ColorRect.new()
	_perde.color = Color(Palet.GOK_DIP, 1.0)
	_perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_perde.visible = false
	add_child(_perde)
	ac()

## Ekrani karart, sahneyi degistir, tekrar ac.
func git(yol: String) -> void:
	if _mesgul:
		return
	_mesgul = true
	await _karart()
	get_tree().change_scene_to_file(yol)
	await get_tree().process_frame
	_mesgul = false
	ac()

## Sahne degistirmeden karart-ac (olum, bolum basa alma).
func yanip_son() -> void:
	if _mesgul:
		return
	_mesgul = true
	await _karart()
	_mesgul = false
	ac()

func _karart() -> void:
	_perde.visible = true
	_perde.modulate.a = 0.0
	var t := create_tween()
	t.tween_property(_perde, "modulate:a", 1.0, SURE)
	await t.finished

func ac() -> void:
	_perde.visible = true
	_perde.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_perde, "modulate:a", 0.0, SURE)
	t.tween_callback(func() -> void: _perde.visible = false)
