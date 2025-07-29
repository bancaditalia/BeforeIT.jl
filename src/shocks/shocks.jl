abstract type AbstractShock end

struct NoShock <: AbstractShock
    NoShock() = new()
end

(s::NoShock)(x) = nothing

struct InterestRateShock{R, T} <: AbstractShock
    rate::R
    final_time::T
end

(s::InterestRateShock)(model) = (model.agg.t <= s.final_time) ? model.cb.r_bar = s.rate : nothing

struct ProductivityShock
    productivity_multiplier::Float64    # productivity multiplier
end

# A permanent change in the labour productivities by the factor s.productivity_multiplier
function (s::ProductivityShock)(model::Bit.Model)
    return model.firms.alpha_bar_i .= model.firms.alpha_bar_i .* s.productivity_multiplier
end

struct ConsumptionShock
    consumption_multiplier::Float64    # productivity multiplier
    final_time::Int
end

# A temporary change in the propensity to consume model.prop.psi by the factor s.consumption_multiplier
function (s::ConsumptionShock)(model::Bit.Model)
    return if model.agg.t == 1
        model.prop.psi = model.prop.psi * s.consumption_multiplier
    elseif model.agg.t == s.final_time
        model.prop.psi = model.prop.psi / s.consumption_multiplier
    end
end
