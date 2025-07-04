# # Full multiple-prediction pipeline

import BeforeIT as Bit
using FileIO

# Decide the name of a folder where to store all data
folder_name = "data/italy"

# Generate parameters and initial conditions from an initial to a final date
cal = Bit.ITALY_CALIBRATION
first_calibration_date = DateTime(2014, 03, 31)
last_calibration_date = DateTime(2014, 12, 31)

# Save all the generated parameters and initial conditions in the selected folder
Bit.save_all_params_and_initial_conditions(
    cal,
    folder_name;
    scale = 0.0005,
    first_calibration_date = first_calibration_date,
    last_calibration_date = last_calibration_date,
)

# Now, run a number "n_sims" of simulations of length "T "for each of the parameters
# and initial conditions in the folder. The following function loads the parameters 
# and initial conditions, it initialises the prediction, runs the prediction `n_sims` times, and finally
# saves the `data_vector` into a `.jld2` file with an appropriate name.
# The whole process is repeatead for all quarters from `2010Q1` to `2019Q4`
Bit.save_all_simulations(folder_name; T = 16, n_sims = 2)

# Finally, align all simulations with the real data to transform them testable predictions
real_data = Bit.ITALY_CALIBRATION.data
Bit.save_all_predictions_from_sims(folder_name, real_data)

# Load predictions from some quarter and plot them against the true data

y = 2014
q = 2

predictions_dict = load("data/italy/abm_predictions/$(y)Q$(q).jld2")["predictions_dict"]

crop = true

p1 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_gdp_quarterly"; crop = crop)
p2 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_household_consumption_quarterly"; crop = crop)
p3 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_fixed_capitalformation_quarterly"; crop = crop)
p4 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_government_consumption_quarterly"; crop = crop)
p5 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_exports_quarterly"; crop = crop)
p6 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_imports_quarterly"; crop = crop)

plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), legend = false)

