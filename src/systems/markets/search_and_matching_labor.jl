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


#TODO: Make this more efficient 111ms :(
function hire_workers!(world::Ark.World)

    f = Ark.Filter(world, (Components.Unemployed,))
    firms = Ark.Filter(world, (Components.Vacancies, Components.Employment))
    Ark.shuffle_entities!(f)
    Ark.shuffle_entities!(firms)

    add_employment = Dict{Ark.Entity, Ark.Entity}()


    for (worker_e, unemployed) in Ark.Query(world, (Components.Unemployed,))
        for j in eachindex(worker_e)

            for (firm_e, vacancies, employment) in Ark.Query(firms)
                for i in shuffle(eachindex(firm_e))
                    if vacancies[i].amount <= 0 || haskey(add_employment, worker_e[j])
                        continue
                    end
                    vacancies[i] = Components.Vacancies(vacancies[i].amount - 1)
                    employment[i] = Components.Employment(employment[i].amount + 1)
                    add_employment[worker_e[j]] = firm_e[i]
                    break
                end
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
