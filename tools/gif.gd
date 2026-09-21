extends Node2D
## Tanitim GIF'i icin kare dizisi. Headless DEGIL calistirilir:
##   powershell -ExecutionPolicy Bypass -File tools\gif.ps1
## (kilidi alir, bu sahneyi kosar, kareleri ffmpeg ile yayin/tanitim.gif yapar)
##
## Bolum 1'de kisa bir senaryo: kos -> kanca tak -> pompalayarak salin ->
## esik ustu hizda birak (firlama bonusu: altin parcacik + hiz izi) -> uc.
## Her 3. fizik karesi (20 fps) cizimden sonra yakalanir, bellekte tutulur
## (diske yazmak kare dusururdu), sonunda 640x360'a indirilip (taban
## cozunurluk; 2x render edildigi icin kayipsiz) build/gif/kare_NNN.png yazilir.

const BOLUM := 1
const KARE_ARALIK := 3          ## 60 / 3 = 20 fps
const SURE_KARE := 216          ## 3,6 sn
const CIKTI := "res://build/gif"
const KANCA_YERI := Vector2(480, 128)   ## bolum 1'in ilk noktasi
const HALAT_HEDEF := 140.0      ## yay dibi (128+140+14) zeminin (304) ustunde kalsin
const BIRAKMA_HIZI := 430.0     ## esik (380) ustu: bonus + 704'teki platforma rahat ulasir
const ASGARI_SALINIM := 2       ## birakmadan once en az bir tam gidis-donus (yon degisimi)

var _oyuncu: Oyuncu
var _asama := 0                 ## 0 kos, 1 salin, 2 uc
var _kare := 0
var _yakala := false
var _kareler: Array[Image] = []
var _salinim := 0               ## tegetsel yon degisimi sayisi
var _onceki_yon := 0.0

func _ready() -> void:
	# Senaryo oyuncunun kaydina dokunmasin: ilk surum 1. bolumu 1,87 sn'de
	# bitirip rekoru ve hayaleti ezdi.
	Kayit.salt_okunur = true
	Engine.max_fps = 60
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CIKTI))
	var bolum: Bolum = load(Bolumler.yol(BOLUM)).instantiate()
	add_child(bolum)
	for i in 6:
		await get_tree().physics_frame
	_oyuncu = bolum.find_child("Oyuncu", true, false)
	_oyuncu.girdi_aktif = false
	_oyuncu.global_position = Vector2(64, 290)      # bolum basi: kosu da gorunsun
	_oyuncu.velocity = Vector2(Ayarlar.HIZ, 0.0)
	# Bitis alani kapali: senaryo bolumu bitirmesin (panel cikmasin).
	# _alanlari_ac bir fizik karesi sonra tum alanlari acar; 6 kare bekledik.
	var bitis: Area2D = bolum.find_child("Bitis", true, false)
	if bitis != null:
		bitis.monitoring = false
	while _kare < SURE_KARE:
		await RenderingServer.frame_post_draw
		if _yakala:
			_yakala = false
			_kareler.append(get_viewport().get_texture().get_image())
	for i in _kareler.size():
		var im := _kareler[i]
		im.resize(640, 360, Image.INTERPOLATE_NEAREST)
		im.save_png("%s/kare_%03d.png" % [CIKTI, i])
	print("gif kareleri hazir: %d adet, asama %d, %s" % [_kareler.size(), _asama, CIKTI])
	get_tree().quit(0 if _asama == 2 else 1)

func _physics_process(dt: float) -> void:
	if _oyuncu == null:
		return
	_kare += 1
	if _kare % KARE_ARALIK == 0:
		_yakala = true
	# Bolum._dogur() girdi_aktif'i geri acabilir; senaryo klavye okumasin.
	_oyuncu.girdi_aktif = false
	var pos := _oyuncu.global_position
	match _asama:
		0:
			_oyuncu.bot_yon = 1.0
			if pos.distance_to(KANCA_YERI) <= Ayarlar.KANCA_MENZIL - 6.0 \
					and _oyuncu.kanca_at((KANCA_YERI - pos).normalized()):
				_asama = 1
		1:
			if not _oyuncu.kancali():
				return                              # halat hala ucuyor
			var capa: Vector2 = _oyuncu.kanca_nokta.global_position
			var disa := (pos - capa).normalized()
			var teget := Vector2(-disa.y, disa.x)
			if teget.x < 0.0:
				teget = -teget
			var hiz := _oyuncu.velocity
			var yon_t := signf(hiz.dot(teget))
			if yon_t != 0.0 and yon_t != _onceki_yon:
				if _onceki_yon != 0.0:
					_salinim += 1
				_onceki_yon = yon_t
			_oyuncu.bot_yon = yon_t                   # salinim yonune bas (pompa)
			if _oyuncu.halat_boyu > HALAT_HEDEF:
				_oyuncu.halat_degistir(-minf(300.0 * dt, _oyuncu.halat_boyu - HALAT_HEDEF))
			# Yeterince hizli, saga ve yukari, capayi gecmis: birak -> firlama bonusu.
			if _salinim >= ASGARI_SALINIM and hiz.length() >= BIRAKMA_HIZI \
					and hiz.x > 0.0 and hiz.y < 0.0 and pos.x > capa.x + 10.0:
				_oyuncu.kanca_birak()
				_asama = 2
		2:
			_oyuncu.bot_yon = 1.0
