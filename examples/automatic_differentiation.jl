using Printf

const SCRIPT_DIR = @__DIR__
const PROJECT_DIR = dirname(SCRIPT_DIR)
const SCRIPT_PATH = abspath(@__FILE__)
const EPOCHS = parse(Int, get(ENV, "BEFOREIT_AD_EPOCHS", "50"))
const RNG_SEED = 42

const PROPERTY_OPTIMIZATION_FIELDS = (
    :tau_INC,
    :tau_FIRM,
    :tau_VAT,
    :tau_SIF,
    :tau_SIW,
    :tau_EXPORT,
    :tau_CF,
    :tau_G,
    :theta_UB,
    :psi,
    :psi_H,
    :mu,
    :theta_DIV,
    :theta,
    :zeta,
    :zeta_LTV,
    :zeta_b,
)

const WORKER_ARG_INDEX = findfirst(==("--worker"), ARGS)

csv_path(kind, float_type_name) = joinpath(SCRIPT_DIR, "gdps_$(kind)_$(float_type_name).csv")

if WORKER_ARG_INDEX !== nothing
    using CSV
    using DataFrames
    using Plots
    using Preferences
    using Random

    const FLOAT_TYPE_NAME = ARGS[WORKER_ARG_INDEX + 1]
    const WORKER_METHODS =
        WORKER_ARG_INDEX + 1 < length(ARGS) ? split(ARGS[WORKER_ARG_INDEX + 2], ",") : ["automatic", "numerical"]

    FLOAT_TYPE_NAME in ("Float64", "Float128") ||
        error("Expected Float64 or Float128, got $(FLOAT_TYPE_NAME)")

    if FLOAT_TYPE_NAME == "Float128"
        using Quadmath
    end

    if "automatic" in WORKER_METHODS
        using DifferentiationInterface
        using Mooncake
    end

    set_preferences!("BeforeIT", "typeFloat" => FLOAT_TYPE_NAME; force = true)
    import BeforeIT as Bit

    const FloatType = Bit.typeFloat

    const SKIPPED_FLATTEN_FIELDS = (:del, :lastid, :id_to_index, :ID)

    function flattened_field_length(field)
        if isa(field, Number)
            return 1
        elseif isa(field, AbstractVector{<:Number}) || isa(field, AbstractMatrix{<:Number})
            return length(field)
        else
            return 0
        end
    end

    function flattened_length(obj)
        len = 0
        for fname in fieldnames(typeof(obj))
            fname in SKIPPED_FLATTEN_FIELDS && continue
            len += flattened_field_length(getfield(obj, fname))
        end
        return len
    end

    function flattened_field_indices(obj, fields; offset = 0)
        index_by_field = Dict{Symbol, UnitRange{Int}}()
        pos = offset + 1

        for fname in fieldnames(typeof(obj))
            fname in SKIPPED_FLATTEN_FIELDS && continue

            field = getfield(obj, fname)
            len = flattened_field_length(field)
            if len > 0
                if fname in fields
                    index_by_field[fname] = pos:(pos + len - 1)
                end
                pos += len
            end
        end

        missing_fields = setdiff(collect(fields), collect(keys(index_by_field)))
        isempty(missing_fields) || error("Missing fields in flattened object: $(missing_fields)")

        indices = Int[]
        for field in fields
            range = index_by_field[field]
            length(range) == 1 || error("Expected scalar field $(field), got flattened range $(range)")
            push!(indices, first(range))
        end
        return indices
    end

    function optimization_indices(model)
        offset =
            flattened_length(model.w_act) +
            flattened_length(model.w_inact) +
            flattened_length(model.firms) +
            flattened_length(model.bank) +
            flattened_length(model.cb) +
            flattened_length(model.gov) +
            flattened_length(model.rotw) +
            flattened_length(model.agg)

        indices = flattened_field_indices(model.prop, PROPERTY_OPTIMIZATION_FIELDS; offset)
        length(indices) == length(PROPERTY_OPTIMIZATION_FIELDS) ||
            error("Expected $(length(PROPERTY_OPTIMIZATION_FIELDS)) optimization indices, got $(length(indices))")
        return indices
    end

    function gdp(m)
        tot_C_h = sum(m.w_act.C_h) + sum(m.w_inact.C_h) + sum(m.firms.C_h) + m.bank.C_h
        tot_I_h = sum(m.w_act.I_h) + sum(m.w_inact.I_h) + sum(m.firms.I_h) + m.bank.I_h
        return sum(m.firms.Y_i .* ((1 .- m.firms.tau_Y_i) - 1 ./ m.firms.beta_i)) +
            sum(m.firms.tau_Y_i .* m.firms.Y_i) +
            m.prop.tau_VAT * tot_C_h / Bit.zero_to_one(m.agg.P_bar_h) +
            m.prop.tau_CF * tot_I_h / Bit.zero_to_one(m.agg.P_bar_CF_h) +
            m.prop.tau_G * m.gov.C_j / Bit.zero_to_one(m.gov.P_j) +
            m.prop.tau_EXPORT * m.rotw.C_l / Bit.zero_to_one(m.rotw.P_l)
    end

    function step_and_reduce_auto!(model_arr, gdpinit0, start_model)
        m = Bit.array_to_model(model_arr, start_model)
        gdpinit = gdp(m)
        Bit.step!(m, 1)
        return (gdp(m) - gdpinit) / gdpinit - ((gdpinit - gdpinit0) / gdpinit0)^2
    end

    function zero_non_optimized!(gstep, optimized_mask)
        for i in eachindex(gstep)
            optimized_mask[i] || (gstep[i] = zero(eltype(gstep)))
        end
        return gstep
    end

    function clamp_optimization_step!(g, k, optimized_indices)
        for i in optimized_indices
            if k[i] + g[i] < zero(FloatType)
                g[i] = -k[i]
            elseif k[i] + g[i] > one(FloatType)
                g[i] = one(FloatType) - k[i]
            end
        end
        return g
    end

    function print_progress(method, epoch, gdps)
        gdp0, gdp1 = last(gdps)
        @printf(
            "[%s %s] epoch %d/%d | GDP step 0 %+0.6f%% | GDP step 1 %+0.6f%%\n",
            method,
            FLOAT_TYPE_NAME,
            epoch,
            EPOCHS,
            100 * (Float64(gdp0) / Float64(first(gdps)[1]) - 1),
            100 * (Float64(gdp1) / Float64(first(gdps)[2]) - 1),
        )
        return flush(stdout)
    end

    function progress_plot(gdps)
        p = plot([x[1] for x in gdps]; marker = :circle)
        p = plot!([x[2] for x in gdps]; marker = :circle)
        return display(p)
    end

    function build_model()
        Random.seed!(RNG_SEED)
        parameters = Bit.AUSTRIA2010Q1.parameters
        initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
        return Bit.Model(parameters, initial_conditions)
    end

    const model = build_model()
    const gdpinit0 = gdp(model)
    const optimized_indices = optimization_indices(model)
    const optimized_mask = let
        mask = falses(length(Bit.model_to_array(model)))
        mask[optimized_indices] .= true
        mask
    end
    const backend = "automatic" in WORKER_METHODS ? AutoMooncake() : nothing

    step_and_reduce_auto!(model_arr) = step_and_reduce_auto!(model_arr, gdpinit0, model)

    println("Optimizing $(length(optimized_indices)) model-array positions for $(FLOAT_TYPE_NAME):")
    for (field, index) in zip(PROPERTY_OPTIMIZATION_FIELDS, optimized_indices)
        println("  $(field) => model array index $(index)")
    end

    function run_automatic()
        backend === nothing && error("Mooncake backend was not initialized")

        k = Bit.model_to_array(model)
        g = zeros(FloatType, length(k))
        gstep = copy(g)
        gdps = []

        for epoch in 1:EPOCHS
            Random.seed!(RNG_SEED)
            g .+= 0.1 * gstep
            clamp_optimization_step!(g, k, optimized_indices)

            m = Bit.array_to_model(k .+ g, model)
            gdpinit = gdp(m)
            Bit.step!(m, 1)
            push!(gdps, (gdpinit, gdp(m)))
            progress_plot(gdps)
            print_progress("Automatic", epoch, gdps)

            Random.seed!(RNG_SEED)
            @time gstep = gradient(step_and_reduce_auto!, backend, k .+ g)
            zero_non_optimized!(gstep, optimized_mask)
        end

        return gdps
    end

    function step_and_reduce_num!(
            model_arr::AbstractVector{T},
            start_model,
            gdpinit0,
            gstep,
            optimized_indices,
        ) where {T <: AbstractFloat}
        step_base = eps(FloatType)^(1 / 3)

        for i in optimized_indices
            v = model_arr[i]

            magnitude = FloatType(max(abs(v), 1.0e-4))
            h = step_base * magnitude

            model_arr[i] = v + h
            Random.seed!(RNG_SEED)
            m = Bit.array_to_model(model_arr, start_model)
            gdpinit = gdp(m)
            Bit.step!(m, 1)
            g_plus_2 = (gdp(m) - gdpinit) / gdpinit - ((gdpinit - gdpinit0) / gdpinit0)^2

            model_arr[i] = v - h
            Random.seed!(RNG_SEED)
            m = Bit.array_to_model(model_arr, start_model)
            gdpinit = gdp(m)
            Bit.step!(m, 1)
            g_minus_2 = (gdp(m) - gdpinit) / gdpinit - ((gdpinit - gdpinit0) / gdpinit0)^2

            model_arr[i] = v

            derivative = (g_plus_2 - g_minus_2) / (2 * h)
            println(derivative)

            gstep[i] = derivative
        end
        return gstep
    end

    function run_numerical()
        local_model = build_model()
        local_gdpinit0 = gdp(local_model)
        k = Bit.model_to_array(local_model)
        g = zeros(FloatType, length(k))
        gstep = copy(g)
        gdps = []

        for epoch in 1:EPOCHS
            Random.seed!(RNG_SEED)
            g .+= 0.1 * gstep
            clamp_optimization_step!(g, k, optimized_indices)

            println((k .+ g)[optimized_indices])
            m = Bit.array_to_model(k .+ g, local_model)
            gdpinit = gdp(m)
            Bit.step!(m, 1)
            push!(gdps, (gdpinit, gdp(m)))
            progress_plot(gdps)
            print_progress("Numerical", epoch, gdps)

            @time gstep = step_and_reduce_num!(
                Bit.model_to_array(local_model) .+ g,
                local_model,
                local_gdpinit0,
                gstep,
                optimized_indices,
            )
            zero_non_optimized!(gstep, optimized_mask)
        end
        return gdps
    end

    function write_gdps(kind, float_type_name, gdps)
        df = DataFrame(
            GDP0 = first.(gdps),
            GDP1 = last.(gdps),
        )
        return CSV.write(csv_path(kind, float_type_name), df)
    end

    if "numerical" in WORKER_METHODS
        gdps_num = run_numerical()
        write_gdps("num", FLOAT_TYPE_NAME, gdps_num)
    end

    if "automatic" in WORKER_METHODS
        gdps_auto = run_automatic()
        write_gdps("auto", FLOAT_TYPE_NAME, gdps_auto)
    end
