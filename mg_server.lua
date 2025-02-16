-- Make sure to load the config.lua first to ensure Config is defined
-- In fxmanifest.lua, it would be done like this:

-- fxmanifest.lua
-- server_script 'config.lua'  -- Load the config first
-- server_script 'server.lua'  -- Then load the server script

-- Now you can safely access Config in server.lua

ESX = exports["es_extended"]:getSharedObject()

-- Check if Config is loaded correctly
if Config then
    print("[DEBUG] Config table is loaded.")
else
    print("[ERROR] Config table is nil!")
end

-- Register usable items logic
for itemName, itemConfig in pairs(Config.UseableItems) do
    ESX.RegisterUsableItem(itemName, function(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if Config.Debug then
            print("[DEBUG] Usable item triggered: " .. itemName)
        end

        if xPlayer then
            local cid = xPlayer.identifier
            if Config.Debug then
                print("[DEBUG] Player Identifier: " .. cid)
            end

            -- Generate vehicle data
            local vehicleData = {
                model = itemConfig.model,
                plate = "AC" .. math.random(11111, 99999),
                garage = itemConfig.garage,
                state = 1,
                in_garage = 0,  -- Default value for in_garage
                garage_id = 'A', -- Default garage_id
                garage_type = 'car', -- Default garage_type
                job_personalowned = '', -- Default job_personalowned
                property = 0,  -- Default property value
                impound = 0,   -- Default impound value
                impound_data = '{}',  -- Default impound data (empty JSON)
                adv_stats = '{"plate":"nil","mileage":0.0,"maxhealth":1000.0}'  -- Default advanced stats
            }

            if Config.Debug then
                print("[DEBUG] Vehicle Data: " .. json.encode(vehicleData))
            end

            -- Insert vehicle data into the database
            exports['oxmysql']:execute('INSERT INTO owned_vehicles (owner, plate, vehicle, garage, state, in_garage, garage_id, garage_type, job_personalowned, property, impound, impound_data, adv_stats) VALUES (@owner, @plate, @vehicle, @garage, @state, @in_garage, @garage_id, @garage_type, @job_personalowned, @property, @impound, @impound_data, @adv_stats)', {
                ['@owner'] = cid,
                ['@plate'] = vehicleData.plate,
                ['@vehicle'] = json.encode({ model = vehicleData.model, plate = vehicleData.plate }),
                ['@garage'] = vehicleData.garage,
                ['@state'] = vehicleData.state,
                ['@in_garage'] = vehicleData.in_garage,
                ['@garage_id'] = vehicleData.garage_id,
                ['@garage_type'] = vehicleData.garage_type,
                ['@job_personalowned'] = vehicleData.job_personalowned,
                ['@property'] = vehicleData.property,
                ['@impound'] = vehicleData.impound,
                ['@impound_data'] = vehicleData.impound_data,
                ['@adv_stats'] = vehicleData.adv_stats
            }, function(result)
                if Config.Debug then
                    print("[DEBUG] Insert result: " .. json.encode(result))
                end

                if result and result.affectedRows > 0 then
                    -- Notify player and remove item
                    TriggerClientEvent('esx:showNotification', source, itemConfig.notification)
                    xPlayer.removeInventoryItem(itemName, 1)
                else
                    TriggerClientEvent('esx:showNotification', source, "Failed to add vehicle to the garage.")
                end
            end)
        else
            if Config.Debug then
                print("[DEBUG] Player not found for source: " .. source)
            end
        end
    end)
end
