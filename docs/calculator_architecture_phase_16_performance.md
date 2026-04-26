# Calculator Architecture - Phase 16 Performance Hardening

## Amaç
Faz 16, matematik semantiğini değiştirmeden hesaplama maliyetini daha görünür, daha sınırlı ve UI için daha güvenli hale getirir. Bu faz production telemetry veya dış servis eklemez; benchmark ve task modelleri local, deterministic ve test odaklıdır.

## Performance Findings
- Graph panelde zaten debounce vardı; buna request invalidation ve per-panel cache eklendi.
- GraphEngine tarafında assert tabanlı sampling kontrolleri release build için yeterli değildi; runtime guard eklendi.
- Worksheet run-all her blok için yeniden hesaplama yapıyordu; clean ve symbol tanımlamayan bloklar artık güvenle skip edilebilir.
- Matrix, stats, solve ve CAS katmanlarında önceki fazlardan gelen guard limitleri korunur.

## Benchmark Harness
`CalculatorBenchmarkSuite`, parser, graph plot, matrix determinant, solve ve stats senaryolarını local olarak koşturur. `WorksheetBenchmarkHarness`, worksheet run-all ölçümü için ayrı application-layer helper sağlar. Sonuçlar sadece caller’a döner; dosyaya, ağa veya telemetry sistemine yazılmaz.

## Computation Task Model
`ComputationTaskRunner` ve `ComputationCancellationToken`, ağır işlerin cancellable/timed bir zarf içinde çalıştırılmasını sağlar. Isolate bu fazda production path’e alınmadı; çünkü worksheet scope, AST ve bazı CalculatorValue tipleri güvenli isolate serialization için daha geniş bir uyumluluk çalışması ister. Bu karar davranış drift riskini azaltır.

## Graph Performance
- Plot işlemleri 120 ms debounce ile kalır.
- Stale scheduled plot request’leri serial id ile iptal edilir.
- Aynı expression/context/viewport/options tekrarında per-panel ephemeral cache kullanılır.
- Cache 8 entry ve 30.000 toplam nokta ile sınırlıdır.
- Runtime sampling guard limitleri: max 8 series, max 8192 sample/series, max 50.000 total point budget.

## Worksheet Performance
- `runAll` dependency graph’i korur, symbol tanımlarını gerekli olduğu için işler.
- Clean calculation/solve/CAS/graph blokları result veya graph metadata varsa skip edilir.
- Execution result artık executed/skipped block listesi ve elapsed duration taşır.
- `runAllBlocks` sırasında controller loading state set eder ve hata durumunda state’i temizler.

## Matrix / CAS / Stats Guards
Mevcut guard’lar korunur:
- matrix total element: 400
- exact determinant: 6x6
- approximate determinant: 12x12
- inverse: 10x10
- dataset length: 10.000
- distribution summation: 100.000
- rational-root candidates: 5000
- derivative/integral node count: 1000
- CAS expand degree: 8, factor degree: 6

## UI Jank Reduction
Graph panel cache/debounce path’i gereksiz recompute’u azaltır. Worksheet run-all loading state ile kullanıcıya yoğun işlem bilgisi taşır. History/worksheet lazy list kullanımı korunur. CustomPainter yalnız plot value, viewport ve display options değişince repaint eder.

## Memory Policy
Graph sample point’leri history’ye yazılmaz. Panel cache global değildir ve entry/point cap ile sınırlıdır. Dialog/controller dispose akışları korunur. Export preview ve worksheet graph state hâlâ metadata-first davranır.

## Cache Policy
Global persistent cache yoktur. Graph cache panel ömrüyle sınırlıdır ve expression + calculation context + sampling options key’i kullanır. Worksheet execution per-run değerleri local map’lerde tutulur.

## Test Strategy
Yeni testler task cancellation, benchmark smoke, graph sampling guard ve worksheet skip-clean davranışını doğrular. Existing regression suite tam çalıştırılır.

## Sonraki Faz
Bir sonraki performans fazında isolate serialization audit, background graph worker, incremental worksheet evaluator, timeline profiling hooks ve opt-in developer benchmark CLI eklenebilir.
