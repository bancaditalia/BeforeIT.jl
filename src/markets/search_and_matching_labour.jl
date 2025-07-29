"""
    search_and_matching_labour(firms::Firms, model)

This function implements a labor search and matching algorithm. It takes in a `Firms` object and a `Model` object as 
input. The `Firms` object contains information about the number of desired employees (`N_d_i`) and the current number 
of employees (`N_i`) for each firm. The `model` object contains information about the current employment 
status (`O_h`) of each worker.

The function performs the following steps:
- Calculates the vacancies (`V_i`) for each firm as the difference between desired and current employees.
- Identifies employed workers and shuffles them randomly.
- Fires workers from firms with negative vacancies to adjust the workforce.
- Identifies unemployed workers and firms with positive vacancies.
- Randomly matches unemployed workers to firms with vacancies until all vacancies are filled or there are no more unemployed workers.

The function returns:
- `N_i`: An updated array of the number of employed workers for each firm.
- `O_h`: An updated array where each element represents the firm a worker is employed with (0 if unemployed).
"""
function search_and_matching_labour(firms::AbstractFirms, model::AbstractModel)

    N_d_i = firms.N_d_i
    N_i = firms.N_i
    O_h = model.w_act.O_h

    V_i = N_d_i .- N_i

    # get employed workers in random order
    H_E = findall(O_h .> 0)
    fshuffle!(H_E)

    # fire workers if vacancies are negative
    for h in H_E

        # find employer of worker
        i = O_h[h]

        # if employer has negative vacancies, fire the worker
        if V_i[i] < 0
            O_h[h] = 0
            N_i[i] -= 1
            V_i[i] += 1
        end
    end

    # find unemployed workers and positive vacancies
    H_U = findall(O_h .== 0)
    fshuffle!(H_U)
    I_V = findall(V_i .> 0)

    # while there are no more vacancies or unemployed workers
    while !isempty(H_U) && !isempty(I_V)
        fshuffle!(I_V)
        for i in I_V
            # select random unemployed worker
            h = H_U[1]
            # employ worker
            O_h[h] = i
            N_i[i] += 1
            V_i[i] -= 1
            popfirst!(H_U)
            isempty(H_U) && break
        end
        ufilter!(i -> V_i[i] > 0, I_V)
    end

    return N_i, O_h
end
