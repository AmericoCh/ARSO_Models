using Plots

# Datos obtenidos de la salida del algoritmo de Benders
# Los datos están organizados como (Γ, [(Iteración, ub, lb)])
data = [
    #([0.0,0.0,0.0], [(1, 7.008e7, 0.0), (2, 2.7008e6, 2.7008e6)]), # (0,0,0)
    #([0.1,0.8,0.5], [(1, 7.884e7, 0.0), (2, 6.22202e6, 6.22202e6)]),
    ([0.4,0.7,0.9], [(1, 8.5848e7, 0.0), (2, 7.025312e6, 7.025312e6)],7.025312e6 ), #Configuración 9
    #([1.0,1.0,1.0], [(1, 8.76e7, 0.0), (2, 7.847e6, 7.847e6)]),
    #([0.0,0.0,0.0], [(1, 2.7008e6, 2.0219e6),(2, 2.7008e6, 2.7008e6)]), # (2,4,6)
    ([0.1,0.8,0.5], [(1, 7.55822e6, 2.0219e6), (2, 6.22202e6, 6.22202e6)],6.22202e6 ), #Configuracion 7
    #([0.4,0.7,0.9], [(1, 1.5693632e7, 2.0219e6), (2, 7.025312e6, 7.025312e6)]), 
    #([1.0,1.0,1.0], [(1, 2.4557e7, 2.0219e6), (2, 7.847e6, 7.847e6)]),
    ([0.5,0.5,0.5], [(1, 5.885636000000001e6, 6.10376e6), (2, 5.885636000000001e6, 6.10376e6)],4.3836e6) # (2,2,2)  Config 8
    #([0.1,0.8,0.5], [(1, 6.22202e6, 6.69506e6), (2, 6.69506e6, 6.69506e6)])
]

# Crear la gráfica para cada valor de L
for (L, iterations, opt_val) in data
    iter = [it[1] for it in iterations]  # Iteraciones
    ub = [it[2] for it in iterations]    # Cota superior
    lb = [it[3] for it in iterations]    # Cota inferior

    plot(
        iter, ub, label="Cota superior", lw=2, marker=:o, color=:blue,
        xlabel="Iteración", ylabel="Valor", #title="Convergencia de Benders para L = $L",
        xticks=1:maximum(iter)
    )
    plot!(iter, lb, label="Cota inferior", lw=2, marker=:s, color=:red)
    
     # Agregar línea horizontal para el valor óptimo
    hline!([opt_val], label="Valor óptimo", color=:green, linestyle=:dash, lw=2)

    # Guardar la gráfica como archivo
    #savefig("C:\\Users\\CLINTON\\Desktop\\americo\\Licenciatura\\prog\\ARSO benders_convergence_L_$L.png")
end
