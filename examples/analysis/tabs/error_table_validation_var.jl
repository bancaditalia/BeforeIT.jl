
function error_table_validation_var(country::String)

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    number_quarters = 4 * 10
    quarters_num = [Bit.date2num(date) for date in DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31)]
    max_year = 2019

    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 8
    presample = 4

    ea = matread(("data/$(country)/calibration/ea/1996.mat"))["ea"]
    data = matread(("data/$(country)/calibration/data/1996.mat"))["data"]

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

        if k == 1
            h5open("data/" * country * "/analysis/forecast_validation_var.h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_var = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_var = forecast - actual
        else
            h5open("data/" * country * "/analysis/forecast_validation_var_$(k).h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_var_k = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_var_k = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_var_k = forecast - actual

            forecast = h5read("data/" * country * "/analysis/forecast_validation_var.h5","forecast")
            rmse_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            error_var = forecast - actual
        end


        if k == 1
            input_data = round.(rmse_var, digits=2)
            input_data_S = string.(input_data)
        else
            input_data = - round.(100 * (rmse_var .- rmse_var_k) ./ rmse_var, digits=1)
            input_data_S = fill("", size(input_data))
            for j in 1:length(horizons)
                h = horizons[j]
                for l in 1:number_variables
                    dm_error_var_k = view(error_var_k, :, j, l)[map(!,isnan.(view(error_var_k, :, j, l)))]
                    dm_error_var = view(error_var, :, j, l)[map(!,isnan.(view(error_var, :, j, l)))]
                    _, p_value = Bit.dmtest_modified(dm_error_var,dm_error_var_k, h)
                    input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) *", "* string(stars(p_value)) * ")"
                end
            end
        end
        
        latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

        idx = k == 1 ? "" : "_$(k)"
        open("data/" * country * "/analysis/rmse_validation_var" * idx * ".tex", "w") do fid
            for line in latex
                write(fid, line * "\n")
            end
        end
        
        if k == 1
            input_data = round.(bias_var, digits=4)
            input_data_S = fill("", size(input_data))

            for j in 1:length(horizons)
                
                h = horizons[j]
                for l in 1:number_variables
                    mz_forecast = (view(error_var, :, j, l) + view(actual, :, j, l))[map(!,isnan.(view(error_var, :, j, l) + view(actual, :, j, l)))]
                    mz_actual = view(actual, :, j, l)[map(!,isnan.(view(actual, :, j, l)))]
                    _, _, p_value = Bit.mztest(mz_actual, mz_forecast)
                    input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) *", "* stars(p_value) * ")"
                end
            end
            
            latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

            open("data/" * country * "/analysis/bias_validation_var.tex", "w") do fid
                for line in latex
                    write(fid, line * "\n")
                end
            end
        end
    end
    return nothing
end