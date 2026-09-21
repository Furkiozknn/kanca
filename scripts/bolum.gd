extends Node2D
class_name Bolum
## Tek bir bolumun tamami: geometriyi Bolumler.VERI tablosundan kurar, sureyi
## tutar, olum/kontrol noktasi/bitis akisini, madalyayi, hayaleti ve arayuzu yonetir.
##
## Sahne dosyalari (scenes/bolumler/bolum_NN.tscn) sadece bolum_no tasir;
## boylece 14 bolum tek kod yolundan uretilir ve veri tek yerde durur.

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")
const MENU_YOLU := "res://scenes/menu.tscn"
const DOKU_DIKEN := preload("res://assets/sprites/diken.png")
const DOKU_BAYRAK := preload("res://assets/sprites/bayrak.png")
const DOKU_KONTROL := preload("res://assets/sprites/kontrol.png")
const DOKU_PARCACIK := preload("res://assets/sprites/parcacik.png")
const DOKU_RUZGAR := preload("res://assets/sprites/ruzgar.png")
const DOKU_MADALYA := preload("res://assets/sprites/madalya.png")
const DOKU_GOK := preload("res://assets/sprites/arka_gok.png")
const DOKU_BULUT := preload("res://assets/sprites/arka_bulut.png")
const DOKU_UZAK := preload("res://assets/sprites/arka_uzak.png")
const DOKU_YAKIN := preload("res://assets/sprites/arka_yakin.png")

@export var bolum_no: int = 1

var _veri: Dictionary = {}
var _oyuncu: Oyuncu = null
var _dunya: Node2D = null
var _hayalet: Hayalet = null
var _kamera: Camera2D = null

var _sure: float = 0.0
var _sayiyor: bool = false
var _duraklatildi: bool = false
var _bitti: bool = false
var _oluyor: bool = false   ## olum islendi, yeniden dogus kare sonunda
var _dogus := Vector2.ZERO
var _sarsinti := 0.0
var _sarsinti_t := 0.0
var _kayit_sayaci := 0.0
var _kayit := PackedVector2Array()
var _parcacik_havuzu: Array[CPUParticles2D] = []
var _parcacik_sira := 0
var _zincir := 0            ## yere degmeden art arda kac kanca (ustalik zinciri)
var _en_uzun_zincir := 0

## Dokunmatikte olumden sonra beliren tek dokunusluk "Bastan basla" dugmesi.
## Kisa bir bekleme var: olum aninda ekranda olan parmak yanlislikla basmasin.
const YENIDEN_BEKLEME := 0.7         ## olumden sonra dugme bu sure boyunca kapali
const YENIDEN_GORUNME := 4.0         ## dugme bu kadar gorunur kalir

var _gunluk := false                 ## bu kosu gunluk meydan okuma mi
var _yeniden_dugme: Button = null
var _yeniden_sayac := 0.0            ## >0 iken dugme gorunur; ilk YENIDEN_BEKLEME'de kapali

var _sure_etiket: Label
var _akis_etiket: Label
var _eniyi_etiket: Label
var _madalya_gorsel: TextureRect
var _duraklat_panel: Control
var _ayar_panel: Control
var _bitis_panel: Control
var _bitis_metin: Label
var _sonraki_dugme: Button

func _ready() -> void:
	add_to_group(&"bolum")
	_gunluk = Gunluk.aktif
	_veri = Bolumler.veri(bolum_no)
	RenderingServer.set_default_clear_color(Ayarlar.RENK_ARKAPLAN)
	_arka_plani_kur()
	_oyuncuyu_kur()
	_arayuzu_kur()
	if _gunluk:
		Gunluk.uygula(_oyuncu)
	else:
		_hayaleti_kur()
	Ses.muzik_cal("muzik")
	_yeniden()

## Oyuncu dogru yere yerlestikten sonra tehlike/bitis alanlarini acar.
## (Yeni kurulan Area2D ayni karede bayat bir ortusmeyi body_entered sayabiliyor.)
func _alanlari_ac() -> void:
	await get_tree().physics_frame
	if not is_inside_tree():
		return
	for a in find_children("", "Area2D", true, false):
		a.monitoring = true

# --- Arka plan --------------------------------------------------------

func _arka_plani_kur() -> void:
	# Gokyuzu: kameradan bagimsiz, ekrani kaplayan degrade.
	var katman := CanvasLayer.new()
	katman.layer = -10
	add_child(katman)
	var gok := TextureRect.new()
	gok.texture = DOKU_GOK
	gok.stretch_mode = TextureRect.STRETCH_SCALE
	gok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	katman.add_child(gok)

	# Parallaks: uzaktan yakina ucan kaya adalari + bulut bandi.
	# modulate ile bilerek soluklastirildi - arka plan adalari oynanis zemini
	# gibi okunmamali (bkz. sprite_uret.gd icindeki kenar rengi notu).
	_parallaks(DOKU_UZAK, Vector2(0.20, 0.08), 320, Vector2(0, 8), -9, Vector2.ZERO, 0.55)
	_parallaks(DOKU_BULUT, Vector2(0.35, 0.14), 256, Vector2(0, -50), -8, Vector2(-7.0, 0.0), 0.8)
	_parallaks(DOKU_YAKIN, Vector2(0.55, 0.22), 320, Vector2(0, 76), -7, Vector2.ZERO, 0.7)
	_firtina_cizgileri()

