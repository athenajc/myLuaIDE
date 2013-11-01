package.cpath = package.cpath..";./?.dll;./?.so;../lib/?.so;../lib/vc_dll/?.dll;../lib/bcc_dll/?.dll;../lib/mingw_dll/?.dll;"

require("wx")
require("sim_8051")
require("py2lua")

wxLua_path = "C:\\wx\\wxLua\\bin\\wxLua.exe"
Python_path = "C:\\Python27\\python.exe"
SDCC_path = "C:\\tools\\SDCC\\bin\\sdcc.exe"
NodeJS_path = "C:\\tools\\nw\\nw.exe"

wx_key_str = [[
wxArrayString  
wxComboBox 
wxCursor 
wxDefaultSize 
wxDefaultPoint 
wxDirTraverser 
wxFlexGridSizer 
wxFrame 
wxList 
wxPanel 
wxPoint 
wxSize 
wxString 
wxTextCtrl 
wxTreeCtrl 
]]

--require("lua_debugger")
local wxT = function(s) return s end
local _ = function(s) return s end
frame = nil

-- File menu
ID_NEW              = wx.wxID_NEW
ID_OPEN             = wx.wxID_OPEN
ID_CLOSE            = wx.wxNewId()
ID_SAVE             = wx.wxID_SAVE
ID_SAVEAS           = wx.wxID_SAVEAS 
ID_SAVEALL          = wx.wxNewId()
ID_EXIT             = wx.wxID_EXIT

-- Edit menu
ID_UNDO             = wx.wxID_UNDO
ID_REDO             = wx.wxID_REDO
ID_CUT              = wx.wxID_CUT
ID_COPY             = wx.wxID_COPY
ID_PASTE            = wx.wxID_PASTE
ID_SELECTALL        = wx.wxID_SELECTALL
ID_AUTOCOMPLETE     = wx.wxNewId()
ID_AUTOCOMPLETE_ENABLE = wx.wxNewId()
ID_COMMENT          = wx.wxNewId()
ID_FOLD             = wx.wxNewId()

-- Find menu
ID_FIND             = wx.wxID_FIND
ID_FINDNEXT         = wx.wxNewId()
ID_FINDPREV         = wx.wxNewId()
ID_REPLACE          = wx.wxNewId()

-- Debug menu
ID_COMPILE          = wx.wxNewId()
ID_RUN              = wx.wxNewId()
ID_DBG_START        = wx.wxNewId()

ID_DBG_STOP         = wx.wxNewId()
ID_DBG_STEP         = wx.wxNewId()
ID_DBG_STEP_OVER    = wx.wxNewId()
ID_DBG_STEP_OUT     = wx.wxNewId()
ID_DBG_CONTINUE     = wx.wxNewId()
ID_DBG_BREAK        = wx.wxNewId()

ID_TOGGLEBREAKPOINT = wx.wxNewId()
ID_VIEWCALLSTACK    = wx.wxNewId()
ID_VIEWWATCHWINDOW  = wx.wxNewId()

-- Help menu
ID_ABOUT            = wx.wxID_ABOUT

-- Watch window menu items
ID_WATCH_LISTCTRL   = wx.wxNewId()
ID_ADDWATCH         = wx.wxNewId()
ID_EDITWATCH        = wx.wxNewId()
ID_REMOVEWATCH      = wx.wxNewId()
ID_EVALUATEWATCH    = wx.wxNewId()

-- Markers for editor marker margin
MARKNUM_BREAK_POINT   = 1
MARKVAL_BREAK_POINT   = 1
MARKNUM_CURRENT_LINE  = 2
MARKVAL_CURRENT_LINE  = 4

MyDebugNB = {}
MyPrj = {}
MyLogNB = {}
MyDbg = {}

MyApp = {
    ID_CreateTree = wx.wxNewId(),
    ID_create_grid = wx.wxNewId(),
    ID_CreateText = wx.wxNewId(),
    ID_CreateNotebook = wx.wxNewId(),    
    
    m_frame = nil,
    m_mgr = nil,
    m_perspectives = nil,
    m_perspectives_menu = nil,
    m_notebook_style = nil,
    m_notebook_theme = nil,
    m_doc_nb = nil,
    
    m_dirtree = nil,
    m_functree = nil,
    m_logger = nil,
    m_debugger = nil,
}

MyDoc = {
    m_id = 0,
    m_filepath = nil,
    m_filename = nil,
    m_modified = false,
    m_type = 0,
    m_func_list,
    m_breakpoints = {},
}

MyDocNB = {}

function bit(p)
  return 2 ^ (p - 1)  -- 1-based indexing
end

-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p)
  return x % (p + p) >= p       
end

function setbit(x, p)
  return hasbit(x, p) and x or x + p
end

function clearbit(x, p)
  return hasbit(x, p) and x - p or x
end

function arg_str(v0, v1, v2, v3, v4, v5, v6)
    local s = ""

    if (v1 == nil) then
        s = tostring(v0).."\n"
    else    
        local t = {v0, v1, v2, v3, v4, v5, v6, nil}
        for i = 1, #t do
            s = s..tostring(t[i]).."  "
            if (t[i] == nil) then
                s = s.."\n"
                return s
            end
        end        
    end

    return s
end

function dprint(v0, v1, v2, v3, v4, v5, v6)
    if (v0 == "$clear$") then
        MyApp.m_debug_info:Clear()
        v0 = ""
    end
    local s = arg_str(v0, v1, v2, v3, v4, v5, v6)
    print(s)
    MyApp.m_debug_info:AppendText(s);
end

dlog = dprint

function log(v0, v1, v2, v3, v4, v5, v6)    
    local s = arg_str(v0, v1, v2, v3, v4, v5, v6)
    print(s)
    MyApp.m_logger:AppendText(s)
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function getchar(s, i)
    return s:sub(i, i)
end

function get_filename(s)
    if (s == nil or s == "") then
        return ""
    end
    return s:match("[^\\|/]+$")
end

function get_path(s)
    if (s == nil or s == "") then
        return ""
    end
    return s:match("(.*[\\|/])")
end

function get_filename_ext(s)
    if (s == nil or s == "") then
        return ""
    end
    return s:match("([^%.]+)$") 
end

function get_bitmap(icon)
    if (icon:sub(1, 2) == "wx") then
        return wx.wxArtProvider.GetBitmap(icon, wx.wxART_TOOLBAR, wx.wxSize(16,16))
    else
        return wx.wxBitmap(icon)
    end
end

function isfile(filename)    
    local f = io.open(filename, "r")

    if (f) then
        local result = (io.type(f) == "file")
        io.close(f)
        return result
    else 
        return false
    end
end

function get_date_string(dt)
    return string.format("%d-%02d-%02d %02d:%02d:%02d", dt.Year, dt.Month, dt.Day, dt.Hour, dt.Minute, dt.Second)
end

function get_file_mod_time(filePath)
    if filePath and #filePath > 0 then
        local fn = wx.wxFileName(filePath)        
        if fn:FileExists() then
            local dt = fn:GetModificationTime()
            return dt, f_exist
        else
            return nil, false
        end
    end

    return nil
end

function file_exist(path)
    if path and #path > 0 then
        local fn = wx.wxFileName(path)
        return fn:FileExists()
    end
    return false
end

function add_tree(tree, root, lst, depth)
    for i = 1, #lst do
        local t = lst[i]
        if (type(t) == "table") then
            local node = tree:GetLastChild(root)
            add_tree(tree, node, t, depth+1)
        else
            tree:AppendItem(root, tostring(t), 4)
        end      
    end
end

function gen_func_tree(tree, doc, lst)
    MyPrj:set_func_lst(lst)
end

function print_token(tokens)
    for i = 1, #tokens do
        print(i, tokens[i])
    end
end

function set_range_visible(doc, pos_start, pos_end)
    doc:set_range_visible(pos_start, pos_end)
end

function c_doc_init(doc)      
    local self = {}
    local c_doc = self
    self.doc = doc

    function exec_cmd_get_stdout_stderr(cmd)
        local file = io.popen(cmd, 'rb') --gives both stdout and stderr in pipe
        local output = file:read('*all')
        file:close()
        print("file close")
        dprint("["..tostring(output).."]") 
        print(output)     
    end

    function c_doc:precompile()
        local doc = self.doc --MyApp:get_current_doc()
        local filename = doc.m_filepath
        print("c_precompile")
        -- do the compilation
        local path = get_path(filename, "\\")
        --log(path)
        local cmd = "cd "..path.." && "..SDCC_path.." --debug "..filename.." 2>&1"
        --local cmd = "C:/tools/SDCC/bin/SDCC.exe 2>&1"
        dprint(cmd)
        local result = exec_cmd_get_stdout_stderr(cmd)
        print("cmd done")
        return true -- return true if it compiled ok
    end

    function c_doc:run_doc(filename)
    end

    function c_pre_process(s) 
        s = s:gsub("/%*[^%*]*%*/", "[$BC]")  -- replace block comment
        s = s:gsub("([//][^\n]*[\n])", "[$LC]\n")         -- replace line comment    
        
        s = s:gsub("%([^%(%)]*%)", " () ")          -- replace parenthesis
        s = s:gsub("\"[^\"\n]*\"", "[$ST]")               -- replace string
        
        s, n = s:gsub("{[^{^}]*}", "[$BLK]")
        while (n > 0) do
            s, n = s:gsub("{[^{^}]*}", "[$BLK]")        
        end

        s = s:gsub(",", " , ")
        s = s:gsub("=", " = ")
        
        return s
    end

    function c_doc:get_func_list(tree)
        local doc = self.doc
        local lst = {}
        local s = doc:GetText()
        s = c_pre_process(s)

        local p = "%a+%s+%(%)%s+[%[]"

        for t in s:gmatch(p) do
            t = t:gsub("[%[\n%(%)]", "")

            table.insert(lst, t)
        end

        doc.m_func_list = lst
        gen_func_tree(tree, doc, lst)  

        return lst
    end

    function c_doc:find_func_pos(doc, token)
        token = trim(token)
        --log("["..token.."]")
        n = doc:GetLength();
        local t1 = "^"..token.." ("
        start_pos = doc:FindText(1, n, t1, wxstc.wxSTC_FIND_REGEXP)
        if (start_pos < 0) then
            t1 = "^[a-zA-Z0-9_*)]+ "..token.." ("
            start_pos = doc:FindText(1, n, t1, wxstc.wxSTC_FIND_REGEXP)
            if (start_pos < 0) then
                t1 = "[a-zA-Z0-9_)]+ [a-zA-Z0-9_*)]+ "..token.." ("
                start_pos = doc:FindText(1, n, t1, wxstc.wxSTC_FIND_REGEXP)
                if (start_pos < 0) then
                    start_pos = doc:FindText(1, n, token, wxstc.wxSTC_FIND_REGEXP)
                end
            end
        end

        end_pos = doc:FindText(start_pos, n, "\n")
        doc:set_range_visible(start_pos, end_pos)
        doc:SetSelection(start_pos, end_pos)
        return 0
    end

    return self
end

function ihx_doc_init(doc)
    local self = {}
    local ihx_doc = self
    self.doc = doc

    function ihx_doc:run_doc(filepath)
        local doc = self.doc
        print("ihx_run_doc", filepath)
        doc.m_debugger:Run(doc.m_filepath, doc:GetText())
    end

    function ihx_doc:precompile()
        local doc = self.doc
        print("ihx_precompile")

        -- do the compilation
        --local records = s8051_debugger:ihx_scan_file(doc.m_filepath)
        --local msg = s8051:get_records_string(records)
        --log(msg)
        return true -- return true if it compiled ok
    end

    function ihx_doc:get_func_list(tree) 
        local doc = self.doc
        doc.m_func_list = {}
        gen_func_tree(tree, doc, doc.m_func_list)
    end

    function ihx_doc:find_func_pos(text, token)
    end

    return self
end

