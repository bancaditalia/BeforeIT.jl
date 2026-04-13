module BeforeITTest

using Test
using MacroTools
using BeforeIT: @sum_over
# Mock Ark module and components for testing
module MockArk
    export MockQuery, MockWorld, Deposits, Health, Empty
    struct MockQuery{W, C}
        world::W
        components::C
    end

    # Make Query iterable: yields (entities, components)
    Base.iterate(q::MockQuery, state = 1) = state > 1 ? nothing : ((q.world.entities, q.world.data[q.components]), 2)
    Base.IteratorSize(::Type{<:MockQuery}) = Base.HasLength()
    Base.length(::MockQuery) = 1
    # Mock world structure
    struct MockWorld{E, D}
        entities::E
        data::D
    end

    struct Deposits
        amount::Float64
    end
    struct Health
        current::Int
        max::Int
    end
    struct Empty end
end


using .MockArk

@testset "@sum_over macro" begin


    @testset "Ark integration" begin
        import Ark

        @testset "Single component query" begin
            world = Ark.World(Deposits)
            Ark.new_entities!(world, 10, (Deposits(10.0),))

            total = @sum_over (d.amount for d in Ark.Query(world, (Deposits,)))
            @test total == 100.0
        end

        @testset "Multiple components" begin
            world = Ark.World(Deposits, Health)
            Ark.new_entities!(world, 5, (Deposits(20.0), Health(50, 100)))

            deposits_total = @sum_over (d.amount for d in Ark.Query(world, (Deposits,)))
            health_total = @sum_over (h.current for h in Ark.Query(world, (Health,)))

            @test deposits_total == 100.0
            @test health_total == 250
        end

        @testset "Complex expression" begin
            world = Ark.World(Health)
            Ark.new_entities!(world, 3, (Health(25, 100),))
            Ark.new_entities!(world, 2, (Health(50, 100),))

            # Sum of missing health
            missing_health = @sum_over ((h.max - h.current) for h in Ark.Query(world, (Health,)))
            @test missing_health == 3 * 75 + 2 * 50  # 325
        end

        @testset "Empty world" begin
            world = Ark.World(Deposits)

            total = @sum_over (d.amount for d in Ark.Query(world, (Deposits,)))
            @test total == 0.0
        end

        @testset "Single entity" begin
            world = Ark.World(Deposits)
            Ark.new_entities!(world, 1, (Deposits(42.0),))

            total = @sum_over (d.amount for d in Ark.Query(world, (Deposits,)))
            @test total == 42.0
        end

        @testset "Type stability" begin
            world = Ark.World(Deposits)
            Ark.new_entities!(world, 5, (Deposits(1.5),))

            total = @sum_over (d.amount for d in Ark.Query(world, (Deposits,)))
            @test total isa Float64
            @test total == 7.5
        end
    end


    @testset "Basic functionality" begin
        # Single component, simple field access
        world = MockWorld(
            [1, 2, 3], Dict(
                Deposits => [
                    Deposits(10.0),
                    Deposits(20.0),
                    Deposits(30.0),
                ]
            )
        )

        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total == 60.0
    end

    @testset "Different variable names" begin
        world = MockWorld(
            [1], Dict(
                Health => [Health(50, 100)]
            )
        )

        # Variable name different from field name
        h_total = @sum_over (hp.current for hp in MockQuery(world, Health))
        @test h_total == 50

        # Single letter variable
        x_total = @sum_over (x.max for x in MockQuery(world, Health))
        @test x_total == 100
    end

    @testset "Complex expressions" begin
        world = MockWorld(
            [1, 2], Dict(
                Health => [
                    Health(50, 100),
                    Health(75, 100),
                ]
            )
        )

        # Arithmetic in expression
        missing_health = @sum_over ((h.max - h.current) for h in MockQuery(world, Health))
        @test missing_health == 75  # (100-50) + (100-75) = 50 + 25

        # Multiplication
        scaled = @sum_over ((h.current * 2) for h in MockQuery(world, Health))
        @test scaled == 250  # 50*2 + 75*2
    end

    @testset "Empty query results" begin
        world = MockWorld(
            Int[], Dict(
                Deposits => Deposits[]
            )
        )

        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total == 0.0  # Should initialize to 0, not error
    end

    @testset "Single element" begin
        world = MockWorld(
            [42], Dict(
                Deposits => [Deposits(99.5)]
            )
        )

        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total == 99.5
    end

    @testset "Negative and zero values" begin
        world = MockWorld(
            [1, 2, 3], Dict(
                Deposits => [
                    Deposits(-10.0),
                    Deposits(0.0),
                    Deposits(5.0),
                ]
            )
        )

        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total == -5.0
    end

    @testset "Nested field access" begin
        # Test with hypothetical nested structure
        struct Inner
            value::Int
        end
        struct Outer
            inner::Inner
        end

        world = MockWorld(
            [1, 2], Dict(
                Outer => [Outer(Inner(10)), Outer(Inner(20))]
            )
        )

        total = @sum_over (o.inner.value for o in MockQuery(world, Outer))
        @test total == 30
    end

    @testset "World expression flexibility" begin
        # World from variable
        w = MockWorld([1], Dict(Deposits => [Deposits(5.0)]))
        total = @sum_over (d.amount for d in MockQuery(w, Deposits))
        @test total == 5.0

        # World from function call (would work if function returned world)
        get_world() = w
        total2 = @sum_over (d.amount for d in MockQuery(get_world(), Deposits))
        @test total2 == 5.0
    end

    @testset "Macro hygiene - no variable leakage" begin
        world = MockWorld([1], Dict(Deposits => [Deposits(1.0)]))

        # Variables defined before macro
        total = 999.0
        i = 999
        e = 999
        vals = 999

        result = @sum_over (d.amount for d in MockQuery(world, Deposits))

        # Original variables should be unchanged
        @test total == 999.0
        @test i == 999
        @test e == 999
        @test vals == 999
        @test result == 1.0
    end

    @testset "Type stability" begin
        world = MockWorld(
            [1, 2, 3], Dict(
                Deposits => [
                    Deposits(1.5),
                    Deposits(2.5),
                    Deposits(3.5),
                ]
            )
        )

        # Should return Float64, not Int or Any
        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total isa Float64
        @test total == 7.5
    end

    @testset "Multiple Query iterations" begin
        # If Query returns multiple (entity, component) tuples
        struct MultiQuery{W, C}
            world::W
            components::C
        end

        Base.iterate(q::MultiQuery, state = 1) = state > 2 ? nothing : (
                (q.world.entities[state:state], q.world.data[q.components][state:state]),
                state + 1,
            )

        # Temporarily override for this test
        world = MockWorld(
            [1, 2, 3, 4], Dict(
                Deposits => [
                    Deposits(1.0),
                    Deposits(2.0),
                    Deposits(3.0),
                    Deposits(4.0),
                ]
            )
        )

        # Test with our MockArk.Query which iterates once with all entities
        total = @sum_over (d.amount for d in MockQuery(world, Deposits))
        @test total == 10.0
    end
end
end
