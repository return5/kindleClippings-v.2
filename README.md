##Introduction  
This program takes a single kindle clipping file and splits it into multiple files based upon the books which have been clipped from.  
Will also take individual words which have been clipped and looks up the definitions of them.  
Definitions will be saved into a filed called 'defs.txt'

###USAGE  
####Requires  
- [Lua](https://lua.org)
- [Curl](htps:curl.se)
- API Key from [Meriam-Webster API](https://www.dictionaryapi.com/) 
- UNIX like OS (Will probably work with something like Cygwin or git bash on Windows, but I haven't tested it.)  
  
####Running  
- place your kindle clipping file inside same directory as all the Lua files. (Make sure it is named 'clippings.txt')
- Add your API key inside 'definitions.lua'. there is a variable named 'key' which you need to set to your API key.
- Run the command:  
  `lua clippings.lua`  
  

