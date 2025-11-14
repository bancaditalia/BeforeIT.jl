module BeforeITPlots

import BeforeIT as Bit
using Plots, StatsPlots, Dates

# Constants for default plotting behavior
const DEFAULT_QUANTITIES = [
    :real_gdp, 
    :real_household_consumption, 
    :real_government_consumption,
    :real_capitalformation, 
    :real_exports, 
    :real_imports, 
    :wages, 
    :euribor, 
    :gdp_deflator,
]

const QUANTITY_TITLES = Dict(
    :real_gdp => "GDP",
    :real_household_consumption => "Household Cons.",
    :real_government_consumption => "Gov. Cons.",
    :real_capitalformation => "Capital Form.",
    :real_exports => "Exports",
    :real_imports => "Imports",
    :gdp_deflator => "GDP Deflator",
)

const DEFAULT_TITLEFONT = 9
const DEFAULT_TICKFONT = 7
const SCALE_FACTOR = 1.0e6  # Scale from millions to actual values

# Helper functions

"""
    get_plot_title(quantity::Symbol) -> String

Return a human-readable title for the given quantity symbol.
Falls back to string conversion if not in QUANTITY_TITLES.
"""
get_plot_title(quantity::Symbol) = get(QUANTITY_TITLES, quantity, string(quantity))

"""
    compute_quantity_data(data_vector, quantity::Symbol)

Extract or compute the data for a given quantity from a DataVector.
GDP deflator is computed as nominal_gdp / real_gdp, other quantities are extracted directly.
"""
function compute_quantity_data(data_vector, quantity::Symbol)
    if quantity == :gdp_deflator
        return data_vector.nominal_gdp ./ data_vector.real_gdp
    else
        return getproperty(data_vector, quantity)
    end
end

"""
    plot_data_vector(model; titlefont=DEFAULT_TITLEFONT, quantities=DEFAULT_QUANTITIES, t_start=nothing, t_end=nothing)

Create error ribbon plots for economic quantities from a single model with ensemble runs.
Returns a vector of plot objects showing mean trajectories with uncertainty bands.

# Arguments
- `model`: A BeforeIT model object
- `titlefont::Int`: Font size for plot titles
- `quantities::Vector{Symbol}`: Economic quantities to plot
- `t_start::Union{Int,Nothing}`: Starting time period (default: first period)
- `t_end::Union{Int,Nothing}`: Ending time period (default: last period)

# Returns
- `Vector`: Array of plot objects
"""
function Bit.plot_data_vector(
    model_vector; 
    titlefont::Int = DEFAULT_TITLEFONT, 
    quantities::Vector{Symbol} = DEFAULT_QUANTITIES,
    t_start::Union{Int,Nothing} = nothing,
    t_end::Union{Int,Nothing} = nothing
)
    data_vector = Bit.DataVector(model_vector)
    time_length = length(data_vector.vector[1].wages)
    
    # Determine time range
    start_idx = isnothing(t_start) ? 1 : max(1, t_start)
    end_idx = isnothing(t_end) ? time_length : min(time_length, t_end)
    time_range = start_idx:end_idx
    
    plots = Vector{Plots.Plot}(undef, length(quantities))
    
    for (i, quantity) in enumerate(quantities)
        title = get_plot_title(quantity)
        full_data = compute_quantity_data(data_vector, quantity)
        
        # Slice data to the specified time range
        data = full_data[time_range, :]
        
        plots[i] = errorline(
            collect(time_range), 
            data,
            errorstyle = :ribbon, 
            title = title, 
            titlefont = titlefont, 
            legend = false
        )
    end
    
    return plots
end

"""
    plot_data_vectors(model_vector; titlefont=DEFAULT_TITLEFONT, quantities=DEFAULT_QUANTITIES)

Create overlaid error ribbon plots comparing multiple models.
Each model appears as a separate line/ribbon on the same plot.

# Arguments
- `model_vector`: Vector of BeforeIT model objects to compare
- `titlefont::Int`: Font size for plot titles
- `quantities::Vector{Symbol}`: Economic quantities to plot

# Returns
- `Vector`: Array of plot objects, one per quantity
"""
function Bit.plot_data_vectors(
    model_vectors; 
    titlefont::Int = DEFAULT_TITLEFONT, 
    quantities::Vector{Symbol} = DEFAULT_QUANTITIES
)
    data_vectors = Bit.DataVector.(model_vectors)
    time_length = length(data_vectors[1].vector[1].wages)
    time_range = 1:time_length
    
    plots = Vector{Plots.Plot}(undef, length(quantities))
    
    for (i, quantity) in enumerate(quantities)
        title = get_plot_title(quantity)
        
        # Create initial plot with first data vector
        first_data = compute_quantity_data(data_vectors[1], quantity)
        p = errorline(
            time_range, 
            first_data,
            errorstyle = :ribbon, 
            title = title, 
            titlefont = titlefont, 
            legend = false
        )
        
        # Overlay remaining data vectors
        for data_vector in data_vectors[2:end]
            overlay_data = compute_quantity_data(data_vector, quantity)
            errorline!(
                time_range, 
                overlay_data,
                errorstyle = :ribbon, 
                titlefont = titlefont, 
                legend = false
            )
        end
        
        plots[i] = p
    end
    
    return plots
