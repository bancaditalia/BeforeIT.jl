abstract type AbstractCache end
mutable struct DesiredIntermediatesCache <: AbstractCache
    vals::Matrix{Float64}
    nominal::Matrix{Float64}
    indices::Vector{Ark.Entity}
    current_index::Int64
end

mutable struct DesiredHouseholdConsumptionCache <: AbstractCache
    vals::Matrix{Float64}
    nominal::Matrix{Float64}
    indices::Vector{Ark.Entity}
    current_index::Int64
end

function emblace!(val, entity, cache::T) where {T <: AbstractCache}
    cache.vals[:, cache.current_index] .= val
    cache.indices[cache.current_index] = entity
    cache.current_index += 1
    return nothing
end

function reset_cache!(cache::T) where {T <: AbstractCache}
    cache.current_index = 1
    cache.nominal .= 0.0
    return nothing
end

function (::Type{T})(vals::Matrix{Float64}) where {T <: AbstractCache}
    return T(vals, zeros(size(vals)), fill(Ark.zero_entity, size(vals, 2)), 1)
end