## Tema "firtinali gokyuzu adalari": ekranda surekli suzulen ruzgar cizgileri.
## Ekran uzayinda (CanvasLayer) duruyor - kamerayla kaymiyor, atmosfer katmani.
func _firtina_cizgileri() -> void:
	var katman := CanvasLayer.new()
	katman.layer = -1
	add_child(katman)
	var pc := CPUParticles2D.new()
	pc.texture = DOKU_RUZGAR
	pc.position = Vector2(320, 150)
	pc.amount = 16
	pc.lifetime = 2.6
	pc.preprocess = 2.6
	pc.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pc.emission_rect_extents = Vector2(420, 210)
	pc.direction = Vector2(-1, 0.12)
	pc.spread = 4.0
	pc.initial_velocity_min = 70.0
	pc.initial_velocity_max = 190.0
	pc.scale_amount_min = 0.5
	pc.scale_amount_max = 1.8
	pc.color = Color(Palet.BULUT_ACIK, 0.22)
	katman.add_child(pc)

func _parallaks(doku: Texture2D, olcek: Vector2, genislik: int, kaydir: Vector2,
		z: int, akis: Vector2, saydam: float) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = olcek
	p.repeat_size = Vector2(genislik, 0)
	p.repeat_times = 24
	p.autoscroll = akis
	p.z_index = z
	add_child(p)
	var s := Sprite2D.new()
	s.texture = doku
	s.centered = false
	s.position = kaydir
	s.modulate = Color(1, 1, 1, saydam)
	p.add_child(s)

# --- Dunya ------------------------------------------------------------

func _oyuncuyu_kur() -> void:
	_oyuncu = OYUNCU_SAHNE.instantiate()
	add_child(_oyuncu)
	_kamera = _oyuncu.get_node("Kamera")
	_oyuncu.kanca_takildi.connect(_kanca_takildi)
	_oyuncu.kanca_koptu.connect(_kanca_koptu)
	_oyuncu.yere_indi.connect(_yere_indi)
	for i in 6:
		var pc := _parcacik_yap()
		add_child(pc)
		_parcacik_havuzu.append(pc)

## Dunyayi sifirdan kurar. Olumde de cagrilir: kirilan noktalar geri gelir.
func _dunyayi_kur() -> void:
	if _dunya != null:
		# queue_free tek basina yetmez: dugum bir kare daha agacta kalir ve
		# get_nodes_in_group eski kanca noktalarini da dondurur.
		remove_child(_dunya)
		_dunya.queue_free()
	_dunya = Node2D.new()
	_dunya.name = "Dunya"
	add_child(_dunya)
	move_child(_dunya, 0)

	_zemini_dose()
	for r: Rect2 in _veri["diken"]:
		_dunya.add_child(_diken(Bolumler.karola(r), false))
	for r: Rect2 in _veri["tavan_diken"]:
		_dunya.add_child(_diken(Bolumler.karola(r), true))
	for a: Dictionary in _veri["ruzgar"]:
		_dunya.add_child(_ruzgar_alani(a["alan"], a["yon"]))
	for p: Vector2 in _veri["kanca"]:
		_dunya.add_child(KancaNoktasi.yap(p, KancaNoktasi.TUR_SABIT))
	for i in (_veri["kanca_h"] as Array).size():
		var h: Dictionary = _veri["kanca_h"][i]
		var n := KancaNoktasi.yap(h["a"], KancaNoktasi.TUR_HAREKETLI)
		n.a = h["a"]
		n.b = h["b"]
		n.faz = float(i) * 0.37
		_dunya.add_child(n)
	for p: Vector2 in _veri["kanca_k"]:
		_dunya.add_child(KancaNoktasi.yap(p, KancaNoktasi.TUR_KIRILGAN))
	for i in (_veri["kontrol"] as Array).size():
		var kn := _kontrol_noktasi(_veri["kontrol"][i], i)
		# Olumden sonra dunya yeniden kuruluyor; zaten aktiflesmis kontrol
		# noktasi pasif gorunmesin.
		if _dogus.distance_to(Vector2(_veri["kontrol"][i])) < 1.0:
			(kn.get_node("Gorsel") as Sprite2D).frame = 1
		_dunya.add_child(kn)
	_dunya.add_child(_bitis_bayragi(_veri["bitis"]))
	_rota_ipucunu_isaretle()
	_kamera_sinirla()

