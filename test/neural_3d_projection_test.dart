import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/services/neural_3d_projection.dart';

void main() {
  group('Neural3DProjection', () {
    test('CF position at zero rotation', () {
      final cfPos = Neural3DProjection.kNeuronPositions['CF_01']!;
      final projected = Neural3DProjection.project(
        cfPos,
        rotX: 0.0,
        rotY: 0.0,
        zoom: 120.0,
        centerX: 200.0,
        centerY: 200.0,
      );

      // CF at (-1.2, -1.0, 0.0)
      // Scale = 120 / (0 + 4) = 30
      // screenX = -1.2 * 30 + 200 = 164
      // screenY = 200 - (-1.0 * 30) = 230
      expect(projected.x, closeTo(164.0, 5.0));
      expect(projected.y, closeTo(230.0, 5.0));
    });

    test('Rotation changes projection results', () {
      final gcPos = Neural3DProjection.kNeuronPositions['GC_01']!;
      final zeroRot = Neural3DProjection.project(
        gcPos,
        rotX: 0.0,
        rotY: 0.0,
        zoom: 120.0,
        centerX: 200.0,
        centerY: 200.0,
      );

      final withRot = Neural3DProjection.project(
        gcPos,
        rotX: 0.5,
        rotY: 0.5,
        zoom: 120.0,
        centerX: 200.0,
        centerY: 200.0,
      );

      expect(zeroRot.x, isNot(withRot.x));
      expect(zeroRot.y, isNot(withRot.y));
    });

    test('Zoom affects scale and position', () {
      final pcPos = Neural3DProjection.kNeuronPositions['PC_01']!;
      final zoom100 = Neural3DProjection.project(
        pcPos,
        rotX: 0.0,
        rotY: 0.0,
        zoom: 100.0,
        centerX: 200.0,
        centerY: 200.0,
      );

      final zoom200 = Neural3DProjection.project(
        pcPos,
        rotX: 0.0,
        rotY: 0.0,
        zoom: 200.0,
        centerX: 200.0,
        centerY: 200.0,
      );

      expect(zoom200.scale, equals(zoom100.scale * 2.0));
    });

    test('Verify all initial neurons have 3D positions', () {
      final expectedKeys = ['GC_01', 'PC_01', 'BC_01', 'DCN_01', 'CF_01'];
      for (final key in expectedKeys) {
        expect(Neural3DProjection.kNeuronPositions.containsKey(key), true, 
            reason: 'Position for $key missing');
      }
    });
  });
}
