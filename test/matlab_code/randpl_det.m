% traslate the above function to MATLAB from julia
function x=randpl_det(n,alpha,N)
    x = zeros(1, n);
    for i=1:n
        x(i) = (round(N / n));
    end
end