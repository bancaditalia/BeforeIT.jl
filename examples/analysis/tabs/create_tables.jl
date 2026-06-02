# Forecast Error Table Generation
# Computes RMSE and bias tables comparing the ABM against AR/VAR benchmarks.
#
# Supports base model and extension variants (e.g., CANVAS, GrowthRateAR1).
# Set `model_constructor` below; the variant name is derived from it.

using Dates, Statistics, JLD2, FileIO
import BeforeIT as Bit

# =============================================================================
# CONFIGURATION
# =============================================================================

country = "AT"
T = 12           # Forecast horizon (quarters)
n_sims = 2     # Ensemble size

horizons = Bit.forecast_horizons   # [1, 2, 4, 8, 12]

starting_quarter = DateTime(2010, 03, 31)
ending_quarter = DateTime(2010, 12, 31)
# ending_quarter = DateTime(2019, 12, 31)

# Set to false after simulations and predictions have been saved once
run_simulation = true

# =============================================================================
# MODEL VARIANT CONFIGURATION
# =============================================================================
# Pick the model to run. The variant name (and hence the output folders under
# data/{country}/analysis/{variant}/) is derived from it, so they cannot disagree.
#
# Options: `Bit.Model`, `Bit.ModelGR`, `Bit.ModelCANVAS` (the variant folder is named after it)

model_constructor = Bit.ModelCANVAS
model_variant = string(nameof(model_constructor))
# =============================================================================
# MAIN
# =============================================================================

@info "Forecast error tables for $country (variant: $(model_variant))"

calibration = Bit.download_zenodo_calibration_object(country);
data = calibration.data
ea = calibration.ea

quarters = collect(starting_quarter:Dates.Month(3):ending_quarter)

folder = "data/$(country)"

# --- Parameters, simulations and predictions (nested per-variant layout) ---
# NOTE: `save_all_params_and_initial_conditions` regenerates `folder` from
# scratch and DELETES it first if it already exists. Use a dedicated scratch
# directory (e.g. "data/IT"), not a curated one (e.g. "data/italy").
if run_simulation
    @info "Generating parameters and initial conditions..."
    Bit.save_all_params_and_initial_conditions(
        calibration, folder; scale = 0.0005,
        first_calibration_date = starting_quarter,
        last_calibration_date = ending_quarter,
    )

    @info "Running simulations and extracting predictions (T=$T, n_sims=$n_sims)..."
    sim_subdir = "simulations/$(model_variant)"
    pred_subdir = "abm_predictions/$(model_variant)"
    Bit.save_all_simulations(folder; T, n_sims, model_constructor, simulation_folder = sim_subdir)
    Bit.save_all_predictions_from_sims(folder, data; simulation_suffix = sim_subdir, prediction_suffix = pred_subdir)
end

# --- Error tables ---
@info "Computing error tables..."

prediction_folder = "abm_predictions/$(model_variant)"

Bit.error_table_ar(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ AR error table"

Bit.error_table_abm(country, ea, data, quarters, horizons; model_variant = model_variant, prediction_folder = prediction_folder)
@info "✓ ABM error table"

Bit.error_table_validation_var(country, ea, data, quarters, horizons; model_variant = model_variant)
@info "✓ VAR validation table"

Bit.error_table_validation_abm(country, ea, data, quarters, horizons; model_variant = model_variant, prediction_folder = prediction_folder)
@info "✓ ABM validation table"

@info "Done. Results saved to data/$(country)/analysis/$(model_variant)/"
