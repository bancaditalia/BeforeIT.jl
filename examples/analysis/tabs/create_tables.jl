# This scripts calls all scripts to create tables for comparing forecasts of the abm and the baseline models (AR, ARX, VAR, VARX)
import BeforeIT as Bit
using LaTeXStrings, CSV, HDF5, MAT

# Clear old files
foreach(rm, filter(endswith(".h5"), readdir("./examples/analysis/tabs/",join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./examples/analysis/tabs/",join=true)))

country = "italy"

include("./analysis_utils.jl")
include("./error_table_ar.jl")
include("./error_table_abm.jl")
include("./error_table_validation_var.jl")
include("./error_table_validation_abm.jl")


error_table_ar()
error_table_validation_var()

error_table_abm(country)
error_table_validation_abm(country)


