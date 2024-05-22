"""
    run_one_sim!(model; shock = NoShock())

Run a single simulation based on the provided `model`. 
The simulation runs for a number of epochs specified by `model.prop.T`.

# Arguments
- `model::Model`: The model configuration used for the simulation.

# Returns
- `data::Data`: The data collected during the simulation.

# Details
The function initializes the data using `BeforeIT.initialise_data(model)`, then iteratively updates the model and data
for each epoch using `BeforeIT.one_epoch!(model)` and `BeforeIT.update_data!(data, model)` respectively.

# Example
```julia
model = BeforeIT.initialize_model(parameters, initial_conditions, T)
data = run_one_sim!(model)
"""
function run_one_sim!(model; multi_threading = false, shock = NoShock())

    data = BeforeIT.initialise_data(model)

    T = model.prop.T

    for _ in 1:T
        BeforeIT.one_epoch!(model; multi_threading = multi_threading, shock = shock)
        BeforeIT.update_data!(data, model)
    end

    return data
end



"""
    run_n_sims(model, n_sims; shock = NoShock())

A function that runs `n_sims` simulations in parallel with multiple threading and returns a vector of 
data objects of dimension `n_sims`.

# Arguments
- `model`: The model configuration used to simulate.
- `n_sims`: The number of simulations to run in parallel.

# Returns
- `data_vector`: A vector containing the data objects collected during each simulation.
"""
function run_n_sims(model, n_sims; shock = NoShock())

    data_vector = Vector{BeforeIT.Data}(undef, n_sims)

    Threads.@threads for i in 1:n_sims
        model_i = deepcopy(model)
        data = run_one_sim!(model_i; shock = shock)
        data_vector[i] = data
    end
    return data_vector
end
