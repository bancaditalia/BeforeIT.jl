@component struct Employed <: AbstractComponent
    rate::FloatType
end
@component struct EmployedAt <: Ark.Relationship end

@component struct Inactive <: AbstractComponent end

@component struct Unemployed <: AbstractComponent
    unemployment_benefits::FloatType
end
