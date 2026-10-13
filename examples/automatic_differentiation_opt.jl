# Maximise GDP growth over a few quarters with respect to 17 policy and behavioural
# parameters by stochastic gradient ascent, with the gradient computed by Mooncake (reverse
# mode) or by central finite differences, and plot the GDP reached along each optimisation.
#
# Each epoch computes the gradient on a new random seed, so the optimisation targets the
# expected GDP growth rather than one random realisation of it. Within one gradient every
# evaluation of the objective uses the same seed (common random numbers). The parameters
# reached at each epoch are scored on held-out seeds that no gradient uses.
#
# Over one quarter, Float64 finite differences with a small enough step match the Mooncake
# gradient. Over four quarters no Float64 step does (see `FD_STEPS`): this is the horizon used
# here. Each precision runs with the two textbook steps, eps^(1/3) and eps^(1/2), so that the
# step is not tuned to the problem.
#
# By default the script plots the saved results in `data/autodiff_optimization.csv`. With
# `--run` it first re-runs all or some of the optimisations and replaces their saved results:
#
#   julia --project=<env> examples/automatic_differentiation_opt.jl
#   julia --project=<env> examples/automatic_differentiation_opt.jl --run
#   julia --project=<env> examples/automatic_differentiation_opt.jl --run float64
#
# The optimisations are `auto` (Mooncake gradient, Float64), `float64` and `float128` (central
# finite differences in that precision). BeforeIT fixes its floating-point type when it is
# loaded, so each precision runs in its own Julia process. The saved results were obtained
# on Austria 2010Q1 with BeforeIT 0.6.0, Mooncake 0.5.63 and Julia 1.13.1.

using CSV
using DataFrames
using Printf
using Random
using Statistics

const SCRIPT_PATH = abspath(@__FILE__)
const RESULTS_FILE = joinpath(@__DIR__, "data", "autodiff_optimization.csv")
const OPTIMISATIONS = ["auto", "float64", "float128"]

const HORIZON = 4 # quarters simulated by the objective
const EPOCHS = 50
const LEARNING_RATE = 0.1
const SEED = 42 # seed of the model initialisation
const EVAL_SEEDS = 10_001:10_010

# Seed of the gradient computed at `epoch`.
training_seed(epoch) = SEED + epoch

# The optimised model properties: tax rates, household and banking parameters, all in [0, 1].
const PARAMETERS = (
    :tau_INC, :tau_FIRM, :tau_VAT, :tau_SIF, :tau_SIW, :tau_EXPORT, :tau_CF, :tau_G,
    :theta_UB, :psi, :psi_H, :mu, :theta_DIV, :theta, :zeta, :zeta_LTV, :zeta_b,
)

# Smallest value of each parameter in the optimisation, the largest is 1. With psi = 0
# households buy nothing, and the household price index computed in the goods market is
# 0 / 0 (`search_and_matching.jl`), so psi is kept slightly above 0.
const PSI_MIN = 1.0e-6
const LOWER_BOUNDS = [parameter == :psi ? PSI_MIN : 0.0 for parameter in PARAMETERS]

optimisation_float_type(optimisation) = optimisation == "float128" ? "Float128" : "Float64"

# The values given after `flag`, up to the next flag, separated by spaces or commas.
function flag_values(flag)
    i = findfirst(==(flag), ARGS)
    i === nothing && return nothing
    j = something(findnext(startswith("--"), ARGS, i + 1), length(ARGS) + 1)
    return [lowercase(v) for arg in ARGS[(i + 1):(j - 1)] for v in split(arg, ",") if !isempty(v)]
end

const WORKER_OPTIMISATIONS = flag_values("--worker")
const RUN_OPTIMISATIONS = flag_values("--run")

