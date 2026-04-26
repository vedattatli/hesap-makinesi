# Calculator Architecture - Phase 15 Input Editors

## Amaç
Faz 15, matematik motorunu değiştirmeden giriş deneyimini profesyonel hale getirir. Yeni katman expression string üretir; değerlendirme hâlâ güvenli lexer/parser/evaluator üzerinden yapılır. UI helper'ları global variable/function resolver açmaz ve worksheet sembollerini yalnızca insertion suggestion olarak gösterir.

## Advanced Expression Editor
Ana expression card artık inline preview, bracket validation ve autocomplete suggestion bar içerir. Insert akışı cursor-aware çalışır; seçili metin varsa replacement yapılır, function insert seçili metni `fn(selected)` şeklinde sarabilir. Klavye kısayolları shell seviyesinde tutulur: `Enter` evaluate, `Ctrl+Enter` save/evaluate, `Ctrl+K` command palette, `Ctrl+L` clear expression.

## Autocomplete
Autocomplete kaynakları built-in fonksiyonlar, constants, unit helpers, stats, graph, CAS ve aktif worksheet symbol listesi üzerinden oluşturulur. Worksheet sembolleri normal calculator resolver'a eklenmez; sadece "Worksheet-scoped; insert only" açıklamasıyla chip/palette içinde gösterilir.

## Function / Symbol Palette
Function palette kategori filtreleriyle çalışır: Basic, Trig, Log/Exp, Symbolic, Complex, Matrix, Units, Stats, Graph, CAS ve Worksheet. Her suggestion name, signature, category, description ve example metadata taşır. Palette insertion mevcut editor cursor/selection akışına bağlanır.

## Matrix / Vector Editors
Matrix editor 6x6 guard ile satır/sütun seçimi ve cell grid sunar, `mat(rows, cols, values...)` üretir. Vector editor 6 eleman guard ile `vec(...)` üretir. Cell değerleri expression string olarak saklanır; numeric coercion UI'da yapılmaz.

## Unit Converter
Unit converter value/source/target alanlarıyla `to(value sourceUnit, targetUnit)` expression üretir. Temperature unit sembolleri dahil edilmiştir. İsteğe bağlı immediate evaluation yerine expression insertion tercih edildi.

## Dataset Editor
Dataset editor comma-separated input ve basit numeric preview sağlar: count/min/max yalnız parse edilebilen numeric preview için gösterilir. CSV import yoktur; çıktı `data(...)` expression'ıdır.

## Graph Function Editor
Graph panel içinde function editor sheet eklendi. Bir satır bir expression olacak şekilde function listesi ve viewport alanları düzenlenir. Graph variable `x` yalnız graph scope notuyla kullanılır; standalone calculator resolver davranışı değişmez.

## Solve / CAS Editor
Solve/CAS sheet solve ve transform modlarını destekler. Solve mode `solve(expr, variable)` veya interval verilirse `solve(expr, variable, min, max)` üretir. CAS mode `simplify/expand/factor(expr)` ve `diff/integral(expr, variable)` üretir.

## Worksheet Block Editors
Worksheet block kartlarına focused editor sheet girişi eklendi. Sheet block type, expression snapshot, dependency/status özeti, run block ve validate worksheet aksiyonlarını sunar. Inline block alanları source of truth olarak korunur.

## Inline Validation
Inline validation şu fazda hafif ve güvenlidir: bracket matching ve expression preview. Ağır dry-run evaluation her keystroke'ta yapılmaz. Core parse/evaluate hataları mevcut result/error kartında gösterilmeye devam eder.

## Responsive / Accessibility
Tüm editor sheet'leri bottom sheet olarak mobile/desktop uyumlu çalışır. Key'ler, semantic labels ve Material input controls test edilebilir şekilde korunur. Reduced motion shell animasyonlarını etkiler; input helper'ları ek animasyon zorunluluğu getirmez.

## Guard Limitleri
Matrix max 6x6, vector max length 6. Dataset editor CSV import yapmaz. Graph editor mevcut GraphEngine guard'larını kullanır. Worksheet block editor dependency graph'i serialize etmez; mevcut executor/validator üzerinden çalışır.

## Sonraki Faz
Bir sonraki fazda true mathematical editor deneyimi genişletilebilir: tokenized rich input, visual bracket highlights, parser-driven diagnostics, keyboard-navigable autocomplete popover, graph expression linting, reusable worksheet scoped symbol picker ve optional CAS step side panel.
