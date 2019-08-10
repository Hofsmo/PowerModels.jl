### generic features that apply to all active-power-only (apo) approximations


"apo models ignore reactive power flows"
function variable_reactive_generation(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_storage(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_branch_flow(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_branch_flow_ne(pm::AbstractActivePowerModel; kwargs...)
end

"apo models ignore reactive power flows"
function variable_reactive_dcline_flow(pm::AbstractActivePowerModel; kwargs...)
end

"do nothing, apo models do not have reactive variables"
function constraint_reactive_gen_setpoint(pm::AbstractActivePowerModel, n::Int, c::Int, i, qg)
end


"on/off constraint for generators"
function constraint_generation_on_off(pm::AbstractActivePowerModel, n::Int, c::Int, i::Int, pmin, pmax, qmin, qmax)
    pg = var(pm, n, c, :pg, i)
    z = var(pm, n, :z_gen, i)

    JuMP.@constraint(pm.model, pg <= pmax*z)
    JuMP.@constraint(pm.model, pg >= pmin*z)
end


"`-rate_a <= p[f_idx] <= rate_a`"
function constraint_thermal_limit_from(pm::AbstractActivePowerModel, n::Int, c::Int, f_idx, rate_a)
    p_fr = var(pm, n, c, :p, f_idx)
    con(pm, n, c, :sm_fr)[f_idx[1]] = JuMP.LowerBoundRef(p_fr)
    JuMP.lower_bound(p_fr) < -rate_a && JuMP.set_lower_bound(p_fr, -rate_a)
    JuMP.upper_bound(p_fr) >  rate_a && JuMP.set_upper_bound(p_fr,  rate_a)
end

""
function constraint_thermal_limit_to(pm::AbstractActivePowerModel, n::Int, c::Int, t_idx, rate_a)
    p_to = var(pm, n, c, :p, t_idx)
    con(pm, n, c, :sm_to)[t_idx[1]] = JuMP.LowerBoundRef(p_to)
    JuMP.lower_bound(p_to) < -rate_a && JuMP.set_lower_bound(p_to, -rate_a)
    JuMP.upper_bound(p_to) >  rate_a && JuMP.set_upper_bound(p_to,  rate_a)
end

""
function constraint_current_limit(pm::AbstractActivePowerModel, n::Int, c::Int, f_idx, c_rating_a)
    p_fr = var(pm, n, c, :p, f_idx)

    JuMP.lower_bound(p_fr) < -c_rating_a && JuMP.set_lower_bound(p_fr, -c_rating_a)
    JuMP.upper_bound(p_fr) >  c_rating_a && JuMP.set_upper_bound(p_fr,  c_rating_a)
end


""
function constraint_thermal_limit_from_on_off(pm::AbstractActivePowerModel, n::Int, c::Int, i, f_idx, rate_a)
    p_fr = var(pm, n, c, :p, f_idx)
    z = var(pm, n, c, :branch_z, i)

    JuMP.@constraint(pm.model, p_fr <=  rate_a*z)
    JuMP.@constraint(pm.model, p_fr >= -rate_a*z)
end

""
function constraint_thermal_limit_to_on_off(pm::AbstractActivePowerModel, n::Int, c::Int, i, t_idx, rate_a)
    p_to = var(pm, n, c, :p, t_idx)
    z = var(pm, n, c, :branch_z, i)

    JuMP.@constraint(pm.model, p_to <=  rate_a*z)
    JuMP.@constraint(pm.model, p_to >= -rate_a*z)
end

""
function constraint_thermal_limit_from_ne(pm::AbstractActivePowerModel, n::Int, c::Int, i, f_idx, rate_a)
    p_fr = var(pm, n, c, :p_ne, f_idx)
    z = var(pm, n, c, :branch_ne, i)

    JuMP.@constraint(pm.model, p_fr <=  rate_a*z)
    JuMP.@constraint(pm.model, p_fr >= -rate_a*z)
end

""
function constraint_thermal_limit_to_ne(pm::AbstractActivePowerModel, n::Int, c::Int, i, t_idx, rate_a)
    p_to = var(pm, n, c, :p_ne, t_idx)
    z = var(pm, n, c, :branch_ne, i)

    JuMP.@constraint(pm.model, p_to <=  rate_a*z)
    JuMP.@constraint(pm.model, p_to >= -rate_a*z)
end





""
function constraint_storage_thermal_limit(pm::AbstractActivePowerModel, n::Int, c::Int, i, rating)
    ps = var(pm, n, c, :ps, i)

    JuMP.lower_bound(ps) < -rating && JuMP.set_lower_bound(ps, -rating)
    JuMP.upper_bound(ps) >  rating && JuMP.set_upper_bound(ps,  rating)
end

""
function constraint_storage_current_limit(pm::AbstractActivePowerModel, n::Int, c::Int, i, bus, rating)
    ps = var(pm, n, c, :ps, i)

    JuMP.lower_bound(ps) < -rating && JuMP.set_lower_bound(ps, -rating)
    JuMP.upper_bound(ps) >  rating && JuMP.set_upper_bound(ps,  rating)
end

""
function constraint_storage_loss(pm::AbstractActivePowerModel, n::Int, i, bus, r, x, standby_loss)
    ps = var(pm, n, pm.ccnd, :ps, i)
    sc = var(pm, n, :sc, i)
    sd = var(pm, n, :sd, i)
    JuMP.@constraint(pm.model, ps + (sd - sc) == standby_loss + r*ps^2)
end

""
function add_generator_power_setpoint(sol, pm::AbstractActivePowerModel)
    add_setpoint(sol, pm, "gen", "pg", :pg)
    add_setpoint_fixed(sol, pm, "gen", "qg")
end

""
function add_storage_setpoint(sol, pm::AbstractActivePowerModel)
    add_setpoint(sol, pm, "storage", "ps", :ps)
    add_setpoint_fixed(sol, pm, "storage", "qs")
    add_setpoint(sol, pm, "storage", "se", :se, conductorless=true)
end

function constraint_storage_on_off(pm::AbstractActivePowerModel, n::Int, i, pmin, pmax, qmin, qmax, charge_ub, discharge_ub)
    z_storage = var(pm, n, :z_storage, i)
    ps = var(pm, n, pm.ccnd, :ps, i)

    JuMP.@constraint(pm.model, ps <= z_storage*pmax)
    JuMP.@constraint(pm.model, ps >= z_storage*pmin)
end

