
# This scripts calls all scripts to create tables for comparing forecasts
# of the abm and the baseline models (AR, ARX, VAR, VARX)

import BeforeIT as Bit
using Dates, DelimitedFiles, Statistics, Printf, LaTeXStrings, CSV, HDF5, FileIO, MAT

country = "italy"

include("./examples/get_parameters_and_initial_conditions.jl")
include("./examples/get_simulations.jl")
include("./examples/get_predictions.jl")

include("./examples/analysis/tabs/analysis_utils.jl")
include("./examples/analysis/tabs/error_table_ar.jl")
include("./examples/analysis/tabs/error_table_abm.jl")
include("./examples/analysis/tabs/error_table_validation_var.jl")
include("./examples/analysis/tabs/error_table_validation_abm.jl")

error_table_ar()
error_table_validation_var()

error_table_abm(country)
error_table_validation_abm(country)
