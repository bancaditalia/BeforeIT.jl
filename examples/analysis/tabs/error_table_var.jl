
function error_table_var(country::String, ea, data, quarters, horizons)
    quarters_num = Bit.date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    number_variables = 5
    presample = 4

    for k in 1:3
        forecast = fill(NaN, number_quarters, number_horizons, number_variables)
        actual = fill(NaN, number_quarters, number_horizons, number_variables)

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                horizon = horizons[j]

                forecast_quarter_num = Bit.date2num(lastdayofmonth(Bit.num2date(quarter_num) +
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

                Y0 = hcat(
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["gdp_deflator_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_household_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .<= quarter_num]),
                    cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]) .^
                           (1 / 4))
                )

                Y = zeros(horizon, number_variables)
                Y0_diff = diff(Y0[(presample - k):end, :]; dims = 1)

                for l in 1:number_variables
                    Y[:, l] = Bit.forecast_k_steps_VAR(
                        Y0_diff[:, l], horizon, intercept = true, lags = k)
                end

                Y[end, [1, 3, 4]] = Y0[end, [1, 3, 4]]' + sum(Y[:, [1, 3, 4]], dims = 1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        create_bias_rmse_tables_var(
            forecast, actual, horizons, "training", number_variables, k)
    end
    return nothing
end
