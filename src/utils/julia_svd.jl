
using LinearAlgebra

function pure_svd(A::AbstractMatrix{T}; tol=1e-15, max_iter=100) where {T}
    # 1. Promote to float to prevent integer overflow/type errors
    T_float = float(T)
    m, n = size(A)

    # 2. Handle Tall Matrices (Recursive Transpose)
    # If m < n, we compute svd(A') => A = V * S * U'
    if m < n
        s = pure_svd(copy(A'); tol=tol, max_iter=max_iter)
        return SVD(collect(s.Vt'), s.S, collect(s.U'))
    end

    # 3. Initialization
    # U starts as A. Jacobi rotations will orthogonalize its columns.
    U = copy(convert(Matrix{T_float}, A)) 
    V = Matrix{T_float}(I, n, n)
    
    # 4. Main One-Sided Jacobi Loop (Orthogonalization)
    for iter in 1:max_iter
        count = 0
        for i in 1:(n-1)
            for j in (i+1):n
                # Check orthogonality of columns i and j
                xi = view(U, :, i)
                xj = view(U, :, j)
                
                aii = dot(xi, xi)
                ajj = dot(xj, xj)
                aij = dot(xi, xj)
                
                # If not orthogonal enough...
                if abs(aij) > tol * sqrt(aii * ajj)
                    count += 1
                    
                    # Compute rotation parameters
                    tau = (ajj - aii) / (2 * aij)
                    sgn = sign(tau)
                    if sgn == 0; sgn = one(T_float); end
                    t = sgn / (abs(tau) + sqrt(1 + tau^2))
                    c = 1 / sqrt(1 + t^2)
                    s_val = c * t
                    
                    # Apply rotation to U columns
                    # (Manually unrolled loop for clarity/performance)
                    @inbounds for k in 1:m
                        uik = U[k, i]
                        ujk = U[k, j]
                        U[k, i] = c * uik - s_val * ujk
                        U[k, j] = s_val * uik + c * ujk
                    end
                    
                    # Apply rotation to V columns
                    @inbounds for k in 1:n
                        vik = V[k, i]
                        vjk = V[k, j]
                        V[k, i] = c * vik - s_val * vjk
                        V[k, j] = s_val * vik + c * vjk
                    end
                end
            end
        end
        if count == 0; break; end
    end
    
    # 5. Extract Singular Values and Fix "Broken" U Columns
    singular_vals = zeros(T_float, n)
    
    # 6. Sort by descending singular values - WAIT, computed above? No. 
    # We do Step 5 first.
    
    # Calculate scale of the matrix to distinguish noise from signal
    # We use the maximum column norm as a reference.
    max_col_norm = zero(T_float)
    for j in 1:n
        max_col_norm = max(max_col_norm, norm(view(U, :, j)))
    end
    
    rank_tol = max(floatmin(T_float), max_col_norm * tol)
    
    for j in 1:n
        # Current column norm is the singular value
        col_norm = norm(view(U, :, j))
        singular_vals[j] = col_norm
        
        if col_norm > rank_tol
            # Case A: Normal column. Just normalize it.
            @. U[:, j] /= col_norm
        else
            # Case B: Rank Deficient (Zero column).
            # We must find a new unit vector orthogonal to all other columns.
            singular_vals[j] = 0.0
            
            # Try standard basis vectors e_1, e_2, ... until we find one 
            # that isn't parallel to existing columns.
            generated_vector = zeros(T_float, m)
            found_direction = false
            
            for k in 1:m
                fill!(generated_vector, 0.0)
                generated_vector[k] = 1.0 # candidate: standard basis e_k
                
                # Gram-Schmidt: Project out all OTHER columns of U
                for other_col in 1:n
                    if other_col == j; continue; end
                    
                    # u_other is already normalized (or will be fixed later).
                    # We project our candidate against it.
                    u_other = view(U, :, other_col)
                    
                    # Only project if u_other has non-zero norm (is valid)
                    denom = dot(u_other, u_other)
                    if denom > floatmin(T_float)^2
                        overlap = dot(generated_vector, u_other)
                        @. generated_vector -= (overlap / denom) * u_other
                    end
                end
                
                # Check if candidate survived projection
                rem_norm = norm(generated_vector)
                if rem_norm > rank_tol
                    @. U[:, j] = generated_vector / rem_norm
                    found_direction = true
                    break
                end
            end
            
            # If standard basis failed (highly unlikely unless m < n),
            # fallback to random noise (last resort)
            if !found_direction
                rand!(generated_vector)
                # Repeat projection logic
                for other_col in 1:n
                    if other_col == j; continue; end
                    u_other = view(U, :, other_col)
                    denom = dot(u_other, u_other)
                    if denom > floatmin(T_float)^2
                        overlap = dot(generated_vector, u_other)
                        @. generated_vector -= (overlap / denom) * u_other
                    end
                end
                @. U[:, j] = generated_vector / norm(generated_vector)
            end
        end
    end
    
    # 6. Sort by descending singular values
    p = sortperm(singular_vals, rev=true)
    
    return SVD(U[:, p], singular_vals[p], copy(V[:, p]'))
end
