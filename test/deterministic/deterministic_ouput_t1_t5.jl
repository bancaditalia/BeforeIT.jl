@testset "time 1 and 5 deterministic" begin

    dir = @__DIR__
    T = 1
    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
    model = BeforeIT.initialise_model(parameters, initial_conditions, T)
    data = BeforeIT.initialise_data(model)

    BeforeIT.one_epoch!(model; multi_threading = false)
    BeforeIT.update_data!(data, model)

    # import results from matlab run
    output_t1 = matread(joinpath(dir, "../matlab_code/output_t1.mat"))

    # confront results between julia and matlab code

    for fieldname in fieldnames(typeof(data))
        julia_output = getfield(data, fieldname)
        matlab_output = output_t1[string(fieldname)]
        # need to remove the first step of the julia output since 
        # the matlab test-code does not save the first step
        if length(julia_output) == 2
            @test isapprox(julia_output[2], matlab_output)
        else
            @test isapprox(julia_output[2:2, :], matlab_output)
        end
    end

    T = 5
    parameters = BeforeIT.AUSTRIA2010Q1.parameters
    initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
    model = BeforeIT.initialise_model(parameters, initial_conditions, T)
    data = BeforeIT.initialise_data(model)
    for t in 1:T
        BeforeIT.one_epoch!(model; multi_threading = false)
        BeforeIT.update_data!(data, model)
    end

    output_t5 = matread(joinpath(dir, "../matlab_code/output_t5.mat"))

    # confront results between julia and matlab code

    for fieldname in fieldnames(typeof(data))
        julia_output = getfield(data, fieldname)
        matlab_output = output_t5[string(fieldname)]

        if length(julia_output) == 6
            @test isapprox(julia_output[2:end], matlab_output', rtol = 1e-4)
        else
            @test isapprox(julia_output[2:end, :], matlab_output, rtol = 1e-5)
        end
    end

end
