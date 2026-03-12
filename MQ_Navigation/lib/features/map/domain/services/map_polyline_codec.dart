import 'package:mq_navigation/features/map/domain/entities/route_leg.dart';

/// Decodes Google encoded polyline strings into point samples that both map
/// renderers can reuse.
abstract final class MapPolylineCodec {
  static List<LocationSample> decode(String encoded) {
    if (encoded.isEmpty) {
      return const <LocationSample>[];
    }

    final coordinates = <LocationSample>[];
    var index = 0;
    var latitude = 0;
    var longitude = 0;

    while (index < encoded.length) {
      var result = 0;
      var shift = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      latitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      result = 0;
      shift = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      longitude += (result & 1) != 0 ? ~(result >> 1) : result >> 1;

      coordinates.add(
        LocationSample(latitude: latitude / 1e5, longitude: longitude / 1e5),
      );
    }

    return coordinates;
  }
}
