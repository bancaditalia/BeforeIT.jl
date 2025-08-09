#!/bin/bash

OUTPUT_CSV="benchmark_results.csv"

if [ -f "$OUTPUT_CSV" ]; then
    echo "Removing existing $OUTPUT_CSV"
    rm "$OUTPUT_CSV"
fi

echo "Threads,BenchmarkType,MedianTime_ns" > "$OUTPUT_CSV"

# Loop through thread counts from 1 to 6
for i in $(seq 1 6); do
    echo "Running benchmarks with $i threads..."
    julia -e """
    using ThreadPinning
    using BenchmarkTools
    using CSV
    using DataFrames

    pinthreads(:cores)

    import BeforeIT as Bit

    function run_model(parameters, initial_conditions, T)
        model = Bit.Model(parameters, initial_conditions)
        Bit.run!(model, T; parallel = true)
    end

    function ensemble_run_model(parameters, initial_conditions, T)
        models = (Bit.Model(parameters, initial_conditions) for _ in 1:24)
        Bit.ensemblerun!(models, T; parallel = true)
    end

    parameters = Bit.AUSTRIA2010Q1.parameters
    initial_conditions = Bit.AUSTRIA2010Q1.initial_conditions
    T = 12

    b1 = @benchmark run_model(\$parameters, \$initial_conditions, \$T) seconds=20
    b2 = @benchmark ensemble_run_model(\$parameters, \$initial_conditions, \$T) seconds=20

    min_b1_ns = minimum(b1.times)
    min_b2_ns = minimum(b2.times)

    num_threads = Threads.nthreads()

    # Append results to CSV
    open(\"$OUTPUT_CSV\", \"a\") do io
        CSV.write(io, DataFrame(Threads = num_threads, BenchmarkType = \"run_model\", MedianTime_ns = min_b1_ns); append=true, header=false)
        CSV.write(io, DataFrame(Threads = num_threads, BenchmarkType = \"ensemble_run_model\", MedianTime_ns = min_b2_ns); append=true, header=false)
    end
    """ --threads=$i --gcthreads=$i --check-bounds=no
done

echo "Benchmarks completed and results saved to $OUTPUT_CSV"

set +H

julia -e """
using CSV, Plots, DataFrames

df = CSV.read(\"benchmark_results.csv\", DataFrame)

run_model_1thread_time = df[(df.Threads .== 1) .& (df.BenchmarkType .== \"run_model\"), :MedianTime_ns][1]
ensemble_run_model_1thread_time = df[(df.Threads .== 1) .& (df.BenchmarkType .== \"ensemble_run_model\"), :MedianTime_ns][1]

df[!, :NormalizedTime] = zeros(Float64, nrow(df))

for i in 1:nrow(df)
    row = df[i, :]
    if row.BenchmarkType == \"run_model\"
        df[i, :NormalizedTime] = run_model_1thread_time / row.MedianTime_ns 
    elseif row.BenchmarkType == \"ensemble_run_model\"
        df[i, :NormalizedTime] = ensemble_run_model_1thread_time / row.MedianTime_ns
    end
end

m = maximum(df[df.BenchmarkType .== \"ensemble_run_model\", :NormalizedTime])
cm = ceil(Int, m) - m > 0.5 ? ceil(Int, m) - 0.5 : ceil(Int, m)

plot(
    df[df.BenchmarkType .== \"run_model\", :Threads],
    df[df.BenchmarkType .== \"run_model\", :NormalizedTime],
    label=\"intra\",
    marker=:circle,
    linewidth=2,
    xlabel=\"Number of Threads\",
    ylabel=\"Speed-up w.r.t. 1 thread\",
    title=\"Performance Scalability\",
    legend=:bottomright,
    ylim=(1, cm),
    yticks = 1:0.5:cm
)

plot!(
    df[df.BenchmarkType .== \"ensemble_run_model\", :Threads],
    df[df.BenchmarkType .== \"ensemble_run_model\", :NormalizedTime],
    label=\"ensemble\",
    marker=:square,
    linewidth=2
)

savefig(\"benchmark_plot.png\")

println(\"Plot saved to benchmark_plot.png\")
"""
