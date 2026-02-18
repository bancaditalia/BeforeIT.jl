# # Full multiple-prediction pipeline with long term predictions

import BeforeIT as Bit
using Plots, StatsPlots, Dates, FileIO

folder_name = "data/italy/long_run" # location for cross-correlations data

# Generate parameters and initial conditions from an initial to a final date
cal = Bit.ITALY_CALIBRATION
first_calibration_date = DateTime(2010, 03, 31)
last_calibration_date = DateTime(2016, 12, 31)

# Save all the generated parameters and initial conditions in the selected folder
Bit.save_all_params_and_initial_conditions(
    cal,
    folder_name;
    scale = 0.0005,
    first_calibration_date = first_calibration_date,
    last_calibration_date = last_calibration_date,
)

Bit.save_all_simulations(folder_name; T = 32, n_sims = 10) # Needed for cross-correlations figures

# Finally, align all simulations with the real data to transform them testable predictions
real_data = Bit.ITALY_CALIBRATION.data
Bit.save_all_predictions_from_sims(folder_name, real_data)
