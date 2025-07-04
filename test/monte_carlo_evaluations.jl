
import BeforeIT as Bit

using MAT, FileIO, Test

dir = @__DIR__

parameters = matread(joinpath(dir, "../data/austria/parameters/2010Q1.mat"))
initial_conditions = matread(joinpath(dir, "../data/austria/initial_conditions/2010Q1.mat"))

model = Bit.Model(parameters, initial_conditions)
data = Bit.Data(model)

T = 20
n_sims = 3
data_vector = Bit.ensemblerun(model, T, n_sims)

@test length(data_vector) == n_sims
@test typeof(data_vector) == Vector{Bit.Data}
@test typeof(data_vector[1]) == Bit.Data
@test typeof(data_vector[1].gdp_deflator_growth_ea) == Vector{Float64}
@test typeof(data_vector[1].gdp_deflator_growth_ea[1]) == Float64
@test length(data_vector[1].gdp_deflator_growth_ea) == T
