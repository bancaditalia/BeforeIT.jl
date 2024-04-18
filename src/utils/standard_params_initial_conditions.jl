using MAT, FileIO

struct InitialState
    parameters::Dict{String, Any}
    initial_conditions::Dict{String, Any}
end

dir = @__DIR__

parameters = matread(joinpath(dir, "parameters_initial_conditions_data/austria/parameters/2010Q1.mat"))
initial_conditions = matread(joinpath(dir, "parameters_initial_conditions_data/austria/initial_conditions/2010Q1.mat"))

const AUSTRIA2010Q1 = InitialState(parameters, initial_conditions)


parameters = load(joinpath(dir, "parameters_initial_conditions_data/italy/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "parameters_initial_conditions_data/italy/initial_conditions/2010Q1.jld2"))

const ITALY2010Q1 = InitialState(parameters, initial_conditions)


parameters = matread(joinpath(dir, "parameters_initial_conditions_data/steady_state/parameters/2010Q1.mat"))
initial_conditions =
    matread(joinpath(dir, "parameters_initial_conditions_data/steady_state/initial_conditions/2010Q1.mat"))

const STEADY_STATE2010Q1 = InitialState(parameters, initial_conditions)
