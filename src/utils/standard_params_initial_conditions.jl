import JLD2

dir = joinpath(splitpath(dirname(pathof(@__MODULE__)))[1:(end - 1)])

parameters = JLD2.load(joinpath(dir, "data/austria/parameters/2010Q1.jld2"))
initial_conditions = JLD2.load(joinpath(dir, "data/austria/initial_conditions/2010Q1.jld2"))

const AUSTRIA2010Q1 = Properties(parameters, initial_conditions)

parameters = JLD2.load(joinpath(dir, "data/italy/parameters/2010Q1.jld2"))
initial_conditions = JLD2.load(joinpath(dir, "data/italy/initial_conditions/2010Q1.jld2"))

const ITALY2010Q1 = Properties(parameters, initial_conditions)

parameters = JLD2.load(joinpath(dir, "data/steady_state/parameters/2010Q1.jld2"))
initial_conditions = JLD2.load(joinpath(dir, "data/steady_state/initial_conditions/2010Q1.jld2"))

const STEADY_STATE2010Q1 = Properties(parameters, initial_conditions)
