# Calculator Architecture - Phase 2

## Faz 1den Devralinan Mimari

Faz 1 sonunda proje saf Dart bir hesap cekirdegine sahipti:

- `CalculatorEngine`
- `CalculatorLexer`
- `ExpressionParser`
- AST node modeli
- `ExpressionEvaluator`
- `CalculationContext`
- `CalculationOutcome`
- `CalculationResult`
- `CalculationError`

Bu cekirdek Flutter import etmeden calisiyor ve unit testlerle
dogrulaniyordu. UI ise hala daha cok `main.dart` icindeki `StatefulWidget`
uzerinde yasayan lokal state ile yonetiliyordu.

## Faz 2de Eklenen Application, State ve Storage Yapisi

Faz 2 ile birlikte presentation ile core arasina yeni bir uygulama katmani
eklendi:

- `CalculatorController`
- `CalculatorState`
- `CalculatorStorage`
- `CalculatorSettings`
- `CalculatorHistoryItem`
- `LocalCalculatorStorage`
- `MemoryCalculatorStorage`

Bu katmanlarin gorevleri:

- `CalculatorController`: expression editor state, cursor, evaluate akisi,
  history, settings ve persistence koordinasyonu
- `CalculatorState`: UIin tek kaynaktan okudugu immutable snapshot
- `CalculatorStorage`: persistence soyutlamasi
- `LocalCalculatorStorage`: yerel JSON dosyalari uzerinden kalici saklama
- `MemoryCalculatorStorage`: testlerde kullanilan in-memory implementasyon

## Yeni UI Akisi

UI artik enginei dogrudan cagirmiyor. Akis su sekildedir:

1. Kullanici expression alanina yazar veya keypad tusuna basar.
2. UI bu girdi komutunu `CalculatorController`a yollar.
3. Controller expression ve cursor stateini gunceller.
4. Kullanici `=` veya Enter ile evaluate ister.
5. Controller `CalculatorEngine`i uygun `CalculationContext` ile cagirir.
6. Sonuc `CalculationOutcome` olarak state icine yazilir.
7. Basarili sonuc historyye eklenir ve storagea kaydedilir.
8. Ayarlar degistiginde settings storagea aninda yazilir.

## History ve Settings Persistence Tasarimi

Storage anahtarlari versionlidir ve dosya adlarina tasinir:

- `calculator.settings.v1.json`
- `calculator.history.v1.json`

History davranisi:

- Sadece basarili hesaplamalar saklanir.
- Kayitlar newest-first tutulur.
- Maksimum 100 kayit tutulur.
- Ayni expression ve ayni sonuc art arda olusursa ikinci kayit eklenmez.
- Bozuk JSON okunursa uygulama bos history ile devam eder.

Settings davranisi:

- Varsayilan aci modu `DEG`
- Varsayilan precision `10`
- Varsayilan theme `system`
- Theme, angle mode ve precision degisiklikleri aninda kaydedilir.
- Bozuk settings JSONu varsa default settings kullanilir.

## Test Stratejisi

Faz 2 testleri su katmanlara bolundu:

- Core engine testleri: Faz 1 davranislarini korur, GRAD ve precision
  formatlama testleri eklendi.
- Controller testleri: editor komutlari, evaluate, history ve settings akisi
- Model testleri: history/settings serialization ve safe fallback
- Storage testleri: memory storage ve shared preferences tabanli storage
- Widget testleri: app acilisi, evaluate, hata gostermesi, GRAD secimi,
  history recall ve precision ayari

## Sonraki Faz Icin Exact, Rational ve Decimal Plani

Faz 3te cekirdegi bozmadan sayi modelini genisletmek icin su yol onerilir:

1. `CalculationResult` icinde numeric `double` yanina tipli bir deger modeli
   eklemek
2. `EvaluatedValue`yi `double` yerine sealed value hierarchyye tasimak
3. Ilk olarak `RationalValue` eklemek ve `1/3 + 1/6` gibi ifadeleri exact
   modda korumak
4. Ardindan `DecimalValue` ekleyip display precision ile hesap precisionini
   ayirmak
5. `CalculationContext` icine exact/approximate policy alanlari eklemek
6. `ResultFormatter`i `double` odakli olmaktan cikarip deger tipi tabanli hale
   getirmek

Bu sayede Faz 2de kurulan controller, settings ve history altyapisi bozulmadan
exact mode eklenebilir.
