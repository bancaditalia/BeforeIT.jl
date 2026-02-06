
using Revise

import BeforeIT as Bit
using Mooncake, DifferentiationInterface

function step_and_reduce!(model_arr, start_model)
    new_model = Bit.array_to_model(model_arr, start_model)
    Bit.step!(new_model)
    return new_model.cb.r_bar
end

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions)

backend = AutoMooncake()
f = model_arr -> step_and_reduce!(model_arr, model)

@time g = gradient(f, backend, Bit.model_to_array(model))