# Aggregate Forecast Results - Tables (CSV and LaTeX)
# Aggregates per-country forecast results into cross-country summaries

using CSV, DataFrames, Statistics, Printf
import BeforeIT as Bit

include(joinpath(@__DIR__, "analysis_utils.jl"))

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Change this to aggregate results for different model variants.
# Reads from: data/{country}/analysis/{MODEL_VARIANT}/
# Writes to:  analysis/tabs/multicountry_forecast_results/{MODEL_VARIANT}/
#
# Options: "base", "growth_rate", "canvas"

MODEL_VARIANT = "canvas"

# =============================================================================
# MAIN SCRIPT
# =============================================================================

@info "Aggregating forecast results for variant: $(MODEL_VARIANT)..."

countries = Bit.discover_countries_with_predictions()
@info "Found $(length(countries)) countries"

output_base = joinpath("analysis", "tabs", "multicountry_forecast_results", MODEL_VARIANT)
mkpath(joinpath(output_base, "countries"))
mkpath(joinpath(output_base, "latex"))

for table_type in AGGREGATE_TABLE_TYPES
    result = load_country_forecast_data(MODEL_VARIANT, table_type, countries)
    result === nothing && (@warn "No data for $table_type"; continue)

    (; country_data, valid_countries, variables, has_pvals) = result
    matrix, pval_matrix = build_12q_matrices(result)
    all(isnan, matrix) && continue

    n_countries = length(valid_countries)
    n_variables = length(variables)
    is_bias = startswith(table_type, "bias_")

    # ── Country x Variable CSV (12q horizon with significance stars) ──
    if has_pvals
        digits = is_bias ? 4 : 1
        str_matrix = Matrix{String}(undef, n_countries, n_variables)
        for i in 1:n_countries, j in 1:n_variables
            if isnan(matrix[i, j])
                str_matrix[i, j] = ""
            else
                val_str = string(round(matrix[i, j], digits=digits))
                star_str = isnan(pval_matrix[i, j]) ? "" : stars(pval_matrix[i, j])
                str_matrix[i, j] = val_str * star_str
            end
        end
        summary_df = DataFrame(str_matrix, variables)
    else
        summary_df = DataFrame(matrix, variables)
    end
    summary_df.Country = valid_countries
    select!(summary_df, :Country, Not(:Country))
    CSV.write(joinpath(output_base, "countries", "$(table_type)_countries.csv"), summary_df)

    # ── Horizon x Variable LaTeX table (cross-country mean +/- SE) ──
    n_horizons = length(FORECAST_HORIZONS)
    mean_vals = fill(NaN, n_horizons, n_variables)
    std_errs = fill(NaN, n_horizons, n_variables)

    for (i, h) in enumerate(FORECAST_HORIZONS), (j, var) in enumerate(variables)
        vals = Float64[]
        for country in valid_countries
            df = country_data[country]
            var in names(df) || continue
            rows = df[df.Horizon .== "$(h)q", :]
            if nrow(rows) == 1 && !ismissing(rows[1, var]) && !isnan(rows[1, var])
                push!(vals, rows[1, var])
            end
        end
        if !isempty(vals)
            mean_vals[i, j] = mean(vals)
            std_errs[i, j] = std(vals) / sqrt(length(vals))
        end
    end

    open(joinpath(output_base, "latex", "cross_country_$(table_type).tex"), "w") do f
        println(f, "% Cross-country aggregated table for $table_type")
        for (i, h) in enumerate(FORECAST_HORIZONS)
            row = ["$(h)q"]
            for j in 1:n_variables
                if !isnan(mean_vals[i,j]) && !isnan(std_errs[i,j])
                    push!(row, @sprintf("%.1f(%.1f)", mean_vals[i,j], std_errs[i,j]))
                else
                    push!(row, "N/A")
                end
            end
            println(f, join(row, " & "), i < n_horizons ? " \\\\ " : "")
        end
    end

    @info "✓ $table_type: $(n_countries) countries"
end

@info "Done."