## Altin madalya kazanildiysa (ve ayar acikken) rotanin kullandigi kanca
## noktalari isaretlenir - "nereden gidilirmis" sorusunun cevabi.
func _rota_ipucunu_isaretle() -> void:
	if not bool(Kayit.ayar("rota_ipucu")):
		return
	if not altin_kazanildi(bolum_no):
		return
	var rota := RotaVerisi.nokta(bolum_no)
	if rota.is_empty():
		return
	for n in _dunya.get_children():
		if not (n is KancaNoktasi):
			continue
		var nokta: KancaNoktasi = n
		# Hareketli nokta rotada orta konumuyla duruyor (Bolumler.tum_kanca).
		var yer: Vector2 = nokta.position
		if nokta.tur == KancaNoktasi.TUR_HAREKETLI:
			yer = (nokta.a + nokta.b) * 0.5
		for p: Vector2 in rota:
			if yer.distance_to(p) < 24.0:
				nokta.rotada(true)
				break

## Zemin dikdortgenleri TileMapLayer'a dosenir (gorsel + carpisma tek yerden).
func _zemini_dose() -> void:
	var kat := TileMapLayer.new()
	kat.name = "Zemin"
	kat.tile_set = KaroSeti.al()
	kat.z_index = 1
	for r: Rect2 in Bolumler.zeminler(bolum_no):
		var tx0 := int(r.position.x) / KaroSeti.BOY
		var ty0 := int(r.position.y) / KaroSeti.BOY
		var tx1 := int(r.end.x) / KaroSeti.BOY - 1
		var ty1 := int(r.end.y) / KaroSeti.BOY - 1
		for ty in range(ty0, ty1 + 1):
			for tx in range(tx0, tx1 + 1):
				kat.set_cell(Vector2i(tx, ty), 0, KaroSeti.koord(tx, ty, tx0, ty0, tx1, ty1))
	_dunya.add_child(kat)

func _diken(r: Rect2, tavan: bool) -> Area2D:
	var alan := Area2D.new()
	alan.position = r.position
	alan.monitorable = false
	alan.monitoring = false   # bayat ortusme tuzagi: ilk fizik karesinden sonra acilir
	var sekil := RectangleShape2D.new()
	sekil.size = r.size
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	carpisma.position = r.size * 0.5
	alan.add_child(carpisma)
	# Diken dokusu 16x16 ve carpisma dikdortgeni de 16 yuksekliginde:
	# gorunen sey ile olduren sey birebir ayni olsun.
	var adet := maxi(1, int(r.size.x / 16.0))
	for i in adet:
		var s := Sprite2D.new()
		s.texture = DOKU_DIKEN
		s.centered = false
		s.flip_v = tavan
		s.position = Vector2(i * 16.0, maxf(r.size.y - 16.0, 0.0) if not tavan else 0.0)
		alan.add_child(s)
	alan.z_index = 2
	alan.body_entered.connect(_tehlikeye_degdi)
	return alan

func _ruzgar_alani(r: Rect2, yon: Vector2) -> Area2D:
	var alan := Area2D.new()
	alan.position = r.position + r.size * 0.5
	alan.monitorable = false
	alan.monitoring = false
	var sekil := RectangleShape2D.new()
	sekil.size = r.size
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.add_child(carpisma)

	var perde := ColorRect.new()
	perde.color = Color(Palet.RUZGAR, 0.08)
	perde.size = r.size
	perde.position = -r.size * 0.5
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alan.add_child(perde)

	var pc := CPUParticles2D.new()
	pc.texture = DOKU_RUZGAR
	pc.amount = clampi(int(r.size.x * r.size.y / 900.0), 8, 40)
	pc.lifetime = 1.1
	pc.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	pc.emission_rect_extents = r.size * 0.5
	pc.direction = yon.normalized()
	pc.spread = 8.0
	pc.initial_velocity_min = 150.0
	pc.initial_velocity_max = 260.0
	pc.scale_amount_min = 0.7
	pc.scale_amount_max = 1.6
	pc.color = Color(Palet.RUZGAR, 0.55)
	alan.add_child(pc)

	var birim := yon.normalized()
	alan.body_entered.connect(func(g: Node2D) -> void:
		if g == _oyuncu:
			_oyuncu.ruzgar += birim)
	alan.body_exited.connect(func(g: Node2D) -> void:
		if g == _oyuncu:
			_oyuncu.ruzgar -= birim)
	alan.z_index = 3   # karolarin (1) onunde, oyuncunun (4) arkasinda
	return alan

