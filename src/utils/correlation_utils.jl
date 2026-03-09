import BeforeIT as Bit
using LinearAlgebra, Statistics, JLD2, Dates

# =============================================================================
# CORE PROCESSING FUNCTIONS
# =============================================================================

"""
    hpfilter(y; λ = 1600.0)

Hodrick-Prescott filter implementation for business cycle analysis.

# Arguments
- `y`: Time series data
- `λ`: Smoothing parameter (default 1600 for quarterly data)

# Returns
- `trend`: Trend component
- `cycle`: Cyclical component
"""
function hpfilter(y; λ = 1600.0)
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

"""
    crosscor(x, y, maxlag = 0)

Cross-correlation function with normalization, similar to MATLAB's xcorr.

# Arguments
- `x`: First time series
- `y`: Second time series
- `maxlag`: Maximum lag to compute

# Returns
- Cross-correlation values at lags -maxlag:maxlag
"""
function crosscor(x, y, maxlag = 0)
    nx = length(x)
    ny = length(y)

    if nx != ny
        error("Inputs must be of the same length")
    end

    # Center the data
    x_centered = x .- mean(x)
    y_centered = y .- mean(y)

    # Calculate population standard deviations (biased estimator for consistency)
    x_std_dev = sqrt(sum(x_centered .^ 2) / nx)
    y_std_dev = sqrt(sum(y_centered .^ 2) / nx)

    lags = (-maxlag):maxlag
    xcorr_result = zeros(length(lags))

    for (i, lag) in enumerate(lags)
        if abs(lag) >= nx
            xcorr_result[i] = 0.0
        else
            if lag == 0
                # No lag case
                covariance = sum(x_centered .* y_centered) / nx
            elseif lag > 0
                # y leads x: correlate x[t] with y[t+lag]
                covariance = sum(x_centered[1:(end - lag)] .* y_centered[(lag + 1):end]) / nx
            else  # lag < 0
                # x leads y: correlate x[t+|lag|] with y[t]
                shift = abs(lag)
                covariance = sum(x_centered[(shift + 1):end] .* y_centered[1:(end - shift)]) / nx
            end

            # Normalize by standard deviations to get correlation
            xcorr_result[i] = covariance / (x_std_dev * y_std_dev)
        end
    end

    return xcorr_result
end

"""
    autocor(x, lags = 0:20)

Autocorrelation function similar to MATLAB's autocorr.

# Arguments
- `x`: Time series data
- `lags`: Range of lags to compute

# Returns
- Autocorrelation values at specified lags
"""
function autocor(x, lags = 0:20)
    nx = length(x)

    # Center the data (remove mean)
    x_centered = x .- mean(x)

    # Calculate population variance (biased estimator for consistency with MATLAB)
    x_var = sum(x_centered .^ 2) / nx

    acorr_result = zeros(length(lags))

    for (i, lag) in enumerate(lags)
        if lag == 0
            # Autocorrelation at lag 0 is always 1.0
            acorr_result[i] = 1.0
        elseif lag >= nx
            # Not enough data for this lag
            acorr_result[i] = 0.0
        else
            # Calculate autocorrelation for lag > 0 using consistent /nx normalization
            covariance = sum(x_centered[1:(end - lag)] .* x_centered[(lag + 1):end]) / nx
            acorr_result[i] = covariance / x_var
        end
    end

    return acorr_result
end

"""
    create_hp_filter_cache(real_data, variable_names)

Create HP filter cache for real data to avoid recomputation.

# Arguments
- `real_data`: Dictionary containing real economic data
- `variable_names`: Collection of variable names to process

# Returns
- `cache`: Dict with cached HP filter results
"""
# Strip Missing values from a vector for HP filtering (requires contiguous numeric data)
strip_missing(y::Vector{Float64}) = y
strip_missing(y) = Float64.(collect(skipmissing(y)))

function create_hp_filter_cache(real_data, variable_names)
    @info "Creating HP filter cache for real data"

    cache = Dict{String, Any}()

    # Cache GDP data first (used as reference)
    for gdp_var in ["real_gdp_quarterly", "real_gdp"]
        if haskey(real_data, gdp_var)
            trend, cycle = hpfilter(strip_missing(real_data[gdp_var]))
            cache[gdp_var] = (trend, cycle)
        end
    end

    # Cache other variables
    for name in variable_names
        if haskey(real_data, name)
            trend, cycle = hpfilter(strip_missing(real_data[name]))
            cache[name] = (trend, cycle)
        end
    end

    return cache
