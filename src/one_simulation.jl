
"""
    run!(model, T; shock = NoShock(), multi_threading = false)

Run a single simulation based on the provided `model`. 
The simulation runs for a number of steps T.

# Arguments
- `model::AbstractModel`: The model configuration used for the simulation.
- `T`: the number of steps to perform.

# Returns
- `model::AbstractModel`: The model updated during the simulation.

# Details
The function iteratively updates the model and data for each step using `Bit.step!(model)`

# Example
```julia
parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions)
run!(model, 2)
```
"""
function run!(model::AbstractModel, T; multi_threading = false, shock = NoShock())
    for _ in 1:T
        Bit.step!(model; multi_threading = multi_threading, shock = shock)
        Bit.update_data!(model)
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
    Threads.@sync for i in 1:n_sims
        model_i = deepcopy(model)
        if multi_threading 
            Threads.@spawn run!(model_i, T; shock, multi_threading)
        else
            run!(model_i, T; shock)
        end
        model_vector[i] = model_i
    end
    return model_vector
end
