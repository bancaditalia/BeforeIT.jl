
@testset "run deterministic" begin
    T = 3

    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

    model = BeforeIT.init_model(parameters, initial_conditions, T;)
    data = BeforeIT.init_data(model)

    for t in 1:(T - 1)
        BeforeIT.run_one_epoch!(model; multi_threading = false)
        BeforeIT.update_data!(data, model)
    end

    model2 = BeforeIT.init_model(parameters, initial_conditions, T;)
    data2 = BeforeIT.init_data(model2)

    for t in 1:(T - 1)
        BeforeIT.run_one_epoch!(model2; multi_threading = false)
        BeforeIT.update_data!(data2, model2)
    end

    # loop over the data fields and compare them
    for field in fieldnames(typeof(data))
        @test isapprox(getproperty(data, field), getproperty(data2, field), rtol = 0.001)
    end
end
