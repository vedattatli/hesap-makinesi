# Calculator Architecture Phase 19 - Final QA

## Amaç

Faz 19 yeni matematik özelliği ekleme fazı değildir. Bu fazın amacı, Faz 1-18 boyunca büyüyen calculator, graph, worksheet, CAS-lite, export, localization ve productization katmanlarını release öncesi kalite sertleştirmeden geçirmek; regresyon alanlarını görünür yapmak; deterministic fuzz/property testleriyle beklenmeyen parser/evaluator çöküşlerini yakalamak; ve CI-ready komutları dokümante etmektir.

## Test Audit

Mevcut test paketi aşağıdaki alanları kapsıyor:

- Lexer/parser: tokenization, equation syntax, malformed expressions.
- Scalar evaluator: arithmetic, trig, exact/approx mode, formatting.
- Exact/symbolic: RationalValue, SymbolicValue, radicals, transforms.
- Complex: complex arithmetic, helpers, formatting.
- Vector/matrix: constructors, operations, determinant, inverse, guards.
- Units: registry, expressions, conversions, temperature handling.
- Statistics/probability: dataset, descriptive stats, distributions, regression.
- Graph: FunctionValue, PlotValue, sampling, discontinuity, graph helpers.
- Worksheet: documents, blocks, storage, execution, scoped symbols, export.
- CAS/solve: equations, solve engine, transforms, system solving.
- UI/product: widget smoke, input panels, accessibility, productization panels.
- Settings/storage/history: serialization, compatibility, backup/restore.

Faz 19 ek testleri özellikle şu boşlukları hedefler:

- Deterministic fuzz: rastgele ama küçük ifadelerde lexer/parser/evaluator crash etmemeli.
- Malformed fuzz: bozuk inputlar typed error üretmeli, internal crash üretmemeli.
- Property tests: temel cebirsel ve sayısal invariantlar korunmalı.
- Integration flows: calculator sonucu, worksheet variable/solve, export ve backup zinciri birlikte çalışmalı.

## Regression Matrix

Detaylı release matrisi `docs/final_regression_matrix.md` içindedir. Bu dosya her büyük feature alanı için must-pass örnekleri, beklenen davranışı ve test odağını listeler. Release adaylarında bu matris manuel smoke test ve otomasyon kapsamı için referans alınmalıdır.

## Fuzz Testing Strategy

Fuzz testleri bounded ve deterministic çalışır:

- Seed sabittir.
- Expression depth ve örnek sayısı küçüktür.
- Büyük sayılar, devasa exponentler ve uzun token streamleri üretilmez.
- Test invariantı sonuç doğruluğu değil, güvenli davranıştır: engine exception fırlatmamalı ve beklenmeyen `internalError` üretmemelidir.
- Parser fuzz valid expressionlarda AST üretimini, malformed expressionlarda ise controlled error davranışını kontrol eder.

Bu yaklaşım CI süresini patlatmadan parser/evaluator yüzeyinde release öncesi “kazara crash” riskini azaltır.

## Property Testing Strategy

Property testleri küçük exact/approx domainlerde çalışır:

- Rational toplama komütatifliği.
- Güvenli çarpma-bölme tersliği.
- Matrix identity davranışı.
- Unit conversion roundtrip.
- Complex conjugate magnitude property.
- `sin^2 + cos^2 = 1` yaklaşık invariantı.
- Tekrarlı dataset mean invariantı.

Bu testler tam property-testing framework kullanmadan deterministic küçük örnek setleriyle yüksek sinyal üretir.

## Golden / Screenshot Tests

Bu fazda golden dosyası eklenmedi. UI son fazlarda responsive, localization, text-scale ve platform farklarına duyarlı hale geldiği için pixel-perfect goldenlar mevcut CI ortamında kırılgan olabilir. Bunun yerine widget smoke, semantics ve integration testleri ana güvenlik ağı olarak korunur. İleride sabit font/rendering pipeline kurulduğunda result card, graph panel, worksheet panel ve high-contrast görünümü için golden seti eklenebilir.

## Integration Flows

Faz 19 entegrasyon testi şu zinciri çalıştırır:

- Exact calculation evaluate edilir.
- Sonuç worksheet calculation block olarak kaydedilir.
- Worksheet variable tanımlanır.
- Solve block scoped variable kullanarak çalıştırılır.
- Worksheet Markdown export üretilir.
- Backup JSON export/parse roundtrip yapılır.
- Normal calculator global scope kapalı kalır.

Bu akış Faz 10-18 arasında birbirine bağlanan controller, worksheet, solve, export ve backup servislerini tek testte doğrular.

## CI-Ready Commands

Önerilen release kalite komutları:

```powershell
flutter analyze
flutter test
git diff --check
dart format --set-exit-if-changed lib test
```

Bu repoda Windows yerel kurulumda Flutter PATH üzerinde değilse komutlar şu şekilde çalıştırılabilir:

```powershell
& C:\src\flutter\bin\flutter.bat analyze
& C:\src\flutter\bin\flutter.bat test
git diff --check
& C:\src\flutter\bin\dart.bat format --set-exit-if-changed lib test
```

`scripts/qa_check.ps1` aynı komutların CI/local kullanım için küçük bir wrapper halidir.

## Bugfix Pass Policy

Bu fazda semantik değişiklik yapılmaz. Düzeltme kapsamı:

- Analyzer uyarıları.
- Flaky veya yavaş test noktaları.
- Serialization fallback açıkları.
- UI overflow/semantics smoke sorunları.
- Guard boundary test eksikleri.

Matematik sonucu değiştiren her düzeltme ayrı regresyon testi gerektirir.

## Coverage Gaps

Bilinen kalan boşluklar:

- Pixel-perfect golden test altyapısı henüz sabitlenmedi.
- Gerçek tarayıcı/desktop platform entegrasyonları manuel smoke test gerektirir.
- Çok uzun fuzz koşuları CI defaultunda çalışmıyor; nightly profile için ayrı genişletilebilir.
- Performance benchmarkları smoke düzeyinde; release perf budget trend takibi manuel yapılmalı.
- Dosya kaydetme/paylaşma platform entegrasyonu bilerek eklenmediği için export preview/copy akışı testleniyor.

## Release Checklist

- `flutter analyze` temiz.
- `flutter test` tüm testleri geçiriyor.
- `git diff --check` whitespace hatası üretmiyor.
- Regression matrix ana örnekleri manuel veya otomasyonla doğrulandı.
- Backup/restore corrupt input güvenli.
- Normal calculator global variables/functions kapalı.
- Worksheet-scoped symbols worksheet dışına sızmıyor.
- Graph/solve numeric fallback guardları typed error/warning üretiyor.
- Accessibility/high contrast/reduced motion smoke testleri geçiyor.

## Sonraki Faz Önerisi

Bir sonraki kalite hattı release automation olabilir:

- CI workflow dosyası.
- Coverage threshold.
- Nightly geniş fuzz suite.
- Golden snapshot pipeline.
- Web/desktop smoke automation.
- Release notes generator.
- Manual QA checklist UI.
- Performance budget trend raporu.
