using BeforeIT, MAT
using Test

import BeforeIT: randpl, epsilon
import DynamicSampling: DynamicSampler, IndexInfo, getlevel, allvalues
import Random: shuffle!, rand, randn
import StatsBase: wsample
using Distributions

function allinds(s::DynamicSampler)
    return sort!(reduce(vcat, s.level_buckets))
end

function randn()
    return 0.0
end

function rand(s::DynamicSampler; info=true)
    idx = minimum(minimum.(s.level_buckets; init=typemax(Int)))
    weight = s.weights[idx]
    level = getlevel(first(s.level_inds), weight)
    idx_in_level = findfirst(x -> x == idx, s.level_buckets[level])
    return IndexInfo(idx, weight, level, idx_in_level)
end
function rand(n::UnitRange)
    return 1
end
function rand(n::Normal)
    return 0.0
end
function randpl(n::Int, alpha::Float64, N::Int)
    # return a vector of n numbers that sum to N
    to_return = [Int(round(N / n + 1e-7)) for _ in 1:n]
    return to_return
end
function epsilon(C::Matrix{Float64})
    return 0.0, 0.0, 0.0
end
function shuffle!(v::Vector)
    # do nothing 
end

function wsample(v::UnitRange{Int64}, w::Vector{Float64})
    return v[1]
end
