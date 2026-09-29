class_name Tema
extends RefCounted
## Tanitim videosundaki dunya: DUZ renk, golgesiz, disi cizgisiz. Renk kodlari
## kancanin kendi videosundan (docs/TASARIM.md) piksel ornekleyerek alindi.
## Iki tema: gece (lacivert zemin, kagit blok) ve kagit (kagit zemin, lacivert
## blok). Bolum 1-7 gece, 8-14 kagit. Oyuncu her temada turkuaz, tehlike her
## temada kirmizi-turuncu; turuncu "hareket" rengi (iz, en iyi sure, secili nokta).

const MUREKKEP := Color("0d1218")    ## video penceresi / gece zemini / kagit blok
const KAGIT := Color("edf2f1")       ## video kagit yuzeyi / gece blok / metin
const TURUNCU := Color("ff9e1b")     ## vurgu: iz, secili kanca, en iyi sure
const TURKUAZ := Color("2ec3b6")     ## oyuncu (videodaki top)
const DIKEN := Color("e94f36")       ## tehlike
const AMBER := Color("f0b459")       ## birincil dugme (videodaki CTA)
const SARI := Color("ffc21a")        ## yalniz odul: madalya, yeni rekor damgasi
const GUMUS := Color("c9ccd6")
const BRONZ := Color("c9865a")
const PANEL := Color("161b24")       ## kart / perde yuzeyi
const KESIK := Color("8a8595")       ## kesik cizgi (menu tavan rayi)

## Tema dizini: 0 gece, 1 kagit.
const TEMALAR: Array = [
	{"ad": "gece", "zemin": Color("0d1218"), "blok": Color("edf2f1")},
	{"ad": "kagit", "zemin": Color("edf2f1"), "blok": Color("0d1218")},
]
const KONTRAST := {"ad": "kontrast", "zemin": Color("000000"), "blok": Color("ffffff")}

const F_GOVDE := "res://assets/fonts/InstrumentSans-Regular.ttf"
const F_KALIN := "res://assets/fonts/InstrumentSans-Bold.ttf"
const F_MONO := "res://assets/fonts/JetBrainsMono-Regular.ttf"
const F_MONO_KALIN := "res://assets/fonts/JetBrainsMono-Bold.ttf"
const F_SIMGE := "res://assets/fonts/simgeler.ttf"
const TEMA_YOLU := "res://assets/tema.tres"

## Sahnede gecerli tema. Bolum kurulurken ve menu acilirken ayarlanir.
static var aktif := 0


## Bolum numarasindan tema: 1-7 gece, 8-14 kagit.
static func bolum_temasi(no: int) -> int:
	return 0 if no <= 7 else 1


static func zemin() -> Color:
	return (TEMALAR[clampi(aktif, 0, TEMALAR.size() - 1)]["zemin"] as Color)


static func blok() -> Color:
	return (TEMALAR[clampi(aktif, 0, TEMALAR.size() - 1)]["blok"] as Color)


## Mono etiketlerin rengi: bloktan %70 opaklik.
static func etiket_rengi(blok_rengi: Color) -> Color:
	return Color(blok_rengi, 0.7)


## Turkce duyarli buyuk harf: i -> I degil İ. Ingilizcede duz to_upper.
static func buyuk(s: String) -> String:
	if TranslationServer.get_locale().begins_with("tr"):
		return s.replace("i", "İ").replace("ı", "I").to_upper()
	return s.to_upper()


## "01 / İLK TUTUŞ" (bolum no + cevrilmis ad).
static func kisa_baslik(no: int, ad: String) -> String:
	return "%02d / %s" % [no, buyuk(ad)]


## Duz dolgulu kutu; HUD rozeti ve kartlar buradan.
static func kutu(dolgu: Color, yaricap: int = 3, yatay: int = 0, dikey: int = 0,
		cerceve: Color = Color(0, 0, 0, 0), kalinlik: int = 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = dolgu
	s.border_color = cerceve
	s.set_border_width_all(kalinlik)
	s.set_corner_radius_all(yaricap)
	s.content_margin_left = yatay
	s.content_margin_right = yatay
	s.content_margin_top = dikey
	s.content_margin_bottom = dikey
	s.anti_aliasing = true
	return s


## Mono etiket: kaynak yazi tipi temada; burada yalniz boyut/renk.
static func etiket(metin: String, boyut: int, renk: Color, mono := true, kalin := false) -> Label:
	var e := Label.new()
	e.text = metin
	if mono:
		e.theme_type_variation = &"EtiketKalin" if kalin else &"Etiket"
	else:
		e.theme_type_variation = &"Baslik" if kalin else &"Govde"
	e.add_theme_font_size_override("font_size", boyut)
	e.add_theme_color_override("font_color", renk)
	e.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return e
