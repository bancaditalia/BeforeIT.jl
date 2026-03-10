# Single-Country Cross-Correlation Analysis
# Creates cross-correlation and autocorrelation plots for a single country
#
# Supports base model and extension variants (CANVAS, GrowthRateAR1).
# Set model_variant, prediction_folder, and model_factory below.

using StatsBase, LinearAlgebra, Statistics, Dates
using Plots, JLD2, FileIO
import BeforeIT as Bit

# =============================================================================
# CONFIGURATION
# =============================================================================

country = "at"  # Country code
correlation_lags = 15
autocorr_lags = 20

plot_variables = [
    "real_capitalformation_quarterly",
    "wages_quarterly",
    "real_household_consumption_quarterly",
    "gdp_deflator_quarterly",
]

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Change these to run analysis for different model variants.
# Output will be saved to: analysis/figs/{country}/{model_variant}/
#
# Options:
#   model_variant = "base"           prediction_folder = "abm_predictions/crosscorr"               model_factory = nothing
#   model_variant = "growth_rate"    prediction_folder = "abm_predictions/growth_rate_crosscorr"   model_factory = Bit.ModelGR
#   model_variant = "canvas"         prediction_folder = "abm_predictions/canvas_crosscorr"        model_factory = Bit.ModelCANVAS

model_variant = "base"
prediction_folder = "abm_predictions/crosscorr"
model_factory = nothing

# =============================================================================
# MAIN SCRIPT
# =============================================================================

@info "Cross-Correlation Analysis for $country (variant: $model_variant)"

calibration = Bit.load_calibration_data(country)
real_data = calibration.data
folder = "data/$(country)/$(prediction_folder)"
output_folder = "analysis/figs/$(country)/$(model_variant)"
mkpath(output_folder)

# Load prediction files
files = filter(f -> endswith(f, ".jld2"), readdir(folder))
isempty(files) && error("No prediction files found in $folder")

first_pred = load(joinpath(folder, first(files)))["predictions_dict"]
vars = collect(filter(v -> endswith(v, "_quarterly"), keys(first_pred)))
gdp_size = size(first_pred["real_gdp_quarterly"])

# Process simulation data and compute correlations
hp_cache = Bit.create_hp_filter_cache(real_data, vars)

_, crosscorr, autocorr, _ = Bit.process_all_simulation_data(
    folder, vars, gdp_size, length(files),
    correlation_lags, autocorr_lags, autocorr_lags, plot_variables[1:min(3, length(plot_variables))]
)

mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, _ =
    Bit.calculate_statistics(crosscorr, autocorr, Dict(), vars)

real_crosscorr, real_autocorr, _ =
    Bit.process_real_data_correlations(real_data, hp_cache, vars, correlation_lags, autocorr_lags)

# Cross-correlation plot
cross_lags = collect(-correlation_lags:correlation_lags)
p1 = plot(layout = (2, 2), size = (1200, 800), plot_title = "Cross-Correlations with Real GDP")

for (k, var) in enumerate(plot_variables[1:min(4, length(plot_variables))])
    haskey(mean_xcorr, var) && haskey(real_crosscorr, var) || continue
    plot!(
        p1, subplot = k, cross_lags, vec(mean_xcorr[var]), ribbon = vec(std_xcorr[var]),
        label = "ABM", color = :steelblue, linewidth = 2
    )
    plot!(
        p1, subplot = k, cross_lags, vec(real_crosscorr[var]),
        label = "Real", color = :crimson, linewidth = 2
    )
    title!(p1, subplot = k, replace(var, "_quarterly" => ""))
    hline!(p1, [0], subplot = k, color = :gray, linestyle = :dot, label = false)
end
savefig(p1, joinpath(output_folder, "crosscorrelations_abm.png"))
@info "✓ Saved cross-correlation plot"

# Autocorrelation plot
auto_lags = collect(0:autocorr_lags)
p2 = plot(layout = (2, 2), size = (1200, 800), plot_title = "Autocorrelations")

for (k, var) in enumerate(plot_variables[1:min(4, length(plot_variables))])
    haskey(mean_autocorr, var) || continue
    plot!(
        p2, subplot = k, auto_lags, vec(mean_autocorr[var]), ribbon = vec(std_autocorr[var]),
        label = "ABM", color = :steelblue, linewidth = 2
    )
    if haskey(real_autocorr, var)
        plot!(
            p2, subplot = k, auto_lags, vec(real_autocorr[var]),
            label = "Real", color = :crimson, linewidth = 2
        )
    end
    title!(p2, subplot = k, replace(var, "_quarterly" => ""))
    hline!(p2, [0], subplot = k, color = :gray, linestyle = :dot, label = false)
end
savefig(p2, joinpath(output_folder, "autocorrelations_abm.png"))
@info "✓ Saved autocorrelation plot"

@info "Done."
