# Error table functions for AR, ABM, and validation models
# Dependencies (Dates, Statistics, JLD2) are already imported via analysis_utils.jl

# =============================================================================
# VARIABLE SPECIFICATIONS
# =============================================================================

# The 5-variable set (training: GDP, deflator, consumption, investment, euribor)
const training_var_specs = [
    (key = "real_gdp_quarterly", transform = log, source = :data),
    (key = "gdp_deflator_growth_quarterly", transform = x -> log(1 + x), source = :data),
    (key = "real_household_consumption_quarterly", transform = log, source = :data),
    (key = "real_fixed_capitalformation_quarterly", transform = log, source = :data),
    (key = "euribor", transform = x -> (1 + x)^(1 / 4), source = :data),
]

# The 8-variable set (validation: adds gov consumption, exports, imports, EA GDP, EA deflator)
const validation_var_specs = [
    (key = "real_gdp_quarterly", transform = log, source = :data),
    (key = "gdp_deflator_growth_quarterly", transform = x -> log(1 + x), source = :data),
    (key = "real_government_consumption_quarterly", transform = log, source = :data),
    (key = "real_exports_quarterly", transform = log, source = :data),
    (key = "real_imports_quarterly", transform = log, source = :data),
    (key = "real_gdp_quarterly", transform = log, source = :ea),
    (key = "gdp_deflator_growth_quarterly", transform = x -> log(1 + x), source = :ea),
    (key = "euribor", transform = x -> (1 + x)^(1 / 4), source = :data),
]

# =============================================================================
# SHARED HELPERS
# =============================================================================

"""
    extract_actual_values(data, ea, forecast_quarter_num, var_specs)

Extract actual values for a forecast quarter, applying the specified transforms.
Replaces the duplicated `hcat(log.(...), ...)` blocks across error table functions.
"""
function extract_actual_values(data, ea, forecast_quarter_num, var_specs)
    mask = data["quarters_num"] .== forecast_quarter_num
    vals = Float64[]
    for spec in var_specs
        src = spec.source == :ea ? ea : data
        raw = src[spec.key][mask]
        push!(vals, spec.transform(only(raw)))
    end
    return vals
end

"""
    extract_abm_forecast(model, forecast_quarter_num, number_of_seeds, var_specs)

Extract ABM forecast values (mean across seeds) for a forecast quarter.
Replaces the duplicated ABM forecast extraction blocks.
"""
function extract_abm_forecast(model, forecast_quarter_num, number_of_seeds, var_specs)
    mask = repeat(model["quarters_num"] .== forecast_quarter_num, 1, number_of_seeds)
    vals = Float64[]
    for spec in var_specs
        # EA variables have different key names in model predictions
        model_key = spec.source == :ea ? replace(spec.key, "_quarterly" => "_ea_quarterly") : spec.key
        push!(vals, spec.transform(mean(model[model_key][mask])))
    end
    return vals
end

# =============================================================================
# ERROR TABLE FUNCTIONS
# =============================================================================

function error_table_ar(
        country::String, ea, data, quarters, horizons;
        model_variant::String = "base",
    )
    quarters_num = date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    variable_names = agg_base_variables
    presample = 4

    for k in 1:3
        forecast = fill(NaN, number_quarters, number_horizons, length(variable_names))
        actual = fill(NaN, number_quarters, number_horizons, length(variable_names))

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                horizon = horizons[j]

                forecast_quarter_num = date2num(lastdayofmonth(num2date(quarter_num) + Month(3 * horizon)))
                num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

                # Skip if actual data doesn't cover this forecast quarter
                any(data["quarters_num"] .== forecast_quarter_num) || continue

                actual[i, j, :] = extract_actual_values(data, ea, forecast_quarter_num, training_var_specs)

                Y0 = hcat(
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["gdp_deflator_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_household_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_fixed_capitalformation_quarterly"][data["quarters_num"] .<= quarter_num]),
                    cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]) .^ (1 / 4)),
                )

                Y = zeros(horizon, number_variables)
                Y0_diff = diff(Y0[(presample - k):end, :]; dims = 1)

                for l in 1:number_variables
                    Y[:, l] = forecast_k_steps_VAR(Y0_diff[:, l], horizon, intercept = true, lags = k)
                end

                Y[end, [1, 3, 4]] = Y0[end, [1, 3, 4]]' + sum(Y[:, [1, 3, 4]], dims = 1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        create_bias_rmse_tables_var(
            forecast, actual, horizons, "training", "ar", variable_names, k, country;
            model_variant = model_variant,
        )
    end
    return nothing
end

