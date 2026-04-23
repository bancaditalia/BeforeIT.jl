mutable struct DesiredSectorProductionCache
    vals::Matrix{Float64}
    indices::Vector{Ark.Entity}
    current_firm::Int64
end

function emblace_firm!(val, entity, cache::DesiredSectorProductionCache)
    cache.vals[:, cache.current_firm] .= val
    cache.indices[cache.current_firm] = entity
    cache.current_firm += 1
    return nothing
end

function reset_cache!(cache::DesiredSectorProductionCache)
    cache.current_firm = 1
    return nothing
end
