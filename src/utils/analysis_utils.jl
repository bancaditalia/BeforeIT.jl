using CSV, DataFrames, Dates, Statistics
using JLD2: load, save

# =============================================================================
# CONSTANTS
# =============================================================================

const agg_base_variables = ["Real GDP", "GDP Deflator Growth", "Real Consumption", "Real Investment", "Euribor"]
const agg_validation_variables = [
    "Real GDP", "GDP Deflator Growth", "Real Gov Consumption", "Real Exports",
    "Real Imports", "Real GDP (EA)", "GDP Deflator Growth (EA)", "Euribor",
]
const forecast_horizons = [1, 2, 4, 8, 12]
const aggregate_table_types = [
    "rmse_abm", "bias_abm",
    "rmse_validation_abm", "bias_validation_abm",
    "rmse_abm_vs_ar", "rmse_ar", "bias_ar",
    "rmse_validation_abm_vs_var", "rmse_validation_var", "bias_validation_var",
    "rmse_abm_vs_base",
    "rmse_validation_abm_vs_base",
]

get_variables_for_table(t) = occursin("validation", t) ? agg_validation_variables : agg_base_variables

# =============================================================================
# HELPERS
# =============================================================================

function stars(p_value)
    p_value < 0.01 && return "***"
    p_value < 0.05 && return "**"
    p_value < 0.1  && return "*"
    return ""
end

nanmean(x) = mean(filter(!isnan, x))
nanmean(x, y) = mapslices(nanmean, x; dims = y)

function calculate_forecast_errors(forecast, actual)
    error = forecast - actual
    rmse = dropdims(100 * sqrt.(nanmean(error .^ 2, 1)), dims = 1)
    bias = dropdims(nanmean(error, 1), dims = 1)
    return rmse, bias, error
end

rmse_improvement(rmse1, rmse2) = -round.(100 * (rmse1 .- rmse2) ./ rmse2, digits = 1)

# =============================================================================
# TABLE WRITING
# =============================================================================

function write_latex_table(filename, country, input_data_S, horizons; model_variant = "base")
    nrows = size(input_data_S, 1)
    row_labels = ["$(i)q" for i in horizons]
    lines = [
        join([row_labels[row]; input_data_S[row, :]], " & ") * (row < nrows ? " \\\\ " : "")
        for row in 1:nrows
    ]
    analysis_dir = "data/$country/analysis/$model_variant"
    mkpath(analysis_dir)
    open("$analysis_dir/$filename", "w") do f
        foreach(line -> write(f, line * "\n"), lines)
    end
end

function write_csv_table(filename, country, input_data, horizons, variable_names; model_variant = "base")
    df = DataFrame(Horizon = ["$(h)q" for h in horizons])
    for (j, var) in enumerate(variable_names)
        df[!, var] = input_data[:, j]
    end
    analysis_dir = "data/$country/analysis/$model_variant"
    mkpath(analysis_dir)
    CSV.write("$analysis_dir/$filename", df)
end

# =============================================================================
# STATISTICAL TEST WRAPPERS
# =============================================================================

function generate_dm_test_comparison(error1, error2, rmse1, rmse2, horizons)
    input_data = rmse_improvement(rmse1, rmse2)
    input_data_S = fill("", size(input_data))
    pval_matrix = fill(NaN, size(input_data))

    for j in eachindex(horizons), l in 1:size(rmse1, 2)
        e1 = view(error1, :, j, l)
        e2 = view(error2, :, j, l)
        dm_e1 = e1[.!isnan.(e1)]
        dm_e2 = e2[.!isnan.(e2)]
        _, p_value = dmtest_modified(dm_e2, dm_e1, horizons[j])
        input_data_S[j, l] = "$(input_data[j, l])($(round(p_value, digits=2)), $(stars(p_value)))"
        pval_matrix[j, l] = p_value
    end
    return input_data_S, pval_matrix
end

function generate_bias_ttest(error, bias, horizons)
    input_data = round.(bias, digits = 4)
    input_data_S = fill("", size(input_data))
    pval_matrix = fill(NaN, size(input_data))

    for j in eachindex(horizons), l in 1:size(bias, 2)
        e = view(error, :, j, l)
        _, p_value = bias_ttest(e[.!isnan.(e)], horizons[j])
        input_data_S[j, l] = "$(input_data[j, l]) ($(round(p_value, digits=3)), $(stars(p_value)))"
        pval_matrix[j, l] = p_value
    end
    return input_data_S, pval_matrix
