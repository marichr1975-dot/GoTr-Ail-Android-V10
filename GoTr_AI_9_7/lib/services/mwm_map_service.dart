import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

class MwmMapInfo {
  final File file;
  final String regionLabel;
  final int sizeBytes;
  final bool headerReadable;

  const MwmMapInfo({
    required this.file,
    required this.regionLabel,
    required this.sizeBytes,
    required this.headerReadable,
  });

  String get sizeLabel => '${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
}

class _ProvinceMap {
  final String label;
  final String fileToken;
  final double lat;
  final double lon;

  const _ProvinceMap(this.label, this.fileToken, this.lat, this.lon);
}

/// V9.9 MWM ONLY
///
/// Se il punto cercato e' in Veneto, sceglie la MWM della provincia piu'
/// vicina fra quelle installate. In questo modo Pianifica usa Belluno per
/// Auronzo/Misurina/Cortina invece di limitarsi alla sola Venezia.
class MwmMapService {
  MwmMapService._();
  static final instance = MwmMapService._();

  static const _venetoMinLat = 44.72;
  static const _venetoMaxLat = 46.82;
  static const _venetoMinLon = 10.55;
  static const _venetoMaxLon = 13.15;

  static const List<_ProvinceMap> _venetoProvinces = [
    _ProvinceMap('Belluno', 'belluno', 46.14, 12.22),
    _ProvinceMap('Treviso', 'treviso', 45.67, 12.24),
    _ProvinceMap('Venezia', 'venezia', 45.44, 12.33),
    _ProvinceMap('Vicenza', 'vicenza', 45.55, 11.55),
    _ProvinceMap('Padova', 'padova', 45.41, 11.88),
    _ProvinceMap('Verona', 'verona', 45.44, 10.99),
    _ProvinceMap('Rovigo', 'rovigo', 45.07, 11.79),
  ];

  Future<Directory> _mapsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/gotr_maps');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<List<File>> installedFiles() async {
    final dir = await _mapsDir();
    final files = <File>[];
    await for (final entity in dir.list(followLinks: false)) {
      if (entity is File && entity.path.toLowerCase().endsWith('.mwm')) {
        files.add(entity);
      }
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  bool _isInVeneto(LatLng p) =>
      p.latitude >= _venetoMinLat &&
      p.latitude <= _venetoMaxLat &&
      p.longitude >= _venetoMinLon &&
      p.longitude <= _venetoMaxLon;

  double _distanceSq(LatLng p, _ProvinceMap province) {
    final dLat = p.latitude - province.lat;
    // Compensazione semplice della longitudine alla latitudine del Veneto.
    final dLon = (p.longitude - province.lon) * math.cos(p.latitude * math.pi / 180.0);
    return dLat * dLat + dLon * dLon;
  }

  _ProvinceMap? _nearestVenetoProvince(LatLng p) {
    if (!_isInVeneto(p)) return null;
    _ProvinceMap? best;
    var bestDistance = double.infinity;
    for (final province in _venetoProvinces) {
      final d = _distanceSq(p, province);
      if (d < bestDistance) {
        bestDistance = d;
        best = province;
      }
    }
    return best;
  }

  Future<MwmMapInfo?> mapForPoint(LatLng point) async {
    final files = await installedFiles();
    if (files.isEmpty) return null;

    final province = _nearestVenetoProvince(point);
    if (province == null) return null;

    File? selected;
    for (final file in files) {
      final name = file.uri.pathSegments.last.toLowerCase();
      if (name.contains('italy_veneto_') && name.contains(province.fileToken)) {
        selected = file;
        break;
      }
    }

    if (selected == null) return null;

    final stat = await selected.stat();
    bool headerReadable = false;
    try {
      final raf = await selected.open();
      final len = stat.size < 64 ? stat.size : 64;
      final Uint8List bytes = await raf.read(len);
      await raf.close();
      headerReadable = bytes.isNotEmpty && bytes.any((b) => b != 0);
    } catch (_) {
      headerReadable = false;
    }

    if (stat.size < 1024 * 1024 || !headerReadable) return null;

    return MwmMapInfo(
      file: selected,
      regionLabel: province.label,
      sizeBytes: stat.size,
      headerReadable: headerReadable,
    );
  }

  Future<String> installPath() async => (await _mapsDir()).path;
}

