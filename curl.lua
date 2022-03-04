local json  = require('json')

local uri = 'curl --parallel --parallel-max 3 -H "Accept: application/json"  --config urls.txt'


local function searchWord()
    local pipe    = io.popen(uri .. " >> luresults.txt")
    local results = json.decode(pipe:read('*all'))
    pipe:close()
    return results
end


local results = searchWord()

