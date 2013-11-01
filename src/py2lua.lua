-- This file is for wxFormBuilder code gen wxPython convert to wxLua
-- It just a testing code
-- it can't be complete transfer, have to do manual rework
-- change the file in out on the bottom for testing
-- fn_in = "C:\\work\\test_wxlua\\noname.py";
-- fn_out = "C:\\work\\test_wxlua\\noname.lua";

require("io")
require("wx")

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function getchar(s, i)
    return s:sub(i, i)
end

function py2lua(s)
    local line = nil
    local prev_indent = 1
    local lines = {}

    s = s:gsub("wx.EmptyString", "\"\"")
    s = s:gsub("True", "true")
    s = s:gsub("False", "false")
    s = s:gsub(".Bind", ":Connect")
    s = s:gsub("|", "+")
    s = s:gsub(", u\"", ", \"")
    s = s:gsub(", id = ", ", ")
    s = s:gsub(",%s*%a+%s*=", ", ")

    function check_indent(s)
        local c = getchar(s, 1)
        if (c ~= " ") then
            return 1
        end

        local indent = s:find("[^%s]")
        if (indent == nil) then
            indent = 0
        end
        return indent
    end

    function replace_def(line)
        matched,i,s0,s1 = line:find( "(.*)def (.*):")

        if matched then
            --print(matched, i, s0,s1)
            line = line:gsub("def", "function")
            line = line:gsub(":", "")
        else
            matched,i,s0,s1 = line:find( "(.*)def(.*):")
            if matched then
                --print(matched, i, s0,s1)
                line = line:gsub("def", "function ")
                line = line:gsub(":", "")
            end
        end

        return line
    end

    function replace_require(line)
        --print(line:find( "import%s*(.*)"))
     
        local n = check_indent(line)
        matched,i,s0 = line:find( "import%s*(.*)")

        if matched then
            --print(matched, i, s0,s1)
            return (string.rep(" ",n-1).."require(\""..s0.."\")")
        else
            return line
        end
    end

    function replace_comment(line)
        line = line:gsub("#", "--")
        return line
    end

    function replace_if(line)
        matched,i,s0 = line:find( "if (.*):")

        if matched then        
            return line:gsub(":", " then")
        else
            return line
        end
    end

    for line in s:gmatch("[^\r\n]+") do
        local tokens = {}
        for t in line:gmatch("[^%s]+") do 
            table.insert(tokens, t)
        end
        local n = #tokens
        local cur_indent = check_indent(line)
        --print_token(tokens)
        
        if (n >= 1) then      
            local t1 = tokens[1]
            local c = getchar(t1, 1)

            if (n > 1) then
                if (t1 ~= "import") then
                    line = line:gsub("wx.", "wx.wx")
                end
                --line = line:gsub(".__init__(", "(")   
            end            

            if (t1 == "import") then
                line = replace_require(line)
            elseif (t1 == "def") then
                line = replace_def(line)
            elseif (t1 == "if") then
                line = replace_if(line)
            elseif (t1 == "class") then 
                line = line:gsub(":", "")
                line = line:gsub("class", "function")
            elseif (c == "#") then
                line = line:gsub("^#", "-- ")
            else
                t2 = line:match("%A%u%a*%(")
                if (t2) then
                    t2 = t2:sub(1, t2:len() - 1)
                    t3 = t2:gsub("%.", ":")
                    --print(t2, t3)
                    line = line:gsub(t2, t2:gsub("%.", ":"))
                end
            end

            --print(cur_indent, prev_indent)    
            if (cur_indent < prev_indent and cur_indent + 10 > prev_indent) then
                if (cur_indent + 4 < prev_indent ) then
                    table.insert(lines, (string.rep(" ",cur_indent+3).."end\n"))
                    table.insert(lines, (string.rep(" ",cur_indent-1).."end\n"))
                else
                    table.insert(lines, (string.rep(" ",cur_indent-1).."end\n"))
                end
            end
           
            prev_indent = cur_indent
   
            table.insert(lines, line.."\n")
        else
            table.insert(lines, line)
        end                 
    end
    s = table.concat(lines)
    s = s:gsub("wx%AwxFrame%A__init__", "self = wx.wxFrame")
    s = s..[[    return self
end

local frame = MyFrame1(wx.NULL)
frame:Show(true)
wx.wxGetApp():MainLoop()
]]
    return s
end

file = {}
function file.read(file)
    local f = io.open(file, "r")
    local content = f:read("*all")
    f:close()
    return content
end

function file.write(file, s)
    local output_file = io.output(io.open(file, "w"))    
    io.write(s)
    output_file:close()
end

function py2lua_file(fn_in, fn_out)
    local s = file.read(fn_in)    
    s = py2lua(s)
    file.write(fn_out, s)    
end

--fn_in = "C:\\work\\test_wxlua\\noname.py";
--fn_out = "C:\\work\\test_wxlua\\noname.lua";


--py2lua_file(fn_in, fn_out)


