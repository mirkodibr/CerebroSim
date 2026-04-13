import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cerebrosim/widgets/neural_canvas.dart';

void main() {
  testWidgets('NeuralCanvas3D should render CustomPaint', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: NeuralCanvas3D(),
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
  });
}
