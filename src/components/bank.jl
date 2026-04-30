@component struct ResidualItems <: AbstractComponent
    amount::FloatType
end

@component struct LendingRate <: AbstractComponent
    rate::FloatType
end

@component struct Banker <: AbstractComponent end

@component struct Bank <: AbstractComponent end
