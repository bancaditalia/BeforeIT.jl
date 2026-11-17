import BeforeIT as Bit

using Test, Dates

@testset "sb_other is nonnegative (clamped at calibration)" begin
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

    # baseline: the bundled calibration yields a nonnegative sb_other
    _, initial_conditions = Bit.get_params_and_initial_conditions(
        object, calibration_date; scale = 0.001
    )
    @test initial_conditions["sb_other"] >= 0

    # Hungary 2024Q1 case: the benefits sum (social_benefits +
    # other_net_transfers - unemployment_benefits - pension_benefits) turns
    # negative when pensions dominate. Pension benefits enter only sb_inact
    # and sb_other, so the raw value is negative without affecting anything
    # else. The clamp must deliver a zero, not a negative budget.
    negative = deepcopy(object)
    negative.calibration["pension_benefits"] .*= 100
    _, initial_conditions_negative = Bit.get_params_and_initial_conditions(
        negative, calibration_date; scale = 0.001
    )
    @test initial_conditions_negative["sb_other"] == 0.0
    @test initial_conditions_negative["sb_inact"] > 0
end

@testset "sb_other is nonnegative (steady-state variant)" begin
    cal = Bit.ITALY_CALIBRATION
    calibration_date = DateTime(2010, 03, 31)
    max_calibration_date = DateTime(2016, 12, 31)
    estimation_date = DateTime(1996, 12, 31)

    # the function writes a deflator key into the data dicts, so pass copies
    copy_of(object) = (
        calibration = deepcopy(object.calibration),
        figaro = deepcopy(object.figaro),
        data = deepcopy(object.data),
        ea = deepcopy(object.ea),
    )
    object = copy_of(cal)

    _, initial_conditions = Bit.get_params_and_initial_conditions_steady_state(
        calibration_date, object.calibration, object.figaro, object.data, object.ea,
        max_calibration_date, estimation_date; scale = 0.001,
    )
    @test initial_conditions["sb_other"] >= 0

    negative = copy_of(cal)
    negative.calibration["pension_benefits"] .*= 100
    _, initial_conditions_negative = Bit.get_params_and_initial_conditions_steady_state(
        calibration_date, negative.calibration, negative.figaro, negative.data, negative.ea,
        max_calibration_date, estimation_date; scale = 0.001,
    )
    @test initial_conditions_negative["sb_other"] == 0.0
    @test initial_conditions_negative["sb_inact"] > 0
end
