include("MasterProblem.jl")
include("SubProblem.jl")
include("BendersAlgorithm.jl")

function main()
    println("Iniciando algoritmo de Benders...")
    benders_algorithm_multiple_L()
end

main()

