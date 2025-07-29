
import BeforeIT as Bit

using Test

ft = [1 2 3 4 5 6 7 8]
expected_output = [10 26]
actual_output = Bit.toannual(ft)
@test actual_output == expected_output

ft = [1 2 3 4 5 6 7 8
      1 2 3 4 5 6 7 8
      1 2 3 4 5 6 7 8]
expected_output = [10 26; 10 26; 10 26]
actual_output = Bit.toannual(ft)
@test actual_output == expected_output

ftsa = [1 2 3 4 5 6 7 8]
expected_output = [2.5 6.5]
output = Bit.toannual_mean(ftsa)
@test size(output) == size(expected_output)

ftsa = [1 2 3 4 5 6 7 8
        1 2 3 4 5 6 7 8
        1 2 3 4 5 6 7 8]
expected_output = [2.5 6.5; 2.5 6.5; 2.5 6.5]
output = Bit.toannual_mean(ftsa)
@test output == expected_output
