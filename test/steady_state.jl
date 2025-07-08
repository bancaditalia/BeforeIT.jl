
import BeforeIT as Bit

parameters = Bit.STEADY_STATE2010Q1.parameters
initial_conditions = Bit.STEADY_STATE2010Q1.initial_conditions

model = Bit.Model(parameters, initial_conditions)

T = 5
for t in 1:T
    Bit.step!(model; multi_threading = false)
end

# check that all variables in the "data" struct are constant up to numerical precision
data = model.data
for field in fieldnames(typeof(data))
    fielddata = getfield(data, field)

    sector_variables = [:real_sector_gva, :noninal_sector_gva_ea, :nominal_sector_gva, :real]

    if field ∉ sector_variables
        zero = sum(abs.(fielddata .- mean(fielddata)))
        @assert isapprox(zero, 0.0, atol = 1e-7)
    else
        zero = sum(abs.(fielddata .- mean(fielddata, dims = 1)))
        @assert isapprox(zero, 0.0, atol = 1e-6)
    end
end
