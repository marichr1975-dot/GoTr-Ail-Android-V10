import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'v8_preferences_screen.dart';

enum V8Mode { start, plan }

class V8ChoiceScreen extends StatefulWidget {
  final V8Mode mode;
  final String? initialPlace;

  const V8ChoiceScreen({
    super.key,
    required this.mode,
    this.initialPlace,
  });

  @override
  State<V8ChoiceScreen> createState() => _V8ChoiceScreenState();
}

class _V8ChoiceScreenState extends State<V8ChoiceScreen> {
  String? _choice;

  static const _blue = Color(0xFF0B5FD7);
  static const _green = Color(0xFF20A85A);
  static const _ink = Color(0xFF112234);

  static const _items = [
    ('Passeggiata', Icons.directions_walk_rounded, Color(0xFF20A85A)),
    ('Rifugio', Icons.cabin_rounded, Color(0xFFE8812B)),
    ('Sentiero nel bosco', Icons.forest_rounded, Color(0xFF188A54)),
    ('Cascata', Icons.water_drop_rounded, Color(0xFF1499D6)),
    ('Fontane', Icons.local_drink_rounded, Color(0xFF0B5FD7)),
  ];

  void _home() => Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

  void _continue() {
    if (_choice == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => V8PreferencesScreen(
          mode: widget.mode,
          activity: _choice!,
          place: widget.mode == V8Mode.plan ? widget.initialPlace : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final planning = widget.mode == V8Mode.plan;
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7FA),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 660;
            return Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(12, compact ? 8 : 12, 16, compact ? 11 : 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF073A79), Color(0xFF0B5FD7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(26),
                      bottomRight: Radius.circular(26),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton.filled(
                        onPressed: _home,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .16),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.home_rounded),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              planning ? 'PIANIFICA' : 'INIZIA',
                              style: const TextStyle(
                                color: Color(0xFF9DD2FF),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.4,
                              ),
                            ),
                            Text(
                              'Cosa vuoi fare?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: compact ? 23 : 26,
                                height: 1.05,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (planning && (widget.initialPlace ?? '').isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                widget.initialPlace!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFEAF4FF),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, compact ? 10 : 14, 14, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.separated(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => SizedBox(height: compact ? 7 : 9),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final selected = _choice == item.$1;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => setState(() => _choice = item.$1),
                                  borderRadius: BorderRadius.circular(18),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 140),
                                    height: compact ? 58 : 66,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      gradient: selected
                                          ? LinearGradient(
                                              colors: [item.$3, item.$3.withValues(alpha: .82)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            )
                                          : const LinearGradient(
                                              colors: [Colors.white, Color(0xFFF7FAFC)],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: selected ? item.$3 : const Color(0xFFD8E3EA),
                                        width: selected ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selected
                                              ? item.$3.withValues(alpha: .22)
                                              : const Color(0x140A2132),
                                          blurRadius: selected ? 12 : 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: compact ? 39 : 44,
                                          height: compact ? 39 : 44,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? Colors.white.withValues(alpha: .20)
                                                : item.$3.withValues(alpha: .13),
                                            borderRadius: BorderRadius.circular(13),
                                          ),
                                          child: Icon(
                                            item.$2,
                                            color: selected ? Colors.white : item.$3,
                                            size: compact ? 22 : 25,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            item.$1,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: compact ? 14.5 : 16,
                                              fontWeight: FontWeight.w900,
                                              color: selected ? Colors.white : _ink,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                                          color: selected ? Colors.white : const Color(0xFF9AA8B3),
                                          size: 23,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(14, 3, 14, compact ? 9 : 13),
                  child: SizedBox(
                    width: double.infinity,
                    height: compact ? 50 : 55,
                    child: FilledButton.icon(
                      onPressed: _choice == null ? null : _continue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                      label: Text(
                        _choice == null ? 'SCEGLI COSA VUOI FARE' : 'AVANTI',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        disabledBackgroundColor: const Color(0xFFD8E0E5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                      ),
                    ),
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