function python_doc_init(doc)        
    local self = {}
    local python_doc = self
    
    self.doc = doc

    function python_doc:run_doc(filepath)
    end

    function python_doc:precompile()
        dlog("python not support compile yet, please select Run")
    end
    
    function python_doc:get_func_list(tree)
        local doc = self.doc
        local lst = {}
        local s = doc:GetText()
       
        -- for each line
        for line in s:gmatch("[^\r\n]+") do 
            -- for each token split by space        
            for t in string.gmatch(line, "[^%s]+") do 
                if (t == "class" or t == "def") then
                    table.insert(lst, line)  
                end
                break           
            end 
        end   

        doc.m_func_list = lst
        gen_func_tree(tree, doc, lst)  

        return lst
    end

    function python_doc:find_func_pos(text, token)
        --token = trim(token)
        token = token:gsub("\n", "")
        log("["..token.."]")
        n = doc:GetLength()
        start_pos = doc:FindText(1, n, token, wxstc.wxSTC_FIND_REGEXP)
        --log(start_pos)
        end_pos = doc:FindText(start_pos, n, "\n")
        doc:set_range_visible(start_pos, end_pos)
        doc:SetSelection(start_pos, end_pos)
    end

    return self
end

function default_doc_init(doc)        
    local self = {}
    local default_doc = self
    
    self.doc = doc

    function default_doc:run_doc(filepath)
    end

    function default_doc:precompile()
    end

    function default_doc:get_func_list(tree) 
        local doc = self.doc
        doc.m_func_list = {}
        gen_func_tree(tree, doc, doc.m_func_list)
    end

    function default_doc:find_func_pos(text, token)
    end

    return self
end

function lua_doc_init(doc)
    local lua = {}
    lua.doc = doc

    function lua:precompile()
        local doc = lua.doc --MyApp.get_current_doc()

        dlog("lua_precompile")
        -- do the compilation
        local ret, errMsg, line_num = wxlua.CompileLuaScript(doc:GetText(), doc.m_filepath)

        if line_num > -1 then
            dlog("!!! Error at line :"..tostring(line_num).."\n"..errMsg.."\n\n")
            doc:GotoLine(line_num-1)
            return false
        else
            dlog("***  Compile pass!\n\n")
        end

        return true -- return true if it compiled ok
    end

    function lua:run_doc(filename)
        local cmd = wxLua_path.." --nostdout /c "..filename
        dprint(cmd)
        os.execute(cmd)  -- /c with console
    end

    function lua:find_func_pos(doc, token)
        token = trim(token)
        --log("["..token.."]")
        --print(token, text)
        n = doc:GetLength()
        token = "function "..token.."[(w*)]"
        start_pos = doc:FindText(1, n, token, wxstc.wxSTC_FIND_REGEXP)
        --log(start_pos)
        end_pos = doc:FindText(start_pos, n, "\n")
        doc:set_range_visible(start_pos, end_pos)
        doc:SetSelection(start_pos, end_pos)
        return 0
    end

    function lua_get_block(lst, tokens, i0)
        i = i0 + 1
        while i <= #tokens do
            t = tokens[i]

            if (t == "end") then
                return i    
            elseif (t == "if" or t == "for" or t == "while" ) then
                i = lua_get_block(lst, tokens, i) 
            end
            i = i + 1
        end
        return #tokens
    end

    function lua_get_function(lst, tokens, i0)
        local sublst = {}
        local t = tokens[i0 + 1]
        --print("func", t, i0)

        i = i0 + 1
        while i <= #tokens do
            t = tokens[i]
            
            if (t == "end") then
                table.insert(lst, sublst)
                return i   
            elseif (t == "if" or t == "for" or t == "while" ) then
                i = lua_get_block(sublst, tokens, i)
            elseif (t  == "function") then
                if (tokens[i+1] == "(") then
                    if (tokens[i - 1] == "=") then
                        table.insert(sublst, tokens[i-2])
                    end
                else
                    table.insert(sublst, tokens[i+1])
                end
                i = lua_get_function(sublst, tokens, i) 
            end   
            i = i + 1
        end
        return #tokens
    end

    function lua_pre_process(s) 
        s = s:gsub("([--][^\n]+[\n])", "\n")         -- replace line comment
        s = s:gsub("%-%-%[%[[^%]|%[]+%]]%-%-", " ")  -- replace block comment
        --s = s:gsub("%([^%(%)]*%)", " ( ) ")          -- replace parenthesis
        s = s:gsub("\"[^\"\n]*\"", "")               -- replace string
        s = s:gsub("%[%[[^%[^%]]*%]%]", "")               -- replace string 
        s = s:gsub("%(", " ( ")
        s = s:gsub("%)", " ) ")
        s = s:gsub("[{]", " { ")
        s = s:gsub("[}]", " } ")
        s = s:gsub(",", " , ")
        s = s:gsub("=", " = ")
        
        return s
    end

    function lua:get_func_list(tree)
        local doc = lua.doc 
        local text = doc:GetText()   
        local tokens = {}
        local f = 0
        local quote = false
        local keystr  = "if then else while do function for in end"

        text = lua_pre_process(text)
        --print(text)
        -- for each line
        for line in text:gmatch("[^\r\n]+") do 
            with_key = false
            for t in string.gmatch(keystr, "[^%s]+") do 
                if (line:find(t)) then
                    with_key = true
                    break
                end
            end 

            if (with_key == true) then
                -- for each token split by space        
                for t in string.gmatch(line, "[^%s]+") do 
                    table.insert(tokens, t)  
                end 
                table.insert(tokens, "\n") 
            end        
        end  

        local func_lst = {}
        local i = 1
        while i <= #tokens do
            t = tokens[i]
            if (t  == "function") then
                if (tokens[i+1] == "(") then
                    if (tokens[i - 1] == "=") then
                        table.insert(func_lst, tokens[i-2])
                    end
                else
                    table.insert(func_lst, tokens[i+1])
                end
                i = lua_get_function(func_lst, tokens, i)            
            end
            i = i + 1
        end

        doc.m_func_list = func_lst
        gen_func_tree(tree, doc, func_lst) 
        return func_lst
    end

    return lua
end

function MyDebugNB:create(parent, frame)
    local ctrl = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
                                wx.wxDefaultPosition, wx.wxDefaultSize,
                                wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE + wx.wxNO_BORDER 
                                - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB);


    local text = wx.wxTextCtrl(ctrl, wx.wxID_ANY, "",
                          wx.wxDefaultPosition, wx.wxDefaultSize,
                          wx.wxTE_READONLY + wx.wxTE_MULTILINE + wx.wxTE_RICH )
    --local text = wxstc.wxStyledTextCtrl(ctrl, wx.wxID_ANY,
    --                                  wx.wxDefaultPosition, wx.wxDefaultSize,
    --                                  wx.wxSUNKEN_BORDER)

    parent.m_debug_info = text    
    
    --text:SetDefaultStyle(wx.wxTextAttr(wx.wxRED)) 
    --text:AppendText("Red text\n")
    --text:SetDefaultStyle(wx.wxTextAttr(wx.wxRED, wx.wxGREEN))
    --text:AppendText("Red on green text\n")
    --text:SetDefaultStyle(wx.wxTextAttr(wx.wxBLUE, wx.wxColour(127, 127, 127)))
    --text:AppendText("Blue on grey text\n")

    ctrl:AddPage(parent.m_debug_info, wxT("Debug"), false, get_bitmap(wx.wxART_HELP_SIDE_PANEL) );
        
    return ctrl;
end

function MyLogNB:create(parent, frame)
    local ctrl = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
                                wx.wxPoint(0, 800), --wx.wxPoint(client_size.x, client_size.y),
                                wx.wxSize(200,160),
                                wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE + wx.wxNO_BORDER 
                                - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB);   

    parent.m_logger = wx.wxTextCtrl(ctrl, wx.wxID_ANY, "",
                          wx.wxDefaultPosition, wx.wxSize(-1, -1),
                          wx.wxTE_READONLY + wx.wxTE_MULTILINE )    
    
    ctrl:AddPage(parent.m_logger, wxT("log"), false, get_bitmap(wx.wxART_INFORMATION) );
        
    return ctrl;
end

function MyFileDropTarget(window)
    local self = wx.wxLuaFileDropTarget()
    self.window = window

    function self.OnDropFiles(self, x, y, filenames)
        self.window:DropFiles(x, y, filenames)
        return true
    end
    return self
end

color = {
    DEFAULT =      wx.wxColour(0,0,0),        

    COMMENT =      wx.wxColour(128,128,128),
    COMMENTBLOCK = wx.wxColour(128,128,256),
    COMMENTLINE =  wx.wxColour(128,128,128),  
    COMMENTDOC   = wx.wxColour(128,128,256),

    IDENTIFIER =   wx.wxColour(60,60,60),
    
    CHARACTER =    wx.wxColour(225,128,0),
    NUMBER =       wx.wxColour(0,196,0),
    OPERATOR =     wx.wxColour(128,0,196),
    STRING =       wx.wxColour(225,127,0),
    STRINGEOL =    wx.wxColour(225,0,0),

    WORD =         wx.wxColour(0,0,247),
    WORD1 =         wx.wxColour(127,0,247),
    WORD2 =         wx.wxColour(0,0,127),
    WORD3 =         wx.wxColour(0,128,255),
    WORD4 =         wx.wxColour(196,196,0),

    CLASSNAME =    wx.wxColour(0,128,0),
    DEFNAME =      wx.wxColour(0,0,128),
    TRIPLE =       wx.wxColour(0,0,0),
    TRIPLEDOUBLE = wx.wxColour(0,0,0),

    PREPROCESSOR = wx.wxColour(60,128,60),
}

function doc_set_lua_lexer(editor)
    local style = {
        wxSTC_LUA_CHARACTER = {7, color.CHARACTER},
        wxSTC_LUA_COMMENT = {1, color.COMMENT, "Italic"},
        wxSTC_LUA_COMMENTDOC = {3, color.COMMENTBLOCK, "Italic"}, 
        wxSTC_LUA_COMMENTLINE = {2, color.COMMENT, "Italic"},
        wxSTC_LUA_DEFAULT = {0, color.DEFAULT},
        wxSTC_LUA_IDENTIFIER = {11, color.IDENTIFIER},
        wxSTC_LUA_LITERALSTRING = {8, color.STRING},
        wxSTC_LUA_NUMBER = {4, color.NUMBER},
        wxSTC_LUA_OPERATOR = {10, color.OPERATOR, "Bold"},
        wxSTC_LUA_PREPROCESSOR = {9, color.PREPROCESSOR},
        wxSTC_LUA_STRING = {6, color.STRING},
        wxSTC_LUA_STRINGEOL = {12, color.STRINGEOL},
        wxSTC_LUA_WORD = {5, color.WORD, "Bold"},
        wxSTC_LUA_WORD2 = {13, color.WORD2},
        wxSTC_LUA_WORD3 = {14, color.WORD3},
        wxSTC_LUA_WORD4 = {15, color.WORD4},
        wxSTC_LUA_WORD5 = {16, color.WORD4},
        wxSTC_LUA_WORD6 = {17, color.WORD4},
    }
    editor:SetLexer(wxstc.wxSTC_LEX_LUA); 

    for key,value in pairs(style) do
        --log(key, value, value[1], value[2])
        editor:StyleSetForeground(value[1], value[2]);
    end

    --Key words
    editor:SetKeyWords(0, wxT("function for while repeat until if else elseif end break return in do then switch case .def"));
    editor:SetKeyWords(1, wxT("local"));
    editor:SetKeyWords(2, wxT("and or not"));
    editor:SetKeyWords(3, wxT("nil true false"));
end  

function doc_set_cpp_lexer(self)
    self:SetLexer(wxstc.wxSTC_LEX_CPP); 
    local style = {
        [wxstc.wxSTC_C_CHARACTER] = color.CHARACTER,
        [wxstc.wxSTC_C_COMMENT] = color.COMMENT,
        [wxstc.wxSTC_C_COMMENTDOC] = color.COMMENTDOC,
        [wxstc.wxSTC_C_COMMENTDOCKEYWORD] = color.COMMENTDOC,
        [wxstc.wxSTC_C_COMMENTDOCKEYWORDERROR] = color.COMMENTDOC,
        [wxstc.wxSTC_C_COMMENTLINE] = color.COMMENTLINE,
        [wxstc.wxSTC_C_COMMENTLINEDOC] = color.COMMENTDOC,
        [wxstc.wxSTC_C_DEFAULT] = color.DEFAULT,
        [wxstc.wxSTC_C_IDENTIFIER] = color.IDENTIFIER,
        [wxstc.wxSTC_C_NUMBER] = color.NUMBER,
        [wxstc.wxSTC_C_OPERATOR] = color.OPERATOR,
        [wxstc.wxSTC_C_PREPROCESSOR] = color.PREPROCESSOR,
        [wxstc.wxSTC_C_REGEX] = color.STRING,
        [wxstc.wxSTC_C_STRING] = color.STRING,
        [wxstc.wxSTC_C_STRINGEOL] = color.STRINGEOL,
        [wxstc.wxSTC_C_UUID] = color.STRING,
        [wxstc.wxSTC_C_VERBATIM] = color.WORD1,
        [wxstc.wxSTC_C_WORD] = color.WORD,
        [wxstc.wxSTC_C_WORD2] = color.WORD2,
    }

    for key,value in pairs(style) do
        self:StyleSetForeground(key, value);
    end

    --Key words
    self:SetKeyWords(0, wxT("for while repeat until if else elseif end break return in do struct class switch case"));
    self:SetKeyWords(1, wxT("void int short char long double float #include #define #typedef"));
    self:SetKeyWords(2, wxT(""));
    self:SetKeyWords(3, wxT("NULL TRUE FALSE nil true false"));
