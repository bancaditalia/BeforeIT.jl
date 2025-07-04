# # Changing expectations via function overloading

# In this tutorial we will illustrate how to experiment with
# different expectations of the agents in the model.

import BeforeIT as Bit

using Random, Plots

# Import standard parameters and initial conditions

par = Bit.AUSTRIA2010Q1.parameters
init = Bit.AUSTRIA2010Q1.initial_conditions

# Set the seed, initialise the model and run one simulation

Random.seed!(1234)
model = Bit.Model(par, init);
Bit.run!(model, 40);

# Now we can experiment with changing expectations of the agents in the model.
# We will change the function `estimate_next_value` to make the agents expect 
# the last value of the time series (so to represent backward looking expectations)

function Bit.estimate_next_value(data)
    return data[end]
end

# Run the model again, with the same seed

Random.seed!(1234)
model2 = Bit.Model(par, init);
Bit.run!(model, 40);

# Plot the results, comparing the two cases as different lines

p1 = plot(model.data.real_gdp, title = "gdp", titlefont = 10, label = "forward looking")
plot!(p1, data_back.real_gdp, titlefont = 10, label = "backward looking")

p2 = plot(model.data.real_household_consumption, title = "consumption", titlefont = 10)
plot!(p2, data_back.real_household_consumption, titlefont = 10, label = "backward looking")

plot(p1, p2, layout = (2, 1), legend = true)

# Plot all time series

p1 = plot(model.data.real_gdp, title = "gdp", titlefont = 10)
plot!(p1, model2.data.real_gdp, titlefont = 10)
p2 = plot(model.data.real_household_consumption, title = "household cons.", titlefont = 10)
plot!(p2, model2.data.real_household_consumption, titlefont = 10)
p3 = plot(model.data.real_government_consumption, title = "gov. cons.", titlefont = 10)
plot!(p3, model2.data.real_government_consumption, titlefont = 10)
p4 = plot(model.data.real_capitalformation, title = "capital form.", titlefont = 10)
plot!(p4, model2.data.real_capitalformation, titlefont = 10)
p5 = plot(model.data.real_exports, title = "exports", titlefont = 10)
plot!(p5, model2.data.real_exports, titlefont = 10)
p6 = plot(model.data.real_imports, title = "imports", titlefont = 10)
plot!(p6, model2.data.real_imports, titlefont = 10)
p7 = plot(model.data.wages, title = "wages", titlefont = 10)
plot!(p7, model2.data.wages, titlefont = 10)
p8 = plot(model.data.euribor, title = "euribor", titlefont = 10)
plot!(p8, model2.data.euribor, titlefont = 10)
p9 = plot(model.data.nominal_gdp ./ model.data.real_gdp, title = "gdp deflator", titlefont = 10)
plot!(p9, model2.data.nominal_gdp ./ model2.data.real_gdp, titlefont = 10)

plot(p1, p2, p3, p4, p5, p6, p7, p8, p9, layout = (3, 3), legend = false)

# Note that, importantly, once the function `estimate_next_value` has been changed,
# the model will use the new expectations in all the simulations, unless the function
# is changed again. To restore the original expectations you could close the Julia session.
