# # Basic example — multibank / new-branch parameter sweep
#
# Same simulation and charts as `basic_example.jl`, but with the parameters
# introduced on the `multibank-paper` branch exposed at the top so you can
# compare a run against the pre-multibank baseline.
#
# Baseline (reproduces the original pre-multibank `basic_example` behaviour):
#     n_banks = 1, omega = 0.0, overdrafts_in_capital_ratio = false
#
# Note: this is a STANDARD `Bit.Model` run (like `basic_example.jl`), so the
# Calvo parameter `theta_calvo` is INERT here — it only bites in CANVAS runs
# (`ModelCANVAS`). It is exposed below for completeness only.

import BeforeIT as Bit
using Plots, StatsPlots

# ---------------------------------------------------------------------------
# PARAMETERS TO VARY  (edit these to explore the new-branch behaviour)
# ---------------------------------------------------------------------------

# (#1) Number of banks. 1 = original single-bank behaviour.
n_banks = 1

# (#4) EMA smoothing of expected inflation:
#   pi_e := (1 - omega) * pi_e + omega * last_realised_inflation
#   0.0 = pure model expectations = ORIGINAL behaviour
#   1.0 = expectation replaced entirely by last realised inflation
# NB: this `omega` is a model parameter and is unrelated to the firm-level
#     `initial_conditions["omega"]` used to scale capital/materials.
omega = 0.0

# (#5) Include drawn overdrafts in the credit-supply / leverage ratio.
#   false = ORIGINAL behaviour
overdrafts_in_capital_ratio = false

# (#2) Calvo price stickiness: fraction of firms that re-adjust prices each
#      step. ONLY AFFECTS CANVAS runs (ModelCANVAS) — inert in this script.
#      For CANVAS: 1.0 = all firms adjust (original), lower = stickier prices.
theta_calvo = 1.0

# (#3) Credit-supply computation bug fix has no parameter — it is always on.
# ---------------------------------------------------------------------------

T = 16

# Copy so we don't mutate the shared AUSTRIA2010Q1 preset.
parameters = copy(Bit.AUSTRIA2010Q1.parameters)
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

parameters["n_banks"] = n_banks
parameters["omega"] = omega
parameters["overdrafts_in_capital_ratio"] = overdrafts_in_capital_ratio
parameters["theta_calvo"] = theta_calvo

# Initialise the model
model = Bit.Model(parameters, initial_conditions)

println("Running with:")
println("  n_banks                     = ", model.prop.n_banks)
println("  omega (EMA)                 = ", model.prop.omega)
println("  overdrafts_in_capital_ratio = ", model.prop.overdrafts_in_capital_ratio)
println("  theta_calvo (CANVAS-only)   = ", model.prop.theta_calvo)

# Run the model for T epochs
for _ in 1:T
    Bit.step!(model; parallel = true)
    Bit.collect_data!(model)
end

# Single-run GDP
plot(model.data.real_gdp, title = "gdp", titlefont = 10)

# Multiple time series at once
ps = Bit.plot_data(model, quantities = [:real_gdp, :real_household_consumption, :real_government_consumption, :real_capitalformation, :real_exports, :real_imports, :wages, :euribor, :gdp_deflator])
plot(ps..., layout = (3, 3))

# Monte-Carlo repetitions in parallel
models = (Bit.Model(parameters, initial_conditions) for _ in 1:2)
models = Bit.ensemblerun!(models, T)
ps = Bit.plot_data_vector(models)
plot(ps..., layout = (3, 3))
