import BeforeIT as Bit

using Random, Plots

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

model = Bit.Model(parameters, initial_conditions)

T = 20
for t in 1:T
    println("Step: ", t)
    Bit.step!(model; parallel = true)
    Bit.collect_data!(model)
end

data = model.data

p1 = plot(data.real_gdp, title = "gdp", titlefont = 10)
p2 = plot(data.real_household_consumption, title = "household cons.", titlefont = 10)
p3 = plot(data.real_government_consumption, title = "gov. cons.", titlefont = 10)
p4 = plot(data.real_capitalformation, title = "capital form.", titlefont = 10)
p5 = plot(data.real_exports, title = "exports", titlefont = 10)
p6 = plot(data.real_imports, title = "imports", titlefont = 10)
p7 = plot(data.wages, title = "wages", titlefont = 10)
p8 = plot(data.euribor, title = "euribor", titlefont = 10)
p9 = plot(data.nominal_gdp ./ data.real_gdp, title = "gdp deflator", titlefont = 10)

plot(p1, p2, p3, p4, p5, p6, p7, p8, p9, layout = (3, 3), legend = false)
