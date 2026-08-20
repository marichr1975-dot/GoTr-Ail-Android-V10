# GoTr-Ail Android V10 - base ricostruita

Questa repository e' stata ricostruita dalla base stabile V9.9 e dai collegamenti
recuperati dall'APK V10 funzionante.

## Stato
- Gemini: codice della V9.9 mantenuto, usa GEMINI_API_KEY tramite --dart-define.
- Mappe MWM: download automatico dalla repository marichr1975-dot/nuove-mappe.
- Release mappe: organic-test-mwm-v1.
- Cartella locale mappe: gotr_maps.
- Nessun fallback intenzionale alle vecchie MBTiles per la selezione della MWM.

## File V10 recuperati/ricostruiti
- lib/services/mwm_release_service.dart
- lib/services/mwm_map_service.dart
- lib/screens/mwm_download_progress_dialog.dart
- collegamento download in home_screen.dart
- collegamento download in planning_map_screen.dart

## Build
La GitHub Action Build V10 APK esegue analyze e build debug.
Per avere Gemini funzionante nell'APK prodotto da GitHub, creare il secret:
GEMINI_API_KEY.
