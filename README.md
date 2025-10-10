# HDF5Multiple.jl

This repository contains a Julia module to save multiple, structured variables to an HDF5 file, with a single function call. 
The code converts structs and dictionaries to HDF5 groups, manages naming conflicts, and supports a wide range of data types. 
Similar functionalities are already available within the [JLD2 format](https://github.com/JuliaIO/JLD2.jl). 
Here we provide those features within a purely HDF5 encoding.


## 1 - Key features

  * **One-line saving:** save any number of variables to an HDF5 file with a single command.
  * **Flexible naming:** provide explicit names for your variables using Pair syntax (`"name" => data`) or let the module create a name automatically based on the variable's type.
  * **Automatic resolution of conflicts:** if a variable name already exists in the file or is used multiple times in the same call, the module automatically appends a numeric suffix (e.g., `my_data_1`, `my_data_2`) to prevent data loss.
  * **Overwrite control:** the user can use the overwrite flag to either replace existing data or create new, suffixed entries.
  * **Storage of structs and dictionaries:** automatically converts nested Julia structs and Dicts into organized HDF5 groups and subgroups.
  * **Data type support:** natively handles a variety of types, including complex numbers, symbols, arrays, ranges, tuples, and more.


## 2 - Usage

### 2.1 - Main function

The module exports a single function:

```Julia
h5write_multiple(file_name, data_array...; open="w", overwrite::Bool=true)
```

  * `file_name::String`: the name of the HDF5 file to create/modify (the .h5 extension is added automatically).
  * `data_array...`: a variable number of Julia objects to save.
  * `open::String`: the file open mode. Common modes are "w" (write, create new file) and "cw" (create/read/write, modify existing file). Defaults to "w".
  * `overwrite::Bool`: if a variable name already exists in the file:
      * true (default): the existing data will be deleted and replaced.
      * false: a new, suffixed variable will be created (e.g., `my_data_1`).

### 2.2 - Basic example

```Julia
using .HDF5Multiple

# Define some data
my_id = 101
my_params = Dict("rate" => 0.5, "iterations" => 200)
my_results = [1.0, 0.9, 0.85]

# Save all variables in one call
h5write_multiple("experiment_1",
    "id" => my_id,
    "parameters" => my_params,
    "results" => my_results
)
```

### 2.3 - Advanced features

#### 2.3.1 - Automatic naming

If you provide a variable without a name, its type will be used as the name. If multiple variables of the same type are provided, they will be automatically suffixed.

```Julia
struct MyParams
    alpha::Float64
    beta::Int
end

p1 = MyParams(0.1, 5)
p2 = MyParams(0.2, 10)
data = [1.0, 2.0, 3.0]

# "p1" and "p2" will be saved as "MyParams" and "MyParams_1"
# "data" will be saved as "Vector{Float64}"
h5write_multiple("auto_named_data", p1, p2, data)
```

#### 2.3.2 - Handling structs and dictionaries

Complex, nested structures are saved recursively as HDF5 groups.

```Julia
struct Point{T}
    x::T
    y::T
end

struct Measurement
    id::String
    location::Point{Float64}
    data::Dict
end

m = Measurement("A-42", Point(10.5, -4.3), Dict("voltage" => 5.2, "temp" => 35.1))

# This will create a hierarchical structure inside the HDF5 file
h5write_multiple("nested_data", "measurement_1" => m)
```

#### 2.3.3 - Overwrite control

The overwrite flag gives you fine-grained control when modifying files.

```Julia
# Create an initial file
h5write_multiple("log", "status" => "RUNNING")

# Use "cw" mode to modify the file
# This will update the "status" variable
h5write_multiple("log", "status" => "COMPLETE"; open="cw", overwrite=true)

# This will create a NEW variable "status_1" because overwrite is false
h5write_multiple("log", "status" => "ARCHIVED"; open="cw", overwrite=false)
```



## 3 - How it Works

The module handles complex data structures by recursively converting Julia structs and Dicts into HDF5 groups. When a struct is saved, its original type name is stored as a group attribute (`struct_type`), which can be useful for manual inspection or for writing a corresponding function to read and reconstruct the data.



## 4 - Dependencies

  * [HDF5.jl](https://github.com/JuliaIO/HDF5.jl)
