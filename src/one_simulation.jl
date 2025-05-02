"""
    run!(model; shock = NoShock())

Run a single simulation based on the provided `model`. 
The simulation runs for a number of epochs specified by `model.prop.T`.

# Arguments
- `model::Model`: The model configuration used for the simulation.

# Returns
- `data::Data`: The data collected during the simulation.

# Details
The function initializes the data using `Bit.init_data(model)`, then iteratively updates the model and data
for each epoch using `Bit.step!(model)` and `Bit.update_data!(data, model)` respectively.

# Example
```julia
model = Bit.init_model(parameters, initial_conditions, T)
data = run!(model)
"""
function run!(model::AbstractModel; multi_threading = false, shock = NoShock())

    data = Bit.init_data(model)

    T = model.prop.T

    for _ in 1:T
        Bit.step!(model; multi_threading = multi_threading, shock = shock)
        Bit.update_data!(data, model)
    end

    return data
end



"""
    ensemblerun(model, n_sims; shock = NoShock(), multi_threading = true)

A function that runs `n_sims` simulations in parallel with multiple threading and returns a vector of 
data objects of dimension `n_sims`.

# Arguments
- `model`: The model configuration used to simulate.
- `n_sims`: The number of simulations to run in parallel.

# Returns
- `data_vector`: A vector containing the data objects collected during each simulation.
"""
function ensemblerun(model::AbstractModel, n_sims; multi_threading = true, shock = NoShock())

    data_vector = Vector{Bit.Data}(undef, n_sims)

    if multi_threading
        Threads.@threads for i in 1:n_sims
            model_i = deepcopy(model)
            data = run!(model_i; shock = shock)
            data_vector[i] = data
        end
    else
        for i in 1:n_sims
            model_i = deepcopy(model)
            data = run!(model_i; shock = shock)
            data_vector[i] = data
        end
    end

    # transform the vector of data objects into a DataVector
    data_vector = Bit.DataVector(data_vector)

    return data_vector
end