end  


function doc_set_python_lexer(self)
    style = {
        CHARACTER =    { 4, color.CHARACTER}, 
        CLASSNAME =    { 8, color.CLASSNAME},
        COMMENTBLOCK = {12, color.COMMENTBLOCK},
        COMMENTLINE =  { 1, color.COMMENTLINE},
        DEFAULT =      { 0, color.DEFAULT},
        DEFNAME =      { 9, color.DEFNAME},
        IDENTIFIER =   {11, color.IDENTIFIER},
        NUMBER =       { 2, color.NUMBER},
        OPERATOR =     {10, color.OPERATOR},
        STRING =       { 3, color.STRING},
        STRINGEOL =    {13, color.STRINGEOL},
        TRIPLE =       { 6, color.TRIPLE},
        TRIPLEDOUBLE = { 7, color.TRIPLEDOUBLE},
        WORD =         { 5, color.WORD},
    }

    for key,value in pairs(style) do
        self:StyleSetForeground(value[1], value[2]);
    end
    
    --Key words
    local keyword = [[and del from not while as elif global or with assert else if 
                      pass yield break except import print class exec in raise continue
                      finally is return def for lambda try]]
    self:SetKeyWords(0, wxT(keyword));
    self:SetKeyWords(1, wxT("void int short char long double float #include #define #typedef"));
    self:SetKeyWords(2, wxT("__init__ self parent __main__"));
    self:SetKeyWords(3, wxT("NULL TRUE FALSE nil true false"));
end 

function doc_set_js_lexer(self)
    local style = {
        wxSTC_LUA_CHARACTER = {7, color.CHARACTER},
        wxSTC_LUA_COMMENT = {1, color.COMMENT, "Italic"},
        wxSTC_LUA_COMMENTDOC = {3, color.COMMENTBLOCK, "Italic"}, 
        wxSTC_LUA_COMMENTLINE = {2, color.COMMENT, "Italic"},
        wxSTC_LUA_DEFAULT = {0, color.DEFAULT},
        wxSTC_LUA_IDENTIFIER = {11, color.IDENTIFIER},
        wxSTC_LUA_LITERALSTRING = {8, color.STRING},
        wxSTC_LUA_NUMBER = {4, color.NUMBER},
        wxSTC_LUA_OPERATOR = {10, color.OPERATOR, "Bold"},
        wxSTC_LUA_PREPROCESSOR = {9, color.PREPROCESSOR},
        wxSTC_LUA_STRING = {6, color.STRING},
        wxSTC_LUA_STRINGEOL = {12, color.STRINGEOL},
        wxSTC_LUA_WORD = {5, color.WORD, "Bold"},
        wxSTC_LUA_WORD2 = {13, color.WORD2},
        wxSTC_LUA_WORD3 = {14, color.WORD3},
        wxSTC_LUA_WORD4 = {15, color.WORD4},
        wxSTC_LUA_WORD5 = {16, color.WORD4},
        wxSTC_LUA_WORD6 = {17, color.WORD4},
    }
    for key,value in pairs(style) do
        self:StyleSetForeground(value[1], value[2]);
    end

    local keyword = [[break case catch continue debugger default delete 
                      do else finally for function if in instanceof new 
                      return switch this throw try typeof var void while 
                      wit def ]]

    --Key words
    self:SetKeyWords(0, wxT(keyword))
    self:SetKeyWords(1, wxT("void int short char long double float #include #define #typedef"));
    self:SetKeyWords(2, wxT("__init__ self parent __main__"));
    self:SetKeyWords(3, wxT("NULL TRUE FALSE nil true false"));
end 

function doc_set_default_lexer(self)
    local style = {
--[[
        wxSTC_HJ_COMMENT = {42, color.COMMENT},
        wxSTC_HJ_COMMENTDOC = {44, color.COMMENTDOC},
        wxSTC_HJ_COMMENTLINE = {43, color.COMMENTLINE},
        wxSTC_HJ_DEFAULT = {41, color.DEFAULT},
        wxSTC_HJ_DOUBLESTRING = {48, color.STRING},
        wxSTC_HJ_KEYWORD = {47, color.WORD1},
        wxSTC_HJ_NUMBER = {45, color.NUMBER},
        wxSTC_HJ_REGEX = {52, color.STRING},
        wxSTC_HJ_SINGLESTRING = {49, color.STRING},
        wxSTC_HJ_START = {40, color.WORD2},
        wxSTC_HJ_STRINGEOL = {51, color.STRINGEOL},
        wxSTC_HJ_SYMBOLS = {50, color.CHARACTER},
        wxSTC_HJ_WORD = {46, color.WORD},
        CHARACTER =    { 4, color.CHARACTER}, 
        CLASSNAME =    { 8, color.CLASSNAME},
        COMMENTBLOCK = {12, color.COMMENTBLOCK},
        COMMENTLINE =  { 1, color.COMMENTLINE},
        DEFAULT =      { 0, color.DEFAULT},
        DEFNAME =      { 9, color.DEFNAME},
        IDENTIFIER =   {11, color.IDENTIFIER},
        NUMBER =       { 2, color.NUMBER},
        OPERATOR =     {10, color.OPERATOR},
        STRING =       { 3, color.STRING},
        STRINGEOL =    {13, color.STRINGEOL},
        TRIPLE =       { 6, color.TRIPLE},
        TRIPLEDOUBLE = { 7, color.TRIPLEDOUBLE},
        WORD =         { 5, color.WORD},
--]]
        wxSTC_LUA_CHARACTER = {7, color.CHARACTER},
        wxSTC_LUA_COMMENT = {1, color.COMMENT, "Italic"},
        wxSTC_LUA_COMMENTDOC = {3, color.COMMENTBLOCK, "Italic"}, 
        wxSTC_LUA_COMMENTLINE = {2, color.COMMENT, "Italic"},
        wxSTC_LUA_DEFAULT = {0, color.DEFAULT},
        wxSTC_LUA_IDENTIFIER = {11, color.IDENTIFIER},
        wxSTC_LUA_LITERALSTRING = {8, color.STRING},
        wxSTC_LUA_NUMBER = {4, color.NUMBER},
        wxSTC_LUA_OPERATOR = {10, color.OPERATOR, "Bold"},
        wxSTC_LUA_PREPROCESSOR = {9, color.PREPROCESSOR},
        wxSTC_LUA_STRING = {6, color.STRING},
        wxSTC_LUA_STRINGEOL = {12, color.STRINGEOL},
        wxSTC_LUA_WORD = {5, color.WORD, "Bold"},
        wxSTC_LUA_WORD2 = {13, color.WORD2},
        wxSTC_LUA_WORD3 = {14, color.WORD3},
        wxSTC_LUA_WORD4 = {15, color.WORD4},
        wxSTC_LUA_WORD5 = {16, color.WORD4},
        wxSTC_LUA_WORD6 = {17, color.WORD4},
    }
    for key,value in pairs(style) do
        self:StyleSetForeground(value[1], value[2]);
    end

    local keyword = [[break case catch continue debugger default delete 
                      do else finally for function if in instanceof new 
                      return switch this throw try typeof var void while 
                      wit def ]]

    --Key words
    self:SetKeyWords(0, wxT(keyword))
    self:SetKeyWords(1, wxT("void int short char long double float #include #define #typedef"));
    self:SetKeyWords(2, wxT("__init__ self parent __main__"));
    self:SetKeyWords(3, wxT("NULL TRUE FALSE nil true false"));
end 


