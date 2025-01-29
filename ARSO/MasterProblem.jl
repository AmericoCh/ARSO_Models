#Descomposición de Benders  para modelos ARSO
#Caso de estudio: Expansión de la Transmisión
#21/01/25
#version 1.5  # se automatizó la adición de cortes
              # Simulación para diferentes presupestos de incertidumbre Γ
              # Se recuperó todas las soluciones óptimas del modelo
using JuMP
using Gurobi
              
using DataFrames
using PrettyTables
                         
const M = 10000  # Big-M linealización
const TOLERANCE = 1e-5  
const MAX_ITERATIONS = 100  
              
ps_prev =1 
pc_prev =1
d_prev =1
              
#PROBLEMA MAESTRO
function master_problem()
    m = Model(Gurobi.Optimizer)
    set_optimizer_attribute(m, "OutputFlag", 0)  #Reducir output solver
    # Varaibles Binarias
    @variable(m, x1, Bin, base_name = "x1")
    @variable(m, x2, Bin, base_name = "x2")
    
    #Variables positivas
    @variable(m, eta >= 0, base_name = "eta")
    
    
    @variable(m, ps11s >= 0, base_name = "ps11s")
    @variable(m, pc11s >= 0, base_name = "pc11s")
    @variable(m, pu11s >= 0, base_name = "pu11s")
    @variable(m, ps21s >= 0, base_name = "ps21s")
    @variable(m, pc21s >= 0, base_name = "pc21s")
    @variable(m, pu21s >= 0, base_name = "pu21s")
    
    
    #Variables irrestrictas
    @variable(m, f111s, base_name = "f111s")
    @variable(m, f211s, base_name = "f211s")
    @variable(m, d111s, base_name = "d111s")
    @variable(m, d211s, base_name = "d211s")
    @variable(m, f121s, base_name = "f121s")
    @variable(m, f221s, base_name = "f221s")
    @variable(m, d121s, base_name = "d121s")
    @variable(m, d221s, base_name = "d221s")
    

    #Función objetivo
    @objective(m, Min, 2*10^6 * x1 + 3*10^6 * x2 + eta)
    

    # Restricciones
    @constraint(m, eta >= 0.5 * 8760 * (2 * ps11s + 20 * pc11s + 200 * pu11s) +
                      0.5 * 8760 * (2 * ps21s + 20 * pc21s + 200 * pu21s))
    
    # Escenario 1
    @constraint(m, ps11s == f111s)
    @constraint(m, pc11s == f211s)
    @constraint(m, 0.5 * d_prev - pu11s == f111s + f211s) 
    @constraint(m, f111s/100 - d111s >= -M * (1 - x1))  
    @constraint(m, f111s/100 - d111s <= M * (1 - x1))   
    @constraint(m, f211s/100 - d211s >= -M * (1 - x2)) 
    @constraint(m, f211s/100 - d211s <= M * (1 - x2))  
    @constraint(m, -50*x1 <= f111s)
    @constraint(m,f111s <= 50*x1)
    @constraint(m, -50*x2 <= f211s)
    @constraint(m,f211s <= 50*x2)
    
    @constraint(m, ps11s <= 0.75 * ps_prev)
    @constraint(m, pc11s <= 1.00 * pc_prev)
    @constraint(m, pu11s <= 0.50 * d_prev)
    
    # Escenario 2
    @constraint(m, ps21s == f121s)
    @constraint(m, pc21s == f221s)
    @constraint(m, 0.75 * d_prev - pu21s == f121s + f221s)
    @constraint(m, f121s/100 - d121s >= -M * (1 - x1))  
    @constraint(m, f121s/100 - d121s <= M * (1 - x1))   
    @constraint(m, f221s/100 - d221s >= -M * (1 - x2))  
    @constraint(m, f221s/100 - d221s <= M * (1 - x2))   
    @constraint(m, -50*x1 <= f121s)
    @constraint(m, f121s <= 50*x1)
    @constraint(m, -50*x2 <= f221s)
    @constraint(m, f221s <= 50*x2)
    
    @constraint(m, ps21s <= 0.25 * ps_prev)
    @constraint(m, pc21s <= 1.00 * pc_prev)
    @constraint(m, pu21s <= 0.75 * d_prev) 
    return m 
end


# Resuelve el problema maestro
function solve_master_problem(m)
    optimize!(m)
    if termination_status(m) != MOI.OPTIMAL
        error("Problema maestro infactible")
    end
    
    vars = Dict(   # Recuperar las variables del modelo 
        "x1" => value(m[:x1]),
        "x2" => value(m[:x2]),
        "eta" => value(m[:eta]),
        "f111s" => value(m[:f111s]),
        "f211s" => value(m[:f211s]),
        "f121s" => value(m[:f121s]),
        "f221s" => value(m[:f221s]),
        "ps11s" => value(m[:ps11s]),
        "ps21s" => value(m[:ps21s]),
        "pc11s" => value(m[:pc11s]),
        "pc21s" => value(m[:pc21s]),
        "pu11s" => value(m[:pu11s]),
        "pu21s" => value(m[:pu21s]),
        "d111s" => value(m[:d111s]),
        "d211s" => value(m[:d211s]),
        "d121s" => value(m[:d121s]),
        "d221s" => value(m[:d221s])
    )

    return objective_value(m), vars
end
    







