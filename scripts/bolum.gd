extends Node2D
class_name Bolum
## Tek bir bolumun tamami: geometriyi Bolumler.VERI tablosundan kurar, sureyi
## tutar, olum/kontrol noktasi/bitis akisini, madalyayi, hayaleti ve arayuzu yonetir.
##
## Sahne dosyalari (scenes/bolumler/bolum_NN.tscn) sadece bolum_no tasir;
## boylece 14 bolum tek kod yolundan uretilir ve veri tek yerde durur.

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")
const MENU_YOLU := "res://scenes/menu.tscn"

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

var _arayuz: CanvasLayer
var _sure_etiket: Label
var _akis_etiket: Label
var _eniyi_etiket: Label
var _madalya_gorsel: Control
var _duraklat_panel: Control
var _ayar_panel: Control
var _bitis_panel: Control
var _bitis_kart: Control
var _bk_ust: Label
var _bk_sure: Label
var _bk_damga: Control
var _bk_madalya: Control
var _bk_madalya_yazi: Label
var _bk_alt: Label
var _bk_esik: Label
var _sonraki_dugme: Button
var _yeniden_kart_dugme: Button
var _ipucu_kutu: Control = null
var _ipucu_sayac := -1.0             ## >0: ilk kancadan sonra ipucu bu kadar daha gorunur
var _ilk_kanca := false

func _ready() -> void:
	add_to_group(&"bolum")
	_gunluk = Gunluk.aktif
	_veri = Bolumler.veri(bolum_no)
	Tema.aktif = Tema.bolum_temasi(bolum_no)
	RenderingServer.set_default_clear_color(Tema.zemin())
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

## Videodaki egik uzun bloklar: uc katman, blok renginde %5-9 opaklik, dogrusal
## parallaks. Doku yok, hepsi duz poligon (her olcekte keskin, ucuz).
func _arka_plani_kur() -> void:
	var blok := Tema.blok()
	_bant_katmani(Vector2(0.12, 0.05), Color(blok, 0.02), [[40.0, 56.0], [200.0, 30.0]], 120.0, -9)
	_bant_katmani(Vector2(0.25, 0.10), Color(blok, 0.026), [[90.0, 24.0], [250.0, 70.0]], 100.0, -8)
	_bant_katmani(Vector2(0.45, 0.18), Color(blok, 0.032), [[20.0, 14.0], [180.0, 40.0]], 80.0, -7)

func _bant_katmani(olcek: Vector2, renk: Color, bantlar: Array, egim: float, z: int) -> void:
	var p := Parallax2D.new()
	p.scroll_scale = olcek
	p.repeat_size = Vector2(320, 0)
	p.repeat_times = 24
	p.z_index = z
	add_child(p)
	for b: Array in bantlar:
		var x: float = b[0]
		var w: float = b[1]
		var poli := Polygon2D.new()
		poli.color = renk
		poli.polygon = PackedVector2Array([
			Vector2(x, -120), Vector2(x + w, -120),
			Vector2(x + w - egim, 480), Vector2(x - egim, 480)])
		p.add_child(poli)

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
			(kn.get_node("Gorsel") as Isaret).frame = 1
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

## Zemin dikdortgenleri TileMapLayer'a dosenir (CARPISMA tek yerden); gorunum
## ayri: ayni dikdortgenler blok renginde duz dolgu cizilir (karo dokusu yok).
func _zemini_dose() -> void:
	var kat := TileMapLayer.new()
	kat.name = "Zemin"
	kat.tile_set = KaroSeti.al()
	kat.visible = false   # yalniz carpisma: cizimi ZeminCizim yapar (fizik gorunurluge bagli degil)
	var kutular: Array[Rect2] = Bolumler.zeminler(bolum_no)
	for r: Rect2 in kutular:
		var tx0 := int(r.position.x) / KaroSeti.BOY
		var ty0 := int(r.position.y) / KaroSeti.BOY
		var tx1 := int(r.end.x) / KaroSeti.BOY - 1
		var ty1 := int(r.end.y) / KaroSeti.BOY - 1
		for ty in range(ty0, ty1 + 1):
			for tx in range(tx0, tx1 + 1):
				kat.set_cell(Vector2i(tx, ty), 0, Vector2i(0, 0))
	_dunya.add_child(kat)
	var cizim := Node2D.new()
	cizim.name = "ZeminCizim"
	cizim.z_index = 1
	cizim.draw.connect(func() -> void:
		for r: Rect2 in kutular:
			cizim.draw_rect(r, Tema.blok()))
	_dunya.add_child(cizim)

