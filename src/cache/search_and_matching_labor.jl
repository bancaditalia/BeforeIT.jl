struct HiringFirmsCache
    vacancies::Vector{Int64}
    active::Vector{Int64}
    employment::Vector{Int64}
    indices::Dict{Ark.Entity, Int64}
    current_index::Int64
    nhiring::Int64
end

function HiringFirmsCache(size::Int64)
    return HiringFirmsCache(
        Vector{Int64}(undef, size),
        Vector{Int64}(undef, size),
        Vector{Int64}(undef, size),
        Dict{Ark.Entity, Int64}(),
        1,
        1,
    )
end

function emblace!(vacancies, employed, entity, cache::HiringFirmsCache)
    cache.vacancies[cache.current_index] = vacancies
    cache.employment[cache.current_index] = employed
    if vacancies > 0
        cache.active[cache.nhiring] = cache.current_index
        cache.nhiring += 1
    end
    cache.indices[entity] = cache.current_index
    cache.current_index += 1
    return nothing
end

function reset_cache!(cache::HiringFirmsCache)
    cache.current_index = 1
    cache.nhiring = 1
    return nothing
end


struct UnemployedWorkersCache
    employed::Vector{Bool}
    newly_employed::Vector{Bool}
    employed_at::Vector{Ark.Entity}
    indices::Dict{Ark.Entity, Int64}
    current_index::Int64
end

function UnemployedWorkersCache(size::Int64)
    return UnemployedWorkersCache(
        Vector{Bool}(undef, size),
        Vector{Bool}(undef, size),
        Vector{Ark.Entity}(undef, size),
        Dict{Ark.Entity, Int64}(),
        1,
    )
end

function emblace_unemployed!(entity, cache::UnemployedWorkersCache)
    cache.employed[cache.current_index] = false
    cache.indices[entity] = cache.current_index
    cache.current_index += 1
    return nothing
end
