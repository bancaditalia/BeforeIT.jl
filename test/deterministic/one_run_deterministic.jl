
@testset "run deterministic" begin
    T = 3
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

    function run_deterministic(parameters, initial_conditions, T, m)
        model = Bit.Model(parameters, initial_conditions)
        for t in 1:(T - 1)
            Bit.step!(model; parallel = m)
            Bit.update_data!(model)
        end
        return model
    end

    model = run_deterministic(parameters, initial_conditions, T, false)
    model2 = run_deterministic(parameters, initial_conditions, T, false)
    model3 = run_deterministic(parameters, initial_conditions, T, true)

    # loop over the data fields and compare them
    data, data2, data3 = model.data, model2.data, model3.data
    for field in fieldnames(typeof(data))
        @test isapprox(getproperty(data, field), getproperty(data2, field), rtol = 0.0001)
        @test isapprox(getproperty(data2, field), getproperty(data3, field), rtol = 0.0001)
    end
end
