
function get_predictions_from_sims(data, quarter_num, horizon, number_seeds)

    # define a dictionary to store the data
    model_dict = Dict{String, Any}()

    year_num = Bit.date2num(DateTime(year(Bit.num2date(quarter_num)) + 1, 1, 1) - Day(1))
    date = Bit.num2date(quarter_num)

    file_name = "data/italy/simulations/" * string(year(date)) * "Q" * string(quarterofyear(date)) * ".jld2"
    sims = load(file_name)["data_vector"]

    forecasting_date = DateTime(year(date), month(date), 1) + Month(3 * horizon + 1)
    forecasting_date = forecasting_date - Day(1)
    forecast_quarter_num = Bit.date2num(forecasting_date)

    q = quarterofyear(DateTime(Bit.num2date(quarter_num)))

    real_gdp = sims.real_gdp
    real_gdp_growth_quarterly = diff(log.(real_gdp), dims = 1)
    real_gdp_growth_quarterly = exp.(real_gdp_growth_quarterly) .- 1
    real_gdp_quarterly =
        data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_gdp_growth_quarterly, dims = 1)
    model_dict["real_gdp_quarterly"] = [
        repeat(data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_gdp_quarterly
    ]
    model_dict["real_gdp"] = [
        repeat(data["real_gdp"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    tmp = [
        repeat(data["real_gdp"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_gdp_growth"] = diff(log.(tmp), dims = 1)

    # calculate discrete compounding rate
    model_dict["real_gdp_growth"] = exp.(model_dict["real_gdp_growth"]) .- 1
    model_dict["real_gdp_growth"] = [
        repeat(data["real_gdp_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_gdp_growth"]
    ]

    model_dict["real_gdp_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["real_gdp_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                real_gdp_quarterly
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["real_gdp_growth_quarterly"] = exp.(model_dict["real_gdp_growth_quarterly"]) .- 1
    model_dict["real_gdp_growth_quarterly"] = [
        repeat(data["real_gdp_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_gdp_growth_quarterly"]
    ]

    nominal_gdp_growth_quarterly = hcat([diff(log.(s.nominal_gdp)) for s in sims]...)
    nominal_gdp_growth_quarterly = exp.(nominal_gdp_growth_quarterly) .- 1
    nominal_gdp_quarterly =
        data["nominal_gdp_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_gdp_growth_quarterly, dims = 1)

    model_dict["nominal_gdp_quarterly"] = [
        repeat(data["nominal_gdp_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_gdp_quarterly
    ]
    model_dict["nominal_gdp"] = [
        repeat(data["nominal_gdp"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_gdp_growth"] = diff(
        log.(
            [
                repeat(data["nominal_gdp"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_gdp_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )

    # # calculate discrete compounding rate
    model_dict["nominal_gdp_growth"] = exp.(model_dict["nominal_gdp_growth"]) .- 1
    model_dict["nominal_gdp_growth"] = [
        repeat(data["nominal_gdp_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_gdp_growth"]
    ]

    model_dict["nominal_gdp_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["nominal_gdp_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                nominal_gdp_quarterly
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["nominal_gdp_growth_quarterly"] = exp.(model_dict["nominal_gdp_growth_quarterly"]) .- 1
    model_dict["nominal_gdp_growth_quarterly"] = [
        repeat(data["nominal_gdp_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["nominal_gdp_growth_quarterly"]
    ]

    gdp_deflator_quarterly = nominal_gdp_quarterly ./ real_gdp_quarterly

    model_dict["gdp_deflator_quarterly"] = [
        repeat(data["gdp_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        gdp_deflator_quarterly
    ]
    model_dict["gdp_deflator"] = [
        repeat(data["gdp_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(gdp_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["gdp_deflator_growth"] = diff(
        log.(
            [
                repeat(data["gdp_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(gdp_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["gdp_deflator_growth"] = exp.(model_dict["gdp_deflator_growth"]) .- 1
    model_dict["gdp_deflator_growth"] = [
        repeat(data["gdp_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["gdp_deflator_growth"]
    ]

    model_dict["gdp_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["gdp_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                gdp_deflator_quarterly
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["gdp_deflator_growth_quarterly"] = exp.(model_dict["gdp_deflator_growth_quarterly"]) .- 1
    model_dict["gdp_deflator_growth_quarterly"] = [
        repeat(data["gdp_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["gdp_deflator_growth_quarterly"]
    ]

    real_gva = sims.real_gva
    real_gva_growth_quarterly = diff(log.(real_gva), dims = 1)
    real_gva_growth_quarterly = exp.(real_gva_growth_quarterly) .- 1
    real_gva_quarterly =
        data["real_gva_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_gva_growth_quarterly, dims = 1)

    model_dict["real_gva_quarterly"] = [
        repeat(data["real_gva_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_gva_quarterly
    ]
    model_dict["real_gva"] = [
        repeat(data["real_gva"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_gva_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_gva_growth"] = diff(
        log.(
            [
                repeat(data["real_gva"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_gva_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )


    # calculate discrete compounding rate
    model_dict["real_gva_growth"] .= exp.(model_dict["real_gva_growth"]) .- 1
    model_dict["real_gva_growth"] = [
        repeat(data["real_gva_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_gva_growth"]
    ]

    model_dict["real_gva_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["real_gva_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                real_gva_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_gva_growth_quarterly"] = exp.(model_dict["real_gva_growth_quarterly"]) .- 1
    model_dict["real_gva_growth_quarterly"] = [
        repeat(data["real_gva_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_gva_growth_quarterly"]
    ]

    nominal_gva = sims.nominal_gva
    nominal_gva_growth_quarterly = diff(log.(nominal_gva), dims = 1)
    nominal_gva_growth_quarterly = exp.(nominal_gva_growth_quarterly) .- 1
    nominal_gva_quarterly =
        data["nominal_gva_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_gva_growth_quarterly, dims = 1)

    model_dict["nominal_gva_quarterly"] = [
        repeat(data["nominal_gva_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_gva_quarterly
    ]
    model_dict["nominal_gva"] = [
        repeat(data["nominal_gva"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_gva_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_gva_growth"] = diff(
        log.(
            [
                repeat(data["nominal_gva"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_gva_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["nominal_gva_growth"] = exp.(model_dict["nominal_gva_growth"]) .- 1
    model_dict["nominal_gva_growth"] = [
        repeat(data["nominal_gva_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_gva_growth"]
    ]

    model_dict["nominal_gva_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["nominal_gva_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                nominal_gva_quarterly
            ]
        ),
        dims = 1,
    )

    # calculate discrete compounding rate
    model_dict["nominal_gva_growth_quarterly"] = exp.(model_dict["nominal_gva_growth_quarterly"]) .- 1
    model_dict["nominal_gva_growth_quarterly"] = [
        repeat(data["nominal_gva_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["nominal_gva_growth_quarterly"]
    ]

    gva_deflator_quarterly = nominal_gva_quarterly ./ real_gva_quarterly

    model_dict["gva_deflator_quarterly"] = [
        repeat(data["gva_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        gva_deflator_quarterly
    ]
    model_dict["gva_deflator"] = [
        repeat(data["gva_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(gva_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["gva_deflator_growth"] = diff(
        log.(
            [
                repeat(data["gva_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(gva_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["gva_deflator_growth"] = exp.(model_dict["gva_deflator_growth"]) .- 1
    model_dict["gva_deflator_growth"] = [
        repeat(data["gva_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["gva_deflator_growth"]
    ]

    model_dict["gva_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["gva_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                gva_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["gva_deflator_growth_quarterly"] = exp.(model_dict["gva_deflator_growth_quarterly"]) .- 1
    model_dict["gva_deflator_growth_quarterly"] = [
        repeat(data["gva_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["gva_deflator_growth_quarterly"]
    ]

    real_household_consumption = sims.real_household_consumption
    model_dict["real_household_consumption_growth_quarterly"] = diff(log.(real_household_consumption), dims = 1)
    model_dict["real_household_consumption_growth_quarterly"] .=
        exp.(model_dict["real_household_consumption_growth_quarterly"]) .- 1
    real_household_consumption_quarterly =
        data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ model_dict["real_household_consumption_growth_quarterly"], dims = 1)

    model_dict["real_household_consumption_quarterly"] = [
        repeat(data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_household_consumption_quarterly
    ]
    model_dict["real_household_consumption"] = [
        repeat(data["real_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_household_consumption_growth"] = diff(
        log.(
            [
                repeat(data["real_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_household_consumption_growth"] .= exp.(model_dict["real_household_consumption_growth"]) .- 1
    model_dict["real_household_consumption_growth"] = [
        repeat(data["real_household_consumption_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_household_consumption_growth"]
    ]

    model_dict["real_household_consumption_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["real_household_consumption_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                real_household_consumption_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_household_consumption_growth_quarterly"] =
        exp.(model_dict["real_household_consumption_growth_quarterly"]) .- 1
    model_dict["real_household_consumption_growth_quarterly"] = [
        repeat(
            data["real_household_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["real_household_consumption_growth_quarterly"]
    ]

    nominal_household_consumption = sims.nominal_household_consumption
    model_dict["nominal_household_consumption_growth_quarterly"] = diff(log.(nominal_household_consumption), dims = 1)
    model_dict["nominal_household_consumption_growth_quarterly"] =
        exp.(model_dict["nominal_household_consumption_growth_quarterly"]) .- 1
    nominal_household_consumption_quarterly =
        data["nominal_household_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ model_dict["nominal_household_consumption_growth_quarterly"], dims = 1)

    model_dict["nominal_household_consumption_quarterly"] = [
        repeat(data["nominal_household_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_household_consumption_quarterly
    ]
    model_dict["nominal_household_consumption"] = [
        repeat(data["nominal_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_household_consumption_growth"] = diff(
        log.(
            [
                repeat(data["nominal_household_consumption"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_household_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_household_consumption_growth"] = exp.(model_dict["nominal_household_consumption_growth"]) .- 1
    model_dict["nominal_household_consumption_growth"] = [
        repeat(data["nominal_household_consumption_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_household_consumption_growth"]
    ]

    model_dict["nominal_household_consumption_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["nominal_household_consumption_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                nominal_household_consumption_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_household_consumption_growth_quarterly"] =
        exp.(model_dict["nominal_household_consumption_growth_quarterly"]) .- 1
    model_dict["nominal_household_consumption_growth_quarterly"] = [
        repeat(
            data["nominal_household_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["nominal_household_consumption_growth_quarterly"]
    ]

    household_consumption_deflator_quarterly =
        nominal_household_consumption_quarterly ./ real_household_consumption_quarterly

    model_dict["household_consumption_deflator_quarterly"] = [
        repeat(data["household_consumption_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        household_consumption_deflator_quarterly
    ]
    model_dict["household_consumption_deflator"] = [
        repeat(data["household_consumption_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(household_consumption_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["household_consumption_deflator_growth"] = diff(
        log.(
            [
                repeat(data["household_consumption_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(household_consumption_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["household_consumption_deflator_growth"] .=
        exp.(model_dict["household_consumption_deflator_growth"]) .- 1
    model_dict["household_consumption_deflator_growth"] = [
        repeat(data["household_consumption_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["household_consumption_deflator_growth"]
    ]

    model_dict["household_consumption_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["household_consumption_deflator_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                household_consumption_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["household_consumption_deflator_growth_quarterly"] =
        exp.(model_dict["household_consumption_deflator_growth_quarterly"]) .- 1
    model_dict["household_consumption_deflator_growth_quarterly"] = [
        repeat(
            data["household_consumption_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["household_consumption_deflator_growth_quarterly"]
    ]

    real_government_consumption = sims.real_government_consumption
    real_government_consumption_growth_quarterly = diff(log.(real_government_consumption), dims = 1)
    real_government_consumption_growth_quarterly = exp.(real_government_consumption_growth_quarterly) .- 1

    model_dict["real_government_consumption_growth_quarterly"] = real_government_consumption_growth_quarterly
    real_government_consumption_quarterly =
        data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_government_consumption_growth_quarterly, dims = 1)

    model_dict["real_government_consumption_quarterly"] = [
        repeat(data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_government_consumption_quarterly
    ]
    model_dict["real_government_consumption"] = [
        repeat(data["real_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_government_consumption_growth"] = diff(
        log.(
            [
                repeat(data["real_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_government_consumption_growth"] = exp.(model_dict["real_government_consumption_growth"]) .- 1
    model_dict["real_government_consumption_growth"] = [
        repeat(data["real_government_consumption_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_government_consumption_growth"]
    ]

    model_dict["real_government_consumption_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["real_government_consumption_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                real_government_consumption_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_government_consumption_growth_quarterly"] =
        exp.(model_dict["real_government_consumption_growth_quarterly"]) .- 1
    model_dict["real_government_consumption_growth_quarterly"] = [
        repeat(
            data["real_government_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["real_government_consumption_growth_quarterly"]
    ]

    nominal_government_consumption = sims.nominal_government_consumption
    nominal_government_consumption_growth_quarterly = diff(log.(nominal_government_consumption), dims = 1)
    nominal_government_consumption_growth_quarterly = exp.(nominal_government_consumption_growth_quarterly) .- 1
    model_dict["nominal_government_consumption_growth_quarterly"] = nominal_government_consumption_growth_quarterly
    nominal_government_consumption_quarterly =
        data["nominal_government_consumption_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_government_consumption_growth_quarterly, dims = 1)

    model_dict["nominal_government_consumption_quarterly"] = [
        repeat(data["nominal_government_consumption_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_government_consumption_quarterly
    ]
    model_dict["nominal_government_consumption"] = [
        repeat(data["nominal_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_government_consumption_growth"] = diff(
        log.(
            [
                repeat(data["nominal_government_consumption"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_government_consumption_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_government_consumption_growth"] = exp.(model_dict["nominal_government_consumption_growth"]) .- 1
    model_dict["nominal_government_consumption_growth"] = [
        repeat(data["nominal_government_consumption_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_government_consumption_growth"]
    ]

    model_dict["nominal_government_consumption_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["nominal_government_consumption_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                nominal_government_consumption_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_government_consumption_growth_quarterly"] =
        exp.(model_dict["nominal_government_consumption_growth_quarterly"]) .- 1
    model_dict["nominal_government_consumption_growth_quarterly"] = [
        repeat(
            data["nominal_government_consumption_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["nominal_government_consumption_growth_quarterly"]
    ]

    government_consumption_deflator_quarterly =
        nominal_government_consumption_quarterly ./ real_government_consumption_quarterly

    model_dict["government_consumption_deflator_quarterly"] = [
        repeat(
            data["government_consumption_deflator_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        government_consumption_deflator_quarterly
    ]
    model_dict["government_consumption_deflator"] = [
        repeat(data["government_consumption_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(government_consumption_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["government_consumption_deflator_growth"] = diff(
        log.(
            [
                repeat(data["government_consumption_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(government_consumption_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["government_consumption_deflator_growth"] =
        exp.(model_dict["government_consumption_deflator_growth"]) .- 1
    model_dict["government_consumption_deflator_growth"] = [
        repeat(data["government_consumption_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["government_consumption_deflator_growth"]
    ]

    model_dict["government_consumption_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["government_consumption_deflator_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                government_consumption_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["government_consumption_deflator_growth_quarterly"] =
        exp.(model_dict["government_consumption_deflator_growth_quarterly"]) .- 1
    model_dict["government_consumption_deflator_growth_quarterly"] = [
        repeat(
            data["government_consumption_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["government_consumption_deflator_growth_quarterly"]
    ]

    real_capitalformation = sims.real_capitalformation
    real_capitalformation_growth_quarterly = diff(log.(real_capitalformation), dims = 1)
    real_capitalformation_growth_quarterly  = exp.(real_capitalformation_growth_quarterly) .- 1
    model_dict["real_capitalformation_growth_quarterly"] = real_capitalformation_growth_quarterly
    real_capitalformation_quarterly =
        data["real_capitalformation_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_capitalformation_growth_quarterly, dims = 1)

    model_dict["real_capitalformation_quarterly"] = [
        repeat(data["real_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_capitalformation_quarterly
    ]
    model_dict["real_capitalformation"] = [
        repeat(data["real_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_capitalformation_growth"] = diff(
        log.(
            [
                repeat(data["real_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_capitalformation_growth"] = exp.(model_dict["real_capitalformation_growth"]) .- 1
    model_dict["real_capitalformation_growth"] = [
        repeat(data["real_capitalformation_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_capitalformation_growth"]
    ]

    model_dict["real_capitalformation_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["real_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                real_capitalformation_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_capitalformation_growth_quarterly"] =
        exp.(model_dict["real_capitalformation_growth_quarterly"]) .- 1
    model_dict["real_capitalformation_growth_quarterly"] = [
        repeat(data["real_capitalformation_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_capitalformation_growth_quarterly"]
    ]

    nominal_capitalformation = sims.nominal_capitalformation
    nominal_capitalformation_growth_quarterly = diff(log.(nominal_capitalformation), dims = 1)
    nominal_capitalformation_growth_quarterly = exp.(nominal_capitalformation_growth_quarterly) .- 1
    model_dict["nominal_capitalformation_growth_quarterly"] = nominal_capitalformation_growth_quarterly
    nominal_capitalformation_quarterly =
        data["nominal_capitalformation_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_capitalformation_growth_quarterly, dims = 1)

    model_dict["nominal_capitalformation_quarterly"] = [
        repeat(data["nominal_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_capitalformation_quarterly
    ]
    model_dict["nominal_capitalformation"] = [
        repeat(data["nominal_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_capitalformation_growth"] = diff(
        log.(
            [
                repeat(data["nominal_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_capitalformation_growth"] = exp.(model_dict["nominal_capitalformation_growth"]) .- 1
    model_dict["nominal_capitalformation_growth"] = [
        repeat(data["nominal_capitalformation_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_capitalformation_growth"]
    ]

    model_dict["nominal_capitalformation_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["nominal_capitalformation_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                nominal_capitalformation_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_capitalformation_growth_quarterly"] =
        exp.(model_dict["nominal_capitalformation_growth_quarterly"]) .- 1
    model_dict["nominal_capitalformation_growth_quarterly"] = [
        repeat(
            data["nominal_capitalformation_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["nominal_capitalformation_growth_quarterly"]
    ]

    capitalformation_deflator_quarterly = nominal_capitalformation_quarterly ./ real_capitalformation_quarterly

    model_dict["capitalformation_deflator_quarterly"] = [
        repeat(data["capitalformation_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        capitalformation_deflator_quarterly
    ]
    model_dict["capitalformation_deflator"] = [
        repeat(data["capitalformation_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(capitalformation_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["capitalformation_deflator_growth"] = diff(
        log.(
            [
                repeat(data["capitalformation_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(capitalformation_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["capitalformation_deflator_growth"] = exp.(model_dict["capitalformation_deflator_growth"]) .- 1
    model_dict["capitalformation_deflator_growth"] = [
        repeat(data["capitalformation_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["capitalformation_deflator_growth"]
    ]

    model_dict["capitalformation_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["capitalformation_deflator_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                capitalformation_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["capitalformation_deflator_growth_quarterly"] =
        exp.(model_dict["capitalformation_deflator_growth_quarterly"]) .- 1
    model_dict["capitalformation_deflator_growth_quarterly"] = [
        repeat(
            data["capitalformation_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["capitalformation_deflator_growth_quarterly"]
    ]

    real_fixed_capitalformation = sims.real_fixed_capitalformation
    real_fixed_capitalformation_growth_quarterly = diff(log.(real_fixed_capitalformation), dims = 1)
    real_fixed_capitalformation_growth_quarterly = exp.(real_fixed_capitalformation_growth_quarterly) .- 1
    model_dict["real_fixed_capitalformation_growth_quarterly"] = real_fixed_capitalformation_growth_quarterly
    real_fixed_capitalformation_quarterly =
        data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_fixed_capitalformation_growth_quarterly, dims = 1)

    model_dict["real_fixed_capitalformation_quarterly"] = [
        repeat(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_fixed_capitalformation_quarterly
    ]
    model_dict["real_fixed_capitalformation"] = [
        repeat(data["real_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_fixed_capitalformation_growth"] = diff(
        log.(
            [
                repeat(data["real_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_fixed_capitalformation_growth"] = exp.(model_dict["real_fixed_capitalformation_growth"]) .- 1
    model_dict["real_fixed_capitalformation_growth"] = [
        repeat(data["real_fixed_capitalformation_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_fixed_capitalformation_growth"]
    ]

    model_dict["real_fixed_capitalformation_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                real_fixed_capitalformation_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_fixed_capitalformation_growth_quarterly"] =
        exp.(model_dict["real_fixed_capitalformation_growth_quarterly"]) .- 1
    model_dict["real_fixed_capitalformation_growth_quarterly"] = [
        repeat(
            data["real_fixed_capitalformation_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["real_fixed_capitalformation_growth_quarterly"]
    ]

    nominal_fixed_capitalformation = sims.nominal_fixed_capitalformation
    nominal_fixed_capitalformation_growth_quarterly = diff(log.(nominal_fixed_capitalformation), dims = 1)
    nominal_fixed_capitalformation_growth_quarterly = exp.(nominal_fixed_capitalformation_growth_quarterly) .- 1
    nominal_fixed_capitalformation_quarterly =
        data["nominal_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_fixed_capitalformation_growth_quarterly, dims = 1)

    model_dict["nominal_fixed_capitalformation_quarterly"] = [
        repeat(data["nominal_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_fixed_capitalformation_quarterly
    ]
    model_dict["nominal_fixed_capitalformation"] = [
        repeat(data["nominal_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_fixed_capitalformation_growth"] = diff(
        log.(
            [
                repeat(data["nominal_fixed_capitalformation"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_fixed_capitalformation_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_fixed_capitalformation_growth"] = exp.(model_dict["nominal_fixed_capitalformation_growth"]) .- 1
    model_dict["nominal_fixed_capitalformation_growth"] = [
        repeat(data["nominal_fixed_capitalformation_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_fixed_capitalformation_growth"]
    ]

    model_dict["nominal_fixed_capitalformation_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["nominal_fixed_capitalformation_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                nominal_fixed_capitalformation_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_fixed_capitalformation_growth_quarterly"] =
        exp.(model_dict["nominal_fixed_capitalformation_growth_quarterly"]) .- 1
    model_dict["nominal_fixed_capitalformation_growth_quarterly"] = [
        repeat(
            data["nominal_fixed_capitalformation_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["nominal_fixed_capitalformation_growth_quarterly"]
    ]

    fixed_capitalformation_deflator_quarterly =
        nominal_fixed_capitalformation_quarterly ./ real_fixed_capitalformation_quarterly

    model_dict["fixed_capitalformation_deflator_quarterly"] = [
        repeat(
            data["fixed_capitalformation_deflator_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        fixed_capitalformation_deflator_quarterly
    ]
    model_dict["fixed_capitalformation_deflator"] = [
        repeat(data["fixed_capitalformation_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(fixed_capitalformation_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["fixed_capitalformation_deflator_growth"] = diff(
        log.(
            [
                repeat(data["fixed_capitalformation_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(fixed_capitalformation_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["fixed_capitalformation_deflator_growth"] =
        exp.(model_dict["fixed_capitalformation_deflator_growth"]) .- 1
    model_dict["fixed_capitalformation_deflator_growth"] = [
        repeat(data["fixed_capitalformation_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["fixed_capitalformation_deflator_growth"]
    ]

    model_dict["fixed_capitalformation_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(
                    data["fixed_capitalformation_deflator_quarterly"][data["quarters_num"] .== quarter_num],
                    1,
                    number_seeds,
                )
                fixed_capitalformation_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["fixed_capitalformation_deflator_growth_quarterly"] =
        exp.(model_dict["fixed_capitalformation_deflator_growth_quarterly"]) .- 1
    model_dict["fixed_capitalformation_deflator_growth_quarterly"] = [
        repeat(
            data["fixed_capitalformation_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num],
            1,
            number_seeds,
        )
        model_dict["fixed_capitalformation_deflator_growth_quarterly"]
    ]

    real_exports = sims.real_exports
    real_exports_growth_quarterly = diff(log.(real_exports), dims = 1)
    real_exports_growth_quarterly = exp.(real_exports_growth_quarterly) .- 1
    real_exports_quarterly =
        data["real_exports_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_exports_growth_quarterly, dims = 1)

    model_dict["real_exports_quarterly"] = [
        repeat(data["real_exports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_exports_quarterly
    ]
    model_dict["real_exports"] = [
        repeat(data["real_exports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_exports_growth"] = diff(
        log.(
            [
                repeat(data["real_exports"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_exports_growth"] = exp.(model_dict["real_exports_growth"]) .- 1
    model_dict["real_exports_growth"] = [
        repeat(data["real_exports_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_exports_growth"]
    ]

    model_dict["real_exports_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["real_exports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                real_exports_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_exports_growth_quarterly"] = exp.(model_dict["real_exports_growth_quarterly"]) .- 1
    model_dict["real_exports_growth_quarterly"] = [
        repeat(data["real_exports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_exports_growth_quarterly"]
    ]

    nominal_exports = sims.nominal_exports
    nominal_exports_growth_quarterly = diff(log.(nominal_exports), dims = 1)
    nominal_exports_growth_quarterly = exp.(nominal_exports_growth_quarterly) .- 1
    nominal_exports_quarterly =
        data["nominal_exports_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_exports_growth_quarterly, dims = 1)

    model_dict["nominal_exports_quarterly"] = [
        repeat(data["nominal_exports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_exports_quarterly
    ]
    model_dict["nominal_exports"] = [
        repeat(data["nominal_exports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_exports_growth"] = diff(
        log.(
            [
                repeat(data["nominal_exports"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_exports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_exports_growth"] = exp.(model_dict["nominal_exports_growth"]) .- 1
    model_dict["nominal_exports_growth"] = [
        repeat(data["nominal_exports_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_exports_growth"]
    ]

    model_dict["nominal_exports_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["nominal_exports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                nominal_exports_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_exports_growth_quarterly"] = exp.(model_dict["nominal_exports_growth_quarterly"]) .- 1
    model_dict["nominal_exports_growth_quarterly"] = [
        repeat(data["nominal_exports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["nominal_exports_growth_quarterly"]
    ]

    exports_deflator_quarterly = nominal_exports_quarterly ./ real_exports_quarterly

    model_dict["exports_deflator_quarterly"] = [
        repeat(data["exports_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        exports_deflator_quarterly
    ]
    model_dict["exports_deflator"] = [
        repeat(data["exports_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(exports_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["exports_deflator_growth"] = diff(
        log.(
            [
                repeat(data["exports_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(exports_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["exports_deflator_growth"] = exp.(model_dict["exports_deflator_growth"]) .- 1
    model_dict["exports_deflator_growth"] = [
        repeat(data["exports_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["exports_deflator_growth"]
    ]

    model_dict["exports_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["exports_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                exports_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["exports_deflator_growth_quarterly"] = exp.(model_dict["exports_deflator_growth_quarterly"]) .- 1
    model_dict["exports_deflator_growth_quarterly"] = [
        repeat(data["exports_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["exports_deflator_growth_quarterly"]
    ]

    real_imports = sims.real_imports
    real_imports_growth_quarterly = diff(log.(real_imports), dims = 1)
    real_imports_growth_quarterly .= exp.(real_imports_growth_quarterly) .- 1
    real_imports_quarterly =
        data["real_imports_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ real_imports_growth_quarterly, dims = 1)

    model_dict["real_imports_quarterly"] = [
        repeat(data["real_imports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        real_imports_quarterly
    ]
    model_dict["real_imports"] = [
        repeat(data["real_imports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(real_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["real_imports_growth"] = diff(
        log.(
            [
                repeat(data["real_imports"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(real_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_imports_growth"] = exp.(model_dict["real_imports_growth"]) .- 1
    model_dict["real_imports_growth"] = [
        repeat(data["real_imports_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["real_imports_growth"]
    ]

    model_dict["real_imports_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["real_imports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                real_imports_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["real_imports_growth_quarterly"] = exp.(model_dict["real_imports_growth_quarterly"]) .- 1
    model_dict["real_imports_growth_quarterly"] = [
        repeat(data["real_imports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["real_imports_growth_quarterly"]
    ]

    nominal_imports = sims.nominal_imports
    nominal_imports_growth_quarterly = diff(log.(nominal_imports), dims = 1)
    nominal_imports_growth_quarterly = exp.(nominal_imports_growth_quarterly) .- 1
    nominal_imports_quarterly =
        data["nominal_imports_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ nominal_imports_growth_quarterly, dims = 1)

    model_dict["nominal_imports_quarterly"] = [
        repeat(data["nominal_imports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        nominal_imports_quarterly
    ]
    model_dict["nominal_imports"] = [
        repeat(data["nominal_imports"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(nominal_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["nominal_imports_growth"] = diff(
        log.(
            [
                repeat(data["nominal_imports"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual(nominal_imports_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_imports_growth"] = exp.(model_dict["nominal_imports_growth"]) .- 1
    model_dict["nominal_imports_growth"] = [
        repeat(data["nominal_imports_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["nominal_imports_growth"]
    ]

    model_dict["nominal_imports_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["nominal_imports_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                nominal_imports_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["nominal_imports_growth_quarterly"] = exp.(model_dict["nominal_imports_growth_quarterly"]) .- 1
    model_dict["nominal_imports_growth_quarterly"] = [
        repeat(data["nominal_imports_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["nominal_imports_growth_quarterly"]
    ]

    imports_deflator_quarterly = nominal_imports_quarterly ./ real_imports_quarterly

    model_dict["imports_deflator_quarterly"] = [
        repeat(data["imports_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        imports_deflator_quarterly
    ]
    model_dict["imports_deflator"] = [
        repeat(data["imports_deflator"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual_mean(imports_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]
    model_dict["imports_deflator_growth"] = diff(
        log.(
            [
                repeat(data["imports_deflator"][data["years_num"] .== year_num], 1, number_seeds)
                Bit.toannual_mean(imports_deflator_quarterly[(5 - q):(end - mod(q, 4)), :]')'
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["imports_deflator_growth"] = exp.(model_dict["imports_deflator_growth"]) .- 1
    model_dict["imports_deflator_growth"] = [
        repeat(data["imports_deflator_growth"][data["years_num"] .== year_num], 1, number_seeds)
        model_dict["imports_deflator_growth"]
    ]

    model_dict["imports_deflator_growth_quarterly"] = diff(
        log.(
            [
                repeat(data["imports_deflator_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
                imports_deflator_quarterly
            ]
        ),
        dims = 1,
    )
    # calculate discrete compounding rate
    model_dict["imports_deflator_growth_quarterly"] = exp.(model_dict["imports_deflator_growth_quarterly"]) .- 1
    model_dict["imports_deflator_growth_quarterly"] = [
        repeat(data["imports_deflator_growth_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        model_dict["imports_deflator_growth_quarterly"]
    ]

    operating_surplus = sims.operating_surplus
    operating_surplus_growth_quarterly = diff(log.(operating_surplus), dims = 1)
    operating_surplus_growth_quarterly = exp.(operating_surplus_growth_quarterly) .- 1
    operating_surplus_quarterly =
        data["operating_surplus_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ operating_surplus_growth_quarterly, dims = 1)

    model_dict["operating_surplus_quarterly"] = [
        repeat(data["operating_surplus_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        operating_surplus_quarterly
    ]
    model_dict["operating_surplus"] = [
        repeat(data["operating_surplus"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(operating_surplus_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    compensation_employees = sims.compensation_employees
    compensation_employees_growth_quarterly = diff(log.(compensation_employees), dims = 1)
    compensation_employees_growth_quarterly = exp.(compensation_employees_growth_quarterly) .- 1
    compensation_employees_quarterly =
        data["compensation_employees_quarterly"][data["quarters_num"] .== quarter_num] .*
        cumprod(1 .+ compensation_employees_growth_quarterly, dims = 1)

    model_dict["compensation_employees_quarterly"] = [
        repeat(data["compensation_employees_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        compensation_employees_quarterly
    ]
    model_dict["compensation_employees"] = [
        repeat(data["compensation_employees"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(compensation_employees_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]

    wages = sims.wages
    wages_growth_quarterly = diff(log.(wages), dims = 1)
    wages_growth_quarterly = exp.(wages_growth_quarterly) .- 1
    wages_quarterly =
        data["wages_quarterly"][data["quarters_num"] .== quarter_num] .* cumprod(1 .+ wages_growth_quarterly, dims = 1)

    model_dict["wages_quarterly"] = [
        repeat(data["wages_quarterly"][data["quarters_num"] .== quarter_num], 1, number_seeds)
        wages_quarterly
    ]
    model_dict["wages"] = [
        repeat(data["wages"][data["years_num"] .== year_num], 1, number_seeds)
        Bit.toannual(wages_quarterly[(5 - q):(end - mod(q, 4)), :]')'
    ]


    quarters_num_ = []
    for m in 0:3:(3 * horizon)
        year_ = year(Bit.num2date(quarter_num))
        month_ = month(Bit.num2date(quarter_num))
        date_ = DateTime(year_, month_, 1) + Month(m) + Month(1)
        date_ = date_ - Day(1)
        push!(quarters_num_, Bit.date2num(date_))
    end

    model_dict["quarters_num"] = quarters_num_

    years_num = []
    for month in 1:12:(horizon / 4 * 12 + floor(q / 4))
        year_ = year(Bit.num2date(quarter_num)) + 1
        date_ = DateTime(year_, 1, 1) + Month(month) - Month(1)
        date_ = date_ - Day(1)
        push!(years_num, Bit.date2num(date_))
    end

    model_dict["years_num"] = years_num

    # Note: nominal and real nace10_gva_quarterly and annually are missing here

    euribor = sims.euribor
    model_dict["euribor"] = (1 .+ euribor) .^ 4 .- 1

    gdp_deflator_growth_ea = sims.gdp_deflator_growth_ea
    model_dict["gdp_deflator_growth_ea_quarterly"] = gdp_deflator_growth_ea
    real_gdp_ea = sims.real_gdp_ea
    model_dict["real_gdp_ea_quarterly"] = real_gdp_ea

    # save the model_dict to an appropriate folder
    save(
        "data/italy/abm_predictions/" * string(year(date)) * "Q" * string(quarterofyear(date)) * ".jld2",
        "model_dict",
        model_dict,
    )

end