## Diken: her 16 px'te bir ucgen (carpisma dikdortgeniyle birebir ayni alan).
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
	var adet := maxi(1, int(r.size.x / 16.0))
	var taban := 0.0 if tavan else maxf(r.size.y - 16.0, 0.0)
	for i in adet:
		var x := i * 16.0
		var poli := Polygon2D.new()
		poli.color = Tema.DIKEN
		poli.antialiased = true
		if tavan:
			poli.polygon = PackedVector2Array([
				Vector2(x, taban), Vector2(x + 16.0, taban), Vector2(x + 8.0, taban + 16.0)])
		else:
			poli.polygon = PackedVector2Array([
				Vector2(x, taban + 16.0), Vector2(x + 16.0, taban + 16.0), Vector2(x + 8.0, taban)])
		alan.add_child(poli)
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
	perde.color = Color(Tema.blok(), 0.06)
	perde.size = r.size
	perde.position = -r.size * 0.5
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alan.add_child(perde)

	var pc := CPUParticles2D.new()
	pc.texture = Cizim.cizgi_dokusu()
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
	pc.angle_min = rad_to_deg(yon.angle())
	pc.angle_max = rad_to_deg(yon.angle())
	pc.color = Color(Tema.blok(), 0.5)
	alan.add_child(pc)

	var birim := yon.normalized()
	alan.body_entered.connect(func(g: Node2D) -> void:
		if g == _oyuncu:
			_oyuncu.ruzgar += birim)
	alan.body_exited.connect(func(g: Node2D) -> void:
		if g == _oyuncu:
			_oyuncu.ruzgar -= birim)
	alan.z_index = 3   # zeminin (1) onunde, oyuncunun (4) arkasinda
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
	var s := Isaret.yap(Isaret.KONTROL)
	s.name = "Gorsel"
	alan.add_child(s)
	alan.name = "Kontrol%d" % sira
	alan.z_index = 2
	alan.body_entered.connect(_kontrole_degdi.bind(alan))
	return alan

func _bitis_bayragi(yer: Vector2) -> Area2D:
	var alan := Area2D.new()
	alan.position = yer
	var sekil := RectangleShape2D.new()
	sekil.size = Vector2(24, 56)
	var carpisma := CollisionShape2D.new()
	carpisma.shape = sekil
	alan.monitorable = false
	alan.monitoring = false   # bayat ortusme tuzagi: ilk fizik karesinden sonra acilir
	alan.add_child(carpisma)
	alan.add_child(Isaret.yap(Isaret.BITIS))
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
	pc.texture = Cizim.nokta_dokusu()
	pc.emitting = false
	pc.one_shot = true
	pc.explosiveness = 0.9
	pc.lifetime = 0.5
	pc.spread = 180.0
	pc.gravity = Vector2(0, 420)
	pc.initial_velocity_min = 60.0
	pc.initial_velocity_max = 190.0
	pc.scale_amount_min = 0.3
	pc.scale_amount_max = 0.8
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
	# Ogretme: ilk kanca tutunca ipucu 6 sn daha kalir, sonra solar.
	if not _ilk_kanca:
		_ilk_kanca = true
		_ipucu_sayac = 6.0
	sars(1.6)
	parcacik_at(yer, Tema.TURUNCU, 6)
	# Ustalik zinciri: yere degmeden art arda tutulan her nokta zinciri uzatir.
	_zincir += 1
	_en_uzun_zincir = maxi(_en_uzun_zincir, _zincir)
	if _zincir >= 2:
		Ses.cal("akis")
	_akis_yaz()

