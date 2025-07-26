
import BeforeIT as Bit

using Test

import DynamicSampling: DynamicSampler, allinds
import Random: shuffle!, rand, randn
import StatsBase: wsample
using Distributions

function randn()
    return 0.0
end

function rand(sp::Bit.WeightVectors.FixedSizeWeighVector)
    return findfirst(i -> !iszero(sp[i]), 1:length(sp))
end
function rand(n::UnitRange)
    return 1
end
function rand(n::Normal)
    return 0.0
end
function Bit.randpl(n::Int, alpha::Float64, N::Int)
    # return a vector of n numbers that sum to N
    to_return = [Int(round(N / n + 1e-7)) for _ in 1:n]
    return to_return
end
function Bit.epsilon(C::Matrix{Float64})
    return 0.0, 0.0, 0.0
end
function shuffle!(v::Vector)
    # do nothing 
end
function Bit.fshuffle!(v::Vector)
    # do nothing 
end
function Bit.ufilter!(cond, v::Vector)
    filter!(cond, v)
end
function wsample(v::UnitRange{Int64}, w::Vector{Float64})
    return v[1]
end
