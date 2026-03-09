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
# Set model_variant and model_factory for the desired variant.
# Results will be saved to: data/{country}/analysis/{model_variant}/
#
# Options:
#   model_variant = "base"        model_factory = nothing
#   model_variant = "growth_rate" model_factory = Bit.ModelGR
#   model_variant = "canvas"      model_factory = Bit.ModelCANVAS

model_variant = "base"
model_factory = nothing

# =============================================================================
# SIMULATION PHASE
# =============================================================================

if run_simulation
    @info "Starting simulations for all countries (variant: $model_variant)..."

    for country in Bit.discover_countries(; subfolder = "parameters")
        @info "Processing $country"
        try
            calibration = Bit.load_calibration_data(country)
            Bit.run_variant_pipeline("data/$country", calibration.data, model_variant; model_factory, T = t, n_sims)
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