function error_table_abm(
        country::String, ea, data, quarters, horizons;
        model_variant::String = "base",
        prediction_folder::String = "abm_predictions/base",
    )
    quarters_num = date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    variable_names = agg_base_variables

    forecast = fill(NaN, number_quarters, number_horizons, length(variable_names))
    actual = fill(NaN, number_quarters, number_horizons, length(variable_names))

    # Build predictions path
    predictions_dir = "./data/$(country)/$(prediction_folder)"

    # Find number_of_seeds from the first available prediction file
    number_of_seeds = nothing
    for q in quarters_num
        fname = "$(predictions_dir)/$(year(num2date(q)))Q$(quarterofyear(num2date(q))).jld2"
        if isfile(fname)
            model = load(fname, "predictions_dict")
            number_of_seeds = size(model["real_gdp_quarterly"], 2)
            break
        end
    end
    if number_of_seeds === nothing
        @warn "No prediction files found for $country in $predictions_dir, skipping"
        return
    end

    for i in 1:number_quarters
        q = quarters_num[i]
        fname = "$(predictions_dir)/$(year(num2date(q)))Q$(quarterofyear(num2date(q))).jld2"

        # Skip quarters without prediction files (leave NaN)
        isfile(fname) || continue

        model = load(fname, "predictions_dict")

        for j in 1:number_horizons
            horizon = horizons[j]

            forecast_quarter_num = date2num(lastdayofmonth(num2date(q) + Month(3 * horizon)))
            num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

            # Skip if actual data doesn't cover this forecast quarter
            any(data["quarters_num"] .== forecast_quarter_num) || continue

            actual[i, j, :] = extract_actual_values(data, ea, forecast_quarter_num, training_var_specs)
            forecast[i, j, :] = extract_abm_forecast(model, forecast_quarter_num, number_of_seeds, training_var_specs)
        end
    end

    # Save forecast to variant subfolder
    analysis_dir = "data/$(country)/analysis/$(model_variant)"
    mkpath(analysis_dir)
    save("$(analysis_dir)/forecast_abm.jld2", "forecast", forecast)
    return create_bias_rmse_tables_abm(
        forecast, actual, horizons, "training", variable_names, country;
        model_variant = model_variant,
    )
end

function error_table_validation_var(
        country::String, ea, data, quarters, horizons;
        model_variant::String = "base",
    )
    quarters_num = date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    variable_names = agg_validation_variables
    presample = 4

    for k in 1:3
        forecast = fill(NaN, number_quarters, number_horizons, length(variable_names))
        actual = fill(NaN, number_quarters, number_horizons, length(variable_names))

        for i in 1:number_quarters
            quarter_num = quarters_num[i]

            for j in 1:number_horizons
                horizon = horizons[j]

                forecast_quarter_num = date2num(lastdayofmonth(num2date(quarter_num) + Month(3 * horizon)))
                num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

                # Skip if actual data doesn't cover this forecast quarter
                any(data["quarters_num"] .== forecast_quarter_num) || continue

                actual[i, j, :] = extract_actual_values(data, ea, forecast_quarter_num, validation_var_specs)

                Y0 = hcat(
                    log.(data["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(1 .+ data["gdp_deflator_growth_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_government_consumption_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_exports_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(data["real_imports_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(ea["real_gdp_quarterly"][data["quarters_num"] .<= quarter_num]),
                    log.(1 .+ ea["gdp_deflator_growth_quarterly"][data["quarters_num"] .<= quarter_num]),
                    cumsum((1 .+ data["euribor"][data["quarters_num"] .<= quarter_num]) .^ (1 / 4)),
                )

                Y0_diff = diff(Y0[(presample - k + 1):end, :]; dims = 1)
                Y = forecast_k_steps_VAR(Y0_diff, horizon, intercept = true, lags = k)

                Y[end, [1, 3, 4, 5, 6]] = Y0[end, [1, 3, 4, 5, 6]]' + sum(Y[:, [1, 3, 4, 5, 6]], dims = 1)
                forecast[i, j, :] = Y[end, :]
            end
        end

        create_bias_rmse_tables_var(
            forecast, actual, horizons, "validation", "var", variable_names, k, country;
            model_variant = model_variant,
        )
    end
    return nothing
end

function error_table_validation_abm(
        country::String, ea, data, quarters, horizons;
        model_variant::String = "base",
        prediction_folder::String = "abm_predictions/base",
    )
    quarters_num = date2num.(quarters)
    number_quarters = length(quarters)
    max_year = year(quarters[end])

    number_horizons = length(horizons)
    variable_names = agg_validation_variables

    forecast = fill(NaN, number_quarters, number_horizons, length(variable_names))
    actual = fill(NaN, number_quarters, number_horizons, length(variable_names))

    # Build predictions path
    predictions_dir = "./data/$(country)/$(prediction_folder)"

    # Find number_of_seeds from the first available prediction file
    number_of_seeds = nothing
    for q in quarters_num
        fname = "$(predictions_dir)/$(year(num2date(q)))Q$(quarterofyear(num2date(q))).jld2"
        if isfile(fname)
            model = load(fname, "predictions_dict")
            number_of_seeds = size(model["real_gdp_quarterly"], 2)
            break
        end
    end
    if number_of_seeds === nothing
        @warn "No prediction files found for $country in $predictions_dir, skipping"
        return
    end

    for i in 1:number_quarters
        q = quarters_num[i]
        fname = "$(predictions_dir)/$(year(num2date(q)))Q$(quarterofyear(num2date(q))).jld2"

        # Skip quarters without prediction files (leave NaN)
        isfile(fname) || continue

        model = load(fname, "predictions_dict")

        for j in 1:number_horizons
            horizon = horizons[j]

            forecast_quarter_num = date2num(lastdayofmonth(num2date(q) + Month(3 * horizon)))
            num2date(forecast_quarter_num) > Date(max_year, 12, 31) && break

            # Skip if actual data doesn't cover this forecast quarter
            any(data["quarters_num"] .== forecast_quarter_num) || continue

            actual[i, j, :] = extract_actual_values(data, ea, forecast_quarter_num, validation_var_specs)
            forecast[i, j, :] = extract_abm_forecast(model, forecast_quarter_num, number_of_seeds, validation_var_specs)
        end
    end

    # Save forecast to variant subfolder
    analysis_dir = "data/$(country)/analysis/$(model_variant)"
    mkpath(analysis_dir)
    save("$(analysis_dir)/forecast_validation_abm.jld2", "forecast", forecast)
    return create_bias_rmse_tables_abm(
        forecast, actual, horizons, "validation", variable_names, country;
        model_variant = model_variant,
    )
end
