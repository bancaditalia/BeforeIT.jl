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
T = 40
model = Bit.init_model(par, init, T)
data = Bit.run!(model)

# Now we can experiment with changing expectations of the agents in the model.
# We will change the function `estimate_next_value` to make the agents expect 
# the last value of the time series (so to represent backward looking expectations)

function Bit.estimate_next_value(data)
    return data[end]
end

# Run the model again, with the same seed

Random.seed!(1234)
model = Bit.init_model(par, init, T)
data_back = Bit.run!(model)

# Plot the results, comparing the two cases as different lines

p1 = plot(data.real_gdp, title = "gdp", titlefont = 10, label = "forward looking")
plot!(p1, data_back.real_gdp, titlefont = 10, label = "backward looking")

p2 = plot(data.real_household_consumption, title = "consumption", titlefont = 10)
plot!(p2, data_back.real_household_consumption, titlefont = 10, label = "backward looking")

plot(p1, p2, layout = (2, 1), legend = true)

# Plot all time series

p1 = plot(data.real_gdp, title = "gdp", titlefont = 10)
plot!(p1, data_back.real_gdp, titlefont = 10)
p2 = plot(data.real_household_consumption, title = "household cons.", titlefont = 10)
plot!(p2, data_back.real_household_consumption, titlefont = 10)
p3 = plot(data.real_government_consumption, title = "gov. cons.", titlefont = 10)
plot!(p3, data_back.real_government_consumption, titlefont = 10)
p4 = plot(data.real_capitalformation, title = "capital form.", titlefont = 10)
plot!(p4, data_back.real_capitalformation, titlefont = 10)
p5 = plot(data.real_exports, title = "exports", titlefont = 10)
plot!(p5, data_back.real_exports, titlefont = 10)
p6 = plot(data.real_imports, title = "imports", titlefont = 10)
plot!(p6, data_back.real_imports, titlefont = 10)
p7 = plot(data.wages, title = "wages", titlefont = 10)
plot!(p7, data_back.wages, titlefont = 10)
p8 = plot(data.euribor, title = "euribor", titlefont = 10)
plot!(p8, data_back.euribor, titlefont = 10)
p9 = plot(data.nominal_gdp ./ data.real_gdp, title = "gdp deflator", titlefont = 10)
plot!(p9, data_back.nominal_gdp ./ data_back.real_gdp, titlefont = 10)

plot(p1, p2, p3, p4, p5, p6, p7, p8, p9, layout = (3, 3), legend = false)

# Note that, importantly, once the function `estimate_next_value` has been changed,
# the model will use the new expectations in all the simulations, unless the function
# is changed again. To restore the original expectations you could close the Julia session.
