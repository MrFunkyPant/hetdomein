-- Framework = nil
local Framework = exports["pepe-core"]:GetCoreObject()

-- TriggerEvent('Framework:GetObject', function(obj) Framework = obj end)

Framework.Functions.CreateCallback("pepe-banking:server:get:private:account", function(source, cb)
    local Player = Framework.Functions.GetPlayer(source)
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts", {}, function(result) 
        local AccountData = {}
        if result ~= nil then
            for k, v in pairs(result) do
                if v.type == 'private' then
                    if v.citizenid == Player.PlayerData.citizenid then
                        DatabaseData = {
                            Owner = v.citizenid,
                            Name = v.name,
                            BankId = v.bankid,
                            Balance = v.balance,
                        }
                        table.insert(AccountData, DatabaseData)
                    end
                end
            end
            cb(AccountData)
        end
    end)
end)

Framework.Functions.CreateCallback("pepe-banking:server:get:shared:account", function(source, cb)
    local Player = Framework.Functions.GetPlayer(source)
    Framework.Functions.ExecuteSql(true, "SELECT * FROM characters_accounts", {}, function(result) 
        local AccountData = {}
        if result ~= nil then
            for k, v in pairs(result) do
                if v.type == 'shared' then
                    local AuthData = json.decode(v.authorized)
                    for Auth, Authorized in pairs(AuthData) do
                        if Authorized == Player.PlayerData.citizenid then
                            DatabaseData = {
                                Owner = v.citizenid,
                                Name = v.name,
                                BankId = v.bankid,
                                Balance = v.balance,
                            }
                            table.insert(AccountData, DatabaseData)
                        end
                    end
                end
            end
            cb(AccountData)
        end
    end)
end)

Framework.Functions.CreateCallback("pepe-banking:server:get:account:users", function(source, cb, bankid)
    local Player = Framework.Functions.GetPlayer(source)
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = bankid,
    }, function(result) 
        local UserData = {}     
         if result ~= nil then
             for k, v in pairs(result) do 
                 local AuthorizedData = json.decode(v.authorized)
                 for Auth, Authorized in pairs(AuthorizedData) do
                     Framework.Functions.ExecuteSql(true, "SELECT * FROM characters_metadata WHERE `citizenid` = @citizenid", {
                         ['@citizenid'] = Authorized,
                     }, function(CharResult) 
                         local DecodeCharInfo = json.decode(CharResult[1].charinfo)
                         AccountArrayData = {
                          Firstname = DecodeCharInfo.firstname,
                          Lastname = DecodeCharInfo.lastname,
                          CitizenId = Authorized,
                         }
                         table.insert(UserData, AccountArrayData)
                     end)
                 end
             end
             cb(UserData)
         end                 
    end)
end)

Framework.Functions.CreateCallback("pepe-banking:server:get:account:transactions", function(source, cb, bankid)
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = bankid,
    }, function(result)
        local ReturnData = {}
        local TransactionData = json.decode(result[1].transactions)
         for k, v in pairs(TransactionData) do
             Transactions = {
                 Name = GetCharName(v.CitizenId),
                 Amount = v.Amount,
                 Type = v.Type,
                 CitizenId = v.CitizenId,
                 Date = v.Date,
                 Time = v.Time,
             }
             table.insert(ReturnData, Transactions)
         end
         cb(ReturnData)
    end)
end)

RegisterServerEvent('pepe-banking:server:withdraw')
AddEventHandler('pepe-banking:server:withdraw', function(RemoveAmount, BankId)
    local src = source
    local Player = Framework.Functions.GetPlayer(source)
    if Player.PlayerData.charinfo.account ~= BankId then
        local Balance = GetAccountBalance(BankId)
        local Amount = tonumber(RemoveAmount)
        local NewBalance = Balance - Amount
        if Balance >= Amount then
         Player.Functions.AddMoney('cash', Amount, 'Bank opnemen')
         TriggerEvent('pepe-banking:server:add:transaction', src, BankId, Amount, 'Remove')
         Framework.Functions.ExecuteSql(false, "UPDATE characters_accounts SET `balance` = @balance WHERE `bankid` = @bankid", {
             ['@balance'] = NewBalance,
             ['@bankid'] = BankId,
         })
        end
    else
        local CurrentBalance = Player.PlayerData.money['bank']
        local Amount = tonumber(RemoveAmount)
        if CurrentBalance >= Amount then
            Player.Functions.RemoveMoney('bank', Amount, 'Bank opnemen')
            Player.Functions.AddMoney('cash', Amount, 'Bank opnemen')
        else
            TriggerClientEvent('pepe-banking:client:send:notify', source, 'Bank', 'error', 'Onvoldoende saldo.')
        end
    end
end)

