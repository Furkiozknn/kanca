extends RefCounted
class_name Palet
## Oyunun tek paleti: Endesga 32'den secilmis 18 renk. Tum sprite'lar
## (tools/sprite_uret.gd) ve kodla cizilen her sey yalniz bunlari kullanir.
## Tema: "firtinali gokyuzu adalari" - soguk gri-mavi kaya, yesil yosun,
## turuncu oyuncu (arka plandan net ayrissin), kirmizi tehlike, camgobegi ruzgar.

# --- Gokyuzu / arka plan (koyudan aciga) ---
const GOK_DIP   := Color("181425")
const GOK_ORTA  := Color("262b44")
const GOK_UST   := Color("3a4466")
const BULUT_KOYU := Color("5a6988")
const BULUT_ACIK := Color("8b9bb4")

# --- Kaya / zemin ---
const KAYA_KOYU  := Color("262b44")
const KAYA_ORTA  := Color("3a4466")
const KAYA_ACIK  := Color("5a6988")
const KAYA_KENAR := Color("8b9bb4")
const YOSUN_KOYU := Color("265c42")
const YOSUN      := Color("3e8948")
const YOSUN_ACIK := Color("63c74d")

# --- Oyuncu ---
const CIZGI  := Color("181425")
const TEN    := Color("ead4aa")
const SAC    := Color("733e39")
const CEKET  := Color("f77622")
const CEKET_K := Color("be4a2f")
const PANTOLON := Color("3a4466")
const PANTOLON_K := Color("262b44")
const ATKI   := Color("e43b44")
const BOT    := Color("733e39")

# --- Tehlike / arayuz ---
const TEHLIKE      := Color("a22633")
const TEHLIKE_ACIK := Color("f6757a")
const HALAT      := Color("e4a672")
const NOKTA      := Color("8b9bb4")
const NOKTA_VURGU := Color("ffffff")
const NOKTA_BAGLI := Color("fee761")
const NOKTA_KIRIK := Color("b55088")
const RUZGAR     := Color("2ce8f5")
const BITIS      := Color("63c74d")
const ALTIN      := Color("fee761")
const GUMUS      := Color("c0cbdc")
const BRONZ      := Color("e4a672")
const METIN      := Color("c0cbdc")
const METIN_SOLUK := Color("5a6988")
