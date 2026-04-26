# Calculator Architecture - Phase 14 Premium UI

## UI Hedefleri
Phase 14 matematik motorunu değiştirmeden ürün yüzeyini premium bir deneyime taşır. Amaç; mode navigation, result card, keypad, graph ve worksheet panellerini aynı tasarım diliyle birleştirmek, animasyonları anlamlı mikro-etkileşimlere dönüştürmek ve masaüstü/web/mobil kırılımlarında daha tutarlı bir shell sağlamaktır.

## Design Language
Yeni presentation design katmanı token tabanlıdır: spacing, radius, motion, shadow, typography, breakpoint ve semantic color dosyaları aynı görsel dili paylaşır. Görsel yaklaşım soft-elevated/glass hissi taşır; yüzeyler yarı saydam container renkleri, ince border ve kontrollü gölgeyle ayrılır. CAS, graph, worksheet, unit, stats ve exact/approx gibi domain anlamları semantic color helper'larıyla ayrıştırılır.

## Layout Sistemi
Calculator screen artık mode-aware shell olarak çalışır. Geniş ekranda sol navigation rail, ana çalışma alanı ve sağ history inspector birlikte görünür. Dar ekranda ana içerik scrollable kalır ve alt yatay mode bar ikincil navigasyonu taşır. CALC, GRAPH, WORKSHEET, CAS, STATS, MATRIX, UNITS ve HISTORY modları aynı navigation sistemi içinde temsil edilir.

## Component Inventory
Temel presentation bileşenleri: premium top toolbar, mode rail/bottom bar, result card, categorized keypad, graph panel, worksheet panel, command palette, settings sheet ve history inspector. Tasarım token'ları `lib/features/calculator/presentation/design/` altında tutulur. Büyük tek dosya yaratmamak için domain panelleri mevcut widget'larda kalır.

## Animation Principles
Animasyonlar state değişimini açıklamak için kullanılır: mode panel geçişleri, result reveal, keypad category transition ve keypad press scale feedback. Ağır veya sürekli animasyon yoktur. Kullanılan API'ler Flutter standard `AnimatedSwitcher`, `AnimatedContainer`, `AnimatedScale` ve `AnimatedSize` tabanlıdır.

## Responsive Rules
`AppBreakpoints.wide` ve üstünde navigation rail + right inspector kullanılır. Compact layout'ta mode navigation bottom command bar'a iner, secondary panels inline/sheet yaklaşımıyla çalışır. Keypad category bar yatay scroll eder, böylece küçük ekranlarda overflow yerine kontrollü keşif sağlar.

## Accessibility Rules
Mevcut semantic labels korunur; graph canvas summary, keypad button semantics ve result live region devam eder. Mode navigation icon/text ile birlikte görünür. Touch hedefleri Material 3 minimum boyutlarında tutulur. Motion azaltma ayarı animasyon sürelerini neredeyse instant yapar.

## Reduced Motion Policy
`CalculatorSettings.reduceMotion` kalıcı ayardır ve default `false` gelir. Settings sheet içinde Accessibility bölümünden değiştirilebilir. UI animasyonları `AppMotion.duration(..., reduceMotion: value)` üzerinden kısaltılır; matematik sonucu veya state akışı etkilenmez.

## Theme System
`AppTheme.build` light/dark theme'i merkezi olarak üretir. Tema Material 3 color scheme, premium surface tonları, input/chip/button/navigation stilleri ve typography tuning içerir. High-contrast için ayrı tema henüz açılmadı; semantic color ve token yapısı buna hazırdır.

## Testing Strategy
Faz 14 testleri behavior yerine UI sözleşmelerini kilitler: reduced motion serialization/controller flow, mode navigation görünürlüğü, command palette açılması, keypad category switch ve settings switch. Golden test eklenmedi; mevcut dinamik platform/font ve geniş faz yüzeyi nedeniyle smoke/widget testleri daha kararlı tercih edildi.
