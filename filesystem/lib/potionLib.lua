local component = require("component")
local brewStand = component.brewing_stand
local sides = require("sides")
local fileName = "/data/recipes.txt"

local potionLib = {}

-- !!!IMPORTANT!!! set the side of ingredient container for the transposer
local ingredientChestSide = 5 

-- Initializing the potions table
potionLib.potions = {}

-- Initializing the transposer proxies
potionLib.invTransposer = nil
potionLib.brewTransposer = nil

-- Function to figure out transposers. There has to be two in the network. The one which has brewing stand
-- at the bottom is the brewing the other is inventory control
function potionLib.initTransposers()
    local inventoryName = "minecraft:brewing_stand"

    for address, name in component.list("transposer", false) do
        invString = component.proxy(address).getInventoryName(0)
        if invString and string.match(inventoryName, invString) then
            potionLib.brewTransposer = component.proxy(address)
        else
            potionLib.invTransposer = component.proxy(address)
        end
    end
end

-- Function to ask the user which potion they want to brew
function potionLib.selectPotion()
    -- Display available potions
    print("Which potion would you like to brew?")
    for i, potion in ipairs(potionLib.potions) do
        print(string.format("[%d] - %s", i, potion.name))
    end

    -- Get user input for potion selection
    local choice
    repeat
        print("Enter the number of the potion you want to brew:")
        choice = tonumber(io.read())
    until choice and choice >= 1 and choice <= #potionLib.potions

    return choice
end

-- Function to ask the user which potion they want to start from
function potionLib.selectStarterPotion()
    -- Display available potions
    print("Which potion would you like to start with? (Optional: pick one if you have a pre-made starter potion)")
    print("[0] - None (Start from scratch)")
    for i, potion in ipairs(potionLib.potions) do
        print(string.format("[%d] - %s", i, potion.name))
    end

    -- Get user input for starter potion selection
    local choice
    repeat
        print("Enter the number of the potion you want to start with (or 0 to start from scratch):")
        choice = tonumber(io.read())
    until choice and choice >= 0 and choice <= #potionLib.potions

    if choice == 0 then
        return nil
    else
        return potionLib.potions[choice].name
    end
end

-- Function to ask the user how many brewing steps they want
function potionLib.selectQuantity()
    print("How many times would you like to brew it?")
    local quantity = tonumber(io.read())
    return quantity
end

-- Function to find inventory side by component name:
function potionLib.findInventorySideByName(proxyName,name)
    -- Iterate over integer values of the sides table
    for _, side in ipairs({sides.top, sides.bottom, sides.north, sides.south, sides.east, sides.west}) do
        local inventoryName = proxyName.getInventoryName(side)
        -- print(inventoryName)
        if inventoryName and string.match(inventoryName, name) then
            return side
        end
    end
    return nil  -- Return nil if not found
end

-- Function to iteratively find the brewing sequence:
function potionLib.resolveDependencies(potionName, sequence, startingPotion)
    sequence = sequence or {} -- if sequence is not provided, initialize it
    local recipe = potionLib.getRecipe(potionName)

    -- If the current potion is the one we're starting with, stop and return
    if potionName == startingPotion then
        table.insert(sequence, potionName)
        return sequence
    end
    
    -- Check if the ingredient is another potion that can be brewed
    local starterPotion = potionLib.getRecipe(recipe.starter)
    if starterPotion then
        potionLib.resolveDependencies(starterPotion.name, sequence, startingPotion)
    end
    
    table.insert(sequence, potionName)
    return sequence
end

-- Function to determine the size of an inventory on a given side:
function potionLib.getInventorySize(proxyName,side)
    return proxyName.getInventorySize(side) or 0
end

-- Function to search for specific items in the inventory and tell the quantity of the item
function potionLib.findNumberOfItemsInInventory(proxyName,itemLabel, side)
    local totalQuantity = 0
    local inventory = proxyName.getInventorySize(side) -- Get the size of the chest inventory

    if inventory then
        local itemStacks = proxyName.getAllStacks(side) -- Get all stacks in the chest
        for slotNum, stack in ipairs(itemStacks) do
            if stack and stack.label == itemLabel then
                -- print("Found Stack by the name: ",stack.label)
                --print("entered, slot number:")
                totalQuantity = totalQuantity + stack.size -- Get the count of items in the slot
            end
        end
    end
    --print("Ready to output number of items", totalQuantity)
    return totalQuantity -- Return 0 if no items were found
