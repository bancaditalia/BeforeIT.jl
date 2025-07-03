# # Essential extension of BeforeIT using macros and mltiple dispatch
import BeforeIT as Bit
using Plots

# define a new central bank object with one extra attribute
Bit.@object mutable struct NewCentralBank(Bit.CentralBank{Float64}) <: Bit.AbstractCentralBank
    fixed_rate::Float64
end

# change the default central bank behaviour for the new type
function Bit.central_bank_rate(cb::NewCentralBank, model::Bit.AbstractModel)
    return cb.fixed_rate
end

p, ic = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions
T = 20

# initialise all agent types using the corresponding functions
properties = Bit.Properties(p, T)
firms = Bit.Firms(p, ic)
w_act, w_inact, V_i_new = Bit.Workers(p, ic, firms)
firms.V_i .= V_i_new
bank = Bit.Bank(p, ic, firms)
government = Bit.Government(p, ic)
rotw = Bit.RestOfTheWorld(p, ic)
agg = Bit.Aggregates(p, ic, T)

# initialise the custom central bank
standard_central_bank = Bit.CentralBank(p, ic)
newcentral_bank = NewCentralBank(args..., 0.02)

# initialise a new model using the new central bank as well as a standard model
standard_model = Bit.Model(w_act, w_inact, firms, bank, standard_central_bank,
government, rotw, agg, properties)

new_model = Bit.Model(w_act, w_inact, firms, bank, newcentral_bank,
government, rotw, agg, properties)

# run a simulation with the new model
data_vec_standard = Bit.ensemblerun(standard_model, 4);
data_vec_new = Bit.ensemblerun(new_model, 4);

# plot the results
ps = Bit.plot_data_vectors([data_vec_standard, data_vec_new], quantities = [:euribor, :gdp_deflator])
plot(ps..., layout = (1, 2), size = (600, 300))
