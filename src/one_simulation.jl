"""
    run!(model, T; shock = NoShock(), parallel = false)

Run a single simulation based on the provided `model`. 
The simulation runs for a number of steps `T`.

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
Bit.run!(model, 2)
```
"""
function run!(model::AbstractModel, T=1; parallel = false, shock = NoShock())
    for _ in 1:T
        Bit.step!(model; parallel = parallel, shock = shock)
        Bit.collect_data!(model)
    end
    return model
end

"""
    ensemblerun!(models, T=1; shock = NoShock(), parallel = true)

A function that runs the models simulations for `T` steps on each of them.

# Arguments
- `models`: The models to simulate. The models can either be in a `Vector` or
  `Generator`.

- `T`: the number of steps to perform.

# Returns
- `models`: The updated models.

# Example
```julia
parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
models = (Bit.Model(parameters, initial_conditions) for _ in 1:10)
Bit.ensemblerun!(models, 2)
```
"""
function ensemblerun!(models::Vector, T=1; parallel = true, shock = NoShock())
    @maybe_threads parallel for i in 1:length(models)
        run!(models[i], T; shock, parallel)
    end
    return models
end
function ensemblerun!(models::Base.Generator, T=1; parallel = true, shock = NoShock())
    if models.iter == AbstractRange
        f, iter = models.f, models.iter
        models = Vector{Base.@default_eltype(models)}(undef, length(models))
        @maybe_threads parallel for i in 1:length(models)
            model = f(iter[i])
            run!(model, T; shock, parallel)
            models[i] = model
        end
        return models
    else
        return ensemblerun!(collect(models), T; parallel, shock)
    end    
end
