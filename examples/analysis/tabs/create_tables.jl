
# This scripts calls all scripts to create tables for comparing forecasts
# of the abm and the baseline models (AR, ARX, VAR, VARX)

import BeforeIT as Bit
using Dates, DelimitedFiles, Statistics, Printf, LaTeXStrings, CSV, HDF5, FileIO, MAT

country = "italy"
cal = Bit.ITALY_CALIBRATION

for calibration_date in collect(DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31))
    params, init_conds = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.0005)
    save("data/italy/parameters/$(year(calibration_date))Q$(Dates.quarterofyear(calibration_date)).jld2", params)
    save("data/italy/initial_conditions/$(year(calibration_date))Q$(Dates.quarterofyear(calibration_date)).jld2", init_conds)
end

year_, number_years = 2010, 10
number_quarters, horizon, number_seeds, number_sectors  = 4 * number_years, 12, 4, 62
T, n_sims = 12, 4

for year in 2010:2019
    for quarter in 1:4
        date = DateTime(year, quarter*3, daysinmonth(DateTime(year, quarter*3, 1)))
        parameters = load("data/italy/parameters/$(year)Q$(quarter).jld2")
        initial_conditions = load("data/italy/initial_conditions/$(year)Q$(quarter).jld2")
        model = Bit.init_model(parameters, initial_conditions, T)
        data_vector = Bit.ensemblerun(model, n_sims)
        prediction_dict = Bit.get_predictions_from_sims(data_vector, cal.data, date)
        save("data/italy/abm_predictions/$(year)Q$(quarter).jld2", "model_dict", prediction_dict)
    end
end

include("./examples/analysis/tabs/analysis_utils.jl")
include("./examples/analysis/tabs/error_table_ar.jl")
include("./examples/analysis/tabs/error_table_abm.jl")
include("./examples/analysis/tabs/error_table_validation_var.jl")
include("./examples/analysis/tabs/error_table_validation_abm.jl")

error_table_ar()
error_table_validation_var()

error_table_abm(country)
error_table_validation_abm(country)
