

module HDF5Multiple
    #     
    export h5write_multiple
    #
    using HDF5
    #
    #Function to create groups and subgroups for dictionaries
    function h5group_check!(file_h5,variable_name,variable_data)
        if variable_data isa Dict
            group = create_group(file_h5,variable_name)
            for (key, value) in variable_data
                if key==:__h5_struct_type_attribute
                    attributes(group)["struct_type"] = value
                else
                    h5group_check!(group,key,value)
                end
            end
        elseif !(variable_data isa Function)
            file_h5[variable_name]=variable_data
        end
    end
    #
    #Function to save multiples new variables into a file. 
    function h5write_multiple(file_name,data_array... ; open="w")
        file_h5=h5open(file_name*".h5", open)
        for variable in data_array
            if variable isa Union{Tuple, AbstractArray}
                variable_name = variable[1]
                variable_data = check_struct(variable[2])
            else
                variable_data = check_struct(variable)
                variable_name = string(typeof(variable_data))
            end
            variable_data isa AbstractRange ? variable_data = collect(variable_data) : nothing
            haskey(file_h5, variable_name) ? delete_object(file_h5, variable_name) : nothing
            try 
                h5group_check!(file_h5,variable_name,variable_data)
            catch err
                close(file_h5)
                println("ERROR in saving the data labeled:", variable_name, " .\nThe variable content is: ", variable_data)
                error(err)        
            end
        end
        close(file_h5)
    end
    #
    #Function to convert a struct into a dictionary
    function struct2dict(p)
        if (typeof(p) <: Dict)
            sol = Dict(key=>check_struct(value) for (key,value) in p )
        else
            sol = Dict{Any,Any}()
            sol[:__h5_struct_type_attribute] = string(typeof(p))
            if (typeof(p) <: Symbol)
                sol["symbol_name"] = string(p)
            else
                field_names = fieldnames(typeof(p))
                for name in field_names
                    sol[string(name)] = check_struct(getfield(p, name))
                end
            end
        end
        return sol
    end
    #
    #Function to turn structures into dictionaries
    function check_struct(value)
        if value isa AbstractArray{Any}
            value = Tuple(value)
        end
        value_type = typeof(value)
        if  isstructtype(value_type) && value_type!=String && !(value_type <: AbstractArray) && !(value_type <: Complex)
            return struct2dict(value)
        else
            return value
        end
    end
end