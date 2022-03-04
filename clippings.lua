--program to parse a kindle clipping file into seperate and dissting files based on the book the individual clippings comes from.
--scans through the clipping file and appends each clipping ot a text file for the book which the clipping is from.
--when a clipping is an individual word it is treated as a word to look up the definition of. each of these is placed in the file 'defs.txt'
--to look up a definitoon the program needs a valid api key from https://www.dictionaryapi.com/.
--API key should be placed in the 'definitions.lua' module file. please look there for the correct location.
--Licnesed under GPL 3.0
--source can be found on https://github.com/return5/kindleclippingsv1
--[[ 
        license: GPL 3.0.  written by: github/return5
    
        Copyright (C) <2021>  <return5>
    
        This program is free software: you can redistribute it and/or modify
        it under the terms of the GNU General Public License as published by
        the Free Software Foundation, either version 3 of the License, or
        (at your option) any later version.
    
        This program is distributed in the hope that it will be useful,
        but WITHOUT ANY WARRANTY; without even the implied warranty of
        MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
        GNU General Public License for more details.
    
        You should have received a copy of the GNU General Public License
        along with this program.  If not, see <https://www.gnu.org/licenses/>.

--]]

--module to handle lookign up defintiions
local def_mod = require('definitions')
--
--module to contain a few helper and utility functions.
local utils   = require('utils')


--find and return the listed location of the clipping in the original book.
local function getLocation(loc)
    local word = loc:match("%s*(Highlight)") or loc:match("%s*(Bookmark)")
    return loc:match(word.."%s+.-(Loc%.%s*%d*)")
end

--write the clipping to the correct file. 
--if it is an individual word then save it to be looked up later.
local function writeToFile(match,loc,file,defs,files,existing_defs)
    if file and file == "defs" then
        def_mod.saveDef(match,defs,existing_defs) 
    elseif file and file ~= "defs" then
        loc = getLocation(loc)
        file:write(match .. "\n\t" .. loc)
        file:write("\n==============\n\n")
    end
end

--get the title of the book which the clipping comes from.
local function getTitle(title,match)
    if utils.countSpaces(match) > 0 then
        return utils.trimString(utils.removeControlChar(title))
    end
    return "defs"
end

--return the correct file to write the clipping to.
local function getFile(title,files)
    --words to look up are handled diffrently so we should ignore those with this function.
    if title ~= "defs" then
        --if file already exists then simply return it.
        if files[title]  then
            return files[title]
        end
        --if file hasnt been created yet then do so.
        files[title] = io.open("./clippings/" .. title .. ".txt","w")
        return files[title]
    end
    return "defs"
end

--goes through the file with the clippings an dpick out each clipping individually.
local function matchClippings(clippings,defs)
    --table to hold all the diffrent files which will hold the clippings.
    local files = {}

    --file which contains the list of definitions already looked up in previous runs of the program.
    local existing_defs = io.open("./clippings/existing_defs.txt","a")

    --look for the clipping, the location data, and the title data inside the clippings file.
    for title,loc,clip in clippings:gmatch("([^\r\n]+)[\r\n]+%- ([^\r\n]+)[\r\n]+([^=]+)[\r\n]+=-") do
        clip       = utils.trimString(clip)
        --extract just the title info from the line. since we are using lua paterns the easiest thing to do is handle this process in two steps.
        title      = getTitle(title,clip)
        --get the file which this clipping should go into.
        local file = getFile(title,files) 
        --write this clipping to the correct file.
        writeToFile(clip,loc,file,defs,files,existing_defs)
    end 
end


local function main()
    --make sure there is a directory called 'clippings' if not then create it.
    os.execute("mkdir -p clippings")

    --list of all previously looked up definitions.
    local defs        = def_mod.getDefs()
    --entire clipping file in one long string.
    local clippings   = utils.readFile("clippings.txt")
    --match and write clipppings to files. also handles saving words to look up for later.
    matchClippings(clippings,defs)

    --create then write the urls needed by curl to call the api. 
    def_mod.writeUrls()
    
    --call the dictionary api with curl for each new word to look up.
    local results = def_mod.searchWords()

    if results then

        --open file to write definitions to.
        local defs_file = io.open("./clippings/defs.txt","a")

        --look up each word and write the defintiion to the def file.
        def_mod.writeResults(results,defs_file)

        --close that file now that all urls have been written/
        defs_file:close()
    end

    --remove that file off the system since it isnt needed anymore.
    os.execute("rm -f ./urls.txt")
end


main()


