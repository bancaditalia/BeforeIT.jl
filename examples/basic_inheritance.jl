# # Essential extension of BeforeIT using macros and multiple dispatch

# # # Extension by Specialization

import BeforeIT as Bit
using Plots

# When extending the BeforeIT model it is required to first create a new model
# type to use instead of the default model, we can do so by using
Bit.@object struct NewModel(Bit.Model) <: Bit.AbstractModel end

# In BeforeIT, new objects can be created to add new behaviours. For instance, 
# we can define a new central bank object with one extra attribute:
Bit.@object mutable struct NewCentralBank(Bit.CentralBank) <: Bit.AbstractCentralBank
    fixed_rate::Float64
end

# and then change the default central bank behaviour for the new type
function Bit.central_bank_rate(cb::NewCentralBank, model::Bit.AbstractModel)
    return cb.fixed_rate
end

p, ic = Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions

# Now, we can reinitialize the model to include the new type, to do so, we will need
# to reinitialize all agent types first
firms          = Bit.Firms(p, ic)
w_act, w_inact = Bit.Workers(p, ic)
bank           = Bit.Bank(p, ic)
government     = Bit.Government(p, ic)
rotw           = Bit.RestOfTheWorld(p, ic)
agg            = Bit.Aggregates(p, ic)
properties     = Bit.Properties(p, ic)
data           = Bit.Data()

# We initialise the default central bank
cb = Bit.CentralBank(p, ic)

# And then initialize a new central bank with the same fields as the original one,
# and the fixed interest rate
new_cb = NewCentralBank(Bit.fields(cb)..., 0.02)

standard_model = Bit.Model((w_act, w_inact, firms, bank, cb, government, rotw, agg, properties, data))
new_model = NewModel((w_act, w_inact, firms, bank, new_cb, government, rotw, agg, properties, data))

# Then, we simulate both models
T = 20
model_vec_standard = Bit.ensemblerun(standard_model, T, 4);
model_vec_new = Bit.ensemblerun(new_model, T, 4);

# And plot the results
using Plots, StatsPlots
ps = Bit.plot_data_vectors([model_vec_standard, model_vec_new], quantities = [:euribor, :gdp_deflator])
plot(ps..., layout = (1, 2), size = (600, 300))

# # # Extension by Specialization & Invocation

# First, we create as before a new model type
Bit.@object struct NewModel2(Bit.Model) <: Bit.AbstractModel end

# Now, let's say that differently from before, one wants to track the number of employees in
# the economy, something not included by default when running a simulation. To do so, we create
# a new data type with
Bit.@object mutable struct MoreData(Bit.Data) <: Bit.AbstractData
    N_employed::Vector{Int} = Int[]
end

# We then need to specialize the function `Bit.update_data!`, and, at the same time,
# invoke the default tracking because we don't want to lose the information on the other
# variables
function Bit.update_data!(m::NewModel2)
    @invoke Bit.update_data!(m::Bit.AbstractModel)
    push!(m.data.N_employed, sum(m.firms.N_i))
end

# We then initialize the model as usual
firms          = Bit.Firms(p, ic)
w_act, w_inact = Bit.Workers(p, ic)
cb             = Bit.CentralBank(p, ic)
bank           = Bit.Bank(p, ic)
government     = Bit.Government(p, ic)
rotw           = Bit.RestOfTheWorld(p, ic)
agg            = Bit.Aggregates(p, ic)
properties     = Bit.Properties(p, ic)
mdata          = MoreData()

new_model = NewModel2((w_act, w_inact, firms, bank, cb, government, rotw, agg, properties, mdata))

# and we run the simulation
Bit.run!(new_model, T);

# Finally we plot the new data
plot(new_model.data.N_employed, label="Employed Workers")