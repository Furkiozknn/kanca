extends Node2D
## Cekirdek mekanik + bolum verisi testleri. Calistirma:
##   powershell -ExecutionPolicy Bypass -File tests\calistir.ps1
## Cikis kodu = kalan test sayisi (0 = hepsi gecti).

const OYUNCU_SAHNE := preload("res://scenes/oyuncu.tscn")

const HALAT_TOLERANS := 1.5   ## px; konum duzeltmesinden sonra kabul edilen sapma
const KARE_SAYISI := 320      ## sarkac simulasyonunun uzunlugu

var _kalan := 0
var _toplam := 0

func _ready() -> void:
	_calistir()

func _calistir() -> void:
	await get_tree().process_frame
	print("=== Kanca testleri ===")
	await _test_menzil()
	await _test_hedefleme_puani()
	await _test_gorus_hatti()
	await _test_hiz_yonu()
	await _test_kanca_tamponu()
	await _test_kojot_kanca()
	await _test_birakma_bonusu()
	await _test_pompa()
	await _test_kamera_ileri()
	await _test_ucus_suresi()
	await _test_halat_kisiti()
	await _test_momentum()
	await _test_kirilgan()
	await _test_hareketli()
	await _test_ruzgar()
	await _test_bolum_sahneleri()
	await _test_kontrol_noktasi()
	_test_karo_hizasi()
	_test_yerlesim()
	_test_madalya()
	_test_hayalet_kaydi()
	_test_akis_kaydi()
	_test_tus_atama()
	_test_rota_verisi()
	_test_madalya_ms()
	_test_gecilebilirlik()
	print("=== %d/%d gecti ===" % [_toplam - _kalan, _toplam])
	get_tree().quit(_kalan)

func _bildir(ad: String, tamam: bool, not_metni: String = "") -> void:
	_toplam += 1
	if tamam:
		print("  GECTI  %s" % ad)
	else:
		_kalan += 1
		printerr("  KALDI  %s  %s" % [ad, not_metni])

func _oyuncu_yap(yer: Vector2) -> Oyuncu:
	var o: Oyuncu = OYUNCU_SAHNE.instantiate()
	o.girdi_aktif = false
	add_child(o)
	o.global_position = yer
	return o

func _nokta_yap(yer: Vector2, tur: int = KancaNoktasi.TUR_SABIT) -> KancaNoktasi:
	var n := KancaNoktasi.yap(yer, tur)
	add_child(n)
	n.global_position = yer
	return n

## Gorus hattini kesen kati blok.
func _duvar_yap(r: Rect2) -> StaticBody2D:
	var g := StaticBody2D.new()
	var sekil := RectangleShape2D.new()
	sekil.size = r.size
	var cs := CollisionShape2D.new()
	cs.shape = sekil
	cs.position = r.position + r.size * 0.5
	g.add_child(cs)
	add_child(g)
	return g

# --- 1b. Hedefleme puanlamasi -----------------------------------------

## Puan = hiza*3 - uzaklik/menzil + hiz yonu uyumu. Hizali uzak nokta,
## hizasiz yakin noktayi yenmeli; esit hizada yakin olan kazanmali.
func _test_hedefleme_puani() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var hizali := _nokta_yap(Vector2(0.0, -200.0))
	var egik := _nokta_yap(Vector2(40.0, -40.0))
	await get_tree().physics_frame
	var secim := o.en_iyi_nokta(Vector2.UP)
	_bildir("hizali uzak nokta, hizasiz yakin noktayi yener", secim == hizali,
		"secim=%s" % (str(secim.global_position) if secim != null else "yok"))

	egik.queue_free()
	var daha_yakin := _nokta_yap(Vector2(0.0, -90.0))
	await get_tree().physics_frame
	var secim2 := o.en_iyi_nokta(Vector2.UP)
	_bildir("esit hizada yakin olan kazanir", secim2 == daha_yakin,
		"secim=%s" % (str(secim2.global_position) if secim2 != null else "yok"))

	o.queue_free()
	hizali.queue_free()
	daha_yakin.queue_free()
	await get_tree().physics_frame

# --- 1c. Gorus hatti --------------------------------------------------

