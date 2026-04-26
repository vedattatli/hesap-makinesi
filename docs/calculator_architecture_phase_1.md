# Calculator Architecture - Phase 1

## Mevcut Durum Ozeti

Proje tek ekranli bir Flutter bilimsel hesap makinesi olarak basladi. Arayuz
ve hesaplama mantigi buyuk olcude ayni akis icinde tutuluyordu.

Ana hesaplama davranisi tek bir motor sinifinda toplanmisti ve UI bu motoru
dogrudan cagiran bir yapiya sahipti. Mevcut cozum temel dort islem, parantez,
bazi trigonometrik fonksiyonlar ve basit hata durumlarini destekliyordu.

## Tespit Edilen Mimari Problemler

- UI ve hesaplama mantigi birbirine yakin baglanmisti.
- Sonuclar yalnizca `double` donen basit bir API ile yonetiliyordu.
- Hatalar tipli bir model yerine istisna tabanli ve sinirliydi.
- Lexer, parser, AST ve evaluator ayrimi net degildi.
- Aciklayici hata mesaji, warning ve normalized expression modeli yoktu.
- Test kapsami temel senaryolarla sinirliydi.

## Yeni Onerilen Mimari

Faz 1 ile birlikte cekirdek hesaplama mantigi `lib/core/calculator/` altina
tasindi.

Yeni yapi:

- `CalculatorEngine`: UI icin public giris noktasi
- `CalculationContext`: aci modu, precision ve gelecekte buyuyecek ayarlar
- `CalculationOutcome`: basarili sonuc veya tipli hata sarmalayicisi
- `CalculationResult`: normalized expression, display result, numeric value,
  warning bilgileri
- `CalculationError`: tipli ve aciklanabilir hata modeli
- `CalculatorLexer`: guvenli tokenization
- `ExpressionParser`: operator precedence bilen AST parser
- `AST nodes`: sayi, sabit, unary, binary ve function call dugumleri
- `Evaluator`: AST uzerinden guvenli hesaplama

Bu yapida Flutter yalnizca presentation katmanidir. Matematik cekirdegi
Flutter import etmez ve saf Dart olarak calisir.

## Matematik Motoru Tasarimi

Faz 1 motoru su akista calisir:

1. Kullanici string ifadeyi girer.
2. `CalculatorLexer` ifadeyi token listesine ayirir.
3. Lexer gerekiyorsa guvenli implicit multiplication tokenlari ekler.
4. `ExpressionParser` tokenlardan AST uretir.
5. Evaluator AST uzerinde hesaplama yapar.
6. `CalculatorEngine` sonucu `CalculationOutcome` icinde UI a verir.

Faz 1 destekleri:

- Sayilar: tam sayi, ondalik, bilimsel gosterim (`1e3`, `2.5e-4`)
- Operatorler: `+`, `-`, `*`, `x`, `/`, `÷`, `^`
- Parantezler
- Unary plus/minus
- Sabitler: `pi`, `π`, `e`
- Fonksiyonlar:
  - `sin`, `cos`, `tan`
  - `asin`, `acos`, `atan`
  - `sqrt`, `abs`
  - `ln`, `log`, `log10`, `log2`
  - `exp`, `pow`, `min`, `max`
  - `floor`, `ceil`, `round`
- Aci modlari: DEG, RAD, GRAD
- Tipli hata modeli
- Warning destegi

## Bu Fazda Yapilanlar

- Yeni saf Dart calculator core katmani kuruldu.
- Lexer / parser / AST / evaluator ayrimi yapildi.
- Typed error ve result modelleri olusturuldu.
- `CalculatorEngine` yeni public giris noktasi olarak eklendi.
- UI entegrasyonu yeni engine ile calisacak sekilde guncellendi.
- UI da aciklayici hata mesaji alani eklendi.
- Core davranislar icin unit testler genisletildi.

## Sonraki Fazlarda Yapilacaklar

- Application layer ve controller yapisinin ayrilmasi
- History ve settings persistence
- Exact / approximate ayrimi icin daha guclu sayi modeli
- Rational ve decimal precision katmani
- Complex number mode
- Unit conversion engine
- Matrix ve statistics modulleri
- Grafik modu
- Klavye girisi ve daha gelismis expression editoru
- Accessibility ve localization derinlestirmeleri
