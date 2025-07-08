
"""
	derivative(model, property, T=1)

Computes the derivative of stepping the model
with respect to a variable of the model. If the
variable is an array, the derivative of the model
will be computed with respect to an infinitesimal
variation of each of the components of the array. 

# Example
```julia
parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions)
model = Bit.derivative(model, :(prop.tau_FIRM))
sum(model.firms.C_d_h)
```
"""
function derivative(model, property, T=1)
	object = property.args[1]
	field = Symbol(string(property.args[2])[2:end])
	s = getfield(model, object)
	p = getfield(s, field)
	if p isa AbstractArray
		p .+= ε
	else
		setfield!(s, field, p + ε)
	end
	for _ in 1:T
		step!(model)
	end
	return model
end

value(x::Union{Dual128, Dual64}) = DualNumbers.realpart(x)
