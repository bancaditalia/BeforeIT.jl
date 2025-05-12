import BeforeIT as Bit
using Dates
using DelimitedFiles
using Statistics
using Printf
using LaTeXStrings
using CSV
using HDF5
using FileIO
using MAT

country = "italy"

for i in 1:number_quarters
    model_dict = Dict{String, Any}()

    quarter_num = quarters_num[i]
    q = quarterofyear(DateTime(Bit.num2date(quarter_num)))
    year_num = Bit.date2num(DateTime(year(Bit.num2date(quarter_num)) + 1, 1, 1) - Day(1))

    forecast_quarter_num = Bit.date2num(lastdayofmonth(Bit.num2date(quarter_num) + Month(3 * horizon)))
    #=
    if Bit.num2date(forecast_quarter_num) > Date(max_year, 12, 31)
        break
    end
    =#
    Y0 = hcat(collect([
        log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
        log.(data["gdp_deflator_quarterly"][data["quarters_num"] .<= quarter_num]),
        log.(data["real_household_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
        log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .<= quarter_num]),
        cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]).^(1/4)),
        log.(data["real_government_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
        log.(data["real_exports_quarterly"][data["quarters_num"] .<= quarter_num]),
        log.(data["real_imports_quarterly"][data["quarters_num"] .<= quarter_num])
    ])...)

    Y = zeros(horizon, number_variables)
    Y0_diff = diff(Y0; dims = 1)
    V = fill(NaN, horizon, number_seeds, number_variables)

    for j = 1:number_seeds  
        for l in 1:number_variables
            Y[:,l] = Bit.forecast_k_steps_VAR(Y0_diff[:,l], horizon, intercept = true, lags = 1, stochastic = true)
        end
        Y[:, [1, 3, 4, 6, 7, 8]] = cumsum(Y[:, [1, 3, 4, 6, 7, 8]], dims =1)
        V[:, j, :] = Y
    end

    real_gdp_growth_quarterly=data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,1].-Y0[end,1]);
    model_dict["real_gdp_growth_quarterly"] = real_gdp_growth_quarterly .-1
    model_dict["real_gdp_growth_quarterly"] = [
        repeat(data["real_gdp_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_gdp_growth_quarterly"]
    ]
    real_gdp_quarterly =
        data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_gdp_growth_quarterly
    model_dict["real_gdp_quarterly"] = [
        repeat(data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_gdp_quarterly
    ]
    model_dict["real_gdp"] = [
        repeat(data["real_gdp"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_gdp"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_gdp_growth"] = diff(log.(tmp), dims = 1)

    # calculate discrete compounding rate
    model_dict["real_gdp_growth"] = exp.(model_dict["real_gdp_growth"]) .- 1
    model_dict["real_gdp_growth"] = [
        repeat(data["real_gdp_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_gdp_growth"]
    ]

    gdp_deflator_quarterly=data["gdp_deflator_quarterly"][data["quarters_num"] .== quarter_num].*exp.(cumsum(V[:,:,2], dims = 1));
    
    model_dict["gdp_deflator_quarterly"] = [
        repeat(data["gdp_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        gdp_deflator_quarterly
    ]
    model_dict["gdp_deflator"] = [
        repeat(data["gdp_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(gdp_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["gdp_deflator_growth"] = diff(
        log.(
            [
                repeat(data["gdp_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(gdp_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["gdp_deflator_growth"] = exp.(model_dict["gdp_deflator_growth"]) .- 1
    model_dict["gdp_deflator_growth"] = [
        repeat(data["gdp_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["gdp_deflator_growth"]
    ]
    
    model_dict["gdp_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["gdp_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                gdp_deflator_quarterly
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["gdp_deflator_growth_quarterly"] = exp.(model_dict["gdp_deflator_growth_quarterly"]) .- 1
    
    model_dict["gdp_deflator_growth_quarterly"] = [
        repeat(data["gdp_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["gdp_deflator_growth_quarterly"]
    ]
    
    real_household_consumption_growth_quarterly=data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,3].-Y0[end,3]);
    model_dict["real_household_consumption_growth_quarterly"] = real_household_consumption_growth_quarterly .-1
    model_dict["real_household_consumption_growth_quarterly"] = [
        repeat(data["real_household_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_household_consumption_growth_quarterly"]
    ]
    real_household_consumption_quarterly =
        data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_household_consumption_growth_quarterly
    model_dict["real_household_consumption_quarterly"] = [
        repeat(data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_household_consumption_quarterly
    ]
    model_dict["real_household_consumption"] = [
        repeat(data["real_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_household_consumption_growth"] = diff(log.(tmp), dims = 1)


    # calculate discrete compounding rate
    model_dict["real_household_consumption_growth"] = exp.(model_dict["real_household_consumption_growth"]) .- 1
    model_dict["real_household_consumption_growth"] = [
        repeat(data["real_household_consumption_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_household_consumption_growth"]
    ]

    real_fixed_capitalformation_growth_quarterly=data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,4].-Y0[end,4]);
    model_dict["real_fixed_capitalformation_growth_quarterly"] = real_fixed_capitalformation_growth_quarterly .-1
    model_dict["real_fixed_capitalformation_growth_quarterly"] = [
        repeat(data["real_fixed_capitalformation_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_fixed_capitalformation_growth_quarterly"]
    ]
    real_fixed_capitalformation_quarterly =
        data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_fixed_capitalformation_growth_quarterly
    model_dict["real_fixed_capitalformation_quarterly"] = [
        repeat(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_fixed_capitalformation_quarterly
    ]
    model_dict["real_fixed_capitalformation"] = [
        repeat(data["real_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_fixed_capitalformation_growth"] = diff(log.(tmp), dims = 1)


    # calculate discrete compounding rate
    model_dict["real_fixed_capitalformation_growth"] = exp.(model_dict["real_fixed_capitalformation_growth"]) .- 1
    model_dict["real_fixed_capitalformation_growth"] = [
        repeat(data["real_fixed_capitalformation_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_fixed_capitalformation_growth"]
    ]

    
    real_government_consumption_growth_quarterly=data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,6].-Y0[end,6]);
    model_dict["real_government_consumption_growth_quarterly"] = real_government_consumption_growth_quarterly .-1
    model_dict["real_government_consumption_growth_quarterly"] = [
        repeat(data["real_government_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_government_consumption_growth_quarterly"]
    ]
    real_government_consumption_quarterly=
        data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_government_consumption_growth_quarterly
    model_dict["real_government_consumption_quarterly"] = [
        repeat(data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_government_consumption_quarterly
    ]
    model_dict["real_government_consumption"] = [
        repeat(data["real_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_government_consumption_growth"] = diff(log.(tmp), dims = 1)
    
    real_exports_growth_quarterly=data["real_exports_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,7].-Y0[end,7]);
    model_dict["real_exports_growth_quarterly"] = real_exports_growth_quarterly .-1
    model_dict["real_exports_growth_quarterly"] = [
        repeat(data["real_exports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_exports_growth_quarterly"]
    ]
    real_exports_quarterly=
        data["real_exports_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_exports_growth_quarterly
    model_dict["real_exports_quarterly"] = [
        repeat(data["real_exports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_exports_quarterly
    ]
    model_dict["real_exports"] = [
        repeat(data["real_exports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_exports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_exports_growth"] = diff(log.(tmp), dims = 1)

    real_imports_growth_quarterly=data["real_imports_quarterly"][data["quarters_num"] .== quarter_num].*exp.(V[:,:,8].-Y0[end,8]);
    model_dict["real_imports_growth_quarterly"] = real_imports_growth_quarterly .-1
    model_dict["real_imports_growth_quarterly"] = [
        repeat(data["real_imports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_imports_growth_quarterly"]
    ]
    real_imports_quarterly=
        data["real_imports_quarterly"][data["quarters_num"] .== quarter_num] .*
        real_imports_growth_quarterly
    model_dict["real_imports_quarterly"] = [
        repeat(data["real_imports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_imports_quarterly
    ]
    model_dict["real_imports"] = [
        repeat(data["real_imports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_imports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_imports_quarterly_growth"] = diff(log.(tmp), dims = 1)

    save("data/" * country * "/ar/" * string(year(Bit.num2date(quarter_num))) * "Q" * string(Dates.quarterofyear(Bit.num2date(quarter_num))) *".jld2",                
        "model_dict",
        model_dict)
end