## Arada kati zemin varsa kanca takilmamali (duvarin arkasina tutunma).
func _test_gorus_hatti() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var n := _nokta_yap(Vector2(0.0, -150.0))
	var duvar := _duvar_yap(Rect2(-40.0, -90.0, 80.0, 16.0))
	await get_tree().physics_frame
	await get_tree().physics_frame
	var engelli := o.kanca_at_hemen(Vector2.UP)
	o.kanca_birak()

	duvar.queue_free()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var acik := o.kanca_at_hemen(Vector2.UP)

	_bildir("arada duvar varsa kanca takilmaz", not engelli, "takildi")
	_bildir("duvar kalkinca ayni noktaya takilir", acik, "takilmadi")

	o.queue_free()
	n.queue_free()
	await get_tree().physics_frame

# --- 1d. Hiz yonu uyumu -----------------------------------------------

## Nisana esit uzaklikta iki nokta varsa, hiz yonundeki secilmeli.
func _test_hiz_yonu() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var sol := _nokta_yap(Vector2(-100.0, -130.0))
	var sag := _nokta_yap(Vector2(100.0, -130.0))
	await get_tree().physics_frame

	o.velocity = Vector2(500.0, 0.0)
	var saga := o.en_iyi_nokta(Vector2.UP)
	o.velocity = Vector2(-500.0, 0.0)
	var sola := o.en_iyi_nokta(Vector2.UP)

	_bildir("hiz yonundeki nokta seciliyor (saga giderken sag)", saga == sag,
		"secim=%s" % (str(saga.global_position) if saga != null else "yok"))
	_bildir("hiz yonundeki nokta seciliyor (sola giderken sol)", sola == sol,
		"secim=%s" % (str(sola.global_position) if sola != null else "yok"))

	o.queue_free()
	sol.queue_free()
	sag.queue_free()
	await get_tree().physics_frame

# --- 1e. Kanca tamponu ------------------------------------------------

## Basis saklanir: tampon suresi icinde hedef belirirse kanca takilir.
func _test_kanca_tamponu() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	await get_tree().physics_frame
	o.kanca_tamponla(Vector2.UP)
	await get_tree().physics_frame
	var n := _nokta_yap(o.global_position + Vector2(0.0, -120.0))
	for i in 4:
		await get_tree().physics_frame
	var tamponla_takildi: bool = o.kancali() or o.uculuyor()
	o.kanca_birak()
	n.queue_free()
	await get_tree().physics_frame

	# Tampon suresi gectikten sonra beliren hedef takilmamali.
	o.velocity = Vector2.ZERO
	o.kanca_tamponla(Vector2.UP)
	for i in int(Ayarlar.KANCA_TAMPON_SURESI * 60.0) + 4:
		await get_tree().physics_frame
	var gec := _nokta_yap(o.global_position + Vector2(0.0, -120.0))
	for i in 4:
		await get_tree().physics_frame
	var gec_takildi: bool = o.kancali() or o.uculuyor()

	_bildir("basis tamponlanir: %.2f sn icinde beliren hedefe takilir"
		% Ayarlar.KANCA_TAMPON_SURESI, tamponla_takildi, "takilmadi")
	_bildir("tampon suresi gecince eski basis kanca atmaz", not gec_takildi, "takildi")

	o.queue_free()
	gec.queue_free()
	await get_tree().physics_frame

# --- 1f. Kojot-kanca --------------------------------------------------

## Hedef menzilden az once cikmissa kisa bir sure daha tutulabilir.
func _test_kojot_kanca() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var n := _nokta_yap(Vector2(0.0, -(Ayarlar.KANCA_MENZIL - 20.0)))
	await get_tree().physics_frame

	o.aday_guncelle(Vector2.UP)
	# Menzilin biraz disina cik (kojot payi icinde).
	o.global_position = Vector2(0.0, 60.0)
	var kojotla := o.kanca_at_hemen(Vector2.UP)
	o.kanca_birak()

	# Kojot penceresi gecsin.
	o.set_physics_process(true)
	for i in int(Ayarlar.KANCA_KOJOT_SURESI * 60.0) + 6:
		await get_tree().physics_frame
	o.set_physics_process(false)
	o.global_position = Vector2(0.0, 60.0)
	var sonra := o.kanca_at_hemen(Vector2.UP)

	_bildir("kojot-kanca: menzilden yeni cikan hedefe hala takilir", kojotla, "takilmadi")
	_bildir("kojot suresi bitince takilmaz", not sonra, "takildi")

	o.queue_free()
	n.queue_free()
	await get_tree().physics_frame

