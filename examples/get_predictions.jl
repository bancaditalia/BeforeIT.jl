# In this tutorial we illustrate how to get predictions from the model for
# a number of quarters starting from previous simulations.

using BeforeIT, FileIO
using Dates

year_ = 2010
number_years = 9
number_quarters = 4 * number_years
horizon = 12
number_seeds = 4
number_sectors = 62

# Load the real time series
data = BeforeIT.ITALY_CALIBRATION.data

quarters_num = []
year_m = year_
for month in 4:3:((number_years + 1) * 12 + 1)
    year_m = year_ + (month ÷ 12)
    mont_m = month % 12
    date = DateTime(year_m, mont_m, 1) - Day(1)
    push!(quarters_num, BeforeIT.date2num(date))
end

for i in 1:number_quarters
    quarter_num = quarters_num[i]
    BeforeIT.get_predictions_from_sims(data, quarter_num, horizon, number_seeds)
end