# Worker process: run the given optimisations, which share one floating-point type.
if WORKER_OPTIMISATIONS !== nothing
    const FLOAT_TYPE_NAME = optimisation_float_type(first(WORKER_OPTIMISATIONS))
    all(o -> optimisation_float_type(o) == FLOAT_TYPE_NAME, WORKER_OPTIMISATIONS) ||
        error("Optimisations $(WORKER_OPTIMISATIONS) need different floating-point types")

    println("Loading BeforeIT with typeFloat=$(FLOAT_TYPE_NAME) (precompiles if the type changed)")
    flush(stdout)
    using Preferences
    set_preferences!("BeforeIT", "typeFloat" => FLOAT_TYPE_NAME; force = true)
    import BeforeIT as Bit
    import Mooncake

    const FloatType = Bit.typeFloat

    minutes(seconds) = @sprintf("%.1f min", seconds / 60)

    # `rand(Normal(0, σ))` in `Bit.estimate` draws a normal of the type of σ. Float64 normals
    # take one random number per draw, other types use a generic method that takes more, so
    # from the first such draw on a Float128 run would read different random numbers than a
    # Float64 run with the same seed. Draw these normals in Float64, so that both precisions
    # start from the same random path. After the first quarter the paths can still part:
    # rounding differences between the two precisions grow until they switch a seller draw,
    # and every later draw differs.
    if FloatType != Float64
        Random.randn(rng::Random.AbstractRNG, ::Type{FloatType}) = FloatType(randn(rng, Float64))
    end

    # Relative steps of the finite differences, h = step * max(|x|, 1e-4): the two textbook
    # rules (Dennis & Schnabel 1996, ch. 5; Nocedal & Wright 2006, sec. 8.1), applied in the
    # precision of the run.
    # - eps^(1/3) (6e-6 in Float64, 6e-12 in Float128) minimises the error of central
    #   differences of a smooth function, balancing truncation (h^2) against rounding (eps/h).
    # - eps^(1/2) (1.5e-8 in Float64, 1.4e-17 in Float128) is the forward-difference rule and
    #   the usual smaller step when the function is not smooth. In Float128 it is below the
    #   resolution of the seller sampler, which works in Float64, so seller draws do not
    #   change within the step.
    # One model step is only piecewise smooth: firms hire whole workers and buyers draw
    # sellers at random, so a small change of a parameter can switch a discrete outcome and
    # make the objective jump. A step that straddles a jump gives jump / 2h instead of the
    # derivative. Every quarter adds discrete outcomes, and from the second quarter on the
    # re-estimated expectations amplify rounding errors, so the usable steps shrink from both
    # sides as the horizon grows. At the initial parameters:
    # - over one quarter, Float64 finite differences match the Mooncake gradient for steps
    #   from 1e-6 to 1e-11;
    # - over four quarters, jumps fall inside every Float64 step down to about 1e-10 and
    #   rounding errors dominate below about 3e-11, so no Float64 step works;
    # - over four quarters, Float128 finite differences agree with each other for steps from
    #   1e-12 to 1e-18. At other parameters, though, jumps can fall inside every Float128
    #   step down to at least 1e-20.
    const FD_STEPS = [eps(FloatType)^(1 / 3), sqrt(eps(FloatType))]

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

    # Reward GDP growth over `HORIZON` quarters, while keeping the initial GDP close to that
    # of the original parameters.
    function step_and_reduce(model_arr, gdpinit0, start_model)
        m = Bit.array_to_model(model_arr, start_model)
        gdpinit = gdp(m)
        Bit.step!(m, HORIZON)
        return (gdp(m) - gdpinit) / gdpinit - ((gdpinit - gdpinit0) / gdpinit0)^2
    end

    Random.seed!(SEED)
    const model = Bit.Model(Bit.AUSTRIA2010Q1.parameters, Bit.AUSTRIA2010Q1.initial_conditions)
    const gdpinit0 = gdp(model)
    const model_arr = Bit.model_to_array(model)

    objective(model_arr) = step_and_reduce(model_arr, gdpinit0, model)

    # Position of each optimised parameter in the model array: the only entry that changes
    # when the parameter does.
    const indices = map(collect(PARAMETERS)) do parameter
        m = deepcopy(model)
        setfield!(m.prop, parameter, getfield(m.prop, parameter) + 1)
        return only(findall(Bit.model_to_array(m) .!= model_arr))
    end

    # GDP after `HORIZON` quarters with the given seed, and its percentage growth from the
    # initial state on each held-out seed. The initial GDP counts no taxes on consumption,
    # investment, government purchases or exports, whose flows are zero before the first
    # quarter, so the growth includes those taxes appearing.
    function final_gdp(model_arr, seed)
        Random.seed!(seed)
        m = Bit.array_to_model(model_arr, model)
        Bit.step!(m, HORIZON)
        return gdp(m)
    end
    function eval_growths(x)
        initial_gdp = gdp(Bit.array_to_model(x, model))
        return 100 .* ([final_gdp(x, seed) for seed in EVAL_SEEDS] ./ initial_gdp .- 1)
    end

    # Gradient of the objective with respect to the optimised parameters on the given seed.
    function automatic_gradient()
        println("automatic: building the Mooncake gradient (compiles the rule through step!, takes several minutes)")
        flush(stdout)
        # Building the cache runs the objective once, which consumes random numbers.
        t = @elapsed cache = Mooncake.prepare_gradient_cache(objective, model_arr)
        println("automatic: Mooncake gradient ready after $(minutes(t))")
        return function (x, seed)
            Random.seed!(seed)
            _, (_, g) = Mooncake.value_and_gradient!!(cache, objective, x)
            return g[indices]
        end
    end

    function numerical_gradient(x, seed, step)
        x = copy(x)
        g = Vector{FloatType}(undef, length(indices))
        for (j, i) in enumerate(indices)
            v = x[i]
            h = FloatType(step) * max(abs(v), FloatType(1.0e-4))

            x[i] = v + h
            Random.seed!(seed)
            f_plus = objective(x)

            x[i] = v - h
            Random.seed!(seed)
            f_minus = objective(x)

            x[i] = v
            g[j] = (f_plus - f_minus) / (2 * h)
        end
        return g
    end

    # Stochastic gradient ascent from the original parameters, scoring the parameters of each
    # epoch on the held-out seeds. `step` is the finite-difference step, `missing` for the
    # Mooncake gradient.
    function optimise(method, step, gradient)
        x = copy(model_arr)
        results = DataFrame(
            method = String[], float_type = String[], horizon = Int[],
            step = Union{Float64, Missing}[], epoch = Int[],
            gdp_growth_mean = Float64[], gdp_growth_sd = Float64[]
        )
        name = ismissing(step) ? method : @sprintf("%s (h = %.1e)", method, step)
        println("$(name) $(FLOAT_TYPE_NAME): starting $(EPOCHS) epochs")
        flush(stdout)
        start = time()
        for epoch in 1:EPOCHS
            growths = eval_growths(x)
            push!(results, (method, FLOAT_TYPE_NAME, HORIZON, step, epoch, mean(growths), std(growths)))

            # A GDP that is not finite gives a gradient that is not finite either, and the
            # parameters would stay NaN from here on: stop the optimisation.
            finite = all(isfinite, growths)
            if epoch < EPOCHS && finite
                # Keep the parameters, all rates and shares, within their bounds.
                g = gradient(x, training_seed(epoch))
                x[indices] .= clamp.(x[indices] .+ LEARNING_RATE .* g, LOWER_BOUNDS, 1)
            end

            elapsed = time() - start
            @printf(
                "%s %s epoch %2d/%d | GDP growth over %d quarters on held-out seeds %+.2f%% (sd %.2f) | %s elapsed, about %s left\n",
                name, FLOAT_TYPE_NAME, epoch, EPOCHS, HORIZON, mean(growths), std(growths),
                minutes(elapsed), minutes(elapsed / epoch * (EPOCHS - epoch))
            )
            flush(stdout)
            if !finite
                println("$(name) $(FLOAT_TYPE_NAME): GDP is not finite, stopping")
                break
            end
        end
        return results
    end

    # Replace the saved results of the optimisations run so far, keeping those of other
    # horizons. Saving after each optimisation keeps the finished ones if a later one fails.
    function save_results(measured)
        rerun = unique(zip(measured.method, measured.float_type, measured.horizon))
        saved = isfile(RESULTS_FILE) ? CSV.read(RESULTS_FILE, DataFrame) : similar(measured, 0)
        saved = vcat(
            filter(row -> (row.method, row.float_type, row.horizon) ∉ rerun, saved), measured;
            cols = :union
        )
        mkpath(dirname(RESULTS_FILE))
        CSV.write(RESULTS_FILE, sort(saved, [:method, :float_type, :horizon, :step, :epoch]))
        println("Results saved to $(RESULTS_FILE)")
        return flush(stdout)
    end

    measured = DataFrame()
    for optimisation in WORKER_OPTIMISATIONS
        if optimisation == "auto"
            append!(measured, optimise("automatic", missing, automatic_gradient()))
            save_results(measured)
        else
            for step in FD_STEPS
                gradient = (x, seed) -> numerical_gradient(x, seed, step)
                append!(measured, optimise("numerical", Float64(step), gradient))
                save_results(measured)
            end
        end
    end
    exit()
