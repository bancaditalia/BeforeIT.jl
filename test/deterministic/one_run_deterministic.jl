
@testset "run deterministic" begin
    T = 3
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

    function run_deterministic(parameters, initial_conditions, T, m)
        model = Bit.init_model(parameters, initial_conditions, T;)
        data = Bit.init_data(model)
        for t in 1:(T - 1)
            Bit.step!(model; multi_threading = m)
            Bit.update_data!(data, model)
        end
        return model, data   
    end

    model, data = run_deterministic(parameters, initial_conditions, T, false)
    model2, data2 = run_deterministic(parameters, initial_conditions, T, false)
    model3, data3 = run_deterministic(parameters, initial_conditions, T, true)
    
    # loop over the data fields and compare them
    for field in fieldnames(typeof(data))
        @test isapprox(getproperty(data, field), getproperty(data2, field), rtol = 0.00001)
        @test isapprox(getproperty(data2, field), getproperty(data3, field), rtol = 0.00001)
    end
end
