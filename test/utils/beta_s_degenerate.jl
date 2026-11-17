import BeforeIT as Bit

using Test, Dates

@testset "beta_s is floored and capped (degenerate sectors)" begin
    # Replicates the call in test/calibration_script.jl on the bundled object.
    cal = Bit.ITALY_CALIBRATION
    calibration_date = DateTime(2010, 03, 31)
    object = (
        calibration = cal.calibration,
        figaro = cal.figaro,
        data = cal.data,
        ea = cal.ea,
        max_calibration_date = DateTime(2016, 12, 31),
        estimation_date = DateTime(1996, 12, 31),
    )
    # the FIGARO column index that get_params_and_initial_conditions reads
    T = findfirst(
        ==(Bit.date2num(DateTime(year(min(calibration_date, object.max_calibration_date)), 12, 31))),
        vec(object.calibration["years_num"]),
    )

    # LU 2024Q1 case (sectors 03/10): a zero-output sector. With all value-added
    # components and its intermediate-consumption column at zero, beta_s is
    # 0/0 = NaN, which the existing replace! turns into 0.0. The floor must
    # lift it to MIN_PRODUCTIVITY so downstream shares stay well-defined.
    zero_output = deepcopy(object)
    zero_output.figaro["intermediate_consumption"][:, 3, T] .= 0
    zero_output.figaro["compensation_employees"][3, T] = 0
    zero_output.figaro["operating_surplus"][3, T] = 0
    zero_output.figaro["taxes_products"][3, T] = 0
    zero_output.figaro["taxes_production"][3, T] = 0
    params_zero, _ = Bit.get_params_and_initial_conditions(
        zero_output, calibration_date; scale = 0.001
    )
    @test params_zero["beta_s"][3] >= 1.0e-6

    # MT 2024Q1 case (sector 10): output without intermediate consumption.
    # beta_s = output / 0 = Inf, which no existing replace! catches. The cap
    # must bring it to 1 / MIN_PRODUCTIVITY so initial materials stay finite.
    no_intermediates = deepcopy(object)
    no_intermediates.figaro["intermediate_consumption"][:, 5, T] .= 0
    params_inf, _ = Bit.get_params_and_initial_conditions(
        no_intermediates, calibration_date; scale = 0.001
    )
    @test isfinite(params_inf["beta_s"][5])
    @test params_inf["beta_s"][5] <= 1.0e6
end