function MyDoc(parent, panel, id, filepath)
    local self = wxstc.wxStyledTextCtrl(panel, id,
                                      wx.wxDefaultPosition, wx.wxDefaultSize,
                                      wx.wxSUNKEN_BORDER)
    --print(filepath)
    self.m_id = id;
    self.m_filepath = filepath;
    self.m_filename = get_filename(filepath)
    self.m_breakpoints = {}
    self.m_func_list = {}
    self.m_editor = self

    self:SetBufferedDraw(true)
    self:StyleClearAll()

    self.m_file_ext = get_filename_ext(self.m_filepath)

    local ext = self.m_file_ext
    -- to add asm and lst, hex support
    if (ext == "lua") then
        self.m_lex_type = wxstc.wxSTC_LEX_LUA
       
        doc_set_lua_lexer(self)               
        self.m_doc_t = lua_doc_init(self)
        self.m_debugger = lua_debugger
    elseif (ext == "c" or self.m_file_ext == "cpp" or 
        self.m_file_ext == "cc" or self.m_file_ext == "h" or
        self.m_file_ext == "hpp") then        
        self.m_lex_type = wxstc.wxSTC_LEX_CPP
        doc_set_cpp_lexer(self)
        self.m_doc_t = c_doc_init(self)
        self.m_debugger = c_debugger
    elseif (ext == "ihx") then   
        self.m_lex_type = wxstc.wxSTC_LEX_NULL 
        doc_set_default_lexer(self)
        self.m_doc_t = ihx_doc_init(self)
        self.m_debugger = s8051_debugger
    elseif (ext == "py") then
        self.m_lex_type = wxstc.wxSTC_LEX_PYTHON
        self:SetLexer(self.m_lex_type)
        doc_set_python_lexer(self)
        self.m_doc_t = python_doc_init(self)
        self.m_debugger = 0
    elseif (ext == "js") then
        self.m_lex_type = wxstc.wxSTC_LEX_LUA            
        self:SetLexer(self.m_lex_type)
        doc_set_js_lexer(self)
        self.m_doc_t = default_doc_init(self)
        self.m_debugger = 0       
    else
        self.m_lex_type = wxstc.wxSTC_LEX_LUA            
   
        self:SetLexer(self.m_lex_type)
        doc_set_default_lexer(self)
        self.m_doc_t = default_doc_init(self)
        self.m_debugger = 0
    end

    local faces = { times = 'Times New Roman',
                    mono  = 'Courier New',
                    helv  = 'Arial',
                    other = 'Comic Sans MS',
                    size  = 10,
                    size2 = 8,
                  }
    -- Global default styles for all languages
    --self:StyleSetSpec(wxstc.wxSTC_STYLE_DEFAULT,     string.format("face:%s,size:%d", faces.mono, faces.size))
    --self:StyleSetSpec(wxstc.wxSTC_STYLE_LINENUMBER,  string.format("back:#C0C0C0,face:%s,size:%d", faces.mono, faces.size2))
    --self:StyleSetSpec(wxstc.wxSTC_STYLE_CONTROLCHAR, string.format("face:%s", faces.others))
    --self:StyleSetSpec(wxstc.wxSTC_STYLE_BRACELIGHT,  "fore:#FFFFFF,back:#0000FF,bold")
    --self:StyleSetSpec(wxstc.wxSTC_STYLE_BRACEBAD,    "fore:#000000,back:#FF0000,bold")
    
    font       = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_NORMAL, wx.wxFONTWEIGHT_NORMAL, false, "Courier New")
    fontItalic = wx.wxFont(10, wx.wxFONTFAMILY_MODERN, wx.wxFONTSTYLE_ITALIC, wx.wxFONTWEIGHT_NORMAL, false, "Courier New")
        
    self:SetFont(font)
    self:StyleSetFont(wxstc.wxSTC_STYLE_DEFAULT, font)
    for i = 0, 32 do
        self:StyleSetFont(i, font)
    end
    
    self:SetUseTabs(false)
    self:SetTabWidth(4)
    self:SetIndent(4)
    self:SetIndentationGuides(true)
    
    -- set margin for line number display
    self:SetMarginType(0, wxstc.wxSTC_MARGIN_NUMBER)
    self:SetMarginWidth(0, 48) 

    self:SetMarginWidth(1, 16) -- marker margin
    self:SetMarginType(1, wxstc.wxSTC_MARGIN_SYMBOL)
    self:SetMarginSensitive(1, true)

    -- set margin for fold margin
    self:SetMarginWidth(2, 16) -- fold margin
    self:SetMarginType(2, wxstc.wxSTC_MARGIN_SYMBOL)
    self:SetMarginMask(2, wxstc.wxSTC_MASK_FOLDERS)
    self:SetMarginSensitive(2, true)

    self:SetFoldFlags(wxstc.wxSTC_FOLDFLAG_LINEBEFORE_CONTRACTED +
                        wxstc.wxSTC_FOLDFLAG_LINEAFTER_CONTRACTED)

    self:SetProperty("fold", "1")
    self:SetProperty("fold.compact", "1")
    self:SetProperty("fold.comment", "1")

    local grey = wx.wxColour(128, 128, 128)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPEN,    wxstc.wxSTC_MARK_BOXMINUS, wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDER,        wxstc.wxSTC_MARK_BOXPLUS,  wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERSUB,     wxstc.wxSTC_MARK_VLINE,    wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERTAIL,    wxstc.wxSTC_MARK_LCORNER,  wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEREND,     wxstc.wxSTC_MARK_BOXPLUSCONNECTED,  wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDEROPENMID, wxstc.wxSTC_MARK_BOXMINUSCONNECTED, wx.wxWHITE, grey)
    self:MarkerDefine(wxstc.wxSTC_MARKNUM_FOLDERMIDTAIL, wxstc.wxSTC_MARK_TCORNER,  wx.wxWHITE, grey)

    self:MarkerDefine(MARKNUM_BREAK_POINT,  wxstc.wxSTC_MARK_CIRCLE, wx.wxBLACK, wx.wxGREEN)
    self:MarkerDefine(MARKNUM_CURRENT_LINE, wxstc.wxSTC_MARK_ARROW, wx.wxBLUE, grey)

    grey:delete()

    function self:precompile()
        self.m_doc_t:precompile()
    end

    function self:exec_cmd(cmd)
        local file = io.popen(cmd, 'rb') --gives both stdout and stderr in pipe
        local output = file:read('*all')
        file:close()
        
        dprint(output) 
    end

    function self:run_doc()
        local exe
        local path = self.m_filepath
        local ext = self.m_file_ext

        dprint("$clear$")  
        if (ext == "c") then
            self:precompile()
            return
        elseif (ext == "ihx") then
            ihx_doc:run_doc(path)
            return
        end
              
        self:save_file()

        if (ext == "lua") then
            if (self:precompile() == false) then            
                log("fail")
                return
            end
            exe = wxLua_path.." --nostdout /c "   -- /c with console        
            --f = loadfile(path)
            --f()
            --return
        elseif (ext == "py") then
            exe = Python_path        
        elseif (ext == "js") then
            --exe = "C:\\wx\\wxjs\\bin\\wxjs.exe"  
            exe = NodeJS_path
        elseif (ext == "c") then
            exe = SDCC_path
        end
        local cmd = exe.." "..path
        dprint(cmd)
        --os.execute(cmd)          
        wx.wxFileName.SetCwd(wx.wxFileName(path):GetPath())
        self:exec_cmd(cmd)
    end

    function self:set_range_visible(pos_start, pos_end)
        if pos_start > pos_end then
            pos_start, pos_end = pos_end, pos_start
        end

        local line_start = self:LineFromPosition(pos_start)
        local line_end   = self:LineFromPosition(pos_end) + 2
        for line = line_start, line_end do
            self:EnsureVisibleEnforcePolicy(line)
        end
    end

    function self:get_func_list(tree)
        local t = self.m_doc_t
        t:get_func_list(tree)
    end

    function self:save_file()
        if (self.m_modified) then
            self:SaveFile(self.m_filepath)
            self.m_modified = false
        end
    end

    function self:ask_if_reload(msg) 
        local result = wx.wxMessageBox(self.m_filepath.." is modified. Do you want to reload?", msg, wx.wxYES_NO)
        --print(string.format("ask if reload %x, %x, %x, %x", result, wx.wxID_YES, wx.wxID_CANCEL, wx.wxID_NO))
        if (result == 2) then  -- Yes == 2, No == 8
            --print("load ", self.m_filepath)
            self:save_file()
            return wx.wxID_YES
        else
            return wx.wxID_CANCEL
        end  
    end

    function self:ask_if_save(msg) 
        local result = wx.wxMessageBox(self.m_filepath.." is modified. Do you want to save?", msg, wx.wxYES_NO)
        if (result == 2) then -- Yes == 2, No == 8
            self:save_file()
            return wx.wxID_YES
        else
            return wx.wxID_CANCEL
        end  
    end

    function self:clear_cur_line_marker(line)
        self:MarkerDelete(line, MARKNUM_CURRENT_LINE)        
    end

    function self:toggle_breakpoint(line)
        local markers = self:MarkerGet(line)
        local dbg = MyDbg.m_debugger

        if (self.m_breakpoints[line] == 0) then
            self:MarkerAdd(line, MARKNUM_BREAK_POINT)
            self.m_breakpoints[line] = 1
            if (dbg) then
                dbg:AddBreakPoint(self.m_filepath, line)
            end
        else
            self:MarkerDelete(line, MARKNUM_BREAK_POINT)
            self.m_breakpoints[line] = 0
            if (dbg) then
                dbg:RemoveBreakPoint(self.m_filepath, line)
            end
        end
        
        --print(self.m_breakpoints)
    end

    function self.OnDocMarginClick(event)
        local line = self:LineFromPosition(event:GetPosition())
        local margin = event:GetMargin()
        --log(margin)
        if margin == 1 then
            log("toggle")
            self:toggle_breakpoint(line)
        elseif margin == 2 then
            if wx.wxGetKeyState(wx.WXK_SHIFT) and wx.wxGetKeyState(wx.WXK_CONTROL) then
                FoldSome()
            else
                local level = self:GetFoldLevel(line)
                if hasbit(level, wxstc.wxSTC_FOLDLEVELHEADERFLAG) then
                    self:ToggleFold(line)
                end
            end
        end
    end

    function self.OnDocModified(event)      
        self.m_modified = self:GetModify()
    end

    function self.OnDocKeyPressed(event)
        if self:CallTipActive() then
            self:CallTipCancel()
        end
        local key = event:GetKey()
        --log("k"..tostring(key))
        if (key == 46) then
            local pos = self:GetCurrentPos()
            -- must have "wx.X" otherwise too many items
            local range = self:GetTextRange(pos-3, pos)
            --log(range)
            if range == "wx." then
                wx_key_pos = pos - 3
                self:AutoCompShow(0, wx_key_str)
            end
        end

        event:Skip()    
    end 
      
    -- connect event with doc modified
    self:Connect(wxstc.wxEVT_STC_SAVEPOINTLEFT, self.OnDocModified)
    self:Connect(wxstc.wxEVT_STC_CHARADDED, self.OnDocKeyPressed)
    self:Connect(wxstc.wxEVT_STC_MARGINCLICK, self.OnDocMarginClick)

    local dt = MyFileDropTarget(self)
    self:SetDropTarget(dt)

    function self.DropFiles(self, x, y, filenames)
        if (#filenames >= 1) then
            filename = filenames[1]
            MyApp:open_file(filename)
        end
    end

    return self
end

function MyDocNB:create(parent, frame)
    self = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
                                    wx.wxDefaultPosition,
                                    wx.wxDefaultSize,
                                    wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE + 
                                    wx.wxNO_BORDER);
    self.m_nb = self
    self.m_docs  = {}  
    self.m_cur_doc = nil
    self.m_new_file_index = 0

    function self:get_if_file_opened(filepath)
        local doc = self.m_docs[filepath]
        return doc
    end

    function self:create_doc_editor(filepath)       
        -- create new document editor
        local doc = MyDoc(self, self, wx.wxNewId(), filepath);
        --print("load", doc, doc.m_filepath)
        if (filepath == "") then 
            filepath = "untitled"
        end

        self.m_docs[filepath] = doc    
         
        -- add page to center notebook
        self:AddPage(doc, doc.m_filename, false);   
        
        -- store page index for selection
        doc.m_page_index = self:GetPageIndex(doc);
           
        return doc;
    end
    
    function self:get_new_filename()
        local cwd = wx.wxFileName.GetCwd()
        local filepath = cwd.."\\untitled"..tostring(self.m_new_file_index)..".lua"
        self.m_new_file_index = self.m_new_file_index + 1
        while (file_exist(filepath)) do
            filepath = cwd.."\\untitled"..tostring(self.m_new_file_index)..".lua"
            self.m_new_file_index = self.m_new_file_index + 1
        end
        print(filepath)
        --local output_file = io.output(io.open(filepath, "w"))  
        --io.write(" ")
        --output_file:close()
        return filepath
    end

    function self:new_file()                 
        local filepath = self:get_new_filename()

        local doc = self:create_doc_editor(filepath) 

        local page_i = doc.m_page_index
        
        print("New", filepath, page_i)

        self:SetSelection(page_i)          
    
        doc:get_func_list(MyApp.m_functree, doc)
        doc.m_modified = false

        self.m_cur_doc = doc
    end

    function self:open_file(filepath)     
        if (file_exist(filepath) == false) then
            return nil
        end
        local doc = self.m_docs[filepath]
        
        if (doc == nil) then
            doc = self:create_doc_editor(filepath) 
        end

        local page_i = doc.m_page_index
        
        print("Open", filepath, page_i)

        self:SetSelection(page_i)  
        
        if (filepath ~= "") then        
            doc:LoadFile(filepath)
            MyPrj:add_file(filepath)
            doc:get_func_list(MyApp.m_functree)
            doc.m_modified = false
        else 
            doc:SetText("")
        end

        self.m_cur_doc = doc
        return doc
    end

    function self:check_docs_modified(dt)
        for path, doc in pairs(self.m_docs) do 
            local file_mod_time, exist = get_file_mod_time(path) 
            if (exist == true) then
                if (file_mod_time:IsLaterThan(dt)) then
                    doc:ask_if_reload("Save on close")
                end
            end
        end
    end

    function self.create_html_ctrl(parent)
        local html = wx.wxHtmlWindow(parent, wx.wxID_ANY,
                                       wx.wxDefaultPosition,
                                       wx.wxSize(400,300));
        local html_text = [[
            <html><body>
            <h3>Welcome to My wxLua IDE</h3>   
            Athena 2013.10.1
           
            </body></html>
        ]]
        html:SetPage(html_text);

        local dt = MyFileDropTarget(html)
        html:SetDropTarget(dt)

        function html.DropFiles(self, x, y, filenames)
            if (#filenames >= 1) then
                filename = filenames[1]
                log("dropfile "..filename)
                MyApp:open_file(filename)
            end
        end
        
        html.m_filepath = ""
        html.m_filename = ""
        parent.html_ctrl = html
        return html
    end    

    function self:update_nb_page_title(filename)
        -- get notebook setected page index    
        local page_i = self:GetSelection()    

        if (filename == "") then 
            self:SetPageText(page_i, wxT("untitled.lua"))
        else
            local name = get_filename(filename)
            --print("SetPageText", name)
            self:SetPageText(page_i, wxT(name))
        end   
    end

    function self:update_current_doc()    
        -- get notebook setected page index
        local page_i = self:GetSelection()
        
        -- get doc by page index
        local doc = self:GetPage(page_i)
        if (doc == nil) then
            print(update_current_doc, "doc == nil", doc, page_i)
            return nil
        end
        self.m_cur_doc = self.m_docs[doc.m_filepath]

        return self.m_cur_doc 
    end

    function self:get_current_doc()           
        return self:update_current_doc() 
    end

    function self:get_current_file()    
        local doc = self:get_current_doc()
        if (doc) then
            return doc.m_filepath
        else
            return ""
        end
    end

    function self:set_current_file()    
    end

    function self:print_docs()
        for key, value in pairs(self.m_docs) do 
            print(key, value) 
        end
    end

    function self:remove_doc(doc) 
        print("remove doc  ", doc)

        self.m_docs[doc.m_filepath] = nil
     
        --self:update_current_doc()
        --self:print_docs()
    end

    function self:save_on_close_file(doc)    
        -- print(self, event)
        if (doc ~= nil and doc.m_modified) then
            return doc:ask_if_save("Save on close")           
        end

        self:remove_doc(doc)
        return wx.wxID_YES
    end

    function self:check_doc(doc)
        print(doc, doc["m_modified"], doc.m_modified)

    end

    function self:save_on_exit(event)  
        --log("save_on_exit")
        for path_key, doc in pairs(self.m_docs) do
            --print(path_key, doc)
            if (doc ~= nil) then        
                self:check_doc(doc)
                if (doc["m_modified"]) then           
                    return doc:ask_if_save("Save on exit")          
                end
            end
        end
        return wx.wxID_YES
    end

    function self.OnPageClose(event)
        local i = event:GetSelection()
        local page_text = self:GetPageText(i)
    
        if (page_text == "Information") then
            self:update_current_doc()
        else
            print("close", self:GetPage(event:GetSelection()).m_filename)
            local doc = self.m_cur_doc --self:GetPage(event:GetSelection())
            self:check_doc(doc)    
            self:save_on_close_file(doc) 
        end
        event:Skip()
    end

    function self.OnPageChange(event) 
        local i = event:GetSelection()
        local page_text = self:GetPageText(i)
    
        if (page_text == "Information") then
            self.m_cur_doc = nil
        else
            local doc = self:update_current_doc()
            --print(doc)
            if (doc) then    
                --print("page", doc.m_filename)

                local lst = doc.m_func_list
                if (doc.m_filename ~= "") then
                    gen_func_tree(MyApp.m_functree, doc, lst)
                end
            end
        end
        MyApp:OnDocPageChange(event)
        event:Skip()
    end  

    self:AddPage(self.create_html_ctrl(self), wxT("Information") , false, get_bitmap(wx.wxART_NORMAL_FILE));

    self:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CLOSE, self.OnPageClose)
    self:Connect(wxaui.wxEVT_COMMAND_AUINOTEBOOK_PAGE_CHANGED, self.OnPageChange)

    return self;
