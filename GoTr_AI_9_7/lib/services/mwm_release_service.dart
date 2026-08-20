import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class MwmReleaseAsset {
  final String name;
  final String url;
  final int size;

  const MwmReleaseAsset({
    required this.name,
    required this.url,
    required this.size,
  });

  factory MwmReleaseAsset.fromJson(Map<String, dynamic> json) {
    return MwmReleaseAsset(
      name: json['name']?.toString() ?? '',
      url: json['browser_download_url']?.toString() ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
    );
  }
}

class _MapArea {
  final String token;
  final double lat;
  final double lon;
  const _MapArea(this.token, this.lat, this.lon);
}

class MwmReleaseService {
  MwmReleaseService._();
  static final instance = MwmReleaseService._();

  static const repository = 'marichr1975-dot/nuove-mappe';
  static const releaseTag = 'organic-test-mwm-v1';
  static const apiUrl =
      'https://api.github.com/repos/$repository/releases/tags/$releaseTag';

  static const _areas = <_MapArea>[
    _MapArea('Italy_Veneto_Belluno', 46.14, 12.22),
    _MapArea('Italy_Veneto_Treviso', 45.67, 12.24),
    _MapArea('Italy_Veneto_Venezia', 45.44, 12.33),
    _MapArea('Italy_Veneto_Vicenza', 45.55, 11.55),
    _MapArea('Italy_Veneto_Padova', 45.41, 11.88),
    _MapArea('Italy_Veneto_Verona', 45.44, 10.99),
    _MapArea('Italy_Veneto_Rovigo', 45.07, 11.79),
    _MapArea('Italy_Friuli-Venezia Giulia_Udine', 46.06, 13.24),
    _MapArea('Italy_Friuli-Venezia Giulia_Pordenone', 45.96, 12.66),
    _MapArea('Italy_Friuli-Venezia Giulia_Gorizia', 45.94, 13.62),
    _MapArea('Italy_Friuli-Venezia Giulia_Trieste', 45.65, 13.77),
    _MapArea('Italy_Trentino-Alto Adige Sudtirol', 46.50, 11.35),
  ];

  List<MwmReleaseAsset>? _cache;

