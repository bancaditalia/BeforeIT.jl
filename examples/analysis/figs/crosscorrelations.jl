using StatsBase, LinearAlgebra, Statistics, Dates
using Plots, StatsPlots
using MAT, JLD2, FileIO
import BeforeIT as Bit

function generate_crosscorrelation_graphs(
        country::String = "italy"
    )
    """
    generate_crosscorrelation_graphs()

    Generate cross-correlation graphs comparing economic models with real data.
    This script analyzes business cycles and correlations between various economic variables.
    """

    year_ = 2010
    number_years = 7
    number_quarters = 4 * number_years
    horizon = 20
    number_seeds = 10
    number_sectors = 62

    # Build folder path based on parameters
    model_folder = "./data/" * country * "/long_run/abm_predictions/"

    # Define the output structure based on parameters
    output_folder = "./analysis/figs/" * country

    # Create output directory
    mkpath(output_folder)

    # Load from file for other countries
    real_data = Bit.ITALY_CALIBRATION.data


    quarters_num = []
    year_m = year_
    for month in 4:3:((number_years + 1) * 12 + 1)
        year_m = year_ + (month ÷ 12)
        mont_m = month % 12
        date = DateTime(year_m, mont_m, 1) - Day(1)
        push!(quarters_num, Bit.date2num(date))
    end

    # Load initial model data to determine sizes
    model_path = model_folder * "2016Q1.jld2"
    model = load(model_path)["predictions_dict"]
    gdpsize = size(model["real_gdp_quarterly"])
    fn = collect(keys(model))
    fn = filter(name -> endswith(name, "_quarterly"), fn)
    # Hodrick-Prescott filter implementation
    function hpfilter(y; λ = 1600.0)
        # Manual implementation as fallback
        T = length(y)

        # Create the second difference matrix
        D = zeros(T - 2, T)
        for i in 1:(T - 2)
            D[i, i] = 1.0
            D[i, i + 1] = -2.0
            D[i, i + 2] = 1.0
        end

        # Calculate the trend
        trend = (I + λ .* (D' * D)) \ y

        # Calculate the cycle
        cycle = y - trend

        return trend, cycle
    end

    # Cross-correlation function similar to MATLAB's xcorr with normalization
    function crosscor(x, y, maxlag = 0)
        nx = length(x)
        ny = length(y)

        if nx != ny
            error("Inputs must be of the same length")
        end

        # Compute correlation
        lags = (-maxlag):maxlag

        # Standardize the inputs
        x_std = (x .- mean(x)) ./ std(x)
        y_std = (y .- mean(y)) ./ std(y)

        xcorr_result = zeros(length(lags))

        for (i, lag) in enumerate(lags)
            if lag < 0
                # x is shifted left
                shift = abs(lag)
                if shift >= nx
                    xcorr_result[i] = 0
                else
                    xcorr_result[i] = sum(x_std[(shift + 1):end] .* y_std[1:(end - shift)]) / (nx - shift)
                end
            elseif lag > 0
                # y is shifted left
                shift = lag
                if shift >= ny
                    xcorr_result[i] = 0
                else
                    xcorr_result[i] = sum(x_std[1:(end - shift)] .* y_std[(shift + 1):end]) / (nx - shift)
                end
            else
                # No shift
                xcorr_result[i] = sum(x_std .* y_std) / nx
            end
        end

        return xcorr_result
    end

    # Autocorrelation function similar to MATLAB's autocorr
    function autocor(x, lags = 0:20)
        nx = length(x)

        # Standardize the input
        x_std = (x .- mean(x)) ./ std(x)

        acorr_result = zeros(length(lags))

        for (i, lag) in enumerate(lags)
            if lag >= nx
                acorr_result[i] = 0
            else
                acorr_result[i] = sum(x_std[1:(end - lag)] .* x_std[(lag + 1):end]) / (nx - lag)
            end
        end

        return acorr_result
    end

    # Cycles plots
    cyclesnames = ["real_gdp_quarterly", "real_capitalformation_quarterly", "real_household_consumption_quarterly", "operating_surplus_quarterly"]

    trends = Dict()
    cycles = Dict()

    for n in 1:length(cyclesnames)
        name = cyclesnames[n]
        trends[name] = zeros(gdpsize)
        cycles[name] = zeros(gdpsize)

        for col in 1:number_seeds
            trends[name][:, col], cycles[name][:, col] = hpfilter(model[name][:, col])
        end
    end

    # Create a 2x2 layout
    cycleplots = plot(layout = (2, 2), size = (900, 700))

    for k in 1:length(cyclesnames)
        name = cyclesnames[k]
        subplot = k

        for col in 1:number_seeds
            plot!(
                cycleplots,
                subplot = subplot,
                cycles[name][:, col] ./ trends[name][:, col],
                legend = false,
                linewidth = 1,
                alpha = 0.5,
            )
        end

        # Format the title nicely
        if length(name) > 9 && name[(end - 8):end] == "quarterly"
            str = name[1:(end - 10)]
        else
            str = name
        end
        str = replace(str, "_" => " ")
        str = titlecase(str)

        plot!(
            cycleplots,
            subplot = subplot,
            title = str,
            ylim = (-0.2, 0.2),
            xlim = (0, 32),
            xlabel = "Period",
            titlefontsize = 9,
        )
    end

    savefig(cycleplots, output_folder * "/cycles_abm.png")

    ## Cross correlation plots
    # Invert gdp_deflator if it exists
    if haskey(real_data, "gdp_deflator_quarterly")
        gdp_deflator = copy(real_data["gdp_deflator_quarterly"])
        gdp_deflator_inverted = 1.0 ./ gdp_deflator
    end

    # Initialize data structures
    cyclesvar = Dict()
    crosscorr = Dict()
    crosscorrdata = Dict()
    autocorr = Dict()
    autocorrdata = Dict()
    stderrordata = Dict()

    for n in 1:length(fn)
        name = fn[n]
        if ndims(model[name]) == 2
            cyclesvar[name] = zeros(gdpsize[2] * number_quarters)
            crosscorr[name] = zeros(31, gdpsize[2] * number_quarters)
            crosscorrdata[name] = zeros(31)
            autocorr[name] = zeros(horizon + 1, gdpsize[2] * number_quarters)
            autocorrdata[name] = zeros(horizon + 1)
        else
            cyclesvar[name] = zeros(gdpsize[2] * number_quarters, 10)
            crosscorr[name] = zeros(31, gdpsize[2] * number_quarters, 10)
            crosscorrdata[name] = zeros(31, 10)
            autocorr[name] = zeros(horizon + 1, gdpsize[2] * number_quarters, 10)
            autocorrdata[name] = zeros(horizon + 1, 10)
            stderrordata[name] = zeros(10)
        end
    end

    nquarters = 0

    # Calculate lag values for cross-correlation and autocorrelation
    c = collect(-15:15)
    cauto = collect(-20:20)

    for i in 1:number_quarters
        quarter_num = quarters_num[i]
        # Convert numerical date to Date object
        date_obj = Bit.num2date(quarter_num)
        year_val = year(date_obj)
        quarter_val = div(month(date_obj) - 1, 3) + 1

        # Build model path with the new folder structure
        model_path = model_folder * "$(year_val)Q$(quarter_val).jld2"

        # Skip if the file doesn't exist
        if !isfile(model_path)
            @warn "Model file not found: $model_path, skipping"
            continue
        end

        model = load(model_path)["predictions_dict"]

        for k in 1:length(fn)
            name = fn[k]
            if size(model[name], 1) == size(model["real_gdp_quarterly"], 1)
                if ndims(model[name]) == 2
                    for n in 1:gdpsize[2]
                        gdptrend, gdpcycle = hpfilter(model["real_gdp_quarterly"][:, n])
                        trend, cycle = hpfilter(model[name][:, n])
                        cyclesvar[name][nquarters * number_seeds + n] = std(model[name][:, n])
                        crosscorr[name][:, nquarters * number_seeds + n] = crosscor(gdpcycle, cycle, 15)
                        autocorr[name][:, nquarters * number_seeds + n] = autocor(cycle, 0:20)
                    end
                else
                    for n in 1:gdpsize[2]
                        for sector in 1:10
                            gdptrend, gdpcycle = hpfilter(model["real_gdp_quarterly"][:, n])
                            trend, cycle = hpfilter(model[name][:, n, sector])
                            cyclesvar[name][nquarters * number_seeds + n, sector] = std(model[name][:, n, sector])
                            crosscorr[name][:, nquarters * number_seeds + n, sector] = crosscor(gdpcycle, cycle, 15)
                            autocorr[name][:, nquarters * number_seeds + n, sector] = autocor(cycle, 0:20)
                        end
                    end
                end
            end
        end
        nquarters += 1
    end

    # Calculate means and standard deviations
    meanxcorr = Dict()
    stdxcorr = Dict()
    meanautocorr = Dict()
    stdautocorr = Dict()
    meancyclesvar = Dict()

    for k in 1:length(fn)
        name = fn[k]
        if ndims(crosscorr[name]) == 2
            meanxcorr[name] = mean(crosscorr[name], dims = 2)
            stdxcorr[name] = std(crosscorr[name], dims = 2)
            meanautocorr[name] = mean(autocorr[name], dims = 2)
            stdautocorr[name] = std(autocorr[name], dims = 2)
            meancyclesvar[name] = mean(cyclesvar[name])
        else
            meanxcorr[name] = zeros(31, 10)
            stdxcorr[name] = zeros(31, 10)
            meancyclesvar[name] = zeros(1, 10)
            meanautocorr[name] = zeros(horizon + 1, 10)
            stdautocorr[name] = zeros(horizon + 1, 10)

            for sector in 1:10
                meancyclesvar[name] = mean(cyclesvar[name][sector])
                meanautocorr[name][:, sector] = mean(autocorr[name][:, :, sector], dims = 2)
                stdautocorr[name][:, sector] = std(autocorr[name][:, :, sector], dims = 2)
            end
        end
    end

    # Process real data for correlations
    for k in 1:length(fn)
        name = fn[k]
        if !haskey(real_data, name)
            continue
        end

        if haskey(real_data, "real_gdp") && size(real_data["real_gdp"], 1) < size(real_data[name], 1)
            if size(real_data[name], 2) == 1
                gdptrend, gdpcycle = hpfilter(real_data["real_gdp_quarterly"])
                trend, cycle = hpfilter(real_data[name])

                minLength = min(length(cycle), length(gdpcycle))
                maxLength = max(length(cycle), length(gdpcycle))
                gdpcycle_adj = gdpcycle[(1 + maxLength - minLength):end]

                crosscorrdata[name] = crosscor(gdpcycle_adj, cycle, 15)
                autocorrdata[name] = autocor(cycle, 0:20)
                if haskey(stderrordata, name)
                    stderrordata[name] = std(real_data[name])
                end
            else
                gdptrend, gdpcycle = hpfilter(real_data["real_gdp_quarterly"])
                sector_count = min(10, size(real_data[name], 2))

                for sector in 1:sector_count
                    trend, cycle = hpfilter(real_data[name][:, sector])
                    minLength = min(length(cycle), length(gdpcycle))
                    maxLength = max(length(cycle), length(gdpcycle))
                    gdpcycle_adj = gdpcycle[(1 + maxLength - minLength):end]

                    crosscorrdata[name][:, sector] = crosscor(gdpcycle_adj, cycle, 15)
                    autocorrdata[name][:, sector] = autocor(cycle, 0:20)
                    if haskey(stderrordata, name)
                        stderrordata[name][sector] = std(real_data[name][:, sector])
                    end
                end
            end
        elseif haskey(real_data, "real_gdp")
            if size(real_data[name], 2) == 1
                gdptrend, gdpcycle = hpfilter(real_data["real_gdp"])
                trend, cycle = hpfilter(real_data[name])

                minLength = min(length(cycle), length(gdpcycle))
                maxLength = max(length(cycle), length(gdpcycle))
                gdpcycle_adj = gdpcycle[(1 + maxLength - minLength):end]

                crosscorrdata[name] = crosscor(gdpcycle_adj, cycle, 15)
                autocorrdata[name] = autocor(cycle, 0:20)
            else
                gdptrend, gdpcycle = hpfilter(real_data["real_gdp"])
                sector_count = min(10, size(real_data[name], 2))

                for sector in 1:sector_count
                    trend, cycle = hpfilter(real_data[name][:, sector])
                    minLength = min(length(cycle), length(gdpcycle))
                    maxLength = max(length(cycle), length(gdpcycle))
                    gdpcycle_adj = gdpcycle[(1 + maxLength - minLength):end]

                    crosscorrdata[name][:, sector] = crosscor(gdpcycle_adj, cycle, 15)
                    autocorrdata[name][:, sector] = autocor(cycle, 0:20)
                end
            end
        end
    end

    # Plot cross-correlations
    plotnames = [
        "real_capitalformation_quarterly",
        "wages_quarterly",
        "real_household_consumption_quarterly",
        "gdp_deflator_quarterly",
        "operating_surplus_quarterly",
    ]

    crossplots = plot(layout = (3, 2), size = (1200, 900))

    for k in 1:length(plotnames)
        name = plotnames[k]

        # Check if the key exists before accessing
        if haskey(meanxcorr, name) && haskey(stdxcorr, name) && haskey(crosscorrdata, name)
            # Using StatsPlots errorline! function as in the compare_model_vs_real script
            plot!(crossplots, subplot = k, c, vec(meanxcorr[name]), label = "Model", color = :blue)
            StatsPlots.errorline!(
                crossplots,
                subplot = k,
                c,
                crosscorr[name],
                errorstyle = :stick,
                errortype = :std,
                errors = vec(stdxcorr[name]),
                fillalpha = 0.3,
                label = nothing,
            )

            # Add the data line
            plot!(crossplots, subplot = k, c, vec(crosscorrdata[name]), linewidth = 2, color = :red, label = "Real")

            # Format title using the project's convention
            if length(name) > 9 && name[(end - 8):end] == "quarterly"
                str = name[1:(end - 10)]
            else
                str = name
            end
            str = replace(str, "_" => " ")
            str = titlecase(str)

            plot!(crossplots, subplot = k, title = str, xlabel = "Lags", titlefontsize = 9)
        end
    end

    savefig(crossplots, output_folder * "/crosscorrelations_abm.png")

    # Plot autocorrelations
    autoplots = plot(layout = (3, 2), size = (1200, 900))

    for k in 1:length(plotnames)
        name = plotnames[k]

        # Check if the key exists before accessing
        if haskey(meanautocorr, name) && haskey(stdautocorr, name)
            # Only use the positive lags (cauto[21:end])
            lags = cauto[21:end]

            # Using StatsPlots errorline! for consistency with the project style
            plot!(autoplots, subplot = k, lags, vec(meanautocorr[name]), label = "Model", color = :blue)

            StatsPlots.errorline!(
                autoplots,
                subplot = k,
                lags,
                autocorr[name],
                errorstyle = :stick,
                errortype = :std,
                errors = vec(stdautocorr[name][21:end]),
                fillalpha = 0.3,
                label = nothing,
            )

            # Add the data line if available
            if haskey(autocorrdata, name) && autocorrdata[name][1] != 0
                plot!(
                    autoplots,
                    subplot = k,
                    lags,
                    vec(autocorrdata[name]),
                    linewidth = 2,
                    color = :red,
                    label = "Real",
                )
            end

            # Format title using the project's convention
            if length(name) > 9 && name[(end - 8):end] == "quarterly"
                str = name[1:(end - 10)]
            else
                str = name
            end
            str = replace(str, "_" => " ")
            str = titlecase(str)

            plot!(autoplots, subplot = k, title = str, xlabel = "Lags", titlefontsize = 9)
        end
    end

    savefig(autoplots, output_folder * "/autocorrelations_abm.png")

    return nothing
end

generate_crosscorrelation_graphs("italy")

include("../../../src/utils/correlation_utils.jl")

# =============================================================================
# CONFIGURATION AND CONSTANTS
# =============================================================================

# Control flags - set these to control which parts of the script run
RUN_SIMULATION = false   # Set to true to run simulation setup
RUN_ANALYSIS = true    # Set to true to run analysis

# Simulation parameters
COUNTRY = "italy"
CALIBRATION = Bit.ITALY_CALIBRATION
FIRST_DATE = DateTime(2010, 03, 31)
LAST_DATE = DateTime(2016, 12, 31)
T = 32
N_SIMS = 10
SCALE = 0.0005

# File and analysis constants
DEFAULT_FOLDER = "data/$(COUNTRY)"
DEFAULT_HORIZON = 20
MAX_SECTORS = 10
CORRELATION_LAGS = 15
AUTOCORR_LAGS = 20
CYCLE_PLOT_YLIM = (-20, 20)

PLOT_VARIABLES = [
    "real_capitalformation_quarterly",
    "wages_quarterly",
    "real_household_consumption_quarterly",
    "gdp_deflator_quarterly",
    "operating_surplus_quarterly",
]

CYCLE_VARIABLES = [
    "real_gdp_quarterly",
    "real_capitalformation_quarterly",
    "real_household_consumption_quarterly",
    "operating_surplus_quarterly",
]

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

"""
Create HP filter cache for real data to avoid recomputation.
Returns: Dict with cached HP filter results
"""
function create_hp_filter_cache(real_data, variable_names)
    @info "Creating HP filter cache for real data"

    cache = Dict{String, Any}()

    # Cache GDP data first (used as reference)
    for gdp_var in ["real_gdp_quarterly", "real_gdp"]
        if haskey(real_data, gdp_var)
            trend, cycle = hpfilter(real_data[gdp_var])
            cache[gdp_var] = (trend, cycle)
        end
    end

    # Cache other variables
    for name in variable_names
        if haskey(real_data, name)
            if ndims(real_data[name]) == 1
                trend, cycle = hpfilter(real_data[name])
                cache[name] = (trend, cycle)
            else
                cache[name] = Dict{Int, Tuple{Vector{Float64}, Vector{Float64}}}()
                n_sectors = min(MAX_SECTORS, size(real_data[name], 2))
                for sector in 1:n_sectors
                    trend, cycle = hpfilter(real_data[name][:, sector])
                    cache[name][sector] = (trend, cycle)
                end
            end
        end
    end

    return cache
end

"""
Initialize result dictionaries based on model structure.
Returns: (cyclesvar, crosscorr, autocorr, cycles_data)
"""
function initialize_results(first_model, variable_names, gdp_size, n_quarters)
    cyclesvar = Dict{String, Any}()
    crosscorr = Dict{String, Any}()
    autocorr = Dict{String, Any}()

    for name in variable_names
        if haskey(first_model, name)
            n_total = gdp_size[2] * n_quarters

            if ndims(first_model[name]) == 2
                cyclesvar[name] = zeros(n_total)
                crosscorr[name] = zeros(2 * CORRELATION_LAGS + 1, n_total)
                autocorr[name] = zeros(DEFAULT_HORIZON + 1, n_total)
            else
                cyclesvar[name] = zeros(n_total, MAX_SECTORS)
                crosscorr[name] = zeros(2 * CORRELATION_LAGS + 1, n_total, MAX_SECTORS)
                autocorr[name] = zeros(DEFAULT_HORIZON + 1, n_total, MAX_SECTORS)
            end
        end
    end

    cycles_data = nothing
    return cyclesvar, crosscorr, autocorr, cycles_data
end

"""
Store cycle data for plotting.
"""
function store_cycle_data!(cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, name, trend, cycle, n, gdp_size)
    if cycles_data_ref[] === nothing
        cycles_data_ref[] = Dict(
            "trends" => Dict{String, Matrix{Float64}}(),
            "cycles" => Dict{String, Matrix{Float64}}(),
            "cyclesnames" => CYCLE_VARIABLES
        )

        for cycle_name in CYCLE_VARIABLES
            cycles_data_ref[]["trends"][cycle_name] = zeros(gdp_size)
            cycles_data_ref[]["cycles"][cycle_name] = zeros(gdp_size)
        end
    end

    cycles_data = cycles_data_ref[]
    return if haskey(cycles_data["trends"], name)
        cycles_data["trends"][name][:, n] = trend
        cycles_data["cycles"][name][:, n] = cycle
    end
end

"""
Process 2D variable (time x simulations).
"""
function process_2d_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, n_seeds)
    for n in 1:gdp_size[2]
        # Compute HP filters
        _, gdp_cycle = hpfilter(model["real_gdp_quarterly"][:, n])
        _, var_cycle = hpfilter(model[name][:, n])

        # Calculate index
        idx = (file_idx - 1) * n_seeds + n

        # Store results
        cyclesvar[name][idx] = std(model[name][:, n])
        crosscorr[name][:, idx] = crosscor(gdp_cycle, var_cycle, CORRELATION_LAGS)
        autocorr[name][:, idx] = autocor(var_cycle, 0:AUTOCORR_LAGS)

        # Store cycle data for first file
        if file_idx == 1 && name in CYCLE_VARIABLES
            var_trend, _ = hpfilter(model[name][:, n])
            store_cycle_data!(cycles_data_ref, name, var_trend, var_cycle, n, gdp_size)
        end
    end
    return
end

"""
Process 3D variable (time x simulations x sectors).
"""
function process_3d_variable!(cyclesvar, crosscorr, autocorr, model, name, file_idx, gdp_size, n_seeds)
    for n in 1:gdp_size[2]
        # GDP reference cycle (computed once per simulation)
        _, gdp_cycle = hpfilter(model["real_gdp_quarterly"][:, n])
        idx = (file_idx - 1) * n_seeds + n

        for sector in 1:MAX_SECTORS
            # Variable cycle
            _, var_cycle = hpfilter(model[name][:, n, sector])

            # Store results
            cyclesvar[name][idx, sector] = std(model[name][:, n, sector])
            crosscorr[name][:, idx, sector] = crosscor(gdp_cycle, var_cycle, CORRELATION_LAGS)
            autocorr[name][:, idx, sector] = autocor(var_cycle, 0:AUTOCORR_LAGS)
        end
    end
    return
end

"""
Process a single variable for correlations and statistics.
"""
function process_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, n_seeds)
    if !haskey(model, name) || size(model[name], 1) != size(model["real_gdp_quarterly"], 1)
        return
    end

    return if ndims(model[name]) == 2
        process_2d_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref, model, name, file_idx, gdp_size, n_seeds)
    else
        process_3d_variable!(cyclesvar, crosscorr, autocorr, model, name, file_idx, gdp_size, n_seeds)
    end
