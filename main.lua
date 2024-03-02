local settings = { print_logs = true, save_logs = false };

local serializer = {};

function serializer:log_output(file_path, data)
    local output = data .. '\n\n'; 
    if settings.print_logs then
        print('Log Output:\n' .. output);
    end;
    if settings.save_logs then
        appendfile(file_path, output); 
    end;
end;

function serializer:serialize(table, indent)
    indent = indent or 0;
    local result = '{\n';

    for i, v in next, table do
        local _i, _v;

        if type(i) == 'number' then 
            _i = '\t[' .. i .. ']';
        else
            _i = '\t["' .. i .. '"]';
        end;

        if type(v) == 'table' then
            _v = self:serialize(v, indent + 1);
        elseif type(v) == 'string' then
            _v = '"' .. v .. '"';
        else
            _v = tostring(v);
        end;

        result = result .. string.rep('\t', indent) .. _i .. ' = ' .. _v .. ',\n';
    end;

    return result:sub(1, #result - 2) .. '\n' .. string.rep('\t', indent) .. '}';
end;

function serializer:request_table_reset(table)
    local new_table = {};
    
    local _url = table[1];
    local _method = table[2];
    local __body = table[3];

    new_table['Url'] = _url;
    new_table['Method'] = _method;

    if __body then
        new_table['Body'] = __body;
    end;

    return new_table;
end;

local request_data, request_index = {}, 0;

local __httpget; __httpget = hookfunction(game.HttpGet, function(...)
    local vararg = {...};
    local serialized = serializer:serialize(vararg);

    serializer:log_output('http_get_logs.txt', .. serialized);
    return __httpget(...);
end);

local __request; __request = hookfunction(request, function(payload)
    local _minimum = 0;
    request_index = request_index + 1;
    local current_tbl = request_data[request_index] or {};
    
    current_tbl = {
        [1] = payload['Url'],
        [2] = payload['Method'],
        [3] = payload['Body']    
    };

    if payload['Method'] == 'GET' then
        _minimum = 2;
    else
        _minimum = 3;
    end;
    
    if #current_tbl >= _minimum then
        local serialized = serializer:serialize(serializer:request_table_reset(current_tbl));
        serializer:log_output('request_logs.txt', serialized);
    end;

    return __request(payload);
end);
