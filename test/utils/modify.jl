@testset "Retrieve/Add/Remove Agents" begin
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)
    actw = Bit.activeworkers(model)
    id = UInt(1)
    agent = actw[id]
    agent.Y_h = agent.Y_h + 1
    agentf = Bit.getfields(agent)
    delete!(actw, id)
    @test !(id in Bit.allids(actw))
    push!(
        actw, (
            Y_h = 1.0, D_h = 1.0, K_h = 1.0, w_h = 1.0, O_h = 1.0,
            C_d_h = 1.0, I_d_h = 1.0, C_h = 1.0, I_h = 2.0,
        )
    )
    id = Bit.lastid(actw)
    agent = actw[id]
    @test agent.Y_h == 1.0
    @test agent.I_h == 2.0
    push!(actw, agentf)
    id = Bit.lastid(model.w_act)
    @test Bit.getfields(actw[id]) == agentf
end
