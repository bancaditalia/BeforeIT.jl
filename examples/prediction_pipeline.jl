## In this tutorial we illustrate a full pipeline of predictions using BeforeIT

import BeforeIT as Bit
using Dates, FileIO, Plots

# calibrate the model on a specific date
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)
parameters, initial_conditions = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.001)

# run the model for a number of quarters
T = 20
n_sims = 4
model = Bit.init_model(parameters, initial_conditions, T)
data_vector = Bit.ensemblerun(model, n_sims)

# obtain predictions from the model simulations
real_data = Bit.ITALY_CALIBRATION.data
quarter_num = Bit.date2num(calibration_date) # unique identifier for the quarter
predictions_dict = Bit.get_predictions_from_sims(data, quarter_num; sims = data_vector)

# plot the predictions against the real data 
p1 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_gdp_quarterly")
p2 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_household_consumption_quarterly")
p3 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_fixed_capitalformation_quarterly")
p4 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_government_consumption_quarterly")
p5 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_exports_quarterly")
p6 = Bit.plot_model_vs_real(predictions_dict, real_data, "real_imports_quarterly")

plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), legend = false)