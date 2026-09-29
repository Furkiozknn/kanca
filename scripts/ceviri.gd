class_name Ceviri
extends RefCounted
## Arayuz metinleri: KAYNAK dil Turkce (tr() anahtari Turkce metnin kendisi),
## Ingilizce tablo asagida. Turkce icin ceviri tablosu gerekmez: anahtar
## bulunamazsa Godot metni aynen doner (proje ayari: yedek dil "tr").
##
## Yeni bir arayuz metni eklerken:
##   1. Kodda tr("Turkce metin") (ornek metotlarda) ya da Ceviri.t("...") (static
##      metotlarda, tr() yok) yaz;
##   2. Asagidaki EN tablosuna ayni anahtarla Ingilizcesini ekle
##      (bicim belirteclerinin sayisi ve sirasi ayni kalsin: %d, %s, %.2f);
##   3. tests/test_kanca.gd -> _test_ceviri eksik anahtari ve belirtec
##      uyusmazligini yakalar.
##
## Ingilizce metinler dogal ve kisa ("Hold left click: hook"), dizgi dizgi
## ceviri degil: videolar X ve YouTube'da Ingilizce yayinlaniyor.

const EN := {
	# --- menu ---
	"Oyna": "Play",
	"Bölüm Seç": "Select level",
	"Günün Bölümü": "Daily level",
	"Çıkış": "Quit",
	"Ayarlar": "Settings",
	"HIZ · %d BÖLÜM": "SPEED · %d LEVELS",
	"SIRADAKİ: %s": "NEXT: %s",
	"Fare: nişan · Sol tık basılı: kanca · A/D: salın · W/S: halat · Boşluk: zıpla": "Mouse: aim · Hold left click: hook · A/D: swing · W/S: rope · Space: jump",
	"Dokun: nişan al ve kanca tak · Parmağı kaldır: bırak · Basılıyken kaydır: halat": "Tap: aim and hook · Lift finger: release · Drag while held: rope",
	"AÇIK BÖLÜM %d / %d · MADALYA %d · ALTIN %d": "LEVELS OPEN %d / %d · MEDALS %d · GOLD %d",
	"GÜNÜN BÖLÜMÜ: %s · EN İYİ %s": "DAILY LEVEL: %s · BEST %s",
	"Cihazını yatay çevir": "Rotate your device to landscape",
	# --- bolum secimi ---
	"BÖLÜM SEÇ": "SELECT LEVEL",
	"Madalya: altın / gümüş / bronz süreler bölüm içinde yazılı · AKIŞ ×N: yere değmeden en uzun kanca zinciri": "Medals: gold / silver / bronze target times are shown in each level · CHAIN ×N: longest hook chain without touching the ground",
	"Kayıtları sıfırla": "Reset progress",
	"Emin misin? Tekrar dokun": "Sure? Tap again",
	# --- ayarlar ---
	"AYARLAR": "SETTINGS",
	"SES VE GÖRÜNTÜ": "SOUND AND DISPLAY",
	"OYNANIŞ": "GAMEPLAY",
	"Müzik": "Music",
	"Efekt": "Effects",
	"Dil": "Language",
	"Tam ekran": "Fullscreen",
	"Nişan": "Aim",
	"yardım": "assist",
	"tam nişan": "precise",
	"orta": "medium",
	"Hayalet": "Ghost",
	"Kapalı": "Off",
	"En iyi koşun": "Your best run",
	"Altın hayalet (bot)": "Gold ghost (bot)",
	"Ekran sarsıntısı": "Screen shake",
	"Rota ipucu (altından sonra)": "Route hint (after gold)",
	"Tek parmak şeması (dokunmatik)": "One-finger controls (touch)",
	"Geri": "Back",
	"Tuş atama": "Key bindings",
	"TUŞ ATAMA": "KEY BINDINGS",
	"Tuşa bas: değiştir · Esc: vazgeç": "Press a key to change · Esc to cancel",
	"Varsayılana dön": "Reset to default",
	"bir tuşa bas…": "press a key…",
	"Fare %d": "Mouse %d",
	"Boşluk": "Space",
	# --- tus adlari (Tuslar.EYLEMLER) ---
	"Sol / geri sallan": "Left / swing back",
	"Sağ / ileri sallan": "Right / swing forward",
	"Zıpla": "Jump",
	"Kanca at": "Throw hook",
	"Halatı kısalt": "Shorten rope",
	"Halatı uzat": "Lengthen rope",
	"Bölümü yeniden başlat": "Restart level",
	"Duraklat": "Pause",
	# --- oyun ici ---
	"R: yeniden   Esc: duraklat": "R: restart   Esc: pause",
	"Baştan başla": "Restart",
	"ALTIN %s": "GOLD %s",
	"EN İYİ %s": "BEST %s",
	"AKIŞ ×%d": "CHAIN ×%d",
	"  · YENİ EN UZUN ZİNCİR": "  · NEW LONGEST CHAIN",
	"GÜNLÜK": "DAILY",
	"DURAKLATILDI": "PAUSED",
	"Devam": "Resume",
	"Bölümü baştan": "Restart level",
	"Menüye dön": "Back to menu",
	"YENİ REKOR": "NEW RECORD",
	"Tekrar dene": "Try again",
	"Sonraki bölüm": "Next level",
	"GÜNLÜK MEYDAN OKUMA": "DAILY CHALLENGE",
	"BUGÜNÜN EN İYİSİ %s": "TODAY'S BEST %s",
	"ALTIN %s · GÜMÜŞ %s · BRONZ %s": "GOLD %s · SILVER %s · BRONZE %s",
	# --- madalyalar ---
	"Altın": "Gold",
	"Gümüş": "Silver",
	"Bronz": "Bronze",
	# --- gunluk degistiriciler ---
	"Kısa halat": "Short rope",
	"Yan rüzgâr": "Side wind",
	# --- bolum adlari ---
	"İlk Tutuş": "First Grip",
	"Halat Boyu": "Rope Length",
	"Diken Tarlası": "Spike Field",
	"Uçurum": "The Gap",
	"Yukarı": "Upward",
	"Sallanan Kayalar": "Swinging Rocks",
	"Dar Geçit": "Narrow Pass",
	"Tek Kullanımlık": "One Use Only",
	"Rüzgâr": "Wind",
	"Dikenli Tavan": "Spiked Ceiling",
	"Hız": "Speed",
	"Kırık Sarkaç": "Broken Pendulum",
	"Fırtına": "Storm",
	"Final": "Finale",
	# --- bolum ipuclari ---
	"Fare ile nişan al, SOL TIK basılı tut: kanca takılır. Bırakınca kopar.": "Aim with the mouse, hold LEFT CLICK: the hook grabs. Let go to release.",
	"Parmağını basılı tut: nişan alır ve kanca takılır. Kaldırınca kopar.": "Hold your finger down: it aims and hooks. Lift to release.",
	"W/S halatı kısaltır-uzatır. Kısa halat daha hızlı döndürür.": "W/S shortens or lengthens the rope. A short rope swings faster.",
	"Basılıyken yukarı/aşağı kaydır: halatı kısaltır-uzatır. Kısa halat daha hızlı döndürür.": "While held, drag up or down to shorten or lengthen the rope. A short rope swings faster.",
	"Kırmızı dikene değme. Sallanarak üstünden geç.": "Don't touch the red spikes. Swing over them.",
	"Turuncu halkalı noktalar yerinde durmaz. Zamanlamayı yakala.": "Points with an orange ring keep moving. Catch the timing.",
	"Tavan alçaldığında halatı kısalt.": "Shorten the rope when the ceiling drops.",
	"Kesik halkalar bir kez tutulur; bıraktığın an kırılır. Duraklama.": "Dashed rings hold once and break the moment you let go. Don't stall.",
	"Akan çizgiler seni taşır. Halatı bırakıp akıntıya gir.": "The streaks carry you. Let go of the rope and ride the current.",
	"Tavandaki dikenler de öldürür. Halatı kısa tut, alçaktan geç.": "Ceiling spikes kill too. Keep the rope short and stay low.",
	"Hareketli ve kırılgan noktalar bir arada. Zinciri önceden planla.": "Moving and fragile points together. Plan the chain ahead.",
	"Rüzgâr yukarı iter, tavan diken dolu. Akıntıda halatı uzatma.": "The wind pushes up and the ceiling is full of spikes. Don't extend the rope in the current.",
}

static var _kuruldu := false


## Ingilizce tabloyu TranslationServer'a yukler (birden cok cagri zararsiz).
static func kur() -> void:
	if _kuruldu:
		return
	_kuruldu = true
	var t := Translation.new()
	t.locale = "en"
	for k in EN:
		t.add_message(k, EN[k])
	TranslationServer.add_translation(t)


## Static metotlarda tr() yok (Object metodu): ayni ceviriyi buradan al.
static func t(metin: String) -> String:
	return TranslationServer.translate(metin)


## Kaynak anahtarin belirtec (%d, %s, %.2f, %%) dizisi: ceviri ile ayni olmali.
static func belirtecler(m: String) -> PackedStringArray:
	var sonuc := PackedStringArray()
	var r := RegEx.new()
	r.compile("%[-+ 0#]*[0-9]*(?:\\.[0-9]+)?[dsf]")
	for e in r.search_all(m):
		sonuc.append(e.get_string())
	return sonuc
