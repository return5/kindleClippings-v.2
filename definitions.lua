--File which contains methods to look up defintions of words.
local M = {}


local utils = require('utils')
local io    = io
local tbl_tostr = table.concat
_ENV  = M


--api key goes inside of this variable. please make sure to set it before attempting to run program if oyu wish to look up defintiions.
local key = "key=faecc96a-2407-4ea2-b4bc-7012ef84ee10 "
--the first part of the url which each api call uses.
local uri = "https://dictionaryapi.com/api/v3/references/collegiate/json/"
--
--the command to use curl.
local curl = 'curl --parallel --parallel-max 10 -H "Accept: application/json"  --config urls.txt'

--table which will hold al lthe urls which curl will use to call the API with.
local url_complete = {}

--open up curl and search for word definitions.
function searchWords()
    if #url_complete > 0 then
        local pipe    = io.popen(curl)
        local results = pipe:read('*all')
        pipe:close() 
        if not results:match("Key is required%.") then
            return results
        end
        --if user has no API key or it is incorrect.
        io.stderr:write("\n============================\n")
        io.stderr:write("Either you have no API key or you entered it incorrectly.\n")
        io.stderr:write("After checking you API key you may need to delete both 'defs.txt' and 'existing_defs.txt' before trying again.\n")
        io.stderr:write("============================\n")
    end
    return nil
end

--make a table consitsting of words and the url to look them up with curl.
--will later concat the table into a string.
--cuts down on the number of string concat operations doing it this way.
local function addWordToComplete(word)
    url_complete[#url_complete + 1] = "url = "
    url_complete[#url_complete + 1] = uri
    url_complete[#url_complete + 1] = word
    url_complete[#url_complete + 1] = "?"
    url_complete[#url_complete + 1] = key
    url_complete[#url_complete + 1] = "\n"
end


--save word to table so that we dont write the same word multiple times in definition file.
--if word doesnt exist then add it to the existing_def file and also the ecistiing_defs table.
--finall for each new word add it and the correct url to url_complete table.
function saveDef(word,existing_defs,file)
    local new_word = utils.trimString(utils.sanitizeWord(word)):lower():gsub("%p$","")
    if new_word:len() > 1 and not existing_defs[new_word] then
        existing_defs[new_word] = true
        file:write(new_word,"\n")
        addWordToComplete(new_word)
    end
end

--extract the word from the results from curl.
local function getWord(match)
    if match then
        return match:match("\"meta\":%s*{%c*\"id\"%s*:%s*\"(.-)\","):gsub("(.-)(:.-)$","%1"):gsub("%c","")
    end
    return nil
end

--write the definitions of the word to file
local function writeDefs(defs,match)
    for def in match:gmatch("\"dt\"%s*:%s*%[%s*%c*%[\"text\"%s*,%s*\"{[^}]-}([^{]-.-[^}]-)\"%]") do
        --we use a second pattern to match the definitons specifically.
        --doing all of this in a single lua pattern was a bit much for me. works better this way for me. 
        if def:match("^[^{].-") then
            def = def:gsub("{._link|([^|]+)[^}]*}","%1"):gsub("{bc}([^{]+)","\n\t - %1"):gsub("{bc}({sx.+})","%1"):gsub("{sx|([^|]*)||.-}.?%s*","\n\t - %1")
            defs:write("\t - ",def,"\n")
        end
    end
end

--match each word which was looked up via the API in the returned JSON object. 
--returns the total length of all matches. this is used to extract the last word.
--this is a workaround to make up for me not being able to find a single lua pattern which would correctly match every word.
local function matchWords(results,defs)
    local len = 0
    for match in results:gmatch("\"meta\":.-}%]%[[%[{]-") do
        len = len  + match:len()
        local word = utils.trimString(getWord(match))
        if word then
            defs:write(word,"\n")
            writeDefs(defs,match)
            defs:write("===========\n\n")
        end
    end
    return len
end

--writes each word and its defintions to the def file. 
function writeResults(results,defs)
    local len = matchWords(results,defs)
    --write the last word to file. see comments for 'matchWords'
    matchWords(getWord(results:sub(len)))
end


--write urls to url file for use by curl
function writeUrls()
    if url_complete and #url_complete > 0 then
        local file = io.open("urls.txt","w")
        file:write(tbl_tostr(url_complete))
        file:close()
    end
end

--read through definition file and populate map with defitions we already have.
local function populateExistingDefs(contents)
    local existing_defs = {}
    if contents  then
        for word in contents:gmatch("(.-)[\n\r]+") do
            existing_defs[word] = true
        end
    end
    return existing_defs
end

--open definitions file and return table of words already in the file.
--if no API key provided then return nil
function getDefs()
    if key and key:len() > 1 then
        local contents = utils.readFile("./clippings/existing_defs.txt")
        return populateExistingDefs(contents)
    end
    return nil
end

return M


