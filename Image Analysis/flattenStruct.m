function flatStruct = flattenStruct(nestedStruct)
    % FLATTENSTRUCT Recursively flatten a nested struct to a flat struct with concatenated field names

    % Input:
    %   nestedStruct: A struct that may contain nested structs

    % Output:
    %   flatStruct: A flat struct with concatenated field names to represent nesting

    % Initialize an empty struct to store the flattened structure
    flatStruct = struct();

    % Get the field names of the nested struct
    fields = fieldnames(nestedStruct);

    % Iterate over each field in the nested struct
    for i = 1:numel(fields)
        % Check if the field contains a nested struct
        if isstruct(nestedStruct.(fields{i}))
            % If the field is a nested struct, recursively call the
            % function to flatten it
            nestedFlatStruct = flattenStruct(nestedStruct.(fields{i}));

            % Get the field names of the flattened nested struct
            nestedFields = fieldnames(nestedFlatStruct);

            % Iterate over each field in the flattened nested struct and
            % concatenate the field names to indicate nesting
            for j = 1:numel(nestedFields)
                % Create a new field name by combining the original field
                % name and the nested field name
                newFieldName = [fields{i} '_' nestedFields{j}];

                % Assign the value of the nested field to the new field in
                % the flat struct
                flatStruct.(newFieldName) = nestedFlatStruct.(nestedFields{j});
            end
        else
            % If the field is not a nested struct, simply copy it to the
            % flat struct
            flatStruct.(fields{i}) = nestedStruct.(fields{i});
        end
    end
end