end

"""
Single-pass processing of all simulation files.
Returns: (cyclesvar, crosscorr, autocorr, cycles_data)
"""
function process_all_simulation_data(model_folder, variable_names, gdp_size, n_seeds, n_quarters)
    @info "Processing simulation data with single pass"

    # Get prediction files
    prediction_files = filter(f -> endswith(f, ".jld2"), readdir(model_folder))
    sort!(prediction_files)

    if isempty(prediction_files)
        error("No prediction files found in $model_folder")
    end

    # Initialize with first file
    first_model = load(joinpath(model_folder, prediction_files[1]))["predictions_dict"]
    cyclesvar, crosscorr, autocorr, cycles_data = initialize_results(first_model, variable_names, gdp_size, n_quarters)

    # Use reference for cycles_data to allow modification
    cycles_data_ref = Ref{Union{Nothing, Dict{String, Any}}}(cycles_data)

    # Process each file exactly once
    for (file_idx, prediction_file) in enumerate(prediction_files)
        @info "Processing file $file_idx/$(length(prediction_files)): $prediction_file"

        model_path = joinpath(model_folder, prediction_file)
        model = load(model_path)["predictions_dict"]

        # Process all variables for this file
        for name in variable_names
            process_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref, model, name, file_idx, gdp_size, n_seeds)
        end
    end

    @info "Simulation data processing completed"
    return cyclesvar, crosscorr, autocorr, cycles_data_ref[]
