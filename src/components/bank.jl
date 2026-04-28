@component struct ResidualItems <: AbstractComponent
    amount::Float64
end

@component struct LendingRate <: AbstractComponent
    rate::Float64
end

@component struct Banker <: AbstractComponent end

@component struct Bank <: AbstractComponent end
