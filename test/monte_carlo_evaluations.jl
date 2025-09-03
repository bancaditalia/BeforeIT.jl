import BeforeIT as Bit

using JLD2, Test

dir = @__DIR__

parameters = load(joinpath(dir, "../data/austria/parameters/2010Q1.jld2"))
initial_conditions = load(joinpath(dir, "../data/austria/initial_conditions/2010Q1.jld2"))

model = Bit.Model(parameters, initial_conditions)

T = 20
n_sims = 3
model_vector = Bit.ensemblerun!((deepcopy(model) for _ in 1:n_sims), T)
data_vector = Bit.DataVector(model_vector)

@test length(data_vector) == n_sims
@test typeof(data_vector) == Vector{Bit.Data}
@test typeof(data_vector[1]) == Bit.Data
@test typeof(data_vector[1].gdp_deflator_growth_ea) == Vector{Float64}
@test typeof(data_vector[1].gdp_deflator_growth_ea[1]) == Float64
@test length(data_vector[1].gdp_deflator_growth_ea) == T
