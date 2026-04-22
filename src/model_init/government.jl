function setup_government!(world, properties::Properties)::Nothing
    (; consumption, debt, subsidies_inactive, subsidies_other) = properties.initial_conditions.government
    T_prime = properties.dimensions.interval_for_expectation_estimation
    local_governments = properties.dimensions.local_governments


    e = Ark.new_entity!(
        world, (
            Components.GovernmentRevenues(0.0),
            Components.ConsumptionDemand(consumption[T_prime]),
            Components.RealisedConsumption(0.0),
            Components.GovernmentDebt(debt),
            Components.SocialBenefitsInactive(subsidies_inactive),
            Components.SocialBenefitsOther(subsidies_other),
            Components.PriceInflationGovernmentGoods(0.0),
            Components.Government(),

        )
    )

    Ark.new_entities!(world, local_governments, (Components.ConsumptionDemand(0.0), Components.LocalGovernment()), relations = ((Components.LocalGovernment => e)))
    return nothing
end
