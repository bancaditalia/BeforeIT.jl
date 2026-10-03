# # A banking sector with multiple banks

# By default the financial sector is made of a single bank, as in the original model.
# Here we show how to split it into several banks and how to inspect each of them.

import BeforeIT as Bit
using Plots

# We load the standard parameters and initial conditions, and we copy the parameters
# to avoid modifying the shared preset
parameters = copy(Bit.AUSTRIA2010Q1.parameters)
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions

# The number of banks is set through the parameter `n_banks`.
# Each firm and household is randomly assigned to one of the banks,
# and the aggregate equity of the banking sector is split equally among them.
parameters["n_banks"] = 3

model = Bit.Model(parameters, initial_conditions);

# The `banks` object now stores one entry per bank, for example the equity of each bank
model.banks.E_k

# and the firms that are customers of each bank
length.(model.banks.firms)

# We run the model as usual
T = 20
Bit.run!(model, T);

# Aggregate variables are tracked as usual, while some variables are also tracked for
# each bank, i.e. `equity_per_bank`, `credit_stock_per_bank`, `credit_new_per_bank`,
# `reserves_per_bank` and `roe_per_bank`. We stack them into a matrix to plot one line per bank
equity = reduce(hcat, model.data.equity_per_bank)'
credit = reduce(hcat, model.data.credit_stock_per_bank)'
p1 = plot(equity, title = "equity", titlefont = 10, label = ["bank 1" "bank 2" "bank 3"])
p2 = plot(credit, title = "loans", titlefont = 10, legend = false)
plot(p1, p2, layout = (1, 2))
