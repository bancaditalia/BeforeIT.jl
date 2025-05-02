@testset "initialize deterministic" begin

    dir = @__DIR__
    T = 3

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    model = Bit.init_model(parameters, initial_conditions, 1)

    properties = model.prop

    H_act = Int(properties.H_act)
    H_inact = Int(properties.H_inact)
    I = properties.I
    H = H_act + H_inact
    H_W = H_act - I - 1

    init_vars = matread(joinpath(dir, "../matlab_code/init_vars_firms.mat"))
    for fieldname in fieldnames(typeof(model.firms))

        if fieldname in [
            :w_i,
            :Q_i,
            :I_i,
            :E_i,
            :P_bar_i,
            :P_CF_i,
            :DS_i,
            :DM_i,
            :DL_i,
            :DL_d_i,
            :K_e_i,
            :L_e_i,
            :Q_s_i,
            :I_d_i,
            :DM_d_i,
            :N_d_i,
            :Pi_e_i,
            :C_d_h,
            :I_d_h,
            :C_h,
            :I_h,
        ]
            continue
        end
        julia_var = getfield(model.firms, fieldname)

        if fieldname in [:Y_h, :K_h, :D_h]
            matlab_var = init_vars[string(fieldname)]
            matlab_var = matlab_var[(H_W + H_inact + 1):(H_W + H_inact + I)]
            @test isapprox(julia_var, matlab_var)
        else
            matlab_var = init_vars[string(fieldname)]
            @test isapprox(julia_var, matlab_var')
        end
    end

    init_vars = matread(joinpath(dir, "../matlab_code/init_vars_bank.mat"))
    for fieldname in fieldnames(typeof(model.bank))

        if fieldname in [:Pi_e_k, :Y_h, :K_h, :D_h, :C_d_h, :I_d_h, :C_h, :I_h]
            continue
        end
        julia_var = getfield(model.bank, fieldname)
        matlab_var = init_vars[string(fieldname)]
        @test isapprox(julia_var, matlab_var')

    end

    init_vars = matread(joinpath(dir, "../matlab_code/init_vars_households.mat"))
    for fn in fieldnames(typeof(model.w_act))

        if fn in [:C_d_h, :I_d_h, :C_h, :I_h]
            continue
        end

        if fn in [:w_h, :O_h]
            julia_var = getfield(model.w_act, fn)
            matlab_var = init_vars[string(fn)]
            @test isapprox(julia_var, matlab_var')
        else
            julia_var = [
                getfield(model.w_act, fn)
                getfield(model.w_inact, fn)
                getfield(model.firms, fn)
                getfield(model.bank, fn)
            ]
            matlab_var = init_vars[string(fn)]
            @test isapprox(julia_var, matlab_var')
        end

    end

end
