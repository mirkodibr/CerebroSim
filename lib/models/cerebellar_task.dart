/// Represents the different simulation tasks supported by the cerebellar model.
enum CerebellarTask {
  /// A classic associative learning task involving blinking in response to a stimulus.
  eyeblink,
  /// A task where the system learns to predict or track a sine wave signal.
  sineWave,
  /// Vestibulo-Ocular Reflex (VOR) task, simulating the stabilization of gaze during head movement.
  vor
}
