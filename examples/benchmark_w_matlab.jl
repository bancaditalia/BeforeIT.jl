## Comparing the performance of the Julia and MATLAB implementations

# We can compare the performance of the Julia and MATLAB implementations
# by running the same model for the same number of epochs and measuring
# the time taken.

import BeforeIT as Bit

using CairoMakie, Statistics, ThreadPinning

pinthreads(:cores)

function run(parameters, initial_conditions, T; multi_threading = false)
    model = Bit.Model(parameters, initial_conditions)
    data = Bit.Data(model);
    
    for _ in 1:T
        Bit.step!(model; multi_threading = multi_threading)
        Bit.update_data!(data, model)
    end
    return model, data
end

parameters = Bit.AUSTRIA2010Q1.parameters
initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
T = 12

# We run the code to compile it first
@time run(parameters, initial_conditions, T; multi_threading = false);
@time run(parameters, initial_conditions, T; multi_threading = true);

# Time taken by the MATLAB code and the Generated C code with MATLAB Coder
# (4 threads for the parallel version), computed independently on an 
# AMD Ryzen 5 5600H
matlab_times_small = [4.399592, 4.398576, 4.352314, 4.385039, 4.389989] ./ T
matlab_times_big = [2000.189556, 1990.485305, 2002.295329, 1994.215843, 1993.651854]
matlab_mtime_small = mean(matlab_times_small)
matlab_stime_small = std(matlab_times_small)
matlab_mtime_big = mean(matlab_times_big)
matlab_stime_big = std(matlab_times_big)

c_times_small = [0.952, 0.940, 0.951, 0.942, 0.938] ./ T
c_times_big = [574.692, 576.725, 572.382, 573.921, 575.949]
c_mtime_small = mean(c_times_small)
c_stime_small = std(c_times_small)
c_mtime_big = mean(c_times_big)
c_stime_big = std(c_times_big)

c_times_small_multi = [0.305, 0.324, 0.330, 0.334, 0.323] ./ T
c_times_big_multi = [209.603, 210.197, 209.610, 211.759, 209.174]
c_mtime_small_multi = mean(c_times_small_multi)
c_stime_small_multi = std(c_times_small_multi)
c_mtime_big_multi = mean(c_times_big_multi)
c_stime_big_multi = std(c_times_big_multi)

# timings from "High-performance computing implementations of agent-based
# economic models for realizing 1: 1 scale simulations of large
# economies", A. Gill et al. (2021)
hpc_mtime_big_multi = 22.92
hpc_mtime_big = hpc_mtime_big_multi*4

# Time taken by the Julia code (same platform as in the matlab benchmarks),
# computed as the average of 5 runs
n_runs = 5

julia_times_small = zeros(n_runs)   
for i in 1:n_runs
    julia_times_small[i] = @elapsed run(parameters, initial_conditions, T; multi_threading = false);
end
julia_times_small ./= T
julia_times_big = [56.593792, 56.297404, 54.682004, 55.079674, 55.192496]
julia_mtime_small = mean(julia_times_small)
julia_stime_small = std(julia_times_small)
julia_mtime_big = mean(julia_times_big)
julia_stime_big = std(julia_times_big)

julia_times_small_multi = zeros(n_runs)
for i in 1:5
    julia_times_small_multi[i] =  @elapsed run(parameters, initial_conditions, T; multi_threading = true);
end
julia_times_small_multi ./= T
julia_times_big_multi = [32.981467, 32.243157, 33.016562, 33.957509, 33.046763]
julia_mtime_small_multi = mean(julia_times_small_multi)
julia_stime_small_multi = std(julia_times_small_multi)
julia_mtime_big_multi = mean(julia_times_big_multi)
julia_stime_big_multi = std(julia_times_big_multi)

labels = ["MATLAB", "Gen. C - 1 core", "Gen. C - 4 cores", "HPC - 1 core*", "HPC - 4 cores*", 
          "BeforeIT.jl - 1 core", "BeforeIT.jl - 4 cores"]

# Create the layout
fig = Figure(size = (800, 400));

ax1 = Axis(fig[1, 1], ylabel="time for one epoch (s)", title="Model with 8 thousand agents")
ax2 = Axis(fig[1, 2], title="Model with 8 million agents")

times_small = [matlab_mtime_small, c_mtime_small, c_mtime_small_multi, julia_mtime_small, julia_mtime_small_multi]
barplot!(ax1,
    1:5,
    times_small,
    bar_labels = :y,
);
ylims!(ax1, 0, 1.15*maximum(times_small))

ax1.yticklabelspace = 25.0
ax1.xticks = (1:5, [labels[1:3]..., labels[6:end]...])
ax1.xticklabelrotation = 45.0
ax1.xgridvisible = false

times_big = [matlab_mtime_big, c_mtime_big, c_mtime_big_multi, hpc_mtime_big, hpc_mtime_big_multi, 
             julia_mtime_big, julia_mtime_big_multi]

ylims!(ax2, 0, 1.15*maximum(times_big))
barplot!(ax2,
    1:7,
    round.(times_big, digits=1),
    bar_labels = :y
);
ax2.xticks = (1:7, labels)
ax2.xticklabelrotation = 45.0
ax2.xgridvisible = false

# Save or display the layout
display(fig)

save("benchmark_w_matlab.png", fig)