end

using Plots

if RUN_OPTIMISATIONS !== nothing
    selected = isempty(RUN_OPTIMISATIONS) ? OPTIMISATIONS : RUN_OPTIMISATIONS
    unknown = setdiff(selected, OPTIMISATIONS)
    isempty(unknown) || error("Unknown optimisations $(unknown), choose from $(OPTIMISATIONS)")

    # The workers set BeforeIT's floating-point type in this environment's preferences:
    # restore the current setting afterwards.
    using Preferences
    beforeit_uuid = Base.identify_package("BeforeIT").uuid
    previous_float_type = load_preference(beforeit_uuid, "typeFloat")
    try
        for float_type in ("Float64", "Float128")
            group = filter(o -> o in selected && optimisation_float_type(o) == float_type, OPTIMISATIONS)
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

results = filter(row -> row.horizon == HORIZON, CSV.read(RESULTS_FILE, DataFrame))

# One colour per gradient method and precision; the finite-difference steps of one precision
# share it and differ by dash pattern.
const COLORS = Dict("automatic" => "#2a78d6", "Float64" => "#eb6834", "Float128" => "#1baf7a")
const ZERO_LINE_COLOR = "#c3c2b7"

p = plot(;
    xlabel = "epoch",
    ylabel = "GDP growth over $(HORIZON) quarters",
    yformatter = y -> "$(round(Int, y))%",
    xticks = 0:10:EPOCHS,
    legend = :bottomright,
    legendfontsize = 8,
    foreground_color_legend = nothing,
    background_color_legend = :white,
    size = (700, 440),
)
hline!(p, [0]; color = ZERO_LINE_COLOR, lw = 1, label = "")

