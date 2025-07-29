
# Helper functions

function growth_rate(x; dims = 1)
    rate = diff(log.(x), dims = dims)
    return exp.(rate) .- 1
end

function compound_quarterly(base, growth)
    return base .* cumprod(1 .+ growth, dims = 1)
end

function prepare_quarterly_annual_level(data, sims, varname, quarter_num, year_num,
        number_seeds, q)
    var_sim = getproperty(sims, Symbol(varname))

    # quarter‑on‑quarter growth used for compounding
    growth_quarterly = growth_rate(var_sim)

    # produce forecast path in quarterly frequency
    quarterly_forecast = compound_quarterly(
        data["$(varname)_quarterly"][data["quarters_num"] .== quarter_num],
        growth_quarterly)

    quarterly_full = [repeat(
                          data["$(varname)_quarterly"][data["quarters_num"] .== quarter_num],
                          1,
                          number_seeds)
                      quarterly_forecast]

    annual_full = [repeat(data[varname][data["years_num"] .== year_num], 1, number_seeds);
                   Bit.toannual(quarterly_forecast[(5 - q):(end - mod(q, 4)), :]')']

    return quarterly_full, annual_full
end

function prepare_quarterly_annual_level_growth(data, sims, varname, quarter_num, year_num,
        number_seeds, q)
    quarterly_full, annual_full = prepare_quarterly_annual_level(data, sims, varname,
        quarter_num, year_num,
        number_seeds, q)

    growth_annual = growth_rate(annual_full)
    growth_annual_full = [repeat(data["$(varname)_growth"][data["years_num"] .== year_num],
                              1, number_seeds)
                          growth_annual]

    growth_quarterly_full = growth_rate(quarterly_full)
    growth_quarterly_full = [repeat(
                                 data["$(varname)_growth_quarterly"][data["quarters_num"] .== quarter_num],
                                 1,
                                 number_seeds)
                             growth_quarterly_full]

    return quarterly_full, annual_full, growth_annual_full, growth_quarterly_full
end

function prepare_quarterly_annual_level_growth_deflator(nominal, real, data, varname,
        quarter_num, year_num, number_seeds,
        q)
    deflator_quarterly = nominal ./ real

    deflator_quarterly_full = [repeat(
                                   data["$(varname)_deflator_quarterly"][data["quarters_num"] .== quarter_num],
                                   1,
                                   number_seeds)
                               deflator_quarterly]

    deflator_annual = [repeat(data["$(varname)_deflator"][data["years_num"] .== year_num],
                           1, number_seeds)
                       Bit.toannual_mean(deflator_quarterly[
                           (5 - q):(end - mod(q, 4)), :]')']

    deflator_growth_annual = growth_rate(deflator_annual)
    deflator_growth_annual_full = [repeat(
                                       data["$(varname)_deflator_growth"][data["years_num"] .== year_num],
                                       1,
                                       number_seeds)
                                   deflator_growth_annual]

    deflator_growth_quarterly = growth_rate(deflator_quarterly_full)
    deflator_growth_quarterly_full = [repeat(
                                          data["$(varname)_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num],
                                          1,
                                          number_seeds)
                                      deflator_growth_quarterly]

    return deflator_quarterly_full, deflator_annual, deflator_growth_annual_full,
    deflator_growth_quarterly_full
end

# Main function

function get_predictions_from_sims(sims, real_data, start_date)

    # initialise a dictionary with all predictions
    predictions_dict = Dict{String, Any}()

    # unique quarter identifier
    quarter_num = Bit.date2num(start_date)

    # unique year identifier (always computed the last day of the year)
    year_num = Bit.date2num(DateTime(year(start_date) + 1, 1, 1) - Day(1))

    number_seeds = size(sims.real_gdp, 2)
    horizon = size(sims.real_gdp, 1) - 1

    q = quarterofyear(start_date)

    variables = ["gdp", "gva", "household_consumption",
        "government_consumption", "capitalformation",
        "fixed_capitalformation", "exports", "imports"]

    for name in variables
        for version in ["real", "nominal"]
            var = "$(version)_$(name)"
            quarterly, annual, growth_annual, growth_quarterly = prepare_quarterly_annual_level_growth(
                real_data,
                sims,
                var,
                quarter_num,
                year_num,
                number_seeds,
                q)

            predictions_dict["$(var)_quarterly"] = quarterly
            predictions_dict[var] = annual
            predictions_dict["$(var)_growth"] = growth_annual
            predictions_dict["$(var)_growth_quarterly"] = growth_quarterly
        end
    end

    # Variables where only levels (no growth series) are required
    variables_level_only = [
        "operating_surplus",
        "compensation_employees",
        "wages"
    ]

    for var in variables_level_only
        quarterly, annual = prepare_quarterly_annual_level(real_data, sims, var,
            quarter_num, year_num,
            number_seeds, q)

        predictions_dict["$(var)_quarterly"] = quarterly
        predictions_dict[var] = annual
    end

    # Deflators

    for name in variables
        real_var = "real_$(name)"
        nominal_var = "nominal_$(name)"
        deflator_q, deflator_y, deflator_growth_y, deflator_growth_q = prepare_quarterly_annual_level_growth_deflator(
            predictions_dict["$(nominal_var)_quarterly"][2:end,
                :],
            predictions_dict["$(real_var)_quarterly"][2:end,
                :],
            real_data,
            name,
            quarter_num,
            year_num,
            number_seeds,
            q)

        predictions_dict["$(name)_deflator_quarterly"] = deflator_q
        predictions_dict["$(name)_deflator"] = deflator_y
        predictions_dict["$(name)_deflator_growth"] = deflator_growth_y
        predictions_dict["$(name)_deflator_growth_quarterly"] = deflator_growth_q
    end

    # Prepare quarters_num and years_num
    predictions_dict["quarters_num"] = [Bit.date2num(DateTime(year(start_date),
                                            month(start_date), 1) +
                                                     Month(m + 1) - Day(1))
                                        for m in 0:3:(3 * horizon)]
    predictions_dict["years_num"] = [Bit.date2num(DateTime(year(start_date) + 1, 1, 1) +
                                                  Month(month - 1) - Day(1))
                                     for month in 1:12:(horizon / 4 * 12 + floor(q / 4))]

    # Additional variables
    # Note: nominal and real nace10_gva_quarterly and annually are missing here
    predictions_dict["euribor"] = (1 .+ sims.euribor) .^ 4 .- 1
    predictions_dict["gdp_deflator_growth_ea_quarterly"] = sims.gdp_deflator_growth_ea
    predictions_dict["real_gdp_ea_quarterly"] = sims.real_gdp_ea

    return predictions_dict
end
