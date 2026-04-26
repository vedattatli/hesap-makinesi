# Calculator Architecture - Phase 10

## Faz 9'dan Devralinan Durum
Faz 9 sonunda hesaplama cekirdegi typed `CalculatorValue` hiyerarsisi uzerinde calisiyordu. Scalar, symbolic, complex, vector, matrix, unit, dataset, regression, function ve plot sonuc tipleri ayni evaluator ve formatter zincirinden geciyordu. `GraphEngine` saf Dart olarak ayriydi; Flutter tarafi yalnizca `GraphPanel` ve `CustomPainter` ile sunum yapiyordu. History ve result modeli zaten function/plot metadata tasiyabildigi icin Faz 10'da worksheet katmanini application/data odakli eklemek mumkun hale geldi.

## Neden Worksheet Katmani Application/Data Katmaninda?
Worksheet/notebook davranisi hesap motorunun kendisinden farkli bir urunlesme katmanidir. Block sirasi, run-all, export, persistence ve template yonetimi domain-degil application problemidir. Bu nedenle:

- CalculatorEngine ve GraphEngine degismeden reuse edilir.
- Worksheet storage calculator settings/history storage'dan ayrik kalir.
- Export servisleri saf Dart string/SVG/CSV uretebilir.
- Flutter UI yalnizca worksheet state'i gosteren bir presentation katmani olur.

Bu ayrim ileride notebook, workspace ve export formatlarinin cekirdegi bozmadan buyumesine izin verir.

## WorksheetDocument Tasarimi
`WorksheetDocument` versioned bir ust modeldir.

- `id`
- `title`
- `blocks`
- `createdAt`
- `updatedAt`
- `version`
- `isArchived`
- `activeGraphState`
- `savedExpressionTemplates`
- `savedGraphStates`

Belge immutable/copy-with akisiyla guncellenir. Baslik bos gelirse `Untitled Worksheet` fallback'i uygulanir. JSON deserialization sirasinda bozuk block veya graph state kayitlari crash yerine skip edilir. Version alani bilerek ayrik tutuldu; ileride named variable/function veya richer block tipleri eklendiginde migration icin zemin hazir.

## WorksheetBlock Tasarimi
Phase 10 icin uc block tipi eklendi:

- `calculation`
- `graph`
- `text`

Tum block'lar su ortak metadata'yi tasir:

- `id`
- `type`
- `title`
- `createdAt`
- `updatedAt`
- `orderIndex`
- `isCollapsed`

### CalculationBlock
Calculation block ifade ve sonuc snapshot'i saklar:

- `expression`
- mode snapshot: `angleMode`, `precision`, `numericMode`, `calculationDomain`, `unitMode`, `resultFormat`
- `result` -> `WorksheetBlockResult`

`WorksheetBlockResult`, `CalculationResult`'tan serializable bir alt-kume tasir. Boylesiyle worksheet persistence yalnizca display string'e bagli kalmaz; unit/vector/matrix/graph/statistics metadata da saklanir.

### GraphBlock
Graph block agir sample array saklamaz; yalnizca yeniden uretim icin gereken state'i saklar:

- `graphState`
- `graphState.expressions`
- `graphState.viewport`
- sampling summary
- graph warnings

SVG/CSV export aninda plot yeniden uretilir. Bu karar history ve worksheet storage'i binlerce noktayla sisirmemek icin secildi.

### TextBlock
Text block sade tutuldu:

- `text`
- `textFormat` -> `plain` veya `markdownLite`

Rich text editor veya tam markdown AST bu fazda eklenmedi.

## Saved Expression / Function Template Yaklasimi
Template modeli su alanlari tasir:

- `id`
- `label`
- `expression`
- `type` -> `expression`, `function`, `graphFunction`
- `variableName`
- `description`
- `createdAt`
- `updatedAt`

Bu kayitlar global symbol resolver degildir. Normal calculator modunda `f`, `g`, `x` davranisi degistirilmedi. Template'ler yalnizca worksheet veya graph UI tarafinda expression insertion kaynagi olarak kullanilir. Bu sayede Faz 9 scoped variable karari korunur.

## SavedGraphState Tasarimi
`WorksheetGraphState` graph panel ile worksheet arasinda kope gorevi gorur.

- `expressions`
- `viewport`
- `autoY`
- `showGrid`
- `showAxes`
- sampling options snapshot
- `plotSeriesCount`
- `plotPointCount`
- `plotSegmentCount`
- `lastPlotSummary`
- `warnings`
- context snapshot: angle/numeric/domain/unit/result format/precision

Graph panel mevcut plot sonucundan bir `WorksheetGraphState` uretir. Worksheet graph block ya da saved graph state recall edildiginde ayni state yeniden GRAPH paneline yuklenebilir.

## Worksheet Execution / Run-All Yaklasimi
`WorksheetController` block yurutmeyi order-preserving sekilde yonetir.

