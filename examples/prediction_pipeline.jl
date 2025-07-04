# # Full prediction pipeline 

import BeforeIT as Bit
using Dates, Plots

# We start from loading the calibration object for italy, which contains 
# 4 datasets: `calibration_data`, `figaro`, `data`, and `ea`. These are
# saved within `BeforeIT.jl` for the Italian case, and would need to be
# appropriately generated for other countries.

cal = Bit.ITALY_CALIBRATION
fieldnames(typeof(cal))

# These are essentially 4 dictionaries with well defined keys, such as

println(keys(cal.calibration))
println(keys(cal.figaro))
println(keys(cal.data))
println(keys(cal.ea))

# The object also contains two time variables related to the data

println(cal.max_calibration_date)
println(cal.estimation_date)

# We can calibrate the model on a specific quarter as follows

calibration_date = DateTime(2014, 03, 31)
parameters, initial_conditions = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.0001)

# We run the model for a number of quarters
T = 20
n_sims = 3
model = Bit.Model(parameters, initial_conditions)
data_vector = Bit.ensemblerun(model, T, n_sims);

# We obtain predictions from the model simulations 

real_data = cal.data
predictions_dict = Bit.get_predictions_from_sims(data_vector, real_data, calibration_date)

# Finally, we can plot the predictions against the real data

crop = true

p1 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_gdp_quarterly"; crop = crop)
p2 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_household_consumption_quarterly"; crop = crop)
p3 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_fixed_capitalformation_quarterly"; crop = crop)
p4 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_government_consumption_quarterly"; crop = crop)
p5 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_exports_quarterly"; crop = crop)
p6 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_imports_quarterly"; crop = crop)

plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), legend = false)
