
using Mooncake, DifferentiationInterface
using Plots
using Random
using JLD2

using Quadmath

# this needs to be rerun using Float64
const FloatType = Float128

using Preferences

set_preferences!("BeforeIT", "typeFloat" => "$FloatType"; force=true)
import BeforeIT as Bit

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

function step_and_reduce_auto!(gradient_vals, model_arr, gdpinit0, start_model)
    for i in eachindex(gradient_vals)
        model_arr[i] += gradient_vals[i]
    end
    m = Bit.array_to_model(model_arr, start_model)
    gdpinit = gdp(m)
    Bit.step!(m, 1)
    return 100 * (gdp(m) - gdpinit)/gdpinit - (100 * (gdpinit - gdpinit0)/gdpinit0)^2
end


parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
Random.seed!(68)
const model = Bit.Model(parameters, initial_conditions)
const gdpinit0 = gdp(model)
const backend = AutoMooncake()
const model_arr = Bit.model_to_array(model)

step_and_reduce_auto!(gradient_vals) = step_and_reduce_auto!(gradient_vals, model_arr, gdpinit0, model)

function step_and_reduce_num!(model_arr::AbstractVector{T}, start_model, gdpinit0, n) where T<:AbstractFloat
    step_base = eps(FloatType)^(1/3)

    gstep = Vector{T}(undef, n)
    for i in 1:n
        v = model_arr[i]
        
        magnitude = FloatType(max(abs(v), 1e-4))
        h = step_base * magnitude

        model_arr[i] = v + h
        Random.seed!(42)
        m = Bit.array_to_model(model_arr, start_model)
        gdpinit = gdp(m)
        Bit.step!(m, 1)
        g_plus_2 = 100 * (gdp(m) - gdpinit)/gdpinit - (100 * (gdpinit - gdpinit0)/gdpinit0)^2

        model_arr[i] = v - h
        Random.seed!(42)
        m = Bit.array_to_model(model_arr, start_model)
        gdpinit = gdp(m)
        Bit.step!(m, 1)
        g_minus_2 = 100 * (gdp(m) - gdpinit)/gdpinit - (100 * (gdpinit - gdpinit0)/gdpinit0)^2

        model_arr[i] = v
        
        derivative = (g_plus_2 - g_minus_2) / (2 * h)

        gstep[i] = derivative
    end
    return gstep
end

ns = [1, 10, 100, 1000, 10000, 106955]

ts_auto = []

for n in ns
    Random.seed!(42)
    t = @elapsed gradient(step_and_reduce_auto!, backend, zeros(n))
    println(t)
    push!(ts_auto, t)
end

ts_num = []
for n in ns
    Random.seed!(42)
    t = @elapsed step_and_reduce_num!(model_arr, model, gdpinit0, n)
    println(t)
    push!(ts_num, t)
end

using Plots

# Data

# AUTOMATIC DIFFERENTIATION
x1 = [1, 10, 100, 1000, 10000, 106955]
y1 = [14.063820278, 12.852828539, 12.714335228, 13.993290489, 12.790418561, 12.670537027]

# NUMERICAL DIFFERENTIATION - Float64
x2 = [1, 10, 100, 1000]
y2 = [0.061355817, 0.480043678, 4.878887772, 49.936250526]

# NUMERICAL DIFFERENTIATION - Float128
x3 = [1, 10, 100]
y3 = [0.737497204, 7.422612335, 74.499984463]

# Continuations
x2_ext = [1000, 10000, 100000]
y2_ext = [49.936250526, 499.36250526, 4993.6250526]

x3_ext = [100, 1000, 10000, 100000]
y3_ext = [74.499984463, 744.99984463, 7449.9984463, 74499.984463]

# X ticks (scientific style)
xtick_vals = [1, 10, 100, 1000, 10000, 100000]
xtick_labels = ["10^$(Int(log10(x)))" for x in xtick_vals]

# Y major ticks (powers of 10)
ymaj = 10.0 .^ (-1:5)
ymaj_labels = ["10^$(i)" for i in -1:5]

p = plot(
    x1, y1;
    label = "Automatic Gradient",
    lw = 2,
    marker = :circle,
    xscale = :log10,
    yscale = :log10,

    xticks = (xtick_vals, xtick_labels),
    yticks = (ymaj, ymaj_labels),

    # Minor ticks + grid styling
    yminorgrid = true,
    ygrid = true,
    gridalpha = 0.3,
    minorgridalpha = 0.15,

    xlabel = "parameters count",
    ylabel = "time (s)",
    title = "",
    legend = :topleft,
)

# Dashed continuation (same color)
plot!(p, x2_ext, y2_ext; label = "", lw = 2, linestyle = :dash, color = 2)
plot!(p, x3_ext, y3_ext; label = "", lw = 2, linestyle = :dash, color = 3)

plot!(p, x2, y2; label = "Numerical Gradient (Float64)", lw = 2, marker = :square, color = 2)

plot!(p, x3, y3; label = "Numerical Gradient (Float128)", lw = 2, marker = :diamond, color = 3)

savefig(p, "autodiff_performance.pdf")
