
function error_table_validation_abm(country::String)

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    number_quarters = 4 * 10
    quarters_num = [Bit.date2num(date) for date in DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31)]
    max_year = 2019
    
    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 8

    forecast = fill(NaN, number_quarters, number_horizons, number_variables)
    actual = fill(NaN, number_quarters, number_horizons, number_variables)

    quarter_num = quarters_num[1]
    model = load("./data/" * country * "/abm_predictions/" * string(year(Bit.num2date(quarter_num))) * "Q" * string(Dates.quarterofyear(Bit.num2date(quarter_num))) *".jld2","model_dict");
    number_of_seeds = size(model["real_gdp_quarterly"],2)

    ea = matread(("data/$(country)/calibration/ea/1996.mat"))["ea"]
    data = matread(("data/$(country)/calibration/data/1996.mat"))["data"]

    for i in 1:number_quarters
        quarter_num = quarters_num[i]
        
        model = load("./data/"* country *"/abm_predictions/" * string(year(Bit.num2date(quarter_num))) * "Q" * string(Dates.quarterofyear(Bit.num2date(quarter_num))) *".jld2","model_dict");

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


            forecast[i, j, :] = hcat(collect([
                log.(mean(model["real_gdp_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(1 .+ mean(model["gdp_deflator_growth_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_government_consumption_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_exports_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_imports_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_gdp_ea_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(1 .+ mean(model["gdp_deflator_growth_ea_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                (1 .+ mean(model["euribor"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])).^(1/4)
                ])...)

        end
    end

    h5open("data/" * country * "/analysis/forecast_validation_abm.h5", "w") do file
        write(file, "forecast", forecast)
    end

    rmse_validation_abm = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
    bias_validation_abm = dropdims(nanmean(forecast - actual, 1), dims=1)
    error_validation_abm = forecast - actual

    file_path = "data/" * country * "/analysis/forecast_validation_var.h5"
    forecast = h5open(file_path, "r") do file
        forecast = read(file["forecast"])
    end

    rmse_validation_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
    error_validation_var = forecast - actual

    input_data = - round.(100 * (rmse_validation_abm .- rmse_validation_var) ./ rmse_validation_var, digits=1)
    input_data_S = fill("", size(input_data))
    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            dm_error_validation_abm = view(error_validation_abm, :, j, l)[map(!,isnan.(view(error_validation_abm, :, j, l)))]
            dm_error_validation_var = view(error_validation_var, :, j, l)[map(!,isnan.(view(error_validation_var, :, j, l)))]
            _, p_value = Bit.dmtest_modified(dm_error_validation_var,dm_error_validation_abm, h)
            input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) *", "* string(stars(p_value)) * ")"
        end
    end

    latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

    open("data/" * country * "/analysis/rmse_validation_abm.tex", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end

    input_data = round.(bias_validation_abm, digits=4)
    input_data_S = fill("", size(input_data))

    for j in 1:length(horizons)
        
        h = horizons[j]
        for l in 1:number_variables
            mz_forecast = (view(error_validation_abm, :, j, l) + view(actual, :, j, l))[map(!,isnan.(view(error_validation_abm, :, j, l) + view(actual, :, j, l)))]
            mz_actual = view(actual, :, j, l)[map(!,isnan.(view(actual, :, j, l)))]
            _, _, p_value = Bit.mztest(mz_actual, mz_forecast)
            input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) *", "* stars(p_value) * ")"
        end
    end

    latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

    open("data/" * country * "/analysis/bias_validation_abm.tex", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end

    return nothing
end
