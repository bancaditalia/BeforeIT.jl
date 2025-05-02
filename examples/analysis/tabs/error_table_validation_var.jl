import BeforeIT as BIT
using Dates, DelimitedFiles, Statistics, Printf, LaTeXStrings, CSV, HDF5, FileIO, MAT


function error_table_validation_var(country::String = "italy")


    nanmean(x) = mean(filter(!isnan,x))
    nanmean(x,y) = mapslices(nanmean,x; dims = y)

    # Helper functions for LaTeX table creation and stars notation
    function stars(p_value)
        if p_value < 0.01
            return "***"
        elseif p_value < 0.05
            return "**"
        elseif p_value < 0.1
            return "*"
        else
            return ""
        end
    end


    dir = @__DIR__

    # Load calibration data (with figaro input-output tables)


    year_ = 2010
    number_years = 10
    number_quarters = 4 * number_years
    quarters_num = []
    year_m = year_
    max_year = 2019

    for month in 4:3:((number_years + 1) * 12 + 1)

        global year_m = year_ + (month ÷ 12)
        mont_m = month % 12
        date = DateTime(year_m, mont_m, 1) - Day(1)

        push!(quarters_num, BIT.date2num(date))

    end
    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 8
    presample = 4


    data = matread(("./src/utils/" * "calibration_data/" * country * "/data/1996.mat"))
    data = data["data"]
    ea = matread(("./src/utils/" * "calibration_data/" * country * "/ea/1996.mat"))
    ea = ea["ea"]

    for k = 1:3

        global forecast = fill(NaN, number_quarters, number_horizons, number_variables)
        global actual = fill(NaN, number_quarters, number_horizons, number_variables)

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                global horizon = horizons[j]
                forecast_quarter_num = BIT.date2num(lastdayofmonth(BIT.num2date(quarter_num) + Month(3 * horizon)))

                if BIT.num2date(forecast_quarter_num) > Date(max_year, 12, 31)
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

                Y = BIT.forecast_k_steps_VAR(Y0_diff, horizon, intercept = true, lags = k)

                Y[end, [1, 3, 4, 5, 6]] = Y0[end, [1, 3, 4, 5, 6]]' + sum(Y[:, [1, 3, 4, 5, 6]], dims=1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        if k == 1
            h5open(dir * "/forecast_validation_var.h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_var = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_var = forecast - actual
        else
            h5open(dir * "/forecast_validation_var_$(k).h5", "w") do file
                write(file, "forecast", forecast)
            end
            rmse_var_k = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            bias_var_k = dropdims(nanmean(forecast - actual, 1), dims=1)
            error_var_k = forecast - actual

            forecast = h5read(dir * "/forecast_validation_var.h5","forecast")
            rmse_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
            error_var = forecast - actual
        end


        if k == 1
            global input_data = round.(rmse_var, digits=2)
            global input_data_S = string.(input_data)
        else
            input_data = - round.(100 * (rmse_var .- rmse_var_k) ./ rmse_var, digits=1)
            input_data_S = fill("", size(input_data))
            for j in 1:length(horizons)
                h = horizons[j]
                for l in 1:number_variables
                    dm_error_var_k = view(error_var_k, :, j, l)[map(!,isnan.(view(error_var_k, :, j, l)))]
                    dm_error_var = view(error_var, :, j, l)[map(!,isnan.(view(error_var, :, j, l)))]
                    _, p_value = dmtest_modified(dm_error_var,dm_error_var_k, h)
                    input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) *", "* string(stars(p_value)) * ")"
                end
            end
        end

        global tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
        global dataFormat = "%.2f"
        global tableColumnAlignment = "r"
        global tableBorders = false
        global booktabs = false
        global makeCompleteLatexDocument = false
        
        global latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

        if k == 1
            open(dir * "/rmse_validation_var.tex", "w") do fid
                for line in latex
                    write(fid, line * "\n")
                end
            end
        else
            open(dir * "/rmse_validation_var_$(k).tex", "w") do fid
                for line in latex
                    write(fid, line * "\n")
                end
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
                    _, _, p_value = mztest(mz_actual, mz_forecast)
                    input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) *", "* stars(p_value) * ")"
                end
            end
            
            latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

            open(dir * "/bias_validation_var.tex", "w") do fid
                for line in latex
                    write(fid, line * "\n")
                end
            end
        
        end
    end
    return nothing
end