end

"""
Calculate statistics from correlation results.
Returns: (mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, mean_cyclesvar)
"""
function calculate_statistics(crosscorr, autocorr, cyclesvar, variable_names)
    @info "Calculating statistics from correlation results"

    mean_xcorr = Dict{String, Any}()
    std_xcorr = Dict{String, Any}()
    mean_autocorr = Dict{String, Any}()
    std_autocorr = Dict{String, Any}()
    mean_cyclesvar = Dict{String, Any}()

    for name in variable_names
        if !haskey(crosscorr, name)
            continue
        end

        if ndims(crosscorr[name]) == 2
            mean_xcorr[name] = mean(crosscorr[name], dims = 2)
            std_xcorr[name] = std(crosscorr[name], dims = 2)
            mean_autocorr[name] = mean(autocorr[name], dims = 2)
            std_autocorr[name] = std(autocorr[name], dims = 2)
            mean_cyclesvar[name] = mean(cyclesvar[name])
        else
            # 3D case - aggregate over sectors
            mean_xcorr[name] = zeros(size(crosscorr[name], 1), MAX_SECTORS)
            std_xcorr[name] = zeros(size(crosscorr[name], 1), MAX_SECTORS)
            mean_autocorr[name] = zeros(DEFAULT_HORIZON + 1, MAX_SECTORS)
            std_autocorr[name] = zeros(DEFAULT_HORIZON + 1, MAX_SECTORS)
            mean_cyclesvar[name] = zeros(1, MAX_SECTORS)

            for sector in 1:MAX_SECTORS
                mean_xcorr[name][:, sector] = mean(crosscorr[name][:, :, sector], dims = 2)
                std_xcorr[name][:, sector] = std(crosscorr[name][:, :, sector], dims = 2)
                mean_autocorr[name][:, sector] = mean(autocorr[name][:, :, sector], dims = 2)
                std_autocorr[name][:, sector] = std(autocorr[name][:, :, sector], dims = 2)
                mean_cyclesvar[name][sector] = mean(cyclesvar[name][:, sector])
            end
        end
    end

    return mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, mean_cyclesvar