  Future<Directory> mapsDirectory() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}${Platform.pathSeparator}gotr_maps');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<MwmReleaseAsset>> catalog({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: const {
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'GoTr-AI-V10',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception('Server mappe non disponibile (HTTP ${response.statusCode}).');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['assets'] is! List) {
      throw Exception('Catalogo mappe non valido.');
    }

    final assets = <MwmReleaseAsset>[];
    for (final raw in decoded['assets'] as List) {
      if (raw is! Map) continue;
      final asset = MwmReleaseAsset.fromJson(Map<String, dynamic>.from(raw));
      if (asset.name.toLowerCase().endsWith('.mwm') && asset.url.isNotEmpty) {
        assets.add(asset);
      }
    }
    if (assets.isEmpty) throw Exception('Nessuna mappa MWM trovata nella Release.');
    assets.sort((a, b) => a.name.compareTo(b.name));
    _cache = assets;
    return assets;
  }

  Future<MwmReleaseAsset?> assetForPoint(LatLng point) async {
    if (point.latitude < 44.6 ||
        point.latitude > 47.2 ||
        point.longitude < 10.3 ||
        point.longitude > 14.1) {
      return null;
    }

    _MapArea? best;
    var bestDistance = double.infinity;
    for (final area in _areas) {
      final dLat = point.latitude - area.lat;
      final dLon = (point.longitude - area.lon) *
          math.cos(point.latitude * math.pi / 180.0);
      final d = dLat * dLat + dLon * dLon;
      if (d < bestDistance) {
        bestDistance = d;
        best = area;
      }
    }
    if (best == null) return null;

    final assets = await catalog();
    final token = _normalize(best.token);
    for (final asset in assets) {
      if (_normalize(asset.name).contains(token)) return asset;
    }
    return null;
  }

  Future<MwmReleaseAsset?> findByText(String text) async {
    final q = _normalize(text);
    if (q.isEmpty) return null;
    final assets = await catalog();

    for (final asset in assets) {
      if (_normalize(asset.name).contains(q)) return asset;
    }

    const aliases = <String, List<String>>{
      'Italy_Veneto_Belluno': [
        'belluno','auronzo','misurina','cortina','zoldo','pecol','alleghe',
        'selva di cadore','arabba','falcade','agordo','longarone','feltre',
        'pieve di cadore','san vito di cadore','borca di cadore'
      ],
      'Italy_Veneto_Venezia': ['venezia','mestre','mira','spinea','jesolo','chioggia'],
      'Italy_Veneto_Padova': ['padova','abano','este','monselice'],
      'Italy_Veneto_Treviso': ['treviso','asolo','vittorio veneto','conegliano'],
      'Italy_Veneto_Vicenza': ['vicenza','asiago','bassano','recoaro'],
      'Italy_Veneto_Verona': ['verona','malcesine','garda','lessinia'],
      'Italy_Veneto_Rovigo': ['rovigo','adria'],
      'Italy_Friuli-Venezia Giulia_Udine': ['udine','tarvisio','tolmezzo','sappada'],
      'Italy_Friuli-Venezia Giulia_Pordenone': ['pordenone'],
      'Italy_Friuli-Venezia Giulia_Gorizia': ['gorizia'],
      'Italy_Friuli-Venezia Giulia_Trieste': ['trieste'],
      'Italy_Trentino-Alto Adige Sudtirol': [
        'trento','bolzano','merano','bressanone','brunico','bruneck',
        'canazei','moena','ortisei','selva val gardena'
      ],
    };

    for (final entry in aliases.entries) {
      if (entry.value.any((p) => q.contains(_normalize(p)))) {
        final token = _normalize(entry.key);
        for (final asset in assets) {
          if (_normalize(asset.name).contains(token)) return asset;
        }
      }
    }
    return null;
  }

  Future<bool> isInstalled(MwmReleaseAsset asset) async {
    final dir = await mapsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    if (!await file.exists()) return false;
    final length = await file.length();
    return length > 100000 && (asset.size <= 0 || length == asset.size);
  }

  Future<File> download(
    MwmReleaseAsset asset, {
    void Function(int received, int total)? onProgress,
  }) async {
    final dir = await mapsDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    final temp = File('${target.path}.download');
    if (await temp.exists()) await temp.delete();

    final client = http.Client();
    IOSink? sink;
    try {
      final request = http.Request('GET', Uri.parse(asset.url));
      request.headers['User-Agent'] = 'GoTr-AI-V10';
      request.headers['Accept-Encoding'] = 'identity';
      final response = await client.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) {
        throw Exception('Download ${asset.name}: HTTP ${response.statusCode}');
      }

      final total = response.contentLength ?? asset.size;
      var received = 0;
      sink = temp.openWrite();
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;

      final length = await temp.length();
      if (length < 100000) throw Exception('Mappa ${asset.name} incompleta.');
      if (asset.size > 0 && length != asset.size) {
        throw Exception('Mappa ${asset.name} incompleta: $length / ${asset.size} byte.');
      }

      if (await target.exists()) await target.delete();
      return temp.rename(target.path);
    } finally {
      try { await sink?.close(); } catch (_) {}
      client.close();
      if (await temp.exists()) {
        try { await temp.delete(); } catch (_) {}
      }
    }
  }

  Future<File?> ensureForPoint(
    LatLng point, {
    void Function(int received, int total)? onProgress,
  }) async {
    final asset = await assetForPoint(point);
    if (asset == null) return null;
    final dir = await mapsDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    if (await isInstalled(asset)) return target;
    return download(asset, onProgress: onProgress);
  }

  Future<File?> ensureForText(
    String text, {
    void Function(int received, int total)? onProgress,
  }) async {
    final asset = await findByText(text);
    if (asset == null) return null;
    final dir = await mapsDirectory();
    final target = File('${dir.path}${Platform.pathSeparator}${asset.name}');
    if (await isInstalled(asset)) return target;
    return download(asset, onProgress: onProgress);
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll('.mwm', '')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}