## bonus = esik ustu hizda birakildi (BIRAKMA_CARPANI uygulandi).
func _kanca_koptu(hiz: Vector2, bonus: bool) -> void:
	if bonus:
		parcacik_at(_oyuncu.global_position, Tema.TURUNCU, 14)
		sars(1.2)
	elif hiz.length() > 320.0:
		parcacik_at(_oyuncu.global_position, Tema.blok(), 8)

func _yere_indi(dusus_hizi: float) -> void:
	_zincir = 0
	_akis_yaz()
	if dusus_hizi > 260.0:
		parcacik_at(_oyuncu.global_position + Vector2(0, 12), Color(Tema.blok(), 0.8),
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
	parcacik_at(_oyuncu.global_position, Tema.TURKUAZ, 18)
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
	if _ipucu_sayac > 0.0:
		_ipucu_sayac -= delta
		if _ipucu_sayac <= 0.0 and is_instance_valid(_ipucu_kutu):
			var kutu := _ipucu_kutu
			kutu.create_tween().tween_property(kutu, "modulate:a", 0.0, 0.4)
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
	var g: Isaret = alan.get_node("Gorsel")
	g.frame = 1
	Ses.cal("kontrol")
	parcacik_at(alan.global_position, Tema.TURKUAZ, 10)

func _bitise_degdi(govde: Node2D) -> void:
	if govde != _oyuncu or _bitti:
		return
	_bitti = true
	_sayiyor = false
	_oyuncu.girdi_aktif = false
	_oyuncu.kanca_birak()
	_oyuncu.set_physics_process(false)
	Ses.cal("bitis")
	parcacik_at(_oyuncu.global_position, Tema.TURUNCU, 24)
	sars(2.0)

	_yeniden_dugmesini_gizle()

	# Gunluk kosu ayri yuvaya yazilir: en iyi sureyi, acik bolumu, akis rekorunu
	# ve hayaleti BOZMAZ - degistiriciyle kosulmus bir sure normal tabloya girmemeli.
	if _gunluk:
		var g_rekor := Kayit.gunluk_yaz(Gunluk.tohum(), _sure)
		_bitis_karti_doldur(tr("GÜNLÜK MEYDAN OKUMA"), Gunluk.baslik(), g_rekor, 3,
			tr("BUGÜNÜN EN İYİSİ %s") % _bicim(Kayit.gunluk_en_iyi(Gunluk.tohum())),
			_akis_yazisi(false), true)
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
	var esik := tr("ALTIN %s · GÜMÜŞ %s · BRONZ %s") % [_bicim(m[0]), _bicim(m[1]), _bicim(m[2])]
	_bitis_karti_doldur(Tema.kisa_baslik(bolum_no, Bolumler.ad(bolum_no)), "", rekor, madalya,
		tr("EN İYİ %s") % _bicim(Kayit.en_iyi(bolum_no)),
		_akis_yazisi(akis_rekor) + "\n" + esik, false)

func _akis_yazisi(yeni_rekor: bool) -> String:
	return tr("AKIŞ ×%d") % _en_uzun_zincir + (tr("  · YENİ EN UZUN ZİNCİR") if yeni_rekor else "")

## Bitis kartini doldurur ve acar. ust = bolum etiketi, alt_baslik = gunluk
## degistirici adi, madalya 0-2 ya da 3 (yok). Ilk odak: madalya altin degilse
## ya da son bolumdeyse TEKRAR (hiz oyununda asil dongu), degilse SONRAKI.
func _bitis_karti_doldur(ust: String, alt_baslik: String, rekor: bool, madalya: int,
		en_iyi: String, ayrinti: String, gunluk: bool) -> void:
	_bk_ust.text = ust if alt_baslik == "" else "%s · %s" % [ust, alt_baslik]
	_bk_sure.text = _bicim(_sure)
	_bk_damga.visible = rekor
	_bk_madalya.visible = madalya < 3
	for c in _bk_madalya.get_children():
		if c is Cizim.Madalya:
			c.queue_free()
	if madalya < 3:
		_bk_madalya.add_child(Bolum.madalya_simgesi(madalya))
		_bk_madalya.move_child(_bk_madalya.get_child(_bk_madalya.get_child_count() - 1), 0)
		_bk_madalya_yazi.text = Tema.buyuk(Bolumler.madalya_adi(madalya))
	_bk_alt.text = en_iyi
	_bk_esik.text = ayrinti
	var son := bolum_no >= Bolumler.sayi()
	_sonraki_dugme.disabled = gunluk or son
	_sonraki_dugme.visible = not gunluk
	var tekrar_birincil := gunluk or son or madalya != 0
	_stil_birincil(_yeniden_kart_dugme, tekrar_birincil)
	_stil_birincil(_sonraki_dugme, not tekrar_birincil)
	_kart_goster(_bitis_panel, _bitis_kart)
	if tekrar_birincil or _sonraki_dugme.disabled:
		_yeniden_kart_dugme.grab_focus()
	else:
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
	else:
		return
	get_viewport().set_input_as_handled()

func _duraklat_degistir() -> void:
	if _bitti:
		return   # dokunmatik Duraklat dugmesi bitis panelinin altinda kalir
	_duraklatildi = not _duraklatildi
	_yeniden_dugmesini_guncelle()
	_ayar_panel.visible = false
	_duraklat_panel.visible = false
	if _duraklatildi:
		_kart_goster(_duraklat_panel, _duraklat_panel.find_child("Kart", true, false))
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
	_sure_etiket.text = _bicim(_sure)

## Ustalik zinciri gostergesi: iki ve ustu zincirde gorunur.
func _akis_yaz() -> void:
	if _akis_etiket == null:
		return
	_akis_etiket.visible = _zincir >= 2
	_akis_etiket.text = tr("AKIŞ ×%d") % _zincir

## Madalya sureleri ms hassasiyetinde uretildigi icin gosterim de ms.
static func _bicim(saniye: float) -> String:
	if saniye <= 0.0:
		return "--:--"
	return "%02d:%06.3f" % [int(saniye) / 60, fmod(saniye, 60.0)]

## 0 altin, 1 gumus, 2 bronz, 3 = gorunmez.
static func madalya_simgesi(no: int) -> Control:
	return Cizim.Madalya.new(no)

## HUD rozeti: zemin renginde %88 opak kucuk plaka. Yazi blok renginde, boylece
## hem bos zeminde hem blogun onunde okunur (dunya cizimini kapatmaz).
func _rozet(ic: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override("panel", Tema.kutu(Color(Tema.zemin(), 0.88), 3, 6, 4))
	p.add_child(ic)
	return p

func _kutu_dikey(ayirim: int = 0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", ayirim)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v

func _arayuzu_kur() -> void:
	_arayuz = CanvasLayer.new()
	_arayuz.name = "Arayuz"
	add_child(_arayuz)
	var blok := Tema.blok()
	var soluk := Tema.etiket_rengi(blok)

	# Sol ust: 01 / BOLUM ADI, buyuk sure, akis sayaci.
	var sol := _kutu_dikey()
	var baslik_metni := Tema.kisa_baslik(bolum_no, Bolumler.ad(bolum_no))
	if _gunluk:
		baslik_metni = "%s · %s" % [tr("GÜNLÜK"), Tema.buyuk(tr(String(Gunluk.degistirici()["ad"])))]
	sol.add_child(Tema.etiket(baslik_metni, 8, soluk))
	_sure_etiket = Tema.etiket("", 16, blok, true, true)
	sol.add_child(_sure_etiket)
	_akis_etiket = Tema.etiket("", 8, Tema.TURUNCU, true, true)
	_akis_etiket.visible = false
	sol.add_child(_akis_etiket)
	var sol_rozet := _rozet(sol)
	sol_rozet.position = Vector2(8, 6)
	_arayuz.add_child(sol_rozet)

	# Sag ust: en iyi sure + madalya, altin hedef, tus/duraklat.
	var sag := _kutu_dikey()
	var en_iyi := Kayit.gunluk_en_iyi(Gunluk.tohum()) if _gunluk else Kayit.en_iyi(bolum_no)
	var satir := HBoxContainer.new()
	satir.mouse_filter = Control.MOUSE_FILTER_IGNORE
	satir.alignment = BoxContainer.ALIGNMENT_END
	satir.add_theme_constant_override("separation", 4)
	_madalya_gorsel = madalya_simgesi(Bolumler.madalya(bolum_no, en_iyi))
	satir.add_child(_madalya_gorsel)
	_eniyi_etiket = Tema.etiket(tr("EN İYİ %s") % _bicim(en_iyi), 8, blok)
	satir.add_child(_eniyi_etiket)
	sag.add_child(satir)
	var hedef: Array = _veri["madalya"]
	var altin := Tema.etiket(tr("ALTIN %s") % _bicim(hedef[0]), 8, soluk)
	altin.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sag.add_child(altin)
	# Dokunmatikte R/Esc yok; ayni koseye gercek bir duraklat dugmesi konur.
	if Ayarlar.dokunmatik_mi():
		var durakla := Button.new()
		durakla.name = "DuraklatDugme"
		durakla.text = tr("Duraklat")
		durakla.add_theme_font_size_override("font_size", 10)
		durakla.custom_minimum_size = Vector2(76, 24)
		durakla.pressed.connect(_duraklat_degistir)
		sag.add_child(durakla)
	else:
		var yardim := Tema.etiket(tr("R: yeniden   Esc: duraklat"), 8, Color(blok, 0.5))
		yardim.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		sag.add_child(yardim)
	var sag_rozet := _rozet(sag)
	sag_rozet.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	sag_rozet.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sag_rozet.offset_right = -8.0
	sag_rozet.offset_left = -8.0
	sag_rozet.offset_top = 6.0
	sag_rozet.offset_bottom = 6.0
	if Ayarlar.dokunmatik_mi():
		sag_rozet.mouse_filter = Control.MOUSE_FILTER_PASS
	_arayuz.add_child(sag_rozet)

	if Ayarlar.dokunmatik_mi():
		_yeniden_dugme = Button.new()
		_yeniden_dugme.name = "YenidenDugme"
		_yeniden_dugme.text = tr("Baştan başla")
		_yeniden_dugme.theme_type_variation = &"Birincil"
		_yeniden_dugme.add_theme_font_size_override("font_size", 12)
		_yeniden_dugme.pressed.connect(_dokunmatik_yeniden)
		_yeniden_dugme.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
		_yeniden_dugme.offset_left = -60.0
		_yeniden_dugme.offset_top = 44.0
		_yeniden_dugme.offset_right = 60.0
		_yeniden_dugme.offset_bottom = 72.0
		_yeniden_dugme.visible = false
		_arayuz.add_child(_yeniden_dugme)

	# Alt ortada bolum ipucu: yalniz bu bolum daha hic bitirilmediyse ve ilk
	# kancadan sonra birkac saniye icinde solar (ogretme, sonra yol acma).
	_ipucu_kutu = null
	var ipucu := Bolumler.ipucu(bolum_no)
	if ipucu != "" and not _gunluk and Kayit.en_iyi(bolum_no) <= 0.0:
		var e := Tema.etiket(ipucu, 10, blok, false)
		var kutu := _rozet(e)
		kutu.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		kutu.grow_horizontal = Control.GROW_DIRECTION_BOTH
		kutu.grow_vertical = Control.GROW_DIRECTION_BEGIN
		kutu.offset_bottom = -12.0
		kutu.offset_top = -12.0
		_arayuz.add_child(kutu)
		_ipucu_kutu = kutu

	_duraklat_panel = _duraklat_paneli()
	_arayuz.add_child(_duraklat_panel)
	_bitis_panel = _bitis_paneli()
	_arayuz.add_child(_bitis_panel)
	# Ayarlar bolumu terk etmeden, duraklatma perdesinin uzerinde acilir.
	_ayar_panel = AyarPanel.yap(_ayarlardan_don, true, _dil_degisti)
	_arayuz.add_child(_ayar_panel)
	_sure_yaz()

func _perde_kok() -> Control:
	var kok := Control.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.mouse_filter = Control.MOUSE_FILTER_STOP
	kok.visible = false
	var perde := Panel.new()
	perde.theme_type_variation = &"Perde"
	perde.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(perde)
	return kok

func _dugme(ad: String, metin: String, islev: Callable, birincil := false, boy := 12) -> Button:
	var d := Button.new()
	d.name = ad
	d.text = metin
	d.custom_minimum_size = Vector2(0, 26)
	d.add_theme_font_size_override("font_size", boy)
	if birincil:
		d.theme_type_variation = &"Birincil"
	d.pressed.connect(islev)
	return d

func _stil_birincil(d: Button, birincil: bool) -> void:
	d.theme_type_variation = &"Birincil" if birincil else &"KartDugme"
	d.add_theme_font_size_override("font_size", 14 if birincil else 12)

## Duraklatma: koyu kart, Devam birincil. Esc / P ile de acilir.
func _duraklat_paneli() -> Control:
	var kok := _perde_kok()
	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)
	var kart := PanelContainer.new()
	kart.name = "Kart"
	kart.add_theme_stylebox_override("panel", Tema.kutu(Tema.PANEL, 8, 26, 18,
		Color(Tema.KAGIT, 0.22), 2))
	orta.add_child(kart)
	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 6)
	kart.add_child(kutu)
	var ust := Tema.etiket(tr("DURAKLATILDI"), 8, Tema.etiket_rengi(Tema.KAGIT))
	ust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(ust)
	var baslik := Tema.etiket(Tema.kisa_baslik(bolum_no, Bolumler.ad(bolum_no)), 10, Tema.KAGIT, true, true)
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(baslik)
	var d1 := _dugme("Devam", tr("Devam"), _duraklat_degistir, true, 14)
	d1.custom_minimum_size = Vector2(200, 32)
	kutu.add_child(d1)
	kutu.add_child(_dugme("Yeniden", tr("Bölümü baştan"), _yeniden))
	kutu.add_child(_dugme("Ayarlar", tr("Ayarlar"), _ayarlara))
	kutu.add_child(_dugme("Menu", tr("Menüye dön"), _menuye))
	return kok

## Bolum sonu: kagit kart. Buyuk sure, madalya, rekor damgasi, en iyi + akis.
## Iki buyuk dugme: Tekrar dene / Sonraki bolum (hangisi birincil: _bitis_karti_doldur).
func _bitis_paneli() -> Control:
	var kok := _perde_kok()
	var orta := CenterContainer.new()
	orta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	kok.add_child(orta)
	var kart := PanelContainer.new()
	kart.name = "Kart"
	kart.add_theme_stylebox_override("panel", Tema.kutu(Tema.KAGIT, 12, 26, 18))
	orta.add_child(kart)
	_bitis_kart = kart
	var kutu := VBoxContainer.new()
	kutu.name = "Kutu"
	kutu.add_theme_constant_override("separation", 5)
	kart.add_child(kutu)

	_bk_ust = Tema.etiket("", 8, Color(Tema.MUREKKEP, 0.65))
	_bk_ust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(_bk_ust)
	_bk_sure = Tema.etiket("", 30, Tema.MUREKKEP, true, true)
	_bk_sure.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(_bk_sure)

	# Sari damga: yalniz yeni rekorda. Duz sari dolgu, murekkep yazi.
	var damga := PanelContainer.new()
	damga.add_theme_stylebox_override("panel", Tema.kutu(Tema.SARI, 3, 8, 2))
	damga.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	damga.add_child(Tema.etiket(tr("YENİ REKOR"), 9, Tema.MUREKKEP, true, true))
	damga.visible = false
	_bk_damga = damga
	kutu.add_child(damga)

	var m := HBoxContainer.new()
	m.alignment = BoxContainer.ALIGNMENT_CENTER
	m.add_theme_constant_override("separation", 5)
	_bk_madalya = m
	_bk_madalya_yazi = Tema.etiket("", 9, Tema.MUREKKEP, true, true)
	m.add_child(_bk_madalya_yazi)
	kutu.add_child(m)

	_bk_alt = Tema.etiket("", 8, Color(Tema.MUREKKEP, 0.75))
	_bk_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(_bk_alt)
	_bk_esik = Tema.etiket("", 8, Color(Tema.MUREKKEP, 0.6))
	_bk_esik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kutu.add_child(_bk_esik)

	var dugmeler := HBoxContainer.new()
	dugmeler.add_theme_constant_override("separation", 8)
	_yeniden_kart_dugme = _dugme("Yeniden", Ayarlar.kisayol(tr("Tekrar dene"), "R"), _yeniden, true, 14)
	_yeniden_kart_dugme.custom_minimum_size = Vector2(150, 32)
	_sonraki_dugme = _dugme("Sonraki", Ayarlar.kisayol(tr("Sonraki bölüm"), "Enter"), _sonraki, false, 12)
	_sonraki_dugme.custom_minimum_size = Vector2(150, 32)
	dugmeler.add_child(_yeniden_kart_dugme)
	dugmeler.add_child(_sonraki_dugme)
	kutu.add_child(dugmeler)
	var menu := _dugme("Menu", Ayarlar.kisayol(tr("Menüye dön"), "Esc"), _menuye, false, 10)
	menu.theme_type_variation = &"KartMetin"
	kutu.add_child(menu)
	return kok

## Kart girisi: 180 ms alfa, 220 ms olcek 0,96 -> 1 (ease-out cubic).
func _kart_goster(kok: Control, kart: Control) -> void:
	kok.visible = true
	kok.modulate.a = 0.0
	var t := kok.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property(kok, "modulate:a", 1.0, 0.18)
	if kart != null:
		kart.pivot_offset = kart.get_combined_minimum_size() * 0.5
		kart.scale = Vector2(0.96, 0.96)
		kart.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC) \
			.tween_property(kart, "scale", Vector2.ONE, 0.22)
	var ilk := kok.find_child("Devam", true, false)
	if ilk is Control:
		(ilk as Control).grab_focus()

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

## Dil degisince arayuz yeniden kurulur (metinler kurulurken cevriliyor).
## Ayar paneli kendi dugmesinden tetikledigi icin yikim bir kare ertelenir.
func _dil_degisti() -> void:
	_arayuzu_yenile.call_deferred()

func _arayuzu_yenile() -> void:
	var ayarda := _ayar_panel != null and _ayar_panel.visible
	var eski := _arayuz
	remove_child(eski)
	eski.queue_free()
	_arayuzu_kur()
	_akis_yaz()
	if ayarda:
		AyarPanel.ana_kutuya_don(_ayar_panel)
		_ayar_panel.visible = true
		_ayar_panel.find_child("GeriAyar", true, false).grab_focus()
	elif _duraklatildi:
		_duraklat_panel.visible = true
		_duraklat_panel.find_child("Devam", true, false).grab_focus()
