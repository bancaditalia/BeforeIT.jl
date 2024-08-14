using BeforeIT


parameters = BeforeIT.STEADY_STATE2010Q1.parameters
initial_conditions = BeforeIT.STEADY_STATE2010Q1.initial_conditions

T = 5
model = BeforeIT.init_model(parameters, initial_conditions, T)
data = BeforeIT.init_data(model)

for t in 1:T
    println(t)
    BeforeIT.one_epoch!(model; multi_threading = false)
    BeforeIT.update_data!(data, model)
end

# check that all variables in the "data" struct are constant up to numerical precision
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
