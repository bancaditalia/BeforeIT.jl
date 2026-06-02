using Statistics, JLD2

# =============================================================================
# CORE PRIMITIVES
# =============================================================================

"""
    hpfilter(y; λ = 1600.0)

Hodrick-Prescott filter for business cycle analysis.

# Arguments
- `y`: time series data (vector)
- `λ`: smoothing parameter (default `1600` for quarterly data)

# Returns
- `trend`: trend component
- `cycle`: cyclical component (`y - trend`)
"""
function hpfilter(y; λ = 1600.0)
    T = length(y)

    # Second-difference matrix
    D = zeros(T - 2, T)
    for i in 1:(T - 2)
        D[i, i] = 1.0
        D[i, i + 1] = -2.0
        D[i, i + 2] = 1.0
    end

    trend = (I + λ .* (D' * D)) \ y
    cycle = y - trend

    return trend, cycle
end

"""
    cross_correlation(x, y, maxlag = 0)

Normalised cross-correlation between two equal-length series, similar to
MATLAB's `xcorr`. Population (biased, `/n`) normalisation is used so that the
result is consistent with [`auto_correlation`](@ref).

This is intentionally distinct from `StatsBase.crosscor`: it takes a single
scalar `maxlag` and returns the correlation at every lag in `-maxlag:maxlag`.

# Arguments
- `x`, `y`: equal-length time series
- `maxlag`: maximum (absolute) lag to compute

# Returns
- Cross-correlation values at lags `-maxlag:maxlag`
"""
function cross_correlation(x, y, maxlag = 0)
    nx = length(x)
    ny = length(y)

    if nx != ny
        error("Inputs must be of the same length")
    end

    # Center the data
    x_centered = x .- mean(x)
    y_centered = y .- mean(y)

    # Population standard deviations (biased estimator for consistency)
    x_std_dev = sqrt(sum(x_centered .^ 2) / nx)
    y_std_dev = sqrt(sum(y_centered .^ 2) / nx)

    lags = (-maxlag):maxlag
    result = zeros(length(lags))

    for (i, lag) in enumerate(lags)
        if abs(lag) >= nx
            result[i] = 0.0
        elseif lag == 0
            covariance = sum(x_centered .* y_centered) / nx
            result[i] = covariance / (x_std_dev * y_std_dev)
        elseif lag > 0
            # y leads x: correlate x[t] with y[t+lag]
            covariance = sum(x_centered[1:(end - lag)] .* y_centered[(lag + 1):end]) / nx
            result[i] = covariance / (x_std_dev * y_std_dev)
        else  # lag < 0
            # x leads y: correlate x[t+|lag|] with y[t]
            shift = abs(lag)
            covariance = sum(x_centered[(shift + 1):end] .* y_centered[1:(end - shift)]) / nx
            result[i] = covariance / (x_std_dev * y_std_dev)
        end
    end

    return result
end

"""
    auto_correlation(x, lags = 0:20)

Autocorrelation of a single series, similar to MATLAB's `autocorr`. Population
(biased, `/n`) normalisation is used, matching [`cross_correlation`](@ref).

This is intentionally distinct from `StatsBase.autocor`.

# Arguments
- `x`: time series data
- `lags`: range of lags to compute

# Returns
- Autocorrelation values at the requested `lags`
"""
function auto_correlation(x, lags = 0:20)
    nx = length(x)

    # Center the data (remove mean)
    x_centered = x .- mean(x)

    # Population variance (biased estimator for consistency)
    x_var = sum(x_centered .^ 2) / nx

    result = zeros(length(lags))

    for (i, lag) in enumerate(lags)
        if lag == 0
            result[i] = 1.0
        elseif lag >= nx
            result[i] = 0.0
        else
            covariance = sum(x_centered[1:(end - lag)] .* x_centered[(lag + 1):end]) / nx
            result[i] = covariance / x_var
        end
    end

    return result
end

# Strip Missing values from a series for HP filtering (requires contiguous numeric data)
strip_missing(y::Vector{Float64}) = y
strip_missing(y) = Float64.(collect(skipmissing(y)))

# =============================================================================
# CORRELATION STATISTICS
# =============================================================================

"""
    CorrelationStats

Cyclical correlation statistics for a set of variables, computed by
[`correlation_stats`](@ref). Each variable is HP-filtered and its cyclical
component is correlated against the GDP cycle (`crosscor`) and against itself
(`autocor`); `volatility` holds the standard deviation of the raw series.

The dictionaries are keyed by variable name. Each value is a matrix whose
columns are independent *samples* (one column for empirical data, one per
simulation for model output), so that ensemble means and bands can be obtained
with [`mean_crosscor`](@ref), [`std_crosscor`](@ref), [`mean_autocor`](@ref) and
[`std_autocor`](@ref).

# Fields
- `variables`: variable names that were processed
- `correlation_lags`: maximum lag of the cross-correlation (rows: `-L:L`)
- `autocorr_lags`: maximum lag of the autocorrelation (rows: `0:H`)
- `crosscor`: `name => (2*correlation_lags + 1) × samples` matrix
- `autocor`: `name => (autocorr_lags + 1) × samples` matrix
- `volatility`: `name => samples`-length vector of raw standard deviations
"""
struct CorrelationStats
    variables::Vector{String}
    correlation_lags::Int
    autocorr_lags::Int
    crosscor::Dict{String, Matrix{Float64}}
    autocor::Dict{String, Matrix{Float64}}
    volatility::Dict{String, Vector{Float64}}
end

# First available GDP key, or `nothing`
function _gdp_reference(data, gdp_var)
    for v in (gdp_var, "real_gdp")
        haskey(data, v) && return v
    end
    return nothing
end

# Normalise a stored series into a `time × samples` matrix.
# Empirical series are vectors (one sample); simulation output is already a matrix.
_as_columns(v::AbstractVector) = reshape(strip_missing(v), :, 1)
_as_columns(m::AbstractMatrix) = m

"""
    correlation_stats(data::AbstractDict, variables; gdp_var = "real_gdp_quarterly",
                         correlation_lags = 15, autocorr_lags = 20)

Compute [`CorrelationStats`](@ref) from an in-memory dictionary of series.

`data` maps variable names to either empirical series (vectors, e.g. a
calibration's `.data`) or simulation output (`time × n_sims` matrices, e.g. a
`predictions_dict`). Variables not present in `data`, not numeric arrays, or
whose sample count differs from the GDP reference are skipped. Empirical series
of differing length are front-aligned before cross-correlation.

    correlation_stats(folder::AbstractString, variables; kwargs...)

Convenience method that loads every `YYYYQn.jld2` prediction file in `folder`
(via the same `extract_yq` convention as [`save_all_predictions_from_sims`](@ref))
and concatenates their simulations into a single `CorrelationStats`.
"""
function correlation_stats(
        data::AbstractDict, variables;
        gdp_var = "real_gdp_quarterly", correlation_lags = 15, autocorr_lags = 20,
    )
    gdp_ref = _gdp_reference(data, gdp_var)
    gdp_ref === nothing && error("No GDP reference ('$gdp_var' or 'real_gdp') found in data")
    gdp_cols = _as_columns(data[gdp_ref])

    crosscor = Dict{String, Matrix{Float64}}()
    autocor = Dict{String, Matrix{Float64}}()
    volatility = Dict{String, Vector{Float64}}()
    found = String[]

    for name in variables
        (haskey(data, name) && data[name] isa AbstractVecOrMat) || continue
        cols = _as_columns(data[name])
        n_samples = size(cols, 2)
        size(gdp_cols, 2) == n_samples || continue

        xc = zeros(2 * correlation_lags + 1, n_samples)
        ac = zeros(autocorr_lags + 1, n_samples)
        vol = zeros(n_samples)

        for n in 1:n_samples
            _, gdp_cycle = hpfilter(gdp_cols[:, n])
            _, var_cycle = hpfilter(cols[:, n])

            # Front-align cycles (matters only for unequal-length empirical series)
            m = min(length(gdp_cycle), length(var_cycle))
            xc[:, n] = cross_correlation(gdp_cycle[(end - m + 1):end], var_cycle[(end - m + 1):end], correlation_lags)
            ac[:, n] = auto_correlation(var_cycle, 0:autocorr_lags)
            vol[n] = std(cols[:, n])
        end

        crosscor[name] = xc
        autocor[name] = ac
        volatility[name] = vol
        push!(found, name)
    end

    return CorrelationStats(found, correlation_lags, autocorr_lags, crosscor, autocor, volatility)
end

function correlation_stats(folder::AbstractString, variables; kwargs...)
    files = sort(collect(extract_yq(readdir(folder))))
    isempty(files) && error("No valid prediction files (YYYYQn.jld2) found in $folder")
    @info "Found $(length(files)) prediction files in $folder"

    stats = [
        correlation_stats(load(joinpath(folder, f))["predictions_dict"], variables; kwargs...)
            for f in files
    ]
    return reduce(_merge_samples, stats)
end

# Concatenate the sample columns of two CorrelationStats (same variables and lags)
function _merge_samples(a::CorrelationStats, b::CorrelationStats)
    crosscor = Dict(k => hcat(a.crosscor[k], b.crosscor[k]) for k in keys(a.crosscor) if haskey(b.crosscor, k))
    autocor = Dict(k => hcat(a.autocor[k], b.autocor[k]) for k in keys(a.autocor) if haskey(b.autocor, k))
    volatility = Dict(k => vcat(a.volatility[k], b.volatility[k]) for k in keys(a.volatility) if haskey(b.volatility, k))
    return CorrelationStats(a.variables, a.correlation_lags, a.autocorr_lags, crosscor, autocor, volatility)
end

"""
    mean_crosscor(stats, var)
    std_crosscor(stats, var)
    mean_autocor(stats, var)
    std_autocor(stats, var)

Ensemble mean / standard deviation across samples of the cross- and
autocorrelation of `var` in a [`CorrelationStats`](@ref), returned as vectors
over the respective lags. The standard deviation is undefined for single-sample
(empirical) statistics.
"""
mean_crosscor(stats::CorrelationStats, var) = vec(mean(stats.crosscor[var]; dims = 2))
std_crosscor(stats::CorrelationStats, var) = vec(std(stats.crosscor[var]; dims = 2))
mean_autocor(stats::CorrelationStats, var) = vec(mean(stats.autocor[var]; dims = 2))
std_autocor(stats::CorrelationStats, var) = vec(std(stats.autocor[var]; dims = 2))

# =============================================================================
# DATA LOADING
# =============================================================================

"""
    load_calibration_data(country_code)

Load the calibration object for `country_code` from migrated data on disk,
looking under `data/<country_code>/` (relative to the working directory) for
`calibration_object.jld2`, then `calibration_data.jld2`.

# Arguments
- `country_code`: country identifier string

# Returns
- the calibration object stored in the file
"""
function load_calibration_data(country_code)
    @info "Loading calibration data for $country_code from migrated data"

    country_dir = "data/$(lowercase(country_code))"
    if !isdir(country_dir)
        error("No migrated data found for $country_code at $country_dir")
    end

    # Try calibration_object.jld2 first, then calibration_data.jld2
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
