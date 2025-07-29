
import BeforeIT as Bit

using Test, Random

function Random.randn(n1::Int, n2::Int)
    return ones(n1, n2)
end

# Define a fixed covariance matrix
C = [2.0 0.5 0.3
     0.5 1.5 0.2
     0.3 0.2 1.0]

# results from original matlab code with rand = false
expected_eps_Y_EA = 1.4142135623731
expected_eps_E = 1.52615733054913
expected_eps_I = 1.29014186522609

eps_Y_EA, eps_E, eps_I = Bit.epsilon(C)

@test isapprox(eps_Y_EA, expected_eps_Y_EA)
@test isapprox(eps_E, expected_eps_E)
@test isapprox(eps_I, expected_eps_I)
