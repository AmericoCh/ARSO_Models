



using JuMP
using Gurobi
include("MasterProblem.jl")
include("SubProblem.jl")






function benders_algorithm_multiple_L()  
    # Valores simétricos/asimetricos de Γ:
    ΓS_values = [0.0, 0.25, 0.5, 0.75, 1, 0.0, 0.1, 0.1, 0.4, 0.2]
    ΓC_values = [0.0, 0.25, 0.5, 0.75, 1, 0.1, 0.8, 0.0, 0.7, 0.3]
    ΓD_values = [0.0, 0.25, 0.5, 0.75, 1, 0.0, 0.5, 0.2, 0.9, 0.4]
      
    # Almacenando resultados
    results_df = DataFrame(
        Escenario = String[], 
        ΓS = Float64[], 
        ΓC = Float64[], 
        ΓD = Float64[], 
        Objetivo = Float64[], 
        x1 = Float64[], 
        x2 = Float64[], 
        PS = Float64[], 
        PC = Float64[], 
        D = Float64[]  
    )
    
    results_dfc = DataFrame(
        Escenario = String[],
        PS1 = Float64[],
        PC1 = Float64[],
        PU1 = Float64[],
        f11 = Float64[],
        f21 = Float64[],
        θ11 = Float64[],
        θ21 = Float64[],
        PS2 = Float64[],
        PC2 = Float64[],
        PU2 = Float64[],
        f12 = Float64[],
        f22 = Float64[],
        θ12 = Float64[],
        θ22 = Float64[]
    )
    
    
    # Recorrer  los escenarios
    for (i, (ΓS, ΓC, ΓD)) in enumerate(zip(ΓS_values, ΓC_values, ΓD_values))
        println("\nEscenario $i: ΓS = $ΓS, ΓC = $ΓC, ΓD = $ΓD")
        
        # Restablecer el modelo maestro antes de cada ejecución
        m = master_problem() 

        ub = Inf
        lb = -Inf
            
        @variable(m, ps11[1:MAX_ITERATIONS] >= 0)
        @variable(m, pc11[1:MAX_ITERATIONS] >= 0)
        @variable(m, pu11[1:MAX_ITERATIONS] >= 0)
        @variable(m, ps21[1:MAX_ITERATIONS] >= 0)
        @variable(m, pc21[1:MAX_ITERATIONS] >= 0)
        @variable(m, pu21[1:MAX_ITERATIONS] >= 0)

        @variable(m, f111[1:MAX_ITERATIONS])
        @variable(m, f211[1:MAX_ITERATIONS])
        @variable(m, d111[1:MAX_ITERATIONS])
        @variable(m, d211[1:MAX_ITERATIONS])
        @variable(m, f121[1:MAX_ITERATIONS])
        @variable(m, f221[1:MAX_ITERATIONS])
        @variable(m, d121[1:MAX_ITERATIONS])
        @variable(m, d221[1:MAX_ITERATIONS]) 

        # Inicializar variables para almacenar resultados
        x1_val, x2_val = 0.0, 0.0
        ps_val, pc_val, d_val = 0.0, 0.0, 0.0
        z_master = 0.0
        
        # para almacenar resultados complementarios
        ps11_val, pc11_val, pu11_val, ps21_val, pc21_val, pu21_val = 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
        f111_val, f211_val, f121_val, f221_val  =  0.0, 0.0, 0.0, 0.0, 0.0
        d111_val, d211_val, d121_val, d221_val  =  0.0, 0.0, 0.0, 0.0, 0.0
        
        for k in 1:MAX_ITERATIONS
            println("\nIteración: $k")   
            z_master, vars =  solve_master_problem(m)
            println("Objetivo maestro: $z_master, x1=$(vars["x1"]), x2=$(vars["x2"])") 
            z_sub, ps, pc, d = solve_subproblem(vars["x1"], vars["x2"], ΓC, ΓS, ΓD)
            println("Objetivo subproblema: $z_sub, ps=$ps, pc=$pc, d=$d")

            ub = z_sub + 2*vars["x1"]*1e6 + 3*vars["x2"]*1e6 
            lb = z_master 

            # Verificar convergencia
            res = ub -lb
            println("(ub, lb): $ub, $lb")
            #println("Diferencia: $(abs(ub - lb))")
            println("TOLERANCE = $TOLERANCE")
            println("Diference: $res")
            
            #Almacenar valores de la última iteración
            ps_val, pc_val, d_val = ps, pc, d     
            x1_val, x2_val = vars["x1"], vars["x2"]
            ps1 = vars["ps11s"]

            if abs(ub - lb) < TOLERANCE
                println("Convergencia alcanzada en $k iteraciones")
                ps11_val, pc11_val, pu11_val = value(ps11[k-1]), value(pc11[k-1]), value(pu11[k-1])
                ps21_val, pc21_val, pu21_val = value(ps21[k-1]), value(pc21[k-1]), value(pu21[k-1])
                
                f111_val, f211_val, f121_val, f221_val  =  value(f111[k-1]),  value(f211[k-1]), value(f121[k-1]), value(f221[k-1])
                d111_val, d211_val, d121_val, d221_val  =  value(d111[k-1]), value(d211[k-1]), value(d121[k-1]), value(d221[k-1])
                break
            else  
                # Agregando los cortes al Problema Maestro de forma dinámica
                @constraint(m, m[:eta] >= 0.5 * 8760 * (2 * ps11[k] + 20 * pc11[k] + 200 * pu11[k]) +
                                      0.5 * 8760 * (2 * ps21[k] + 20 * pc21[k] + 200 * pu21[k]))

                # Escenario 1
                @constraint(m, ps11[k] == f111[k])
                @constraint(m, pc11[k] == f211[k])
                @constraint(m, 0.5 * d - pu11[k] == f111[k] + f211[k])
                @constraint(m, f111[k] / 100 - d111[k] >= -M * (1 - m[:x1]))  
                @constraint(m, f111[k] / 100 - d111[k] <= M * (1 - m[:x1]))   
                @constraint(m, f211[k] / 100 - d211[k] >= -M * (1 - m[:x2])) 
                @constraint(m, f211[k] / 100 - d211[k] <= M * (1 - m[:x2]))  
                @constraint(m, -50*m[:x1] <= f111[k])
                @constraint(m,f111[k] <= 50*m[:x1])
                @constraint(m, -50*m[:x2] <= f211[k])
                @constraint(m,f211[k] <= 50*m[:x2])
                
                @constraint(m, ps11[k] <= 0.75 * ps)
                @constraint(m, pc11[k] <= 1.00 * pc)
                @constraint(m, pu11[k] <= 0.50 * d)

                # Escenario 2
                @constraint(m, ps21[k] == f121[k])
                @constraint(m, pc21[k] == f221[k])
                @constraint(m, 0.75 * d - pu21[k] == f121[k] + f221[k]) 
                @constraint(m, f121[k] / 100 - d121[k] >= -M * (1 - m[:x1]))  
                @constraint(m, f121[k] / 100 - d121[k] <= M * (1 - m[:x1]))   
                @constraint(m, f221[k] / 100 - d221[k] >= -M * (1 - m[:x2]))  
                @constraint(m, f221[k] / 100 - d221[k] <= M * (1 - m[:x2]))   
                @constraint(m, -50*m[:x1] <= f121[k])
                @constraint(m, f121[k] <= 50*m[:x1])
                @constraint(m, -50*m[:x2] <= f221[k])
                @constraint(m, f221[k] <= 50*m[:x2])

                @constraint(m, ps21[k] <= 0.25 * ps)
                @constraint(m, pc21[k] <= 1.00 * pc)
                @constraint(m, pu21[k] <= 0.75 * d)
            end
        end
        # Agregar resultados al DataFrame
        push!(results_df, (
            "Escenario $i", ΓS, ΓC, ΓD, z_master, x1_val, x2_val, ps_val, pc_val, d_val # x1_val, x2_val
        ))
        
        push!(results_dfc, (
            "Escenario $i", ps11_val, pc11_val, pu11_val,  f111_val, f211_val,  d111_val, d211_val, ps21_val, pc21_val, pu21_val, f121_val, f221_val, d121_val, d221_val 
        ))
        
    end
    # Imprimir la tabla
    pretty_table(results_df, header=["Escenario", "ΓS", "ΓC", "ΓD", "Objetivo", "x1", "x2", "PS", "PC", "D"])
    
    pretty_table(results_dfc, header=["Escenario", "PS1", "PC1", "PU1",  "f11", "f21",  "θ11", "θ21", "PS2", "PC2", "PU2",  "f12", "f22",  "θ12", "θ22"])
    
    # Define archivos de salida
    latex_file_path = raw"C:\Users\CLINTON\Desktop\americo\Licenciatura\resultados_benders_alg.tex"
    
    latex_file_path_c = raw"C:\Users\CLINTON\Desktop\americo\Licenciatura\resultados_benders_alg_c.tex"

    # Configura el formato de tabla
    latex_format = tf_latex_default  # Formato LaTeX por defecto

    # Escribe la tabla en formato LaTeX
    open(latex_file_path, "w") do io
        pretty_table(
            io,
            results_df,  # Tabla de resultados
            header=["Escenario", "ΓS", "ΓC", "ΓD", "Objetivo", "x1", "x2", "PS", "PC", "D"],  # Encabezados
            backend=Val(:latex),  
            tf=latex_format,  
            alignment=:c
        )
    end
    
    
    open(latex_file_path_c, "w") do io
        pretty_table(
            io,
            results_dfc,  # Tabla de resultados
            header=["Escenario", "PS1", "PC1", "PU1",  "f11", "f21",  "θ11", "θ21", "PS2", "PC2", "PU2",  "f12", "f22",  "θ12", "θ22"],  # Encabezados
            backend=Val(:latex),  
            tf=latex_format,  
            alignment=:c
        )
    end 
    println("La tabla ha sido exportada exitosamente a $latex_file_path")
end

# Ejecutar
#benders_algorithm_multiple_L()











