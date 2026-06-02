# Single-Country Cross-Correlation Analysis
# Creates cross-correlation and autocorrelation plots for a single country
#
# Self-contained example: it first generates a small ensemble of model
# predictions (one file per quarter, as in `prediction_pipeline_multiple.jl`),
# then compares their business-cycle statistics — cross-correlations with real
# GDP and autocorrelations — against the real data.

import BeforeIT as Bit
using Dates, Plots, JLD2, FileIO

# =============================================================================
# CONFIGURATION
# =============================================================================

# Country: any 2-letter code in `Bit.AVAILABLE_COUNTRIES`.
# Every other country is downloaded from Zenodo via `Bit.download_zenodo_calibration_object`.
country = "AT"

correlation_lags = 15
autocorr_lags = 20

plot_variables = [
    "real_capitalformation_quarterly",
    "wages_quarterly",
    "real_household_consumption_quarterly",
    "gdp_deflator_quarterly",
]

# Ensemble generation settings
# Predictions are written to `simulation_data/$(country)/abm_predictions/YYYYQn.jld2` files
folder = "simulation_data/$(country)"
first_calibration_date = DateTime(2010, 03, 31)
last_calibration_date = DateTime(2012, 12, 31)
T = 20                                         # quarters simulated per prediction
n_sims = 4                                     # simulations per quarter

# Model variant to simulate: `Bit.Model` (base), `Bit.ModelGR`, or `Bit.ModelCANVAS`
model_constructor = Bit.Model

# =============================================================================
# GENERATE PREDICTION FILES
# =============================================================================
# Mirrors `examples/prediction_pipeline_multiple.jl`: calibrate on each quarter,
# run `n_sims` simulations of length `T`, and align them with the real data to
# obtain one `abm_predictions/YYYYQn.jld2` file per quarter.

calibration = Bit.download_zenodo_calibration_object(country);
real_data = calibration.data
prediction_folder = joinpath(folder, "abm_predictions")

# Set to `true` to generate prediction files from scratch.
# If `false`, the script will look for existing files in `prediction_folder` and will skip to the statistics and plots.
prediction_from_scratch = true

if prediction_from_scratch
    @info "Generating prediction files in $prediction_folder"
    Bit.save_all_params_and_initial_conditions(
        calibration, folder; scale = 0.0005,
        first_calibration_date = first_calibration_date,
        last_calibration_date = last_calibration_date,
    )
    Bit.save_all_simulations(folder; T = T, n_sims = n_sims, model_constructor = model_constructor)
    Bit.save_all_predictions_from_sims(folder, real_data)
end

# =============================================================================
# COMPUTE CORRELATION STATISTICS
# =============================================================================

# Quarterly variables actually produced by the model
first_pred = load(joinpath(prediction_folder, first(readdir(prediction_folder))))["predictions_dict"]
vars = collect(filter(v -> endswith(v, "_quarterly"), keys(first_pred)))

# Compute correlation statistics for the ABM predictions and the real data. The function `Bit.correlation_stats`
abm_stats = Bit.correlation_stats(prediction_folder, vars; correlation_lags = correlation_lags, autocorr_lags = autocorr_lags)
real_stats = Bit.correlation_stats(real_data, vars; correlation_lags = correlation_lags, autocorr_lags = autocorr_lags)

# =============================================================================
# PLOTS
# =============================================================================

output_folder = "analysis/figs/$(country)"
mkpath(output_folder)

# Cross-correlation plot
cross_lags = collect(-correlation_lags:correlation_lags)
p1 = plot(layout = (2, 2), size = (1200, 800), plot_title = "Cross-Correlations with Real GDP")

for (k, var) in enumerate(plot_variables[1:min(4, length(plot_variables))])
    haskey(abm_stats.crosscor, var) && haskey(real_stats.crosscor, var) || continue
    plot!(
        p1, subplot = k, cross_lags, Bit.mean_crosscor(abm_stats, var), ribbon = Bit.std_crosscor(abm_stats, var),
        label = "ABM", color = :steelblue, linewidth = 2
    )
    plot!(
        p1, subplot = k, cross_lags, Bit.mean_crosscor(real_stats, var),
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
    haskey(abm_stats.autocor, var) || continue
    plot!(
        p2, subplot = k, auto_lags, Bit.mean_autocor(abm_stats, var), ribbon = Bit.std_autocor(abm_stats, var),
        label = "ABM", color = :steelblue, linewidth = 2
    )
    if haskey(real_stats.autocor, var)
        plot!(
            p2, subplot = k, auto_lags, Bit.mean_autocor(real_stats, var),
            label = "Real", color = :crimson, linewidth = 2
        )
    end
    title!(p2, subplot = k, replace(var, "_quarterly" => ""))
    hline!(p2, [0], subplot = k, color = :gray, linestyle = :dot, label = false)
end
savefig(p2, joinpath(output_folder, "autocorrelations_abm.png"))
@info "✓ Saved autocorrelation plot"
