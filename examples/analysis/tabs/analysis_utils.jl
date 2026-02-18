
function latexTableContent(input_data::Matrix{String}, tableRowLabels::Vector{String}, 
        dataFormat::String, tableColumnAlignment, tableBorders::Bool, booktabs::Bool, 
        makeCompleteLatexDocument::Bool)
    nrows, ncols = size(input_data)
    latex = []

    if makeCompleteLatexDocument
        push!(latex, "\\documentclass{article}")
        push!(latex, "\\begin{document}")
    end

    booktabs && push!(latex, "\\toprule")

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

    booktabs && push!(latex, "\\bottomrule")
    makeCompleteLatexDocument && push!(latex, "\\end{document}")

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

function calculate_forecast_errors(forecast, actual)
    error = forecast - actual
    rmse = dropdims(100 * sqrt.(nanmean(error.^2, 1)), dims=1)
    bias = dropdims(nanmean(error, 1), dims=1)
    return rmse, bias, error
end

function write_latex_table(filename, country, input_data_S, horizons; model_variant::String="base")
    tableRowLabels = ["$(i)q" for i in horizons]
    dataFormat, tableColumnAlignment = "%.2f", "r"
    tableBorders, booktabs, makeCompleteLatexDocument = false, false, false

    latex = latexTableContent(input_data_S, tableRowLabels, dataFormat, tableColumnAlignment, tableBorders, booktabs, makeCompleteLatexDocument)

    analysis_dir = "data/$(country)/analysis/$(model_variant)"
    mkpath(analysis_dir)
    open("$(analysis_dir)/$(filename)", "w") do fid
        for line in latex
            write(fid, line * "\n")
        end
    end
end

function write_csv_table(filename, country, input_data, horizons, number_variables; model_variant::String="base")
    """
    Write table data to CSV format for easy programmatic access.

    # Arguments
    - `filename`: CSV filename (e.g., "rmse_var.csv")
    - `country`: Country code
    - `input_data`: Matrix of numerical values (horizons × variables)
    - `horizons`: Vector of forecast horizons
    - `number_variables`: Number of variables (5 for base, 8 for validation)
    - `model_variant`: Subfolder for different model variants (default: "base")
    """

    # Variable names based on number of variables
    if number_variables == 5
        variable_names = ["Real GDP", "GDP Deflator Growth", "Real Consumption", "Real Investment", "Euribor"]
    elseif number_variables == 8
        variable_names = ["Real GDP", "GDP Deflator Growth", "Real Gov Consumption", "Real Exports", "Real Imports", "Real GDP (EA)", "GDP Deflator Growth (EA)", "Euribor"]
    else
        # Fallback for other cases
        variable_names = ["Var$i" for i in 1:number_variables]
    end

    # Create DataFrame with proper structure
    df = DataFrame()

    # Add horizon column
    df.Horizon = ["$(h)q" for h in horizons]

    # Add variable columns
    for (j, var_name) in enumerate(variable_names)
        if j <= size(input_data, 2)
            df[!, var_name] = input_data[:, j]
        else
            df[!, var_name] = fill(NaN, length(horizons))
        end
    end

    # Write CSV file
    analysis_dir = "data/$(country)/analysis/$(model_variant)"
    mkpath(analysis_dir)
    csv_path = "$(analysis_dir)/$(filename)"
    CSV.write(csv_path, df)

    @info "Saved CSV table: $csv_path"
end

function generate_dm_test_comparison(error1, error2, rmse1, rmse2, horizons, number_variables)
    input_data = -round.(100 * (rmse1 .- rmse2) ./ rmse2, digits=1)
    input_data_S = fill("", size(input_data))
    pval_matrix = fill(NaN, size(input_data))

    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            dm_error1 = view(error1, :, j, l)[map(!, isnan.(view(error1, :, j, l)))]
            dm_error2 = view(error2, :, j, l)[map(!, isnan.(view(error2, :, j, l)))]
            _, p_value = Bit.dmtest_modified(dm_error2, dm_error1, h)
            input_data_S[j, l] = string(input_data[j, l]) * "(" * string(round(p_value, digits=2)) * ", " * string(stars(p_value)) * ")"
            pval_matrix[j, l] = p_value
        end
    end
    return input_data_S, pval_matrix
end

