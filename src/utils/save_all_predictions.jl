function save_all_params_and_initial_conditions(
        calibration_object, folder_name; scale = 0.0005,
        first_calibration_date = DateTime(2010, 03, 31),
        last_calibration_date = DateTime(2011, 12, 31)
    )

    if isdir(folder_name)
        @warn "The folder $(folder_name) already exists and will be deleted with its content."
        rm(folder_name; force = true, recursive = true)
    end

    parameters_folder = folder_name * "/parameters/"
    initial_conditions_folder = folder_name * "/initial_conditions/"

    for calibration_date in collect(first_calibration_date:Dates.Month(3):last_calibration_date)
        params, init_conds = Bit.get_params_and_initial_conditions(calibration_object, calibration_date; scale = scale)
        save(
            parameters_folder *
                string(year(calibration_date)) *
                "Q" *
                string(Dates.quarterofyear(calibration_date)) *
                ".jld2",
            params,
        )
        save(
            initial_conditions_folder *
                string(year(calibration_date)) *
                "Q" *
                string(Dates.quarterofyear(calibration_date)) *
                ".jld2",
            init_conds,
        )
    end

    return
end

function extract_yq(files)
    return Set([match(r"^(\d{4})Q(\d)\.jld2$", f).match for f in files if occursin(r"Q", f)])
end

"""
    save_all_simulations(folder_name; T=12, n_sims=4, model_constructor=Bit.Model, simulation_folder=nothing)

Run ensemble simulations for all parameter/initial_condition pairs and save results.

# Arguments
- `folder_name`: Base folder containing data (e.g., "data/it")
- `T`: Number of quarters to simulate (default: 12)
- `n_sims`: Number of ensemble simulations (default: 4)
- `model_constructor`: Model constructor `(parameters, initial_conditions) -> Model`.
                   Pass `Bit.ModelGR` or `Bit.ModelCANVAS`; defaults to `Bit.Model` (baseline).
- `simulation_folder`: Output subdirectory under `folder_name` (default: `simulations`).
                   Pass e.g. `"simulations/canvas"` to keep variant outputs separated.
                   Input is always read from `parameters/` and `initial_conditions/`.

# Examples
```julia
# Baseline model
Bit.save_all_simulations("data/it"; T=12, n_sims=100)

# GrowthRate extension
Bit.save_all_simulations("data/it"; T=12, n_sims=100,
    model_constructor=Bit.ModelGR, simulation_folder="simulations/growth_rate")

# CANVAS extension
Bit.save_all_simulations("data/it"; T=12, n_sims=100,
    model_constructor=Bit.ModelCANVAS, simulation_folder="simulations/canvas")
```
"""
function save_all_simulations(folder_name; T = 12, n_sims = 4, model_constructor = Model, simulation_folder = nothing)
    # Always read from standard folders
    param_dir = folder_name * "/parameters/"
    init_dir = folder_name * "/initial_conditions/"

    # Output subdirectory (defaults to "simulations"); ensure it exists
    sim_dir = joinpath(folder_name, something(simulation_folder, "simulations")) * "/"
    mkpath(sim_dir)

    param_files = readdir(param_dir)
    init_files = readdir(init_dir)
    # Extract year and quarter from filenames like 2010Q1.jld2

    param_yq = extract_yq(param_files)
    init_yq = extract_yq(init_files)
    filenames = sort(collect(intersect(param_yq, init_yq)))

    # Only process year/quarter pairs present in both
    for yq in filenames
        year, quarter = yq[1:4], yq[6]
        println("Y: ", year, " Q: ", quarter)
        param_file = joinpath(param_dir, string(year, "Q", quarter, ".jld2"))
        init_file = joinpath(init_dir, string(year, "Q", quarter, ".jld2"))

        try
            parameters = load(param_file)
            initial_conditions = load(init_file)

            model = model_constructor(parameters, initial_conditions)
            model_vector = Bit.ensemblerun!((deepcopy(model) for _ in 1:n_sims), T)
            data_vector = DataVector(model_vector)
            sim_file = joinpath(sim_dir, string(year, "Q", quarter, ".jld2"))

            save(sim_file, "data_vector", data_vector)
        catch e
            e isa InterruptException && rethrow()
            @warn "Skipping $(year)Q$(quarter) due to error" exception = (e, catch_backtrace())
        end
    end
    return
end

function save_all_predictions_from_sims(folder_name, real_data; simulation_suffix = "simulations", prediction_suffix = "abm_predictions")


    # Load simulations
    sim_folder = folder_name * "/$(simulation_suffix)"

    sim_files = readdir(sim_folder)

    sim_yq = extract_yq(sim_files)
    sim_yq = sort(collect(sim_yq))

    # Ensure the output directory exists (callers should not have to pre-create it)
    mkpath(folder_name * "/$(prediction_suffix)")

    for yq in sim_yq
        y = parse(Int, yq[1:4])
        q = parse(Int, yq[6])

        if q == 4
            # last quarter special case
            start_date = DateTime(y + 1, 1, 1) - Day(1)
        else
            start_date = DateTime(y, q * 3 + 1, 1) - Day(1)
        end


        file_name = joinpath(sim_folder, string(y, "Q", q, ".jld2"))
        sims = load(file_name)["data_vector"]
        predictions_dict = get_predictions_from_sims(sims, real_data, start_date)
        # save the predictions_dict
        save(folder_name * "/$(prediction_suffix)/$(y)Q$(q).jld2", "predictions_dict", predictions_dict)
    end

    return
end
