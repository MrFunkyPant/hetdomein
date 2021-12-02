local IsLockPicking = false
Framework = exports["pepe-core"]:GetCoreObject()

-- Code

AddEventHandler('pepe-lockpick:client:openLockpick', function(callback)
    lockpickCallback = callback
    openLockpick(true)
end)

function OpenLockpickGame(callback)
 lockpickCallback = callback
 openLockpick(true)
end

RegisterNUICallback('callback', function(data, cb)
    openLockpick(false)
	lockpickCallback(data.success)
    cb('ok')
end)

RegisterNUICallback('exit', function(data)
    lockpickCallback(data.success)
    openLockpick(false)
end)

 function openLockpick(bool)
 SetNuiFocus(bool, bool)
 SendNUIMessage({
     action = "ui",
     toggle = bool,
 })
 SetCursorLocation(0.5, 0.2)
 IsLockPicking = bool
end

function GetLockPickStatus()
    return IsLockPicking
end