import 'dart:math' as math;
import 'package:meta/meta.dart';

/// Represents a point in 3D space for the neural simulation.
@immutable
class Offset3D {
  final double x;
  final double y;
  final double z;

  const Offset3D(this.x, this.y, this.z);
}

/// Represents the result of a 3D to 2D projection.
@immutable
class ProjectedPoint {
  final double x;
  final double y;
  final double scale;
  final double zDepth;

  const ProjectedPoint(this.x, this.y, this.scale, this.zDepth);
}

/// Utility class for projecting 3D neural coordinates onto a 2D screen.
/// 
/// It uses isometric projection with perspective divide and supports 
/// rotation around X and Y axes.
class Neural3DProjection {
  /// Biologically-inspired 3D coordinates for the cerebellar microcircuit.
  /// 
  /// Coordinates are normalized around (0,0,0):
  /// - X axis: Lateral separation
  /// - Y axis: Vertical layers (Molecular Top +Y, Deep Bottom -Y)
  /// - Z axis: Depth (Anterior/Posterior)
  static const Map<String, Offset3D> kNeuronPositions = {
    'CF_01': Offset3D(-1.2, -1.0, 0.0),
    'GC_01': Offset3D(-0.4, -0.6, 0.8),
    'BC_01': Offset3D(0.2, 0.8, -0.5),
    'PC_01': Offset3D(0.8, 0.2, 0.0),
    'DCN_01': Offset3D(1.8, -1.2, 0.0),
  };

  /// Projects an [Offset3D] into a [ProjectedPoint] based on view parameters.
  /// 
  /// [rotX] and [rotY] are rotation angles in radians.
  /// [zoom] controls the field of view/scaling.
  /// [centerX] and [centerY] define the screen origin.
  static ProjectedPoint project(
    Offset3D point, {
    required double rotX,
    required double rotY,
    required double zoom,
    required double centerX,
    required double centerY,
  }) {
    // 1. Rotate around Y axis (Yaw)
    final double cosY = math.cos(rotY);
    final double sinY = math.sin(rotY);
    double x1 = point.x * cosY + point.z * sinY;
    double y1 = point.y;
    double z1 = -point.x * sinY + point.z * cosY;

    // 2. Rotate around X axis (Pitch)
    final double cosX = math.cos(rotX);
    final double sinX = math.sin(rotX);
    double x2 = x1;
    double y2 = y1 * cosX - z1 * sinX;
    double z2 = y1 * sinX + z1 * cosX;

    // 3. Perspective Divide
    // S = zoom / (z + 4.0)
    final double scale = zoom / (z2 + 4.0);

    // 4. Screen Mapping
    // In our biological model, Y+ is Up. 
    // In Flutter, Y+ is Down, so we subtract projected Y from centerY.
    final double screenX = x2 * scale + centerX;
    final double screenY = centerY - y2 * scale;

    return ProjectedPoint(screenX, screenY, scale, z2);
  }
}