# --- 1g. Birakma bonusu -----------------------------------------------

## Esik ustu hizda birakmak BIRAKMA_CARPANI kadar odullendirilir, altinda degil.
func _test_birakma_bonusu() -> void:
	var capa := _nokta_yap(Vector2(0.0, -150.0))
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	await get_tree().physics_frame

	o.kanca_at_hemen(Vector2.UP)
	var hizli_once := Vector2(Ayarlar.BIRAKMA_ESIGI + 80.0, 0.0)
	o.velocity = hizli_once
	o.kanca_birak()
	var hizli_sonra := o.velocity.length()

	o.kanca_at_hemen(Vector2.UP)
	var yavas_once := Vector2(Ayarlar.BIRAKMA_ESIGI - 120.0, 0.0)
	o.velocity = yavas_once
	o.kanca_birak()
	var yavas_sonra := o.velocity.length()

	_bildir("esik ustu birakmada hiz bonusu var",
		absf(hizli_sonra - hizli_once.length() * Ayarlar.BIRAKMA_CARPANI) < 1.0,
		"%.1f -> %.1f (beklenen %.1f)" % [hizli_once.length(), hizli_sonra,
			hizli_once.length() * Ayarlar.BIRAKMA_CARPANI])
	_bildir("esik alti birakmada hiza dokunulmaz",
		absf(yavas_sonra - yavas_once.length()) < 1.0,
		"%.1f -> %.1f" % [yavas_once.length(), yavas_sonra])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 1h. Pompa (halat kisaltma) ---------------------------------------

## Gergin halati kisaltmak aci momentumunu korur: tegetsel hiz artar.
func _test_pompa() -> void:
	var hizlar: Array[float] = []
	for pompa in [false, true]:
		var capa := _nokta_yap(Vector2(0.0, -140.0))
		var o := _oyuncu_yap(Vector2.ZERO)
		await get_tree().physics_frame
		o.kanca_at_hemen(Vector2.UP)
		o.velocity = Vector2(300.0, 0.0)
		for i in 30:
			if pompa:
				o.halat_degistir(-2.0)
			await get_tree().physics_frame
		hizlar.append(o.velocity.length())
		o.queue_free()
		capa.queue_free()
		await get_tree().physics_frame

	_bildir("halati kisaltmak sallanmayi hizlandirir (pompa)",
		hizlar[1] > hizlar[0] * 1.15,
		"pompasiz=%.1f pompali=%.1f" % [hizlar[0], hizlar[1]])

# --- 1i. Ileri bakan kamera -------------------------------------------

func _test_kamera_ileri() -> void:
	var o := _oyuncu_yap(Vector2(0.0, -400.0))
	await get_tree().physics_frame
	var duruyor := absf(o.kamera_ileri.x)
	for i in 40:
		o.velocity.x = 600.0
		await get_tree().physics_frame

	_bildir("kamera hiz yonune bakiyor", o.kamera_ileri.x > 50.0 and duruyor < 5.0,
		"duruyor=%.1f hizli=%.1f" % [duruyor, o.kamera_ileri.x])
	_bildir("yuksek hizda goruntu hafif uzaklasiyor",
		o.kamera_yakinlik < 0.99 and o.kamera_yakinlik > 1.0 - Ayarlar.KAMERA_UZAKLASMA - 0.01,
		"yakinlik=%.3f" % o.kamera_yakinlik)
	o.queue_free()
	await get_tree().physics_frame

# --- 1. Menzil --------------------------------------------------------

func _test_menzil() -> void:
	var o := _oyuncu_yap(Vector2.ZERO)
	o.set_physics_process(false)
	var uzak := _nokta_yap(Vector2(0.0, -(Ayarlar.KANCA_MENZIL + 60.0)))
	await get_tree().physics_frame

	_bildir("menzil disindaki noktaya kanca takilmaz",
		not o.kanca_at_hemen(Vector2.UP),
		"uzaklik=%.1f menzil=%.1f" % [Ayarlar.KANCA_MENZIL + 60.0, Ayarlar.KANCA_MENZIL])

	var yakin := _nokta_yap(Vector2(0.0, -(Ayarlar.KANCA_MENZIL - 40.0)))
	await get_tree().physics_frame
	var takildi := o.kanca_at_hemen(Vector2.UP)
	_bildir("menzil icindeki noktaya kanca takilir", takildi and o.kanca_nokta == yakin,
		"kanca_nokta=%s" % str(o.kanca_nokta))

	o.queue_free()
	uzak.queue_free()
	yakin.queue_free()
	await get_tree().physics_frame