function generate_mz_test_bias(error, actual, bias, horizons, number_variables)
    input_data = round.(bias, digits=4)
    input_data_S = fill("", size(input_data))

    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            mz_forecast = (view(error, :, j, l) + view(actual, :, j, l))[map(!, isnan.(view(error, :, j, l) + view(actual, :, j, l)))]
            mz_actual = view(actual, :, j, l)[map(!, isnan.(view(actual, :, j, l)))]
            _, _, p_value = Bit.mztest(mz_actual, mz_forecast)
            input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) * ", " * stars(p_value) * ")"
        end
    end
    return input_data_S
end

function generate_bias_ttest(error, bias, horizons, number_variables)
    input_data = round.(bias, digits=4)
    input_data_S = fill("", size(input_data))
    pval_matrix = fill(NaN, size(input_data))

    for j in 1:length(horizons)
        h = horizons[j]
        for l in 1:number_variables
            e = view(error, :, j, l)[map(!, isnan.(view(error, :, j, l)))]
            _, p_value = Bit.bias_ttest(e, h)
            input_data_S[j, l] = string(input_data[j, l]) * " (" * string(round(p_value, digits=3)) * ", " * stars(p_value) * ")"
            pval_matrix[j, l] = p_value
        end
    end
    return input_data_S, pval_matrix
end

function create_bias_rmse_tables_abm(forecast, actual, horizons, type, number_variables, country; model_variant::String="base")
    type_prefix = type == "validation" ? "validation_" : ""
    comparison_model = type == "validation" ? "var" : "ar"

    rmse_abm, bias_abm, error_abm = calculate_forecast_errors(forecast, actual)

    # 1. Save ABSOLUTE RMSE
    rmse_abs_numeric = round.(rmse_abm, digits=2)
    write_csv_table("rmse_$(type_prefix)abm.csv", country, rmse_abs_numeric, horizons, number_variables; model_variant=model_variant)
    write_latex_table("rmse_$(type_prefix)abm.tex", country, string.(rmse_abs_numeric), horizons; model_variant=model_variant)

    # 2. Save RELATIVE TO AR/VAR benchmark
    base_analysis_dir = "data/$(country)/analysis/base"
    forecast_benchmark = load("$(base_analysis_dir)/forecast_$(type_prefix)$(comparison_model).jld2")["forecast"]
    rmse_benchmark, _, error_benchmark = calculate_forecast_errors(forecast_benchmark, actual)

    rmse_vs_benchmark_latex, pval_vs_benchmark = generate_dm_test_comparison(error_abm, error_benchmark, rmse_abm, rmse_benchmark, horizons, number_variables)
    write_latex_table("rmse_$(type_prefix)abm_vs_$(comparison_model).tex", country, rmse_vs_benchmark_latex, horizons; model_variant=model_variant)

    rmse_vs_benchmark_numeric = -round.(100 * (rmse_abm .- rmse_benchmark) ./ rmse_benchmark, digits=1)
    write_csv_table("rmse_$(type_prefix)abm_vs_$(comparison_model).csv", country, rmse_vs_benchmark_numeric, horizons, number_variables; model_variant=model_variant)
    write_csv_table("pval_$(type_prefix)abm_vs_$(comparison_model).csv", country, pval_vs_benchmark, horizons, number_variables; model_variant=model_variant)

    # 3. Save VARIANT VS BASE ABM (only for non-base variants)
    if model_variant != "base"
        forecast_base_abm = load("$(base_analysis_dir)/forecast_$(type_prefix)abm.jld2")["forecast"]
        rmse_base_abm, _, error_base_abm = calculate_forecast_errors(forecast_base_abm, actual)

        rmse_vs_base_latex, pval_vs_base = generate_dm_test_comparison(error_abm, error_base_abm, rmse_abm, rmse_base_abm, horizons, number_variables)
        write_latex_table("rmse_$(type_prefix)abm_vs_base.tex", country, rmse_vs_base_latex, horizons; model_variant=model_variant)

        rmse_vs_base_numeric = -round.(100 * (rmse_abm .- rmse_base_abm) ./ rmse_base_abm, digits=1)
        write_csv_table("rmse_$(type_prefix)abm_vs_base.csv", country, rmse_vs_base_numeric, horizons, number_variables; model_variant=model_variant)
        write_csv_table("pval_$(type_prefix)abm_vs_base.csv", country, pval_vs_base, horizons, number_variables; model_variant=model_variant)
    end

    # 4. Save bias with t-test p-values (HAC standard errors)
    bias_data_latex, pval_bias = generate_bias_ttest(error_abm, bias_abm, horizons, number_variables)
    write_latex_table("bias_$(type_prefix)abm.tex", country, bias_data_latex, horizons; model_variant=model_variant)

    bias_data_numeric = round.(bias_abm, digits=4)
    write_csv_table("bias_$(type_prefix)abm.csv", country, bias_data_numeric, horizons, number_variables; model_variant=model_variant)
    write_csv_table("pval_bias_$(type_prefix)abm.csv", country, pval_bias, horizons, number_variables; model_variant=model_variant)

    return nothing