end

lua_debugger = {}
function lua_debugger:init()    
    --log("create lua_debugger")
        
    self.m_debug_run = 0
    self.m_cur_debug_line = 0
    self.m_cur_debug_doc = nil
    self.m_dbg = nil

    function self:set_breakpoint()   
        local doc = self.m_cur_debug_editor
        local n = doc:GetLineCount()
        local dbg = self.m_dbg
        --log("set_breakpoint", doc.m_filepath)
        dbg:ClearAllBreakPoints()
        for line = 1, n do
            if (doc.m_breakpoints[line] == 1) then
                log(dbg:AddBreakPoint(doc.m_filepath, line))
            end
        end
        --dbg:AddBreakPoint(doc.m_filepath, n)
    end

    function self:clear_prev_line_marker()
        if (self.m_cur_debug_editor) then
            self.m_cur_debug_editor:MarkerDelete(self.m_cur_debug_line, MARKNUM_CURRENT_LINE)
        end
    end

    function self.OnDebugeeConnected(event)
        log("dbg Connected")
        local doc = self.m_cur_debug_editor
      
        wxlua_debug_file_end = 0

        self:Run(doc.m_filepath, doc.m_editor:GetText().."\r\n    wxlua_debug_file_end = 1\r\n")        
        
        self:Step()
        self:set_breakpoint()
    end

    -- StopServer() -> got event OnDebuggerExit -> got event OnDebugeeDisconnected
    function self.OnDebugeeDisconnected(event)    
        log("dbg Disconnected")

        if (self.m_debug_run) then    
            --dbg:KillDebuggee()
            local dbg = self.m_dbg
            dbg:Disconnect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_CONNECTED)
            dbg:Disconnect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_DISCONNECTED)        
            dbg:Disconnect(wxlua.wxEVT_WXLUA_DEBUGGER_BREAK)
            dbg:Reset() 
            dbg.m_debug_run = 0

            dbg = nil
            self.m_dbg = nil
            --MyApp.m_debugger = nil
        end
    end

    function self.OnDebuggerBreak(event)
        local line = event:GetLineNumber()
        local filename = event:GetFileName()
        --log("dbg Break "..tostring(line).."   "..filename.."  ref:"..tostring(event:GetReference()))
        
        local doc = MyApp:get_current_doc()
                
        self:clear_prev_line_marker()
        
        if (line >= doc:GetLineCount()) then
            log("DBG: run to the end, StopServer")
            --MyApp.m_debugger:StopServer() 
        else
            doc:MarkerAdd(line, MARKNUM_CURRENT_LINE)
            doc:GotoLine(line)    
            doc:SetSelectionStart(doc:PositionFromLine(line))
            doc:SetSelectionEnd(doc:GetLineEndPosition(line))

            self.m_cur_debug_editor = doc
            self.m_cur_debug_line = line 
        end
    end

    function self.OnDebuggerExit(event)
        log("*** DBG Exit:"..event:GetMessage())
        --stop_debug(event)

        if (self.m_debug_run) then
            self.m_debug_run = 0

            self.m_dbg:KillDebuggee()
            self.m_dbg:ClearAllBreakPoints()       
            self:clear_prev_line_marker()
        end
    end

    function self.OnDebuggerPrint(event)
        log("DBG Print:"..event:GetMessage())
    end

    function self.OnDebuggerError(event)
        log("DBG Error:"..event:GetMessage())
    end

    function self.OnDebuggerStackEnum(event)
        log("DBG StackEnum:"..event:GetMessage())
    end

    function self.OnDebuggerStackEntryEnum(event)
        log("DBG StackEntryEnum:"..event:GetMessage())
    end

    function self.OnDebuggerStackTableEnum(event)
        log("DBG StackTableEnum:"..event:GetMessage())
    end

    function self.OnDebuggerEvalExpr(event)
        log("DBG EvalExpr:"..event:GetMessage())
    end
        
    function self:Start() 
        if (self.m_dbg  == nil) then
            log("create wxLuaDebuggerServer")
            self.m_dbg  = wxlua.wxLuaDebuggerServer(1551)
        
        end

        --log("debugger "..tostring(dbg))
        if (self.m_dbg ) then 
            
            self.m_debug_run = 1
            self.m_cur_debug_line = 0
            self.m_cur_debug_editor = MyApp:get_current_doc()
                 
            local dbg = self.m_dbg

            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_CONNECTED,    self.OnDebugeeConnected)
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_DEBUGGEE_DISCONNECTED, self.OnDebugeeDisconnected)  

            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_BREAK,  self.OnDebuggerBreak)            
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_PRINT,  self.OnDebuggerPrint) 
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_ERROR,  self.OnDebuggerError) 
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_EXIT,   self.OnDebuggerExit)

            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_STACK_ENUM,       self.OnDebuggerStackEnum) 
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_STACK_ENTRY_ENUM, self.OnDebuggerStackEntryEnum)
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_TABLE_ENUM,       self.OnDebuggerStackTableEnum)
            dbg:Connect(wxlua.wxEVT_WXLUA_DEBUGGER_EVALUATE_EXPR,    self.OnDebuggerEvalExpr)

            log("dbg:start server")
            log(dbg:StartServer())

            debuggee_pid = dbg:StartClient()
            --log("dbg:StartClient", debuggee_pid)
        end
        return true
    end

    function self:Stop( )
        log("OnStopDebug") 

        local dbg = self.m_dbg
        if (dbg) then
            dbg:StopServer() 
        end
    end

    function self:AddBreakPoint(fileName, lineNumber)
        if (self.m_dbg) then
            --log("AddBreakPoint", fileName, lineNumber, self.m_dbg, "\n")
            self.m_dbg:AddBreakPoint(fileName, lineNumber)
        end
    end

    function self:RemoveBreakPoint(fileName, lineNumber)
        if (self.m_dbg) then
            self.m_dbg:RemoveBreakPoint(fileName, lineNumber)
        end
    end

    function self:ClearAllBreakPoints( )
        if (self.m_dbg) then
            self.m_dbg:ClearAllBreakPoints()
        end
    end

    function self:Run(fileName, buffer)
        if (self.m_dbg) then
            self.m_dbg:Run(fileName, buffer)
        end
    end

    function self:Step()
        if (self.m_dbg) then
            self.m_dbg:Step()
        end
    end
    function self:StepOver()
        if (self.m_dbg) then
            self.m_dbg:StepOver()
        end
    end 

    function self:StepOut()
        if (self.m_dbg) then
            self.m_dbg:StepOut()
        end
    end

    function self:Continue()
        if (self.m_dbg) then            
            log("lua_debugger continue", self.m_dbg)
            return self.m_dbg:Continue()
        end
    end

    function self:Break()
        if (self.m_dbg) then
            self.m_dbg:Break()
        end
    end

    function self:Reset()
        if (self.m_dbg) then
            self.m_dbg:Reset()
        end
    end

    return self
end

function MyDbg:create(parent, menubar)
    self.m_menu = wx.wxMenu{
        { ID_RUN,       "Run\tF6",           "Run test" },
        { ID_COMPILE,   "Compile",  "Lua:Precompile to check syntax, C:Compile" },
        { },
        { ID_DBG_START,     "Debug run\tF5",   "Run at debugger mode" },        
        { ID_DBG_STEP,      "Step\tF11",   "Next step from current line of debugger mode" },
        { ID_DBG_STEP_OVER, "Step Over",   "Next step, bypass function" },
        { ID_DBG_STEP_OUT,  "Step Out",    "Step out of current function" },
        { ID_DBG_STOP,      "Stop Debug",  "Stop and destroy debugger" },
    }
                
    menubar:Append(self.m_menu, "&Debug")

    self.m_debugger = nil
    self.m_debug_run = false
    
    function self:exec_cmd_get_stdout_stderr(cmd)
        local file = io.popen(cmd, 'rb') --gives both stdout and stderr in pipe
        local output = file:read('*all')
        file:close()
        log(output) 
    end

    function self:precompile()
        -- print("precompile")
        return MyApp:get_current_doc().m_doc_t:precompile()
    end
    
    function self.OnRun(event)
        local doc = MyApp:get_current_doc()
        doc:run_doc()        
    end

    function self.OnCompile(event)
        --local filename = MyApp:get_current_file()
        --log("***  Precompile "..filename)
        
        self:precompile()
    end

    function self.OnStartDebug(event)  
        local dbg = self.m_debugger
        if (dbg and self.m_debug_run) then
            log("continue")            
            dbg:Continue()
            return
        end
        
        local doc = MyApp:get_current_doc()
        if (doc.m_debugger == 0) then
            return
        end

        if (doc:precompile()) then  
            if (doc.m_debugger == lua_debugger) then
                log("lua:start debug")
                --dbg:Start() 
                self.m_debugger = lua_debugger:init()
                self.m_debugger:Start()
                self.m_debug_run = true
            else
                self.m_debugger = doc.m_debugger
                self.m_debug_run = self.m_debugger:Start(doc.m_filepath, doc:GetText())
                doc:set_breakpoint(self.m_debugger)
                self.m_debugger:Step()
            end 

            MyApp.m_debugger = self.m_debugger
        else
            log("compile error")
        end
    end

    function self.OnStepOut(event)
        if (self.m_debugger and self.m_debug_run) then
            self.m_debugger:StepOut()
        end
    end

    function self.OnStepOver(event)
        if (self.m_debugger and self.m_debug_run) then
            self.m_debugger:StepOver()
        end
    end

    function self.OnStep(event)
        if (self.m_debugger and self.m_debug_run) then
            self.m_debugger:Step()
        end
    end

    function self.OnStopDebug(event)
        log("OnStopDebug") 

        local debugger = self.m_debugger
        if (debugger) then
            self.m_debug_run = 0
            debugger:Stop() 
            self.m_debugger = nil
        end
    end

    parent:Connect(ID_RUN,           wx.wxEVT_COMMAND_MENU_SELECTED, self.OnRun);
    parent:Connect(ID_COMPILE,       wx.wxEVT_COMMAND_MENU_SELECTED, self.OnCompile);
    parent:Connect(ID_DBG_START,     wx.wxEVT_COMMAND_MENU_SELECTED, self.OnStartDebug);
    parent:Connect(ID_DBG_STEP,      wx.wxEVT_COMMAND_MENU_SELECTED, self.OnStep);
    parent:Connect(ID_DBG_STEP_OVER, wx.wxEVT_COMMAND_MENU_SELECTED, self.OnStepOver);
    parent:Connect(ID_DBG_STEP_OUT,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnStepOut);
    parent:Connect(ID_DBG_STOP,      wx.wxEVT_COMMAND_MENU_SELECTED, self.OnStopDebug);

    return self
