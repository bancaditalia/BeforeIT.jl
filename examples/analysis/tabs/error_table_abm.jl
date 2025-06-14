
function error_table_abm(country::String, ea, data, quarters)

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    quarters_num = Bit.date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    horizons = [1, 2, 4, 8, 12]
    number_horizons = length(horizons)
    number_variables = 5

    forecast = fill(NaN, number_quarters, number_horizons, number_variables)
    actual = fill(NaN, number_quarters, number_horizons, number_variables)

    quarter_num = quarters_num[1]
    model = load("./data/" * country * "/abm_predictions/" * string(year(Bit.num2date(quarter_num))) * "Q" * string(Dates.quarterofyear(Bit.num2date(quarter_num))) *".jld2","model_dict");
    number_of_seeds = size(model["real_gdp_quarterly"],2)

    for i in 1:number_quarters
        quarter_num = quarters_num[i]

        model = load("./data/" * country * "/abm_predictions/" * string(year(Bit.num2date(quarter_num))) * "Q" * string(Dates.quarterofyear(Bit.num2date(quarter_num))) *".jld2","model_dict");
        
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

            forecast[i, j, :] = hcat(collect([
                log.(mean(model["real_gdp_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(1 .+ mean(model["gdp_deflator_growth_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_household_consumption_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                log.(mean(model["real_fixed_capitalformation_quarterly"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])),
                (1 .+ mean(model["euribor"][repeat(model["quarters_num"] .== forecast_quarter_num,1,number_of_seeds)])).^(1/4)
                ])...)
        end
    end

    h5open("data/" * country * "/analysis/forecast_abm.h5", "w") do file
        write(file, "forecast", forecast)
    end

    rmse_abm = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
    bias_abm = dropdims(nanmean(forecast - actual, 1), dims=1)
    error_abm = forecast - actual

    file_path = "data/" * country * "/analysis/forecast_ar.h5"

    forecast = h5open(file_path, "r") do file
        read(file["forecast"])
    end

    rmse_ar = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
    error_ar = forecast - actual

    input_data = - round.( 100 * (rmse_abm .- rmse_ar) ./ rmse_ar, digits=1)
    input_data_S = fill("", size(input_data))

    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            dm_error_abm = view(error_abm, :, j, l)[map(!,isnan.(view(error_abm, :, j, l)))]
            dm_error_ar = view(error_ar, :, j, l)[map(!,isnan.(view(error_ar, :, j, l)))]
            _, p_value = Bit.dmtest_modified(dm_error_abm,dm_error_ar, h)
            input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) *", "* string(stars(p_value)) * ")"
        end
    end

    latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

    open("data/" * country * "/analysis/rmse_abm.tex", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end

    input_data = round.(bias_abm, digits=4)
    input_data_S = fill("", size(input_data))

    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            mz_forecast = (view(error_abm, :, j, l) + view(actual, :, j, l))[map(!,isnan.(view(error_abm, :, j, l) + view(actual, :, j, l)))]
            mz_actual = view(actual, :, j, l)[map(!,isnan.(view(actual, :, j, l)))]
            _, _, p_value = Bit.mztest(mz_actual, mz_forecast)
            input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) *", "* stars(p_value) * ")"
        end
    end

    latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

    open("data/" * country * "/analysis/bias_abm.tex", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end
    return nothing
end

