# Time the gradient of a one-step GDP objective with respect to the first n entries of the
# model array, using Mooncake (reverse mode) and central finite differences.
#
# By default the script plots the saved results in `data/autodiff_performance.csv`. With
# `--run` it first re-runs all or some of the benchmarks and replaces their saved results:
#
#   julia --project=<env> examples/automatic_differentiation_perf.jl
#   julia --project=<env> examples/automatic_differentiation_perf.jl --run
#   julia --project=<env> examples/automatic_differentiation_perf.jl --run auto float128
#
# The benchmarks are `auto` (Mooncake gradient, Float64), `float64` and `float128` (central
# finite differences in that precision). BeforeIT fixes its floating-point type when it is
# loaded, so each precision runs in its own Julia process. The saved results were obtained
# on Austria 2010Q1 with BeforeIT 0.6.0, Mooncake 0.5.63 and Julia 1.13.1.

using CSV
using DataFrames
using Printf
using Random

const SCRIPT_PATH = abspath(@__FILE__)
const RESULTS_FILE = joinpath(@__DIR__, "data", "autodiff_performance.csv")
const BENCHMARKS = ["auto", "float64", "float128"]

benchmark_float_type(benchmark) = benchmark == "float128" ? "Float128" : "Float64"

# The values given after `flag`, up to the next flag, separated by spaces or commas.
function flag_values(flag)
    i = findfirst(==(flag), ARGS)
    i === nothing && return nothing
    j = something(findnext(startswith("--"), ARGS, i + 1), length(ARGS) + 1)
    return [lowercase(v) for arg in ARGS[(i + 1):(j - 1)] for v in split(arg, ",") if !isempty(v)]
end

const WORKER_BENCHMARKS = flag_values("--worker")
const RUN_BENCHMARKS = flag_values("--run")

# Worker process: time the given benchmarks, which share one floating-point type.
if WORKER_BENCHMARKS !== nothing
    const FLOAT_TYPE_NAME = benchmark_float_type(first(WORKER_BENCHMARKS))
    all(b -> benchmark_float_type(b) == FLOAT_TYPE_NAME, WORKER_BENCHMARKS) ||
        error("Benchmarks $(WORKER_BENCHMARKS) need different floating-point types")

    using Preferences
    set_preferences!("BeforeIT", "typeFloat" => FLOAT_TYPE_NAME; force = true)
    import BeforeIT as Bit
    import Mooncake

    const FloatType = Bit.typeFloat

    function gdp(m)
        tot_C_h = sum(m.w_act.C_h) + sum(m.w_inact.C_h) + sum(m.firms.C_h) + sum(m.banks.C_h)
        tot_I_h = sum(m.w_act.I_h) + sum(m.w_inact.I_h) + sum(m.firms.I_h) + sum(m.banks.I_h)
        return sum(m.firms.Y_i .* ((1 .- m.firms.tau_Y_i) - 1 ./ m.firms.beta_i)) +
            sum(m.firms.tau_Y_i .* m.firms.Y_i) +
            m.prop.tau_VAT * tot_C_h / Bit.zero_to_one(m.agg.P_bar_h) +
            m.prop.tau_CF * tot_I_h / Bit.zero_to_one(m.agg.P_bar_CF_h) +
            m.prop.tau_G * m.gov.C_j / Bit.zero_to_one(m.gov.P_j) +
            m.prop.tau_EXPORT * m.rotw.C_l / Bit.zero_to_one(m.rotw.P_l)
    end

    function step_and_reduce(model_arr, gdpinit0, start_model)
        m = Bit.array_to_model(model_arr, start_model)
        gdpinit = gdp(m)
        Bit.step!(m, 1)
        return 100 * (gdp(m) - gdpinit) / gdpinit - (100 * (gdpinit - gdpinit0) / gdpinit0)^2
    end

    Random.seed!(42)
    const model = Bit.Model(Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions)
    const gdpinit0 = gdp(model)
    const model_arr = Bit.model_to_array(model)

    # The objective as a function of the first n entries of the model array.
    function step_and_reduce_head(head)
        x = copy(model_arr)
        copyto!(x, head)
        return step_and_reduce(x, gdpinit0, model)
    end

    function numerical_gradient(n)
        step_base = eps(FloatType)^(1 / 3)
        x = copy(model_arr)
        g = Vector{FloatType}(undef, n)
        for i in 1:n
            v = x[i]
            h = step_base * max(abs(v), FloatType(1.0e-4))

            x[i] = v + h
            Random.seed!(42)
            f_plus = step_and_reduce(x, gdpinit0, model)

            x[i] = v - h
            Random.seed!(42)
            f_minus = step_and_reduce(x, gdpinit0, model)

            x[i] = v
            g[i] = (f_plus - f_minus) / (2 * h)
        end
        return g
    end

    ns = [1, 10, 100, 1000, 10000, length(model_arr)]
    measured = DataFrame(
        method = String[], float_type = String[], n = Int[], seconds = Float64[],
        prepare_seconds = Union{Float64, Missing}[]
    )

    # Automatic gradient. `prepare_gradient_cache` builds Mooncake's rule and buffers once per
    # input size; the first call also compiles the rule through `step!`, which takes minutes.
    # The cache must be built before seeding: building it runs the objective once, which
    # consumes random numbers.
    if "auto" in WORKER_BENCHMARKS
        for n in ns
            head = model_arr[1:n]
            t_prepare = @elapsed cache = Mooncake.prepare_gradient_cache(step_and_reduce_head, head)
            ts = map(1:5) do _
                Random.seed!(42)
                @elapsed Mooncake.value_and_gradient!!(cache, step_and_reduce_head, head)
            end
            t = sort(ts)[3]
            @printf(
                "automatic  n=%-6d gradient %.3f s (median of 5), cache preparation %.1f s\n",
                n, t, t_prepare
            )
            push!(measured, ("automatic", FLOAT_TYPE_NAME, n, t, t_prepare))
        end
    end

    # Numerical gradient (`float64` or `float128`): two model steps per entry, so only the
    # smaller sizes are timed.
    if any(!=("auto"), WORKER_BENCHMARKS)
        num_max_n = FloatType == Float64 ? 1000 : 100
        for n in filter(<=(num_max_n), ns)
            numerical_gradient(1)
            t = @elapsed numerical_gradient(n)
            @printf("numerical  n=%-6d %s gradient %.3f s\n", n, FLOAT_TYPE_NAME, t)
            push!(measured, ("numerical", FLOAT_TYPE_NAME, n, t, missing))
        end
    end

    # Replace the saved results of the benchmarks just run.
    rerun = unique(zip(measured.method, measured.float_type))
    saved = isfile(RESULTS_FILE) ? CSV.read(RESULTS_FILE, DataFrame) : similar(measured, 0)
    saved = vcat(filter(row -> (row.method, row.float_type) ∉ rerun, saved), measured; cols = :union)
    mkpath(dirname(RESULTS_FILE))
    CSV.write(RESULTS_FILE, sort(saved, [:method, :float_type, :n]))
    exit()