func _kontrol_noktasi(yer: Vector2, sira: int) -> Area2D:
	var alan := Area2D.new()
	alan.position = yer
	alan.monitorable = false
	alan.monitoring = false
	var sekil := RectangleShape2D.new()
	sekil.size = Vector2(24, 40)
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.add_child(carpisma)
	var s := Sprite2D.new()
	s.texture = DOKU_KONTROL
	s.hframes = 2
	s.name = "Gorsel"
	# Kontrol noktalari platform ustunden 32 px yukarida taniml; sprite 24 px
	# yuksek, tabani zemine otursun diye 8 px asagi kayiyor.
	s.centered = false
	s.position = Vector2(-8, 8)
	alan.add_child(s)
	alan.name = "Kontrol%d" % sira
	alan.z_index = 2
	alan.body_entered.connect(_kontrole_degdi.bind(alan))
	return alan

func _bitis_bayragi(yer: Vector2) -> Area2D:
	var alan := Area2D.new()
	alan.position = yer
	alan.monitorable = false
	alan.monitoring = false   # bayat ortusme tuzagi: ilk fizik karesinden sonra acilir
	var sekil := RectangleShape2D.new()
	sekil.size = Vector2(24, 56)
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.add_child(carpisma)
	var s := Sprite2D.new()
	s.texture = DOKU_BAYRAK
	s.centered = false          # direk tabani zemine otursun
	s.position = Vector2(-8, 0)
	alan.add_child(s)
	alan.name = "Bitis"
	alan.z_index = 2
	alan.body_entered.connect(_bitise_degdi)
	return alan

func _kamera_sinirla() -> void:
	var sinir := Rect2(_veri["basla"], Vector2.ZERO)
	for r: Rect2 in Bolumler.zeminler(bolum_no):
		sinir = sinir.merge(r)
	sinir = sinir.expand(_veri["bitis"] + Vector2(80, 0))
	_kamera.limit_left = int(sinir.position.x) - 40
	_kamera.limit_right = int(sinir.end.x) + 40
	_kamera.limit_top = int(sinir.position.y) - 140
	_kamera.limit_bottom = int(sinir.end.y) + 60

# --- Parcacik ve sarsinti ---------------------------------------------

func _parcacik_yap() -> CPUParticles2D:
	var pc := CPUParticles2D.new()
	pc.texture = DOKU_PARCACIK
	pc.emitting = false
	pc.one_shot = true
	pc.explosiveness = 0.9
	pc.lifetime = 0.5
	pc.spread = 180.0
	pc.gravity = Vector2(0, 420)
	pc.initial_velocity_min = 60.0
	pc.initial_velocity_max = 190.0
	pc.scale_amount_min = 0.6
	pc.scale_amount_max = 1.4
	pc.z_index = 7
	return pc

## Kisa bir parcacik patlamasi. KancaNoktasi da kirilirken bunu cagirir.
func parcacik_at(yer: Vector2, renk: Color, adet: int = 10) -> void:
	var pc := _parcacik_havuzu[_parcacik_sira]
	_parcacik_sira = (_parcacik_sira + 1) % _parcacik_havuzu.size()
	pc.global_position = yer
	pc.amount = maxi(adet, 1)
	pc.color = renk
	pc.restart()
	pc.emitting = true

func sars(guc: float) -> void:
	if bool(Kayit.ayar("sarsinti")):
		_sarsinti = maxf(_sarsinti, guc)

# --- Oyuncu olaylari --------------------------------------------------

func _kanca_takildi(yer: Vector2) -> void:
	sars(1.6)
	parcacik_at(yer, Palet.NOKTA_BAGLI, 6)
	# Ustalik zinciri: yere degmeden art arda tutulan her nokta zinciri uzatir.
	_zincir += 1
	_en_uzun_zincir = maxi(_en_uzun_zincir, _zincir)
	if _zincir >= 2:
		Ses.cal("akis")
	_akis_yaz()

## bonus = esik ustu hizda birakildi (BIRAKMA_CARPANI uygulandi).
func _kanca_koptu(hiz: Vector2, bonus: bool) -> void:
	if bonus:
		parcacik_at(_oyuncu.global_position, Palet.ALTIN, 14)
		sars(1.2)
	elif hiz.length() > 320.0:
		parcacik_at(_oyuncu.global_position, Palet.HALAT, 8)

func _yere_indi(dusus_hizi: float) -> void:
	_zincir = 0
	_akis_yaz()
	if dusus_hizi > 260.0:
		parcacik_at(_oyuncu.global_position + Vector2(0, 12), Palet.KAYA_KENAR,
			clampi(int(dusus_hizi / 60.0), 4, 14))
		sars(minf(dusus_hizi / 260.0, 3.5))

# --- Akis -------------------------------------------------------------

## Bolumu bastan baslatir: sure sifir, kontrol noktalari silinir, dunya yenilenir.
func _yeniden() -> void:
	_sure = 0.0
	_dogus = _veri["basla"]
	_kayit = PackedVector2Array()
	_kayit_sayaci = 0.0
	_oluyor = false
	_zincir = 0
	_en_uzun_zincir = 0
	_yeniden_dugmesini_gizle()
	_dunyayi_kur()
	_dogur()
	if _hayalet != null:
		_hayalet.basla()

