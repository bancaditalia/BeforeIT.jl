"""
--------- CANVAS model by overwriting ---------

There are 4 major changes from the Poledna et al. (2023) to the CANVAS model (Hommes et al., 2025)

1) Increased heterogeneity with respect to consumer behaviour and initiasation
2) Increased heterogeniety with respect to firm initialisation
3) Demand pull firm level price and quanitity setting
4) Adaptive learning for the central bank to learn the parameters of the Taylor rule

This script implements changes 3 and 4 by overwriting the methods that govern that behaviour. 
To introduce changes 1 and 2 we need dissagregated data at the household and firm level.
"""

import BeforeIT as Bit
using Plots, Dates, FileIO

# calibration
T = 12
year_i = 2019
quarter = 1
scale = 0.001
cal = Bit.ITALY_CALIBRATION
calibration_date = DateTime(2010, 03, 31)

# standard calibration 
p, ic = Bit.get_params_and_initial_conditions(cal, calibration_date; scale = scale)

# new variables needed for the CANVAS model
T_estimation_exo = findall(cal.data["quarters_num"] .== Bit.date2num(cal.estimation_date))[1][1]
T_calibration_exo = findall(cal.data["quarters_num"] .== Bit.date2num(calibration_date))[1][1]
timescale_sum_output = 1.0 # TODO: to be changed, this should be: timescale * sum(output)
Y_EA_series = timescale_sum_output .* cal.ea["real_gdp_quarterly"][T_estimation_exo:T_calibration_exo] ./ cal.ea["real_gdp_quarterly"][T_calibration_exo]
pi_EA_series = diff(log.(cal.ea["gdp_deflator_quarterly"][(T_estimation_exo - 1):T_calibration_exo]))
r_bar_series = r_bar_series = (cal.data["euribor"][T_estimation_exo:T_calibration_exo] .+ 1.0) .^ (1.0 / 4.0) .- 1

# new aggregates for the CANVAS model
mutable struct AggregatesCANVAS{T, I} <: Bit.AbstractAggregates
    Bit.@aggregates T I
    Y_EA_series::Vector{T}
    pi_EA_series::Vector{T}
    r_bar_series::Vector{T}
end

# new firms for the CANVAS model
mutable struct FirmsCANVAS{T <: AbstractVector, I <: AbstractVector} <: Bit.AbstractFirms
    Bit.@firm T I
end

# new function to update the firms expectation and decisions in the CANVAS model
function Bit.firms_expectations_and_decisions(firms::FirmsCANVAS, model)

    # unpack non-firm variables
    tau_SIF = model.prop.tau_SIF
    tau_FIRM = model.prop.tau_FIRM
    theta = model.prop.theta
    theta_DIV = model.prop.theta_DIV
    P_bar_HH = model.agg.P_bar_HH
    P_bar_CF = model.agg.P_bar_CF
    P_bar_g = model.agg.P_bar_g
    a_sg = model.prop.products.a_sg
    gamma_e = model.agg.gamma_e
    pi_e = model.agg.pi_e

    # Individual firm quantity and price adjustments
    I = length(firms.G_i);
    gamma_d_i = zeros(I);
    pi_d_i = zeros(I);

    for i=1:I
        if firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i]-1;
            pi_d_i[i]=0;
        elseif firms.Q_s_i[i] <= firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0;
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] >= P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = 0;
            pi_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
        elseif firms.Q_s_i[i] > firms.Q_d_i[i] && firms.P_i[i] < P_bar_g[firms.G_i[i]]
            gamma_d_i[i] = firms.Q_d_i[i] / firms.Q_s_i[i] - 1;
            pi_d_i[i] = 0;
        end
    end
    #pi_d_i = min.(pi_d_i, 0.3) # cap the price adjustment to 30%. Otherwise it can reach 200% in some cases

    Q_s_i = firms.Q_s_i .* (1 .+ gamma_e) .* (1 .+ gamma_d_i)

    # price setting
    # dividing equation for pi_c_i into smaller pieces
    pi_l_i = (1 + tau_SIF) .* firms.w_bar_i ./ firms.alpha_bar_i .* (P_bar_HH ./ firms.P_i .- 1)
    term = dropdims(sum(a_sg[:, firms.G_i] .* P_bar_g, dims = 1), dims = 1)
    pi_k_i = firms.delta_i ./ firms.kappa_i .* (P_bar_CF ./ firms.P_i .- 1)

    pi_m_i =  1 ./ firms.beta_i .* (term ./ firms.P_i .- 1)

    pi_c_i = pi_l_i .+ pi_k_i .+ pi_m_i

    new_P_i = firms.P_i .* (1 .+ pi_c_i) .* (1 + pi_e) .* (1 .+ pi_d_i)

    I_d_i = firms.delta_i ./ firms.kappa_i .* min(Q_s_i, firms.K_i .* firms.kappa_i)

    # intermediate goods to purchase
    DM_d_i = min.(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.beta_i

    # target employment
    N_d_i = max.(1.0, round.(min(Q_s_i, firms.K_i .* firms.kappa_i) ./ firms.alpha_bar_i))

    # expected profits 
    Pi_e_i = firms.Pi_i .* (1 + pi_e) * (1 + gamma_e)

    # target loans
    DD_e_i =
        Pi_e_i .- theta .* firms.L_i .- tau_FIRM .* max.(0, Pi_e_i) .- (theta_DIV .* (1 .- tau_FIRM)) .* max.(0, Pi_e_i) # expected future cash flow
    DL_d_i = max.(0, -DD_e_i - firms.D_i)

    # expected capital
    K_e_i = P_bar_CF .* (1 + pi_e) .* firms.K_i

    # expected loans
    L_e_i = (1 - theta) .* firms.L_i

    return Q_s_i, I_d_i, DM_d_i, N_d_i, Pi_e_i, DL_d_i, K_e_i, L_e_i, new_P_i, pi_d_i, pi_c_i, pi_l_i, pi_k_i, pi_m_i
end

# new firms initialisation
firms_st, args = Bit.init_firms(p, ic)
firms = FirmsCANVAS(args...)
firms.Q_s_i = copy(firms.Q_d_i) # overwrite to avoid division by zero for new firm price and quantity setting mechanism

# new aggregates initialisation
agg_st, args = Bit.init_aggregates(p, ic, T)
agg = AggregatesCANVAS(args..., Y_EA_series, pi_EA_series, r_bar_series) # add new variables to the aggregates

# standard initialisations
workers_act, workers_inact, V_i_new, _, _ = Bit.init_workers(p, ic, firms)
firms_st.V_i = V_i_new
firms.V_i = V_i_new
bank, _ = Bit.init_bank(p, ic, firms)
central_bank, _ = Bit.init_central_bank(p, ic)
government, _ = Bit.init_government(p, ic)
rotw, _ = Bit.init_rotw(p, ic)
properties = Bit.init_properties(p, T)

# define a standard model
model_std = Bit.Model(workers_act, workers_inact, firms_st, bank, central_bank, government, rotw, agg_st, properties)

# define a CANVAS model
model_canvas = Bit.Model(workers_act, workers_inact, firms, bank, central_bank, government, rotw, agg, properties)

# adjust accounting
Bit.update_variables_with_totals!(model_std)
Bit.update_variables_with_totals!(model_canvas)

# run the model(s)
data_vector_std = Bit.ensemblerun(model_std, 8)
data_vector_canvas = Bit.ensemblerun(model_canvas, 8)

# plot the results
ps = Bit.plot_data_vectors([data_vector_std, data_vector_canvas])
plot(ps..., layout = (3, 3))