end

function MyEditMenu(parent, menubar)
    local ID_PY2LUA = wx.wxNewId()
    local self = wx.wxMenu{
        { ID_UNDO,      "&Undo\tCtrl-Z",       "Undo the editing" },
        { ID_REDO,      "&Redo\tCtrl-Y",       "Redo the undo editing" },
        { },    
        { ID_CUT,       "Cu&t\tCtrl-X",        "Cut selected text to clipboard" },
        { ID_COPY,      "&Copy\tCtrl-C",       "Copy selected text to the clipboard" },
        { ID_PASTE,     "&Paste\tCtrl-V",      "Paste text from clipboard" },
        { ID_SELECTALL, "Select A&ll\tCtrl-A", "Select all text" },
        { },
        { ID_FIND,      "&Find\tCtrl-F",      "Find string" },
        { ID_FINDNEXT,  "Find Next\tF3",      "Find next match string" },
        { ID_REPLACE,   "Replace\tCtrl-H",    "Replace string" },
        { },
        { ID_FOLD,      "&Fold/Expand all\tF12", "Fold or Expand all code folds"},
        {},
        { ID_PY2LUA,    "Python to Lua",         "Convert python to lua"} 
    }
                
    menubar:Append(self, "&Edit")

    function get_selected_text(doc)
        local str = doc:GetTextRange(doc:GetSelectionStart(), doc:GetSelectionEnd())
        --log("get_selected_text "..str)
        return str
    end

    latest_pos = 1

    function find_check_direction(event)
        local flags = event:GetFlags() % 2
        --log(flags)
        --log(wx.wxFR_DOWN)
        
        if (flags == wx.wxFR_DOWN) then 
            return 1
        else
            return 0
        end 
    end

    -- wxFindReplaceDialog flags are different from wxStc FindText flags
    function get_stcflags(fr_flags)
        local stc_flags = 0
        
        if (hasbit(fr_flags, wx.wxFR_WHOLEWORD)) then
            stc_flags = stc_flags + wxstc.wxSTC_FIND_WHOLEWORD
        end
        if (hasbit(fr_flags, wx.wxFR_MATCHCASE)) then
            stc_flags = stc_flags + wxstc.wxSTC_FIND_MATCHCASE
        end    

        return stc_flags
    end

    function find_prev_token(text, token, flags)
        -- get the text length for range setting
        local n = text:GetLength()
        local stc_flags = get_stcflags(flags)

        -- check if rearch the start, do the search from the end
        if (latest_pos <= 1) then
            latest_pos = n
        end    

        -- do the first search from the last time postion
        local start_pos = text:FindText(latest_pos, 1, token, stc_flags)
        
        -- if can't find it, search from the end
        if (start_pos < 0) then        
            start_pos = text:FindText(n, 1, token, stc_flags)
        end

        -- make founded token visible 
        set_range_visible(text, start_pos, start_pos + token:len())
        
        -- store the latest position
        text:SetSelection(start_pos, start_pos + token:len()) 

        latest_pos = start_pos - 1
        return 0
    end

    function find_next_token(text, token, flags)
        -- get the text length for range setting
        local n = text:GetLength();    
        local stc_flags = get_stcflags(flags)    
       
        if (latest_pos > n) then
            latest_pos = 1
        end

        -- do the first search from the last time postion
        local start_pos = text:FindText(latest_pos, n, token, stc_flags)

        -- if can't find it, search from the start
        if (start_pos < 0 or start_pos >= n) then        
            start_pos = text:FindText(1, n, token, stc_flags)

            -- if still can't find it, skip the search
            if (start_pos < 0 or start_pos >= n) then        
                return -1
            end
        end    

        -- make founded token visible
        set_range_visible(text, start_pos, start_pos + token:len())
        
        -- highlight the selection
        text:SetSelection(start_pos, start_pos + token:len())
        
        -- store the latest position
        latest_pos = start_pos + token:len()

        return 0
    end

    local _last_find_flags_ = 0
    local _last_find_string_ = ""

    function self.OnReplaceAll(event)
        --log("OnReplaceAll "..event:GetFindString().."  with  "..event:GetReplaceString() )

        local doc = MyApp:get_current_doc()
        -- get the text length for range setting
        local n = doc:GetLength()
        local replace_str = event:GetReplaceString()
        _last_find_string_ = event:GetFindString()
        _last_find_flags_ = event:GetFlags()
                
        latest_pos = doc:GetSelectionStart()

        --log("len", n)
        local text = doc:GetText()

        local str, v = string.gsub(text, _last_find_string_, replace_str)        
        --log(v)
        if (v > 0) then
            doc:SetText(str)
        end
        
        local result = find_next_token(doc, replace_str, _last_find_flags_)
    end

    function self.OnFind(event)
        _last_find_flags_ = event:GetFlags()
        _last_find_string_ = event:GetFindString()

        --if (find_check_direction(event) == 1) then  
            --log("on find next "..event:GetFindString())
            find_next_token(MyApp:get_current_doc(), _last_find_string_, _last_find_flags_)
        --else
            --log("on find prev "..event:GetFindString())
        --    find_prev_token(MyApp:get_current_doc(), _last_find_string_, _last_find_flags_)
        --end
    end

    function self.OnUndo(event)
        local doc = MyApp:get_current_doc()
        if (doc and doc:CanUndo()) then
            doc:Undo()
        end    
    end

    function self.OnRedo(event)
        local doc = MyApp:get_current_doc()
        if (doc and doc:CanRedo()) then
            doc:Redo()
        end    
    end

    function self.OnCut(event)
        local doc = MyApp:get_current_doc()
        if (doc) then
            doc:Cut()
        end    
    end

    function self.OnCopy(event)
        local doc = MyApp:get_current_doc()
        if (doc) then
            doc:Copy()
        end    
    end

    function self.OnPaste(event)
        local doc = MyApp:get_current_doc()
        if (doc) then
            doc:Paste()
        end
    end

    function self.OnSelectAll(event)
        local doc = MyApp:get_current_doc()
        if (doc) then
            doc:SelectAll()
        end    
    end

    function self.OnFindNext(event) 
        if (last_find_string == "") then
            OnShowFind(event)
        else
            find_next_token(MyApp:get_current_doc(), _last_find_string_, _last_find_flags_)
        end
    end

    function self.OnReplace(event)
        --log("OnReplace  "..event:GetFindString().."  with  "..event:GetReplaceString() )
        local doc = MyApp:get_current_doc()

        -- do the replace text action
        doc:ReplaceSelection(event:GetReplaceString())
        
        -- auto jump to next match text
        _last_find_flags_ = event:GetFlags()
        _last_find_string_ = event:GetFindString()
        find_next_token(doc, _last_find_string_, _last_find_flags_)
    end

    function self.OnShowFind(event)
        -- get current doc
        local doc = MyApp:get_current_doc()

        -- create wxFindReplaceData for search
        local find_data = wx.wxFindReplaceData()

        -- initial the find string by selection
        local token = get_selected_text(doc)
        --log("find "..token)
        find_data:SetFindString(token)
       
        local find_dlg = wx.wxFindReplaceDialog(MyApp.m_frame, find_data, "Find")

        -- connect event handler
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND,      self.OnFind)
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND_NEXT, self.OnFind)

        -- initial the latest position for start position
        latest_pos = doc:GetSelectionStart()
        doc:SearchAnchor()
        find_dlg:Show()    
    end

    function self.OnShowReplace(event)
        --log("OnShowReplace")
        -- get current doc editor
        local doc = MyApp:get_current_doc()

        -- create wxFindReplaceData for replace
        local find_data = wx.wxFindReplaceData()

        -- initial the find string by selection
        local token = get_selected_text(doc)
        --log("replace "..token)
        find_data:SetFindString(token)

        -- create dialog
        local find_dlg = wx.wxFindReplaceDialog(MyApp.m_frame, find_data, "Replace", wx.wxFR_REPLACEDIALOG)
        
        -- connect event handler
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND,             self.OnFind)
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND_NEXT,        self.OnFind)
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND_REPLACE,     self.OnReplace)
        find_dlg:Connect(wx.wxEVT_COMMAND_FIND_REPLACE_ALL, self.OnReplaceAll)
        
        -- initial the latest position for start position
        latest_pos = doc:GetSelectionStart()
        
        find_dlg:Show()       
    end

    function self.OnPy2Lua(event)
        local doc = MyApp:get_current_doc()
        local s = doc:GetText()
        s = py2lua(s)    
        doc:SetText(s)
    end

    parent:Connect(ID_UNDO,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnUndo)
    parent:Connect(ID_REDO,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnRedo)    
    parent:Connect(ID_CUT,   wx.wxEVT_COMMAND_MENU_SELECTED, self.OnCut)
    parent:Connect(ID_COPY,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnCopy)
    parent:Connect(ID_PASTE, wx.wxEVT_COMMAND_MENU_SELECTED, self.OnPaste)
    
    parent:Connect(ID_SELECTALL, wx.wxEVT_COMMAND_MENU_SELECTED, self.OnSelectAll)
        
    parent:Connect(ID_FIND,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnShowFind)
    parent:Connect(ID_REPLACE, wx.wxEVT_COMMAND_MENU_SELECTED, self.OnShowReplace)
    parent:Connect(ID_FINDNEXT,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnFindNext)

    parent:Connect(ID_PY2LUA,  wx.wxEVT_COMMAND_MENU_SELECTED, self.OnPy2Lua)
    return self
end

function MyFileMenu(parent, menubar)
    local self = wx.wxMenu({
            { ID_NEW_PRJ,     "New Project",   "Create a project" },
            { ID_OPEN_PRJ,    "Open Project",  "Open an existing project" },
            { ID_CLOSE_PRJ,   "Close project", "Close the current project" },
            { },
            { ID_NEW,     "&New\tCtrl-N",        "Create an empty file" },
            { ID_OPEN,    "&Open...\tCtrl-O",    "Open an existing file" },
            { ID_CLOSE,   "&Close file\tCtrl+W", "Close the current file" },
            { },
            { ID_SAVE,    "&Save\tCtrl-S",       "Save the current document" },
            { ID_SAVEAS,  "Save &As...\tAlt-S",  "Save the current document to a file with a new name" },
            { ID_SAVEALL, "Save A&ll...\tCtrl-Shift-S", "Save all open documents" },
            { },
            { ID_EXIT,    "E&xit\tAlt-X",        "Exit Program" }})
            
    menubar:Append(self, "&File")  

    function self.OnOpenFile(event)
        local fileDialog = wx.wxFileDialog(MyApp.m_frame,
                                           "Open Lua file",
                                           "",
                                           "",
                                           "Lua files(*.lua)|*.lua|All files(*)|*",
                                           wx.wxFD_OPEN + wx.wxFILE_MUST_EXIST)
        local result = false
        if fileDialog:ShowModal() == wx.wxID_OK then
            local filename = fileDialog:GetPath()
            result = MyApp:open_file(filename)
            
            if result then
                MyApp.m_frame:SetTitle("My Lua IDE - " .. filename)           
            end
        end
        fileDialog:Destroy()
        return result
    end

    function self.OnSaveAsFile(event)    
        local doc = MyApp:get_current_doc()

        local fileDialog = wx.wxFileDialog(MyApp.m_frame,
                                           "Save as file",
                                           "",
                                           "",
                                           "Lua files(*.lua)|*.lua|All files(*)|*",
                                           wx.wxFD_SAVE)
        local result = false
        if fileDialog:ShowModal() == wx.wxID_OK then
            filepath = fileDialog:GetPath()
            result = doc:SaveFile(filepath)
            if result then
                MyApp:open_file(filepath)
                log(filepath.." saved.")            
            else
                log("fail to save "..filepath)
            end

        end
        fileDialog:Destroy()
      
        return result
    end

    function self.OnSaveFile(event)    
        local doc = MyApp:get_current_doc()
        local filename = doc.m_filepath    
        
        if (doc == nil) then
            log("no file to save...")
            return
        end
        
        if filename == nil or filename == "" then
            return OnSavefile(event)
        end
        
        --log("Save".."   index="..tostring(MyApp.m_doc_index))
        --log("Save "..filename)
        if (doc:GetModify() == false) then
            log(filename.." not modified.")
        elseif (doc:SaveFile(filename)) then
            log(filename.." saved.")
            doc.m_modified = false
            doc:get_func_list(MyApp.m_functree);
        else
            log("fail to save "..filename)
        end
    end 

    function self.OnSaveAllFile(event)
        log("Save all file")
        local n  = self.m_doc_count          
        --log("doc count "..tostring(n))
        
        for i = 1, n do
            local doc = self.m_docs[i]

            if (doc:GetModify() == false) then
                log(filename.." not modified.")
            elseif (doc:SaveFile(filename)) then
                doc.m_modified = false
                log(filename.." saved.")
            else
                log("fail to save "..filename)
            end
        end
    end

    function self.OnNewFile(event)
        log("new file")
        MyApp:new_file()
    end

    function self.OnExit(event)  
        --print("close check if doc :IsModified");

        MyApp.m_frame:Close()
    end

    parent:Connect(ID_NEW,    wx.wxEVT_COMMAND_MENU_SELECTED, self.OnNewFile);
    parent:Connect(ID_OPEN,   wx.wxEVT_COMMAND_MENU_SELECTED, self.OnOpenFile);
    parent:Connect(ID_SAVE,   wx.wxEVT_COMMAND_MENU_SELECTED, self.OnSaveFile);
    parent:Connect(ID_SAVEAS, wx.wxEVT_COMMAND_MENU_SELECTED, self.OnSaveAsFile);
    parent:Connect(ID_SAVEALL,wx.wxEVT_COMMAND_MENU_SELECTED, self.OnSaveAllFile);
    parent:Connect(ID_EXIT,   wx.wxEVT_COMMAND_MENU_SELECTED, self.OnExit);

    return self