end

# =============================================================================
# PER-COUNTRY TABLE GENERATION
# =============================================================================

function create_bias_rmse_tables_abm(forecast, actual, horizons, type, variable_names, country; model_variant = "base")
    type_prefix = type == "validation" ? "validation_" : ""
    comparison_model = type == "validation" ? "var" : "ar"

    rmse_abm, bias_abm, error_abm = calculate_forecast_errors(forecast, actual)

    # 1. Absolute RMSE
    rmse_abs = round.(rmse_abm, digits = 2)
    write_csv_table("rmse_$(type_prefix)abm.csv", country, rmse_abs, horizons, variable_names; model_variant)
    write_latex_table("rmse_$(type_prefix)abm.tex", country, string.(rmse_abs), horizons; model_variant)

    # 2. Relative to AR/VAR benchmark
    benchmark_file = "data/$country/analysis/$model_variant/forecast_$(type_prefix)$(comparison_model).jld2"
    forecast_benchmark = load(benchmark_file)["forecast"]
    rmse_benchmark, _, error_benchmark = calculate_forecast_errors(forecast_benchmark, actual)

    rmse_vs_benchmark_latex, pval_vs_benchmark = generate_dm_test_comparison(error_abm, error_benchmark, rmse_abm, rmse_benchmark, horizons)
    write_latex_table("rmse_$(type_prefix)abm_vs_$(comparison_model).tex", country, rmse_vs_benchmark_latex, horizons; model_variant)
    write_csv_table("rmse_$(type_prefix)abm_vs_$(comparison_model).csv", country, rmse_improvement(rmse_abm, rmse_benchmark), horizons, variable_names; model_variant)
    write_csv_table("pval_$(type_prefix)abm_vs_$(comparison_model).csv", country, pval_vs_benchmark, horizons, variable_names; model_variant)

    # 3. Relative to base ABM (non-base variants only)
    if model_variant != "base"
        base_abm_file = "data/$country/analysis/base/forecast_$(type_prefix)abm.jld2"
        if isfile(base_abm_file)
            forecast_base_abm = load(base_abm_file)["forecast"]
            rmse_base_abm, _, error_base_abm = calculate_forecast_errors(forecast_base_abm, actual)

            rmse_vs_base_latex, pval_vs_base = generate_dm_test_comparison(error_abm, error_base_abm, rmse_abm, rmse_base_abm, horizons)
            write_latex_table("rmse_$(type_prefix)abm_vs_base.tex", country, rmse_vs_base_latex, horizons; model_variant)
            write_csv_table("rmse_$(type_prefix)abm_vs_base.csv", country, rmse_improvement(rmse_abm, rmse_base_abm), horizons, variable_names; model_variant)
            write_csv_table("pval_$(type_prefix)abm_vs_base.csv", country, pval_vs_base, horizons, variable_names; model_variant)
        else
            @warn "Skipping base ABM comparison for $country: base variant not yet available"
        end
    end

    # 4. Bias with HAC t-test
    bias_latex, pval_bias = generate_bias_ttest(error_abm, bias_abm, horizons)
    write_latex_table("bias_$(type_prefix)abm.tex", country, bias_latex, horizons; model_variant)
    write_csv_table("bias_$(type_prefix)abm.csv", country, round.(bias_abm, digits = 4), horizons, variable_names; model_variant)
    write_csv_table("pval_bias_$(type_prefix)abm.csv", country, pval_bias, horizons, variable_names; model_variant)

    return nothing
end

