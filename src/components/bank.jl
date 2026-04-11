struct EquityCapital <: AbstractComponent
    amount::Float64
end

struct ResidualItems <: AbstractComponent
    amount::Float64
end

struct LendingRate <: AbstractComponent
    rate::Float64
end
