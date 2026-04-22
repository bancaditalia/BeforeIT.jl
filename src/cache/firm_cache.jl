# Resource you add once at init (size = n_products)
struct FirmTmpBuffers{T}
    sector_production_cost::Vector{T}
end
