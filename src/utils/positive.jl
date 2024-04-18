export pos, neg, round
"""
    pos(vector) -> vector

Returns new vector such that all the NaN and negative values in `vector` to zero.
Mimicks max(0, vector) in Matlab. If vector is a scalar returns a scalar.

# Example
```jldoctest
julia> vector = [1, 2, 3, NaN, -1 ]

julia> pos(vector)
5-element Vector{Float64}:
 1.0
 2.0
 3.0
 0.0
 0.0
```
"""
function pos(vector::AbstractArray)
    T = typeof(vector[1])
    r = copy(vector)
    for i in eachindex(r)
        if isnan(r[i]) || r[i] < zero(T)
            r[i] = zero(T)
        end
    end
    return r
end

function pos(number::T) where {T <: Number}
    if isnan(number) || number < zero(T)
        return zero(T)
    else
        return number
    end
end

"""
    neg(vector) -> vector

Returns new vector such that all the NaN and positive values in `vector` to zero.
Mimicks min(0, vector) in Matlab. If vector is a scalar returns a scalar.

# Example
```jldoctest
julia> vector = [1, 2, 3, NaN, -1 ]

julia> neg(vector)
5-element Vector{Float64}:
0.0
0.0
0.0
0.0
-1.0
```
"""
function neg(vector::AbstractArray)
    # @show neg
    T = typeof(vector[1])
    r = copy(vector)
    for i in eachindex(r)
        if isnan(r[i]) || r[i] > zero(T)
            r[i] = zero(T)
        end
    end
    return r
end

function neg(number::T) where {T <: Number}
    if isnan(number) || number > zero(T)
        return zero(T)
    else
        return number
    end
end

# like in the original code
function round(x)
    return Base.round(x, RoundNearestTiesUp)
end

# function round.(x)
#     return Base.round.(x + SMALL_FLOAT)
# end    