end

"""
Determine the appropriate GDP reference for correlations.
"""
function determine_gdp_reference(hp_cache)
    for gdp_var in ["real_gdp_quarterly", "real_gdp"]
        if haskey(hp_cache, gdp_var)
            return gdp_var
        end
    end
    return nothing
end

"""
Process single dimension real variable.
"""
function process_real_1d_variable!(crosscorr_data, autocorr_data, stderr_data, real_data, name, gdp_cycle, cached_data)
    _, cycle = cached_data

    # Align cycles by length
    min_length = min(length(cycle), length(gdp_cycle))
    max_length = max(length(cycle), length(gdp_cycle))
    gdp_cycle_adj = gdp_cycle[(1 + max_length - min_length):end]

    crosscorr_data[name] = crosscor(gdp_cycle_adj, cycle, CORRELATION_LAGS)
    autocorr_data[name] = autocor(cycle, 0:AUTOCORR_LAGS)
    return stderr_data[name] = std(real_data[name])
end

"""
Process multi-sector real variable.
"""
function process_real_3d_variable!(crosscorr_data, autocorr_data, stderr_data, real_data, name, gdp_cycle, cached_data)
    n_sectors = length(cached_data)
    crosscorr_data[name] = zeros(2 * CORRELATION_LAGS + 1, n_sectors)
    autocorr_data[name] = zeros(AUTOCORR_LAGS + 1, n_sectors)
    stderr_data[name] = zeros(n_sectors)

    for (sector, sector_data) in cached_data
        _, cycle = sector_data
        # Align cycles by length
        min_length = min(length(cycle), length(gdp_cycle))
        max_length = max(length(cycle), length(gdp_cycle))
        gdp_cycle_adj = gdp_cycle[(1 + max_length - min_length):end]

        crosscorr_data[name][:, sector] = crosscor(gdp_cycle_adj, cycle, CORRELATION_LAGS)
        autocorr_data[name][:, sector] = autocor(cycle, 0:AUTOCORR_LAGS)
        stderr_data[name][sector] = std(real_data[name][:, sector])
    end
    return
