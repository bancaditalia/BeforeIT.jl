
import BeforeIT as Bit

using Test

@testset "randpl" begin

    # Test if sum of the output is equal to N
    n, alpha, N = 48, 2.0, 123 # I_s(1) and N_s(1)
    x = Bit.randpl(n, alpha, N)
    @test sum(x) == N

    # Test if all elements are greater than or equal to 1
    @test all(x .>= 1)
end
