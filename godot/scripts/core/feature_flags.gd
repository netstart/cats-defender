extends Node
## FeatureFlags — flags de recursos (M24, M26).
## Autoload: FeatureFlags

var ads_enabled := false            # OrangeBTNAds oculto (decisão 7)
var debug_menu_enabled := OS.is_debug_build()
var perf_overlay_enabled := OS.is_debug_build()