RegisterServerEvent('pepe-banking:server:deposit')
AddEventHandler('pepe-banking:server:deposit', function(AddAmount, BankId)
    local src = source
    local Player = Framework.Functions.GetPlayer(source)
    if Player.PlayerData.charinfo.account ~= BankId then
        local Balance = GetAccountBalance(BankId)
        local CurrentCash = Player.PlayerData.money['cash']
        local Amount = tonumber(AddAmount)
        local NewBalance = Balance + Amount
        if CurrentCash >= Amount then
         Player.Functions.RemoveMoney('cash', Amount, 'Bankstorting')  
         TriggerEvent('pepe-banking:server:add:transaction', src, BankId, Amount, 'Add')
         Framework.Functions.ExecuteSql(false, "UPDATE characters_accounts SET `balance` = @balance WHERE `bankid` = @bankid", {
            ['@balance'] = NewBalance,
            ['@bankid'] = BankId,
         })
        end
    else
        local CurrentCash = Player.PlayerData.money['cash']
        local Amount = tonumber(AddAmount)
        if CurrentCash >= Amount then
            Player.Functions.RemoveMoney('cash', Amount, 'Bankstorting')
            Player.Functions.AddMoney('bank', Amount, 'Bankstorting')
        else
            TriggerClientEvent('pepe-banking:client:send:notify', source, 'Bank', 'error', 'Onvoldoende contant geld.')
        end
    end
end)

RegisterServerEvent('pepe-banking:server:create:account')
AddEventHandler('pepe-banking:server:create:account', function(AccountName, AccountType)
local Player = Framework.Functions.GetPlayer(source)
local RandomAccountId = CreateRandomIban()
-- Framework.Functions.ExecuteSqlOld(false, "INSERT INTO `characters_accounts` (`citizenid`, `type`, `name`, `bankid`, `authorized`) VALUES ('"..Player.PlayerData.citizenid.."', '"..AccountType.."', '"..AccountName.."', '"..RandomAccountId.."', '[\""..Player.PlayerData.citizenid.."\"]')", {
    Framework.Functions.ExecuteSql(false, "INSERT INTO `characters_accounts` (`citizenid`, `type`, `name`, `bankid`, `authorized`) VALUES (@citizenid, @type, @name, @bankid, @authorized)", {
    ['@citizenid'] = Player.PlayerData.citizenid,
     ['@type'] = AccountType,
     ['@name'] = AccountName,
     ['@bankid'] = RandomAccountId,
     ['@authorized'] = json.encode({Player.PlayerData.citizenid}),
 })
 TriggerClientEvent('pepe-banking:client:refresh:bank', source)
end)

RegisterServerEvent('pepe-banking:server:add:user')
AddEventHandler('pepe-banking:server:add:user', function(BankId, TargetBsn)
    local src = source
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = BankId,
    }, function(result)
        if result ~= nil then
            local Count = 0
            local UserData = json.decode(result[1].authorized)
            local NewUsers = {}
            for k, v in pairs(UserData) do
                Count = Count + 1
                table.insert(NewUsers, v)
            end
            if Count < 5 then
             table.insert(NewUsers, TargetBsn)
             Framework.Functions.ExecuteSql(false, "UPDATE characters_accounts SET `authorized` = @authorized WHERE `bankid` = @bankid", {
                 ['@authorized'] = json.encode(NewUsers),
                 ['@bankid'] = BankId,
             })
             TriggerClientEvent('pepe-banking:client:refresh:bank', src)
            else
             TriggerClientEvent('Framework:Notify', src, "U kunt maximaal 4 burgers aan dit account toevoegen.", 'error', 6500)
            end
        end
    end)
end)

RegisterServerEvent('pepe-banking:server:remove:user')
AddEventHandler('pepe-banking:server:remove:user', function(BankId, TargetBsn)
    local src = source
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = BankId, 
    }, function(result)
        if result ~= nil then
            local UserData = json.decode(result[1].authorized)
            local NewUsers = {}
            for k, v in pairs(UserData) do
                if v ~= TargetBsn then
                 table.insert(NewUsers, v)
                end
            end
            Framework.Functions.ExecuteSql(false, "UPDATE characters_accounts SET `authorized` = @authorized WHERE `bankid` = @bankid", {
                ['@authorized'] = json.encode(NewUsers),
                ['@bankid'] = BankId,
            })
            TriggerClientEvent('pepe-banking:client:refresh:bank', src)
        end
    end)
