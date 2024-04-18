# In this tutorial we illustrate how to calibrate the model to the Italian data for a specific quarter

import BeforeIT as Bit
using Dates, Statistics, FileIO


# We start from loading the calibration oject for italy, which contains 4 datasets: calibration_data, figaro, data, and ea
# These are saved within BeforeIT for the Italian case, and would need to be appropriately generated for other countries

cal = Bit.ITALY_CALIBRATION

fieldnames(typeof(cal))

# These are essentually 4 dictionaries with well defined keys, such as
println(keys(cal.calibration))
println(keys(cal.figaro))
println(keys(cal.data))
println(keys(cal.ea))

# The object also contains two time variables related to the data
println(cal.max_calibration_date)
println(cal.estimation_date)

# We can calibrate the model on a specific quarter as follows

calibration_date = DateTime(2010, 03, 31)
parameters, initial_conditions = Bit.get_params_and_initial_conditions(
    cal,    
    calibration_date;
    scale = 0.01,
)

# In sgeneral, we might want to repeat this operation for multiple quarters.
# In the following, we loop over all quarters from 2010Q1 to 2019Q4
# and save the parameters and initial conditions in separate files.
# We can then load these files later to run the model for each quarter.
start_calibration_date = DateTime(2010, 03, 31)
end_calibration_date = DateTime(2019, 12, 31)

for calibration_date in collect(start_calibration_date:Dates.Month(3):end_calibration_date)
    params, init_conds = Bit.get_params_and_initial_conditions(
        cal,    
        calibration_date;
        scale = 0.0005,
    )
    save(
        "data/" *
        "italy/" *
        "/parameters/" *
        string(year(calibration_date)) *
        "Q" *
        string(Dates.quarterofyear(calibration_date)) *
        ".jld2",
        params,
    )
    save(
        "data/" *
        "italy/" *
        "/initial_conditions/" *
        string(year(calibration_date)) *
        "Q" *
        string(Dates.quarterofyear(calibration_date)) *
        ".jld2",
        init_conds,
    )
end
