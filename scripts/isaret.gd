class_name Isaret
extends Node2D
## Kontrol noktasi ve bitis bayragi: duz renk, kodla cizilir (PNG yok).
## KONTROL: ince direk + flama; pasifken bloktan soluk, aktifken turkuaz.
## BITIS: uzaktan okunan yuksek direk + turuncu bayrak.

enum { KONTROL, BITIS }

var tur := KONTROL
## Kontrol noktasi: 0 pasif, 1 aktif.
var frame := 0:
	set(v):
		frame = v
		queue_redraw()


static func yap(t: int) -> Isaret:
	var i := Isaret.new()
	i.tur = t
	return i


func _draw() -> void:
	var b := Tema.blok()
	if tur == KONTROL:
		var renk := Tema.TURKUAZ if frame == 1 else Color(b, 0.45)
		draw_rect(Rect2(-1.0, 6.0, 2.0, 26.0), renk)
		draw_colored_polygon(PackedVector2Array([
			Vector2(1.0, 6.0), Vector2(13.0, 11.0), Vector2(1.0, 16.0)]), renk)
	else:
		draw_rect(Rect2(-1.5, -24.0, 3.0, 56.0), b)
		draw_rect(Rect2(1.5, -24.0, 15.0, 10.0), Tema.TURUNCU)
