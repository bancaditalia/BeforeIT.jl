function search_and_matching_labor!(world::Ark.World)
    calculate_initial_vacancies!(world)
    fire_employed_workers!(world)
    build_hiring_firms_cache!(world)
    hire_workers!(world)
    return nothing
end

function calculate_initial_vacancies!(world::Ark.World)
    for (_, vacancies, desired_employment, employment) in Ark.Query(world, (Components.Vacancies, Components.DesiredEmployment, Components.Employment))
        vacancies.amount .= desired_employment.amount - employment.amount
    end
    return nothing
end

function build_hiring_firms_cache!(world)
    cache = Ark.get_resource(world, HiringFirmsCache)
    reset_cache!(cache)

    for (e, desired_employment, employment) in Ark.Query(world, (Components.DesiredEmployment, Components.Employment))
        for i in eachindex(e)
            BeforeIT.emblace!(desired_employment[i].amount - employment[i].amount, employment[i].amount, e[i], cache)
        end
    end

    return nothing
end

function fire_employed_workers!(world::Ark.World)
    f = Ark.Filter(world, (Components.Employed,), with = (Components.EmployedAt,))
    Ark.shuffle_entities!(f)
    remove_employment = Vector{Ark.Entity}()
    for (firm_e, vacancies, employment) in Ark.Query(world, (Components.Vacancies, Components.Employment))
        for i in eachindex(firm_e)

            for (worker_e, _) in Ark.Query(world, (Components.EmployedAt,), relations = (Components.EmployedAt => firm_e[i],))
                for j in eachindex(worker_e)
                    vacancies[i].amount >= 0 && break
                    push!(remove_employment, worker_e[j])
                    vacancies[i] = Components.Vacancies(vacancies[i].amount + 1)
                    employment[i] = Components.Employment(employment[i].amount - 1)
                end
            end
        end
    end

    for now_unemployed in remove_employment
        Ark.exchange_components!(
            world, now_unemployed,
            remove = (Components.Employed, Components.EmployedAt),
            add = (Components.Unemployed(0.0),)
        )
    end

    return nothing
end

function hire_workers!(world::Ark.World)

    cache = Ark.get_resource(world, HiringFirmsCache)
    f = Ark.Filter(world, (Components.Unemployed,))
    firms = Ark.Filter(world, (Components.Vacancies, Components.Employment))
    Ark.shuffle_entities!(f)
    Ark.shuffle_entities!(firms)

    add_employment = Dict{Ark.Entity, Ark.Entity}()


    while cache.nhiring > 0 && nunemployed > 0
        shuffle!(view(cache.active, 1:cache.nhiring))
        i = 1
        while i < cache.nhiring
            firm_index = cache.active[i]

            if iszero(cache.vacancies[firm_index])
                active[i] = active[cache.nhiring]
                cache.nhiring -= 1
            else
                i += 1
            end
        end

    end

    for (worker_e, firm_e) in add_employment
        Ark.exchange_components!(
            world, worker_e,
            remove = (Components.Unemployed,),
            add = (Components.Employed(0.0), Components.EmployedAt()),
            relations = (Components.EmployedAt => firm_e,)
        )
    end


    return nothing
end
