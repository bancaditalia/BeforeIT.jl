
using Aqua

@testset "Code quality" begin
	Aqua.test_all(Bit, ambiguities = false, unbound_args = false, 
	persistent_tasks = (tmax = 60,)) # Windows might need more time...
	@test Test.detect_ambiguities(Bit) == Tuple{Method, Method}[]
end