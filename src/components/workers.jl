@component struct Employed <: AbstractComponent
    wage::Float64
end
@component struct Inactive <: AbstractComponent end

@component struct Unemployed <: AbstractComponent
    unemployment_benefits::Float64
end
