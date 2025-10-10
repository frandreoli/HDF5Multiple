using Pkg, Revise
cd(@__DIR__)
Pkg.activate(dirname(@__DIR__))
Pkg.instantiate()
using HDF5Multiple

#Structures to save
struct struct_a
    struct_a1
    struct_a2
end
#
struct struct_b
    struct_b1
    struct_b2
end
#
println("Saving a test file")
#
h5write_multiple("test", #File name (without extension)
    #
    #Variables to be saved ("name_variable", variable)
    #Structures and dictionaries will be saved as groups
    #Nested structures will become subgroups
    "A" => 1,
    "B" => struct_a("w",2), 
    "C" => struct_a(1,struct_b(1,2)   ) ,
    "D" => struct_a(1,Dict("B"=>"test", "C"=>2)   ) ,
    "E" => struct_a(1,Dict("B"=>4, "C"=>struct_a(1,2))   ) ,
    "F" => struct_a(struct_b(2,struct_a(2,struct_a(2,struct_b(1,Dict("m"=>"AA", "n"=>struct_a(1,struct_b(2,1))))))),7),
    "G" => 1im+8.0,
    "H" => :o,
    "I" => [1 2;2 5;2 2;3 1],
    "L" => 1:5,
    "M" => [(1,2) ; (2,3)],
    "N" => (1,"A", (2,"B")),
    "O" => [1; (1,2)],
    "P" => [1.0im 2;8 1; 2 1+9im],
    "Q" => x->2*x, 
    [1;2;3],
    struct_a(1,2),
    struct_a(2,"test"),
    struct_b(1,2),
)
#
#How the function handles file modification
h5write_multiple("test", "struct_b"=>5. ; open="cw")
h5write_multiple("test", "struct_b"=>10 ; open="cw", overwrite = false)
h5write_multiple("test", "struct_b"=>20 ; open="cw", overwrite = false)
#
println("File correctly saved.")