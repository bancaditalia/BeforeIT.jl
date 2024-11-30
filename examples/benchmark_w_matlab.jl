## Comparing the performance of the Julia and MATLAB implementations

# We can compare the performance of the Julia and MATLAB implementations
# by running the same model for the same number of epochs and measuring
# the time taken.

using BeforeIT, StatsPlots, Statistics, ThreadPinning

pinthreads(:cores)

function run(parameters, initial_conditions, T; multi_threading = false)
    model = BeforeIT.init_model(parameters, initial_conditions, T)
    data = BeforeIT.init_data(model);
    
    for _ in 1:T
        BeforeIT.run_one_epoch!(model; multi_threading = multi_threading)
        BeforeIT.update_data!(data, model)
    end
    return model, data
end

parameters = BeforeIT.AUSTRIA2010Q1.parameters
initial_conditions = BeforeIT.AUSTRIA2010Q1.initial_conditions
T = 1

# We run the code to compile it first
@time run(parameters, initial_conditions, T; multi_threading = false);
@time run(parameters, initial_conditions, T; multi_threading = true);

# Time taken by the MATLAB code and the Generated C code with MATLAB Coder
# (6 threads for the parallel version), computed independently on an AMD Ryzen 5 5600H
matlab_times = [4.399592, 4.398576, 4.352314, 4.385039, 4.389989]
matlab_times ./= T
matlab_times = [matlab_times, [1000.0, 1000.0, 1000.0, 1000.0, 1000.0]]
matlab_time = mean.(matlab_times)
matlab_time_std = std.(matlab_times)

c_times = [0.952, 0.940, 0.951, 0.942, 0.938]
c_times ./= T
c_times = [c_times, [1000.0, 1000.0, 1000.0, 1000.0, 1000.0]]
c_time = mean.(c_times)
c_time_std = std.(c_times)

c_times_multi_thread = [0.305, 0.324, 0.330, 0.334, 0.323]
c_times_multi_thread ./= T
c_times_multi_thread = [c_times_multi_thread, [1000.0, 1000.0, 1000.0, 1000.0, 1000.0]]
c_time_multi_thread = mean.(c_times_multi_thread)
c_time_multi_thread_std = std.(c_times_multi_thread)

# Time taken by the Julia code (same platform as in the the matlab benchmarks),
# computed as the average of 5 runs
n_runs = 5

julia_times_1_thread = zeros(n_runs)   
for i in 1:n_runs
    julia_times_1_thread[i] = @elapsed run(parameters, initial_conditions, T; multi_threading = false);
end
julia_times_1_thread ./= T
julia_times_1_thread = [julia_times_1_thread, [61.010209, 60.503288, 61.343696, 60.170186, 59.275483]]
julia_time_1_thread = mean.(julia_times_1_thread)
julia_time_1_thread_std = std.(julia_times_1_thread)

julia_times_multi_thread = zeros(n_runs)
for i in 1:5
    julia_times_multi_thread[i] =  @elapsed run(parameters, initial_conditions, T; multi_threading = true);
end
julia_times_multi_thread ./= T
julia_times_multi_thread = [julia_times_multi_thread, [35.904997, 34.800452, 36.283711, 35.967733, 37.254648]]
julia_time_multi_thread = mean.(julia_times_multi_thread)
julia_time_multi_thread_std = std.(julia_times_multi_thread)

# Get the number of threads used
n_threads = Threads.nthreads()

theme(:default, bg = :white)

means = reduce(hcat, [matlab_time, c_time, c_time_multi_thread, 
           julia_time_1_thread, julia_time_multi_thread])'

stds = reduce(hcat, [matlab_time_std, c_time_std, c_time_multi_thread_std, 
               julia_time_1_thread_std, julia_time_multi_thread_std])'

ix1, ix2 = [1], [2]
means1, means2 = means[:, ix1], means[:, ix2]

scaler = 1 * maximum(means1) / maximum(means2)

means[:, ix2] .*= scaler

labels = ["MATLAB", "Gen. C, 1 thread", "Gen. C, 6 threads", "BeforeIT.jl, 1 thread", "BeforeIT.jl, 6 threads"]

p3 = groupedbar(means, yerr = stds, ylabel="mean time for one epoch (s)", 
                labels=["\$8\\cdot10^3\\textrm{\\:agents}\$" "\$8\\cdot10^6\\textrm{\\:agents}\$"],
                xticks=(1:size(means,1), labels), foreground_color_legend=nothing, xtickfont = font(5),
                ytickfont = font(8), guidefont = font(8), grid=false, dpi=1200);

plot!(twinx(),  ylims=ylims(p3)./scaler, ylabel="",
      xtickfont = font(5), ytickfont = font(8), guidefont = font(8))

# Save the image
savefig("benchmark_w_matlab.png")

# The Julia implementation is faster than the MATLAB implementation, and the multi-threaded version is
# faster than the single-threaded version.
