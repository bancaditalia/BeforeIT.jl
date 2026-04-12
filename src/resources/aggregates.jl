struct TimeIndex
    step::Int64
end

mutable struct MacroeconomicState
    gross_domestic_product_history::Vector{Float64}
    inflation_history::Vector{Float64}
    aggregate_price_index::Float64
    household_consumption_price_index::Float64
    capital_goods_price_index::Float64
    household_consumption_price_index_previous::Float64
    capital_goods_price_index_previous::Float64
    expected_gross_domestic_product::Float64
    expected_output_growth::Float64
    expected_inflation::Float64
    foreign_output_shock::Float64
    export_demand_shock::Float64
    investment_demand_shock::Float64
end