end

"""
Process real data correlations using cached HP filters.
Returns: (crosscorr_data, autocorr_data, stderr_data)
"""
function process_real_data_correlations(real_data, hp_cache, variable_names)
    @info "Processing real data correlations"

    crosscorr_data = Dict{String, Any}()
    autocorr_data = Dict{String, Any}()
    stderr_data = Dict{String, Any}()

    for name in variable_names
        if !haskey(hp_cache, name)
            continue
        end

        # Determine GDP reference
        gdp_ref = determine_gdp_reference(hp_cache)
        if gdp_ref === nothing
            @warn "No GDP reference found for correlations"
            continue
        end

        if isa(hp_cache[gdp_ref], Tuple)
            _, gdp_cycle = hp_cache[gdp_ref]
        else
            # Multi-dimensional case - use first sector
            _, gdp_cycle = first(values(hp_cache[gdp_ref]))
        end

        if isa(hp_cache[name], Tuple)
            # Single dimension case
            process_real_1d_variable!(
                crosscorr_data, autocorr_data, stderr_data,
                real_data, name, gdp_cycle, hp_cache[name]
            )
        else
            # Multi-sector case
            process_real_3d_variable!(
                crosscorr_data, autocorr_data, stderr_data,
                real_data, name, gdp_cycle, hp_cache[name]
            )
        end
    end

    return crosscorr_data, autocorr_data, stderr_data