end

function MyHelpMenu(parent, menubar)
    local help_menu = wx.wxMenu(); 
    help_menu:Append(wx.wxID_ABOUT, _("About..."));
    menubar:Append(help_menu, _("Help"));        
    
    function OnAbout(event)
        wx.wxMessageBox(_("wxLua IDE."), _("About wxIDE"), wx.wxOK, MyApp.m_frame);
    end

    parent:Connect(ID_ABOUT, wx.wxEVT_COMMAND_MENU_SELECTED, OnAbout);

    return help_menu
end
-- --------------------------------------------------------------------------------------------------

function MyPrj:create(parent, frame)

    
    local notebook = wxaui.wxAuiNotebook(frame, wx.wxID_ANY,
                                wx.wxPoint(0, 0), --wx.wxPoint(client_size.x, client_size.y),
                                wx.wxSize(400,400),
                                wxaui.wxAUI_NB_DEFAULT_STYLE + wxaui.wxAUI_NB_TAB_EXTERNAL_MOVE + wx.wxNO_BORDER 
                                - wxaui.wxAUI_NB_CLOSE_ON_ACTIVE_TAB);
    
    function add_search_box(panel, tree)
        local self = wx.wxComboBox(panel, wx.wxID_ANY, "",
                                             wx.wxDefaultPosition, wx.wxDefaultSize,
                                             {},
                                             wx.wxTE_PROCESS_ENTER) -- generates event when enter is pressed
     
        self.func_lst = {}
        self.full_func_lst = {}
        self.event_from_item_selected = false
        self.search_string = ""

        function self:set_items(lst)
            self:Clear()
            if (lst == nil or #lst == 0) then
                return
            end

            local lst1 = {}
            for i = 1, #lst do
                local t = lst[i]
                if (type(t) ~= "table") then
                    --self:Append(t)
                    table.insert(lst1, t)
                end
            end        
            table.sort(lst1)

            for i = 1, #lst1 do
                self:Append(lst1[i])
            end
        end
        
        function self:add_func_lst(lst)
            if (lst == nil or #lst == 0) then
                return
            end
            for i = 1, #lst do
                local t = lst[i]
                if (type(t) == "table") then
                    self:add_func_lst(t)
                else
                    table.insert(self.func_lst, t)
                end        
            end
        end

        function self:set_func_lst(lst)
            self:set_items(lst)
            self.full_func_lst = lst
            self.func_lst = {}
            self:add_func_lst(lst)
        end

        function self:update_search_text(s)
            local n = s:len()

            if (n == 0) then
                tree:set_list(self.full_func_lst)
                return
            end

            local lst = {}
            local n1 = 0
            for i = 1, #self.func_lst do
                local f = self.func_lst[i]
                local p0,p1 = f:find(s)
                if (p0 ~= nil and p0 == 1) then
                    --print(p0, p1, f)
                    table.insert(lst, f)
                    n1 = n1 + 1
                end
            end

            if (n > 1 or n1 == 0) then
                for i = 1, #self.func_lst do
                    local f = self.func_lst[i]
                    local p0,p1 = f:find(s)
                    if (p0 ~= nil and p0 > 1) then
                        --print(p0, p1, f)
                        table.insert(lst, f)
                    end
                end
            end
            tree:set_list(lst)     
        end

        function self.OnSelectItem(event)
            self.event_from_item_selected = true
            --print("OnSelectItem", event:GetString(), event:GetId(), event:GetEventType(), event:GetEventObject())
            if (self.search_string ~= "") then
                self:update_search_text("")
                self.search_string = ""
            end
            tree:select_item(event:GetString())
            
        end

        function self.OnKeyUpdate(event)
            if (self.event_from_item_selected == false) then
                -- print("OnKeyUpdate", event:GetString(), event:GetId(), event:GetEventType(), event:GetEventObject())
                self:update_search_text(event:GetString())
                self.search_string = event:GetString()
            end
            self.event_from_item_selected = false
        end

        function self:clear_text()
            self:SetValue("")

            --if (self.search_string ~= "") then            
                self:update_search_text("")
                self.search_string = ""
            --end
        end

        self:Connect(wx.wxEVT_COMMAND_COMBOBOX_SELECTED, self.OnSelectItem)
        self:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, self.OnKeyUpdate)

        return self
    end

    -- ---------------------------------------------------------------------------------------------
    function self:create_project_tree(parent)

        local prj_tree = wx.wxTreeCtrl(parent, wx.wxID_ANY,
                                          wx.wxDefaultPosition, wx.wxDefaultSize,
                                          wx.wxTR_DEFAULT_STYLE + wx.wxNO_BORDER);

        local imglist = wx.wxImageList(16, 16, true, 2);
        imglist:Add(get_bitmap(wx.wxART_FOLDER));
        imglist:Add(get_bitmap(wx.wxART_NORMAL_FILE));
        prj_tree:AssignImageList(imglist);

        local root = prj_tree:AddRoot(wxT("Project"), 0);
        local lst = {}
        --local items = wx.wxArrayTreeItemIds();

        prj_tree:Expand(root);

        function prj_tree:add_file(filepath)
            if (lst[filepath] == nil) then
                lst[filepath] = prj_tree:AppendItem(root, wxT(filepath), 1)
                prj_tree:Expand(root)                
            end            
        end

        function prj_tree.OnSelectFile( event )
            local item = event:GetItem() 
            local path = prj_tree:GetItemText(item)
            MyApp:open_file(path)
        end 

        prj_tree:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED, prj_tree.OnSelectFile)

        return prj_tree;
    end
    -- ---------------------------------------------------------------------------------------------
    function self:create_dir_tree(parent)
        local dir_tree = wx.wxGenericDirCtrl(parent,  wx.wxID_ANY, wx.wxDirDialogDefaultFolderStr,
                            wx.wxDefaultPosition, wx.wxDefaultSize)
        dir_tree:SetPath("C:\\work\\test_wxlua\\")

        function dir_tree.OnSelectFile( event )
            local path = dir_tree:GetPath()
            
            if (isfile(path)) then
                MyApp:open_file(path)
                --self:add_file(path)
            else
                dir_tree:ExpandPath(path)
            end
        end 

        dir_tree:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED, dir_tree.OnSelectFile)
        return dir_tree
    end
    -- ---------------------------------------------------------------------------------------------
    function self:create_function_tree(parent, notebook)
        local frame = notebook        
        local panel = wx.wxPanel(frame, wx.wxID_ANY)

        local sizer = wx.wxFlexGridSizer(2, 0, 0, 0)
        sizer:AddGrowableCol(0)
        sizer:AddGrowableRow(1)

        -- create our treectrl
        local func_tree = wx.wxTreeCtrl(panel, wx.wxID_ANY,
                                  wx.wxDefaultPosition, wx.wxDefaultSize,
                                  wx.wxTR_LINES_AT_ROOT + wx.wxTR_HAS_BUTTONS )
        local tree = func_tree
        local search_box = add_search_box(panel, func_tree)
        func_tree.m_search_box = search_box
        --local box_caption = wx.wxStaticBox( panel, wx.wxID_ANY, "Search function")
        --local sizer1 = wx.wxStaticBoxSizer( box_caption, wx.wxVERTICAL );
        local sizer2 = wx.wxFlexGridSizer(0, 2, 0, 0)
        sizer2:AddGrowableCol(1)
        sizer2:AddGrowableRow(0)

        local ID_CLEAR_BUTTON = wx.wxNewId()
        local b1 = wx.wxButton(panel, ID_CLEAR_BUTTON, "<", wx.wxDefaultPosition, wx.wxSize(28, 28))
         
        sizer2:Add(b1, 0, wx.wxALIGN_CENTER_VERTICAL+wx.wxALL, 0)
        sizer2:Add(search_box, 0, wx.wxGROW+wx.wxALIGN_LEFT+wx.wxALL, 1)

        --sizer1:Add(sizer2, 0, wx.wxALL + wx.wxGROW + wx.wxCENTER, 5)       

        sizer:Add( sizer2, 0, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL, 0 )
        sizer:Add( func_tree, 0, wx.wxGROW+wx.wxALIGN_CENTER_VERTICAL, 0 ) 
        
        panel:SetSizer(sizer)
        sizer:SetSizeHints(panel)
        panel:Layout() -- help sizing the windows before being shown
        notebook:AddPage( panel, wxT("Function"), false, get_bitmap(wx.wxART_LIST_VIEW) );

        function func_tree:add_list(root, lst, depth)
            for i = 1, #lst do
                local t = lst[i]
                if (type(t) == "table") then
                    local node = func_tree:GetLastChild(root)
                    func_tree:add_list(node, t, depth+1)
                else
                    func_tree:AppendItem(root, tostring(t), 4)
                end        
            end
        end

        function func_tree:set_list(lst)
            -- remove all items
            func_tree:DeleteAllItems()
            
            -- add root
            local root_id = func_tree:AddRoot( "Root", 2, -1 )
            func_tree:add_list(root_id, lst, 0)

            func_tree:Expand(root_id)             
        end

        function func_tree.OnSelectFunction(event)
            local doc = MyApp:get_current_doc()
            local item_id = event:GetItem()
            local str = func_tree:GetItemText(item_id).."\n"
            --log(str)             
            --print(doc, doc.m_filename)
            doc.m_doc_t:find_func_pos(doc, str)
        end      
 
        function func_tree:get_root_child()
            local tree = func_tree
            local lst = {}
            local root = tree:GetRootItem()
            -- GetChildrenCount, GetFirstChild, GetNextChild

            local child_id, cookie = tree:GetFirstChild(root)
            while (child_id:IsOk()) do            
                text = tree:GetItemText(child_id)            
                --print(tree:GetItemText(child_id))
                table.insert(lst, text)
                child_id, cookie = tree:GetNextChild(child_id, cookie)
            end

            table.sort(lst)
            return lst
        end

        function func_tree:select_item(s)
            local tree = func_tree
            local root = tree:GetRootItem()

            local child_id, cookie = tree:GetFirstChild(root)
            while (child_id:IsOk()) do            
                if (s == tree:GetItemText(child_id)) then
                    tree:SelectItem(child_id, true)
                    tree:Expand(child_id)
                    --tree:ScrollTo(child_id)
                    return child_id
                end
                child_id, cookie = tree:GetNextChild(child_id, cookie)
            end

            return nil
        end

        func_tree:Connect(wx.wxEVT_COMMAND_TREE_ITEM_ACTIVATED, func_tree.OnSelectFunction)
        frame:Connect(ID_CLEAR_BUTTON, wx.wxEVT_COMMAND_BUTTON_CLICKED,
            function (event) search_box:clear_text() end )
    
        return func_tree
    end
    -- ---------------------------------------------------------------------------------------------

    local prj, dir, func

    dir = self:create_dir_tree(frame)
    prj = self:create_project_tree(frame)

    notebook:AddPage( dir, wxT("Dir"), false, get_bitmap(wx.wxART_FOLDER) );    
    notebook:AddPage( prj, wxT("Project"), false, get_bitmap(wx.wxART_FILE_OPEN) );

    func = self:create_function_tree(frame, notebook)

    MyApp.m_dirtree = dir
    MyApp.m_projtree = prj
    MyApp.m_functree = func



    function self:add_file(filepath)
        prj:add_file(filepath)
    end

    function self:set_func_lst(lst)
        func:set_list(lst)
        func.m_search_box:set_func_lst(lst)
    end

    return notebook;
