using Plots, StatsPlots

const default_quantities = [:real_gdp, :real_household_consumption, :real_government_consumption, :real_capitalformation, :real_exports, :real_imports, :wages, :euribor, :gdp_deflator]

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

function plot_data_vector(data_vector::DataVector; titlefont = 9, quantities = default_quantities)	
	Te = length(data_vector.vector[1].wages)
	
	ps = []

	for q in quantities
		# define title via the table only if the entry exists
		title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
		if q == :gdp_deflator
			push!(ps, errorline(1:Te, data_vector.nominal_gdp ./ data_vector.real_gdp, errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false))
		else
			push!(ps, errorline(1:Te, getproperty(data_vector, q), errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false))
		end
	end
	return ps
end

# plot multiple data vectors, one line for each vector
function plot_data_vectors(data_vectors; titlefont = 9, quantities = Bit.default_quantities)
	Te = length(data_vectors[1].vector[1].wages)
	
	ps = []

	for q in quantities
		# define title via the table only if the entry exists
		title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
		if q == :gdp_deflator
            dv = data_vectors[1]
            p = errorline(1:Te, dv.nominal_gdp ./ dv.real_gdp, errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false);
            for dv in data_vectors[2:end]
                errorline!(1:Te, dv.nominal_gdp ./ dv.real_gdp, errorstyle = :ribbon, titlefont = titlefont, legend = false);
            end
			push!(ps, p)
		else
            dv = data_vectors[1]
            p = errorline(1:Te, getproperty(dv, q), errorstyle = :ribbon, title = title, titlefont = titlefont, legend = false);
            for dv in data_vectors[2:end]  
                errorline!(1:Te, getproperty(dv, q), errorstyle = :ribbon, titlefont = titlefont, legend = false);
            end
    		push!(ps, p)
		end
	end
	return ps
end


function plot_data(data::Data; titlefont = 9, quantities = default_quantities)
	ps = []
	for q in quantities
		title = haskey(quantity_titles, q) ? quantity_titles[q] : string(q)
		if q == :gdp_deflator
			push!(ps, plot(data.nominal_gdp ./ data.real_gdp, title = title, titlefont = titlefont, legend = false))
		else
			push!(ps, plot(getproperty(data, q), title = title, titlefont = titlefont, legend = false))
		end
	end
	return ps
end

