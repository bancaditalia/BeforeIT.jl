
"""
Possible alternative to deleteat! if the equivalence
between the two methods holds
"""
function swap_pop!(A, i)
	A[i], A[end] = A[end], A[i]
	pop!(A)
end