function create_bias_rmse_tables_var(forecast, actual, horizons, forecast_type, model_type, variable_names, k, country; model_variant = "base")
    type_prefix = forecast_type == "validation" ? "validation_" : ""
    analysis_dir = "data/$country/analysis/$model_variant"
    mkpath(analysis_dir)

    return if k == 1
        save("$analysis_dir/forecast_$(type_prefix)$(model_type).jld2", "forecast", forecast)
        rmse_var, bias_var, error_var = calculate_forecast_errors(forecast, actual)

        write_latex_table("rmse_$(type_prefix)$(model_type).tex", country, string.(round.(rmse_var, digits = 2)), horizons; model_variant)
        write_csv_table("rmse_$(type_prefix)$(model_type).csv", country, round.(rmse_var, digits = 2), horizons, variable_names; model_variant)

        bias_latex, pval_bias = generate_bias_ttest(error_var, bias_var, horizons)
        write_latex_table("bias_$(type_prefix)$(model_type).tex", country, bias_latex, horizons; model_variant)
        write_csv_table("bias_$(type_prefix)$(model_type).csv", country, round.(bias_var, digits = 4), horizons, variable_names; model_variant)
        write_csv_table("pval_bias_$(type_prefix)$(model_type).csv", country, pval_bias, horizons, variable_names; model_variant)

    else
        save("$analysis_dir/forecast_$(type_prefix)$(model_type)_$(k).jld2", "forecast", forecast)
        rmse_var_k, _, error_var_k = calculate_forecast_errors(forecast, actual)

        forecast_base_var = load("$analysis_dir/forecast_$(type_prefix)$(model_type).jld2")["forecast"]
        rmse_base_var, _, error_base_var = calculate_forecast_errors(forecast_base_var, actual)

        rmse_comparison_latex, pval_comparison = generate_dm_test_comparison(error_var_k, error_base_var, rmse_var_k, rmse_base_var, horizons)
        write_latex_table("rmse_$(type_prefix)$(model_type)_$(k).tex", country, rmse_comparison_latex, horizons; model_variant)
        write_csv_table("rmse_$(type_prefix)$(model_type)_$(k).csv", country, rmse_improvement(rmse_var_k, rmse_base_var), horizons, variable_names; model_variant)
        write_csv_table("pval_$(type_prefix)$(model_type)_$(k).csv", country, pval_comparison, horizons, variable_names; model_variant)
    end
end

# =============================================================================
# SHARED DATA LOADING FOR AGGREGATE ANALYSIS
# =============================================================================

"""
    load_country_forecast_data(model_variant, table_type, countries)

Load per-country CSVs and optional p-value CSVs for a given table type.
Returns a NamedTuple `(country_data, pval_data, valid_countries, variables, has_pvals)`
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
            @warn "Failed to load $csv_file" exception = (e, catch_backtrace())
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
                @warn "Failed to load $pval_file" exception = (e, catch_backtrace())
            end
        end
    end

    return (; country_data, pval_data, valid_countries, variables, has_pvals)
end

"""
    build_12q_matrices(result)

Build country × variable matrices from the 12q horizon.
Takes the output of `load_country_forecast_data`. Returns `(matrix, pval_matrix)`.
"""
function build_12q_matrices(result; horizon = "12q")
    (; country_data, pval_data, valid_countries, variables, has_pvals) = result
    n_countries = length(valid_countries)
    n_variables = length(variables)

    matrix = fill(NaN, n_countries, n_variables)
    pval_matrix = fill(NaN, n_countries, n_variables)

    for (i, country) in enumerate(valid_countries)
        df = country_data[country]
        row = df[df.Horizon .== horizon, :]
        nrow(row) == 1 || continue
        for (j, var) in enumerate(variables)
            if var in names(df) && !ismissing(row[1, var]) && !isnan(row[1, var])
                matrix[i, j] = row[1, var]
            end
        end
        if has_pvals && haskey(pval_data, country)
            pdf = pval_data[country]
            prow = pdf[pdf.Horizon .== horizon, :]
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

# =============================================================================
# COUNTRY DISCOVERY
# =============================================================================

"""
    discover_countries(; folder="data", subfolder="abm_predictions/base")

Find country codes that have JLD2 files in the given subfolder.

# Examples
```julia
discover_countries(; subfolder="abm_predictions/base")   # base predictions
discover_countries(; subfolder="abm_predictions/canvas") # canvas predictions
discover_countries(; subfolder="parameters")             # calibrated countries
```
"""
function discover_countries(; folder::String = "data", subfolder::String = "abm_predictions/base")
    countries = String[]
    isdir(folder) || return countries
    for entry in readdir(folder)
        dir = joinpath(folder, entry, subfolder)
        isdir(dir) && any(endswith(".jld2"), readdir(dir)) && push!(countries, entry)
    end
    return sort(countries)
end

discover_countries(variant::String; folder::String = "data") =
    discover_countries(; folder = folder, subfolder = "abm_predictions/$variant")
