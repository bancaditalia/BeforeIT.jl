struct HiringFirmsCache
    vacancies::Vector{Int64}
    employment::Vector{Int64}
    indices::Dict{Ark.Entity, Int64}
    current_index::Int64
end

function emblace!(vacancies, employed, entity, cache::HiringFirmsCache)
    cache.vacancies[cache.current_index] = vacancies
    cache.employment[cache.current_index] = employed
    cache.indices[entity] = cache.current_index
    cache.current_index += 1
    return nothing
end

function HiringFirmsCache(size::Int64)
    return HiringFirmsCache(
        Vector{Int64}(undef, size),
        Vector{Int64}(undef, size),
        Dict{Ark.Entity, Int64}(),
        1,
    )
end
