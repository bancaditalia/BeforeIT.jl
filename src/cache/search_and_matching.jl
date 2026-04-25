abstract type AbstractDemandCache end

mutable struct DesiredIntermediatesCache <: AbstractDemandCache
    vals::Matrix{Float64}
    nominal::Matrix{Float64}
    indices::Dict{Ark.Entity, Int64}
    current_index::Int64
end

mutable struct DesiredHouseholdConsumptionCache <: AbstractDemandCache
    vals::Matrix{Float64}
    nominal::Matrix{Float64}
    indices::Vector{Ark.Entity}
    current_index::Int64
end

function emblace!(val, entity, cache::T) where {T <: AbstractDemandCache}
    cache.vals[cache.current_index, :] .= val
    cache.indices[entity] = current_index
    cache.current_index += 1
    return nothing
end

function reset_cache!(cache::T) where {T <: AbstractDemandCache}
    cache.current_index = 1
    cache.nominal .= 0.0
    return nothing
end

function (::Type{T})(values::Int64, sectors::Int64) where {T <: AbstractDemandCache}
    return T(Matrix{Float64}(undef, values, sectors), zeros(values, sectors), Dict{Ark.Entity, Int64}(), 1)
end


mutable struct StockCache
    available_stocks::Vector{Float64}
    stock_capacity::Vector{Float64}
    prices::Vector{Float64}
    weights::Vector{Float64}
    sector::Vector{Int64}
    indices::Dict{Ark.Entity, Int64}
    current_index::Int64
    sector_offset::Vector{Int}
end

function StockCache(size::Int64, sectors::Int64)
    return StockCache(
        Vector{Float64}(undef, size),
        Vector{Float64}(undef, size),
        Vector{Float64}(undef, size),
        Vector{Float64}(undef, size),
        Vector{Int64}(undef, size),
        Dict{Ark.Entity, Int64}(),
        1,
        Vector{Int64}(undef, sectors + 1),
    )
end

function emblace!(available, stock_capacity, price, sector, entity, cache::StockCache)
    cache.available_stocks[cache.current_index] = available
    cache.stock_capacity[cache.current_index] = stock_capacity
    cache.prices[cache.current_index] = price
    cache.sector[cache.current_index] = sector
    cache.indices[entity] = cache.current_index
    cache.current_index += 1
    return nothing
end


function reset_cache!(cache::StockCache)
    cache.current_index = 1
    return nothing
end

function finalize_stock_cache!(cache::StockCache)

    p = sortperm(cache.sector)

    permute!(cache.available_stocks, p)
    permute!(cache.stock_capacity, p)
    permute!(cache.sector, p)
    permute!(cache.prices, p)


    invp = invperm(p)
    cache.indices = Dict{Ark.Entity, Int64}(e => invp[i] for (e, i) in cache.indices)

    prev_sector = -1
    for (i, sector) in enumerate(cache.sector)
        if sector != prev_sector
            cache.sector_offset[sector] = i
            prev_sector = sector
        end
    end

    cache.sector_offset[cache.sector[end] + 1] = length(cache.sector)

    @inbounds for i in 1:(length(cache.sector_offset) - 1)
        build_sampling_weights!(
            get_weights(cache, i),
            get_prices(cache, i),
            get_available_stocks(cache, i)
        )

    end

    return
end

function get_available_stocks(cache::StockCache, sector::Int64)
    return @view cache.available_stocks[cache.sector_offset[sector]:cache.sector_offset[sector + 1]]
end

function get_stock_capacity(cache::StockCache, sector::Int64)
    return @view cache.stock_capacity[cache.sector_offset[sector]:cache.sector_offset[sector + 1]]
end

function get_prices(cache::StockCache, sector::Int64)
    return @view cache.prices[cache.sector_offset[sector]:cache.sector_offset[sector + 1]]
end

function get_weights(cache::StockCache, sector::Int64)
    return @view cache.weights[cache.sector_offset[sector]:cache.sector_offset[sector + 1]]
end

function build_sampling_weights!(
        weights::AbstractVector{Float64},
        price::AbstractVector{Float64},
        stock::AbstractVector{Float64},
    )
    @assert length(weights) == length(price) == length(stock)
    price_sum = 0.0
    size_sum = 0.0
    @inbounds for i in eachindex(price, stock)
        wp = exp(-2.0 * price[i])
        ws = max(stock[i], 0.0)
        weights[i] = wp
        price_sum += wp
        size_sum += ws
    end
    inv_price_sum = price_sum > 0 ? inv(price_sum) : 0.0
    inv_size_sum = size_sum > 0 ? inv(size_sum) : 0.0
    @inbounds for i in eachindex(weights, price, stock)
        weights[i] = weights[i] * inv_price_sum + max(stock[i], 0.0) * inv_size_sum
    end
    return weights
end

function choose_random_firm(cache::StockCache, sector, weights)
    return rand(weights) + cache.sector_offset[sector]
end

function find_entity_index(entity, cache)
    return cache.indices[entity]
end
