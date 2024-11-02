using BeforeIT, MAT
using Test

import BeforeIT: randpl, epsilon, wsample_single
import Random: shuffle!, rand, randn
using Distributions

function randn()
    return 0.0
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

function wsample_single(v::UnitRange{Int64}, w::Vector{Float64}, wsum)
    return v[1]
end

function wsample_single_2(v::UnitRange{Int64}, w::Vector{Float64}, wmax)
    return v[1]
end

