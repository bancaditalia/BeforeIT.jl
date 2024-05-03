using BeforeIT
using MAT, FileIO, Plots, StatsPlots
using Dates

# load data from 1996

real_data = BeforeIT.ITALY_CALIBRATION.data

# load predictions from 2010Q1

model = load("data/italy/abm_predictions/2015Q1.jld2")["model_dict"]

function plot_model_vs_real(model, real, varname; crop = true)

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
        y = year(BeforeIT.num2date(r))
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


num_ticks = []
year_ticks = []
for r in real_data["years_num"]
    # get year of r
    y = year(BeforeIT.num2date(r))
    # save year only if it's new
    if !(y in year_ticks)
        push!(num_ticks, r)
        push!(year_ticks, y)
    end
end

# plot real gdp
plot_model_vs_real(model, real_data, "real_gdp")

# plot real household consumption
plot_model_vs_real(model, real_data, "real_household_consumption")

# plot real fixed capital formation
plot_model_vs_real(model, real_data, "real_fixed_capitalformation")

# plot real government consumption
plot_model_vs_real(model, real_data, "real_government_consumption")

# plot real exports
plot_model_vs_real(model, real_data, "real_exports")

# plot real imports
plot_model_vs_real(model, real_data, "real_imports")

### quarterly plots ###

# plot real gdp quarterly
p1 = plot_model_vs_real(model, real_data, "real_gdp_quarterly")

# plot real household consumption quarterly
p2 = plot_model_vs_real(model, real_data, "real_household_consumption_quarterly")

# plot real fixed capital formation quarterly
p3 = plot_model_vs_real(model, real_data, "real_fixed_capitalformation_quarterly")

# plot real government consumption quarterly
p4 = plot_model_vs_real(model, real_data, "real_government_consumption_quarterly")

# plot real exports quarterly
p5 = plot_model_vs_real(model, real_data, "real_exports_quarterly")

# plot real imports quarterly
p6 = plot_model_vs_real(model, real_data, "real_imports_quarterly")

plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), legend = false)


# translate the above from Matlab to Julia
