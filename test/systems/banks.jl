using Test
import Ark

# --- 1. Stub Implementation for Old OOP Model ---
mutable struct MockBank
    r::Float64
    Pi_k::Float64
    Pi_e_k::Float64
    E_k::Float64
    D_h::Float64
    D_k::Float64
end

mutable struct MockFirms
    L_i::Vector{Float64}
    D_i::Vector{Float64}
    D_h::Vector{Float64}
    E_i::Vector{Float64}
    K_i::Vector{Float64}
end

mutable struct MockWorkers
    D_h::Vector{Float64}
end

mutable struct MockCB
    r_bar::Float64
end

mutable struct MockProp
    mu::Float64
    theta_DIV::Float64
    tau_FIRM::Float64
    zeta_b::Float64
end

mutable struct MockAgg
    pi_e::Float64
    gamma_e::Float64
    P_bar_CF::Float64
end

mutable struct MockModel
    bank::MockBank
    firms::MockFirms
    w_act::MockWorkers
    w_inact::MockWorkers
    cb::MockCB
    prop::MockProp
    agg::MockAgg
end

# Helper to iterate firms in the old system
eachfirm(model::MockModel) = 1:length(model.firms.L_i)

# (Assume the old functions from pasted_text_0.txt are included here or in the module)
# ... [Insert old functions: bank_profits, set_bank_profits!, etc.] ...
#
@testset "Banking Systems: OOP vs ECS Parity" begin
    # --- 1. Initialize Mock Data ---
    num_firms = 3
    num_workers = 2
    
    # OOP Model Setup
    model = MockModel(
        MockBank(0.0, 100.0, 0.0, 500.0, 10.0, 0.0),
        MockFirms([50.0, 100.0, 20.0], [10.0, -5.0, 30.0], [5.0, 5.0, 5.0], [100.0, -10.0, 50.0], [200.0, 150.0, 100.0]),
        MockWorkers([15.0, 20.0]),
        MockWorkers([5.0, 5.0]),
        MockCB(0.02),
        MockProp(0.03, 0.5, 0.2, 0.8),
        MockAgg(0.02, 0.01, 1.0)
    )

    # ECS World Setup (Mirroring the OOP Data)
    world = Ark.World()
    
    # Mock Resources
    Ark.add_resource!(world, Bit.Properties(...)) # Assume mocked properties matching MockProp
    Ark.add_resource!(world, Bit.Expectations(model.agg.pi_e, model.agg.gamma_e))
    Ark.add_resource!(world, Bit.PriceIndices(model.agg.P_bar_CF))
    
    # Central Bank Entity
    Ark.new_entity!(world, (Bit.Components.NominalInterestRate(model.cb.r_bar),))
    
    # Bank Entity
    bank_entity = Ark.new_entity!(world, (
        Bit.Components.LendingRate(model.bank.r),
        Bit.Components.Profits(model.bank.Pi_k),
        Bit.Components.ExpectedProfits(model.bank.Pi_e_k),
        Bit.Components.Equity(model.bank.E_k),
        Bit.Components.ResidualItems(model.bank.D_k),
        Bit.Components.Deposits(model.bank.D_h) # Bank owner deposits
    ))

    # Firm Entities
    for i in 1:num_firms
        Ark.new_entity!(world, (
            Bit.Components.LoansOutstanding(model.firms.L_i[i]),
            Bit.Components.Deposits(model.firms.D_i[i]),
            Bit.Components.Equity(model.firms.E_i[i]),
            Bit.Components.CapitalStock(model.firms.K_i[i]),
            Bit.Components.Firm()
        ))
        # Firm owner deposits
        Ark.new_entity!(world, (Bit.Components.Deposits(model.firms.D_h[i]), Bit.Components.Household()))
    end

    # Worker Entities
    for d in [model.w_act.D_h; model.w_inact.D_h]
        Ark.new_entity!(world, (Bit.Components.Deposits(d), Bit.Components.Household()))
    end


    # --- 2. Test Bank Rate ---
    set_bank_rate!(model)
    Bit.set_bank_rate!(world)
    
    ecs_bank_rate = single(Ark.Query(world, (Bit.Components.LendingRate,)))[2].rate
    @test isapprox(ecs_bank_rate, model.bank.r, atol=1e-7)


    # --- 3. Test Expected Profits ---
    set_bank_expected_profits!(model)
    Bit.set_bank_expected_profits!(world)
    
    ecs_expected_profits = single(Ark.Query(world, (Bit.Components.ExpectedProfits,)))[2].amount
    @test isapprox(ecs_expected_profits, model.bank.Pi_e_k, atol=1e-7)


    # --- 4. Test Bank Equity ---
    set_bank_equity!(model)
    Bit.set_bank_equity!(world)
    
    ecs_equity = single(Ark.Query(world, (Bit.Components.Equity,), with=(Bit.Components.LendingRate,)))[2].amount
    @test isapprox(ecs_equity, model.bank.E_k, atol=1e-7)


    # --- 5. Test Insolvent Firms Financing ---
    finance_insolvent_firms!(model)
    Bit.finance_insolvent_firms!(world)
    
    # Check bank equity deduction
    ecs_bank_equity_after = single(Ark.Query(world, (Bit.Components.Equity,), with=(Bit.Components.LendingRate,)))[2].amount
    @test isapprox(ecs_bank_equity_after, model.bank.E_k, atol=1e-7)
    
    # Check firm 2 (which was insolvent: D_i = -5.0, E_i = -10.0)
    # Note: In a real test, you'd query the specific entity ID for firm 2. 
    # Here we just verify the sums match to ensure the math was applied correctly.
    ecs_total_firm_equity = sum(c.amount for (_, c) in Ark.Query(world, (Bit.Components.Equity,), with=(Bit.Components.Firm,)))
    @test isapprox(ecs_total_firm_equity, sum(model.firms.E_i), atol=1e-7)


    # --- 6. Test Bank Deposits (Residuals) ---
    set_bank_deposits!(model)
    Bit.set_bank_deposits!(world)
    
    ecs_residual = single(Ark.Query(world, (Bit.Components.ResidualItems,)))[2].amount
    @test isapprox(ecs_residual, model.bank.D_k, atol=1e-7)


    # --- 7. Test Bank Profits ---
    # (Requires deposits and rates to be fully updated)
    set_bank_profits!(model)
    Bit.set_bank_profits!(world)
    
    ecs_profits = single(Ark.Query(world, (Bit.Components.Profits,), with=(Bit.Components.LendingRate,)))[2].amount
    @test isapprox(ecs_profits, model.bank.Pi_k, atol=1e-7)
end