end

"""
Create modernized cross-correlation plots.
"""
function create_crosscorr_plots(mean_xcorr, std_xcorr, real_crosscorr, output_folder)
    @info "Creating modernized cross-correlation plots"

    lags = collect(-CORRELATION_LAGS:CORRELATION_LAGS)
    cross_plots = plot(
        layout = (3, 2),
        size = (1400, 1000),
        plot_title = "Cross-Correlations with Real GDP",
        plot_titlefontsize = 16,
        margin = 5Plots.mm,
        dpi = 300
    )

    for (k, name) in enumerate(PLOT_VARIABLES)
        if !haskey(mean_xcorr, name) || !haskey(real_crosscorr, name)
            continue
        end

        # Model data with error bands (ribbon plot for better visibility)
        mean_vals = vec(mean_xcorr[name])
        std_vals = vec(std_xcorr[name])

        plot!(
            cross_plots, subplot = k, lags, mean_vals,
            yerror = std_vals,
            fillalpha = 0.3,
            fillcolor = :steelblue,
            label = "ABM Model",
            color = :steelblue,
            linewidth = 2.5,
            linestyle = :solid
        )

        # Real data with contrasting color (solid line)
        plot!(
            cross_plots, subplot = k, lags, vec(real_crosscorr[name]),
            linewidth = 3, color = :crimson, linestyle = :solid, label = "Real Data"
        )

        # Modern formatting
        formatted_name = format_variable_name(name)
        plot!(
            cross_plots, subplot = k,
            title = formatted_name,
            titlefontsize = 12,
            titlefontweight = :bold,
            xlabel = "Lags (Quarters)",
            ylabel = "Cross-Correlation",
            labelfontsize = 10,
            tickfontsize = 9,
            legendfontsize = 9,
            grid = true,
            gridwidth = 1,
            gridcolor = :lightgray,
            gridalpha = 0.5,
            framestyle = :box,
            background_color = :white,
            legend = :topright
        )

        # Add zero line for reference
        hline!(cross_plots, [0], subplot = k, color = :black, linestyle = :dot, linewidth = 1, alpha = 0.7, label = false)
        vline!(cross_plots, [0], subplot = k, color = :black, linestyle = :dot, linewidth = 1, alpha = 0.7, label = false)
    end

    output_path = joinpath(output_folder, "crosscorrelations_abm.png")
    savefig(cross_plots, output_path)
    @info "Modernized cross-correlation plots saved to $output_path"

    return cross_plots