## Olum: kontrol noktasindan devam, sure isliyor (hiz oyunu - olum zaman kaybi).
func _oldu() -> void:
	# Dusus olumunde _process her karede tetikler, dikende sinyal birden cok
	# kez gelebilir: yeniden dogus kare sonuna ertelendigi icin kilit sart.
	if _bitti or _oluyor:
		return
	_oluyor = true
	_zincir = 0
	Ses.cal("olum")
	parcacik_at(_oyuncu.global_position, Palet.ATKI, 18)
	sars(5.0)
	_sayiyor = true
	_yeniden_sayac = YENIDEN_GORUNME
	_yeniden_dogur.call_deferred()
	Gecis.yanip_son()

## Olum sinyali Area2D'nin icinden geliyor; dunyayi kare sonunda yeniliyoruz.
func _yeniden_dogur() -> void:
	_dunyayi_kur()
	_dogur()
	_oluyor = false

func _dogur() -> void:
	_oyuncu.kanca_birak()
	_oyuncu.ruzgar = Vector2.ZERO
	_oyuncu.global_position = _dogus
	_oyuncu.velocity = Vector2.ZERO
	_oyuncu.girdi_aktif = true
	_oyuncu.set_physics_process(true)
	_kamera.reset_smoothing()
	_sayiyor = true
	_bitti = false
	_duraklatildi = false
	_duraklat_panel.visible = false
	_ayar_panel.visible = false
	_bitis_panel.visible = false
	_sure_yaz()
	_alanlari_ac.call_deferred()

func _process(delta: float) -> void:
	if _sayiyor:
		_sure += delta
		_sure_yaz()
		_kayit_sayaci += delta
		if _kayit_sayaci >= Hayalet.ARALIK:
			_kayit_sayaci -= Hayalet.ARALIK
			_kayit.append(_oyuncu.global_position)
	# Kamera ofseti iki kaynagin toplami: sarsinti + oyuncunun ileri bakisi.
	var sars_ofset := Vector2.ZERO
	if _sarsinti > 0.0:
		_sarsinti_t += delta
		_sarsinti = move_toward(_sarsinti, 0.0, Ayarlar.SARSINTI_SONUMU * delta)
		sars_ofset = Vector2(
			sin(_sarsinti_t * Ayarlar.SARSINTI_HIZ) * _sarsinti,
			cos(_sarsinti_t * Ayarlar.SARSINTI_HIZ * 1.3) * _sarsinti)
	_kamera.offset = sars_ofset + _oyuncu.kamera_ileri
	_kamera.zoom = Vector2.ONE * _oyuncu.kamera_yakinlik
	if _yeniden_sayac > 0.0:
		_yeniden_sayac -= delta
		_yeniden_dugmesini_guncelle()
	if not _bitti and not _duraklatildi and _oyuncu.global_position.y > Ayarlar.OLUM_Y:
		_oldu()

func _tehlikeye_degdi(govde: Node2D) -> void:
	if govde == _oyuncu and not _bitti:
		_oldu()

func _kontrole_degdi(govde: Node2D, alan: Area2D) -> void:
	if govde != _oyuncu or _bitti:
		return
	if _dogus.distance_to(alan.position) < 1.0:
		return
	_dogus = alan.position
	var g: Sprite2D = alan.get_node("Gorsel")
	g.frame = 1
	Ses.cal("kontrol")
	parcacik_at(alan.global_position, Palet.NOKTA_BAGLI, 10)

