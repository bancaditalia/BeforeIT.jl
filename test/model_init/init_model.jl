import BeforeIT as Bit
import Ark
using Test


@testset "Model initialization" begin
    model = Bit.ECSModel(Bit.STEADY_STATE2010Q1)

    world = model.world
    properties = Bit.properties(model)


    @testset "Population accounting" begin
        inactive_count = Ark.count_entities(Ark.Query(world, (Bit.Components.Inactive,)))
        unemployed_count = Ark.count_entities(Ark.Query(world, (Bit.Components.Unemployed,)))
        capitalist_count = Ark.count_entities(Ark.Query(world, (Bit.Components.Capitalist,)))
        firm_count = Ark.count_entities(Ark.Query(world, (Bit.Components.PrincipalProduct,)))

        @test inactive_count == properties.population.inactive
        @test unemployed_count == properties.population.active - properties.dimensions.total_firms - 1
        @test capitalist_count == properties.dimensions.total_firms
        @test firm_count == properties.dimensions.total_firms
    end

    @testset "Firm initialization invariants" begin
        for (e, _, output, sales, demand, price, inventories, vacancies, investment, equity) in Ark.Query(
                world,
                (
                    Bit.Components.PrincipalProduct,
                    Bit.Components.Output,
                    Bit.Components.Sales,
                    Bit.Components.GoodsDemand,
                    Bit.Components.Price,
                    Bit.Components.Inventories,
                    Bit.Components.Vacancies,
                    Bit.Components.Investment,
                    Bit.Components.Equity,
                )
            )
            @test all(output.amount .>= 0.0)
            @test all(sales.amount .== output.amount)
            @test all(demand.amount .== output.amount)
            @test all(price.value .== 1.0)
            @test all(inventories.amount .== 0.0)
            @test all(investment.amount .== 0.0)
            @test all(equity.amount .== 0.0)
            @test all(vacancies.amount .>= 0)
        end
    end

    @testset "Firm accounting identities" begin
        omega = properties.initial_conditions.firms.capacity_utilization

        for (_, _, output, capital, intermediates, employment, vacancies, labor_prod, capital_prod, material_prod) in Ark.Query(
                world,
                (
                    Bit.Components.PrincipalProduct,
                    Bit.Components.Output,
                    Bit.Components.CapitalStock,
                    Bit.Components.Intermediates,
                    Bit.Components.Employment,
                    Bit.Components.Vacancies,
                    Bit.Components.LaborProductivity,
                    Bit.Components.CapitalProductivity,
                    Bit.Components.IntermediateProductivity,
                )
            )
            @test isapprox.(output.amount, labor_prod.value .* employment.amount, atol = 1.0e-7) |> all
            @test isapprox.(capital.amount, output.amount ./ (omega .* capital_prod.value), atol = 1.0e-7) |> all
            @test isapprox.(intermediates.amount, output.amount ./ (omega .* material_prod.value), atol = 1.0e-7) |> all
            @test all(vacancies.amount .== employment.amount)
        end
    end

    @testset "Household initialization" begin
    end

    @testset "Rest-of-world initialization" begin
    end

    @testset "Macroeconomic resource initialization" begin
    end

    @testset "Sector aggregate initialization" begin
    end
end
