import BeforeIT as Bit
using FileIO, Dates







function test_predictions_equivalence(quarter_num; tolerance=1e-10)
    date = Bit.num2date(quarter_num)
    year_str = string(year(date))
    quarter_str = string(quarterofyear(date))
    
    # Define file paths
    output_file = "data/italy/abm_predictions/" * year_str * "Q" * quarter_str * ".jld2"
    backup_file = "data/italy/abm_predictions/backup_" * year_str * "Q" * quarter_str * ".jld2"
    
    # Load both results
    original_dict = load(backup_file)["model_dict"]
    new_dict = load(output_file)["model_dict"]
    
    # Compare results
    all_equal = true
    differences = Dict()
    
    # Check for key differences
    original_keys = Set(keys(original_dict))
    new_keys = Set(keys(new_dict))
    
    missing_keys = setdiff(original_keys, new_keys)
    extra_keys = setdiff(new_keys, original_keys)
    
    if !isempty(missing_keys)
        println("Keys missing in new function: $(missing_keys)")
        all_equal = false
    end
    
    if !isempty(extra_keys)
        println("Extra keys in new function: $(extra_keys)")
        all_equal = false
    end
    
    # Check for value differences
    for key in intersect(original_keys, new_keys)
        if isa(original_dict[key], Array) && eltype(original_dict[key]) <: Number
            # For numeric arrays, compare with tolerance
            if size(original_dict[key]) != size(new_dict[key])
                println("Size mismatch for $key: $(size(original_dict[key])) vs $(size(new_dict[key]))")
                all_equal = false
                continue
            end
            
            try
                max_diff = maximum(abs.(original_dict[key] - new_dict[key]))
                if max_diff > tolerance
                    println("Values differ for $key by maximum of $max_diff")
                    differences[key] = max_diff
                    all_equal = false
                end
            catch e
                println("Error comparing arrays for $key: $e")
                all_equal = false
            end
        elseif original_dict[key] != new_dict[key]
            println("Values differ for $key")
            all_equal = false
        end
    end
        
    return all_equal, differences
end

"""
Run tests across multiple quarters and provides a summary of results.
"""
function run_prediction_tests()

    # Test parameters
    start_year = 2010
    num_years = 10  # Test 1 year (4 quarters)
    
    # Run tests
    passed = 0
    total = num_years * 4
    
    println("Testing modularized prediction function against original implementation")
    println("================================================================")
    
    for year in start_year:(start_year + num_years - 1)
        for quarter in 1:4
            date = DateTime(year, 3*quarter, 1) - Day(1)
            quarter_num = Bit.date2num(date)
            
            println("\nTesting $(year)Q$quarter...")
            result, diffs = test_predictions_equivalence(quarter_num)
            
            if result
                println("✓ Test PASSED for $(year)Q$quarter")
                passed += 1
            else
                println("✗ Test FAILED for $(year)Q$quarter with $(length(diffs)) differences")
                if !isempty(diffs)
                    for (i, (key, diff)) in enumerate(sort(collect(pairs(diffs)), by=x->x[2], rev=true))
                        println("  - $key: max difference $diff")
                        i >= 5 && length(diffs) > 5 && println("  - ... ($(length(diffs)-5) more differences omitted)") && break
                    end
                end
            end
        end
    end
    
    # Summary
    println("\n================================================================")
    println("SUMMARY: $passed/$total tests passed")
    
    if passed == total
        println("✓ SUCCESS! The functions produce equivalent results.")
        return true
    else
        println("✗ FAILURE! The functions produce different results.")
        return false
    end
end

# Run the tests
run_prediction_tests()