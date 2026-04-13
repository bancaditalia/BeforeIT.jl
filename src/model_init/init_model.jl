abstract type AbstractModel end
struct ECSModel{CS <: Tuple, CT <: Tuple, ST <: Tuple, N, M} <: AbstractModel
    world::Ark.World{CS, CT, ST, N, M}
end

function ECSModel(parameters::Dict{String, Any}, init_conditions::Dict{String, Any})
    return ECSModel(Properties(parameters, init_conditions))
end

function ECSModel(properties::Properties)
    world = Ark.World(Components.COMPONENTS...)

    setup_firms!(world, properties)
    setup_workers!(world, properties)
    setup_bank!(world, properties)
    setup_central_bank!(world, properties)
    setup_government!(world, properties)
    setup_rotw!(world, properties)
    setup_aggregates!(world, properties)

    normalize_deposits_and_capital_stocks!(world)
    add_deposits_to_bank!(world)

    return ECSModel(world)
end

function normalize_deposits_and_capital_stocks!(world)
    total_disposable_income = @sum_over (income.amount for income in Ark.Query(world, (Components.NetDisposableIncome,)))


    for (_, capital, deposits) in Ark.Query(world, (Components.CapitalStock, Components.Deposits))
        capital.amount .= capital.amount ./ total_disposable_income
        deposits.amount .= deposits.amount ./ total_disposable_income
    end

    return nothing
end

function add_deposits_to_bank!(world)
    total_deposits = @sum_over (deposits.amount for deposits in Ark.Query(world, (Components.Deposits,)))

    for (e, b) in Ark.Query(world, (Components.ResidualItems,))
        b.amount .+= total_deposits
    end

    return
end

function properties(m::ECSModel)
    return Ark.get_resource(m.world, Properties)
end
