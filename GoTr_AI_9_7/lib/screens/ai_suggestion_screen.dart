import 'package:flutter/material.dart';

import '../services/gemini_ai_service.dart';

class AiSuggestionScreen extends StatelessWidget {
  final AiTrailSuggestion suggestion;
  const AiSuggestionScreen({super.key, required this.suggestion});

  static const _blue = Color(0xFF0B5FD7);
  static const _green = Color(0xFF20A85A);
  static const _orange = Color(0xFFF18C2C);
  static const _ink = Color(0xFF112234);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      appBar: AppBar(
        title: const Text('Proposta AI', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: _blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 660;
            return ListView(
              padding: EdgeInsets.fromLTRB(13, compact ? 10 : 14, 13, 18),
              children: [
                Container(
                  padding: EdgeInsets.all(compact ? 14 : 17),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF073A79), _blue],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 21),
                          SizedBox(width: 7),
                          Text(
                            'GEMINI',
                            style: TextStyle(
                              color: Color(0xFF9DD2FF),
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: compact ? 8 : 11),
                      Text(
                        suggestion.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 19 : 22,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: compact ? 6 : 8),
                      Text(
                        suggestion.summary,
                        style: TextStyle(
                          color: const Color(0xFFEAF4FF),
                          fontSize: compact ? 12.8 : 14,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 10 : 13),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.route_rounded,
                        label: 'Tipo',
                        value: suggestion.routeType,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MetricCard(
                        icon: Icons.straighten_rounded,
                        label: 'Distanza',
                        value: suggestion.distance,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _MetricCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Difficoltà',
                  value: suggestion.difficulty,
                  horizontal: true,
                ),
                if (suggestion.reasons.isNotEmpty) ...[
                  SizedBox(height: compact ? 12 : 15),
                  const Text(
                    'Perché è adatto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink),
                  ),
                  const SizedBox(height: 7),
                  ...suggestion.reasons.take(3).map(
                        (e) => const _BulletShell().buildBullet(
                          icon: Icons.check_circle_rounded,
                          text: e,
                          color: _green,
                        ),
                      ),
                ],
                if (suggestion.cautions.isNotEmpty) ...[
                  SizedBox(height: compact ? 11 : 14),
                  const Text(
                    'Attenzione',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _ink),
                  ),
                  const SizedBox(height: 7),
                  ...suggestion.cautions.take(2).map(
                        (e) => const _BulletShell().buildBullet(
                          icon: Icons.warning_amber_rounded,
                          text: e,
                          color: _orange,
                        ),
                      ),
                ],
                SizedBox(height: compact ? 13 : 17),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7EF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBDE5CC)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.verified_rounded, color: _green, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Profilo AI creato. GoTr-AI userà queste preferenze come base per scegliere la traccia reale sulla mappa.',
                          style: TextStyle(fontSize: 12.2, height: 1.3, fontWeight: FontWeight.w700, color: _ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool horizontal;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    if (horizontal) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0E8EE)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF0B5FD7), size: 20),
            const SizedBox(width: 8),
            Text('$label: ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
            Expanded(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0E8EE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF0B5FD7), size: 19),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10.5, color: Color(0xFF627383), fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF112234)),
          ),
        ],
      ),
    );
  }
}

class _BulletShell {
  const _BulletShell();

  Widget buildBullet({required IconData icon, required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.25, fontWeight: FontWeight.w600, color: Color(0xFF112234)),
            ),
          ),
        ],
      ),
    );
  }
}