end

using Plots

if RUN_BENCHMARKS !== nothing
    selected = isempty(RUN_BENCHMARKS) ? BENCHMARKS : RUN_BENCHMARKS
    unknown = setdiff(selected, BENCHMARKS)
    isempty(unknown) || error("Unknown benchmarks $(unknown), choose from $(BENCHMARKS)")

    # The workers set BeforeIT's floating-point type in this environment's preferences:
    # restore the current setting afterwards.
    using Preferences
    beforeit_uuid = Base.identify_package("BeforeIT").uuid
    previous_float_type = load_preference(beforeit_uuid, "typeFloat")
    try
        for float_type in ("Float64", "Float128")
            group = filter(b -> b in selected && benchmark_float_type(b) == float_type, BENCHMARKS)
            isempty(group) && continue
            println("Running $(join(group, ", ")) with BeforeIT.typeFloat=$(float_type)")
            project = dirname(Base.active_project())
            run(`$(Base.julia_cmd()) --project=$(project) $(SCRIPT_PATH) --worker $(join(group, ","))`)
        end
    finally
        if previous_float_type === nothing
            delete_preferences!(beforeit_uuid, "typeFloat"; force = true)
        else
            set_preferences!(beforeit_uuid, "typeFloat" => previous_float_type; force = true)
        end
    end
    println("Results saved to $(RESULTS_FILE)")
end

results = CSV.read(RESULTS_FILE, DataFrame)
select_results(method, float_type) =
    sort(filter(row -> row.method == method && row.float_type == float_type, results), :n)

automatic = select_results("automatic", "Float64")
numerical64 = select_results("numerical", "Float64")
numerical128 = select_results("numerical", "Float128")

# The numerical gradient scales linearly with n: extend it to the full model array.
n_full = maximum(results.n)
extrapolate(r) = ([r.n[end], n_full], r.seconds[end] .* [1, n_full / r.n[end]])

xtick_vals = [1, 10, 100, 1000, 10000, 100000]
xtick_labels = ["10^$(Int(log10(x)))" for x in xtick_vals]

ymaj = 10.0 .^ (-1:5)
ymaj_labels = ["10^$(i)" for i in -1:5]

p = plot(;
    xscale = :log10,
    yscale = :log10,

    xticks = (xtick_vals, xtick_labels),
    yticks = (ymaj, ymaj_labels),

    # Minor ticks + grid styling
    yminorgrid = true,
    ygrid = true,

    xlabel = "parameters count",
    ylabel = "time (s)",
    title = "",
    legend = :topleft,
)

# Series without saved results (e.g. before the first Float128 run) are skipped.
if !isempty(automatic)
    plot!(
        p, automatic.n, automatic.seconds;
        label = "Automatic Gradient", lw = 2, marker = :circle, color = 1
    )
end

for (r, label, marker, color) in (
        (numerical64, "Numerical Gradient (Float64)", :square, 2),
        (numerical128, "Numerical Gradient (Float128)", :diamond, 3),
    )
    isempty(r) && continue
    plot!(p, extrapolate(r)...; label = "", lw = 2, linestyle = :dash, color)
    plot!(p, r.n, r.seconds; label, lw = 2, marker, color)
end

savefig(p, "autodiff_performance.pdf")
