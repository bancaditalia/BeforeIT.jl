@component struct Employed <: AbstractComponent
    rate::Float64
end

@component struct Inactive <: AbstractComponent end

@component struct Unemployed <: AbstractComponent
    unemployment_benefits::Float64
end