end

# =============================================================================
# SHARED CONSTANTS FOR AGGREGATE ANALYSIS
# =============================================================================

const AGGREGATE_TABLE_TYPES = [
    "rmse_abm", "bias_abm",
    "rmse_validation_abm", "bias_validation_abm",
    "rmse_abm_vs_ar", "rmse_ar", "bias_ar",
    "rmse_validation_abm_vs_var", "rmse_validation_var", "bias_validation_var",
    "rmse_abm_vs_base",
    "rmse_validation_abm_vs_base",
]

const AGG_BASE_VARIABLES = ["Real GDP", "GDP Deflator Growth", "Real Consumption", "Real Investment", "Euribor"]
const AGG_VALIDATION_VARIABLES = ["Real GDP", "GDP Deflator Growth", "Real Gov Consumption", "Real Exports",
                                   "Real Imports", "Real GDP (EA)", "GDP Deflator Growth (EA)", "Euribor"]

const FORECAST_HORIZONS = [1, 2, 4, 8, 12]

get_variables_for_table(t) = occursin("validation", t) ? AGG_VALIDATION_VARIABLES : AGG_BASE_VARIABLES

const VARIANT_CONFIG = Dict(
    "base"        => (prediction_folder="abm_predictions",             extension_file=nothing),
    "growth_rate" => (prediction_folder="abm_predictions_growth_rate", extension_file="../../GrowthRateAR1_extension.jl"),
    "canvas"      => (prediction_folder="abm_predictions_canvas",      extension_file="../../CANVAS_extension.jl"),
)

# =============================================================================
# SHARED DATA LOADING FOR AGGREGATE ANALYSIS
# =============================================================================

"""
    load_country_forecast_data(model_variant, table_type, countries)

Load per-country CSVs and optional p-value CSVs for a given table type.
Returns a NamedTuple (country_data, pval_data, valid_countries, variables, has_pvals)
or `nothing` if no data found.
"""
function load_country_forecast_data(model_variant, table_type, countries)
    variables = get_variables_for_table(table_type)

    country_data = Dict{String, DataFrame}()
    for country in countries
        csv_file = joinpath("data", country, "analysis", model_variant, "$(table_type).csv")
        isfile(csv_file) || continue
        try
            df = CSV.read(csv_file, DataFrame)
            if startswith(table_type, "rmse_") && !occursin("vs_", table_type)
                numeric_cols = [c for c in names(df) if c != "Horizon" && eltype(df[!, c]) <: Number]
                if any(any(x -> !ismissing(x) && !isnan(x) && x < 0, df[!, c]) for c in numeric_cols)
                    @warn "Skipping $csv_file: negative values in absolute RMSE"
                    continue
                end
            end
            country_data[country] = df
        catch e
            @warn "Failed to load $csv_file" exception=(e, catch_backtrace())
        end
    end

    isempty(country_data) && return nothing
    valid_countries = sort(collect(keys(country_data)))

    is_comparison = occursin("_vs_", table_type)
    is_bias = startswith(table_type, "bias_")
    has_pvals = is_comparison || is_bias

    pval_data = Dict{String, DataFrame}()
    if has_pvals
        pval_name = is_comparison ? replace(table_type, "rmse_" => "pval_") : "pval_" * table_type
        for country in valid_countries
            pval_file = joinpath("data", country, "analysis", model_variant, "$(pval_name).csv")
            isfile(pval_file) || continue
            try
                pval_data[country] = CSV.read(pval_file, DataFrame)
            catch e
                @warn "Failed to load $pval_file" exception=(e, catch_backtrace())
            end
        end
    end

    return (; country_data, pval_data, valid_countries, variables, has_pvals)
end