end

-- Function to search for specific items in the inventory and tell the quantity of the item
function potionLib.findNumberOfPotionsInInventory(proxyName,itemLabel,alkimiaLvl,side)
    local totalQuantity = 0
    local inventory = proxyName.getInventorySize(side) -- Get the size of the chest inventory

    if inventory then
        local itemStacks = proxyName.getAllStacks(side) -- Get all stacks in the chest
        for slotNum, stack in ipairs(itemStacks) do
            if stack and stack.label == itemLabel and stack.aspects.Alkimia == alkimiaLvl then
                    -- print("Found Stack by the name: ",stack.label)
                    --print("entered, slot number:")
                    totalQuantity = totalQuantity + stack.size -- Get the count of items in the slot
            end
        end
    end
    --print("Ready to output number of items", totalQuantity)
    return totalQuantity -- Return 0 if no items were found
end

-- Function to find first slot with the item of interest in the inventory
function potionLib.findFirstSlotWithItemInInventory(proxyName,itemLabel, side)
    local firstSlot = nil
    local inventory = proxyName.getInventorySize(side) -- Get the size of the chest inventory

    --print(itemLabel)

    if inventory then
        local itemStacks = proxyName.getAllStacks(side) -- Get all stacks in the chest
        for slotNum, stack in ipairs(itemStacks) do
            if stack and stack.label == itemLabel then
                firstSlot = slotNum
            end
        end
    end
    return firstSlot -- Return nil if no items were found
end

-- Function to find first slot with the item of interest in the inventory
function potionLib.findFirstSlotWithPotionInInventory(proxyName,itemLabel, alkimiaLvl, side)
    local firstSlot = nil
    local inventory = proxyName.getInventorySize(side) -- Get the size of the chest inventory

    if inventory then
        local itemStacks = proxyName.getAllStacks(side) -- Get all stacks in the chest
        for slotNum, stack in ipairs(itemStacks) do
            if stack and stack.label == itemLabel and stack.aspects.Alkimia == alkimiaLvl then
                firstSlot = slotNum
            end
        end
    end
    return firstSlot -- Return nil if no items were found
end

--function that brews one set of items and transfers them to output container
function potionLib.brewPotion(brewTransposer,invTransposer, potionName, brewSide, inputSide, outputSide)
    -- Fetch the recipe
    local recipe = potionLib.getRecipe(potionName)

    --print(potionName)

    -- Transfer one ingredient to the brewing stand
    local ingredientSlot = potionLib.findFirstSlotWithItemInInventory(invTransposer,recipe.ingredient,inputSide)
    brewTransposer.transferItem(ingredientChestSide, 0, 1, ingredientSlot)

    -- Transfer three starter potions to the brewing stand one by one
    for targetSlot = 1, 3 do  -- Adjusted to transfer to specific slots in brewing stand
        --print(recipe.starter)
        --print(recipe.alkimiaLvl)
        local starterPotionSlot = potionLib.findFirstSlotWithPotionInInventory(invTransposer,recipe.starter,recipe.alkimiaLvl,inputSide)
        invTransposer.transferItem(inputSide, brewSide, 1, starterPotionSlot, targetSlot)
    end

    -- Wait for the brewing to complete
    while brewStand.getBrewTime() > 0 do
        os.sleep(1)  -- Wait for 1 second intervals
    end
    
    -- Transfer brewed potions to the output container
    for sourceSlot = 1, 3 do  -- Check the first 3 slots which are the output of the brewing stand
        invTransposer.transferItem(brewSide, outputSide, 1, sourceSlot)  -- Transfer brewed potions one by one
    end

end

