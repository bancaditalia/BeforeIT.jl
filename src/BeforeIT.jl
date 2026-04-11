module BeforeIT

import Base: length

using Ark
using LazyArrays
using LinearAlgebra
using MacroTools
using Preferences
using Quadmath
using Random
using StatsBase
using WeightVectors


include("components/components.jl")

include("model_init/init_properties.jl")
include("model_init/init_model.jl")
include("model_init/firms.jl")
include("model_init/workers.jl")
include("model_init/bank.jl")
include("model_init/government.jl")
include("model_init/rotw.jl")

include("utils/randpl.jl")

end