end

"""
    determine_gdp_reference(hp_cache)

Determine the appropriate GDP reference for correlations.

# Arguments
- `hp_cache`: HP filter cache dictionary

# Returns
- GDP variable name or nothing if not found
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
    process_real_1d_variable!(crosscorr_data, autocorr_data, stderr_data, real_data, name, gdp_cycle, cached_data, correlation_lags, autocorr_lags)

Process single dimension real variable.

# Arguments
- `crosscorr_data`: Dictionary to store cross-correlation results
- `autocorr_data`: Dictionary to store autocorrelation results
- `stderr_data`: Dictionary to store standard error results
- `real_data`: Real economic data
- `name`: Variable name
- `gdp_cycle`: GDP cycle data for cross-correlation reference
- `cached_data`: Cached HP filter results for this variable
- `correlation_lags`: Number of lags for cross-correlation
- `autocorr_lags`: Number of lags for autocorrelation
"""
function process_real_1d_variable!(crosscorr_data, autocorr_data, stderr_data, real_data, name, gdp_cycle, cached_data, correlation_lags, autocorr_lags)
    _, cycle = cached_data

    # Align cycles by length
    min_length = min(length(cycle), length(gdp_cycle))
    max_length = max(length(cycle), length(gdp_cycle))
    gdp_cycle_adj = gdp_cycle[(1 + max_length - min_length):end]

    crosscorr_data[name] = crosscor(gdp_cycle_adj, cycle, correlation_lags)
    autocorr_data[name] = autocor(cycle, 0:autocorr_lags)
    return stderr_data[name] = std(strip_missing(real_data[name]))
end

"""
    process_real_data_correlations(real_data, hp_cache, variable_names, correlation_lags, autocorr_lags)

Process real data correlations using cached HP filters.

# Arguments
- `real_data`: Real economic data dictionary
- `hp_cache`: HP filter cache dictionary
- `variable_names`: Collection of variable names to process
- `correlation_lags`: Number of lags for cross-correlation
- `autocorr_lags`: Number of lags for autocorrelation

# Returns
- `(crosscorr_data, autocorr_data, stderr_data)`: Processed correlation data
"""
function process_real_data_correlations(real_data, hp_cache, variable_names, correlation_lags, autocorr_lags)
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

        _, gdp_cycle = hp_cache[gdp_ref]

        process_real_1d_variable!(
            crosscorr_data, autocorr_data, stderr_data,
            real_data, name, gdp_cycle, hp_cache[name], correlation_lags, autocorr_lags
        )
    end

    return crosscorr_data, autocorr_data, stderr_data
end

# =============================================================================
# SIMULATION PROCESSING FUNCTIONS
# =============================================================================

"""
    initialize_results(first_model, variable_names, gdp_size, n_quarters, correlation_lags, default_horizon)

Initialize result dictionaries based on model structure.

# Arguments
- `first_model`: First model data to determine structure
- `variable_names`: Collection of variable names
- `gdp_size`: Size of GDP data (time, simulations)
- `n_quarters`: Number of quarters
- `correlation_lags`: Number of lags for cross-correlation
- `default_horizon`: Default horizon for autocorrelation

# Returns
- `(cyclesvar, crosscorr, autocorr, cycles_data)`: Initialized result dictionaries
"""
function initialize_results(first_model, variable_names, gdp_size, n_files, correlation_lags, default_horizon)
    cyclesvar = Dict{String, Any}()
    crosscorr = Dict{String, Any}()
    autocorr = Dict{String, Any}()

    n_total = n_files * gdp_size[2]

    @info "Initializing arrays for $n_files files × $(gdp_size[2]) simulations = $n_total total simulations"

    for name in variable_names
        if haskey(first_model, name) && ndims(first_model[name]) == 2
            cyclesvar[name] = zeros(n_total)
            crosscorr[name] = zeros(2 * correlation_lags + 1, n_total)
            autocorr[name] = zeros(default_horizon + 1, n_total)
        end
    end

    cycles_data = nothing
    return cyclesvar, crosscorr, autocorr, cycles_data
