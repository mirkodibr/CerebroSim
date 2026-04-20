/// Represents the different simulation tasks supported by the cerebellar model.
enum CerebellarTask {
  /// A classic associative learning task involving blinking in response to a stimulus.
  eyeblink,
  /// A task where the system learns to predict or track a sine wave signal.
  sineWave,
  /// Vestibulo-Ocular Reflex (VOR) task, simulating the stabilization of gaze during head movement.
  vor,
  /// A complex 2D motor control task where the agent must move an arm to a target.
  armReaching
}

extension CerebellarTaskDisplay on CerebellarTask {
  String get displayName {
    switch (this) {
      case CerebellarTask.eyeblink:
        return 'Eyeblink Conditioning';
      case CerebellarTask.sineWave:
        return 'Sine Wave Tracking';
      case CerebellarTask.vor:
        return 'VOR Adaptation';
      case CerebellarTask.armReaching:
        return '2D Arm Reaching';
    }
  }

  String get shortName {
    switch (this) {
      case CerebellarTask.eyeblink:
        return 'EYEBLINK';
      case CerebellarTask.sineWave:
        return 'SINE';
      case CerebellarTask.vor:
        return 'VOR';
      case CerebellarTask.armReaching:
        return 'ARM';
    }
  }
}
