
import BeforeIT as Bit

using Test

@testset "test no shock" begin
    shock = Bit.NoShock()
    x = [1]
    shock(x)
    @test x == [1]
end

@testset "test time shock" begin
    mutable struct Foo
        r_bar::Any
    end
    mutable struct Agg
        t::Any
    end

    struct Bar
        cb::Any
        agg::Any
    end
    model = Bar(Foo(0.01), Agg(1))
    shock = Bit.InterestRateShock(0.02, 1)
    shock(model)
    @test model.cb.r_bar == 0.02
    model.cb.r_bar = 0.01
    model.agg.t = 2
    shock(model)
    @test model.cb.r_bar == 0.01
end
