using LinearAlgebra, Statistics

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

"""
    format_variable_name(name)

Format variable names for plot titles by removing suffixes and cleaning up.

# Arguments
- `name`: Variable name string

# Returns
- Formatted string suitable for plot titles
"""
function format_variable_name(name)
    # Remove quarterly suffix if present
    if length(name) > 9 && name[(end - 8):end] == "quarterly"
        str = name[1:(end - 10)]
    else
        str = name
    end

    # Replace underscores with spaces and capitalize
    str = replace(str, "_" => " ")
    str = titlecase(str)

    return str
end
