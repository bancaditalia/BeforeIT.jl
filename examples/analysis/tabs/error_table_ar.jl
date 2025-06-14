
function error_table_ar(country::String, ea, data, quarters_num)

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    quarters_num = Bit.date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 5
    presample = 4

    for k = 1:3
        forecast = fill(NaN, number_quarters, number_horizons, number_variables)
        actual = fill(NaN, number_quarters, number_horizons, number_variables)

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                horizon = horizons[j]
                forecast_quarter_num = Bit.date2num(lastdayofmonth(Bit.num2date(quarter_num) + Month(3 * horizon)))

                if Bit.num2date(forecast_quarter_num) > Date(max_year, 12, 31)
                    break
                end

                actual[i, j, :] = hcat(collect([
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(1 .+ data["gdp_deflator_growth_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(data["real_household_consumption_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== forecast_quarter_num]),
                    (1 .+ data["euribor"][data["quarters_num"] .== forecast_quarter_num]).^(1/4)
                    ])...)

                Y0 = hcat(collect([
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["gdp_deflator_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_household_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .<= quarter_num]),
                    cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]).^(1/4))
                ])...)

                Y = zeros(horizon, number_variables)
                Y0_diff = diff(Y0[presample - k:end,:]; dims = 1)
                
                for l in 1:number_variables
                    Y[:,l] = Bit.forecast_k_steps_VAR(Y0_diff[:,l], horizon, intercept = true, lags = k)
                end

                Y[end, [1, 3, 4]] = Y0[end, [1, 3, 4]]' + sum(Y[:, [1, 3, 4]], dims=1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        if k == 1
            h5open("data/$(country)/analysis/forecast_ar.h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_ar = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_ar = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_ar = forecast - actual
        else
            h5open("data/$(country)/analysis/forecast_ar_$(k).h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_ar_k = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_ar_k = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_ar_k = forecast - actual

            forecast = h5read("data/$(country)/analysis/forecast_ar.h5","forecast")
            rmse_ar = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            error_ar = forecast - actual
        end

        if k == 1
            input_data = round.(rmse_ar, digits=2)
            input_data_S = string.(input_data)
        else
            input_data = - round.(100 * (rmse_ar .- rmse_ar_k) ./ rmse_ar, digits=1)
            input_data_S = fill("", size(input_data))
            for j in 1:length(horizons)
                h = horizons[j]
                for l in 1:number_variables
                    dm_error_ar_k = view(error_ar_k, :, j, l)[map(!,isnan.(view(error_ar_k, :, j, l)))]
                    dm_error_ar = view(error_ar, :, j, l)[map(!,isnan.(view(error_ar, :, j, l)))]
                    _, p_value = Bit.dmtest_modified(dm_error_ar,dm_error_ar_k, h)
                    input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) *", "* string(stars(p_value)) * ")"
                end
            end
        end

        latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

        idx = k == 1 ? "" : "_$(k)"
        open("data/$(country)/analysis/rmse_ar$(idx).tex", "w") do fid
            for line in latex
                write(fid, line * "\n")
            end
        end
        
        if k == 1
            input_data = round.(bias_ar, digits=4)
            input_data_S = fill("", size(input_data))

            for j in 1:length(horizons)
                
                h = horizons[j]
                for l in 1:number_variables
                    mz_forecast = (view(error_ar, :, j, l) + view(actual, :, j, l))[map(!,isnan.(view(error_ar, :, j, l) + view(actual, :, j, l)))]
                    mz_actual = view(actual, :, j, l)[map(!,isnan.(view(actual, :, j, l)))]
                    _, _, p_value = Bit.mztest(mz_actual, mz_forecast)
                    input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) *", "* stars(p_value) * ")"
                end
            end
            
            latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

            open("data/$(country)/analysis/bias_ar.tex", "w") do fid
                for line in latex
                    write(fid, line * "\n")
                end
            end
        end
    end
    return nothing
end