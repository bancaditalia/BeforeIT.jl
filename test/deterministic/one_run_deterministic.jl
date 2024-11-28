
@testset "run deterministic" begin
    T = 3
    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

    function run_deterministic(parameters, initial_conditions, T, m)
        model = BeforeIT.init_model(parameters, initial_conditions, T;)
        data = BeforeIT.init_data(model)
        for t in 1:(T - 1)
            BeforeIT.run_one_epoch!(model; multi_threading = false)
            BeforeIT.update_data!(data, model)
        end
        return model, data   
    end

    model, data = run_deterministic(parameters, initial_conditions, T, false)
    model2, data2 = run_deterministic(parameters, initial_conditions, T, false)
    model3, data3 = run_deterministic(parameters, initial_conditions, T, true)
    
    # loop over the data fields and compare them
    for field in fieldnames(typeof(data))
        @test isapprox(getproperty(data, field), getproperty(data2, field), rtol = 0.001)
        @test isapprox(getproperty(data2, field), getproperty(data3, field), rtol = 0.001)
    end
end
