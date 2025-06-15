
function error_table_validation_var(country::String, ea, data, quarters)

    quarters_num = Bit.date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 8
    presample = 4

    for k = 1:3

        forecast = fill(NaN, number_quarters, number_horizons, number_variables)
        actual = fill(NaN, number_quarters, number_horizons, number_variables)

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                horizon = horizons[j]

                forecast_quarter_num = Bit.date2num(lastdayofmonth(Bit.num2date(quarter_num) + Month(3 * horizon)))
                Bit.num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

                actual[i, j, :] = hcat(collect([
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(1 .+ data["gdp_deflator_growth_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(data["real_government_consumption_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(data["real_exports_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(data["real_imports_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(ea["real_gdp_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(1 .+ ea["gdp_deflator_growth_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    (1 .+ data["euribor"][data["quarters_num"] .== forecast_quarter_num]).^(1/4)
                    ])...)

                Y0 = hcat(collect([
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(1 .+ data["gdp_deflator_growth_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_government_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_exports_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_imports_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(ea["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(1 .+ ea["gdp_deflator_growth_quarterly"][data["quarters_num"] .<= quarter_num]),
                    cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]).^(1/4))
                    ])...)

                Y0_diff = diff(Y0[presample - k + 1:end,:]; dims = 1)
                Y = Bit.forecast_k_steps_VAR(Y0_diff, horizon, intercept = true, lags = k)

                Y[end, [1, 3, 4, 5, 6]] = Y0[end, [1, 3, 4, 5, 6]]' + sum(Y[:, [1, 3, 4, 5, 6]], dims=1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        create_bias_rmse_tables_var(forecast, actual, horizons, "validation", number_variables, k)
    end
    return nothing
end

