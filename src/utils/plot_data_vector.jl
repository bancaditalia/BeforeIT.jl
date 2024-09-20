using Plots, StatsPlots

"""
	plot_data_vector function

	data_vector = run_n_sims(model, n = 8)
	plots = plot_data_vector(data_vector)
	Plots.plot(plots...)



"""
function plot_data_vector(data)

	data_vector = data[1]

	Te = length(data_vector.wages)
 
	p1 = errorline(1:Te, data_vector.real_gdp, errorstyle = :ribbon, title = "gdp", titlefont = 10)
	p2 = errorline(
	    1:Te,
	    data_vector.real_household_consumption,
	    errorstyle = :ribbon,
	    title = "household cons.",
	    titlefont = 10,
	)
	p3 =
	    errorline(1:Te, data_vector.real_government_consumption, errorstyle = :ribbon, title = "gov. cons.", titlefont = 10)
	p4 = errorline(1:Te, data_vector.real_capitalformation, errorstyle = :ribbon, title = "capital form.", titlefont = 10)
	p5 = errorline(1:Te, data_vector.real_exports, errorstyle = :ribbon, title = "exports", titlefont = 10)
	p6 = errorline(1:Te, data_vector.real_imports, errorstyle = :ribbon, title = "imports", titlefont = 10)
	p7 = errorline(1:Te, data_vector.wages, errorstyle = :ribbon, title = "wages", titlefont = 10)
	p8 = errorline(1:Te, data_vector.euribor, errorstyle = :ribbon, title = "euribor", titlefont = 10)
	p9 = errorline(
	    1:Te,
	    data_vector.nominal_gdp ./ data.real_gdp,
	    errorstyle = :ribbon,
	    title = "gdp deflator",
	    titlefont = 10,
	)
	return p1, p2, p3, p4, p5, p6, p7, p8, p9

end
