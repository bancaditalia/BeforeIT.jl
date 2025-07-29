
import BeforeIT as Bit
using JLD2, Dates

reference_file = joinpath(@__DIR__, "2010Q1.jld2")
reference_predictions = load(reference_file)["model_dict"]

# calibrate the model on a specific date
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)
parameters, initial_conditions = Bit.get_params_and_initial_conditions(cal,
                                                                       calibration_date;
                                                                       scale = 0.0001)

# run the model for a number of quarters
T = 12
n_sims = 2
model = Bit.Model(parameters, initial_conditions)
model_vector = Bit.ensemblerun(model, T, n_sims, parallel = false)

# obtain predictions from the model simulations
real_data = Bit.ITALY_CALIBRATION.data
predictions_dict = Bit.get_predictions_from_sims(Bit.DataVector(model_vector), real_data,
                                                 calibration_date)

# for each key in the predictions_dict, check if the values are equal to the reference_predictions
for key in keys(predictions_dict)
    @test isapprox(predictions_dict[key], reference_predictions[key], atol = 1e-6,
                   rtol = 1e-6)
end
