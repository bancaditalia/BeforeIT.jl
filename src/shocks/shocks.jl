abstract type AbstractShock end

struct NoShock <: AbstractShock
    NoShock() = new()
end

(s::NoShock)(x) = nothing

struct InterestRateShock <: AbstractShock
    rate::Any
    final_time::Any
end

(s::InterestRateShock)(model) = (model.agg.t <= s.final_time) ? model.cb.r_bar = s.rate : nothing
