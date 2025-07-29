
function error_table_abm(country::String, ea, data, quarters, horizons)
    quarters_num = Bit.date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    number_variables = 5

    forecast = fill(NaN, number_quarters, number_horizons, number_variables)
    actual = fill(NaN, number_quarters, number_horizons, number_variables)

    q = quarters_num[1]
    model = load(
        "./data/$(country)/abm_predictions/$(year(Bit.num2date(q)))Q$(quarterofyear(Bit.num2date(q))).jld2",
        "model_dict")
    number_of_seeds = size(model["real_gdp_quarterly"], 2)

    for i in 1:number_quarters
        q = quarters_num[i]
        model = load(
            "./data/$(country)/abm_predictions/$(year(Bit.num2date(q)))Q$(quarterofyear(Bit.num2date(q))).jld2",
            "model_dict")

        for j in 1:number_horizons
            horizon = horizons[j]

            forecast_quarter_num = Bit.date2num(lastdayofmonth(Bit.num2date(q) +
                                                               Month(3 * horizon)))
            Bit.num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

            actual[i, j, :] = hcat(
                log.(data["real_gdp_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                log.(1 .+
                     data["gdp_deflator_growth_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                log.(data["real_household_consumption_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                (1 .+ data["euribor"][data["quarters_num"] .== forecast_quarter_num]) .^
                (1 / 4)
            )

            forecast[i, j, :] = hcat(
                log.(mean(model["real_gdp_quarterly"][repeat(
                    model["quarters_num"] .== forecast_quarter_num, 1, number_of_seeds)])),
                log.(1 .+ mean(model["gdp_deflator_growth_quarterly"][repeat(
                    model["quarters_num"] .== forecast_quarter_num, 1, number_of_seeds)])),
                log.(mean(model["real_household_consumption_quarterly"][repeat(
                    model["quarters_num"] .== forecast_quarter_num, 1, number_of_seeds)])),
                log.(mean(model["real_fixed_capitalformation_quarterly"][repeat(
                    model["quarters_num"] .== forecast_quarter_num, 1, number_of_seeds)])),
                (1 .+ mean(model["euribor"][repeat(
                    model["quarters_num"] .== forecast_quarter_num,
                    1, number_of_seeds)])) .^ (1 / 4)
            )
        end
    end
    save("data/$(country)/analysis/forecast_abm.jld2", "forecast", forecast)
    create_bias_rmse_tables_abm(forecast, actual, horizons, "training", number_variables)
end
