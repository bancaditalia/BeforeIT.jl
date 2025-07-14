using StatsBase, DSP, LinearAlgebra, Statistics, Dates
using Plots, StatsPlots
using MAT, JLD2, FileIO
import BeforeIT as Bit

function generate_crosscorrelation_graphs(
    country::String = "italy";
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
        # First check if DSP.jl has this function
        if isdefined(DSP, :hpf)
            try
                trend = DSP.hpf(y, λ)
                cycle = y - trend
                return trend, cycle
            catch
                # Fall back to manual implementation
            end
        end

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
    cyclesnames = ["real_gdp_quarterly", "real_capitalformation_quarterly", "real_household_consumption_quarterly","operating_surplus_quarterly"]

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
