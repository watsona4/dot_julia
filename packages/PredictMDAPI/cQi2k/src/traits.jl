abstract type TargetStyle end
struct UnknownTargetStyle <: TargetStyle end
struct MixedTargetStyle <: TargetStyle end
struct Regression <: TargetStyle end
struct Classification{N} <: TargetStyle end
const BinaryClassification = Classification{2}
