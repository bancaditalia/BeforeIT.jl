
function latexTableContent(input_data::Matrix{String}, tableRowLabels::Vector{String}, 
        dataFormat::String, tableColumnAlignment, tableBorders::Bool, booktabs::Bool, 
        makeCompleteLatexDocument::Bool)
    nrows, ncols = size(input_data)
    latex = []

    if makeCompleteLatexDocument
        push!(latex, "\\documentclass{article}")
        push!(latex, "\\begin{document}")
    end

    if booktabs
        push!(latex, "\\toprule")
    end

    for row in 1:nrows
        row_content = [tableRowLabels[row]]
        for col in 1:ncols
            push!(row_content, input_data[row, col])
        end
        if row < nrows
            push!(latex, join(row_content, " & "), " \\\\ ")
        else
            push!(latex, join(row_content, " & "))
        end
    end

    if booktabs
        push!(latex, "\\bottomrule")
    end

    if makeCompleteLatexDocument
        push!(latex, "\\end{document}")
    end

    return latex
end

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

nanmean(x) = mean(filter(!isnan,x))
nanmean(x,y) = mapslices(nanmean,x; dims = y)

function create_bias_rmse_tables_abm(forecast, actual, horizons, type, number_variables)

    type = type == "validation" ? "validation_" : ""

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    rmse_validation_abm = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
    bias_validation_abm = dropdims(nanmean(forecast - actual, 1), dims=1)
    error_validation_abm = forecast - actual

    forecast = load("data/$(country)/analysis/forecast_$(type)abm.jld2")["forecast"]

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

    open("data/$(country)/analysis/rmse_$(type)abm.tex", "w") do fid
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

    open("data/$(country)/analysis/bias_$(type)abm.tex", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end

    return nothing
end

function create_bias_rmse_tables_var(forecast, actual, horizons, type, number_variables, k)
    type = type == "validation" ? "validation_" : ""

    tableRowLabels = ["1q", "2q", "4q", "8q", "12q"]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    if k == 1
        save("data/$(country)/analysis/forecast_$(type)var.jld2", "forecast", forecast)
        rmse_var = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
        bias_var = dropdims(nanmean(forecast - actual, 1), dims=1)
        error_var = forecast - actual
    else
        save("data/$(country)/analysis/forecast_$(type)var_$(k).jld2", "forecast", forecast)
        rmse_var_k = dropdims(100 * sqrt.(nanmean((forecast - actual).^2,1)), dims=1)
        bias_var_k = dropdims(nanmean(forecast - actual, 1), dims=1)
        error_var_k = forecast - actual

        forecast = load("data/$(country)/analysis/forecast_$(type)var.jld2")["forecast"]
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
    open("data/$(country)/analysis/rmse_$(type)var" * idx * ".tex", "w") do fid
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

        open("data/$(country)/analysis/bias_$(type)var.tex", "w") do fid
            for line in latex
                write(fid, line * "\n")
            end
        end
    end
end