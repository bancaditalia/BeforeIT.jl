function [nominal_gdp,real_gdp,nominal_gva,real_gva,nominal_household_consumption,real_household_consumption, ...
    nominal_government_consumption,real_government_consumption,nominal_capitalformation,real_capitalformation, ...
    nominal_fixed_capitalformation,real_fixed_capitalformation,nominal_fixed_capitalformation_dwellings, ...
    real_fixed_capitalformation_dwellings,nominal_exports,real_exports,nominal_imports,real_imports, ...
    operating_surplus,compensation_employees,wages,taxes_production,nominal_sector_gva,real_sector_gva, ...
    euribor,gdp_deflator_growth_ea,real_gdp_ea,E_CB,D_RoW,L_G,D_k,D_i,D_h,E_k,L_i]=detabm(G,H_act,H_inact,J,L, ...
    tau_INC,tau_FIRM,tau_VAT,tau_SIF,tau_SIW,tau_EXPORT,tau_CF,tau_G,theta_UB,psi,psi_H,theta_DIV,theta,mu, ...
    r_G,zeta,zeta_LTV,zeta_b,alpha_bar_i,beta_i,kappa_i,delta_i,w_bar_i,tau_Y_i,tau_K_i,b_CF_g,b_CFH_g,b_HH_g, ...
    c_G_g,c_E_g,c_I_g,a_sg,G_i,T,T_prime,T_max,alpha_pi_EA,beta_pi_EA,sigma_pi_EA,alpha_Y_EA,beta_Y_EA, ...
    sigma_Y_EA,rho,r_star,xi_pi,xi_gamma,pi_star,alpha_G,beta_G,sigma_G,alpha_E,beta_E,sigma_E,alpha_I,beta_I, ...
    sigma_I,P_i,K_i,M_i,S_i,N_i,D_i,L_i,D_h,w_h,K_h,L_G,E_k,E_CB,D_RoW,O_h,sb_inact,sb_other,Y,pi,r_bar,Y_EA, ...
    pi_EA,C_G,C_E,Y_I,P_bar,P_bar_g,P_bar_HH,P_bar_CF,Q_d_i,Pi_i,Pi_k,D_k,C,E_i)
nominal_gdp=zeros(1,T);
real_gdp=zeros(1,T);
nominal_gva=zeros(1,T);
real_gva=zeros(1,T);
nominal_household_consumption=zeros(1,T);
real_household_consumption=zeros(1,T);
nominal_government_consumption=zeros(1,T);
real_government_consumption=zeros(1,T);
nominal_capitalformation=zeros(1,T);
real_capitalformation=zeros(1,T);
nominal_fixed_capitalformation=zeros(1,T);
real_fixed_capitalformation=zeros(1,T);
nominal_fixed_capitalformation_dwellings=zeros(1,T);
real_fixed_capitalformation_dwellings=zeros(1,T);
nominal_exports=zeros(1,T);
real_exports=zeros(1,T);
nominal_imports=zeros(1,T);
real_imports=zeros(1,T);
operating_surplus=zeros(1,T);
compensation_employees=zeros(1,T);
wages=zeros(1,T);
taxes_production=zeros(1,T);
nominal_sector_gva=zeros(T,G);
real_sector_gva=zeros(T,G);
euribor=zeros(1,T);
gdp_deflator_growth_ea=zeros(1,T);
real_gdp_ea=zeros(1,T);

