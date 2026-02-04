"""
    svd_mx2(A::AbstractMatrix{T}) where T -> SVD

Compute the SVD of an M x 2 matrix A analytically. Returns a `LinearAlgebra.SVD` object.

### Logic Overview:
This function avoids general iterative SVD algorithms by solving the 2x2 problem analytically.
1. **Reduce to 2x2**: We find eigenvalues and eigenvectors of A'A (a symmetric 2x2 matrix).
   - Eigenvalues of A'A are singular values squared (σ₁², σ₂²).
   - Eigenvectors of A'A form the orientation of the input space (V).
2. **Analytical Solution**:
   - The rotation angle θ for V is found via `atan(2γ, α-β)`, which diagonalizes A'A.
   - Singular values are then computed as the norms of the rotated columns (A*V).
3. **Handle Rank Deficiency & Dimension**:
   - For M=1, only one singular value exists. U is 1x1.
   - For M≥2, two singular values are returned. U is Mx2.
   - We ensure U remains orthonormal by "inventing" orthogonal directions using Gram-Schmidt when singular values are near zero.
"""
function svd_mx2(A::AbstractMatrix)
    M, N = size(A)

    # 1. Rotation angle for V
    c1, c2 = view(A,:,1), view(A,:,2)
    α, β, γ = dot(c1,c1), dot(c2,c2), dot(c1,c2)

    θ = 0.5 * atan(2γ, α-β)
    c, s = cos(θ), sin(θ)
    V = [c -s; s c]

    W = A * V

    if M == 1
        s1 = norm(view(W, :, 1))
        S = [s1]
        u1 = s1 > 0 ? W[:, 1] ./ s1 : [1.0]
        U = reshape(u1, 1, 1)
    else
        s1, s2 = norm(view(W, :, 1)), norm(view(W, :, 2))
        S = [s1, s2]

        # 3. Construct orthonormal U by normalizing W
        # S[1] > 0 is numerically safe; S[2] uses a relative threshold
        u1 = s1 > 1e-15 ? W[:, 1] ./ s1 : [1.0; zeros(Float64, M-1)]
        u2 = if s2 > 1e-15
            W[:, 2] ./ s2
        else
            # Gram-Schmidt fallback for orthonormality
            v = zeros(Float64, M)
            v[argmin(abs.(u1))] = 1.0
            v .-= dot(u1, v) .* u1
            v ./= norm(v)
        end
        U = hcat(u1, u2)
    end

    return SVD(U, S, V')
end
