
function plot_model_vs_real(model, real, varname; crop = true)
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
        ylimits = (min_y, max_y) .* 1e6
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
        real[x_nums],
        1e6 * real[varname],
        label = "real",
        title = title,
        titlefontsize = 9,
        xlimits = xlimits,
        ylimits = ylimits,
        xticks = (num_ticks, year_ticks),
        xrotation = 20,
        tickfontsize = 7,
    )
    StatsPlots.errorline!(model[x_nums], 1e6 * model[varname], errorstyle = :ribbon, label = "model", errortype = :std)
    return p
end

