% Clear workspace
clear;

% Load calibration data
load('../data/calibration/2010Q1.mat','calibration_data');
load('../data/figaro/2010.mat','figaro');

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
estimation_date=datetime(1996,12,31); % for the AR processes

for calibration_date=start_calibration_date:calquarters:end_calibration_date
    
    % Variables and constants for calibration
    T_calibration=find(calibration_data.years_num==datenum(datetime(year(min(calibration_date,max_calibration_date)),12,31)));
    T_calibration_quarterly=find(calibration_data.quarters_num==datenum(calibration_date));
    T_estimation_exo=find(data.quarters_num==datenum(estimation_date));
    T_calibration_exo=find(data.quarters_num==datenum(calibration_date));
    T_calibration_exo_max=length(data.quarters_num);
    intermediate_consumption=figaro.intermediate_consumption(:,:,T_calibration);
    household_consumption=figaro.household_consumption(:,T_calibration);
    fixed_capitalformation=figaro.fixed_capitalformation(:,T_calibration);
    % capitalformation=figaro.capitalformation(:,T_calibration);
    % capital_consumption=figaro.capital_consumption(:,T_calibration);
    % imports=figaro.imports(:,T_calibration);
    exports=figaro.exports(:,T_calibration);
    compensation_employees=figaro.compensation_employees(:,T_calibration);
    household_cash_quarterly=calibration_data.household_cash_quarterly(T_calibration_quarterly);
    property_income=calibration_data.property_income(T_calibration);
    mixed_income=calibration_data.mixed_income(T_calibration);
    operating_surplus=figaro.operating_surplus(:,T_calibration);
    firm_cash_quarterly=calibration_data.firm_cash_quarterly(T_calibration_quarterly);
    firm_debt_quarterly=calibration_data.firm_debt_quarterly(T_calibration_quarterly);
    % firm_interest_quarterly=calibration_data.firm_interest_quarterly(T_calibration_quarterly);
    firm_interest=calibration_data.firm_interest(T_calibration);
    government_debt_quarterly=calibration_data.government_debt_quarterly(T_calibration_quarterly);
    % interest_government_debt_quarterly=calibration_data.interest_government_debt_quarterly(T_calibration_quarterly);
    interest_government_debt=calibration_data.interest_government_debt(T_calibration);
    government_consumption=figaro.government_consumption(:,T_calibration);
    social_benefits=calibration_data.social_benefits(T_calibration);
    unemployment_benefits=calibration_data.unemployment_benefits(T_calibration);
    pension_benefits=calibration_data.pension_benefits(T_calibration);
    corporate_tax=calibration_data.corporate_tax(T_calibration);
    % wages=figaro.wages(:,T_calibration);
    wages=calibration_data.wages(T_calibration);
    taxes_products_household=figaro.taxes_products_household(T_calibration);
    social_contributions=calibration_data.social_contributions(T_calibration);
    income_tax=calibration_data.income_tax(T_calibration);
    capital_taxes=calibration_data.capital_taxes(T_calibration);
    taxes_products_fixed_capitalformation=figaro.taxes_products_capitalformation(T_calibration);
    % taxes_products_export=figaro.taxes_products_export(T_calibration);
    taxes_production=figaro.taxes_production(:,T_calibration);
    taxes_products_government=figaro.taxes_products_government(T_calibration);
    bank_equity_quarterly=calibration_data.bank_equity_quarterly(T_calibration_quarterly);
    taxes_products=figaro.taxes_products(:,T_calibration);
    % government_deficit_quarterly=calibration_data.government_deficit_quarterly(T_calibration_quarterly);
    government_deficit=calibration_data.government_deficit(T_calibration);
    firms=calibration_data.firms(:,T_calibration);
    employees=calibration_data.employees(:,T_calibration);
    % inactive=calibration_data.inactive(T_calibration);
    population=calibration_data.population(T_calibration);
    % unemployed=calibration_data.unemployed(T_calibration);
    r_bar=(data.euribor(T_calibration_exo)+1).^(1/4)-1;
    scale=1/1000;
    omega=0.85;
    fixed_assets=calibration_data.fixed_assets(T_calibration);
    dwellings=calibration_data.dwellings(T_calibration);
    fixed_assets_eu7=calibration_data.fixed_assets_eu7(:,T_calibration);
    dwellings_eu7=calibration_data.dwellings_eu7(:,T_calibration);
    nominal_nace64_output_eu7=calibration_data.nominal_nace64_output_eu7(:,T_calibration);
    gross_capitalformation_dwellings=calibration_data.gross_capitalformation_dwellings(T_calibration);
    nace64_capital_consumption=calibration_data.nace64_capital_consumption(:,T_calibration);
    nominal_nace64_output=calibration_data.nominal_nace64_output(:,T_calibration);
    unemployment_rate_quarterly=data.unemployment_rate_quarterly(T_calibration_exo);
    
    % Calculate variables from accounting indentities
    output=sum(intermediate_consumption)'+taxes_products+taxes_production+compensation_employees+operating_surplus;%+capital_consumption;
    capital_consumption=nace64_capital_consumption./nominal_nace64_output.*output;
    operating_surplus=operating_surplus-capital_consumption;
    taxes_products_export=0;
    employers_social_contributions=min(social_contributions,sum(compensation_employees)-wages);
    fixed_capitalformation=max(0,fixed_capitalformation);
    taxes_products_capitalformation_dwellings=gross_capitalformation_dwellings*(1-1/(1+taxes_products_fixed_capitalformation/sum(fixed_capitalformation)));
    timescale=data.nominal_gdp_quarterly(T_calibration_exo)/(sum(compensation_employees+operating_surplus+capital_consumption+taxes_production+taxes_products)+taxes_products_household+taxes_products_capitalformation_dwellings+taxes_products_government+taxes_products_export);
    fixed_assets_other_than_dwellings=(fixed_assets-dwellings)*((fixed_assets_eu7-dwellings_eu7)./nominal_nace64_output_eu7.*output)/sum((fixed_assets_eu7-dwellings_eu7)./nominal_nace64_output_eu7.*output);
    capitalformation_dwellings=(gross_capitalformation_dwellings-taxes_products_capitalformation_dwellings)*fixed_capitalformation/sum(fixed_capitalformation);
    fixed_capital_formation_other_than_dwellings=fixed_capitalformation-capitalformation_dwellings;
    exports=max(0,exports);
    imports=max(0,sum(intermediate_consumption,2)+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings*sum(capital_consumption)/sum(fixed_capital_formation_other_than_dwellings)+capitalformation_dwellings+exports-output);
    reexports=min(0,sum(intermediate_consumption,2)+household_consumption+government_consumption+fixed_capital_formation_other_than_dwellings*sum(capital_consumption)/sum(fixed_capital_formation_other_than_dwellings)+capitalformation_dwellings+exports-output);
    household_social_contributions=social_contributions-employers_social_contributions;
    wages=compensation_employees*(1-employers_social_contributions/sum(compensation_employees));
    household_income_tax=income_tax-corporate_tax;
    other_net_transfers=max(0,sum(taxes_products_household)+sum(taxes_products_capitalformation_dwellings)+sum(taxes_products_export)+sum(taxes_products)+sum(taxes_production)+employers_social_contributions+household_social_contributions+household_income_tax+corporate_tax+capital_taxes-social_benefits-sum(government_consumption)-interest_government_debt-government_deficit);
    disposable_income=sum(wages)+mixed_income+property_income+social_benefits+other_net_transfers-household_social_contributions-household_income_tax-capital_taxes;
    unemployed=round(unemployment_rate_quarterly*sum(employees));
    inactive=population-sum(max(max(1,firms),employees))-unemployed-sum(max(1,firms))-1;
    
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
    delta_s=fillmissing(timescale*capital_consumption./fixed_assets_other_than_dwellings/omega,'constant',0);
    w_s=timescale*wages./employees;
    tau_Y_s=taxes_products./output;
    tau_K_s=taxes_production./output;
    b_CF_g=fixed_capital_formation_other_than_dwellings/sum(fixed_capital_formation_other_than_dwellings);
    b_CFH_g=capitalformation_dwellings/sum(capitalformation_dwellings);
    b_HH_g=household_consumption/sum(household_consumption);
    a_sg=fillmissing(intermediate_consumption./sum(intermediate_consumption),'constant',0);
    c_G_g=government_consumption/sum(government_consumption);
    c_E_g=(exports-reexports)/sum(exports-reexports);
    c_I_g=imports/sum(imports);
    
    % Parameters
    T_prime=T_calibration_exo-T_estimation_exo+1;
    T=12;
    T_max=T-max(0,T_calibration_exo+T-T_calibration_exo_max);
    G=length(intermediate_consumption);
    S=G;
    H_act=sum(employees)+unemployed+sum(firms)+1;
    H_inact=inactive;
    J=round(sum(firms)/4);
    L=round(sum(firms)/2);
    mu=timescale*firm_interest/firm_debt_quarterly-r_bar;
    tau_INC=(household_income_tax+capital_taxes)/(sum(wages)+property_income+mixed_income-household_social_contributions);
    tau_FIRM=timescale*corporate_tax/(sum(max(0,timescale*operating_surplus-timescale*firm_interest*fixed_assets_other_than_dwellings/sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly*max(0,operating_surplus)/sum(max(0,operating_surplus))))+timescale*firm_interest-r_bar*(firm_debt_quarterly-bank_equity_quarterly));
    tau_VAT=taxes_products_household/sum(household_consumption);
    tau_SIF=employers_social_contributions/sum(wages);
    tau_SIW=household_social_contributions/sum(wages);
    tau_EXPORT=sum(taxes_products_export)/sum(exports-reexports);
    tau_CF=sum(taxes_products_capitalformation_dwellings)/sum(capitalformation_dwellings);
    tau_G=sum(taxes_products_government)/sum(government_consumption);
    psi=(sum(household_consumption)+sum(taxes_products_household))/disposable_income;
    psi_H=(sum(capitalformation_dwellings)+sum(taxes_products_capitalformation_dwellings))/disposable_income;
    theta_DIV=timescale*(mixed_income+property_income)/(sum(max(0,timescale*operating_surplus-timescale*firm_interest*fixed_assets_other_than_dwellings/sum(fixed_assets_other_than_dwellings)+r_bar*firm_cash_quarterly*max(0,operating_surplus)/sum(max(0,operating_surplus))))+timescale*firm_interest-r_bar*(firm_debt_quarterly-bank_equity_quarterly)-timescale*corporate_tax);
    r_G=timescale*interest_government_debt/government_debt_quarterly;
    theta_UB=.55*(1-tau_INC)*(1-tau_SIW);
    theta=0.05;
    zeta=0.03;
    zeta_LTV=0.6;
    zeta_b=0.5;
    [alpha_pi_EA,beta_pi_EA,sigma_pi_EA,epsilon_pi_EA]=estimate(diff(log(ea.gdp_deflator_quarterly(T_estimation_exo-1:T_calibration_exo))));
    [alpha_Y_EA,beta_Y_EA,sigma_Y_EA,epsilon_Y_EA]=estimate(log(ea.real_gdp_quarterly(T_estimation_exo:T_calibration_exo)));
    [rho,r_star,xi_pi,xi_gamma,pi_star]=estimate_taylor_rule((data.euribor(T_estimation_exo:T_calibration_exo)+1).^(1/4)-1,exp(diff(log(ea.gdp_deflator_quarterly(T_estimation_exo-1:T_calibration_exo))))-1,exp(diff(log(ea.real_gdp_quarterly(T_estimation_exo-1:T_calibration_exo))))-1);
    [alpha_G,beta_G,sigma_G,epsilon_G]=estimate(log(timescale*sum(government_consumption)*data.real_government_consumption_quarterly(T_estimation_exo:T_calibration_exo)/data.real_government_consumption_quarterly(T_calibration_exo)));
    [alpha_E,beta_E,sigma_E,epsilon_E]=estimate(log(timescale*sum(exports-reexports)*data.real_exports_quarterly(T_estimation_exo:T_calibration_exo)/data.real_exports_quarterly(T_calibration_exo)));
    [alpha_I,beta_I,sigma_I,epsilon_I]=estimate(log(timescale*sum(imports)*data.real_imports_quarterly(T_estimation_exo:T_calibration_exo)/data.real_imports_quarterly(T_calibration_exo)));
    
    C=cov([epsilon_Y_EA,epsilon_E,epsilon_I]);
    
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
    Y=timescale*sum(output)*data.real_gdp_quarterly(T_estimation_exo:T_calibration_exo)/data.real_gdp_quarterly(T_calibration_exo);
    pi=diff(log(data.gdp_deflator_quarterly(T_estimation_exo-1:T_calibration_exo)));
    Y_EA=ea.real_gdp_quarterly(T_calibration_exo);
    pi_EA=ea.gdp_deflator_quarterly(T_calibration_exo)/ea.gdp_deflator_quarterly(T_calibration_exo-1)-1;
    C_G=[timescale*sum(government_consumption)*data.real_government_consumption_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_government_consumption_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    C_E=[timescale*sum(exports-reexports)*data.real_exports_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_exports_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    Y_I=[timescale*sum(imports)*data.real_imports_quarterly(T_estimation_exo:min(T_calibration_exo+T,T_calibration_exo_max))/data.real_imports_quarterly(T_calibration_exo);nan(max(0,T_calibration_exo+T-T_calibration_exo_max),1)];
    
    save(['../model/initial_conditions/',num2str(year(calibration_date)),'Q',num2str(quarter(calibration_date)),'.mat'],'D_I','L_I','omega','w_UB','sb_inact','sb_other','D_H','K_H','L_G','E_k','E_CB','D_RoW','N_s','Y','pi','Y_EA','pi_EA','r_bar','C_G','C_E','Y_I');
end
