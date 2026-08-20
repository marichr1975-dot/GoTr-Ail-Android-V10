import 'package:flutter/material.dart';

import 'saved_routes_screen.dart';
import '../services/gps_service.dart';
import '../services/mwm_map_service.dart';
import 'planning_map_screen.dart';
import 'mwm_download_progress_dialog.dart';
import 'v8_choice_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _blue = Color(0xFF0B5FD7);
  static const _green = Color(0xFF20A85A);

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _startFromGps(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6)),
            SizedBox(width: 16),
            Expanded(child: Text('Cerco la tua posizione GPSâ€¦', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
        ),
      ),
    );

    try {
      final point = await GpsService.currentPosition();
      final mwm = await MwmDownloadProgressDialog.ensureForPoint(context, point);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (mwm == null) {
        final path = await MwmMapService.instance.installPath();
        messenger.showSnackBar(SnackBar(
          duration: const Duration(seconds: 7),
          content: Text('GPS OK, ma non trovo una mappa disponibile sul server per questa zona. Cartella locale: $path'),
        ));
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Color(0xFF20A85A)),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Mappa pronta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 25,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            '${mwm.regionLabel}\n\n'
            'La mappa della zona Ã¨ giÃ  disponibile offline.',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CONTINUA'),
            ),
          ],
        ),
      );
      if (!context.mounted) return;
      _open(context, const V8ChoiceScreen(mode: V8Mode.start));
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text('Uscire da GoTr-AI?', style: TextStyle(fontWeight: FontWeight.w900)),
            content: const Text('Vuoi chiudere lâ€™app?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('NO')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('ESCI')),
            ],
          ),
        );
        if (exit == true && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/monte_pelmo.png', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x33000A17), Color(0x44000A17), Color(0xE6081826)],
                  stops: [0, .48, 1],
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxHeight < 660;
                  return Padding(
                    padding: EdgeInsets.fromLTRB(18, compact ? 12 : 18, 18, compact ? 12 : 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: compact ? 46 : 52,
                              height: compact ? 46 : 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .96),
                                borderRadius: BorderRadius.circular(17),
                                boxShadow: const [BoxShadow(color: Color(0x2A000000), blurRadius: 16, offset: Offset(0, 6))],
                              ),
                              child: const Icon(Icons.terrain_rounded, color: _blue, size: 30),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GoTr-Ail', style: TextStyle(color: Colors.white, fontSize: compact ? 27 : 30, height: 1, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                                  const SizedBox(height: 4),
                                  Text('Il tuo accompagnatore nei sentieri', style: TextStyle(color: const Color(0xFFEAF4FF), fontSize: compact ? 11.5 : 13, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _HomeAction(
                          icon: Icons.hiking_rounded,
                          title: 'Inizia',
                          color: _green,
                          compact: compact,
                          onTap: () => _startFromGps(context),
                        ),
                        SizedBox(height: compact ? 9 : 11),
                        _HomeAction(
                          icon: Icons.auto_awesome_rounded,
                          title: 'Pianifica',
                          color: _blue,
                          compact: compact,
                          onTap: () => _open(context, const PlanningMapScreen()),
                        ),
                        SizedBox(height: compact ? 9 : 11),
                        _HomeAction(
                          icon: Icons.bookmark_rounded,
                          title: 'Salvati',
                          color: Colors.white,
                          darkText: true,
                          compact: compact,
                          onTap: () => _open(context, const SavedRoutesScreen()),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool compact;
  final bool darkText;
  final VoidCallback onTap;

  const _HomeAction({
    required this.icon,
    required this.title,
    required this.color,
    required this.compact,
    required this.onTap,
    this.darkText = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = darkText ? const Color(0xFF0B5FD7) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: compact ? 68 : 78,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: darkText ? [Colors.white, const Color(0xFFF3F6FA)] : [color, Color.lerp(color, Colors.black, .18)!]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: .14)),
            boxShadow: [BoxShadow(color: (darkText ? Colors.black : color).withValues(alpha: darkText ? .16 : .30), blurRadius: 18, offset: const Offset(0, 7))],
          ),
          child: Row(
            children: [
              Container(
                width: compact ? 45 : 52,
                height: compact ? 45 : 52,
                decoration: BoxDecoration(color: darkText ? const Color(0xFFF0F3F7) : Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(17)),
                child: Icon(icon, color: fg, size: compact ? 25 : 29),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(color: fg, fontSize: compact ? 21 : 24, fontWeight: FontWeight.w900, height: 1)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: fg, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}

