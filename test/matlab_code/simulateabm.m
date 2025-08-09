

function [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption,nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation,nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings,real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports,operating_surplus,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva,euribor,gdp_deflator_growth_ea,real_gdp_ea]=simulateabm(year,quarter,seed,predictors)
    rng(seed);
    T=1;%12*2;
    G=62;
    
    filepath = fileparts(which('simulateabm'))

    if year==2010
        if quarter==1
            % parameters=coder.load('./parameters/2010Q1.mat','G','H_act','H_inact','J','L','tau_INC','tau_FIRM','tau_VAT','tau_SIF','tau_SIW','tau_EXPORT','tau_CF','tau_G','theta_UB','psi','psi_H','theta_DIV','theta','mu','r_G','zeta','zeta_LTV','zeta_b','I_s','alpha_s','beta_s','kappa_s','delta_s','w_s','tau_Y_s','tau_K_s','b_CF_g','b_CFH_g','b_HH_g','c_G_g','c_E_g','c_I_g','a_sg','T','T_prime','T_max','alpha_pi_EA','beta_pi_EA','sigma_pi_EA','alpha_Y_EA','beta_Y_EA','sigma_Y_EA','rho','r_star','xi_pi','xi_gamma','pi_star','alpha_G','beta_G','sigma_G','alpha_E','beta_E','sigma_E','alpha_I','beta_I','sigma_I','C');
            % initial_conditions=coder.load('./initial_conditions/2010Q1.mat','D_H','D_I','D_RoW','E_CB','E_k','K_H','L_G','L_I','omega','sb_inact','sb_other','w_UB','N_s','Y','pi','Y_EA','pi_EA','r_bar','C_G','C_E','Y_I');
            
            parameters=coder.load(fullfile(filepath,'../../data/austria/parameters/2010Q1.mat'),'G','H_act','H_inact','J','L','tau_INC','tau_FIRM','tau_VAT','tau_SIF','tau_SIW','tau_EXPORT','tau_CF','tau_G','theta_UB','psi','psi_H','theta_DIV','theta','mu','r_G','zeta','zeta_LTV','zeta_b','I_s','alpha_s','beta_s','kappa_s','delta_s','w_s','tau_Y_s','tau_K_s','b_CF_g','b_CFH_g','b_HH_g','c_G_g','c_E_g','c_I_g','a_sg','T','T_prime','T_max','alpha_pi_EA','beta_pi_EA','sigma_pi_EA','alpha_Y_EA','beta_Y_EA','sigma_Y_EA','rho','r_star','xi_pi','xi_gamma','pi_star','alpha_G','beta_G','sigma_G','alpha_E','beta_E','sigma_E','alpha_I','beta_I','sigma_I','C');
            initial_conditions=coder.load(fullfile(filepath,'../../data/austria/initial_conditions/2010Q1.mat'),'D_H','D_I','D_RoW','E_CB','E_k','K_H','L_G','L_I','omega','sb_inact','sb_other','w_UB','N_s','Y','pi','Y_EA','pi_EA','r_bar','C_G','C_E','Y_I');
        else
            error('No data available for this quarter!');
        end
    else
        error('No data available for this year!');
    end
    
    % G=parameters.G;
    H_act=parameters.H_act;
    H_inact=parameters.H_inact;
    J=parameters.J;
    L=parameters.L;
    tau_INC=parameters.tau_INC;
    tau_FIRM=parameters.tau_FIRM;
    tau_VAT=parameters.tau_VAT;
    tau_SIF=parameters.tau_SIF;
    tau_SIW=parameters.tau_SIW;
    tau_EXPORT=parameters.tau_EXPORT;
    tau_CF=parameters.tau_CF;
    tau_G=parameters.tau_G;
    theta_UB=parameters.theta_UB;
    psi=parameters.psi;
    psi_H=parameters.psi_H;
    theta_DIV=parameters.theta_DIV;
    theta=parameters.theta;
    mu=parameters.mu;
    r_G=parameters.r_G;
    zeta=parameters.zeta;
    zeta_LTV=parameters.zeta_LTV;
    zeta_b=parameters.zeta_b;
    I_s=parameters.I_s;
    alpha_s=parameters.alpha_s;
    beta_s=parameters.beta_s;
    kappa_s=parameters.kappa_s;
    delta_s=parameters.delta_s;
    w_s=parameters.w_s;
    tau_Y_s=parameters.tau_Y_s;
    tau_K_s=parameters.tau_K_s;
    b_CF_g=parameters.b_CF_g;
    b_CFH_g=parameters.b_CFH_g;
    b_HH_g=parameters.b_HH_g;
    c_G_g=parameters.c_G_g;
    c_E_g=parameters.c_E_g;
    c_I_g=parameters.c_I_g;
    a_sg=parameters.a_sg;
    % T=parameters.T;
    T_prime=parameters.T_prime;
    T_max=parameters.T_max;
    alpha_pi_EA=parameters.alpha_pi_EA;
    beta_pi_EA=parameters.beta_pi_EA;
    sigma_pi_EA=parameters.sigma_pi_EA;
    alpha_Y_EA=parameters.alpha_Y_EA;
    beta_Y_EA=parameters.beta_Y_EA;
    sigma_Y_EA=parameters.sigma_Y_EA;
    rho=parameters.rho;
    r_star=parameters.r_star;
    xi_pi=parameters.xi_pi;
    xi_gamma=parameters.xi_gamma;
    pi_star=parameters.pi_star;
    alpha_G=parameters.alpha_G;
    beta_G=parameters.beta_G;
    sigma_G=parameters.sigma_G;
    alpha_E=parameters.alpha_E;
    beta_E=parameters.beta_E;
    sigma_E=parameters.sigma_E;
    alpha_I=parameters.alpha_I;
    beta_I=parameters.beta_I;
    sigma_I=parameters.sigma_I;
    C=parameters.C;
    
    I=sum(I_s);
    G_i=zeros(1,I);
    for g=1:G
        i=sum(I_s(1:g-1));
        j=I_s(g);
        G_i(i+1:i+j)=g;
    end
    
    alpha_bar_i=zeros(1,I);
    beta_i=zeros(1,I);
    kappa_i=zeros(1,I);
    w_bar_i=zeros(1,I);
    delta_i=zeros(1,I);
    tau_Y_i=zeros(1,I);
    tau_K_i=zeros(1,I);
    for i=1:I 
        g=G_i(i);
        alpha_bar_i(i)=alpha_s(g);
        beta_i(i)=beta_s(g);
        kappa_i(i)=kappa_s(g);
        delta_i(i)=delta_s(g);
        w_bar_i(i)=w_s(g);
        tau_Y_i(i)=tau_Y_s(g);
        tau_K_i(i)=tau_K_s(g);
    end
    
    Y=initial_conditions.Y;
    pi=initial_conditions.pi;
    r_bar=initial_conditions.r_bar;
    Y_EA=initial_conditions.Y_EA;
    pi_EA=initial_conditions.pi_EA;
    C_G=initial_conditions.C_G;
    C_E=initial_conditions.C_E;
    Y_I=initial_conditions.Y_I;
    
    Y=[Y;zeros(T,1)];
    pi=[pi;zeros(T,1)];
    
    D_H=initial_conditions.D_H;
    D_I=initial_conditions.D_I;
    D_RoW=initial_conditions.D_RoW;
    E_CB=initial_conditions.E_CB;
    E_k=initial_conditions.E_k;
    K_H=initial_conditions.K_H;
    L_G=initial_conditions.L_G;
    L_I=initial_conditions.L_I;
    omega=initial_conditions.omega;
    sb_inact=initial_conditions.sb_inact;
    sb_other=initial_conditions.sb_other;
    w_UB=initial_conditions.w_UB;
    N_s=initial_conditions.N_s;
    
    P_bar=1;
    P_bar_g=ones(G,1);
    P_bar_HH=1;
    P_bar_CF=1;
    
    N_i=zeros(1,I);
    % to_return = [Int(round(N / n)) for _ in 1:n]
    for g=1:G
        % N_i(G_i==g)=randpl(I_s(g),2,N_s(g)); 
        % DETERMINISTIC VERSION
        N_i(G_i==g) = randpl_det(I_s(g),2,N_s(g));
    end

    Y_i=alpha_bar_i.*N_i;
    Q_d_i=Y_i;
    P_i=ones(1,I);
    S_i=zeros(1,I);
    K_i=Y_i./(omega*kappa_i);
    M_i=Y_i./(omega*beta_i);
    L_i=L_I.*K_i/sum(K_i);
    
    pi_bar_i=1-(1+tau_SIF).*w_bar_i./alpha_bar_i-delta_i./kappa_i-1./beta_i-tau_K_i-tau_Y_i;
    D_i=D_I.*max(0,pi_bar_i.*Y_i)/sum(max(0,pi_bar_i.*Y_i));
    
    r=r_bar+mu;
    Pi_i=pi_bar_i.*Y_i-r*L_i+r_bar*max(0,D_i);
    
    Pi_k=mu*sum(L_i)+r_bar*E_k;
    
    H_W=H_act-I-1;
    w_h=zeros(1,H_W);
    O_h=zeros(1,H_W);
    V_i=N_i;
    h=1;
    for i=1:I
        while V_i(i)>0
            O_h(h)=i;
            w_h(h)=w_bar_i(i);
            V_i(i)=V_i(i)-1;
            h=h+1;
        end
    end
    w_h(O_h==0)=w_UB/theta_UB;
    
    H=H_act+H_inact;
    Y_h=zeros(1,H);
    for h=1:H
        if h<=H_W
            if O_h(h)~=0
                Y_h(h)=(w_h(h)*(1-tau_SIW-tau_INC*(1-tau_SIW))+sb_other)*P_bar_HH;
            else
                Y_h(h)=(theta_UB*w_h(h)+sb_other)*P_bar_HH;
            end
        elseif h>H_W && h<=H_W+H_inact
            Y_h(h)=(sb_inact+sb_other)*P_bar_HH;
        elseif h>H_W+H_inact && h<=H_W+H_inact+I
            i=h-(H_W+H_inact);
            Y_h(h)=theta_DIV*(1-tau_INC)*(1-tau_FIRM)*max(0,Pi_i(i))+sb_other*P_bar_HH;
        elseif h>H_W+H_inact+I && h<=H
            Y_h(h)=theta_DIV*(1-tau_INC)*(1-tau_FIRM)*max(0,Pi_k)+sb_other*P_bar_HH;
        end
    end
    
    D_h=D_H*Y_h/sum(Y_h);
    K_h=K_H*Y_h/sum(Y_h);
    
    D_k=sum(D_i)+sum(D_h)+E_k-sum(L_i);
    
    nominal_gdp=zeros(1,T+1);
    real_gdp=zeros(1,T+1);
    nominal_gva=zeros(1,T+1);
    real_gva=zeros(1,T+1);
    nominal_household_consumption=zeros(1,T+1);
    real_household_consumption=zeros(1,T+1);
    nominal_government_consumption=zeros(1,T+1);
    real_government_consumption=zeros(1,T+1);
    nominal_capitalformation=zeros(1,T+1);
    real_capitalformation=zeros(1,T+1);
    nominal_fixed_capitalformation=zeros(1,T+1);
    real_fixed_capitalformation=zeros(1,T+1);
    nominal_fixed_capitalformation_dwellings=zeros(1,T+1);
    real_fixed_capitalformation_dwellings=zeros(1,T+1);
    nominal_exports=zeros(1,T+1);
    real_exports=zeros(1,T+1);
    nominal_imports=zeros(1,T+1);
    real_imports=zeros(1,T+1);
    operating_surplus=zeros(1,T+1);
    compensation_employees=zeros(1,T+1);
    wages=zeros(1,T+1);
    taxes_production=zeros(1,T+1);
    nominal_sector_gva=zeros(T+1,G);
    real_sector_gva=zeros(T+1,G);
    euribor=zeros(1,T+1);
    gdp_deflator_growth_ea=zeros(1,T+1);
    real_gdp_ea=zeros(1,T+1);
    
    nominal_gdp(1)=sum(Y_i.*(1-1./beta_i))+sum(Y_h)*psi/(1/tau_VAT+1)+tau_G*C_G(T_prime)+sum(Y_h)*psi_H/(1/tau_CF+1)+tau_EXPORT*C_E(T_prime);
    real_gdp(1)=nominal_gdp(1);
    nominal_gva(1)=sum(Y_i.*((1-tau_Y_i)-1./beta_i));
    real_gva(1)=nominal_gva(1);
    nominal_household_consumption(1)=sum(Y_h)*psi;
    real_household_consumption(1)=nominal_household_consumption(1);
    nominal_government_consumption(1)=(1+tau_G)*C_G(T_prime);
    real_government_consumption(1)=nominal_government_consumption(1);
    nominal_capitalformation(1)=sum(Y_i.*delta_i./kappa_i)+sum(Y_h)*psi_H;
    real_capitalformation(1)=nominal_capitalformation(1);
    nominal_fixed_capitalformation(1)=nominal_capitalformation(1);
    real_fixed_capitalformation(1)=nominal_capitalformation(1);
    nominal_fixed_capitalformation_dwellings(1)=sum(Y_h)*psi_H;
    real_fixed_capitalformation_dwellings(1)=nominal_fixed_capitalformation_dwellings(1);
    nominal_exports(1)=(1+tau_EXPORT)*C_E(T_prime);
    real_exports(1)=nominal_exports(1);
    nominal_imports(1)=Y_I(T_prime);
    real_imports(1)=nominal_imports(1);
    operating_surplus(1)=sum(Y_i.*(1-((1+tau_SIF).*w_bar_i./alpha_bar_i+1./beta_i))-tau_K_i.*Y_i-tau_Y_i.*Y_i);
    compensation_employees(1)=(1+tau_SIF)*sum(w_bar_i.*N_i);
    wages(1)=sum(w_bar_i.*N_i);
    taxes_production(1)=sum(tau_K_i.*Y_i);
    
    for g=1:G
        nominal_sector_gva(1,g)=sum(Y_i(G_i==g).*((1-tau_Y_i(G_i==g))-1./beta_i(G_i==g)));
    end
    
    real_sector_gva(1,:)=nominal_sector_gva(1,:);
    euribor(1)=r_bar;
    gdp_deflator_growth_ea(1)=pi_EA;
    real_gdp_ea(1)=Y_EA;
    
    disp(predictors==true)
    disp(nominal_household_consumption)

    % export a number of variables to txt files in order to compare with the Julia version
    % specifically, export all variables that end with _i (i.e., the firms variables)
    % collect all variables in a matlab struct and write to a mat file
    save(fullfile(filepath,'init_vars_firms.mat'),'N_i','Y_i','Q_d_i','P_i','S_i','K_i','M_i','D_i','L_i','G_i', ...
    'alpha_bar_i','beta_i','kappa_i', 'w_bar_i', 'delta_i', 'tau_Y_i', 'tau_K_i', 'pi_bar_i', 'Pi_i', 'V_i', ...
    'Y_h', 'D_h', 'K_h');
    save(fullfile(filepath,'init_vars_bank.mat'), 'D_k', 'Pi_k', 'E_k', 'r')
    save(fullfile(filepath,'init_vars_households.mat'), 'w_h', 'O_h', 'Y_h', 'D_h', 'K_h');


    E_i = zeros(1,I); % DUMMY VARIABLE TO HELP CONFRONTATION WITH JULIA CODE
    % if predictors
    %     [nominal_gdp(2:T+1),real_gdp(2:T+1),nominal_gva(2:T+1),real_gva(2:T+1),nominal_household_consumption(2:T+1),real_household_consumption(2:T+1),nominal_government_consumption(2:T+1),real_government_consumption(2:T+1),nominal_capitalformation(2:T+1),real_capitalformation(2:T+1),nominal_fixed_capitalformation(2:T+1),real_fixed_capitalformation(2:T+1),nominal_fixed_capitalformation_dwellings(2:T+1),real_fixed_capitalformation_dwellings(2:T+1),nominal_exports(2:T+1),real_exports(2:T+1),nominal_imports(2:T+1),real_imports(2:T+1),operating_surplus(2:T+1),compensation_employees(2:T+1),wages(2:T+1),taxes_production(2:T+1),nominal_sector_gva(2:T+1,:),real_sector_gva(2:T+1,:),euribor(2:T+1),E_CB,D_RoW,L_G,D_k,D_i,D_h,E_k,L_i]=abmx(G,H_act,H_inact,J,L,tau_INC,tau_FIRM,tau_VAT,tau_SIF,tau_SIW,tau_EXPORT,tau_CF,tau_G,theta_UB,psi,psi_H,theta_DIV,theta,mu,r_G,zeta,zeta_LTV,zeta_b,alpha_bar_i,beta_i,kappa_i,delta_i,w_bar_i,tau_Y_i,tau_K_i,b_CF_g,b_CFH_g,b_HH_g,c_G_g,c_E_g,c_I_g,a_sg,G_i,T,T_prime,T_max,P_i,K_i,M_i,S_i,N_i,D_i,L_i,D_h,w_h,K_h,L_G,E_k,E_CB,D_RoW,O_h,sb_inact,sb_other,Y,pi,r_bar,C_G,C_E,Y_I,P_bar,P_bar_g,P_bar_HH,P_bar_CF,Q_d_i,Pi_i,Pi_k,D_k);
    % else
        [nominal_gdp(2:T+1),real_gdp(2:T+1),nominal_gva(2:T+1),real_gva(2:T+1),nominal_household_consumption(2:T+1), ...
        real_household_consumption(2:T+1),nominal_government_consumption(2:T+1),real_government_consumption(2:T+1), ...
        nominal_capitalformation(2:T+1),real_capitalformation(2:T+1),nominal_fixed_capitalformation(2:T+1), ...
        real_fixed_capitalformation(2:T+1),nominal_fixed_capitalformation_dwellings(2:T+1), ...
        real_fixed_capitalformation_dwellings(2:T+1),nominal_exports(2:T+1),real_exports(2:T+1), ...
        nominal_imports(2:T+1),real_imports(2:T+1),operating_surplus(2:T+1),compensation_employees(2:T+1), ...
        wages(2:T+1),taxes_production(2:T+1),nominal_sector_gva(2:T+1,:),real_sector_gva(2:T+1,:),euribor(2:T+1), ...
        gdp_deflator_growth_ea(2:T+1),real_gdp_ea(2:T+1),E_CB,D_RoW,L_G,D_k,D_i,D_h,E_k,L_i]=detabm(G,H_act,H_inact, ...
        J,L,tau_INC,tau_FIRM,tau_VAT,tau_SIF,tau_SIW,tau_EXPORT,tau_CF,tau_G,theta_UB,psi,psi_H,theta_DIV,theta,mu, ...
        r_G,zeta,zeta_LTV,zeta_b,alpha_bar_i,beta_i,kappa_i,delta_i,w_bar_i,tau_Y_i,tau_K_i,b_CF_g,b_CFH_g,b_HH_g, ...
        c_G_g,c_E_g,c_I_g,a_sg,G_i,T,T_prime,T_max,alpha_pi_EA,beta_pi_EA,sigma_pi_EA,alpha_Y_EA,beta_Y_EA, ...
        sigma_Y_EA,rho,r_star,xi_pi,xi_gamma,pi_star,alpha_G,beta_G,sigma_G,alpha_E,beta_E,sigma_E,alpha_I, ...
        beta_I,sigma_I,P_i,K_i,M_i,S_i,N_i,D_i,L_i,D_h,w_h,K_h,L_G,E_k,E_CB,D_RoW,O_h,sb_inact,sb_other,Y,pi, ...
        r_bar,Y_EA,pi_EA,C_G(T_prime),C_E(T_prime),Y_I(T_prime),P_bar,P_bar_g,P_bar_HH,P_bar_CF,Q_d_i,Pi_i,Pi_k, ...
        D_k,C, E_i);
    % end
    end
    
    