# --- 2. Ucus suresi ---------------------------------------------------

## Kanca aninda takilmaz: once halat ucar. Cok kisa ama gercek bir gecikme.
func _test_ucus_suresi() -> void:
	var capa := _nokta_yap(Vector2(0.0, -150.0))
	var o := _oyuncu_yap(Vector2.ZERO)
	await get_tree().physics_frame

	var basladi := o.kanca_at(Vector2.UP)
	var hemen_takildi := o.kancali()
	var ucuyor := o.uculuyor()

	var kare := 0
	while kare < 30 and not o.kancali():
		await get_tree().physics_frame
		kare += 1
	var beklenen := int(ceil(Ayarlar.KANCA_UCUS_SURESI * 60.0))

	_bildir("kanca atilinca once halat ucar (ayni karede takilmaz)",
		basladi and ucuyor and not hemen_takildi, "kancali=%s" % str(hemen_takildi))
	_bildir("halat ~%d kare sonra tutunur" % beklenen,
		o.kancali() and absi(kare - beklenen) <= 2,
		"kare=%d beklenen=%d" % [kare, beklenen])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 3. Halat kisiti --------------------------------------------------

func _test_halat_kisiti() -> void:
	var capa := _nokta_yap(Vector2(0.0, -300.0))
	var o := _oyuncu_yap(Vector2(0.0, -150.0))
	await get_tree().physics_frame

	var takildi := o.kanca_at_hemen(Vector2.UP)
	var boy := o.halat_boyu
	o.velocity = Vector2(520.0, 0.0)   # sert bir savurma

	var en_kotu := 0.0
	for i in KARE_SAYISI:
		await get_tree().physics_frame
		if not o.kancali():
			break
		var sapma: float = o.global_position.distance_to(capa.global_position) - o.halat_boyu
		en_kotu = maxf(en_kotu, sapma)

	_bildir("takiliyken mesafe halat boyunu asmaz (%d kare)" % KARE_SAYISI,
		takildi and o.kancali() and en_kotu <= HALAT_TOLERANS,
		"halat=%.1f en_buyuk_sapma=%.3f" % [boy, en_kotu])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 4. Momentum ------------------------------------------------------

func _test_momentum() -> void:
	var capa := _nokta_yap(Vector2(0.0, -300.0))
	var o := _oyuncu_yap(Vector2(0.0, -150.0))
	await get_tree().physics_frame
	o.kanca_at_hemen(Vector2.UP)
	o.velocity = Vector2(420.0, 0.0)

	# Sarkacin en hizlandigi ana kadar salla.
	var once := Vector2.ZERO
	for i in 40:
		await get_tree().physics_frame
		if absf(o.velocity.x) > absf(once.x):
			once = o.velocity
	var birakmadan_once := o.velocity
	o.kanca_birak()
	var sonra := o.velocity

	_bildir("birakinca yatay hiz sifirlanmaz",
		absf(sonra.x) >= absf(birakmadan_once.x) * 0.95 and signf(sonra.x) == signf(birakmadan_once.x),
		"once=%.1f sonra=%.1f" % [birakmadan_once.x, sonra.x])

	for i in 30:
		await get_tree().physics_frame
	_bildir("birakildiktan sonra yatay hiz korunur",
		absf(o.velocity.x) >= absf(sonra.x) * 0.9,
		"birakinca=%.1f 30 kare sonra=%.1f" % [sonra.x, o.velocity.x])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 5. Kirilgan nokta ------------------------------------------------