-- function to iteratively go through brewing sequence and run potionLib.brewPotion()"
function potionLib.mainBrewing(brewSide, inputSide, outputSide)
    -- Step 1: Ask user which potion to brew
    local potionChoice = potionLib.selectPotion()
    local startingPotion = potionLib.selectStarterPotion()
    local selectedPotion = potionLib.potions[potionChoice]


    -- Step 2: Ask how many potions to brew
    local quantity = potionLib.selectQuantity()

    -- Step 3: Resolve dependencies
    local sequence = potionLib.resolveDependencies(selectedPotion.name, nil, startingPotion)
    
    -- Check if the first potion in the sequence has enough starter potions
    local firstRecipe = potionLib.getRecipe(sequence[1])
    local neededStarter = quantity * 3
    local actualStarter = potionLib.findNumberOfPotionsInInventory(potionLib.invTransposer, firstRecipe.starter, firstRecipe.alkimiaLvl, inputSide)
    if actualStarter < neededStarter then
        print("Not enough starter potions for " .. sequence[1] .. ". Needed: " .. neededStarter .. ", Available: " .. actualStarter)
        return
    end
    
    -- Check for other ingredients for all potions in the sequence
    for _, potionName in ipairs(sequence) do
        local recipe = potionLib.getRecipe(potionName)
        
        local neededIngredient = quantity
        local actualIngredient = potionLib.findNumberOfItemsInInventory(potionLib.invTransposer, recipe.ingredient, inputSide)

        if actualIngredient < neededIngredient then
            print("Not enough of the ingredient for " .. potionName .. ": " .. recipe.ingredient .. ". Needed: " .. neededIngredient .. ", Available: " .. actualIngredient)
            return
        end
    end

    -- Step 4: Brew potions in the resolved sequence
    for index, potionName in ipairs(sequence) do
        local targetOutputSide = inputSide -- Default to input side
        
        -- If it's the last potion in the sequence, send it to the main output
        if index == #sequence then
            targetOutputSide = outputSide
        end

        for i=1, quantity do
            print("Brewing",potionName)
            --print("Input:",inputSide)
            --print("output:",targetOutputSide)
            potionLib.brewPotion(potionLib.brewTransposer, potionLib.invTransposer, potionName, brewSide, inputSide, targetOutputSide)
        end
    end


    print("Brewing complete!")
end

-- Define a function to read the recipes file and populate the potions list.
function potionLib.loadRecipes()

    -- Attempt to open the file in read mode.
    local file = io.open(fileName, "r")

    -- Check if the file was successfully opened.
    if not file then
        print("Error: Could not open the file.")
        return nil
    end

    -- Read each line of the file.
    for line in file:lines() do
        -- Split the line into parts using a comma as the delimiter.
        local parts = {}
        for part in string.gmatch(line, "([^,]+)") do
            table.insert(parts, part)
        end

            -- Create a table for the potion recipe and populate it.
        local alkimiaLvl = tonumber(parts[3])
        if alkimiaLvl == -1 then
            alkimiaLvl = nil
        end
        local recipe = {
            name = parts[1],
            starter = parts[2],
            alkimiaLvl = alkimiaLvl,
            ingredient = parts[4]
        }

        -- Add the recipe table to the potions list.
        table.insert(potionLib.potions, recipe)
    end

    -- Close the file.
    file:close()
end

-- Function to get recipe by name of the potion needed to craft
function potionLib.getRecipe(potionName)
    -- print("Searching for:", potionName)  -- Debug
    for _, potion in ipairs(potionLib.potions) do
        -- print("Checking against:", potion.name)  -- Debug
        if string.lower(potion.name) == string.lower(potionName) then
            return potion
        end
    end
    return nil  -- If the potion is not found in the list
end

--very generic function that prints tables
function potionLib.printTable(t, indent)
    indent = indent or ""

    for k, v in pairs(t) do
        if type(v) == "table" then
            print(indent .. tostring(k) .. ":")
            printTable(v, indent .. "  ")
        else
            print(indent .. tostring(k) .. ": " .. tostring(v))
        end
    end
end

-- Load the recipes immediately upon requiring the library
potionLib.loadRecipes()
potionLib.initTransposers()

return potionLib