# Costo del modelo ARSO vs Costo determinista 

using Plots
using LaTeXStrings

Γ_SimValues = [0.0, 0.25, 0.5, 0.75, 1]

function cost_compareSim(Γ_SimValues)
    cost_ARSO = [2.7008e6, 6.11909e6, 6.69506e6, 7.27103e6, 7.847e6]
    cost_deterministic = fill(2.7008e6, length(Γ_SimValues))

    # Gráfico
    plot(Γ_SimValues, cost_ARSO, label="Costo ARSO", lw=2, marker=:circle, xlabel=L"\varGamma^{\textrm{S}} = \varGamma^{\textrm{C}}= \varGamma^{\textrm{U}} ", ylabel="Costo total (\$)") 
    plot!(Γ_SimValues, cost_deterministic, label="Costo determinístico", lw=2, linestyle=:dash, marker=:square, legend=:right)

# Exportar la gráfica como archivo PDF
#savefig("C:\\Users\\CLINTON\\Desktop\\americo\\Licenciatura\\graf_comparacion_costos_sim.pdf") 
end

cost_compareSim(Γ_SimValues)



# Valores asimétricos de Γ
ΓS_values = [0.0, 0.1, 0.1, 0.4, 0.2]
ΓC_values = [0.1, 0.8, 0.0, 0.7, 0.3] 
ΓD_values = [0.0, 0.5, 0.2, 0.9, 0.4] 

function cost_compareAsim(ΓS_values, ΓC_values, ΓD_values)
    
    robust_costs = [2.7008e6, 6.22202e6, 4.383596e6, 7.025312e6, 6.228152e6]
    deterministic_costs = fill(2.7008e6, length(ΓS_values))
 
    x_labels = ["($ΓS, $ΓC, $ΓD)" for (ΓS, ΓC, ΓD) in zip(ΓS_values, ΓC_values, ΓD_values)]

    plot(1:5, robust_costs, label="Costo ARSO", lw=2, marker=:circle, xlabel=L"(\varGamma^{\textrm{S}},\varGamma^{\textrm{C}}, \varGamma^{\textrm{D}})", ylabel="Costo total (\$)", xlims=(0.5,5.5)) # size=(800, 650)
    plot!(1:5, deterministic_costs, label="Costo Determinístico", lw=2,linestyle=:dash, marker=:square, legend=:right)
    xticks!(1:5, x_labels, fontsize=8) #, rotation=45

end

#cost_compareAsim(ΓS_values, ΓC_values, ΓD_values)

#savefig("C:\\Users\\CLINTON\\Desktop\\americo\\Licenciatura\\graf_comparacion_costos_asim.pdf") #or png