func _test_kirilgan() -> void:
	var capa := _nokta_yap(Vector2(0.0, -120.0), KancaNoktasi.TUR_KIRILGAN)
	var o := _oyuncu_yap(Vector2.ZERO)
	await get_tree().physics_frame

	var ilk := o.kanca_at_hemen(Vector2.UP)
	o.kanca_birak()
	# Uyari suresi kadar bekle, sonra kirilmis olmali.
	var bekle := int(Ayarlar.KIRILGAN_UYARI * 60.0) + 6
	for i in bekle:
		await get_tree().physics_frame

	var ikinci := o.kanca_at_hemen(Vector2.UP)
	_bildir("kirilgan nokta bir kez tutulur, sonra kullanilamaz",
		ilk and not ikinci and not capa.kullanilabilir(),
		"ilk=%s ikinci=%s" % [str(ilk), str(ikinci)])

	o.queue_free()
	capa.queue_free()
	await get_tree().physics_frame

# --- 6. Hareketli nokta -----------------------------------------------

func _test_hareketli() -> void:
	var n := _nokta_yap(Vector2(0.0, -120.0), KancaNoktasi.TUR_HAREKETLI)
	n.a = Vector2(-80.0, -120.0)
	n.b = Vector2(80.0, -120.0)
	await get_tree().physics_frame
	var bas := n.global_position
	var en_sol := bas.x
	var en_sag := bas.x
	# Nokta artik fizik karesinde hareket ediyor (sabit 60 Hz); yine de guvenli
	# bir ust sinirla tam tur tamamlanana kadar don.
	var kare := 0
	while kare < 20000:
		await get_tree().physics_frame
		kare += 1
		en_sol = minf(en_sol, n.global_position.x)
		en_sag = maxf(en_sag, n.global_position.x)
		if en_sol <= -79.0 and en_sag >= 79.0:
			break

	_bildir("hareketli nokta iki uc arasinda gidip gelir (tasmadan)",
		en_sol <= -79.0 and en_sag >= 79.0 and en_sol >= -80.5 and en_sag <= 80.5,
		"en_sol=%.1f en_sag=%.1f kare=%d" % [en_sol, en_sag, kare])
	n.queue_free()
	await get_tree().physics_frame

# --- 7. Ruzgar --------------------------------------------------------

## Itici alan icinde oyuncu ruzgar yonunde hizlanmali.
func _test_ruzgar() -> void:
	var o := _oyuncu_yap(Vector2(0.0, -400.0))
	await get_tree().physics_frame
	o.velocity = Vector2.ZERO
	o.ruzgar = Vector2.UP
	var basta := o.global_position.y
	for i in 30:
		await get_tree().physics_frame
	var ruzgarli := o.velocity.y

	o.ruzgar = Vector2.ZERO
	o.velocity = Vector2.ZERO
	o.global_position = Vector2(0.0, -400.0)
	for i in 30:
		await get_tree().physics_frame
	var ruzgarsiz := o.velocity.y

	_bildir("ruzgar alani oyuncuyu yonune iter",
		ruzgarli < ruzgarsiz - 100.0,
		"ruzgarli_vy=%.1f ruzgarsiz_vy=%.1f (basta y=%.1f)" % [ruzgarli, ruzgarsiz, basta])
	o.queue_free()
	await get_tree().physics_frame

# --- 8. Bolum sahneleri -----------------------------------------------

func _test_bolum_sahneleri() -> void:
	_bildir("14 bolum tanimli", Bolumler.sayi() == 14, "sayi=%d" % Bolumler.sayi())
	for no in range(1, Bolumler.sayi() + 1):
		var yol := Bolumler.yol(no)
		if not ResourceLoader.exists(yol):
			_bildir("bolum %d sahnesi var" % no, false, yol)
			continue
		var sahne: PackedScene = load(yol)
		var bolum: Bolum = sahne.instantiate()
		add_child(bolum)
		for i in 3:
			await get_tree().physics_frame

		var veri := Bolumler.veri(no)
		var noktalar := 0
		for n in get_tree().get_nodes_in_group(KancaNoktasi.GRUP):
			if bolum.is_ancestor_of(n):
				noktalar += 1
		var oyuncu: Node = bolum.find_child("Oyuncu", true, false)
		var bitis: Node = bolum.find_child("Bitis", true, false)
		var zemin: TileMapLayer = bolum.find_child("Zemin", true, false)
		var karo := 0
		if zemin != null:
			karo = zemin.get_used_cells().size()

		var tamam: bool = (bolum.bolum_no == no
			and oyuncu != null
			and bitis != null
			and zemin != null
			and karo > 0
			and noktalar >= 3
			and noktalar == Bolumler.tum_kanca(no).size()
			and veri["basla"] != veri["bitis"])
		_bildir("bolum %d: baslangic + bitis + %d kanca + %d karo" % [no, noktalar, karo], tamam,
			"oyuncu=%s bitis=%s zemin=%s karo=%d nokta=%d/%d" % [
				str(oyuncu != null), str(bitis != null), str(zemin != null), karo,
				noktalar, Bolumler.tum_kanca(no).size()])

		bolum.free()
		await get_tree().physics_frame