else
    using CSV
    using DataFrames
    using Plots

    const WORKER_RUNS = (
        ("Float64", "numerical,automatic"),
        ("Float128", "numerical"),
    )

    function run_worker_process(float_type_name, methods)
        command = `$(Base.julia_cmd()) --project=$(PROJECT_DIR) $(SCRIPT_PATH) --worker $(float_type_name) $(methods)`
        println("Running $(methods) with BeforeIT.typeFloat=$(float_type_name)")
        return run(command)
    end

    for (float_type_name, methods) in WORKER_RUNS
        run_worker_process(float_type_name, methods)
    end

    a = CSV.read(csv_path("auto", "Float64"), DataFrame)
    b = CSV.read(csv_path("num", "Float64"), DataFrame)
    c = CSV.read(csv_path("num", "Float128"), DataFrame)

    lw = 2
    p = plot(
        100 .* (a.GDP1 / a.GDP1[1] .- 1);
        label = "Automatic Gradient",
        legend = :bottomright,
        color = 1,
        xlabel = "epoch",
        ylabel = "percentage change",
        dpi = 1000,
        yformatter = y -> "$(Int(y))%",
        linewidth = lw,
        markersize = 3,
        markershape = :circle,
    )
    plot!(p, 100 .* (b.GDP1 / b.GDP1[1] .- 1); label = "Numerical Gradient (Float64)", markersize = 3, marker = :square, color = 2, linewidth = lw)
    plot!(p, 100 .* (c.GDP1 / c.GDP1[1] .- 1); label = "Numerical Gradient (Float128)", markersize = 3, marker = :diamond, color = 3, linewidth = lw)
    savefig(p, joinpath(SCRIPT_DIR, "gdp_optimization.pdf"))
end
