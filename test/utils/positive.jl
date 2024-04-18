using BeforeIT
using Test

@testset "test pos" begin
    a = [1, 2, 3, NaN, -1]
    @test pos(a) == [1, 2, 3, 0, 0]
    @test pos(1) == 1
    @test pos(-1) == 0
    @test pos(NaN) == 0
end

@testset "test neg" begin
    a = [1, 2, 3, NaN, -1]
    @test neg(a) == [0, 0, 0, 0, -1]
    @test neg(1) == 0
    @test neg(-1) == -1
    @test neg(NaN) == 0
end
