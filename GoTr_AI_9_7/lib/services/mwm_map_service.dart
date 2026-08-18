import 'dart:io';
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

/// V9.6 MWM ONLY
///
/// Questo servizio NON prova a reinventare il parser binario di Organic Maps.
/// Fa una verifica sicura e concreta del file .mwm installato sul telefono:
/// - lo trova nella cartella privata dell'app;
/// - verifica che sia leggibile e non vuoto;
/// - associa la mappa al GPS tramite l'area di test di Venezia.
///
/// Il parsing di sentieri/POI/routing arrivera' solo collegando il core Organic Maps.
class MwmMapService {
  MwmMapService._();
  static final instance = MwmMapService._();

  static const _veniceMinLat = 44.95;
  static const _veniceMaxLat = 45.85;
  static const _veniceMinLon = 11.70;
  static const _veniceMaxLon = 13.05;

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

  bool _pointIsInVeniceTestArea(LatLng p) {
    return p.latitude >= _veniceMinLat &&
        p.latitude <= _veniceMaxLat &&
        p.longitude >= _veniceMinLon &&
        p.longitude <= _veniceMaxLon;
  }

  Future<MwmMapInfo?> mapForPoint(LatLng point) async {
    final files = await installedFiles();
    if (files.isEmpty) return null;

    File? selected;
    String label = 'Mappa MWM';

    if (_pointIsInVeniceTestArea(point)) {
      for (final file in files) {
        final n = file.uri.pathSegments.last.toLowerCase();
        if (n.contains('venezia') || n.contains('venice')) {
          selected = file;
          label = 'Venezia';
          break;
        }
      }
    }

    // Fuori dall'area coperta, o se manca la MWM corretta, non usare una mappa a caso.
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
      regionLabel: label,
      sizeBytes: stat.size,
      headerReadable: headerReadable,
    );
  }

  Future<String> installPath() async => (await _mapsDir()).path;
}
