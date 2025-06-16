# This scripts calls all scripts to create tables for comparing forecasts
# of the abm and the baseline models (AR, ARX, VAR, VARX)

import BeforeIT as Bit

# install required packages
import Pkg; Pkg.add("LaTeXStrings")

using Dates, DelimitedFiles, Statistics, Printf, LaTeXStrings, CSV, FileIO, MAT

cal = Bit.ITALY_CALIBRATION
T, n_sims = 12, 4
quarters = DateTime(2010, 03, 31):Dates.Month(3):DateTime(2019, 12, 31)

for q in quarters
    params, init_conds = Bit.get_params_and_initial_conditions(cal, q; scale = 0.0005)
    model = Bit.init_model(params, init_conds, T)
    data_vector = Bit.ensemblerun(model, n_sims)
    prediction_dict = Bit.get_predictions_from_sims(data_vector, cal.data, q)
    save("data/italy/abm_predictions/$(year(q))Q$(quarterofyear(q)).jld2", "model_dict", prediction_dict)
end

include("./examples/analysis/tabs/analysis_utils.jl")
include("./examples/analysis/tabs/error_table_var.jl")
include("./examples/analysis/tabs/error_table_abm.jl")
include("./examples/analysis/tabs/error_table_validation_var.jl")
include("./examples/analysis/tabs/error_table_validation_abm.jl")

country = "italy"
ea = matread(("data/$(country)/calibration/ea/1996.mat"))["ea"]
data = matread(("data/$(country)/calibration/data/1996.mat"))["data"]
horizons = [1, 2, 4, 8, 12]

error_table_var(country, ea, data, quarters, horizons)
error_table_validation_var(country, ea, data, quarters, horizons)
error_table_abm(country, ea, data, quarters, horizons)
error_table_validation_abm(country, ea, data, quarters, horizons)
