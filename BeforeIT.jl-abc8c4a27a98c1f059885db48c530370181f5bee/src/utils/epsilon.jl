using LinearAlgebra, Random

function epsilon(C::Matrix{Float64})

    if isapprox(sum(C), 0, atol = 1e-8)
        return 0.0, 0.0, 0.0
    end

    L, _ = cholesky(C)

    # eps_ = rand ? randn(3, 1) : ones(3, 1)
    eps_ = randn(3, 1)
    eps_Y_EA = dot(L[1, :], eps_)
    eps_E = dot(L[2, :], eps_)
    eps_I = dot(L[3, :], eps_)
    return eps_Y_EA, eps_E, eps_I
end
