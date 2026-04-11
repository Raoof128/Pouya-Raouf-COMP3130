import 'package:flutter_test/flutter_test.dart';
import 'package:mq_navigation/features/map/data/mappers/campus_projection_impl.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_overlay_meta.dart';
import 'package:mq_navigation/features/map/domain/entities/campus_point.dart';

void main() {
  const meta = CampusOverlayMeta(
    imageAsset: 'assets/maps/mq-campus.png',
    width: 100,
    height: 80,
    pixelBounds: CampusPixelBounds(south: 0, west: 0, north: 80, east: 100),
    buildingPixelOffsetX: 10,
    gpsNorth: 1,
    gpsSouth: 0,
    gpsEast: 1,
    gpsWest: 0,
    initialFitPadding: 20,
    minZoomOffset: 1.5,
    maxZoom: 3,
    gpsProjection: CampusGpsProjection(
      method: 'gcp_affine',
      affine: CampusAffineProjection(
        x: [0, 100, 0],
        y: [0, 0, 80],
        normalization: CampusAffineNormalization(
          minLat: 0,
          maxLat: 1,
          minLng: 0,
          maxLng: 1,
        ),
      ),
    ),
  );

  const projection = CampusProjectionImpl(meta);

  test('building pixels apply the shared marker offset only to markers', () {
    const point = CampusPoint(x: 20, y: 30);

    final routeMapPoint = projection.pixelToMapPoint(point);
    final buildingMapPoint = projection.buildingPixelToMapPoint(point);

    expect(routeMapPoint.latitude, 50);
    expect(routeMapPoint.longitude, 20);
    expect(buildingMapPoint.latitude, 50);
    expect(buildingMapPoint.longitude, 30);
  });

  test('gps projection uses affine coefficients without building offset', () {
    final pixel = projection.gpsToPixel(latitude: 0.5, longitude: 0.25);
    final mapPoint = projection.gpsToMapPoint(latitude: 0.5, longitude: 0.25);

    expect(pixel.x, 25);
    expect(pixel.y, 40);
    expect(mapPoint.latitude, 40);
    expect(mapPoint.longitude, 25);
  });

  test('large campus assets normalize map-space bounds for flutter_map', () {
    const largeMeta = CampusOverlayMeta(
      imageAsset: 'assets/maps/mq-campus.png',
      width: 4678,
      height: 3307,
      pixelBounds: CampusPixelBounds(
        south: 0,
        west: 0,
        north: 3307,
        east: 4678,
      ),
      buildingPixelOffsetX: 80,
      gpsNorth: 1,
      gpsSouth: 0,
      gpsEast: 1,
      gpsWest: 0,
      initialFitPadding: 20,
      minZoomOffset: 1.5,
      maxZoom: 3,
    );
    const largeProjection = CampusProjectionImpl(largeMeta);

    final topLeft = largeProjection.pixelToMapPoint(
      const CampusPoint(x: 0, y: 0),
    );
    final bottomRight = largeProjection.pixelToMapPoint(
      const CampusPoint(x: 4678, y: 3307),
    );

    expect(largeMeta.mapNorth, lessThanOrEqualTo(85));
    expect(largeMeta.mapEast, lessThanOrEqualTo(170));
    expect(topLeft.latitude, largeMeta.mapNorth);
    expect(topLeft.longitude, 0);
    expect(bottomRight.latitude, 0);
    expect(bottomRight.longitude, largeMeta.mapEast);
  });
}
