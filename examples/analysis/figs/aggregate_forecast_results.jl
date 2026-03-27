# Aggregate Forecast Results - Figures (Heatmaps)
# Creates heatmaps for visual comparison of forecast performance across countries

using DataFrames, Statistics, Plots
import BeforeIT as Bit

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Change this to create heatmaps for different model variants.
# Reads from: data/{country}/analysis/{model_variant}/
# Writes to:  analysis/figs/forecast_performance/{model_variant}/
#
# Options: "base", "growth_rate", "canvas"

model_variant = "base"

# =============================================================================
# MAIN SCRIPT
# =============================================================================

@info "Creating forecast heatmaps for variant: $(model_variant)..."

countries = Bit.discover_countries(model_variant)
@info "Found $(length(countries)) countries"

output_dir = joinpath("analysis", "figs", "forecast_performance", model_variant)
mkpath(output_dir)

for table_type in Bit.aggregate_table_types
    result = Bit.load_country_forecast_data(model_variant, table_type, countries)
    result === nothing && continue

    (; valid_countries, variables, has_pvals) = result
    matrix, pval_matrix = Bit.build_12q_matrices(result)
    all(isnan, matrix) && continue

    n_countries = length(valid_countries)
    n_variables = length(variables)
    valid_vals = matrix[.!isnan.(matrix)]

    is_bias = occursin("bias", table_type)
    is_raw_rmse = table_type in ["rmse_abm", "rmse_ar", "rmse_validation_abm", "rmse_validation_var"]
    is_diverging = is_bias || !is_raw_rmse

    # Pre-compute color scale bounds once
    max_abs = maximum(abs.(valid_vals))
    val_min, val_max = extrema(valid_vals)
    val_range = val_max - val_min

    color_kwargs = is_diverging ? (color = :RdBu, clims = (-max_abs, max_abs)) : (color = :YlOrRd,)
    clean_vars = [replace(v, " " => "\n") for v in variables]

    p = heatmap(
        matrix;
        colorbar = false,
        size = (max(600, n_variables * 120), max(400, n_countries * 40)),
        margin = 15Plots.mm,
        xticks = (1:n_variables, clean_vars),
        yticks = (1:n_countries, valid_countries),
        xrotation = 45,
        color_kwargs...,
    )

    for i in 1:n_countries, j in 1:n_variables
        val = matrix[i, j]
        isnan(val) && continue
        txt = string(round(val, digits = is_bias ? 4 : 1))
        has_pvals && !isnan(pval_matrix[i, j]) && (txt *= Bit.stars(pval_matrix[i, j]))
        txt_color = if is_diverging
            abs(val) / max_abs > 0.65 ? :white : :black
        else
            normalized = val_range > 0 ? (val - val_min) / val_range : 0.0
            normalized > 0.7 ? :white : :black
        end
        annotate!(j, i, text(txt, 6, txt_color, :center))
    end

    savefig(p, joinpath(output_dir, "$(table_type)_heatmap.png"))
    @info "✓ $table_type"
end

@info "Done."
