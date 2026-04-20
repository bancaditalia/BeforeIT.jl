struct TimeIndex
    step::Int64
end

mutable struct MacroeconomicState
    gross_domestic_product_history::Vector{Float64}       #Y
    inflation_history::Vector{Float64}                    #pi_
    sector_price_index::Vector{Float64}                   #P_bar_g
    aggregate_price_index::Float64                        #P_bar
    household_consumption_price_index::Float64            #P_bar_HH
    capital_goods_price_index::Float64                    #P_bar_CF
    household_consumption_price_index_previous::Float64   #P_bar_h
    capital_goods_price_index_previous::Float64           #P_bar_CF_H
    expected_gross_domestic_product::Float64              #Y_e
    expected_output_growth::Float64                       #gamma_e
    expected_inflation::Float64                           #pi_e
end