"""
    build_12q_matrices(result)

Build country x variable matrices from 12q horizon data.
Takes the output of `load_country_forecast_data`.
Returns (matrix, pval_matrix).
"""
function build_12q_matrices(result)
    (; country_data, pval_data, valid_countries, variables, has_pvals) = result
    n_countries = length(valid_countries)
    n_variables = length(variables)

    matrix = fill(NaN, n_countries, n_variables)
    pval_matrix = fill(NaN, n_countries, n_variables)

    for (i, country) in enumerate(valid_countries)
        df = country_data[country]
        row_12q = df[df.Horizon .== "12q", :]
        nrow(row_12q) == 1 || continue
        for (j, var) in enumerate(variables)
            if var in names(df) && !ismissing(row_12q[1, var]) && !isnan(row_12q[1, var])
                matrix[i, j] = row_12q[1, var]
            end
        end
        if has_pvals && haskey(pval_data, country)
            pdf = pval_data[country]
            prow = pdf[pdf.Horizon .== "12q", :]
            nrow(prow) == 1 || continue
            for (j, var) in enumerate(variables)
                if var in names(pdf) && !ismissing(prow[1, var]) && !isnan(prow[1, var])
                    pval_matrix[i, j] = prow[1, var]
                end
            end
        end
    end

    return matrix, pval_matrix
end

"""
    discover_countries_with_variant_predictions(prediction_folder)

Find country codes that have JLD2 prediction files in the given folder.
"""
function discover_countries_with_variant_predictions(prediction_folder::String)
    countries = String[]
    isdir("data") || return countries
    for entry in readdir("data")
        preds_dir = joinpath("data", entry, prediction_folder)
        if isdir(preds_dir) && any(endswith(".jld2"), readdir(preds_dir))
            push!(countries, entry)
        end
    end
    return sort(countries)
end

# =============================================================================
# PER-COUNTRY TABLE GENERATION
# =============================================================================

function create_bias_rmse_tables_var(forecast, actual, horizons, forecast_type, model_type, number_variables, k, country; model_variant::String="base")
    type_prefix = forecast_type == "validation" ? "validation_" : ""
    analysis_dir = "data/$(country)/analysis/$(model_variant)"
    mkpath(analysis_dir)

    if k == 1
        save("$(analysis_dir)/forecast_$(type_prefix)$(model_type).jld2", "forecast", forecast)
        rmse_var, bias_var, error_var = calculate_forecast_errors(forecast, actual)

        # Save RMSE data
        input_data_rmse = round.(rmse_var, digits=2)
        write_latex_table("rmse_$(type_prefix)$(model_type).tex", country, string.(input_data_rmse), horizons; model_variant=model_variant)
        write_csv_table("rmse_$(type_prefix)$(model_type).csv", country, input_data_rmse, horizons, number_variables; model_variant=model_variant)

        # Save bias data with t-test p-values (HAC standard errors)
        bias_data_latex, pval_bias = generate_bias_ttest(error_var, bias_var, horizons, number_variables)
        write_latex_table("bias_$(type_prefix)$(model_type).tex", country, bias_data_latex, horizons; model_variant=model_variant)

        # For CSV, save just the numerical bias values (without p-values and stars)
        bias_data_numeric = round.(bias_var, digits=4)
        write_csv_table("bias_$(type_prefix)$(model_type).csv", country, bias_data_numeric, horizons, number_variables; model_variant=model_variant)
        write_csv_table("pval_bias_$(type_prefix)$(model_type).csv", country, pval_bias, horizons, number_variables; model_variant=model_variant)

    else
        save("$(analysis_dir)/forecast_$(type_prefix)$(model_type)_$(k).jld2", "forecast", forecast)
        rmse_var_k, _, error_var_k = calculate_forecast_errors(forecast, actual)

        forecast_base_var = load("$(analysis_dir)/forecast_$(type_prefix)$(model_type).jld2")["forecast"]
        rmse_base_var, _, error_base_var = calculate_forecast_errors(forecast_base_var, actual)

        # Generate comparison data for LaTeX (with p-values and stars)
        rmse_comparison_data_latex, pval_comparison = generate_dm_test_comparison(error_var_k, error_base_var, rmse_var_k, rmse_base_var, horizons, number_variables)
        write_latex_table("rmse_$(type_prefix)$(model_type)_$(k).tex", country, rmse_comparison_data_latex, horizons; model_variant=model_variant)

        # For CSV, save just the numerical comparison values (percentage improvement)
        rmse_comparison_data_numeric = -round.(100 * (rmse_var_k .- rmse_base_var) ./ rmse_base_var, digits=1)
        write_csv_table("rmse_$(type_prefix)$(model_type)_$(k).csv", country, rmse_comparison_data_numeric, horizons, number_variables; model_variant=model_variant)
        write_csv_table("pval_$(type_prefix)$(model_type)_$(k).csv", country, pval_comparison, horizons, number_variables; model_variant=model_variant)
    end
end