# --- 8b. Kontrol noktasi ----------------------------------------------

## Kontrol noktasina degip olunce oradan devam edilmeli ve sure SIFIRLANMAMALI
## (hiz oyunu: olmek yine de zaman kaybi).
func _test_kontrol_noktasi() -> void:
	const BOLUM := 11
	var kn: Vector2 = Bolumler.veri(BOLUM)["kontrol"][0]
	var bolum: Bolum = load(Bolumler.yol(BOLUM)).instantiate()
	add_child(bolum)
	for i in 8:
		await get_tree().physics_frame
	var oyuncu: Oyuncu = bolum.find_child("Oyuncu", true, false)
	oyuncu.girdi_aktif = false
	oyuncu.global_position = kn
	oyuncu.velocity = Vector2.ZERO
	for i in 10:
		await get_tree().physics_frame
	var alindi: bool = (bolum.get("_dogus") as Vector2).distance_to(kn) < 1.0
	var sure_once: float = bolum.get("_sure")

	# Cukura dus.
	oyuncu.global_position = Vector2(kn.x, Ayarlar.OLUM_Y + 60.0)
	for i in 20:
		await get_tree().physics_frame
	var dogdu := oyuncu.global_position.distance_to(kn) < 60.0
	var sure_sonra: float = bolum.get("_sure")

	_bildir("kontrol noktasi aliniyor", alindi, "dogus=%s kn=%s" % [str(bolum.get("_dogus")), str(kn)])
	_bildir("olunce kontrol noktasindan doguyor, sure sifirlanmiyor",
		dogdu and sure_sonra >= sure_once,
		"uzaklik=%.1f sure %.2f -> %.2f" % [oyuncu.global_position.distance_to(kn), sure_once, sure_sonra])

	bolum.free()
	await get_tree().physics_frame

# --- 9. Karo hizasi ---------------------------------------------------

## TileMapLayer'a dosenen dunya ile veri tablosu ayni yerde olmali.
func _test_karo_hizasi() -> void:
	var bozuk := ""
	for no in range(1, Bolumler.sayi() + 1):
		for r: Rect2 in Bolumler.zeminler(no):
			if fmod(r.position.x, KaroSeti.BOY) != 0.0 or fmod(r.position.y, KaroSeti.BOY) != 0.0 \
					or fmod(r.size.x, KaroSeti.BOY) != 0.0 or fmod(r.size.y, KaroSeti.BOY) != 0.0:
				bozuk += " b%d:%s" % [no, str(r)]
	_bildir("tum zeminler %d px karo izgarasinda" % KaroSeti.BOY, bozuk == "", bozuk)

# --- 9b. Yerlesim -----------------------------------------------------

## Baslangic, bitis ve kontrol noktalari bir platformun UZERINDE olmali.
## Elle yazilmis tabloda bir sayiyi kaydirmak bitisi bosluga dusurebilir;
## gecilebilirlik testi bunu yakalamaz (o sadece bosluklara bakiyor).
func _test_yerlesim() -> void:
	var bozuk := ""
	for no in range(1, Bolumler.sayi() + 1):
		var d := Bolumler.veri(no)
		var zeminler := Bolumler.zeminler(no)
		var noktalar: Array[Vector2] = [Vector2(d["basla"]), Vector2(d["bitis"])]
		for k: Vector2 in d["kontrol"]:
			noktalar.append(k)
		for p: Vector2 in noktalar:
			var oturuyor := false
			for r: Rect2 in zeminler:
				if p.x >= r.position.x and p.x <= r.end.x \
						and p.y < r.position.y and r.position.y - p.y <= 120.0:
					oturuyor = true
					break
			if not oturuyor:
				bozuk += " b%d:%s" % [no, str(p)]
	_bildir("baslangic/bitis/kontrol noktalari bir platformun uzerinde", bozuk == "", bozuk)

