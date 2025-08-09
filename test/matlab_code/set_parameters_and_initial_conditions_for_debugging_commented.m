% Clear workspace
clear;

% Load calibration data
load('../data/calibration/2010Q1.mat','calibration_data');

% Load time series data
load('../data/data/1996.mat','data');
load('../data/ea/1996.mat','ea');

% Calculate GDP deflator from levels
data.gdp_deflator_quarterly=data.nominal_gdp_quarterly./data.real_gdp_quarterly;
ea.gdp_deflator_quarterly=ea.nominal_gdp_quarterly./ea.real_gdp_quarterly;

% Calibration date
start_calibration_date=datetime(2010,03,31);
end_calibration_date=datetime(2019,12,31);
max_calibration_date=datetime(2016,12,31);
estimation_date=datetime('1996-12-31');

for calibration_date=start_calibration_date:calquarters:end_calibration_date
    
    % Variables and constants for calibration
    T_calibration=find(calibration_data.years_num==datenum(datetime(year(min(calibration_date,max_calibration_date)),12,31)));
    T_calibration_quarterly=find(calibration_data.quarters_num==datenum(calibration_date));
    T_estimation_exo=find(data.quarters_num==datenum(estimation_date));
    T_calibration_exo=find(data.quarters_num==datenum(calibration_date));
    T_calibration_exo_max=length(data.quarters_num);
    intermediate_consumption=calibration_data.intermediate_consumption(:,:,T_calibration);
    household_consumption=calibration_data.household_consumption(:,T_calibration);
    fixed_capitalformation=calibration_data.fixed_capitalformation(:,T_calibration);
    capitalformation_dwellings=calibration_data.capitalformation_dwellings(:,T_calibration);
    capital_consumption=calibration_data.capital_consumption(:,T_calibration);
    % imports=calibration_data.imports(:,T_calibration);
    exports=calibration_data.exports(:,T_calibration);
    fixed_assets=calibration_data.fixed_assets(:,T_calibration);
    dwellings=calibration_data.dwellings(:,T_calibration);
    compensation_employees=calibration_data.compensation_employees(:,T_calibration);
    household_cash_quarterly=calibration_data.household_cash_quarterly(T_calibration_quarterly);
    property_income=calibration_data.property_income(T_calibration);
    mixed_income=calibration_data.mixed_income(T_calibration);
    operating_surplus=calibration_data.operating_surplus(:,T_calibration);
    firm_cash_quarterly=calibration_data.firm_cash_quarterly(T_calibration_quarterly);
    firm_debt_quarterly=calibration_data.firm_debt_quarterly(T_calibration_quarterly);
    % firm_interest_quarterly=calibration_data.firm_interest_quarterly(T_calibration_quarterly);
    government_debt_quarterly=calibration_data.government_debt_quarterly(T_calibration_quarterly);
    % interest_government_debt_quarterly=calibration_data.interest_government_debt_quarterly(T_calibration_quarterly);
    government_consumption=calibration_data.government_consumption(:,T_calibration);
    social_benefits=calibration_data.social_benefits(T_calibration);
    unemployment_benefits=calibration_data.unemployment_benefits(T_calibration);
    pension_benefits=calibration_data.pension_benefits(T_calibration);
    corporate_tax=calibration_data.corporate_tax(T_calibration);
    employers_social_contributions=calibration_data.compensation_employees(:,T_calibration)-calibration_data.wages(:,T_calibration);
    taxes_products_household=calibration_data.taxes_products_household(T_calibration);
    social_contributions=calibration_data.social_contributions(T_calibration);
    income_tax=calibration_data.income_tax(T_calibration);
    capital_taxes=calibration_data.capital_taxes(T_calibration);
    taxes_products_capitalformation_dwellings=calibration_data.taxes_products_capitalformation_dwellings(T_calibration);
    taxes_products_export=calibration_data.taxes_products_export(T_calibration);
    taxes_production=calibration_data.taxes_production(:,T_calibration);
    taxes_products_government=calibration_data.taxes_products_government(T_calibration);
    bank_equity_quarterly=calibration_data.bank_equity_quarterly(T_calibration_quarterly);
    taxes_products=calibration_data.taxes_products(:,T_calibration);
    % government_deficit_quarterly=calibration_data.government_deficit_quarterly(T_calibration_quarterly);
    firms=calibration_data.firms(:,T_calibration);
    employees=calibration_data.employees(:,T_calibration);
    inactive=calibration_data.inactive;
    unemployed=calibration_data.unemployed;
    timescale=data.nominal_gdp_quarterly(T_calibration_exo)/(sum(compensation_employees+operating_surplus+capital_consumption+taxes_production+taxes_products)+taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_government+taxes_products_export);
    scale=1/1000;
    omega=0.85;
    % r_bar=max(0,(data.euribor(T_calibration_exo)+1).^(1/4)-1);
    
    %% Set interest to zero for model to remain in steady state
    r_bar=0;
    firm_interest_quarterly=0;
    interest_government_debt_quarterly=0;
    government_deficit_quarterly=0;
    %%
    
    % Calculate variables from accounting indentities
    output=sum(intermediate_consumption)'+taxes_products+taxes_production+compensation_employees+operating_surplus+capital_consumption;
    fixed_capital_formation_other_than_dwellings=fixed_capitalformation-capitalformation_dwellings;
    imports=max(0,sum(intermediate_consumption,2)+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings*sum(capital_consumption)/sum(fixed_capital_formation_other_than_dwellings)+capitalformation_dwellings+exports-output);
    reexports=min(0,sum(intermediate_consumption,2)+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings*sum(capital_consumption)/sum(fixed_capital_formation_other_than_dwellings)+capitalformation_dwellings+exports-output);
    wages=compensation_employees*(1-sum(employers_social_contributions)/sum(compensation_employees));
    household_social_contributions=social_contributions-sum(employers_social_contributions);
    household_income_tax=income_tax-corporate_tax;
    other_net_transfers=sum(taxes_products_household)+sum(taxes_products_capitalformation_dwellings)+sum(taxes_products_export)+sum(taxes_products)+sum(taxes_production)+sum(employers_social_contributions)+household_social_contributions+household_income_tax+corporate_tax+capital_taxes-social_benefits-sum(government_consumption)-interest_government_debt_quarterly/timescale-government_deficit_quarterly/timescale;
    disposable_income=sum(wages)+mixed_income+property_income+social_benefits+other_net_transfers-household_social_contributions-household_income_tax-capital_taxes;
    fixed_assets_other_than_dwellings=fixed_assets-dwellings;
    
    % Scale number of firms and employees
    firms=max(1,round(scale*firms));
    employees=max(firms,round(scale*employees));
    inactive=max(1,round(scale*inactive));
    unemployed=max(1,round(scale*unemployed));
    
    % Sector parameters
    I_s=firms;
    alpha_s=timescale*output./employees;
    beta_s=output./sum(intermediate_consumption)';
    kappa_s=timescale*output./fixed_assets_other_than_dwellings/omega;
    delta_s=timescale*capital_consumption./fixed_assets_other_than_dwellings/omega;
    w_s=timescale*wages./employees;
    tau_Y_s=taxes_products./output;
    tau_K_s=taxes_production./output;
    b_CF_g=fixed_capital_formation_other_than_dwellings/sum(fixed_capital_formation_other_than_dwellings);
    b_CFH_g=capitalformation_dwellings/sum(capitalformation_dwellings);
    b_HH_g=household_consumption/sum(household_consumption);
    a_sg=intermediate_consumption./sum(intermediate_consumption);
    c_G_g=government_consumption/sum(government_consumption);
    c_E_g=(exports-reexports)/sum(exports-reexports);
    c_I_g=imports/sum(imports);
    
    % Parameters
    T_prime=T_calibration_exo-T_estimation_exo+1;
   12;
    T_max=T-max(0,T_calibration_exo+T-T_calibration_exo_max);
    G=length(intermediate_consumption);
    S=G;
    H_act=sum(employees)+unemployed+sum(firms)+1;
    H_inact=inactive;
    J=round(sum(firms)/4);
    L=round(sum(firms)/2);
    mu=firm_interest_quarterly/firm_debt_quarterly-r_bar;
    tau_INC=(household_income_tax+capital_taxes)/(sum(wages)+property_income+mixed_income-household_social_contributions);
    tau_FIRM=timescale*corporate_tax/(sum(max(0,timescale*operating_surplus-firm_interest_quarterly*fixed_assets_other_than_dwellings/sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly*max(0,operating_surplus)/sum(max(0,operating_surplus))))+firm_interest_quarterly-r_bar*(firm_debt_quarterly-bank_equity_quarterly));
    tau_VAT=taxes_products_household/sum(household_consumption);
    tau_SIF=sum(employers_social_contributions)/sum(wages);
    tau_SIW=household_social_contributions/sum(wages);
    tau_EXPORT=sum(taxes_products_export)/sum(exports-reexports);
    tau_CF=sum(taxes_products_capitalformation_dwellings)/sum(capitalformation_dwellings);
    tau_G=sum(taxes_products_government)/sum(government_consumption);
    psi=(sum(household_consumption)+sum(taxes_products_household))/disposable_income;
    psi_H=(sum(capitalformation_dwellings)+sum(taxes_products_capitalformation_dwellings))/disposable_income;
    theta_DIV=timescale*(mixed_income+property_income)/(sum(max(0,timescale*operating_surplus-firm_interest_quarterly*fixed_assets_other_than_dwellings/sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly*max(0,operating_surplus)/sum(max(0,operating_surplus))))+firm_interest_quarterly-r_bar*(firm_debt_quarterly-bank_equity_quarterly)-timescale*corporate_tax);
    r_G=interest_government_debt_quarterly/government_debt_quarterly;
    theta_UB=.55*(1-tau_INC)*(1-tau_SIW);
    theta=0.05;
    zeta=0.03;
    zeta_LTV=0.6;
    zeta_b=0.5;
    
    %% Set paramaters of AR(1) processes to zero (and one) for model to remain in steady state
    alpha_pi_EA=1;
    beta_pi_EA=0;
    sigma_pi_EA=0;
    alpha_Y_EA=1;
    beta_Y_EA=0;
    sigma_Y_EA=0;
    rho=1;
    r_star=0;
    xi_pi=0;
    xi_gamma=0;
    pi_star=0;
    alpha_G=1;
    beta_G=0;
    sigma_G=0;
    alpha_E=1;
    beta_E=0;
    sigma_E=0;
    alpha_I=1;
    beta_I=0;
    sigma_I=0;
    
    C=zeros(3);
    %%
    
    save(['../model/parameters/',num2str(year(calibration_date)),'Q',num2str(quarter(calibration_date)),'.mat'],'T','T_max','S','G','H_act','H_inact','J','L','tau_INC','tau_FIRM','tau_VAT','tau_SIF','tau_SIW','tau_EXPORT','tau_CF','tau_G','theta_UB','psi','psi_H','theta_DIV','theta','mu','r_G','zeta','zeta_LTV','zeta_b','I_s','alpha_s','beta_s','kappa_s','delta_s','w_s','tau_Y_s','tau_K_s','b_CF_g','b_CFH_g','b_HH_g','c_G_g','c_E_g','c_I_g','a_sg','T_prime','alpha_pi_EA','beta_pi_EA','sigma_pi_EA','alpha_Y_EA','beta_Y_EA','sigma_Y_EA','rho','r_star','xi_pi','xi_gamma','pi_star','alpha_G','beta_G','sigma_G','alpha_E','beta_E','sigma_E','alpha_I','beta_I','sigma_I','C');
    
    % Sector initial conditions
    N_s=employees;
    D_I=firm_cash_quarterly;
    L_I=firm_debt_quarterly;
    w_UB=timescale*unemployment_benefits/unemployed;
    sb_inact=timescale*pension_benefits/inactive;
    sb_other=timescale*(social_benefits+other_net_transfers-unemployment_benefits-pension_benefits)/(sum(employees)+unemployed+inactive+sum(firms)+1);
    D_H=household_cash_quarterly;
    K_H=sum(dwellings);
    L_G=government_debt_quarterly;
    E_k=bank_equity_quarterly;
    E_CB=L_G+L_I-D_I-D_H-E_k;
    D_RoW=0;
    
    % Initial conditions
    
    %% Create initial times series of inflation with only zeros (inflation) and with constant output of t0 for model to remain in steady state
    Y=timescale*sum(output)*ones(T_calibration_exo-T_estimation_exo+1,1);
    pi=zeros(T_calibration_exo-T_estimation_exo+1,1);
    %%
    
    Y_EA=ea.real_gdp_quarterly(T_calibration_exo);
    pi_EA=0;
    C_G=[timescale*sum(government_consumption)*data.real_government_consumption_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_government_consumption_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    C_E=[timescale*sum(exports-reexports)*data.real_exports_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_exports_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    Y_I=[timescale*sum(imports)*data.real_imports_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_imports_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    
    save(['../model/initial_conditions/',num2str(year(calibration_date)),'Q',num2str(quarter(calibration_date)),'.mat'],'D_I','L_I','omega','w_UB','sb_inact','sb_other','D_H','K_H','L_G','E_k','E_CB','D_RoW','N_s','Y','pi','Y_EA','pi_EA','r_bar','C_G','C_E','Y_I');
end
