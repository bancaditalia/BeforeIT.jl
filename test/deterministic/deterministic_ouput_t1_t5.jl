
@testset "time 1 and 5 deterministic" begin

    dir = @__DIR__
    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)
    data = Bit.Data(model)

    Bit.step!(model; multi_threading = false)
    Bit.update_data!(data, model)

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

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.Model(parameters, initial_conditions)
    data = Bit.Data(model)
    T = 5
    for t in 1:T
        Bit.step!(model; multi_threading = false)
        Bit.update_data!(data, model)
    end

    output_t5 = matread(joinpath(dir, "../matlab_code/output_t5.mat"))

    # confront results between julia and matlab code

    for fieldname in fieldnames(typeof(data))
        julia_output = getfield(data, fieldname)
        julia_output = fieldname in [:nominal_sector_gva, :real_sector_gva] ? reduce(hcat, julia_output)' : julia_output
        matlab_output = output_t5[string(fieldname)]

        if length(julia_output) == 6
            @test isapprox(julia_output[2:end], matlab_output', rtol = 1e-4)
        else
            @test isapprox(julia_output[2:end, :], matlab_output, rtol = 1e-5)
        end
    end

end