# --- 10. Madalya ------------------------------------------------------

func _test_madalya() -> void:
	var bozuk := ""
	for no in range(1, Bolumler.sayi() + 1):
		var m: Array = Bolumler.veri(no)["madalya"]
		if not (float(m[0]) < float(m[1]) and float(m[1]) < float(m[2])):
			bozuk += " b%d:%s" % [no, str(m)]
		elif Bolumler.madalya(no, float(m[0]) - 0.01) != 0 \
				or Bolumler.madalya(no, float(m[1]) - 0.01) != 1 \
				or Bolumler.madalya(no, float(m[2]) - 0.01) != 2 \
				or Bolumler.madalya(no, float(m[2]) + 1.0) != 3:
			bozuk += " b%d:esik" % no
	_bildir("madalya esikleri artan ve dogru siniflandiriyor", bozuk == "", bozuk)

# --- 11. Hayalet kaydi ------------------------------------------------

func _test_hayalet_kaydi() -> void:
	var ornek := PackedVector2Array([Vector2(1, 2), Vector2(3, 4), Vector2(5, 6)])
	Kayit.hayalet_yaz(99, ornek)
	var geri := Kayit.hayalet_oku(99)
	_bildir("hayalet kaydi yazilip geri okunuyor", geri == ornek,
		"yazilan=%d okunan=%d" % [ornek.size(), geri.size()])
	DirAccess.remove_absolute(Kayit.HAYALET_YOL % 99)

# --- 11b. Akis (ustalik zinciri) kaydi --------------------------------

func _test_akis_kaydi() -> void:
	Kayit.akis_yaz(98, 1)
	var arttirdi := Kayit.akis_yaz(98, 4)
	var dusurmedi := not Kayit.akis_yaz(98, 3)
	_bildir("akis kaydi yalniz rekor olunca guncelleniyor",
		arttirdi and dusurmedi and Kayit.akis(98) == 4, "akis=%d" % Kayit.akis(98))

# --- 11c. Tus atama ---------------------------------------------------

func _test_tus_atama() -> void:
	var eski := Kayit.tuslar()
	Kayit.tus_yaz("zipla", KEY_K)
	var yazildi := false
	for olay: InputEvent in InputMap.action_get_events("zipla"):
		if olay is InputEventKey and (olay as InputEventKey).physical_keycode == KEY_K:
			yazildi = true
	# Fare/gamepad atamalari ozel tustan etkilenmemeli.
	var kanca_fare := false
	for olay: InputEvent in InputMap.action_get_events("kanca_at"):
		if olay is InputEventMouseButton:
			kanca_fare = true
	Kayit.tuslari_sifirla()
	var sifirlandi: bool = Kayit.tuslar().is_empty() and Tuslar.tus_adi("zipla") != "K"
	for eylem: String in eski:
		Kayit.tus_yaz(eylem, int(eski[eylem]))

	_bildir("ozel tus atamasi InputMap'e yaziliyor", yazildi, "zipla=K yazilamadi")
	_bildir("ozel tus fare atamasini silmiyor", kanca_fare, "kanca_at fare atamasi kayboldu")
	_bildir("varsayilana donunce ozel atama kalmiyor", sifirlandi,
		"zipla=%s" % Tuslar.tus_adi("zipla"))

# --- 11d. Uretilmis rota verisi ---------------------------------------

