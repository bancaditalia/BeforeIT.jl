# Helper functions

function growth_rate(x; dims=1)
    rate = diff(log.(x), dims=dims)
    return exp.(rate) .- 1
end

function compound_quarterly(base, growth)
    return base .* cumprod(1 .+ growth, dims=1)
end

function prepare_quarterly_annual(data, sims, varname, quarter_num, year_num, number_seeds, q)

    var_sim = getproperty(sims, Symbol(varname))

    # quarter‑on‑quarter growth used for compounding
    growth_quarterly = growth_rate(var_sim)

    # produce forecast path in quarterly frequency
    quarterly_forecast =
        compound_quarterly(data["$(varname)_quarterly"][data["quarters_num"] .== quarter_num], growth_quarterly)

    quarterly_full = [
        repeat(data["$(varname)_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        quarterly_forecast  # vertical concatenation
    ]

    annual_full = [
        repeat(data[varname][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(quarterly_forecast[(5 - q):(end - mod(q, 4)), :]')'
    ]

    return quarterly_full, annual_full
end

function prepare_quarterly_annual_growth(data, sims, varname, quarter_num, year_num, number_seeds, q)

    quarterly_full, annual_full = prepare_quarterly_annual(data, sims, varname, quarter_num, year_num, number_seeds, q)

    growth_annual = diff(log.(annual_full), dims=1)
    growth_annual = exp.(growth_annual) .- 1

    growth_annual_full = [repeat(data["$(varname)_growth"][data["years_num"] .== year_num], 1, number_seeds); growth_annual]

    growth_quarterly_full = growth_rate(quarterly_full)
    growth_quarterly_full = [repeat(data["$(varname)_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds); growth_quarterly_full]

    return quarterly_full, annual_full, growth_annual_full, growth_quarterly_full
end

function prepare_deflator(nominal, real, data, name, quarter_num, year_num, number_seeds, q)
    deflator_quarterly = nominal ./ real

    deflator_quarterly_full = [
        repeat(data["$(name)_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        deflator_quarterly
    ]

    deflator_annual = [
        repeat(data["$(name)_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    deflator_growth_annual = growth_rate(deflator_annual)
    deflator_growth_annual_full = [repeat(data["$(name)_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds); deflator_growth_annual]

    deflator_growth_quarterly = growth_rate(deflator_quarterly_full)
    deflator_growth_quarterly_full = [repeat(data["$(name)_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds); deflator_growth_quarterly]

    return deflator_quarterly_full, deflator_annual, deflator_growth_annual_full, deflator_growth_quarterly_full
end


# Main function (modularised)

function get_predictions_from_sims(data, quarter_num, horizon, number_seeds)

    model_dict = Dict{String, Any}()

    year_num = Bit.date2num(DateTime(year(Bit.num2date(quarter_num)) + 1, 1, 1) - Day(1))
    date = Bit.num2date(quarter_num)

    file_name = "data/italy/simulations/$(year(date))Q$(quarterofyear(date)).jld2"
    sims = load(file_name)["data_vector"]

    q = quarterofyear(date)

    variables = ["real_gdp", "nominal_gdp", "real_gva", "nominal_gva",
                 "real_household_consumption", "nominal_household_consumption",
                 "real_government_consumption", "nominal_government_consumption",
                 "real_capitalformation", "nominal_capitalformation",
                 "real_fixed_capitalformation", "nominal_fixed_capitalformation",
                 "real_exports", "nominal_exports",
                 "real_imports", "nominal_imports"]

    for var in variables
        quarterly, annual, growth_annual, growth_quarterly = prepare_quarterly_annual_growth(
            data, sims, var, quarter_num, year_num, number_seeds, q)

        model_dict["$(var)_quarterly"] = quarterly
        model_dict[var] = annual
        model_dict["$(var)_growth"] = growth_annual
        model_dict["$(var)_growth_quarterly"] = growth_quarterly
    end

    # Deflators
    deflators = [("gdp", "nominal_gdp", "real_gdp"),
                 ("gva", "nominal_gva", "real_gva"),
                 ("household_consumption", "nominal_household_consumption", "real_household_consumption"),
                 ("government_consumption", "nominal_government_consumption", "real_government_consumption"),
                 ("capitalformation", "nominal_capitalformation", "real_capitalformation"),
                 ("fixed_capitalformation", "nominal_fixed_capitalformation", "real_fixed_capitalformation"),
                 ("exports", "nominal_exports", "real_exports"),
                 ("imports", "nominal_imports", "real_imports")]

    for (name, nominal_var, real_var) in deflators
        deflator_q, deflator_y, deflator_growth_y, deflator_growth_q = prepare_deflator(
            model_dict["$(nominal_var)_quarterly"][2:end, :],
            model_dict["$(real_var)_quarterly"][2:end, :],
            data, name, quarter_num, year_num, number_seeds, q)

        model_dict["$(name)_deflator_quarterly"] = deflator_q
        model_dict["$(name)_deflator"] = deflator_y
        model_dict["$(name)_deflator_growth"] = deflator_growth_y
        model_dict["$(name)_deflator_growth_quarterly"] = deflator_growth_q
    end

    # Variables where only levels (no growth series) are required
    level_only_vars = [
        "operating_surplus",
        "compensation_employees",
        "wages",
    ]

    for var in level_only_vars
        quarterly, annual = prepare_quarterly_annual(
            data, sims, var, quarter_num, year_num, number_seeds, q,
        )

        model_dict["$(var)_quarterly"] = quarterly
        model_dict[var]                = annual
    end

    # Prepare quarters_num and years_num
    model_dict["quarters_num"] = [Bit.date2num(DateTime(year(date), month(date), 1) + Month(m + 1) - Day(1)) for m in 0:3:(3 * horizon)]
    model_dict["years_num"] = [Bit.date2num(DateTime(year(date) + 1, 1, 1) + Month(month - 1) - Day(1)) for month in 1:12:(horizon / 4 * 12 + floor(q / 4))]

    # Additional variables
    model_dict["euribor"] = (1 .+ sims.euribor) .^ 4 .- 1
    model_dict["gdp_deflator_growth_ea_quarterly"] = sims.gdp_deflator_growth_ea
    model_dict["real_gdp_ea_quarterly"] = sims.real_gdp_ea

    # save the dictionary
    save("data/italy/abm_predictions/$(year(date))Q$(q).jld2", "model_dict", model_dict)

end
