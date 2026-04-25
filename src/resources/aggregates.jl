struct TimeIndex
    step::Int64
end

mutable struct MacroeconomicState
    gross_domestic_product_history::Vector{Float64}       #Y
    inflation_history::Vector{Float64}                    #pi_
end

mutable struct Expectations
    gross_domestic_product::Float64              #Y_e
    output_growth::Float64                       #gamma_e
    inflation::Float64                           #pi_e
end

mutable struct PriceIndices
    sector::Vector{Float64}                   #P_bar_g
    aggregate::Float64                        #P_bar
    household_consumption::Float64            #P_bar_HH
    capital_goods::Float64                    #P_bar_CF
    household_consumption_previous::Float64   #P_bar_h
    capital_formation_households::Float64       #P_bar_CF_H
end
