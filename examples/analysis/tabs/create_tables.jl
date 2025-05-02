# This scripts calls all scripts to create tables for comparing forecasts of the abm and the baseline models (AR, ARX, VAR, VARX)
import BeforeIT as Bit
using LaTeXStrings, CSV, HDF5, MAT

# Clear old files
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/",join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/",join=true)))

model_types = ["base", "extended_heuristic", "optimal_consumption"]
distribution_types = ["calibrated", "empirical"]
nation = "netherlands"

Bit.error_table_ar()
Bit.error_table_ar_nace10()
Bit.error_table_validation_var()
Bit.error_table_var_nace10()
Bit.error_table_arx()
Bit.error_table_validation_varx()

for model_type in model_types
    for distribution_type in distribution_types
        foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
        foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
        if model_type == "extended_heuristic"
            for version_c = 1:8
                # Unconditional forecasts
                Bit.error_table_abm(nation, model_type, distribution_type; version_c)
                Bit.error_table_abm_nace10(nation, model_type, distribution_type; version_c) 
                Bit.error_table_validation_abm(nation, model_type, distribution_type; version_c)
                Bit.error_table_abm_nace10_var(nation, model_type, distribution_type; version_c) 

                # Conditional forecast
                Bit.error_table_abmx(nation, model_type, distribution_type; version_c) 
                Bit.error_table_abmx_uf(nation, model_type, distribution_type; version_c) 
                Bit.error_table_validation_abmx(nation, model_type, distribution_type; version_c)
                Bit.error_table_validation_abmx_uf(nation, model_type, distribution_type; version_c)
            end
        else
            # Unconditional forecasts
            Bit.error_table_abm(nation, model_type, distribution_type)
            Bit.error_table_abm_nace10(nation, model_type, distribution_type) 
            Bit.error_table_validation_abm(nation, model_type, distribution_type)
            Bit.error_table_abm_nace10_var(nation, model_type, distribution_type) 

            # Conditional forecast
            Bit.error_table_abmx(nation, model_type, distribution_type) 
            Bit.error_table_abmx_uf(nation, model_type, distribution_type) 
            Bit.error_table_validation_abmx(nation, model_type, distribution_type)
            Bit.error_table_validation_abmx_uf(nation, model_type, distribution_type)
        end
    end
end
#=
model_type = "base"
distribution_type = "calibrated"

# Unconditional forecasts
include("error_table_ar.jl")
include("error_table_abm.jl")
include("error_table_ar_nace10.jl") 
include("error_table_abm_nace10.jl") 
include("error_table_validation_var.jl")
include("error_table_validation_abm.jl")
include("error_table_var_nace10.jl")
include("error_table_abm_nace10_var.jl") 

# Conditional forecast
include("error_table_arx.jl")
include("error_table_abmx.jl") 
include("error_table_abmx_uf.jl") 
include("error_table_validation_varx.jl")
include("error_table_validation_abmx.jl")
include("error_table_validation_abmx_uf.jl")

distribution_type = "empirical"
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))

# Unconditional forecasts
include("error_table_ar.jl")
include("error_table_abm.jl")
include("error_table_ar_nace10.jl") 
include("error_table_abm_nace10.jl") 
include("error_table_validation_var.jl")
include("error_table_validation_abm.jl")
include("error_table_var_nace10.jl")
include("error_table_abm_nace10_var.jl") 

# Conditional forecast
include("error_table_arx.jl")
include("error_table_abmx.jl") 
include("error_table_abmx_uf.jl") 
include("error_table_validation_varx.jl")
include("error_table_validation_abmx.jl")
include("error_table_validation_abmx_uf.jl")

model_type = "extended_heuristic"

distribution_type = "calibrated"
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))

distribution_type = "empirical"
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))

for v = 1:8
    global version_c = v

    distribution_type = "calibrated"
    # Unconditional forecasts
    include("error_table_ar.jl")
    include("error_table_abm.jl")
    include("error_table_ar_nace10.jl") 
    include("error_table_abm_nace10.jl") 
    include("error_table_validation_var.jl")
    include("error_table_validation_abm.jl")
    include("error_table_var_nace10.jl")
    include("error_table_abm_nace10_var.jl") 

    # Conditional forecast
    include("error_table_arx.jl")
    include("error_table_abmx.jl") 
    include("error_table_abmx_uf.jl") 
    include("error_table_validation_varx.jl")
    include("error_table_validation_abmx.jl")
    include("error_table_validation_abmx_uf.jl")

    distribution_type = "empirical"
    # Unconditional forecasts
    include("error_table_ar.jl")
    include("error_table_abm.jl")
    include("error_table_ar_nace10.jl") 
    include("error_table_abm_nace10.jl") 
    include("error_table_validation_var.jl")
    include("error_table_validation_abm.jl")
    include("error_table_var_nace10.jl")
    include("error_table_abm_nace10_var.jl") 

    # Conditional forecast
    include("error_table_arx.jl")
    include("error_table_abmx.jl") 
    include("error_table_abmx_uf.jl") 
    include("error_table_validation_varx.jl")
    include("error_table_validation_abmx.jl")
    include("error_table_validation_abmx_uf.jl")
end
#=
model_type = "optimal_consumption"

distribution_type = "calibrated"
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))

# Unconditional forecasts
include("error_table_ar.jl")
include("error_table_abm.jl")
include("error_table_ar_nace10.jl") 
include("error_table_abm_nace10.jl") 
include("error_table_validation_var.jl")
include("error_table_validation_abm.jl")
include("error_table_var_nace10.jl")
include("error_table_abm_nace10_var.jl") 

# Conditional forecast
include("error_table_arx.jl")
include("error_table_abmx.jl") 
include("error_table_abmx_uf.jl") 
include("error_table_validation_varx.jl")
include("error_table_validation_abmx.jl")
include("error_table_validation_abmx_uf.jl")

distribution_type = "empirical"
foreach(rm, filter(endswith(".h5"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))
foreach(rm, filter(endswith(".tex"), readdir("./analysis/tabs/" * model_type * "/" * distribution_type, join=true)))

# Unconditional forecasts
include("error_table_ar.jl")
include("error_table_abm.jl")
include("error_table_ar_nace10.jl") 
include("error_table_abm_nace10.jl") 
include("error_table_validation_var.jl")
include("error_table_validation_abm.jl")
include("error_table_var_nace10.jl")
include("error_table_abm_nace10_var.jl") 

# Conditional forecast
include("error_table_arx.jl")
include("error_table_abmx.jl") 
include("error_table_abmx_uf.jl") 
include("error_table_validation_varx.jl")
include("error_table_validation_abmx.jl")
include("error_table_validation_abmx_uf.jl")
=#