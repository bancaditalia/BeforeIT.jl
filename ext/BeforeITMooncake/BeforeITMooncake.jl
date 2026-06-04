module BeforeITMooncake

import BeforeIT as Bit
import Mooncake

Mooncake.@zero_derivative Mooncake.MinimalCtx Tuple{typeof(Bit.create_weighted_sampler), Any, Any, Any}

end
