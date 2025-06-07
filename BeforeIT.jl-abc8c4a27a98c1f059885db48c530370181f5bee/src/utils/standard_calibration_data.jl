
using MAT, Dates

dir = joinpath(splitpath(dirname(pathof(@__MODULE__)))[1:end-1])

nation = "italy"

# Load calibration data (with figaro input-output tables)
calibration_data = matread(joinpath(dir, "data/" * nation * "/calibration/calibration/2010Q1.mat"))["calibration_data"]
figaro = matread(joinpath(dir, "data/" * nation * "/calibration/figaro/2010.mat"))["figaro"]

# Load time series data
data = matread(joinpath(dir, "data/" * nation * "/calibration/data/1996.mat"))["data"]
ea = matread(joinpath(dir, "data/" * nation * "/calibration/ea/1996.mat"))["ea"]

# add calibration times to the data
max_calibration_date = DateTime(2016, 12, 31)
estimation_date = DateTime(1996, 12, 31)


struct CalibrationData
    calibration::Dict{String, Any}
    figaro::Dict{String, Any}
    data::Dict{String, Any}
    ea::Dict{String, Any}
    max_calibration_date::DateTime
    estimation_date::DateTime
end

const ITALY_CALIBRATION = CalibrationData(calibration_data, figaro, data, ea, max_calibration_date, estimation_date)
