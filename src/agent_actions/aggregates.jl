
function gross_domestic_product(model::AbstractModel)
	firms, agg, prop = model.firms, model.agg, model.prop
	return sum(firms.Y_i)
end
function set_gross_domestic_product!(model::AbstractModel)
	agg, prop = model.agg, model.prop
	push!(agg.Y, 0.0)
    agg.Y[prop.T_prime + agg.t] = gross_domestic_product(model)
end

set_time!(model) = (model.agg.t += 1)