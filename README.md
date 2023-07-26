# Suit Up Boilerplate
This boilerplate should serve as a solid basis for starting a new project. It has the latest version of Knit established, as well as core Controllers and Services written by *Aaron Jay (seyai)* that handle player save data, character spawning, and basic client-server communication.

This README aims to introduce some patterns found in this boilerplate, as well as how to best take advantage of some of the modules found in it.

UI is not included in this template.

# Installing Packages
It is recommended to install Packages locally via Wally. Install tools via `aftman install`, then install the packages with `wally run`

# Handling PlayerData
Player data is handled via `src/Server/Modules/PlayerContainer.lua` utilizing ProfileService and ReplicaService (see below).

To read player data, it is suggested to use the following:
```
local container = PlayerService:GetContainer(player)
local data = container.Profile.Data
-- perform read operations here
```

To write player data, it is suggested to write to the Replica such that ReplicaService can propagate the newly modified state to its respective clients. These changes can then be listened to on the client using `replica:ListenToWrite()` and other listener methods. (see ReplicaService docs for more)

Replica write methods can only be called on the server for safety.

```
local container = PlayerService:GetContainer(player)
local replica = container.Replica

-- using DataWriteLib
replica:Write("IncrementCurrency", 100) -- this adds 100 currency, and signals the player that they received 100

-- using direct write operation
replica:IncrementValue({"Currency"}, 100) -- the WriteLib is shorthand for this.
```

## Profile+ReplicaService (modified)
[ProfileService](https://madstudioroblox.github.io/ProfileService/) and [ReplicaService](https://madstudioroblox.github.io/ReplicaService/) are modules created by Roblox developer veteran [loleris](https://twitter.com/LM_loleris) as a way to safely store player data and reflect that data as it changes across the client-server boundary with minimal network traffic, respectively.

ReplicaService has been minimally modified by Aaron Jay (seyai) to include quality of life methods like IncrementValue when operating on numeric data.

### WriteLibs
ReplicaService features WriteLibs, which are collections of predefined functions that predictably mutate data. Updating user data using WriteLibs is preferred because they also function as RemoteEvents that can be specifically listened for on the client using ReplicaService's API. This is great for accurate updates to player state with simple implementation.

# Currency
Currency is built-in to the boilerplate as `playerContainer.`

# Item Shop
An Item Shop exists via `ShopService.lua`, and can be invoked on both the client and server using the PurchaseItem method.

```
-- client
ShopService:PurchaseItem("TestItem", 10) -- // purchase 10 TestItem

-- server
ShopService:PurchaseItem(player, "TestItem", 10) -- // server call requires direct reference to the player object
```
## Adding items
Items that can be purchased with in-game currency can be added to `src/Shared/ShopData.lua`. This module can be used to get item data using string keys, and this data will be used when calling the `playerContainer.Replica:Write("PurchaseItem", itemId, itemamount)`.

# Additional Modules

## Promises
[Promise](https://eryn.io/roblox-lua-promise/) by [evaera](https://twitter.com/evaeraevaera) is a Luau implementation of the Promise structure similar to Promise/A+, and allows for predictable timing of Roblox's asynchronous structure

### WaitFor
This RbxUtil module by sleitnick is useful Promise implementation of `WaitForChild`, and should be used when you are expecting to do something after an Instance is found.