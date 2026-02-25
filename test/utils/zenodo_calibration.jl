# Test for zenodo calibration data functionality
# Tests the integration between download_zenodo_calibration_object and get_params_and_initial_conditions

import BeforeIT as Bit
using Dates, Test

@testset "Zenodo calibration integration" begin
    # Test that we can download and use AT calibration data
    @testset "Austria calibration" begin
        # Download the calibration object
        at = Bit.download_zenodo_calibration_object("AT")

        # Test that the calibration object has the expected structure
        @test hasproperty(at, :calibration)
        @test hasproperty(at, :figaro)
        @test hasproperty(at, :data)
        @test hasproperty(at, :ea)
        @test hasproperty(at, :max_calibration_date)
        @test hasproperty(at, :estimation_date)

        # Test that we can get valid calibration quarters
        valid_quarters = Bit.get_valid_calibration_quarters(at)
        @test !isempty(valid_quarters)
        @test all(q -> q[1] >= 1995 && q[2] in 1:4, valid_quarters)

        # Test a specific quarter that should be available
        calibration_date = DateTime(2020, 03, 31)

        # Test that get_params_and_initial_conditions works with zenodo data
        @testset "get_params_and_initial_conditions with zenodo data" begin
            # This should work without throwing an error
            @test begin
                parameters, initial_conditions = Bit.get_params_and_initial_conditions(
                    at, calibration_date; scale = 1 / 1000
                )
                true
            end

            # Test that we get the expected parameter and initial condition keys
            parameters, initial_conditions = Bit.get_params_and_initial_conditions(
                at, calibration_date; scale = 1 / 1000
            )

            # Test some key parameters exist
            @test haskey(parameters, "rho")
            @test haskey(parameters, "theta")
            @test haskey(parameters, "mu")

            # Test some key initial conditions exist
            @test haskey(initial_conditions, "omega")
            @test haskey(initial_conditions, "Y")
            @test haskey(initial_conditions, "D_H")

            # Test that values are reasonable (positive where expected)
            @test parameters["rho"] > 0
            @test parameters["rho"] < 1
            @test initial_conditions["omega"] > 0
            @test initial_conditions["omega"] < 1

            # Test that we can create a model with these parameters
            @test begin
                model = Bit.Model(parameters, initial_conditions)
                true
            end
        end

        @testset "Quarterly data availability" begin
            # Test that quarterly data is properly handled
            calibration_date = DateTime(2020, 03, 31)
            parameters, initial_conditions = Bit.get_params_and_initial_conditions(
                at, calibration_date; scale = 1 / 1000
            )

            # Test that quarterly variables are properly scaled/loaded
            @test haskey(initial_conditions, "D_I")
            @test initial_conditions["D_I"] >= 0

            # Test that the function handles missing quarterly data gracefully
            # (should fall back to annual data with appropriate warnings)
            # This is harder to test directly, but we can at least verify the function doesn't crash
        end
    end

    @testset "Error handling" begin
        # Test invalid country code
        @test_throws ErrorException Bit.download_zenodo_calibration_object("XX")

        # Test that get_params_and_initial_conditions handles edge cases
        at = Bit.download_zenodo_calibration_object("AT")

        # Test with a date that should be too early
        very_early_date = DateTime(1900, 01, 01)
        @test_throws Exception Bit.get_params_and_initial_conditions(at, very_early_date)
    end
end

@testset "Multiple countries" begin
    # Test that we can download and use multiple countries
    countries_to_test = ["AT", "DE", "FR"]  # Small subset for testing

    for country in countries_to_test
        @testset "$country calibration" begin
            co = Bit.download_zenodo_calibration_object(country)

            # Get valid quarters
            valid_quarters = Bit.get_valid_calibration_quarters(co)
            @test !isempty(valid_quarters)

            # Test with the most recent valid quarter
            if !isempty(valid_quarters)
                latest_year = maximum(q -> q[1], valid_quarters)
                latest_quarter = maximum(q -> q[2], filter(q -> q[1] == latest_year, valid_quarters))
                calibration_date = DateTime(
                    latest_year, latest_quarter * 3,
                    latest_quarter * 3 in [3, 12] ? 31 : 30
                )

                @test begin
                    parameters, initial_conditions = Bit.get_params_and_initial_conditions(
                        co, calibration_date; scale = 1 / 1000
                    )
                    true
                end
            end
        end
    end
end
