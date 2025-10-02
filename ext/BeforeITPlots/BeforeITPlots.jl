module BeforeITPlots

import BeforeIT as Bit
using Plots, StatsPlots, Dates

const default_quantities = [
    :real_gdp, :real_household_consumption, :real_government_consumption,
    :real_capitalformation, :real_exports, :real_imports, :wages, :euribor, :gdp_deflator,
]

# define a table that maps the quantities to concise names
const quantity_titles = Dict(
    :real_gdp => "gdp",
    :real_household_consumption => "household cons.",
    :real_government_consumption => "gov. cons.",
    :real_capitalformation => "capital form.",
    :real_exports => "exports",
    :real_imports => "imports",
    :gdp_deflator => "gdp deflator",
)

function Bit.plot_data_vector(model; titlefont = 9, quantities = default_quantities)
    data_vector = Bit.DataVector(model)
    Te = length(data_vector.vector[1].wages)

    ps = []

    for q in quantities
        # define title via the table only if the entry exists
        title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
        if q == :gdp_deflator
            push!(
                ps, errorline(
                    1:Te, data_vector.nominal_gdp ./ data_vector.real_gdp,
                    errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false
                )
            )
        else
            push!(
                ps, errorline(
                    1:Te, getproperty(data_vector, q),
                    errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false
                )
            )
        end
    end
    return ps
end

# plot multiple data vectors, one line for each vector
function Bit.plot_data_vectors(model_vector; titlefont = 9, quantities = default_quantities)

    data_vectors = Bit.DataVector.(model_vector)
    Te = length(data_vectors[1].vector[1].wages)

    ps = []

    for q in quantities
        # define title via the table only if the entry exists
        title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
        if q == :gdp_deflator
            dv = data_vectors[1]
            p = errorline(
                1:Te, dv.nominal_gdp ./ dv.real_gdp,
                errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false
            )
            for dv in data_vectors[2:end]
                errorline!(
                    1:Te, dv.nominal_gdp ./ dv.real_gdp,
                    errorstyle = :ribbon, titlefont = titlefont, legend = false
                )
            end
            push!(ps, p)
        else
            dv = data_vectors[1]
            p = errorline(
                1:Te, getproperty(dv, q),
                errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false
            )
            for dv in data_vectors[2:end]
                errorline!(
                    1:Te, getproperty(dv, q),
                    errorstyle = :ribbon, titlefont = titlefont, legend = false
                )
            end
            push!(ps, p)
        end
    end
    return ps
end

function Bit.plot_data(model; titlefont = 9, quantities = default_quantities)
    data = model.data
    ps = []
    for q in quantities
        title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
        if q == :gdp_deflator
            push!(
                ps, plot(
                    data.nominal_gdp ./ data.real_gdp,
                    title = title, titlefont = titlefont, legend = false
                )
            )
        else
            push!(
                ps, plot(
                    getproperty(data, q),
                    title = title, titlefont = titlefont, legend = false
                )
            )
        end
    end
    return ps
end


function Bit.plot_model_vs_real(model, real, varname; crop = true)
    num_ticks = []
    year_ticks = []
    for r in real["years_num"]
        # get year of r
        y = year(Bit.num2date(r))
        # save year only if it's new
        if !(y in year_ticks)
            push!(num_ticks, r)
            push!(year_ticks, y)
        end
    end

    if length(varname) > 9
        if varname[(end - 8):end] == "quarterly"
            x_nums = "quarters_num"
            title = varname[1:(end - 10)]
        else
            x_nums = "years_num"
            title = varname
        end
    else
        x_nums = "years_num"
        title = varname
    end

    if crop
        min_x = minimum(model[x_nums])
        max_x = maximum(model[x_nums])
        xlimits = (min_x, max_x)
        min_y = minimum(real[varname][min_x .<= real[x_nums] .<= max_x])
        max_y = maximum(real[varname][min_x .<= real[x_nums] .<= max_x])
        min_y = minimum((min_y, minimum(model[varname])))
        max_y = maximum((max_y, maximum(model[varname])))
        ylimits = (min_y, max_y) .* 1.0e6
    else
        ylimits = :auto
        xlimits = :auto
    end

    if crop
        all_tick_numbers = model[x_nums]
    else
        all_tick_numbers = real[x_nums]
    end

    num_ticks = []
    year_ticks = []
    for r in all_tick_numbers
        # get year of r
        y = year(Bit.num2date(r))
        # save year only if it's new
        if !(y in year_ticks)
            push!(num_ticks, r)
            push!(year_ticks, y)
        end
    end

    p = plot(
        real[x_nums], 1.0e6 * real[varname], label = "real", title = title,
        titlefontsize = 9, xlimits = xlimits, ylimits = ylimits, xticks = (num_ticks, year_ticks),
        xrotation = 20, tickfontsize = 7,
    )
    StatsPlots.errorline!(model[x_nums], 1.0e6 * model[varname], errorstyle = :ribbon, label = "model", errortype = :std)
    return p
end

end
