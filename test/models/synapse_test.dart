import 'package:flutter_test/flutter_test.dart';
import 'package:cerebrosim/models/synapse.dart';

void main() {
  group('Synapse Model Tests', () {
    test('Synapse should be correctly initialized', () {
      const synapse = Synapse(
        sourceId: 'n1',
        targetId: 'n2',
        weight: 0.5,
        learningRate: 0.01,
        eligibilityTrace: 0.2,
        targetType: 'PC',
      );

      expect(synapse.sourceId, 'n1');
      expect(synapse.targetId, 'n2');
      expect(synapse.weight, 0.5);
      expect(synapse.learningRate, 0.01);
      expect(synapse.eligibilityTrace, 0.2);
      expect(synapse.targetType, 'PC');
    });

    test('Synapse should have default eligibilityTrace', () {
      const synapse = Synapse(
        sourceId: 'n1',
        targetId: 'n2',
        weight: 0.5,
        learningRate: 0.01,
        targetType: 'SC',
      );
      expect(synapse.eligibilityTrace, 0.0);
      expect(synapse.targetType, 'SC');
    });

    test('copyWith should return a new object with updated values', () {
      const synapse = Synapse(
        sourceId: 'n1',
        targetId: 'n2',
        weight: 0.5,
        learningRate: 0.01,
        targetType: 'PC',
      );

      final updatedSynapse = synapse.copyWith(
        weight: 0.6,
        eligibilityTrace: 0.3,
        targetType: 'SC',
      );

      expect(updatedSynapse.weight, 0.6);
      expect(updatedSynapse.eligibilityTrace, 0.3);
      expect(updatedSynapse.targetType, 'SC');
      expect(updatedSynapse.sourceId, synapse.sourceId);
      expect(updatedSynapse.targetId, synapse.targetId);
      expect(updatedSynapse.learningRate, synapse.learningRate);
    });

    test('toJson and fromJson should be consistent', () {
      const synapse = Synapse(
        sourceId: 'n1',
        targetId: 'n2',
        weight: 0.5,
        learningRate: 0.01,
        eligibilityTrace: 0.2,
        targetType: 'PC',
      );

      final json = synapse.toJson();
      final fromJson = Synapse.fromJson(json);

      expect(fromJson.sourceId, synapse.sourceId);
      expect(fromJson.targetId, synapse.targetId);
      expect(fromJson.weight, synapse.weight);
      expect(fromJson.learningRate, synapse.learningRate);
      expect(fromJson.eligibilityTrace, synapse.eligibilityTrace);
      expect(fromJson.targetType, synapse.targetType);
    });
  });
}
