import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/plot_point.dart';
import '../models/cerebellar_task.dart';
import '../providers/simulation_provider.dart';
import '../providers/environment_provider.dart';

class PlotBufferNotifier extends Notifier<List<PlotPoint>> {
  @override
  List<PlotPoint> build() => [];

  void addPoint(PlotPoint point) {
    final nextBuffer = List<PlotPoint>.from(state)..add(point);
    if (nextBuffer.length > 200) {
      nextBuffer.removeAt(0);
    }
    state = nextBuffer;
  }
}

final plotBufferProvider = NotifierProvider<PlotBufferNotifier, List<PlotPoint>>(() {
  return PlotBufferNotifier();
});

class SignalPlotter extends ConsumerWidget {
  const SignalPlotter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(simulationProvider);
    final task = ref.watch(environmentProvider);

    // Update buffer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newPoint = PlotPoint(
        criticPrediction: state.criticPrediction,
        actualSignal: state.climbingFiberSignal,
        gainRatio: state.rollingGainRatio,
      );
      
      ref.read(plotBufferProvider.notifier).addPoint(newPoint);
    });

    final buffer = ref.watch(plotBufferProvider);

    return Container(
      height: 180,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          _buildLegend(task),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: SignalPlotterPainter(buffer: buffer, isVor: task == CerebellarTask.vor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(CerebellarTask task) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem('Critic', const Color(0xFF00FFFF)),
        const SizedBox(width: 16),
        _legendItem('Actual', const Color(0xFFEF9F27)),
        if (task == CerebellarTask.vor) ...[
          const SizedBox(width: 16),
          _legendItem('Gain', const Color(0xFF8A2BE2)),
        ],
      ],
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }
}

class SignalPlotterPainter extends CustomPainter {
  final List<PlotPoint> buffer;
  final bool isVor;

  SignalPlotterPainter({required this.buffer, required this.isVor});

  @override
  void paint(Canvas canvas, Size size) {
    if (buffer.isEmpty) return;

    final paintCritic = Paint()..color = const Color(0xFF00FFFF)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final paintActual = Paint()..color = const Color(0xFFEF9F27)..strokeWidth = 2.0..style = PaintingStyle.stroke;
    final paintGain = Paint()..color = const Color(0xFF8A2BE2)..strokeWidth = 2.0..style = PaintingStyle.stroke;

    final pathCritic = Path();
    final pathActual = Path();
    final pathGain = Path();

    final double stepX = size.width / (buffer.length > 1 ? buffer.length - 1 : 1);
    
    for (int i = 0; i < buffer.length; i++) {
      final x = i * stepX;
      double mapY(double val) => size.height / 2 - (val * size.height / 2);

      if (i == 0) {
        pathCritic.moveTo(x, mapY(buffer[i].criticPrediction));
        pathActual.moveTo(x, mapY(buffer[i].actualSignal));
        pathGain.moveTo(x, mapY(buffer[i].gainRatio));
      } else {
        pathCritic.lineTo(x, mapY(buffer[i].criticPrediction));
        pathActual.lineTo(x, mapY(buffer[i].actualSignal));
        pathGain.lineTo(x, mapY(buffer[i].gainRatio));
      }
    }

    canvas.drawPath(pathCritic, paintCritic);
    canvas.drawPath(pathActual, paintActual);
    if (isVor) {
      canvas.drawPath(pathGain, paintGain);
    }
  }

  @override
  bool shouldRepaint(covariant SignalPlotterPainter oldDelegate) {
    return oldDelegate.buffer != buffer;
  }
}
