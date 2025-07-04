
"""
    run!(model, T; shock = NoShock())

Run a single simulation based on the provided `model`. 
The simulation runs for a number of epochs specified by `model.prop.T`.

# Arguments
- `model::AbstractModel`: The model configuration used for the simulation.
- `T`: the number of steps to perform.

# Returns
- `model::AbstractModel`: The model updated during the simulation.

# Details
The function initializes the data using `Bit.Data(model)`, then iteratively updates the model and data
for each epoch using `Bit.step!(model)` and `Bit.update_data!(data, model)` respectively.

# Example
```julia
model = Bit.Model(parameters, initial_conditions)
```
"""
function run!(model::AbstractModel, T; multi_threading = false, shock = NoShock())

    model.agg.t == 1 && update_data_init!(model)
    for _ in 1:T
        Bit.step!(model; multi_threading = multi_threading, shock = shock)
    end

    return model
end

"""
    ensemblerun(model, T, n_sims; shock = NoShock(), multi_threading = true)

A function that runs `n_sims` simulations in parallel with multiple threading and returns a vector of 
models of dimension `n_sims`.

# Arguments
- `model`: The model configuration used to simulate.
- `T`: the number of steps to perform.
- `n_sims`: The number of simulations to run in parallel.

# Returns
- `model_vector`: A vector containing the `n_sims` models simulated.

Note that the input model is not updated.
"""
function ensemblerun(model::AbstractModel, T, n_sims; multi_threading = true, shock = NoShock())

    model_vector = Vector{Bit.Model}(undef, n_sims)

    if multi_threading
        Threads.@threads for i in 1:n_sims
            model_i = deepcopy(model)
            model_i.agg.t == 1 && update_data_init!(model)
            run!(model_i, T; shock = shock)
            model_vector[i] = model_i
        end
    else
        for i in 1:n_sims
            model_i = deepcopy(model)
            model_i.agg.t == 1 && update_data_init!(model)
            run!(model_i, T; shock = shock)
            model_vector[i] = model_i
        end
    end

    return model_vector
end
