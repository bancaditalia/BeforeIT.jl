# Here we show how to get simulations for all quarters
# from `2010Q1` to `2019Q4`, and for all years from 2010 to 2019.

import BeforeIT as Bit

using MAT, FileIO

# The following code loads the parameters and initial conditions,
# it initialises the model, runs the model `n_sims` times, and finally
# saves the `data_vector` into a `.jld2` file with an appropriate name.
# The whole process is repeatead for all quarters from `2010Q1` to `2019Q4`,
# and for all years from 2010 to 2019.

for year in 2010:2019
    for quarter in 1:4
        println("Y: ", year, " Q: ", quarter)
        parameters = load("data/italy/parameters/" * string(year) * "Q" * string(quarter) * ".jld2")
        initial_conditions = load("data/italy/initial_conditions/" * string(year) * "Q" * string(quarter) * ".jld2")
        T = 12
        model = Bit.init_model(parameters, initial_conditions, T)
        n_sims = 4
        data_vector = Bit.ensemblerun(model, n_sims)
        save("data/italy/simulations/" * string(year) * "Q" * string(quarter) * ".jld2", "data_vector", data_vector)
    end
end
