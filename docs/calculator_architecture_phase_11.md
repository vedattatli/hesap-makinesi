# Calculator Architecture - Phase 11

## Faz 10'dan Devralinan Worksheet / Export Mimarisi
Faz 10 sonunda uygulama `WorksheetDocument` uzerinde versioned block persistence, worksheet controller akisi, graph state snapshot'i ve Markdown/CSV/SVG export servislerine sahipti. Calculation, text ve graph block'lari saklanabiliyor; graph sample noktalarinin tamamini depolamadan expression + viewport + sampling ozeti uzerinden yeniden uretim yapilabiliyordu. `CalculatorEngine` ve `GraphEngine` saf Dart olarak kalmis, Flutter tarafi ise yalnizca worksheet/graph presentation katmanini tasiyordu.

## Neden Worksheet-Scoped Resolver Gerekir?
Worksheet not defteri mantigi, global degisken veya global function sistemi ile ayni sey degildir. Kullanici ayni uygulama icinde birden fazla worksheet acabilir; bir worksheet'teki `a`, `mass` veya `f(x)` digerine sizmamalidir. Ayrica normal calculator davranisi korunmalidir: worksheet disinda `a + 1` veya `f(3)` hata vermeye devam etmelidir.

Bu nedenle scope su sekilde sinirlandi:

- default evaluator scope yoksa mevcut davranis korunur
- worksheet execution sirasinda opsiyonel scope enjekte edilir
- graph block ve worksheet preview ayni scope'u kullanabilir
- global symbol resolver acilmaz

## Global Resolver Acmama Karari
Phase 11 bilerek global variable/function katmani eklemez. Bunun sebepleri:

- Faz 1-10 boyunca kurulan deterministic evaluator davranisini bozmamak
- history / result / graph panel akisini surprizsiz tutmak
- templates'i global symbol registry'ye donusturmemek
- gelecekte gelebilecek worksheet-scoped workspace modelini daha guvenli kurmak

Boylece user-defined symbols yalnizca aktif worksheet execution baglaminda anlam kazanir.

## Variable Definition Block Tasarimi
Yeni `variableDefinition` block tipi su bilgileri tasir:

- `symbolName`
- `expression`
- `normalizedExpression`
- `result`
- `dependencies`
- `isStale`
- `lastEvaluatedAt`
- worksheet-level error alanlari
- mode snapshot: numeric/format/angle/domain/unit/precision

Naming kurallari strict tutuldu:

- bos isim yok
- identifier formati zorunlu
- built-in constant ve built-in function adlari yasak
- graph/function local `x` worksheet variable olarak yasak
- unit isimleri genel olarak reserved, ancak Phase 11 ornekleri ile uyum icin `a` istisnasi korundu

Variable block sonucu `WorksheetBlockResult` olarak snapshot'lanir; bu sayede exact/unit/vector/matrix gibi result metadata kaybolmaz.

## Function Definition Block Tasarimi
Yeni `functionDefinition` block tipi su alanlari tasir:

- `symbolName`
- `parameters`
- `bodyExpression`
- `normalizedBodyExpression`
- `dependencies`
- `isStale`
- `lastEvaluatedAt`
- worksheet-level error alanlari
- mode snapshot

Function kurallari:

- isim built-in function/constant ile cakisamaz
- parametre adlari unique olmalidir
- parametreler local scope'ta worksheet variables'dan once cozulur
- body worksheet variables ve worksheet functions kullanabilir
- direct recursion ve indirect recursion cycle olarak reddedilir
- arity mismatch typed error uretir

Function block result'i numeric bir deger degil, validator dostu signature snapshot'idir:

- `f(x) = x^2 + a`

## EvaluationScope / Scoped Symbol Table Tasarimi
Core tarafa genel ama default-off bir `EvaluationScope` eklendi. Bu model Flutter'a bagli degildir ve su alanlari tasir:

- `variables`
- `functions`
- `parent`
- `activeFunctionSourceIds`
- `maxCallDepth`

Worksheet tarafinda bunun uzerine:

- `WorksheetSymbol`
- `WorksheetSymbolTable`

modelleri kuruldu.

Resolution order:

1. local function parameters
2. worksheet variables
3. worksheet user-defined functions
4. built-in constants / functions / units
5. undefined error

Core evaluator built-in isimleri override ettirmez. Boylece `sin`, `sqrt`, `pi`, `e`, `i` ve units mevcut anlamlarini korur.

## Dependency Graph Tasarimi
Dependency graph node'lari block bazlidir:

- `variableDefinition`
- `functionDefinition`
- `calculation`
- `graph`

`text` block'lari graph'a girmez.

Edges:

- symbol sahibi block -> bu symbol'u kullanan dependent block

Analyzer expression AST uzerinden:

- variable refs
- function refs

toplar; fakat su isimleri dependency saymaz:

- built-in constants/functions
- units
- function parameter isimleri
- graph expression icindeki `x`

Graph block `f(x)` ifadesi kullanirsa yalnizca `f`'ye baglanir; `x` dependency degildir.

## Topological Sort ve Cycle Detection Yaklasimi
Executor once dependency graph'i kurar, sonra deterministic topological order uretir. Birden fazla runnable node varsa worksheet display order'i tie-breaker olarak kullanilir. Boylece:

- run order dependency'ye gore dogru olur
- display order degismez

Cycle detection DFS stack yaklasimi ile yapilir. Desteklenen hata senaryolari:

