
# # Comparing the performance of the Julia and MATLAB implementations

# We can compare the performance of the Julia and MATLAB implementations
# by running the same model for the same number of epochs and measuring
# the time taken.

using BeforeIT, Plots, Statistics

function run(parameters, initial_conditions, T; multi_threading = false)
    model = BeforeIT.init_model(parameters, initial_conditions, T)
    data = BeforeIT.init_data(model);
    
    for _ in 1:T
        BeforeIT.one_epoch!(model; multi_threading = multi_threading)
        BeforeIT.update_data!(data, model)
    end
    return model, data
end

parameters = BeforeIT.AUSTRIA2010Q1.parameters
initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
T = 12 

# we run the code to compile it first
@time run(parameters, initial_conditions, T; multi_threading = false);
@time run(parameters, initial_conditions, T; multi_threading = true);

# time taken by the MATLAB code and the Generated Mex code with C backend
# in MATLAB Coder with 6 threads, computed independently on an AMD Ryzen 5 5600H
matlab_times = [4.399592, 4.398576, 4.352314, 4.385039, 4.389989]
matlab_time = mean(matlab_times)
matlab_time_std = std(matlab_times)

c_times = [1.083792, 1.092614, 1.087623, 1.081414, 1.086691]
c_time = mean(c_times)
c_time_std = std(c_times)

c_times_multi_thread = [0.449823, 0.452169, 0.445972, 0.462876, 0.435441]
c_time_multi_thread = mean(c_times_multi_thread)
c_time_multi_thread_std = std(c_times_multi_thread)

# time taken by the Julia code (same platform as in the the matlab benchmarks),
# computed as the average of 5 runs
n_runs = 5

julia_times_1_thread = zeros(n_runs)   
for i in 1:n_runs
    julia_times_1_thread[i] = @elapsed run(parameters, initial_conditions, T; multi_threading = false);
end
julia_time_1_thread = mean(julia_times_1_thread)
julia_time_1_thread_std = std(julia_times_1_thread)

julia_times_multi_thread = zeros(n_runs)
for i in 1:5
    julia_times_multi_thread[i] =  @elapsed run(parameters, initial_conditions, T; multi_threading = true);
end
julia_time_multi_thread = mean(julia_times_multi_thread)
julia_time_multi_thread_std = std(julia_times_multi_thread)

# get the number of threads used
n_threads = Threads.nthreads()

theme(:default, bg = :white)

# bar chart of the time taken vs the time taken by the MATLAB code, also plot the stds as error bars
# make a white background with no grid
bar(
    ["MATLAB", "Gen. C, 1 thread", "Gen. C, 6 threads", "Julia, 1 thread", "Julia, $n_threads threads"], 
    [matlab_time, c_time, c_time_multi_thread, julia_time_1_thread, julia_time_multi_thread], 
    yerr = [matlab_time_std, c_time_std, c_time_multi_thread_std, julia_time_1_thread_std, julia_time_multi_thread_std],
    legend = false, 
    dpi = 300, 
    size = (400, 300), 
    grid = false, 
    ylabel = "Time for one simulation (s)",
    xtickfont = font(4),
    ytickfont = font(6),
    guidefont = font(6)
)


# the Julia implementation is faster than the MATLAB implementation, and the multi-threaded version is
# faster than the single-threaded version.

# increase

# save the image
savefig("benchmark_w_matlab.png")