- `runBlock(blockId)` tek block calistirir.
- `runAllBlocks()` block listesini ustten alta gezer.
- Text block'lar skip edilir.
- Calculation block'lar `CalculatorEngine` ile evaluate edilir.
- Graph block'lar `plot(...)` ifadesi yeniden kurulup `CalculatorEngine`/`GraphEngine` zinciriyle render edilir.
- Basarisiz block digerlerini durdurmaz; hata snapshot'i block icinde tutulur.

Run-all normal calculator history'yi spam etmez. Worksheet deneysel kayit katmani oldugu icin history ve worksheet akislarinin ayrik tutulmasi bilinclidir.

## Export Service Yaklasimi
Export servisleri saf Dart olarak ayri tutuldu:

- `WorksheetExportService`
- `GraphSvgExporter`
- `GraphDataCsvExporter`

Tum export'lar `WorksheetExportResult` doner:

- `fileName`
- `mimeType`
- `contentText`
- `extension`
- `createdAt`
- optional `warning`

Bu model UI'nin file picker olmadan preview/copy akisina izin verir.

## Markdown / CSV / SVG Kararlari
### Markdown
Worksheet block'lari sirali ve okunabilir bir notebook ozeti olarak aktarilir:

- worksheet basligi
- created/updated metadata
- calculation block expression/result/mode/warning
- graph block expression listesi/viewport/summary
- text block icerigi

Satir sonlari `\n` olarak normalize edilir.

### Worksheet CSV
Calculation agirlikli tablosal export uretir:

- worksheet kimligi
- block kimligi
- expression
- result
- mode snapshot
- warnings/errors
- timestamps

CSV escaping RFC4180 benzeri uygulanir; virgul, tirnak ve newline iceren alanlar quote edilir.

### Graph SVG
`GraphSvgExporter`, `PlotValue` segmentlerini ayri `<polyline>` elemanlari olarak yazar. Bu sayede discontinuity/asymptote gecislerinde segmentler birbirine baglanmaz. Viewport, axes ve grid deterministic parametrelerle export edilir.

### Graph Data CSV
Point verisi kalici storage'a yazilmaz; export aninda yeniden uretip:

- `seriesIndex`
- `seriesLabel`
- `segmentIndex`
- `pointIndex`
- `x`
- `y`
- `defined`

alanlariyla CSV'ye donusturulur.

## PNG Export Neden Uygulanmadi?
Bu fazda platform bagimsiz, test-dostu ve packagesiz kalmak ana oncelikti. PNG export icin Flutter tarafinda `RepaintBoundary` tabanli bir UI-level pipeline mumkun olsa da:

- widget testlerinde kirilganlik artirir,
- desktop/mobile farkliliklari yaratabilir,
- pure Dart export katmanindan ayrik bir yol gerektirir.

Bu nedenle Phase 10'da SVG asil graph export formatidir. PNG icin mimari hazirligi `WorksheetGraphState` ve graph export service ayirimiyle birakildi.

## Storage ve Backward Compatibility
Worksheet persistence ayri dosyalara tasindi:

- `calculator.worksheets.v1.json`
- `calculator.active_worksheet.v1.json`

Kurallar:

- dosya yoksa bos liste / `null` doner
- bozuk JSON crash yerine safe fallback ile bos doner
- eski calculator settings/history storage'i etkilenmez
- taninmayan block tipleri skip edilir
- eksik field'lar default deger alir

Bu sayede eski uygulama datasi bozulmadan yeni worksheet sistemi eklenebilir.

## UI Worksheet Panel Mimarisi
UI tarafinda worksheet panel calculator ekranina yeni bir mod olarak eklendi.

- `GRAPH` ve `WORKSHEET` modlari birbirinden ayrik
- worksheet panel block listesi, create/select/rename/delete akisi tasir
- block bazli run / recall / export eylemleri vardir
- graph block `GRAPH` paneline geri yuklenebilir
- result card ve graph panel uzerinden worksheet'e save aksiyonlari vardir
- export sonucu file save yerine preview + copy akisiyla sunulur

Bu panel ayri widget olarak tutuldugu icin ileride daha buyuk notebook/editor deneyimine evrilebilir.

## Guard Limitleri
Phase 10 icin secilen guard'lar:

- max worksheets: `50`
- max blocks per worksheet: `500`
- max text block length: `20000`
- max saved templates: `200`
- max graph series per panel/block: `6`
- max Markdown export chars: `2_000_000`
- max CSV export rows: `100_000`
- max SVG/graph data point export: `50_000`

Limit asimlari crash yerine worksheet-level typed error uretir.

## Sonraki Faz: Variables / Functions / Workspace
Faz 11 icin dogal adim worksheet-scoped variable ve user-defined function sistemidir.

- worksheet-scoped named constants
- expression dependencies
- function templates'ten persisted user functions'a gecis
- safe recalculation order
- cycle detection
- variable manager UI

Bu fazda template'lerin global resolver olmamasi bilincliydi; Phase 11 bu alani scoped evaluation ile guvenli sekilde genisletebilir.
