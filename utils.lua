--file which contains util and helper functions for kindle clipping program.
local M  = {}
local io = io
_ENV     = M


--remove leading and trailling whitespace
function trimString(str)
    str = str:gsub("^%s*","")
    return str:gsub("%s*$","")
end


--remove all control chars from a string.
function removeControlChar(word)
    return word:gsub("%c","")
end

--clean up results gotten via the API.
function sanitizeResults(def)
    local word = def:gsub("{[^}]-}","")
    word       = word:gsub("%s-%-%s-,-[\n\r]+]","")
    return trimString(word)
end

--if word is UTF then we need to clean it up a bit.
local function sanitizeUTF(word)
    local new_word,i = word:gsub("\xE2\x80\x98","")
    new_word,j       = new_word:gsub("\xE2\x80\x9D","")
    new_word,k       = new_word:gsub("\xE2\x80\x9C","")
    return new_word
end


--clean up a word some before attempting to use it further.
function sanitizeWord(word)
    local new_word = word:gsub("[\32-\44\46-\47\58-\64\91-\96\123-\126]*","")
    --if word is UTF.
    if new_word:find("\xE2\x80[\x98\x9D\x9C]*") then
        new_word = sanitizeUTF(new_word)    
    end
    return new_word
end

--open a file to read it.
--if successful then return entire contents as a string.
function readFile(file)
    local f        = io.open(file,"r")
    local contents = nil
    if f then
        contents = f:read("*a")
        f:close()
    end
    return contents
end

--count the number of spaces in a word/sentence.
function countSpaces(match)
    local i = 0
    if match then
        for _ in match:gmatch("%s") do
            i = i + 1
        end
    end
    return i
end

return M