func _bitise_degdi(govde: Node2D) -> void:
	if govde != _oyuncu or _bitti:
		return
	_bitti = true
	_sayiyor = false
	_oyuncu.girdi_aktif = false
	_oyuncu.kanca_birak()
	_oyuncu.set_physics_process(false)
	Ses.cal("bitis")
	parcacik_at(_oyuncu.global_position, Palet.BITIS, 24)

	_yeniden_dugmesini_gizle()

	# Gunluk kosu ayri yuvaya yazilir: en iyi sureyi, acik bolumu, akis rekorunu
	# ve hayaleti BOZMAZ - degistiriciyle kosulmus bir sure normal tabloya girmemeli.
	if _gunluk:
		var g_rekor := Kayit.gunluk_yaz(Gunluk.tohum(), _sure)
		var g_satirlar := [
			"GÜNLÜK MEYDAN OKUMA",
			Gunluk.baslik(),
			"Süre: %s" % _bicim(_sure),
			"YENİ REKOR!" if g_rekor else "Bugünün en iyisi: %s" % _bicim(
				Kayit.gunluk_en_iyi(Gunluk.tohum())),
			"Akış: ×%d" % _en_uzun_zincir,
		]
		_bitis_metin.text = "\n".join(PackedStringArray(g_satirlar))
		_bitis_panel.visible = true
		_sonraki_dugme.disabled = true
		_bitis_panel.find_child("Yeniden", true, false).grab_focus()
		return

	var akis_rekor := Kayit.akis_yaz(bolum_no, _en_uzun_zincir)
	var rekor := Kayit.sure_yaz(bolum_no, _sure)
	Kayit.bolum_ac(mini(bolum_no + 1, Bolumler.sayi()))
	if rekor and int(Kayit.ayar("hayalet_kip")) > 0:
		Kayit.hayalet_yaz(bolum_no, _kayit, Hayalet.ARALIK)

	var madalya := Bolumler.madalya(bolum_no, _sure)
	if madalya < 3:
		Ses.cal("madalya")
	var m: Array = _veri["madalya"]
	var satirlar := [
		"%d. bölüm — %s" % [bolum_no, Bolumler.ad(bolum_no)],
		"Süre: %s" % _bicim(_sure),
		"YENİ REKOR!" if rekor else "En iyi: %s" % _bicim(Kayit.en_iyi(bolum_no)),
		"Madalya: %s" % Bolumler.MADALYA_ADI[madalya],
		"Altın %s · Gümüş %s · Bronz %s" % [_bicim(m[0]), _bicim(m[1]), _bicim(m[2])],
		"Akış: ×%d%s" % [_en_uzun_zincir, "  (yeni en uzun zincir!)" if akis_rekor else ""],
	]
	_bitis_metin.text = "\n".join(PackedStringArray(satirlar))
	_bitis_panel.visible = true
	_sonraki_dugme.disabled = bolum_no >= Bolumler.sayi()
	_sonraki_dugme.grab_focus()

func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("duraklat"):
		if _ayar_panel.visible:
			_ayarlardan_don()
		elif _bitti:
			_menuye()
		else:
			_duraklat_degistir()
	elif olay.is_action_pressed("yeniden") and not _duraklatildi:
		_yeniden()
	elif _bitti and olay.is_action_pressed("ui_accept") and not _sonraki_dugme.disabled:
		_sonraki()
	else:
		return
	get_viewport().set_input_as_handled()

func _duraklat_degistir() -> void:
	if _bitti:
		return   # dokunmatik Duraklat dugmesi bitis panelinin altinda kalir
	_duraklatildi = not _duraklatildi
	_yeniden_dugmesini_guncelle()
	_ayar_panel.visible = false
	_duraklat_panel.visible = _duraklatildi
	_sayiyor = not _duraklatildi
	_oyuncu.set_physics_process(not _duraklatildi)
	Ses.cal("menu")
	if _duraklatildi:
		_duraklat_panel.find_child("Devam", true, false).grab_focus()

func _sonraki() -> void:
	if bolum_no < Bolumler.sayi():
		Gecis.git(Bolumler.yol(bolum_no + 1))

func _menuye() -> void:
	Gunluk.aktif = false
	Gecis.git(MENU_YOLU)

# --- Dokunmatik yeniden baslatma --------------------------------------

## Telefonda olumden sonra bolumu bastan almanin tek yolu Duraklat -> "Bölümü
## yeniden başla" idi (iki dokunus). Olumun ardindan ekranin ust ortasinda
## tek dokunusluk bir dugme beliriyor.
##
## Yanlislikla tetiklenmesin diye iki onlem var: (1) dugme ilk
## YENIDEN_BEKLEME saniyesinde KAPALI - olum aninda ekranda olan parmak
## uzerine denk gelirse bir sey olmaz, (2) ekranin tamami degil, kucuk bir
## dugme; tek parmak semasinin kanca dokunusuyla cakismiyor.
func _yeniden_dugmesini_guncelle() -> void:
	if _yeniden_dugme == null:
		return
	var gorunur := _yeniden_sayac > 0.0 and not _bitti and not _duraklatildi
	_yeniden_dugme.visible = gorunur
	_yeniden_dugme.disabled = _yeniden_sayac > YENIDEN_GORUNME - YENIDEN_BEKLEME

func _yeniden_dugmesini_gizle() -> void:
	_yeniden_sayac = 0.0
	if _yeniden_dugme != null:
		_yeniden_dugme.visible = false

func _dokunmatik_yeniden() -> void:
	if _yeniden_dugme != null and _yeniden_dugme.disabled:
		return
	Ses.cal("menu")
	_yeniden()

# --- Hayalet ----------------------------------------------------------

