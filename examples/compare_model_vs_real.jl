import BeforeIT as Bit

using Plots, StatsPlots, Dates

# load data from 1996
real_data = Bit.ITALY_CALIBRATION.data

# load predictions from 2010Q1
model = load("data/italy/abm_predictions/2015Q1.jld2")["model_dict"]

# Plot real gdp
Bit.plot_model_vs_real(model, real_data, "real_gdp")

# Plot real household consumption
Bit.plot_model_vs_real(model, real_data, "real_household_consumption")

# Plot real fixed capital formation
Bit.plot_model_vs_real(model, real_data, "real_fixed_capitalformation")

# Plot real government consumption
Bit.plot_model_vs_real(model, real_data, "real_government_consumption")

# Plot real exports
Bit.plot_model_vs_real(model, real_data, "real_exports")

# Plot real imports
Bit.plot_model_vs_real(model, real_data, "real_imports")

### Quarterly Plots ###

# Plot real gdp quarterly
p1 = Bit.plot_model_vs_real(model, real_data, "real_gdp_quarterly")

# Plot real household consumption quarterly
p2 = Bit.plot_model_vs_real(model, real_data, "real_household_consumption_quarterly")

# Plot real fixed capital formation quarterly
p3 = Bit.plot_model_vs_real(model, real_data, "real_fixed_capitalformation_quarterly")

# Plot real government consumption quarterly
p4 = Bit.plot_model_vs_real(model, real_data, "real_government_consumption_quarterly")

# Plot real exports quarterly
p5 = Bit.plot_model_vs_real(model, real_data, "real_exports_quarterly")

# Plot real imports quarterly
p6 = Bit.plot_model_vs_real(model, real_data, "real_imports_quarterly")

plot(p1, p2, p3, p4, p5, p6, layout = (3, 2), legend = false)

# translate the above from Matlab to Julia
