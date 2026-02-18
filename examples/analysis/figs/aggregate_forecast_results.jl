# Aggregate Forecast Results - Figures (Heatmaps)
# Creates heatmaps for visual comparison of forecast performance across countries

using CSV, DataFrames, Statistics, Plots
import BeforeIT as Bit

include(joinpath(@__DIR__, "../tabs/analysis_utils.jl"))

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Change this to create heatmaps for different model variants.
# Reads from: data/{country}/analysis/{MODEL_VARIANT}/
# Writes to:  analysis/figs/multicountry/forecast_performance/{MODEL_VARIANT}/heatmaps/
#
# Options: "base", "growth_rate", "canvas"

MODEL_VARIANT = "canvas"

# =============================================================================
# MAIN SCRIPT
# =============================================================================

@info "Creating forecast heatmaps for variant: $(MODEL_VARIANT)..."

countries = Bit.discover_countries_with_predictions()
@info "Found $(length(countries)) countries"

output_dir = joinpath("analysis", "figs", "multicountry", "forecast_performance", MODEL_VARIANT, "heatmaps")
mkpath(output_dir)

for table_type in AGGREGATE_TABLE_TYPES
    result = load_country_forecast_data(MODEL_VARIANT, table_type, countries)
    result === nothing && continue

    (; valid_countries, variables, has_pvals) = result
    matrix, pval_matrix = build_12q_matrices(result)
    all(isnan, matrix) && continue

    n_countries = length(valid_countries)
    n_variables = length(variables)

    # ── Heatmap ──
    clean_vars = [replace(v, " " => "\n") for v in variables]
    plot_width = max(600, n_variables * 120)
    plot_height = max(400, n_countries * 40)

    is_bias = occursin("bias", table_type)
    is_raw_rmse = table_type in ["rmse_abm", "rmse_ar", "rmse_validation_abm", "rmse_validation_var"]
    valid_vals = matrix[.!isnan.(matrix)]

    if is_bias || !is_raw_rmse
        max_abs = maximum(abs.(valid_vals))
        p = heatmap(matrix,
            color=:RdBu, clims=(-max_abs, max_abs), colorbar=false,
            size=(plot_width, plot_height), margin=15Plots.mm,
            xticks=(1:n_variables, clean_vars), yticks=(1:n_countries, valid_countries),
            xrotation=45)
    else
        p = heatmap(matrix,
            color=:YlOrRd, colorbar=false,
            size=(plot_width, plot_height), margin=15Plots.mm,
            xticks=(1:n_variables, clean_vars), yticks=(1:n_countries, valid_countries),
            xrotation=45)
    end

    # Annotations with adaptive text color and significance stars
    for i in 1:n_countries, j in 1:n_variables
        val = matrix[i, j]
        isnan(val) && continue
        txt = is_bias ? string(round(val, digits=4)) : string(round(val, digits=1))
        if has_pvals && !isnan(pval_matrix[i, j])
            txt *= stars(pval_matrix[i, j])
        end
        if is_bias || !is_raw_rmse
            txt_color = abs(val) / max_abs > 0.65 ? :white : :black
        else
            min_val, max_val = extrema(valid_vals)
            range = max_val - min_val
            normalized = range > 0 ? (val - min_val) / range : 0.0
            txt_color = normalized > 0.7 ? :white : :black
        end
        annotate!(j, i, text(txt, 6, txt_color, :center))
    end

    savefig(p, joinpath(output_dir, "$(table_type)_heatmap.png"))
    @info "✓ $table_type"
end

@info "Done."
