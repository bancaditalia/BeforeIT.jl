# Multi-Country Simulation and Table Creation
# Runs the prediction pipeline for all countries with calibration data
#
# Supports base model and extension variants (e.g., CANVAS, GrowthRateAR1).

import BeforeIT as Bit
using Dates

# =============================================================================
# CONFIGURATION
# =============================================================================

t = 12             # Forecast horizon (quarters)
n_sims = 100       # Number of simulations per quarter
run_simulation = true
run_analysis = true

quarters = DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31)

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Pick the model to run. The variant name (and hence the output folders under
# data/{country}/analysis/{variant}/) is derived from it, so they cannot disagree.
#
# Options: `Bit.Model`, `Bit.ModelGR`, `Bit.ModelCANVAS` (the variant folder is named after it)

model_constructor = Bit.Model
model_variant = string(nameof(model_constructor))

# =============================================================================
# SIMULATION PHASE
# =============================================================================

if run_simulation
    @info "Starting simulations for all countries (variant: $model_variant)..."

    for country in Bit.discover_countries(; subfolder = "parameters")
        @info "Processing $country"
        try
            calibration = Bit.load_calibration_data(country)
            folder = "data/$country"
            sim_subdir = "simulations/$(model_variant)"
            pred_subdir = "abm_predictions/$(model_variant)"
            Bit.save_all_simulations(folder; T = t, n_sims, model_constructor, simulation_folder = sim_subdir)
            Bit.save_all_predictions_from_sims(folder, calibration.data; simulation_suffix = sim_subdir, prediction_suffix = pred_subdir)
            @info "Completed $country"
        catch e
            @error "Failed $country" exception = (e, catch_backtrace())
        end
    end
end

# =============================================================================
# ANALYSIS PHASE
# =============================================================================

if run_analysis
    @info "Generating error tables (variant: $model_variant)..."

    for country in Bit.discover_countries(model_variant)
        @info "Generating tables for $country"
        try
            calibration = Bit.load_calibration_data(country)
            mkpath(joinpath("data", country, "analysis", model_variant))

            Bit.error_table_ar(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant)
            Bit.error_table_validation_var(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant)
            Bit.error_table_abm(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant, prediction_folder = "abm_predictions/$model_variant")
            Bit.error_table_validation_abm(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant, prediction_folder = "abm_predictions/$model_variant")

            @info "Completed $country"
        catch e
            @error "Failed $country" exception = (e, catch_backtrace())
        end
    end
end

@info "Done."
