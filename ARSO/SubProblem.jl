using JuMP
using Gurobi

#export solve_subproblem
include("MasterProblem.jl")


#SUBPROBLEMA
 
function solve_subproblem(x1, x2, ΓC, ΓS, ΓD)
    s = Model(Gurobi.Optimizer)
    set_optimizer_attribute(s, "OutputFlag", 0)  # Reducir salida del solver
   
    set_optimizer_attribute(s, "NonConvex", 2) # resolver prob no convexos con flexibilidad

    #variables
    @variable(s, PS)
    @variable(s, PC)
    @variable(s, D)
    
    #variables irrestrictas: duales de restricciones de igualdad en el Escenario 1
    @variable(s, alpha11)
    @variable(s, alpha12)
    @variable(s, alpha13)
    @variable(s, alpha21)
    @variable(s, alpha22)
    @variable(s, alpha23)
    
    
    #Variables positivas: duales  de restricciones de desigualdad en el Escenario 1
    @variable(s, betamax111 >= 0)
    @variable(s, betamin111 >= 0)
    @variable(s, betamax112 >= 0)
    @variable(s, betamin112 >= 0)
    @variable(s, betamax121 >= 0)
    @variable(s, betamin121 >= 0)
    @variable(s, betamax122 >= 0)
    @variable(s, betamin122 >= 0)
    @variable(s, gammamax11 >= 0)
    @variable(s, gammamin11 >= 0)
    @variable(s, gammamax12 >= 0)
    @variable(s, gammamin12 >= 0)
    @variable(s, gammamax13 >= 0)
    @variable(s, gammamin13 >= 0)
    
    
    #variables positivas: duales de restricciones de desigualdad en el Escenario 2
    @variable(s, betamax211 >= 0)
    @variable(s, betamin211 >= 0)
    @variable(s, betamax212 >= 0)
    @variable(s, betamin212 >= 0)
    @variable(s, betamax221 >= 0)
    @variable(s, betamin221 >= 0)
    @variable(s, betamax222 >= 0)
    @variable(s, betamin222 >= 0)
    @variable(s, gammamax21 >= 0)
    @variable(s, gammamin21 >= 0)
    @variable(s, gammamax22 >= 0)
    @variable(s, gammamin22 >= 0)
    @variable(s, gammamax23 >= 0)
    @variable(s, gammamin23 >= 0)
       
      
    
     #Funcion objetivo
    @objective(s, Max,-( (1-x1)*10e6*betamax111 + (1-x1)*10e6*betamin111 + x1*50*betamax112 + x1*50*betamin112 
                        + (1-x2)*10e6*betamax121 + (1-x2)*10e6*betamin121 + x2*50*betamax122 + x2*50*betamin122
                        + 0.75*PS*gammamax11 +1.0* PC*gammamax12 + 0.5*D*gammamax13 - 0.5*D*alpha13
                        + (1-x1)*10e6* betamax211 + (1-x1)* 10e6* betamin211 + x1*50*betamax212 + x1*50*betamin212
                        + (1-x2)*10e6*betamax221 + (1-x2)*10e6*betamin221 + x2*50*betamax222 + x2*50*betamin222
                        + 0.25*PS*gammamax21 + 1.0*PC*gammamax22 + 0.75*D*gammamax23 - 0.75*D*alpha23))

    
    # Restricciones de variables inciertas (incertibumbre a largo plazo, problema de segundo nivel) 
    
    # Conjunto de incertidumbre presupustaria
    @constraint(s, 140 <= PS <= 200)
    @constraint(s, 80 <= PC <= 100)
    @constraint(s, 64 <= D <= 80) 
    
    @constraint(s,200 - PS <= 60*ΓS)   #presupuesto de incertidumbre Γ
    @constraint(s,100 - PC <= 20*ΓC)
    @constraint(s, D - 64 <= 16*ΓD)
    
    #Restricciones duales del Escenario 1
    @constraint(s, 0.5*8760*2 + alpha11 + gammamax11 - gammamin11 == 0)
    @constraint(s, 0.5*8760*20 + alpha12 + gammamax12 - gammamin12 == 0)
    @constraint(s, 0.5*8760*200 - alpha13 + gammamax13 - gammamin13 == 0)

    @constraint(s, -alpha11 - alpha13 - betamin111/100 +betamax111/100 - betamin112 + betamax112 == 0)
    @constraint(s, -alpha12 - alpha13 - betamin121/100 +betamax121/100 - betamin122 + betamax122 == 0)

    @constraint(s, betamin111 - betamax111 == 0)
    @constraint(s, betamin121 - betamax121 == 0)

    #Restricciones duales del segundo Escenario
    @constraint(s, 0.5*8760*2 + alpha21 + gammamax21 - gammamin21 == 0)
    @constraint(s, 0.5*8760*20 + alpha22 + gammamax22 - gammamin22 == 0)
    @constraint(s, 0.5*8760*200 - alpha23 + gammamax23 - gammamin23 == 0)

    @constraint(s, -alpha21 - alpha23 - betamin211/100 +betamax211/100 - betamin212 + betamax212 == 0)
    @constraint(s, -alpha22 - alpha23 - betamin221/100 +betamax221/100 - betamin222 + betamax222 == 0)

    @constraint(s, betamin211 - betamax211 == 0)
    @constraint(s, betamin221 - betamax221 == 0)
    
    
    optimize!(s)
    if termination_status(s) != MOI.OPTIMAL
        error("Subproblema infactible")
    end
   
    return objective_value(s), value(PS), value(PC), value(D)
end


      
