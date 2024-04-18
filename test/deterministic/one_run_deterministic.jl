
@testset "run deterministic" begin
    T = 3
    dir = @__DIR__

    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions

    parameters1 = deepcopy(parameters)
    parameters2 = deepcopy(parameters)
    initial_conditions1 = deepcopy(initial_conditions)
    initial_conditions2 = deepcopy(initial_conditions)

    model = BeforeIT.initialise_model(parameters1, initial_conditions1, T;)
    data = BeforeIT.initialise_data(model)
    for t in 1:(T - 1)
        BeforeIT.one_epoch!(model; multi_threading = false)
        BeforeIT.update_data!(data, model)
    end


    model2 = BeforeIT.initialise_model(parameters2, initial_conditions2, T;)
    data2 = BeforeIT.initialise_data(model2)

    for t in 1:(T - 1)
        BeforeIT.one_epoch!(model2; multi_threading = false)
        BeforeIT.update_data!(data2, model2)
    end

    # loop over the data fields and compare them
    for field in fieldnames(typeof(data))
        @test isapprox(getproperty(data, field), getproperty(data2, field), rtol = 0.001)
    end
end
