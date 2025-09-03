
@testset "Retrieve/Add/Remove Agents" begin
	parameters = Bit.AUSTRIA2010Q1.parameters;
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions;
    model = Bit.Model(parameters, initial_conditions);
    id = 1
    agent = model.w_act[id]
    agent.Y_h = agent.Y_h + 1
    delete!(agent, 1)
    @test !(1 in Bit.allids(model.w_act))
    push!(
        model.w_act, 
        (Y_h = 1.0, D_h = 1.0, K_h = 1.0, w_h = 1.0, O_h = 1.0, 
         C_d_h = 1.0, I_d_h = 1.0, C_h = 1.0, I_h = 2.0)
    )
    @test model.w_act[length(model.w_act.Y_h)+1].Y_h == 1.0
    @test model.w_act[length(model.w_act.Y_h)+1].I_h == 2.0
end