end

"""
    plot_data(model; titlefont=DEFAULT_TITLEFONT, quantities=DEFAULT_QUANTITIES)

Create simple line plots for economic quantities from a single model run.
No uncertainty bands are shown.

# Arguments
- `model`: A BeforeIT model object
- `titlefont::Int`: Font size for plot titles
- `quantities::Vector{Symbol}`: Economic quantities to plot

# Returns
- `Vector`: Array of plot objects
"""
function Bit.plot_data(
    model; 
    titlefont::Int = DEFAULT_TITLEFONT, 
    quantities::Vector{Symbol} = DEFAULT_QUANTITIES
)
    data = model.data
    plots = Vector{Plots.Plot}(undef, length(quantities))
    
    for (i, quantity) in enumerate(quantities)
        title = get_plot_title(quantity)
        
        # Compute the data (handles GDP deflator special case)
        if quantity == :gdp_deflator
            plot_data = data.nominal_gdp ./ data.real_gdp
        else
            plot_data = getproperty(data, quantity)
        end
        
        plots[i] = plot(
            plot_data,
            title = title, 
            titlefont = titlefont, 
            legend = false
        )
    end
    
    return plots
end


"""
    generate_year_ticks(time_numbers) -> (Vector, Vector)

Generate tick marks showing only unique years from numerical time values.
Returns a tuple of (tick_positions, year_labels).
"""
function generate_year_ticks(time_numbers)
    num_ticks = Int[]
    year_ticks = Int[]
    
    for time_num in time_numbers
        y = year(Bit.num2date(time_num))
        if !(y in year_ticks)
            push!(num_ticks, time_num)
            push!(year_ticks, y)
        end
    end
    
    return num_ticks, year_ticks
end

"""
    parse_variable_name(varname::AbstractString) -> (String, String)

Parse variable name to determine time axis type and display title.
Returns (x_nums, title) where x_nums is "quarters_num" or "years_num".
"""
function parse_variable_name(varname::AbstractString)
    # Check if variable name ends with "quarterly"
    if length(varname) > 9 && endswith(varname, "quarterly")
        x_nums = "quarters_num"
        title = varname[1:(end - 10)]  # Remove "_quarterly" suffix
    else
        x_nums = "years_num"
        title = varname
    end
    
    return x_nums, title
end

"""
    compute_axis_limits(model, real, varname, x_nums, crop::Bool)

Compute appropriate x and y axis limits for model vs. real data comparison.
"""
function compute_axis_limits(model, real, varname, x_nums, crop::Bool)
    if !crop
        return :auto, :auto
    end
    
    # X-axis limits from model data
    min_x = minimum(model[x_nums])
    max_x = maximum(model[x_nums])
    xlimits = (min_x, max_x)
    
    # Y-axis limits from overlapping region
    real_mask = min_x .<= real[x_nums] .<= max_x
    min_y = minimum(real[varname][real_mask])
    max_y = maximum(real[varname][real_mask])
    
    # Expand to include model data range
    min_y = min(min_y, minimum(model[varname]))
    max_y = max(max_y, maximum(model[varname]))
    
    ylimits = (min_y, max_y) .* SCALE_FACTOR
    
    return xlimits, ylimits
end

"""
    plot_model_vs_real(model, real, varname; crop=true)

Compare model predictions against real-world historical data.

Creates a plot with:
- Real data as a line
- Model predictions as an error ribbon (mean ± std)
- Scaled values (×10⁶) for readability
- Year labels on x-axis

# Arguments
- `model`: Model simulation results
- `real`: Real-world historical data
- `varname::AbstractString`: Variable name to plot
- `crop::Bool`: If true, zoom to model's time period

# Returns
- `Plot`: Plots.jl plot object
"""
function Bit.plot_model_vs_real(
    model, 
    real, 
    varname::AbstractString; 
    crop::Bool = true
)
    # Determine time axis and plot title
    x_nums, title = parse_variable_name(varname)
    
    # Compute axis limits
    xlimits, ylimits = compute_axis_limits(model, real, varname, x_nums, crop)
    
    # Generate year tick marks
    tick_source = crop ? model[x_nums] : real[x_nums]
    num_ticks, year_ticks = generate_year_ticks(tick_source)
    
    # Create base plot with real data
    p = plot(
        real[x_nums], 
        SCALE_FACTOR * real[varname], 
        label = "Real", 
        title = title,
        titlefontsize = DEFAULT_TITLEFONT, 
        xlimits = xlimits, 
        ylimits = ylimits, 
        xticks = (num_ticks, year_ticks),
        xrotation = 20, 
        tickfontsize = DEFAULT_TICKFONT,
    )
    
    # Overlay model predictions with uncertainty
    StatsPlots.errorline!(
        model[x_nums], 
        SCALE_FACTOR * model[varname], 
        errorstyle = :ribbon, 
        label = "Model", 
        errortype = :std
    )
    
    return p
end

end
