import Distributions as Dist

using Distributions, LinearAlgebra

function epsilon(C::AbstractMatrix)
    if isapprox(C, zeros(size(C)), atol = 1.0e-8)
        return zeros(size(C, 1))
    end

    return rand(Dist.MvNormal(zeros(size(C, 1)), Symmetric(C)))
end

function set_epsilon!(model::Ark.World)

    C = BeforeIT.properties(model).product_coeffs.consumption_matrix

    epsilons = BeforeIT.epsilons(model)
    new_eps = epsilon(C)
    epsilons = Epsilons(new_eps...)
    epsilons.Y_EA = new_eps[1]
    epsilons.E = new_eps[2]
    return epsilons.I = new_eps[3]

end