## Hayalet kaynagi ayardan gelir: 1 = kendi en iyi kosun, 2 = ALTIN HAYALET
## (botun kosusu). Altin hayalet yalniz o bolumde altin madalya kazanildiysa
## acilir - "nereden gidilirmis"in cevabi odul olmali, basta verilen bir sey degil.
## Veri yoksa (bot o bolumu bitirememisse) sessizce kendi kosuna duser.
func _hayaleti_kur() -> void:
	var kip := int(Kayit.ayar("hayalet_kip"))
	if kip <= 0:
		return
	if kip >= 2 and altin_kazanildi(bolum_no):
		var altin := RotaVerisi.iz(bolum_no)
		if altin.size() >= 2:
			_hayalet = Hayalet.new()
			add_child(_hayalet)
			# Botun izi 10 Hz: tools/rota.gd IZ_ARALIK_KARE = 6 kare.
			_hayalet.kur(altin, Hayalet.ARALIK, true)
			return
	var kayit := Kayit.hayalet_oku(bolum_no)
	var ornekler: PackedVector2Array = kayit.get("ornekler", PackedVector2Array())
	if ornekler.size() < 2:
		return
	_hayalet = Hayalet.new()
	add_child(_hayalet)
	_hayalet.kur(ornekler, float(kayit.get("aralik", Hayalet.ARALIK)))

## O bolumde altin madalya kazanildi mi (rota ipucu ve altin hayalet bunu sorar).
static func altin_kazanildi(no: int) -> bool:
	return Bolumler.madalya(no, Kayit.en_iyi(no)) == 0

# --- Arayuz -----------------------------------------------------------

func _sure_yaz() -> void:
	_sure_etiket.text = "Süre  %s" % _bicim(_sure)

## Ustalik zinciri gostergesi: iki ve ustu zincirde gorunur.
func _akis_yaz() -> void:
	if _akis_etiket == null:
		return
	_akis_etiket.visible = _zincir >= 2
	_akis_etiket.text = "Akış ×%d" % _zincir

## Madalya sureleri ms hassasiyetinde uretildigi icin gosterim de ms.
static func _bicim(saniye: float) -> String:
	if saniye <= 0.0:
		return "--:--"
	return "%02d:%06.3f" % [int(saniye) / 60, fmod(saniye, 60.0)]

func _arayuzu_kur() -> void:
	var katman := CanvasLayer.new()
	katman.name = "Arayuz"
	add_child(katman)

	_sure_etiket = _serit(_etiket("", 16, Color(1, 1, 1)))
	_sure_etiket.position = Vector2(12, 8)
	katman.add_child(_sure_etiket)

	_akis_etiket = _serit(_etiket("", 12, Palet.ALTIN))
	_akis_etiket.position = Vector2(12, 78)
	_akis_etiket.visible = false
	katman.add_child(_akis_etiket)

	var en_iyi := Kayit.gunluk_en_iyi(Gunluk.tohum()) if _gunluk else Kayit.en_iyi(bolum_no)
	_eniyi_etiket = _serit(_etiket("En iyi  %s" % _bicim(en_iyi), 11, Ayarlar.RENK_METIN))
	_eniyi_etiket.position = Vector2(12, 30)
	katman.add_child(_eniyi_etiket)

	# Sureler ms hassasiyetine gecince "En iyi 00:08.800" uzadi; simge 92'de
	# metnin uzerine biniyordu.
	_madalya_gorsel = madalya_simgesi(Bolumler.madalya(bolum_no, en_iyi))
	_madalya_gorsel.position = Vector2(108, 30)
	katman.add_child(_madalya_gorsel)

	var baslik_metni := "%d. %s" % [bolum_no, _veri["ad"]]
	if _gunluk:
		baslik_metni = "GÜNLÜK · %s" % String(Gunluk.degistirici()["ad"])
	var baslik := _serit(_etiket(baslik_metni, 11,
		Palet.ALTIN if _gunluk else Ayarlar.RENK_METIN_SOLUK))
	baslik.position = Vector2(12, 46)
	katman.add_child(baslik)

	var hedef: Array = _veri["madalya"]
	var altin := _serit(_etiket("Altın hedefi  %s" % _bicim(hedef[0]), 10, Palet.ALTIN))
	altin.position = Vector2(12, 62)
	katman.add_child(altin)

	# Dokunmatikte R/Esc yok; ayni koseye gercek bir duraklat dugmesi konur.
	if Ayarlar.dokunmatik_mi():
		var durakla := Button.new()
		durakla.name = "DuraklatDugme"
		durakla.text = "Duraklat"
		durakla.add_theme_font_size_override("font_size", 10)
		durakla.pressed.connect(_duraklat_degistir)
		durakla.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		durakla.offset_left = -78.0
		durakla.offset_top = 6.0
		durakla.offset_right = -10.0
		durakla.offset_bottom = 28.0
		katman.add_child(durakla)
	else:
		var yardim := _serit(_etiket("R: yeniden   Esc: duraklat", 10, Ayarlar.RENK_METIN_SOLUK))
		yardim.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		yardim.offset_left = -152.0
		yardim.offset_top = 8.0
		yardim.offset_right = -12.0
		yardim.offset_bottom = 24.0
		yardim.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		katman.add_child(yardim)

	if Ayarlar.dokunmatik_mi():
		_yeniden_dugme = Button.new()
		_yeniden_dugme.name = "YenidenDugme"
		_yeniden_dugme.text = "Baştan başla"
		_yeniden_dugme.add_theme_font_size_override("font_size", 12)
		_yeniden_dugme.pressed.connect(_dokunmatik_yeniden)
		_yeniden_dugme.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_yeniden_dugme.offset_left = -56.0
		_yeniden_dugme.offset_top = 44.0
		_yeniden_dugme.offset_right = 56.0
		_yeniden_dugme.offset_bottom = 70.0
		_yeniden_dugme.visible = false
		katman.add_child(_yeniden_dugme)

	var ipucu := Bolumler.ipucu(bolum_no)
	if ipucu != "":
		var e := _serit(_etiket(ipucu, 11, Color(0.95, 0.9, 0.6)))
		e.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		e.offset_top = -34.0
		e.offset_bottom = -14.0
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		katman.add_child(e)

	_duraklat_panel = panel("DURAKLATILDI", [
		{"ad": "Devam", "metin": "Devam", "islev": _duraklat_degistir},
		{"ad": "Yeniden", "metin": "Bölümü yeniden başla", "islev": _yeniden},
		{"ad": "Ayarlar", "metin": "Ayarlar", "islev": _ayarlara},
		{"ad": "Menu", "metin": "Menüye dön", "islev": _menuye},
	])
	katman.add_child(_duraklat_panel)

	_bitis_panel = panel("BÖLÜM BİTTİ", [
		{"ad": "Sonraki", "metin": Ayarlar.kisayol("Sonraki bölüm", "Enter"), "islev": _sonraki},
		{"ad": "Yeniden", "metin": Ayarlar.kisayol("Tekrar dene", "R"), "islev": _yeniden},
		{"ad": "Menu", "metin": Ayarlar.kisayol("Menüye dön", "Esc"), "islev": _menuye},
	])
	katman.add_child(_bitis_panel)
	_bitis_metin = _bitis_panel.find_child("Baslik", true, false)
	_sonraki_dugme = _bitis_panel.find_child("Sonraki", true, false)

	# Ayarlar bolumu terk etmeden, duraklatma perdesinin uzerinde acilir.
	_ayar_panel = AyarPanel.yap(_ayarlardan_don, true)
	katman.add_child(_ayar_panel)

