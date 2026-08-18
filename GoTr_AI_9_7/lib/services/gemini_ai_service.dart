import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class AiTrailRequest {
  final String activity;
  final String place;
  final double? latitude;
  final double? longitude;
  final String distance;
  final String difficulty;
  final bool dog;
  final bool children;
  final bool forest;
  final bool rock;
  final bool loop;

  const AiTrailRequest({
    required this.activity,
    required this.place,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.difficulty,
    required this.dog,
    required this.children,
    required this.forest,
    required this.rock,
    required this.loop,
  });
}

class AiTrailSuggestion {
  final String title;
  final String summary;
  final String routeType;
  final String difficulty;
  final String distance;
  final List<String> reasons;
  final List<String> cautions;

  const AiTrailSuggestion({
    required this.title,
    required this.summary,
    required this.routeType,
    required this.difficulty,
    required this.distance,
    required this.reasons,
    required this.cautions,
  });

  factory AiTrailSuggestion.fromJson(Map<String, dynamic> json) {
    List<String> strings(dynamic value) => value is List
        ? value.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    return AiTrailSuggestion(
      title: json['title']?.toString() ?? 'Proposta GoTr-AI',
      summary: json['summary']?.toString() ?? '',
      routeType: json['route_type']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? '',
      distance: json['distance']?.toString() ?? '',
      reasons: strings(json['reasons']),
      cautions: strings(json['cautions']),
    );
  }
}

class GeminiAiService {
  GeminiAiService._();
  static final instance = GeminiAiService._();

  static const _apiKey = String.fromEnvironment('GEMINI_API_KEY');
  // Flash-Lite è ottimizzato da Google per bassa latenza: qui serve una
  // scelta breve e strutturata, non ragionamento lungo.
  static const _model = 'gemini-3.5-flash-lite';

  bool get configured => _apiKey.trim().isNotEmpty;

  Future<AiTrailSuggestion> suggest(AiTrailRequest request) async {
    if (!configured) {
      throw Exception(
        'Gemini non configurato. Avvia Flutter con --dart-define=GEMINI_API_KEY=...',
      );
    }

    final position = request.latitude == null || request.longitude == null
        ? 'coordinate non disponibili'
        : '${request.latitude!.toStringAsFixed(6)}, ${request.longitude!.toStringAsFixed(6)}';

    final prompt = '''
Sei il motore AI di GoTr-AI, app per escursionisti non esperti.
Devi interpretare le preferenze dell'utente e proporre un PROFILO DI PERCORSO prudente.
Non inventare numeri di sentiero, rifugi, fontane, cascate o nomi di luoghi non presenti nei dati forniti.
Non affermare che un percorso reale esiste: la geometria verrà verificata dalla mappa offline di GoTr-AI nel passo successivo.
Se ci sono bambini o cane, privilegia sicurezza, pendenze moderate, fondo semplice e possibilità di rientro.
Rispondi esclusivamente nel JSON richiesto.

DATI UTENTE:
- attività: ${request.activity}
- zona: ${request.place}
- posizione: $position
- distanza desiderata: ${request.distance}
- difficoltà: ${request.difficulty}
- cane: ${request.dog}
- bambini: ${request.children}
- bosco: ${request.forest}
- roccia: ${request.rock}
- anello: ${request.loop}
''';

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent',
    );

    final response = await http
        .post(
          uri,
          headers: {
            'x-goog-api-key': _apiKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 450,
              'responseMimeType': 'application/json',
              'responseJsonSchema': {
                'type': 'object',
                'properties': {
                  'title': {'type': 'string'},
                  'summary': {'type': 'string'},
                  'route_type': {'type': 'string'},
                  'difficulty': {'type': 'string'},
                  'distance': {'type': 'string'},
                  'reasons': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  },
                  'cautions': {
                    'type': 'array',
                    'items': {'type': 'string'}
                  }
                },
                'required': [
                  'title',
                  'summary',
                  'route_type',
                  'difficulty',
                  'distance',
                  'reasons',
                  'cautions'
                ]
              }
            }
          }),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw TimeoutException(
            'Gemini non ha risposto entro 60 secondi. Controlla la connessione e riprova.',
          ),
        );

    if (response.statusCode != 200) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['error'] is Map) {
          detail = (decoded['error'] as Map)['message']?.toString() ?? detail;
        }
      } catch (_) {}
      throw Exception('Gemini HTTP ${response.statusCode}: $detail');
    }

    final decoded = jsonDecode(response.body);
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw Exception('Gemini non ha restituito una proposta.');
    }
    final content = candidates.first['content'];
    final parts = content is Map ? content['parts'] : null;
    if (parts is! List || parts.isEmpty || parts.first['text'] == null) {
      throw Exception('Risposta Gemini non leggibile.');
    }

    final raw = parts.first['text'].toString();
    final json = jsonDecode(raw);
    if (json is! Map) throw Exception('Risposta Gemini non valida.');
    return AiTrailSuggestion.fromJson(Map<String, dynamic>.from(json));
  }
}
