
using MAT, FileIO, Dates

dir = @__DIR__

parameters_mat = matread(joinpath(dir, "matlab_code/italy_calibration/parameters/2010Q1.mat"))
initial_conditions_mat = matread(joinpath(dir, "matlab_code/italy_calibration/initial_conditions/2010Q1.mat"))

using BeforeIT

calibration_data = BeforeIT.ITALY_CALIBRATION.calibration
figaro = BeforeIT.ITALY_CALIBRATION.figaro
data = BeforeIT.ITALY_CALIBRATION.data
ea = BeforeIT.ITALY_CALIBRATION.ea

# define a calibration period
start_calibration_date = DateTime(2010, 03, 31)
max_calibration_date = DateTime(2016, 12, 31)
estimation_date = DateTime(1996, 12, 31)

# Calibrate on a specific quarter
calibration_date = DateTime(2010, 03, 31)#-Dates.Month(3)
parameters, initial_conditions = BeforeIT.get_params_and_initial_conditions(
    (calibration = calibration_data,
    figaro = figaro,
    data = data,
    ea = ea,
    max_calibration_date = max_calibration_date,
    estimation_date = estimation_date), calibration_date;
    scale = 0.001,
)

for key in collect(keys(initial_conditions))[1:end]
    println(key)
    @assert isapprox(initial_conditions[key], initial_conditions[key])
end

println(" ")
println("PARAMS")
println(" ")

# for key in collect(keys(parameters_mat))[2:end]
#     println(key)
#     println(parameters_mat[key])
#     println(parameters[key])
#     @assert isapprox(parameters_mat[key], parameters[key])
# end