end
-- --------------------------------------------------------------------------------------------------

function MyToolBar(parent, aui_mgr)    
    local self = {}
    local function add_tools(parent, name, lst)
        local tb = wx.wxToolBar(parent, wx.wxID_ANY, wx.wxDefaultPosition, wx.wxDefaultSize, wx.wxTB_FLAT + wx.wxTB_NODIVIDER)
        tb:SetToolBitmapSize(wx.wxSize(16,16));
        tb.control = {}

        for i = 1, #lst do
            local t = lst[i]
            if #t == 0 then
                tb:AddSeparator()
            elseif t[1] == "ComboBox" then
                tb:AddControl(wx.wxStaticText(tb, wx.wxID_ANY, t[3]))
                local cb = wx.wxComboBox(tb, t[2], t[3], t[4], t[5], t[6], t[7] )
                tb:AddControl(cb)
                table.insert(tb.control, cb)
            else
                tb:AddTool(t[1], t[2], get_bitmap(t[3]), t[4])
            end
        end

        tb:Realize();
        -- add the toolbars to the manager
        aui_mgr:AddPane(tb, wxaui.wxAuiPaneInfo():
                      Name(wxT(name)):
                      ToolbarPane():Top():
                      LeftDockable(false):RightDockable(false));
        return tb
    end

    local tb1_lst = {
        {ID_NEW,     "New",      wx.wxART_NORMAL_FILE, "Create an empty document"},
        {ID_OPEN,    "Open",     wx.wxART_FILE_OPEN,   "Open an existing document"},
        {ID_SAVE,    "Save",     wx.wxART_FILE_SAVE,   "Save the current document"},
        {ID_SAVEALL, "Save All", wx.wxART_NEW_DIR,     "Save all documents"},
        {},
        {ID_CUT,     "Cut",      wx.wxART_CUT,         "Cut the selection"},
        {ID_COPY,    "Copy",     wx.wxART_COPY,        "Copy the selection"},
        {ID_PASTE,   "Paste",    wx.wxART_PASTE,       "Paste text from the clipboard"},
        {},
        {ID_UNDO,    "Undo",     wx.wxART_UNDO,        "Undo last edit"},
        {ID_REDO,    "Redo",     wx.wxART_REDO,        "Redo last undo"},
        {},
        {ID_FIND,    "Find",     wx.wxART_FIND,        "Find string"},
        {ID_REPLACE, "Replace",  wx.wxART_FIND_AND_REPLACE, "Find and replace string"},
    }
    add_tools(parent, "Edit toolbar", tb1_lst)

    local tb2_lst = {
        {ID_RUN,           "Run",        "images/run1.png",       "Build and Run"},
        {},
        {ID_DBG_START,     "Debug",      "images/dbgrun.png",     "Start Debug"},
        {ID_DBG_STEP,      "Step",       "images/dbgstep.png",    "Next Step"},
        {ID_DBG_STEP_OVER, "Step Over",  "images/dbgnext.png",    "Step over function"},
        {ID_DBG_STEP_OUT,  "Step Out",   "images/dbgstepout.png", "Step out current function"},
        {ID_DBG_STOP,      "Stop Debug", "images/dbgstop.png",    "Stop debugger"},
    }

    add_tools(parent, "debug toolbar", tb2_lst)

    local tb3_lst = {
        {"ComboBox", wx.wxID_ANY, " Goto Line ", wx.wxPoint(0, 0), wx.wxSize(100, 16), {"100", "500", "1000", "1500", "2000", "2500", "3000"}, 0},
    }
    
    local tb3 = add_tools(parent, "", tb3_lst)
    local goto_combo = tb3.control[1]

    function goto_combo.OnSelectItem(event)
        --print("OnSelectItem", event:GetString(), event:GetId(), event:GetEventType(), event:GetEventObject())
     
    end

    function goto_combo.OnKeyUpdate(event)
        --print("OnKeyUpdate", event:GetString(), event:GetId(), event:GetEventType(), event:GetEventObject())
        local s = event:GetString()
        if (s == nil or s == "" or s:len() == 0) then
            return
        end
        
        local line = tonumber(s) - 1 
        local doc = MyApp:get_current_doc()
        doc:EnsureVisibleEnforcePolicy(line)
        doc:GotoLine(line)
        local p1 = doc:PositionFromLine(line)
        local p2 = doc:GetLineEndPosition(line)
        doc:SetSelection(p1, p2)
    end

    function self:OnDocPageChange(doc)
        local n = doc:GetLineCount()              
        
        goto_combo:Clear()
        if (n > 2000) then
            div = 200
        elseif (n > 1000) then
            div = 100
        else
            div = 50
        end
        local i = 0

        while i < n do    
            goto_combo:Append(tostring(i))
            i = i + div
        end
        goto_combo:Append(tostring(n))
        goto_combo:SetValue(tostring(n))
    end
    goto_combo:Connect(wx.wxEVT_COMMAND_COMBOBOX_SELECTED, goto_combo.OnSelectItem)
    goto_combo:Connect(wx.wxEVT_COMMAND_TEXT_UPDATED, goto_combo.OnKeyUpdate)

    return self 
end
-- --------------------------------------------------------------------------------------------------

function MyFrame(parent)

    -- create the frame window
    local self = wx.wxFrame(wx.NULL,
                        wx.wxID_ANY,
                        wxT("My Lua IDE - Athena"),
                        wx.wxPoint(200, 0),
                        wx.wxSize(1600, 1024));
    
    self.deact_time = wx.wxDateTime:Now()
    self:SetMinSize(wx.wxSize(1024, 768));

    -- create menu
    local menubar = wx.wxMenuBar()

    MyFileMenu(self, menubar)
    MyEditMenu(self, menubar)
    MyApp.m_dbg = MyDbg:create(self, menubar)
    MyHelpMenu(self, menubar)

    self:SetMenuBar(menubar)

    --self:CreateStatusBar(1)
    --self:SetStatusText("Welcome to wxLua.")    

    function self.OnActivate(event)
        --if not event:GetActive() and ide.config.editor.saveonappswitch then SaveAll() end
        if (event:GetActive()) then
            now = wx.wxDateTime:Now()
            --self:SetStatusText("acivate "..get_date_string(now))

            if (MyApp.m_doc_nb) then
                MyApp.m_doc_nb:check_docs_modified(self.deact_time)
            end            
        else
            self.deact_time = wx.wxDateTime:Now()
            --self:SetStatusText("deactivate "..get_date_string(self.deact_time))
        end
        event:Skip()
    end

    function self.OnClose(event)
        MyApp:save_config()
        MyApp:save_on_exit(event)
        -- ensure the event is skipped to allow the frame to close
        event:Skip()
    end

    self:Connect(wx.wxEVT_CLOSE_WINDOW, self.OnClose)   
    self:Connect(wx.wxEVT_ACTIVATE, self.OnActivate)

    return self
end
-- --------------------------------------------------------------------------------------------------
function MyApp:create(parent, id, title, pos, size, style)
    
    local frame = MyFrame(wx.NULL)
    local self = MyApp
    local app = self
    self.m_frame = frame   

    -- tell wxAuiManager to manage this frame
    self.m_mgr = wxaui.wxAuiManager()
    self.m_mgr:SetManagedWindow(frame);
    
    local toolbar = MyToolBar(frame, self.m_mgr)   
        
    -- add a bunch of panes
                  
    self.m_doc_nb = MyDocNB:create(self, frame);
    self.m_prj_nb = MyPrj:create(self, frame);
   
    self.m_mgr:AddPane(self.m_doc_nb, wxaui.wxAuiPaneInfo():Name(wxT("main_panel")):
                  CenterPane():PaneBorder(false));                  

    self.m_mgr:AddPane(MyLogNB:create(self, frame), wxaui.wxAuiPaneInfo():Name(wxT("bottom_panel")):
                  CenterPane():PaneBorder(false):CloseButton(false):Show());

    self.m_mgr:AddPane(self.m_prj_nb, wxaui.wxAuiPaneInfo():Name(wxT("left_panel")):
                  PaneBorder(false):CloseButton(false):Show());  

    self.m_mgr:AddPane(MyDebugNB:create(self, frame), wxaui.wxAuiPaneInfo():Name(wxT("debug_panel")):
                  CenterPane():PaneBorder(false):CloseButton(false):Show());
      
    -- make some default perspectives
    local perspective_all = self.m_mgr:SavePerspective();

    local i, count;
    local all_panes = self.m_mgr:GetAllPanes();
    count = all_panes:GetCount()
    for i = 0, count-1 do
        if ( all_panes:Item(i):IsToolbar() == false) then
            all_panes:Item(i):Hide();
        end
    end

    self.m_mgr:GetPane(wxT("left_panel")):Show():Left():Layer(0):Row(0):Position(0);
    self.m_mgr:GetPane(wxT("debug_panel")):Show():Bottom():Layer(0):Row(0):Position(1);
    self.m_mgr:GetPane(wxT("bottom_panel")):Show():Row(0):Layer(0):Position(1):Bottom();
    self.m_mgr:GetPane(wxT("main_panel")):Show();

    local perspective_default = self.m_mgr:SavePerspective();

    self.m_perspectives = wx.wxArrayString()
    self.m_perspectives:Add(perspective_default);
    self.m_perspectives:Add(perspective_all);

    -- "commit" all changes made to wxAuiManager
    self.m_mgr:Update();       
    
    -- show the frame window
    frame:Show(true)      

    --self.m_dbg = MyDbg(self, self.m_frame)
  
    function app:open_file(filepath)     
        return self.m_doc_nb:open_file(filepath)
    end

    function app:new_file()     
        return self.m_doc_nb:new_file()
    end

    function app:get_current_doc()  
        return self.m_doc_nb:get_current_doc()
    end

    function app:remove_doc(doc)
        self.m_doc_nb:remove_doc()    
    end

    function app:save_on_close_file(event)    
        return self.m_doc_nb:save_on_close_file(event) 
    end

    function app:save_on_exit(event)    
        return self.m_doc_nb:save_on_exit(event)
    end

    function app:set_last_file(filename)
        self.m_config:Write("LastFile", filename)
    end
    
    function app:save_config()
        --log("create config - MyLuaIde.cfg")
        local config = wx.wxFileConfig("", "", "MyLuaIde.cfg", "", wx.wxCONFIG_USE_LOCAL_FILE);
        
        local n  = 0              

        for path, doc in pairs(self.m_doc_nb.m_docs) do 
            n = n + 1
            config:Write("LastFile"..n, path)        
        end  

        config:Write("LastFileCount", n) 
        config:delete()  
    end  

    function app:load_config()
        --log("create config - MyLuaIde.cfg")
        local config = wx.wxFileConfig("", "", "MyLuaIde.cfg", "", wx.wxCONFIG_USE_LOCAL_FILE);

        if (config:Exists("LastFileCount")) then
            --log("config exists")
            local ok, lastfilecount = config:Read("LastFileCount")
            if (ok) then
                local n = tonumber(lastfilecount)
                for i = 1, n do
                    local ok, filename = config:Read("LastFile"..i)
                    --log("Get LastFile "..tostring(ok).." = "..filename)
                    if (ok and filename and filename ~= "") then
                        self:open_file(filename)
                    end
                end
            end
        end
        config:delete() 
    end    

    function app:OnDocPageChange(event)        
        toolbar:OnDocPageChange(self.m_doc_nb:get_current_doc())
    end

    self:load_config() 

    return self
end
-- --------------------------------------------------------------------------------------------------
function main()
    local app = MyApp:create()

    if (app ~= nil) then
        wx.wxGetApp():MainLoop()
        return true
    else
        return false
    end
end
-- --------------------------------------------------------------------------------------------------
main()