end

"""
    store_cycle_data!(cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, name, trend, cycle, n, gdp_size, cycle_variables)

Store cycle data for plotting.

# Arguments
- `cycles_data_ref`: Reference to cycles data dictionary
- `name`: Variable name
- `trend`: Trend component
- `cycle`: Cycle component
- `n`: Simulation index
- `gdp_size`: Size of GDP data
- `cycle_variables`: List of cycle variables to track
"""
function store_cycle_data!(cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, name, trend, cycle, n, gdp_size, cycle_variables)
    if cycles_data_ref[] === nothing
        cycles_data_ref[] = Dict(
            "trends" => Dict{String, Matrix{Float64}}(),
            "cycles" => Dict{String, Matrix{Float64}}(),
            "cyclesnames" => cycle_variables
        )

        for cycle_name in cycle_variables
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
    process_2d_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)

Process 2D variable (time x simulations).

# Arguments
- `cyclesvar`: Dictionary to store cycle variance results
- `crosscorr`: Dictionary to store cross-correlation results
- `autocorr`: Dictionary to store autocorrelation results
- `cycles_data_ref`: Reference to cycles data for plotting
- `model`: Model data dictionary
- `name`: Variable name
- `file_idx`: File index
- `gdp_size`: Size of GDP data
- `correlation_lags`: Number of lags for cross-correlation
- `autocorr_lags`: Number of lags for autocorrelation
- `cycle_variables`: List of cycle variables to track
"""
function process_2d_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)
    for n in 1:gdp_size[2]
        # Compute HP filters
        _, gdp_cycle = hpfilter(model["real_gdp_quarterly"][:, n])
        _, var_cycle = hpfilter(model[name][:, n])

        # Calculate index
        idx = (file_idx - 1) * gdp_size[2] + n

        # Store results
        cyclesvar[name][idx] = std(model[name][:, n])
        crosscorr[name][:, idx] = crosscor(gdp_cycle, var_cycle, correlation_lags)
        autocorr[name][:, idx] = autocor(var_cycle, 0:autocorr_lags)

        # Store cycle data for first file
        if file_idx == 1 && name in cycle_variables
            var_trend, _ = hpfilter(model[name][:, n])
            store_cycle_data!(cycles_data_ref, name, var_trend, var_cycle, n, gdp_size, cycle_variables)
        end
    end
    return
end

"""
    process_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)

Process a single variable for correlations and statistics.

# Arguments
- `cyclesvar`: Dictionary to store cycle variance results
- `crosscorr`: Dictionary to store cross-correlation results
- `autocorr`: Dictionary to store autocorrelation results
- `cycles_data_ref`: Reference to cycles data for plotting
- `model`: Model data dictionary
- `name`: Variable name
- `file_idx`: File index
- `gdp_size`: Size of GDP data
- `correlation_lags`: Number of lags for cross-correlation
- `autocorr_lags`: Number of lags for autocorrelation
- `cycle_variables`: List of cycle variables to track
"""
function process_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref::Ref{Union{Nothing, Dict{String, Any}}}, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)
    if !haskey(model, name) || size(model[name], 1) != size(model["real_gdp_quarterly"], 1)
        return
    end
    ndims(model[name]) == 2 || return
    process_2d_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)
end

"""
    process_all_simulation_data(model_folder, variable_names, gdp_size, n_quarters, correlation_lags, default_horizon, autocorr_lags, cycle_variables)

Single-pass processing of all simulation files.

# Arguments
- `model_folder`: Path to model prediction files
- `variable_names`: Collection of variable names to process
- `gdp_size`: Size of GDP data (time, simulations)
- `n_quarters`: Number of quarters
- `correlation_lags`: Number of lags for cross-correlation
- `default_horizon`: Default horizon for autocorrelation
- `autocorr_lags`: Number of lags for autocorrelation
- `cycle_variables`: List of cycle variables to track