func _ayarlara() -> void:
	Ses.cal("menu")
	_duraklat_panel.visible = false
	AyarPanel.ana_kutuya_don(_ayar_panel)
	_ayar_panel.visible = true
	_ayar_panel.find_child("GeriAyar", true, false).grab_focus()

func _ayarlardan_don() -> void:
	Ses.cal("menu")
	_ayar_panel.visible = false
	_duraklat_panel.visible = true
	_duraklat_panel.find_child("Devam", true, false).grab_focus()

func _etiket(metin: String, boy: int, renk: Color) -> Label:
	return etiket_yap(metin, boy, renk)

# --- Ortak arayuz parcalari (menu.gd de kullanir) ----------------------

## HUD metni dunya ciziminin onunde; koyu seffaf serit onu kanca noktasi gibi
## sprite'larin uzerinde de okunur tutar (v0.3.1 web bulgusu).
static func _serit(e: Label) -> Label:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.05, 0.10, 0.62)
	s.content_margin_left = 4.0
	s.content_margin_right = 4.0
	s.content_margin_top = 1.0
	s.content_margin_bottom = 1.0
	s.corner_radius_top_left = 2
	s.corner_radius_top_right = 2
	s.corner_radius_bottom_left = 2
	s.corner_radius_bottom_right = 2
	e.add_theme_stylebox_override("normal", s)
	return e

static func etiket_yap(metin: String, boy: int, renk: Color) -> Label:
	var e := Label.new()
	e.text = metin
	e.add_theme_font_size_override("font_size", boy)
	e.add_theme_color_override("font_color", renk)
	return e

## 0 altin, 1 gumus, 2 bronz, 3 = gorunmez.
static func madalya_simgesi(no: int) -> TextureRect:
	var t := TextureRect.new()
	var atlas := AtlasTexture.new()
	atlas.atlas = DOKU_MADALYA
	atlas.region = Rect2(clampi(no, 0, 2) * 12, 0, 12, 12)
	t.texture = atlas
	t.custom_minimum_size = Vector2(12, 12)
	t.visible = no < 3
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func panel(baslik: String, dugmeler: Array) -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_STOP
	kok.visible = false

	var perde := ColorRect.new()
	perde.color = Color(Palet.GOK_DIP, 0.85)
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(perde)

	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)

	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 8)
	orta.add_child(kutu)

	var b := etiket_yap(baslik, 16, Color(1, 1, 1))
	b.name = "Baslik"
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(b)

	for d: Dictionary in dugmeler:
		var dugme := Button.new()
		dugme.name = String(d["ad"])
		dugme.text = String(d["metin"])
		dugme.add_theme_font_size_override("font_size", 12)
		dugme.pressed.connect(d["islev"])
		kutu.add_child(dugme)

	return kok
