"""
    run!(model, T; shock = NoShock(), parallel = false)

Run a single simulation based on the provided `model`. 
The simulation runs for a number of steps T.

# Arguments
- `model::AbstractModel`: The model configuration used for the simulation.
- `T`: the number of steps to perform.

# Returns
- `model::AbstractModel`: The model updated during the simulation.

# Details
The function iteratively updates the model and data for each step using `Bit.step!(model)`.

# Example
```julia
parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
model = Bit.Model(parameters, initial_conditions)
run!(model, 2)
```
"""
function run!(model::AbstractModel, T; parallel = false, shock = NoShock())
    for _ in 1:T
        Bit.step!(model; parallel = parallel, shock = shock)
        Bit.update_data!(model)
    end
    return model
end

"""
    ensemblerun(model, T, n_sims; shock = NoShock(), parallel = true)

A function that runs `n_sims` simulations in parallel with multiple threading and returns a vector of 
models of dimension `n_sims`.

# Arguments
- `model`: The model configuration used to simulate.
- `T`: the number of steps to perform.
- `n_sims`: The number of simulations to run.

# Returns
- `model_vector`: A vector containing the `n_sims` models simulated.

Note that the input model is not updated.
"""
function ensemblerun(model::M, T, n_sims; parallel = true, shock = NoShock()) where {M}
    model_vector = Vector{M}(undef, n_sims)
    @maybe_threads parallel for i in 1:n_sims
        model_i = deepcopy(model)
        run!(model_i, T; shock, parallel)
        model_vector[i] = model_i
    end
    return model_vector
end