# Returns
- `(cyclesvar, crosscorr, autocorr, cycles_data)`: Processed correlation data
"""
function process_all_simulation_data(model_folder, variable_names, gdp_size, n_quarters, correlation_lags, default_horizon, autocorr_lags, cycle_variables)
    @info "Processing simulation data with single pass"

    # Get prediction files and extract valid year-quarter combinations
    prediction_files = filter(f -> endswith(f, ".jld2"), readdir(model_folder))

    # Extract year and quarter from filenames like 2010Q1.jld2 (same pattern as save_all_simulations)
    function extract_yq(files)
        return Set([match(r"^(\d{4}Q\d)\.jld2$", f)[1] for f in files if occursin(r"Q", f) && match(r"^(\d{4}Q\d)\.jld2$", f) !== nothing])
    end

    prediction_yq = extract_yq(prediction_files)
    valid_filenames = sort(collect(prediction_yq))

    if isempty(valid_filenames)
        error("No valid prediction files found in $model_folder")
    end

    @info "Found $(length(valid_filenames)) valid prediction files with year-quarter pattern"

    # Use first valid file for initialization
    first_file = first(valid_filenames) * ".jld2"
    first_model = load(joinpath(model_folder, first_file))["predictions_dict"]
    cyclesvar, crosscorr, autocorr, cycles_data = initialize_results(first_model, variable_names, gdp_size, length(valid_filenames), correlation_lags, default_horizon)

    # Use reference for cycles_data to allow modification
    cycles_data_ref = Ref{Union{Nothing, Dict{String, Any}}}(cycles_data)

    # Process each valid file exactly once
    for (file_idx, yq_filename) in enumerate(valid_filenames)
        prediction_file = yq_filename * ".jld2"
        @info "Processing file $file_idx/$(length(valid_filenames)): $prediction_file"

        model_path = joinpath(model_folder, prediction_file)
        model = load(model_path)["predictions_dict"]

        # Process all variables for this file
        for name in variable_names
            process_variable!(cyclesvar, crosscorr, autocorr, cycles_data_ref, model, name, file_idx, gdp_size, correlation_lags, autocorr_lags, cycle_variables)
        end
    end

    @info "Simulation data processing completed"
    return cyclesvar, crosscorr, autocorr, cycles_data_ref[]
end

# =============================================================================
# STATISTICAL FUNCTIONS
# =============================================================================

"""
    calculate_statistics(crosscorr, autocorr, cyclesvar, variable_names)

Calculate statistics from correlation results.

# Arguments
- `crosscorr`: Cross-correlation results from simulations
- `autocorr`: Autocorrelation results from simulations
- `cyclesvar`: Cycle variance results from simulations
- `variable_names`: Collection of variable names

# Returns
- `(mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, mean_cyclesvar)`: Statistical summaries
"""
function calculate_statistics(crosscorr, autocorr, cyclesvar, variable_names)
    @info "Calculating statistics from correlation results"

    mean_xcorr = Dict{String, Any}()
    std_xcorr = Dict{String, Any}()
    mean_autocorr = Dict{String, Any}()
    std_autocorr = Dict{String, Any}()
    mean_cyclesvar = Dict{String, Any}()

    for name in variable_names
        haskey(crosscorr, name) || continue
        mean_xcorr[name] = mean(crosscorr[name], dims = 2)
        std_xcorr[name] = std(crosscorr[name], dims = 2)
        mean_autocorr[name] = mean(autocorr[name], dims = 2)
        std_autocorr[name] = std(autocorr[name], dims = 2)
        if haskey(cyclesvar, name)
            mean_cyclesvar[name] = mean(cyclesvar[name])
        end
    end

    return mean_xcorr, std_xcorr, mean_autocorr, std_autocorr, mean_cyclesvar
end

""""
    load_calibration_data(country_code)
Load calibration data for a given country from migrated data.
# Arguments
- `country_code`: Country identifier string
# Returns
- Calibration data object
"""

function load_calibration_data(country_code)
    @info "Loading calibration data for $country_code from migrated data"

    country_dir = "data/$(lowercase(country_code))"
    if !isdir(country_dir)
        error("No migrated data found for $country_code at $country_dir")
    end

    # Try to load calibration_object.jld2 first, then calibration_data.jld2
    calibration_object_file = joinpath(country_dir, "calibration_object.jld2")
    calibration_data_file = joinpath(country_dir, "calibration_data.jld2")

    if isfile(calibration_object_file)
        return load(calibration_object_file)["calibration_object"]
    elseif isfile(calibration_data_file)
        return load(calibration_data_file)["calibration_data"]
    else
        error("No calibration data found for $country_code in $country_dir")
    end
end

