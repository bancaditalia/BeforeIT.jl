
using Aqua

@testset "Code quality" begin
	Aqua.test_all(Bit, ambiguities = false, unbound_args = false)
	@test Test.detect_ambiguities(Bit) == Tuple{Method, Method}[]
end