
using Aqua

@testset "Code quality" begin
	Aqua.test_all(BeforeIT, ambiguities = false, unbound_args = false)
	@test Test.detect_ambiguities(BeforeIT) == Tuple{Method, Method}[]
end