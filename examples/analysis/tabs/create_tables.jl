
# This scripts calls all scripts to create tables for comparing forecasts
# of the abm and the baseline models (AR, ARX, VAR, VARX)

import BeforeIT as Bit
using Dates, DelimitedFiles, Statistics, Printf, LaTeXStrings, CSV, HDF5, FileIO, MAT

country = "italy"
cal = Bit.ITALY_CALIBRATION
parameters, initial_conditions = Bit.get_params_and_initial_conditions(cal, DateTime(2010, 03, 31); scale = 0.01)

for calibration_date in collect(DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31))
    params, init_conds = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = 0.0005)
    save("data/italy/initial_conditions/$(year(calibration_date))Q$(Dates.quarterofyear(calibration_date)).jld2", params)
    save("data/italy/initial_conditions/$(year(calibration_date))Q$(Dates.quarterofyear(calibration_date)).jld2", init_conds)
end

for year in 2010:2019
    for quarter in 1:4
        parameters = load("data/italy/parameters/$(year)Q$(quarter).jld2")
        initial_conditions = load("data/italy/initial_conditions/$(year)Q$(quarter).jld2")
        T = 12
        model = Bit.init_model(parameters, initial_conditions, T)
        n_sims = 4
        data_vector = Bit.ensemblerun(model, n_sims)
        save("data/italy/simulations/$(year)Q$(quarter).jld2", "data_vector", data_vector)
    end
end

year_, number_years = 2010, 10
number_quarters, horizon, number_seeds, number_sectors  = 4 * number_years, 12, 4, 62

# Load the real time series
data = Bit.ITALY_CALIBRATION.data

quarters_num = []
for month in 4:3:((number_years + 1) * 12 + 1)
    year_m = year_ + (month ÷ 12)
    mont_m = month % 12
    date = DateTime(year_m, mont_m, 1) - Day(1)
    push!(quarters_num, Bit.date2num(date))
end
for i in 1:number_quarters
    quarter_num = quarters_num[i]
    Bit.get_predictions_from_sims(data, quarter_num)
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