for t=1:T
    disp("Timestep: "+t);

    %%% MOVED THIS TO THE BEGINNING TO HELP CONFRONTATION WITH JULIA VERSION (WHERE DATA IS SAVED AT THE END)
    insolvent=find(D_i<0 & E_i<0);
    for q=1:length(insolvent)
        i=insolvent(q);
        E_k=E_k-(L_i(i)-D_i(i)-zeta_b*P_bar_CF*K_i(i));
        E_i(i)=E_i(i)+(L_i(i)-D_i(i)-zeta_b*P_bar_CF*K_i(i));
        L_i(i)=zeta_b*P_bar_CF*K_i(i);
        D_i(i)=0;
    end


    [alpha_Y,beta_Y,epsilon_Y]=estimate(log(Y(1:T_prime+t-1)));
    epsilon_Y = 0; % DETERMINISTIC VERSION
    Y_e=exp(alpha_Y*log(Y(T_prime+t-1))+beta_Y+epsilon_Y);
    gamma_e=Y_e/Y(T_prime+t-1)-1;
    
    [alpha_pi,beta_pi,epsilon_pi]=estimate(pi(1:T_prime+t-1));
    epsilon_pi = 0; % DETERMINISTIC VERSION
    pi_e=exp(alpha_pi*pi(T_prime+t-1)+beta_pi+epsilon_pi)-1;
    
    disp("gamma_e")
    disp(string(gamma_e))
    disp("Y_e")
    disp(string(Y_e))


    if sum(C)>0.0001
        [epsilon_Y_EA,epsilon_E,epsilon_I]=epsilon(C);
        epsilon_I = 0; % DETERMINISTIC VERSION
        epsilon_E = 0; % DETERMINISTIC VERSION
        epsilon_Y_EA = 0; % DETERMINISTIC VERSION
    else
        epsilon_Y_EA = 0.0;
        epsilon_E = 0.0;
        epsilon_I = 0.0;
    end 

    gamma_EA=exp(alpha_Y_EA*log(Y_EA)+beta_Y_EA+epsilon_Y_EA)/Y_EA-1;
    Y_EA=exp(alpha_Y_EA*log(Y_EA)+beta_Y_EA+epsilon_Y_EA);
    

    disp("gamma_EA")
    disp(string(gamma_EA))
    disp("Y_EA")
    disp(string(Y_EA))

    % epsilon_pi_EA=normrnd(0,sigma_pi_EA); 
    epsilon_pi_EA=0; % DETERMINISTIC VERSION

    pi_EA=exp(alpha_pi_EA*log(1+pi_EA)+beta_pi_EA+epsilon_pi_EA)-1;
    
    disp("pi_EA")
    disp(string(pi_EA))

    r_bar=rho*r_bar+(1-rho)*(r_star+pi_star+xi_pi*(pi_EA-pi_star)+xi_gamma*gamma_EA);
    r=r_bar+mu;

    disp("r_bar")
    disp(string(r_bar))
    disp("r")
    disp(string(r))


    Q_s_i=Q_d_i*(1+gamma_e);
    disp("Q_s_i")
    disp(string(mean(Q_s_i)))

    pi_c_i=(1+tau_SIF).*w_bar_i./alpha_bar_i.*(P_bar_HH./P_i-1)+1./beta_i.*(sum(a_sg(:,G_i).*P_bar_g)./P_i-1)+delta_i./kappa_i.*(P_bar_CF./P_i-1);
    P_i=P_i.*(1+pi_c_i)*(1+pi_e);
    disp("P_i")
    disp(string(mean(P_i)))
    
    I_d_i=delta_i./kappa_i.*min(Q_s_i,K_i.*kappa_i);
    disp("I_d_i")
    disp(string(mean(I_d_i)))


    DM_d_i=min(Q_s_i,K_i.*kappa_i)./beta_i;
    disp("DM_d_i")
    disp(string(mean(DM_d_i)))


    N_d_i=max(1,round(min(Q_s_i,K_i.*kappa_i)./alpha_bar_i));
    disp("N_d_i")
    disp(string(mean(N_d_i)))

    Pi_e_i=Pi_i*(1+pi_e)*(1+gamma_e);
    disp("Pi_e_i")
    disp(string(mean(Pi_e_i)))


    DD_e_i=Pi_e_i-theta*L_i-tau_FIRM*max(0,Pi_e_i)-(theta_DIV*(1-tau_FIRM))*max(0,Pi_e_i);
    DL_d_i=max(0,-DD_e_i-D_i);
    disp("DL_d_i")
    disp(string(mean(DL_d_i)))


    K_e_i=P_bar_CF*(1+pi_e)*K_i;
    L_e_i=(1-theta)*L_i;
    disp("K_e_i")
    disp(string(mean(K_e_i)))
    disp("L_e_i")
    disp(string(mean(L_e_i)))


    % DETERMINISTIC VERSION
    DL_i=search_and_matching_credit_det(DL_d_i,K_e_i,L_e_i,E_k,zeta,zeta_LTV); 
    %mean(DL_i[DL_i .> 0]
    disp("DL_i")
    disp(string(mean(DL_i(DL_i > 0))))

    V_i=N_d_i-N_i;
    disp("V_i")
    disp(string(mean(V_i)))

    % DETERMINISTIC VERSION
    [N_i,O_h]=search_and_matching_labor_det(N_i,V_i,O_h); 
    
    w_i=w_bar_i.*min(1.5,min(Q_s_i,min(K_i.*kappa_i,M_i.*beta_i))./(N_i.*alpha_bar_i));
    alpha_i=alpha_bar_i.*min(1.5,min(Q_s_i,min(K_i.*kappa_i,M_i.*beta_i))./(N_i.*alpha_bar_i));
    disp("w_i")
    disp(string(mean(w_i)))

    Y_i=min(Q_s_i,min(N_i.*alpha_i,min(K_i.*kappa_i,M_i.*beta_i)));
    disp("Y_i")
    disp(string(mean(Y_i)))


    I=length(G_i);
    H_W=H_act-I-1;
    for h=1:H_W
       i=O_h(h);
       if i~=0
          w_h(h)=w_i(i);
       end
    end
    disp("w_h")
    disp(string(mean(w_h)))

    
    sb_other=sb_other*(1+gamma_e);
    sb_inact=sb_inact*(1+gamma_e);
    disp("sb_other")
    disp(string(sb_other))
    disp("sb_inact")
    disp(string(sb_inact))


    Pi_e_k=Pi_k*(1+pi_e)*(1+gamma_e);
    disp("Pi_e_k")
    disp(string(Pi_e_k))


    H=H_act+H_inact;
    Y_e_h=zeros(1,H);
    for h=1:H
        if h<=H_W
            if O_h(h)~=0
                Y_e_h(h)=(w_h(h)*(1-tau_SIW-tau_INC*(1-tau_SIW))+sb_other)*P_bar_HH*(1+pi_e);
            else
                Y_e_h(h)=(theta_UB*w_h(h)+sb_other)*P_bar_HH*(1+pi_e);
            end
        elseif h>H_W && h<=H_W+H_inact
            Y_e_h(h)=(sb_inact+sb_other)*P_bar_HH*(1+pi_e);
        elseif h>H_W+H_inact && h<=H_W+H_inact+I
            i=h-(H_W+H_inact);
            Y_e_h(h)=theta_DIV*(1-tau_INC)*(1-tau_FIRM)*max(0,Pi_e_i(i))+sb_other*P_bar_HH*(1+pi_e);
        elseif h>H_W+H_inact+I && h<=H
            Y_e_h(h)=theta_DIV*(1-tau_INC)*(1-tau_FIRM)*max(0,Pi_e_k)+sb_other*P_bar_HH*(1+pi_e);
        end
    end
    
    C_d_h=(psi*Y_e_h)/(1+tau_VAT);
    
    I_d_h=psi_H*Y_e_h/(1+tau_CF);
    
    disp("C_d_h")
    disp(string(sum(C_d_h)))
    disp("I_d_h")
    disp(string(sum(I_d_h)))


    % epsilon_G=normrnd(0,sigma_G); 
    epsilon_G=0; % DETERMINISTIC VERSION

    C_G=exp(alpha_G*log(C_G)+beta_G+epsilon_G);
    disp("C_G")
    disp(string(C_G))

    C_d_j=C_G/J*ones(1,J)*sum(c_G_g.*P_bar_g)*(1+pi_e);
    disp("C_d_j")
    disp(string(mean(C_d_j)))

    C_E=exp(alpha_E*log(C_E)+beta_E+epsilon_E);
    disp("C_E")
    disp(string(C_E))
    C_d_l=C_E/L*ones(1,L)*sum(c_E_g.*P_bar_g)*(1+pi_e);
    disp("C_d_l")
    disp(string(mean(C_d_l)))

    Y_I=exp(alpha_I*log(Y_I)+beta_I+epsilon_I);
    disp("Y_I")
    disp(string(Y_I))

    Y_m=c_I_g'*Y_I;
    disp("Y_m")
    disp(string(mean(Y_m)))
    
    P_m=P_bar_g'*(1+pi_e);
    disp("P_m")
    disp(string(mean(P_m)))

    % DETERMINISTIC VERSION
    [Q_d_i,Q_d_m,P_bar_i,DM_i,P_CF_i,I_i,P_bar_h,C_h,P_bar_CF_h,I_h,P_j,C_j,P_l,C_l]=search_and_matching_det(P_i,Y_i,S_i,K_i.*kappa_i-Y_i,G_i,P_m,Y_m,a_sg,DM_d_i,b_CF_g,I_d_i,P_bar_g.*b_HH_g/sum(P_bar_g.*b_HH_g),C_d_h,P_bar_g.*b_CFH_g/sum(P_bar_g.*b_CFH_g),I_d_h,P_bar_g.*c_G_g/sum(P_bar_g.*c_G_g),C_d_j,P_bar_g.*c_E_g/sum(P_bar_g.*c_E_g),C_d_l);
    

    Q_i=min(Y_i+S_i,Q_d_i);
    Q_m=min(Y_m,Q_d_m);
    K_h=K_h+I_h;
    
    disp("Q_d_i")
    disp(string(mean(Q_d_i)))
    disp("Q_i")
    disp(string(mean(Q_i)))

    disp("Q_d_m")
    disp(string(mean(Q_d_m)))
    disp("Q_m")
    disp(string(mean(Q_m)))
    writematrix(Q_m, 'Q_m.txt')

    disp("P_bar_i")
    disp(string(mean(P_bar_i)))
    disp("DM_i")
    disp(string(mean(DM_i)))
    disp("P_CF_i")
    disp(string(mean(P_CF_i)))
    disp("I_i")
    disp(string(mean(I_i)))


    disp("C_h")
    disp(string(sum(C_h)))
    disp("I_h")
    disp(string(sum(I_h)))
    disp("K_h")
    disp(string(sum(K_h)))

    disp("P_bar_h")
    disp(string(mean(P_bar_h)))

    disp("C_j")
    disp(string(C_j))
    disp("P_j")
    disp(string(P_j))


    pi(T_prime+t)=log(sum(P_i.*Y_i)/sum(Y_i)/P_bar);
    P_bar=sum(P_i.*Y_i)/sum(Y_i);
    
    for g=1:G
        P_bar_g(g)=(sum(P_i(G_i==g).*Q_i(G_i==g))+P_m(g)*Q_m(g))/(sum(Q_i(G_i==g))+Q_m(g));
    end
    
    P_bar_CF=sum(b_CF_g.*P_bar_g);
    P_bar_HH=sum(b_HH_g.*P_bar_g);
    
    K_i=K_i-delta_i./kappa_i.*Y_i+I_i;
    disp("K_i")
    disp(string(mean(K_i)))

    M_i=M_i-Y_i./beta_i+DM_i;
	disp("M_i")
    disp(string(mean(M_i)))
    
    DS_i=Y_i-Q_i;
    disp("DS_i")
    disp(string(mean(DS_i)))

    S_i=S_i+DS_i;
    disp("S_i") 
    disp(string(mean(S_i)))

    
    Pi_i=P_i.*Q_i+P_i.*DS_i-(1+tau_SIF)*w_i.*N_i*P_bar_HH-1./beta_i.*P_bar_i.*Y_i-delta_i./kappa_i.*P_CF_i.*Y_i-tau_Y_i.*P_i.*Y_i-tau_K_i.*P_i.*Y_i-r*(L_i+max(0,-D_i))+r_bar*max(0,D_i);
    disp("Pi_i")
    disp(string(mean(Pi_i)))

    Pi_k=r*sum(L_i+max(0,-D_i))+r*sum(max(0,-D_h))+r_bar*max(0,D_k)-r_bar*sum(max(0,D_i))-r_bar*sum(max(0,D_h))-r_bar*max(0,-D_k);
    disp("Pi_k")
    disp(string(Pi_k))

    E_k=E_k+Pi_k-theta_DIV*(1-tau_FIRM)*max(0,Pi_k)-tau_FIRM*max(0,Pi_k);
    disp("E_k")
    disp(string(E_k))
    

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
    
    disp("Y_h")
    disp(string(sum(Y_h)))

    D_h=D_h+Y_h-(1+tau_VAT)*C_h-(1+tau_CF)*I_h+r_bar*max(0,D_h)-r*max(0,-D_h);
    disp("D_h")
    disp(string(sum(D_h)))

    
    pi_CB=r_G*L_G-r_bar*D_k;
    disp("pi_CB")
    disp(string(pi_CB))

    Y_G=(tau_SIF+tau_SIW)*sum(w_h(O_h~=0))*P_bar_HH+tau_INC*(1-tau_SIW)*P_bar_HH*sum(w_h(O_h~=0))+tau_VAT*sum(C_h)+tau_INC*(1-tau_FIRM)*theta_DIV*(sum(max(0,Pi_i))+max(0,Pi_k))+tau_FIRM*(sum(max(0,Pi_i))+max(0,Pi_k))+tau_CF*sum(I_h)+sum(tau_Y_i.*P_i.*Y_i)+sum(tau_K_i.*P_i.*Y_i)+tau_EXPORT*C_l;
    Pi_G=C_j+r_G*L_G+H_inact*sb_inact*P_bar_HH+theta_UB*sum(w_h(O_h==0))*P_bar_HH+H*sb_other*P_bar_HH-Y_G;
    L_G=L_G+Pi_G;
    disp("Y_G")
    disp(string(Y_G))
    disp("Pi_G")
    disp(string(Pi_G))
    disp("L_G")
    disp(string(L_G))

    

    DD_i=P_i.*Q_i-(1+tau_SIF)*w_i.*N_i*P_bar_HH-DM_i.*P_bar_i-P_CF_i.*I_i-tau_Y_i.*P_i.*Y_i-tau_K_i.*P_i.*Y_i-r*(L_i+max(0,-D_i))+r_bar*max(0,D_i)+DL_i-theta*L_i-tau_FIRM*max(0,Pi_i)-theta_DIV*(1-tau_FIRM)*max(0,Pi_i);
    D_i=D_i+DD_i;
    L_i=(1-theta)*L_i+DL_i;
    disp("M_i")
    disp(string(mean(M_i)))
    E_i=D_i+M_i.*sum(a_sg(:,G_i).*P_bar_g)+P_i.*S_i+P_bar_CF*K_i-L_i;

    disp(size(sum(a_sg(:,G_i).*P_bar_g)))
    disp(size(a_sg(:,G_i).*P_bar_g))
    disp(size(a_sg))
    disp(size(P_bar_g))
    disp("DD_i")
    disp(string(mean(DD_i)))
    disp("D_i")
    disp(string(mean(D_i)))
    disp("L_i")
    disp(string(mean(L_i)))
    disp("E_i")
    disp(string(mean(E_i)))



    E_CB=E_CB+pi_CB;
    D_RoW=D_RoW-(1+tau_EXPORT)*C_l+sum(P_m.*Q_m);
    D_k=sum(D_i)+sum(D_h)+E_k-sum(L_i);
    disp("E_CB")
    disp(string(E_CB))
    disp("D_RoW")
    disp(string(D_RoW))
    disp("D_k")
    disp(string(D_k))
    

    Y(T_prime+t)=sum(Y_i);
    
    nominal_gdp(t)=sum(tau_Y_i.*Y_i.*P_i)+tau_VAT*sum(C_h)+tau_CF*sum(I_h)+tau_G*C_j+tau_EXPORT*C_l+sum((1-tau_Y_i).*P_i.*Y_i)-sum(1./beta_i.*P_bar_i.*Y_i);
    real_gdp(t)=sum(Y_i.*((1-tau_Y_i)-1./beta_i))+sum(tau_Y_i.*Y_i)+tau_VAT*sum(C_h)/P_bar_h+tau_CF*sum(I_h)/P_bar_CF_h+tau_G*C_j/P_j+tau_EXPORT*C_l/P_l;
    nominal_gva(t)=sum((1-tau_Y_i).*P_i.*Y_i)-sum(1./beta_i.*P_bar_i.*Y_i);
    real_gva(t)=sum(Y_i.*((1-tau_Y_i)-1./beta_i));
    nominal_household_consumption(t)=(1+tau_VAT)*sum(C_h);
    real_household_consumption(t)=(1+tau_VAT)*sum(C_h)/P_bar_h;
    nominal_government_consumption(t)=(1+tau_G)*C_j;
    real_government_consumption(t)=(1+tau_G)*C_j/P_j;
    nominal_capitalformation(t)=sum(P_CF_i.*I_i)+(1+tau_CF)*sum(I_h)+sum(DS_i.*P_i)+sum(DM_i.*P_bar_i-1./beta_i.*P_bar_i.*Y_i);
    real_capitalformation(t)=sum(I_i)+(1+tau_CF)*sum(I_h)/P_bar_CF_h+sum(DM_i-Y_i./beta_i)+sum(DS_i);
    nominal_fixed_capitalformation(t)=sum(P_CF_i.*I_i)+(1+tau_CF)*sum(I_h);
    real_fixed_capitalformation(t)=sum(I_i)+(1+tau_CF)*sum(I_h)/P_bar_CF_h;
    nominal_fixed_capitalformation_dwellings(t)=(1+tau_CF)*sum(I_h);
    real_fixed_capitalformation_dwellings(t)=(1+tau_CF)*sum(I_h)/P_bar_CF_h;
    nominal_exports(t)=(1+tau_EXPORT)*C_l;
    real_exports(t)=(1+tau_EXPORT)*C_l/P_l;
    nominal_imports(t)=sum(P_m.*Q_m);
    real_imports(t)=sum(Q_m);
    operating_surplus(t)=sum(P_i.*Q_i+P_i.*DS_i-(1+tau_SIF)*w_i.*N_i*P_bar_HH-1./beta_i.*P_bar_i.*Y_i-tau_Y_i.*P_i.*Y_i-tau_K_i.*P_i.*Y_i);
    compensation_employees(t)=(1+tau_SIF)*sum(w_i.*N_i)*P_bar_HH;
    wages(t)=sum(w_i.*N_i)*P_bar_HH;
    taxes_production(t)=sum(tau_K_i.*Y_i.*P_i);
    
    for g=1:G
        nominal_sector_gva(t,g)=sum((1-tau_Y_i(G_i==g)).*P_i(G_i==g).*Y_i(G_i==g))-sum(1./beta_i(G_i==g).*P_bar_i(G_i==g).*Y_i(G_i==g));
        real_sector_gva(t,g)=sum(Y_i(G_i==g).*((1-tau_Y_i(G_i==g))-1./beta_i(G_i==g)));
    end
    
    euribor(t)=r_bar;
    gdp_deflator_growth_ea(t)=pi_EA;
    real_gdp_ea(t)=Y_EA;
    
    % save all the arrays above, starting from nominal_gdp and ending with real_gdp_ea, to a file
    filepath = fileparts(which('detabm'))
    save(fullfile(filepath,'output_t'+string(t)+'.mat'),'nominal_gdp','real_gdp','nominal_gva','real_gva', ...
    'nominal_household_consumption','real_household_consumption','nominal_government_consumption', ...
    'real_government_consumption','nominal_capitalformation','real_capitalformation', ...
    'nominal_fixed_capitalformation','real_fixed_capitalformation','nominal_fixed_capitalformation_dwellings', ...
    'real_fixed_capitalformation_dwellings','nominal_exports','real_exports','nominal_imports','real_imports', ...
    'operating_surplus','compensation_employees','wages','taxes_production','nominal_sector_gva', ...
    'real_sector_gva','euribor','gdp_deflator_growth_ea','real_gdp_ea');

    filepath = fileparts(which('detabm'))
    save(fullfile(filepath,'firms_t'+string(t)+'.mat'),'N_i','Y_i','Q_d_i','P_i','S_i','K_i','M_i','D_i','L_i','G_i', ...
        'alpha_bar_i','beta_i','kappa_i', 'w_bar_i', 'delta_i', 'tau_Y_i', 'tau_K_i', 'Pi_i', 'V_i',  'Y_h', 'D_h', ...
        'K_h', 'w_i', 'Q_i', 'I_i', 'E_i', 'P_bar_i', 'P_CF_i', 'DS_i', 'DM_i');
    save(fullfile(filepath,'bank_t'+string(t)+'.mat'), 'D_k', 'Pi_k', 'E_k', 'r');
    save(fullfile(filepath,'households_t'+string(t)+'.mat'), 'w_h', 'O_h', 'Y_h', 'D_h', 'K_h');
end

end
