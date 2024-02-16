local component = require("component")
local potionLib = require("potionLib")

local potions = {}

function main()
    
    local brewSide = potionLib.findInventorySideByName(potionLib.invTransposer, "brewing_stand")  -- Replace with a function to get the side of the brewing stand
    local inputSide = potionLib.findInventorySideByName(potionLib.invTransposer,"te")  -- Replace with a function to get the side of the input container
    local outputSide = potionLib.findInventorySideByName(potionLib.invTransposer,"wooden_device0")  -- Replace with a function to get the side of the output container
    
    potionLib.mainBrewing(brewSide,inputSide,outputSide)

end

main()