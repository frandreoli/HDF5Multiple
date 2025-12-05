module HDF5Multiple
    #     
    export h5write_multiple
    #
    using HDF5
    #
    #Function to create groups and subgroups for dictionaries
    function h5data_write!(file_h5,variable_name,variable_data)
        if variable_data isa Dict
            group = create_group(file_h5,variable_name)
            for (key, value) in variable_data
                if key==:__h5_struct_type_attribute
                    attributes(group)["struct_type"] = value
                else
                    h5data_write!(group,key,value)
                end
            end
        else
            if variable_data isa AbstractRange variable_data = collect(variable_data) end
            file_h5[variable_name]=variable_data
        end
    end
    #
    #Function to save multiples new variables into a file. 
    function h5write_multiple(file_name,data_array... ; open="w", overwrite::Bool = true)
        name_list  = Dict{String,Int64}()
        #
        h5open(file_name * ".h5", open) do file_h5
            for variable in data_array
                #
                #Inferring the variable name and data
                if variable isa Pair
                    variable_name = string(variable[1])
                    variable_data = h5data_encode(variable[2])
                else
                    variable_name = string(typeof(variable))
                    variable_data = h5data_encode(variable)
                end
                #
                #Checking conflicts with existing variables
                variable_name_start = variable_name
                while haskey(file_h5, variable_name) 
                    if variable_name in keys(name_list)
                        name_list[variable_name]+=1
                        variable_name =variable_name_start*"_"*string(name_list[variable_name])
                    elseif overwrite
                        delete_object(file_h5, variable_name)
                    else
                        name_list[variable_name] = 1
                        variable_name =variable_name*"_"*string(name_list[variable_name])
                    end
                end
                if !(variable_name in keys(name_list)) 
                    name_list[variable_name] = 0 
                end
                #
                #Properly treating AbstractRanges
                if variable_data isa AbstractRange variable_data = collect(variable_data) end
                #
                try 
                    h5data_write!(file_h5,variable_name,variable_data)
                catch err
                    println("ERROR in saving the data labeled:", variable_name, " .\nThe variable content is: ", variable_data)
                    error(err)        
                end
            end
        end
    end
    #
    #Function to convert a struct into a dictionary of data and metadata
    function h5handle_struct(p)
        if (typeof(p) <: Dict)
            sol = Dict(key=>h5data_encode(value) for (key,value) in p )
        else
            # Create a dictionary to hold info
            sol = Dict{Any,Any}()
            sol[:__h5_struct_type_attribute] = string(typeof(p))
            if (typeof(p) <: Symbol)
                sol["symbol_name"] = string(p)
            else
                field_names = fieldnames(typeof(p))
                for name in field_names
                    sol[string(name)] = h5data_encode(getfield(p, name))
                end
            end
        end
        return sol
    end
    #
    #Function to convert a function into a dictionary of metadata
    function h5handle_function(f::Function)
        # Create a dictionary to hold info
        info = Dict{Any, Any}()
        info[:__h5_struct_type_attribute] = "Function"
        info["name"] = string(nameof(f))
        # Try to find source code location
        ms = methods(f)
        if !isempty(ms)
            m = first(ms) # Get the first method definition
            info["module"] = string(m.module)
            info["file"] = string(m.file)
            info["line"] = m.line
            info["arguments"] = string(m.nargs) 
        else
            info["note"] = "Built-in or anonymous function with no specific methods table."
        end
        return info
    end
    #
    #Function to handle blacklisted elements
    function h5is_blacklisted(value)
        type_str = string(typeof(value))
        return occursin("Plots.Plot", type_str)
    end
    #
    #Function to turn structures into dictionaries
    function h5data_encode(value)
        if value isa AbstractArray{Any}
            value = Tuple(value)
        end
        value_type = typeof(value)
        if value isa Enum
            dict = Dict{Any,Any}()
            dict[:__h5_struct_type_attribute] = string(value_type)
            dict["value"] = string(value)
            dict["possible_values"] = string.(collect(instances(value_type)))
            return dict
        #
        elseif value isa Function
            return h5handle_function(value)
        #
        elseif h5is_blacklisted(value)
            return string("NOT SAVED: Object of type ", value_type)
        #
        elseif isstructtype(value_type) && value_type!=String && !(value_type <: AbstractArray) && !(value_type <: Complex)
            return h5handle_struct(value)
        #
        else
            return value
        end
    end
end