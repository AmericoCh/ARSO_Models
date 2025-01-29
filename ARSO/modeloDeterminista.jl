# Modelo Determinista

using JuMP
using Gurobi


model = Model(Gurobi.Optimizer)
set_optimizer_attribute(model, "OutputFlag", 0)  # Reducir salida del solver

# Parámetros
bM = 10e5       #Big-M

C_inv1 = 2e6   # Costo de inversión línea 1
C_inv2 = 3e6   # Costo de inversión línea 2

PS_max = 200   # Capacidad máxima esperada de generación renovable (MW)
PC_max =100   # Capacidad máxima esperada de generación convencional (MW)
D = 64      # Demanda esperada (MW)

f_max = 50     # Capacidad de transmisión por línea (MW)
cost_PS = 2    # Costo de generación renovable ($/MWh)
cost_PC = 20   # Costo de generación convencional ($/MWh)
cost_PU = 200  # Costo de energía no servida ($/MWh)



# Variables de decisión
@variable(model, x1, Bin)  # Inversión en línea 1
@variable(model, x2, Bin)  # Inversión en línea 2

@variable(model, PS)  # Energía renovable generada
@variable(model, PC)  # Energía convencional generada
@variable(model, PU)  # Energía no servida

@variable(model, f1 )  # Flujo en línea 1
@variable(model, f2)  # Flujo en línea 2

@variable(model, θ1) # ángulo de voltaje en el  nodo 1
@variable(model, θ2) # ángulo de voltaje en el nodo 2




# Función objetivo determinista (no conjunto de incertidumbre, no escenarios)
@objective(
    model, Min,
    C_inv1 * x1 + C_inv2 * x2 + 8760 * (cost_PS * PS + cost_PC * PC + cost_PU * PU)
)


# Restricciones

# Ecuaciones de Balance (promedio)
@constraint(model, balance, 0.625*D == PU + f1 +f2)

@constraint(model, flow_PS, PS - f1 == 0)
@constraint(model, flow_PC, PC - f2 == 0)

#Linealizados big-M
@constraint(model, -bM* (1 - x1) - (f1/100 - θ1) <= 0)  
@constraint(model,  f1/100 - θ1 <= bM* (1 - x1) )
@constraint(model,  -x1*50 - f1 <= 0 )
@constraint(model,  f1 <= x1*50) 

@constraint(model, -bM* (1 - x2) - (f2/100 - θ2) <= 0)  
@constraint(model,  f2/100 - θ2 <= bM* (1 - x2) )
@constraint(model,  -x2*50 - f2 <= 0 )
@constraint(model,  f2 <= x2*50) 


#Capacidades operativas (promedio)
@constraint(model, 0 <= PS <= 0.625*PS_max)  
@constraint(model, 0 <= PC <= PC_max)        
@constraint(model, 0 <= PU <= 0.625*D)     

# Resolver el modelo
optimize!(model)

# Resultados
println("Estado de optimización: ", termination_status(model))
println("Costo total: ", objective_value(model))
println("Decisión de inversión en línea 1 (x1): ", value(x1))
println("Decisión de inversión en línea 2 (x2): ", value(x2))
println("Generación renovable (PS): ", value(PS))
println("Generación convencional (PC): ", value(PC))
println("Energía no servida (PU): ", value(PU))
println("Flujo en línea 1 (f1): ", value(f1))
println("Flujo en línea 2 (f2): ", value(f2))