# Multi-Country Simulation and Table Creation
# Runs the prediction pipeline for a list of countries, downloading each
# country's calibration object from Zenodo.
#
# Supports base model and extension variants (e.g., CANVAS, GrowthRateAR1).

import BeforeIT as Bit
using Dates

# =============================================================================
# CONFIGURATION
# =============================================================================

# Countries to process (2-letter codes; see `Bit.AVAILABLE_COUNTRIES`).
# Each calibration object is downloaded from Zenodo.
countries = ["IT", "AT", "ES"]

T = 12             # Forecast horizon (quarters)
n_sims = 4         # Number of simulations per quarter

quarters = DateTime(2010, 03, 31):Dates.Month(3):DateTime(2011, 03, 31)

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
# SIMULATION PHASE
# =============================================================================
# NOTE: `save_all_params_and_initial_conditions` regenerates `data/<country>`
# from scratch and DELETES it first if it already exists.


@info "Starting simulations (variant: $model_variant) for: $(join(countries, ", "))"

for country in countries
    @info "Processing $country"

    calibration = Bit.download_zenodo_calibration_object(country)
    folder = "data/$country"
    sim_subdir = "simulations/$(model_variant)"
    pred_subdir = "abm_predictions/$(model_variant)"

    # Parameters/initial conditions are model-independent: generate them once per
    # country so a later run with a different model_constructor does not wipe the
    # previous variant's outputs (`save_all_params_and_initial_conditions` deletes
    # the whole country folder if it exists).
    if !isdir(joinpath(folder, "parameters"))
        Bit.save_all_params_and_initial_conditions(
            calibration, folder; scale = 0.0005,
            first_calibration_date = first(quarters),
            last_calibration_date = last(quarters),
        )
    end
    Bit.save_all_simulations(folder; T = T, n_sims, model_constructor, simulation_folder = sim_subdir)
    Bit.save_all_predictions_from_sims(folder, calibration.data; simulation_suffix = sim_subdir, prediction_suffix = pred_subdir)
    @info "Completed $country"

end


# =============================================================================
# ANALYSIS PHASE
# =============================================================================

@info "Generating error tables (variant: $model_variant)..."

for country in countries
    @info "Generating tables for $country"

    calibration = Bit.download_zenodo_calibration_object(country)
    mkpath(joinpath("data", country, "analysis", model_variant))

    Bit.error_table_ar(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant)
    Bit.error_table_validation_var(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant)
    Bit.error_table_abm(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant, prediction_folder = "abm_predictions/$model_variant")
    Bit.error_table_validation_abm(country, calibration.ea, calibration.data, quarters, Bit.forecast_horizons; model_variant, prediction_folder = "abm_predictions/$model_variant")

    @info "Completed $country"

end


@info "Done."