## tools/rota.gd her bolum icin bot kosusu + rota uretiyor. Rotanin her adimi
## gercek bir kanca noktasi olmali, ardisik noktalar zincir menzilinde ve
## aralarinda kati zemin olmadan gorunur olmali.
func _test_rota_verisi() -> void:
	var zincir: float = Ayarlar.KANCA_MENZIL + Ayarlar.KANCA_AZAMI_HALAT * 0.7
	var bozuk := ""
	for no in range(1, Bolumler.sayi() + 1):
		var rota := RotaVerisi.nokta(no)
		if rota.is_empty():
			bozuk += " b%d:rota yok;" % no
			continue
		var kanca := Bolumler.tum_kanca(no)
		var zeminler := Bolumler.zeminler(no)
		for i in rota.size():
			var p: Vector2 = rota[i]
			var var_mi := false
			for k: Vector2 in kanca:
				if k.distance_to(p) < 1.5:
					var_mi = true
					break
			if not var_mi:
				bozuk += " b%d:%s kanca noktasi degil;" % [no, str(p)]
			if i > 0:
				var onceki: Vector2 = rota[i - 1]
				if onceki.distance_to(p) > zincir:
					bozuk += " b%d:%s-%s cok uzak;" % [no, str(onceki), str(p)]
				elif not Bolumler.gorus_var(onceki, p, zeminler):
					bozuk += " b%d:%s-%s arasi kapali;" % [no, str(onceki), str(p)]
		if RotaVerisi.sure(no) <= 0.0:
			bozuk += " b%d:bot suresi yok;" % no
	_bildir("uretilmis rota verisi tutarli (%d bolum)" % Bolumler.sayi(), bozuk == "", bozuk)

## Madalya esikleri bot kosusundan uretildigi icin ms hassasiyetinde olmali.
func _test_madalya_ms() -> void:
	var bozuk := ""
	for no in range(1, Bolumler.sayi() + 1):
		var m := RotaVerisi.madalya(no)
		if m.size() != 3:
			bozuk += " b%d:esik uretilmemis;" % no
			continue
		var ms_var := false
		for d: float in m:
			if absf(d - roundf(d * 10.0) / 10.0) > 0.0001:
				ms_var = true
		if not ms_var:
			bozuk += " b%d:ms hassasiyeti yok (%s);" % [no, str(m)]
	_bildir("madalya esikleri ms hassasiyetinde", bozuk == "", bozuk)

# --- 12. Gecilebilirlik -----------------------------------------------

## Her bosluk kanca zinciriyle asilabiliyor mu? Ledge'den menzil icindeki
## noktalara tutunulur, oradan zincirle ilerlenir, son nokta karsi kenara
## inecek kadar yakin olmali. Bolum verisi bozulursa bu test yakalar.
## Hareketli noktalar orta konumlariyla sayilir (Bolumler.tum_kanca).
## Ayarlar.KANCA_MENZIL calisma aninda ayarlanabilir (var), o yuzden const degil.
const INIS_MESAFESI := 300.0
const ZIPLA_YUKSEKLIGI := 45.0
const OYUNCU_YARI_BOY := 14.0

func _test_gecilebilirlik() -> void:
	var zincir_menzili: float = Ayarlar.KANCA_MENZIL + Ayarlar.KANCA_AZAMI_HALAT * 0.7
	for no in range(1, Bolumler.sayi() + 1):
		var kanca := Bolumler.tum_kanca(no)
		var zeminler: Array[Rect2] = []
		for r: Rect2 in Bolumler.zeminler(no):
			if r.position.y >= 150.0:   # tavan bloklarini ele
				zeminler.append(r)
		zeminler.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)

		var kotu := ""
		for i in range(zeminler.size() - 1):
			var sol_r: Rect2 = zeminler[i]
			var sag_r: Rect2 = zeminler[i + 1]
			var gx0 := sol_r.end.x
			var gx1 := sag_r.position.x
			if gx1 <= gx0 + 1.0:
				continue
			var sol := Vector2(gx0, sol_r.position.y - OYUNCU_YARI_BOY - ZIPLA_YUKSEKLIGI)
			var sag := Vector2(gx1, sag_r.position.y - OYUNCU_YARI_BOY)

			var goruldu: Array[Vector2] = []
			var kuyruk: Array[Vector2] = []
			for k: Vector2 in kanca:
				if k.distance_to(sol) <= Ayarlar.KANCA_MENZIL:
					goruldu.append(k)
					kuyruk.append(k)
			while not kuyruk.is_empty():
				var k: Vector2 = kuyruk.pop_back()
				for m: Vector2 in kanca:
					if not goruldu.has(m) and k.distance_to(m) <= zincir_menzili:
						goruldu.append(m)
						kuyruk.append(m)

			var indi := false
			for k: Vector2 in goruldu:
				if k.distance_to(sag) <= INIS_MESAFESI:
					indi = true
					break
			if not indi:
				kotu += " bosluk %d-%d;" % [int(gx0), int(gx1)]

		_bildir("bolum %d: tum bosluklar kanca zinciriyle asilabilir" % no, kotu == "", kotu)
