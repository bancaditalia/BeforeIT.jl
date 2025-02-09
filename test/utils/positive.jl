
import BeforeIT as Bit
using Test

@testset "test pos" begin
    a = [1, 2, 3, NaN, -1]
    @test Bit.pos(a) == [1, 2, 3, 0, 0]
    @test Bit.pos(1) == 1
    @test Bit.pos(-1) == 0
    @test Bit.pos(NaN) == 0
end

@testset "test neg" begin
    a = [1, 2, 3, NaN, -1]
    @test Bit.neg(a) == [0, 0, 0, 0, -1]
    @test Bit.neg(1) == 0
    @test Bit.neg(-1) == -1
    @test Bit.neg(NaN) == 0
end
