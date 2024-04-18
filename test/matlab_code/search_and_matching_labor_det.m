function [N_i,O_h]=search_and_matching_labor_det(N_i,V_i,O_h)
H_E=find(O_h>0);
% H_E=H_E(randperm(length(H_E)));
% DETERMINISTIC VERSION: NO RANDOMIZATION

for e=1:length(H_E)
    h=H_E(e);
    i=O_h(h);
    if V_i(i)<0
        O_h(h)=0;
        N_i(i)=N_i(i)-1;
        V_i(i)=V_i(i)+1;
    end
end

H_U=find(O_h==0);
I_V=find(V_i>0);
while ~isempty(H_U) && ~isempty(I_V)
    % I_V=I_V(randperm(length(I_V)));
    % DETEMINISTIC VERSION: NO RANDOMIZATION

    for f=1:length(I_V)
        i=I_V(f);
        % e=randi(length(H_U));
        % DETEMINISTIC VERSION: NO RANDOMIZATION
        e=1;

        h=H_U(e);
        O_h(h)=i;
        N_i(i)=N_i(i)+1;
        V_i(i)=V_i(i)-1;
        H_U(e)=[];
        if isempty(H_U)
            break
        end
    end
    I_V=find(V_i>0);
end
end