end

"""
Create modernized autocorrelation plots.
"""
function create_autocorr_plots(mean_autocorr, std_autocorr, real_autocorr, output_folder)
    @info "Creating modernized autocorrelation plots"

    lags = collect(0:AUTOCORR_LAGS)
    auto_plots = plot(
        layout = (3, 2),
        size = (1400, 1000),
        plot_title = "Autocorrelations",
        plot_titlefontsize = 16,
        margin = 5Plots.mm,
        dpi = 300
    )

    for (k, name) in enumerate(PLOT_VARIABLES)
        if !haskey(mean_autocorr, name)
            continue
        end

        # Model data with error bands (ribbon plot for better visibility)
        mean_vals = vec(mean_autocorr[name])
        std_vals = vec(std_autocorr[name])

        plot!(
            auto_plots, subplot = k, lags, mean_vals,
            yerror = std_vals,
            fillalpha = 0.3,
            fillcolor = :steelblue,
            label = "ABM Model",
            color = :steelblue,
            linewidth = 2.5,
            linestyle = :solid
        )

        # Real data (if available) - solid line
        if haskey(real_autocorr, name) && !iszero(real_autocorr[name])
            plot!(
                auto_plots, subplot = k, lags, vec(real_autocorr[name]),
                linewidth = 3, color = :crimson, linestyle = :solid, label = "Real Data"
            )
        end

        # Modern formatting
        formatted_name = format_variable_name(name)
        plot!(
            auto_plots, subplot = k,
            title = formatted_name,
            titlefontsize = 12,
            titlefontweight = :bold,
            xlabel = "Lags (Quarters)",
            ylabel = "Autocorrelation",
            labelfontsize = 10,
            tickfontsize = 9,
            legendfontsize = 9,
            grid = true,
            gridwidth = 1,
            gridcolor = :lightgray,
            gridalpha = 0.5,
            framestyle = :box,
            background_color = :white,
            legend = :topright
        )

        # Add zero line for reference
        hline!(auto_plots, [0], subplot = k, color = :black, linestyle = :dot, linewidth = 1, alpha = 0.7, label = false)
    end

    output_path = joinpath(output_folder, "autocorrelations_abm.png")
    savefig(auto_plots, output_path)
    @info "Modernized autocorrelation plots saved to $output_path"

    return auto_plots
