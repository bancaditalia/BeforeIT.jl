module BeforeITMooncake

import BeforeIT as Bit
import Mooncake
import Random

Mooncake.@zero_derivative Mooncake.MinimalCtx Tuple{typeof(Bit.create_weighted_sampler), Any, Any, Any}

# The seller sampler carries no derivative (see above), so neither do drawing a seller from
# it nor zeroing a seller's weight. Without these rules Mooncake records every draw of the
# goods markets on its tape.
Mooncake.@zero_derivative Mooncake.MinimalCtx Tuple{
    typeof(Bit.WeightVectors._rand), Random.AbstractRNG, Memory{UInt64},
}
Mooncake.@zero_derivative Mooncake.MinimalCtx Tuple{
    typeof(Bit.WeightVectors._setindex!), Memory{UInt64}, Float64, Int,
}

end
