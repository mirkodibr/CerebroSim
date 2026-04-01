/// A map providing human-readable descriptions for different cerebellar cell types.
///
/// These descriptions explain the functional role of each neuron in the cerebellar
/// circuit simulation, such as relaying signals, providing inhibition, or carrying
/// error information.
const Map<String, String> kCellTypeDescriptions = {
  /// Granule cell: receives and relays sensory signals from the mossy fibers.
  'GC': 'Granule cell: receives and relays sensory signals from the mossy fibers.',
  /// Purkinje cell: the output of the cerebellar cortex, controlling movement correction.
  'PC': 'Purkinje cell: the output of the cerebellar cortex, controlling movement correction.',
  /// Basket cell: provides lateral inhibition to sharpen Purkinje cell signals.
  'BC': 'Basket cell: provides lateral inhibition to sharpen Purkinje cell signals.',
  /// Deep Cerebellar Nucleus: sends the final correction signals to the motor system.
  'DCN': 'Deep Cerebellar Nucleus: sends the final correction signals to the motor system.',
  /// Climbing Fibre: carries strong error signals from the inferior olive to the Purkinje cells.
  'CF': 'Climbing Fibre: carries strong error signals from the inferior olive to the Purkinje cells.',
  /// Stellate Cell: provides feed-forward inhibition to the Purkinje cells.
  'SC': 'Stellate Cell: provides feed-forward inhibition to the Purkinje cells.',
};