end

# =============================================================================
# SIMULATION SETUP SCRIPT
# =============================================================================

if RUN_SIMULATION
    @info "Starting simulation setup for $COUNTRY"

    try
        # Check if parameters and initial conditions already exist
        param_dir = joinpath(DEFAULT_FOLDER, "parameters")
        init_dir = joinpath(DEFAULT_FOLDER, "initial_conditions")

        param_exists = isdir(param_dir) && !isempty(filter(f -> endswith(f, ".jld2"), readdir(param_dir)))
        init_exists = isdir(init_dir) && !isempty(filter(f -> endswith(f, ".jld2"), readdir(init_dir)))

        if param_exists && init_exists
            @info "Parameters and initial conditions already exist, skipping generation"
        else
            @info "Generating parameters and initial conditions"
            # Save parameters and initial conditions
            Bit.save_all_params_and_initial_conditions(
                CALIBRATION,
                DEFAULT_FOLDER;
                scale = SCALE,
                first_calibration_date = FIRST_DATE,
                last_calibration_date = LAST_DATE,
            )
        end

        # Save simulations using existing parameters/initial conditions but with longrun suffix
        # Note: We'll need to manually modify the simulation and prediction storage

        # First run standard save_all_simulations (creates simulations/ folder)
        Bit.save_all_simulations(DEFAULT_FOLDER; T = T, n_sims = N_SIMS)

        # Then move/copy the results to longrun folders
        sim_dir = joinpath(DEFAULT_FOLDER, "simulations")
        sim_longrun_dir = joinpath(DEFAULT_FOLDER, "simulations_longrun")

        if isdir(sim_dir) && !isdir(sim_longrun_dir)
            cp(sim_dir, sim_longrun_dir)
            @info "Copied simulations to simulations_longrun folder"
        end

        # Align with real data for predictions (creates abm_predictions/ folder)
        real_data = CALIBRATION.data
        Bit.save_all_predictions_from_sims(DEFAULT_FOLDER, real_data)

        # Move predictions to longrun folder
        pred_dir = joinpath(DEFAULT_FOLDER, "abm_predictions")
        pred_longrun_dir = joinpath(DEFAULT_FOLDER, "abm_predictions_longrun")

        if isdir(pred_dir) && !isdir(pred_longrun_dir)
            cp(pred_dir, pred_longrun_dir)
            @info "Copied predictions to abm_predictions_longrun folder"
        end

        @info "Simulation data setup completed successfully"

    catch e
        error("Failed to setup simulation data: $e")
    end
end

# =============================================================================
# ANALYSIS SCRIPT
# =============================================================================

if RUN_ANALYSIS
    @info "Starting cross-correlation analysis for $COUNTRY"

    try
        # Setup paths and parameters
        output_folder = "./analysis/figs/$COUNTRY"

        # Get real data
        real_data = CALIBRATION.data

        # Calculate derived parameters
        n_years = year(LAST_DATE) - year(FIRST_DATE) + 1
        n_quarters = 4 * n_years

        # Setup paths - use longrun subfolder for analysis
        model_folder = joinpath(DEFAULT_FOLDER, "abm_predictions_longrun")
        mkpath(output_folder)

        # Load initial model to get structure
        model_files = filter(f -> endswith(f, ".jld2"), readdir(model_folder))
        if isempty(model_files)
            error("No model files found in $model_folder")
        end

        first_model_path = joinpath(model_folder, first(model_files))
        first_model = load(first_model_path)["predictions_dict"]
        gdp_size = size(first_model["real_gdp_quarterly"])

        # Get variable names
        variable_names = filter(name -> endswith(name, "_quarterly"), keys(first_model))

        # Create HP filter cache for real data
        hp_cache = create_hp_filter_cache(real_data, collect(variable_names))

        # Process simulation data (single pass)
        cyclesvar, crosscorr, autocorr, cycles_data = process_all_simulation_data(
            model_folder, collect(variable_names), gdp_size, N_SIMS, n_quarters
        )

        # Calculate statistics
        mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, _ =
            calculate_statistics(crosscorr, autocorr, cyclesvar, collect(variable_names))

        # Process real data correlations
        real_crosscorr, real_autocorr, _ =
            process_real_data_correlations(real_data, hp_cache, collect(variable_names))


        create_crosscorr_plots(mean_xcorr, std_xcorr, real_crosscorr, output_folder)
        create_autocorr_plots(mean_autocorr, std_autocorr, real_autocorr, output_folder)

        @info "Cross-correlation analysis completed successfully"

    catch e
        @error "Cross-correlation analysis failed: $e"
        rethrow(e)
    end
end
