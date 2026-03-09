# Forecast Error Table Generation
# Computes RMSE and bias tables comparing the ABM against AR/VAR benchmarks.
#
# Supports base model and extension variants (e.g., CANVAS, GrowthRateAR1).
# Set model_variant, prediction_folder, and model_factory below.

using Dates, Statistics, JLD2, FileIO
import BeforeIT as Bit

# =============================================================================
# CONFIGURATION
# =============================================================================

country = "it"
t = 12           # Forecast horizon (quarters)
n_sims = 100     # Ensemble size

horizons = Bit.forecast_horizons   # [1, 2, 4, 8, 12]

starting_quarter = DateTime(2010, 03, 31)
ending_quarter   = DateTime(2019, 12, 31)

# Set to false after simulations and predictions have been saved once
run_simulation   = true
save_predictions = true

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Change these to run analysis for different model variants.
# Results will be saved to: data/{country}/analysis/{model_variant}/
#
# Options:
#   model_variant = "base"        prediction_folder = "abm_predictions"               model_factory = nothing
#   model_variant = "growth_rate" prediction_folder = "abm_predictions_growth_rate"   model_factory = Bit.ModelGR
#   model_variant = "canvas"      prediction_folder = "abm_predictions_canvas"        model_factory = Bit.ModelCANVAS

model_variant     = "base"
prediction_folder = "abm_predictions"
model_factory     = nothing

# =============================================================================
# MAIN
# =============================================================================

@info "Forecast error tables for $country (variant: $model_variant)"

calibration = Bit.load_calibration_data(country)
data        = calibration.data
ea          = calibration.ea

quarters = collect(starting_quarter:Dates.Month(3):ending_quarter)

folder = "data/$(country)"

# --- Simulations ---
if run_simulation
    @info "Running simulations (T=$t, n_sims=$n_sims)..."
    Bit.save_all_simulations(
        folder; T = t, n_sims = n_sims,
        model_factory     = model_factory,
        simulation_folder = model_variant == "base" ? nothing : model_variant,
    )
end

# --- Extract predictions ---
if save_predictions
    @info "Extracting predictions..."
    sim_suffix  = model_variant == "base" ? "simulations"      : "simulations_$(model_variant)"
    pred_suffix = model_variant == "base" ? "abm_predictions"  : "abm_predictions_$(model_variant)"
    Bit.save_all_predictions_from_sims(
        folder, data;
        simulation_suffix  = sim_suffix,
        prediction_suffix  = pred_suffix,
    )
end

# --- Error tables ---
@info "Computing error tables..."

Bit.error_table_ar(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ AR error table"

Bit.error_table_abm(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ ABM error table"

Bit.error_table_validation_var(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ VAR validation table"

Bit.error_table_validation_abm(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ ABM validation table"

@info "Done. Results saved to data/$(country)/analysis/$(model_variant)/"