# Mean percentage growth of GDP from the initial state over the held-out seeds (their standard
# deviation is saved but not drawn). Series without saved results for this horizon are
# skipped; a series that ends early stopped at a GDP that is not finite.
plot_gdp!(r; kwargs...) = plot!(p, r.epoch, r.gdp_growth_mean; lw = 2, kwargs...)

automatic = sort(filter(row -> row.method == "automatic", results), :epoch)
numerical = filter(row -> row.method == "numerical", results)

# The automatic gradient comes first in the legend but is drawn last, on top.
isempty(automatic) || plot_gdp!(automatic; label = "Automatic Gradient", color = COLORS["automatic"])

# Steps are named by their rule (see `FD_STEPS`) when they follow one; eps(Float128) = 2^-112.
const MACHINE_EPS = Dict("Float64" => eps(Float64), "Float128" => 2.0^-112)
function step_label(step, float_type)
    value = replace(@sprintf("%.1e", step), r"e-0*" => "e-")
    for (rule, power) in (("ε^(1/3)", 1 / 3), ("ε^(1/2)", 1 / 2))
        isapprox(step, MACHINE_EPS[float_type]^power; rtol = 1.0e-6) && return "$(rule) ≈ $(value)"
    end
    return value
end
for float_type in ("Float64", "Float128")
    r_type = filter(row -> row.float_type == float_type, numerical)
    for (i, step) in enumerate(sort(unique(r_type.step); rev = true))
        r = sort(filter(row -> row.step == step, r_type), :epoch)
        plot_gdp!(
            r; label = "Numerical Gradient ($(float_type), h = $(step_label(step, float_type)))",
            color = COLORS[float_type], linestyle = (:solid, :dash, :dot)[mod1(i, 3)]
        )
    end
end

isempty(automatic) || plot_gdp!(automatic; label = "", color = COLORS["automatic"])

savefig(p, "gdp_optimization.pdf")