end)

RegisterServerEvent('pepe-banking:server:add:transaction')
AddEventHandler('pepe-banking:server:add:transaction', function(Source, BankId, Amount, Type)
    local src = Source
    local Player = Framework.Functions.GetPlayer(src)
    Framework.Functions.ExecuteSql(false, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = BankId,
    }, function(result)
        if result ~= nil then
            local NewTransactionData = {}
            local TransactionData = json.decode(result[1].transactions)
            local AddTransaction = {Type = Type, Amount = Amount, CitizenId = Player.PlayerData.citizenid, Date = os.date('%d-'..'%m-'..'%y'), Time = os.date('%H:'..'%M')}
            for k, v in pairs(TransactionData) do
                table.insert(NewTransactionData, v)
            end
            table.insert(NewTransactionData, AddTransaction)
            Framework.Functions.ExecuteSql(false, "UPDATE characters_accounts SET `transactions` = @transaction WHERE `bankid` = @bankid", {
                ['@transaction'] = json.encode(NewTransactionData),
                ['@bankid'] = BankId,
            })
        end
    end)
end)

RegisterServerEvent('pepe-banking:server:remove:account')
AddEventHandler('pepe-banking:server:remove:account', function(BankId)
    Framework.Functions.ExecuteSql(false, 'DELETE FROM `characters_accounts` WHERE `bankid` = @bankid', {
        ['@bankid'] = BankId,
    })
end)

RegisterNetEvent('pepe-banking:server:give:cash')
AddEventHandler('pepe-banking:server:give:cash', function(TargetPlayer, Amount)
    local SelfPlayer = Framework.Functions.GetPlayer(source)
    local TargetPlayer = Framework.Functions.GetPlayer(TargetPlayer)
    SelfPlayer.Functions.RemoveMoney('cash', Amount, 'Gegeven contant geld')
    TargetPlayer.Functions.AddMoney('cash', Amount, 'Gegeven contant geld')
    TriggerClientEvent('Framework:Notify', SelfPlayer.PlayerData.source, "Je gaf €"..Amount.. "", "success", 4500)
    TriggerClientEvent('Framework:Notify', TargetPlayer.PlayerData.source, "Jij ontving €"..Amount.. " van "..SelfPlayer.PlayerData.charinfo.firstname, "success", 4500)
end)

Framework.Commands.Add("geefgeld", "Geef geld aan een andere burger.", {{name="id", help="Burger ID"},{name="bedrag", help="Aantal"}}, true, function(source, args)
    local SelfPlayer = Framework.Functions.GetPlayer(source)
    local TargetPlayer = Framework.Functions.GetPlayer(tonumber(args[1]))
    local Amount = tonumber(args[2])
    if TargetPlayer ~= nil then
        if TargetPlayer.PlayerData.source ~= SelfPlayer.PlayerData.source then
            if Amount ~= nil and Amount > 0 then
                if SelfPlayer.PlayerData.money['cash'] >= Amount then
                    TriggerClientEvent('pepe-banking:client:check:players:near', SelfPlayer.PlayerData.source, TargetPlayer.PlayerData.source, Amount)
                else
                    TriggerClientEvent('Framework:Notify', source, "Je hebt niet genoeg contant geld.", "error", 4500)
                end
            end
        else
            TriggerClientEvent('Framework:Notify', source, "Wat?", "error", 4500)
        end
    else
        TriggerClientEvent('Framework:Notify', source, "Geen burger gevonden.", "error", 4500)
    end
end)

function GetCharName(CitizenId)
    local CharName = nil
    Framework.Functions.ExecuteSql(true, "SELECT * FROM characters_metadata WHERE `citizenid` = @citizenid", {
        ['@citizenid'] = CitizenId,
    }, function(CharResult) 
        local DecodeCharInfo = json.decode(CharResult[1].charinfo)
        CharName = DecodeCharInfo.firstname..' '..DecodeCharInfo.lastname
    end)
    return CharName
end

function GetAccountBalance(BankId)
    local ReturnData = nil
    Framework.Functions.ExecuteSql(true, "SELECT * FROM characters_accounts WHERE `bankid` = @bankid", {
        ['@bankid'] = BankId,
    }, function(result)
        ReturnData = result[1].balance
    end)
    return ReturnData
end

function CreateRandomIban()
    return "NL0"..math.random(1,9)..Framework.Shared.RandomInt(3):upper()..math.random(1111,9999)..math.random(1111,9999)..math.random(11,99)
end