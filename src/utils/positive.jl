export pos, neg, matlab_round
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

@inline function pos(x::T) where {T <: Number}
    return isnan(x) || x < zero(T) ? zero(T) : x
end

"""
    pos!(vector) -> vector

In-place version of `pos`. Mimicks max(0, vector) in Matlab. 
Returns the updated vector.
"""
function pos!(A)
    @simd for i in eachindex(A)
        A[i] = ifelse(isnan(A[i]), zero(eltype(A)), max(zero(eltype(A)), A[i]))
    end
    return A
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

@inline function neg(x::T) where {T <: Number}
    return isnan(x) || x > zero(T) ? zero(T) : x
end

"""
    neg!(vector) -> vector

In-place version of `neg`. Mimicks min(0, vector) in Matlab. 
Returns the updated vector.
"""
function neg!(A)
    @simd for i in eachindex(A)
        A[i] = ifelse(isnan(A[i]), zero(eltype(A)), min(zero(eltype(A)), A[i]))
    end
    return A
end

# like in the original code
function matlab_round(x)
    return Base.round(x, RoundNearestTiesUp)
end

# function round.(x)
#     return Base.round.(x + SMALL_FLOAT)
# end    
