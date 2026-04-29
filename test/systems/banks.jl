using Test
import Ark

include("old_actions/bank.jl")
@testset "Banking System Parity with Automated Setup" begin

    # --- Existing Test ---
    @testset "finance_insolvent_firms!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        I = properties.dimensions.total_firms
        test_L_i = fill(10.0, I)
        test_D_i = fill(5.0, I)
        test_E_i = fill(20.0, I)
        test_K_i = fill(20.0, I)

        test_D_i[2] = -5.0
        test_E_i[2] = -10.0

        mock_model = build_mock_model(
            properties;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            firms_E_i = test_E_i,
            firms_K_i = test_K_i,
            bank_E_k = 500.0
        )

        set_mock_components!(
            world;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            firms_E_i = test_E_i,
            firms_K_i = test_K_i,
            bank_E_k = 500.0
        )

        finance_insolvent_firms!(mock_model)
        Bit.finance_insolvent_firms!(world)

        ecs_bank_equity = Bit.single(Ark.Query(world, (Bit.Components.Equity,), with = (Bit.Components.Bank,)))[2].amount
        @test isapprox(ecs_bank_equity, mock_model.bank.E_k, atol = 1.0e-7)

        ecs_total_firm_equity = sum(sum(c.amount) for (_, c) in Ark.Query(world, (Bit.Components.Equity,), with = (Bit.Components.Output,)))
        @test isapprox(ecs_total_firm_equity, sum(mock_model.firms.E_i), atol = 1.0e-7)
    end

    # --- New Tests ---

    @testset "set_bank_deposits!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        I = properties.dimensions.total_firms
        test_L_i = fill(15.0, I)
        test_D_i = fill(5.0, I)

        H_act = properties.population.active
        H_inact = properties.population.inactive

        mock_model = build_mock_model(
            properties;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            bank_E_k = 1000.0,
            w_act_D_h = fill(0.0, H_act),
            w_inact_D_h = fill(0.0, H_inact),
            firms_D_h = fill(0.0, I),
            bank_D_h = 0.0
        )

        set_mock_components!(
            world;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            bank_E_k = 1000.0,
            w_act_D_h = fill(0.0, H_act),
            w_inact_D_h = fill(0.0, H_inact),
            firms_D_h = fill(0.0, I),
            bank_D_h = 0.0
        )

        set_bank_deposits!(mock_model)
        Bit.set_bank_deposits!(world)

        ecs_residual = Bit.single(Ark.Query(world, (Bit.Components.ResidualItems,), with = (Bit.Components.Bank,)))[2].amount
        @test isapprox(ecs_residual, mock_model.bank.D_k, atol = 1.0e-7)
    end

    @testset "set_bank_expected_profits!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        mock_model = build_mock_model(
            properties;
            bank_Pi_k = 150.0
        )

        # Override expectations in OOP mock
        mock_model.agg.pi_e = 0.05
        mock_model.agg.gamma_e = 0.02

        set_mock_components!(
            world;
            bank_Pi_k = 150.0
        )

        # Override expectations in ECS resource
        expectations = Ark.get_resource(world, Bit.Expectations)

        expectations.output_growth = 0.02
        expectations.inflation = 0.05

        set_bank_expected_profits!(mock_model)
        Bit.set_bank_expected_profits!(world)

        ecs_expected_profits = Bit.single(Ark.Query(world, (Bit.Components.ExpectedProfits,), with = (Bit.Components.Bank,)))[2].amount
        @test isapprox(ecs_expected_profits, mock_model.bank.Pi_e_k, atol = 1.0e-7)
    end

    @testset "set_bank_rate!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        mock_model = build_mock_model(properties)

        set_bank_rate!(mock_model)
        Bit.set_bank_rate!(world)

        ecs_bank_rate = Bit.single(Ark.Query(world, (Bit.Components.LendingRate,), with = (Bit.Components.Bank,)))[2].rate
        @test isapprox(ecs_bank_rate, mock_model.bank.r, atol = 1.0e-7)
    end

    @testset "set_bank_equity!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        mock_model = build_mock_model(
            properties;
            bank_E_k = 500.0,
            bank_Pi_k = 200.0
        )

        set_mock_components!(
            world;
            bank_E_k = 500.0,
            bank_Pi_k = 200.0
        )

        set_bank_equity!(mock_model)
        Bit.set_bank_equity!(world)

        ecs_equity = Bit.single(Ark.Query(world, (Bit.Components.Equity,), with = (Bit.Components.Bank,)))[2].amount
        @test isapprox(ecs_equity, mock_model.bank.E_k, atol = 1.0e-7)
    end

    @testset "set_bank_profits!" begin
        properties = Bit.STEADY_STATE2010Q1
        world = Bit.ECSModel(properties).world

        I = properties.dimensions.total_firms
        test_L_i = fill(20.0, I)
        test_D_i = fill(10.0, I)

        # Introduce a firm with negative deposits to hit the max(0, -D_i) logic
        test_D_i[1] = -5.0

        mock_model = build_mock_model(
            properties;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            bank_D_k = 50.0,
            bank_r = 0.05
        )

        set_mock_components!(
            world;
            firms_L_i = test_L_i,
            firms_D_i = test_D_i,
            bank_D_k = 50.0,
            bank_r = 0.05
        )

        # Sync the central bank rate for the mock model (assuming it defaults to initial_conditions)
        mock_model.cb.r_bar = properties.initial_conditions.banking.policy_rate

        set_bank_profits!(mock_model)
        Bit.set_bank_profits!(world)

        ecs_profits = Bit.single(Ark.Query(world, (Bit.Components.Profits,), with = (Bit.Components.Bank,)))[2].amount
        @test isapprox(ecs_profits, mock_model.bank.Pi_k, atol = 1.0e-7)
    end

end