- direct cycle: `a = a + 1`
- indirect cycle: `a = b + 1`, `b = a + 1`
- function cycle: `f(x)=g(x)+1`, `g(x)=f(x)+1`
- mixed cycle: `a = f(1)`, `f(x)=a+x`

Cycle bulundugunda:

- ilgili block'lar `dependencyCycle` alir
- downstream dependents `staleDependency` alir
- uygulama crash olmaz
- cycle path ozet metin olarak uretilir

## Stale / Dirty Block Yaklasimi
Worksheet duzenlenirken her degisiklik otomatik run etmez. Bunun yerine:

- variable/function tanimi degisirse kendisi ve downstream dependents stale olur
- calculation block duzenlenirse yalnizca kendisi stale olur
- graph block expression/viewport degisirse o graph block stale olur

`WorksheetExecutor.markDependentsStale(...)` block'lari isaretler ama symbol manager gorunurlugunu korumak icin symbol summary'leri de yeniden uretir.

## Run Block / Run Affected / Run All Akisi
Executor su akisleri saglar:

- `validate(...)`
- `runBlock(...)`
- `runAll(...)`
- `markDependentsStale(...)`

Controller seviyesinde bunlar:

- `runBlock(blockId)`
- `runAllBlocks()`
- `runAffectedBlocks(blockId)`
- `validateActiveWorksheet()`

akislariyla disari acilir.

Davranis:

- `runBlock` once gerekli upstream dependency'leri hesaplar
- `runAll` tum runnable graph'i topological order ile gezer
- `runAffected` degisen tanimdan sonra gerekli yolu tekrar calistirir
- upstream hata verirse dependent block `staleDependency` ile isaretlenir
- text block'lar skip edilir
- normal calculator history spam edilmez

## Graph Block + Scoped Function Etkilesimi
Phase 9 graphing motoru zaten local `x` scope kullanabiliyordu. Phase 11 ile buna worksheet scope da eklendi.

Boylece worksheet graph block:

- `f(x)`
- `a*x`
- `f(x) + energy`

gibi ifadeleri ayni worksheet'teki variable/function tanimlariyla render edebilir.

Ancak standalone graphing davranisi korunur:

- worksheet scope verilmezse `plot(f(x), ...)` global olarak calismaz

Bu karar Faz 9'un "global resolver yok" ilkesini korur.

## Export Degisiklikleri
Worksheet export artik yeni block tiplerini de kapsar.

Markdown:

- variable definitions
- function definitions
- stale/error durumu
- dependency summary

CSV:

- `symbolName`
- `functionParameters`
- `definitionExpression`
- `dependencies`
- `stale`
- worksheet error kolonlari

Graph SVG / graph data CSV export scope-sensitive hale getirildi:

- graph block export aninda worksheet scope ile yeniden evaluate edilir
- scope cozulmezse export typed worksheet error verir

## Storage / Backward Compatibility Yaklasimi
Serialization su ilkelerle guncellendi:

- yeni block tipleri JSON'a eklenir
- eski worksheet dosyalari yeni field'lar olmadan da yuklenir
- derived dependency graph kalici saklanmaz; yeniden insa edilir
- stale flag ve dependency listesi gibi hafif alanlar saklanabilir
- unknown block type policy safe skip olarak korunur
- corrupt JSON fallback crash yerine empty/safe load davranisi verir

`WorksheetDocument.version` Faz 11 ile birlikte arttirilmasa bile model extansion'lari backward compatible tutuldu; mevcut implementation `currentVersion = 2` uzerinden devam ediyor.

## UI Variable / Function Manager Yaklasimi
Worksheet paneli minimum ama islevsel sekilde genisletildi:

- Add Variable
- Add Function
- Validate
- symbol summary section
- stale/error badges
- dependency summary

Variable block karti:

- name
- expression
- result
- stale / error durumu
- run / save / delete / move

Function block karti:

- name
- parameters
- body
- signature preview
- stale / error durumu
- save / delete / move

Ayri bir spreadsheet editor veya visual dependency graph bu faza dahil edilmedi.

## Guard Limitleri
Phase 11 icin secilen limitler:

- max symbols per worksheet: `500`
- max function parameters: `5`
- max function call depth: `32`
- max dependency graph nodes: `1000`
- max dependency graph edges: `5000`
- max worksheet blocks: mevcut Phase 10 limiti `500`
- max expression length: mevcut parser guard'lari reuse edilir
- cycle path display: kisa summary formatinda tutulur

Per-run memoization:

- variable values run sirasinda map icinde tutulur
- function definitions AST olarak bir run boyunca reuse edilir
- cross-worksheet persistent cache yoktur

## Sonraki Faz Icin CAS-Lite / Equation Solving Plani
Phase 11 artik worksheet-scoped symbol ve deterministic dependency order kurdu. Bu zemin uzerine sonraki fazda:

- equation parser
- `solve(expr = 0, variable)`
- polynomial detection
- numeric root fallback
- derivative/integral helper'lari
- worksheet solve block'lari
- graph root/intersection entegrasyonu

eklenebilir.

Dogal yon:

1. solve-block yeni worksheet block tipi olur
2. scoped symbol table solve-block tarafindan reuse edilir
3. symbolic-lite ve numeric fallback ayrik servislerde tutulur
4. graph panel root/solve sonucu ile birlikte calisabilir

Boylece Faz 11'de kurulan worksheet scope, ileride CAS-lite ve equation solving icin temel execution omurgasi haline gelir.
