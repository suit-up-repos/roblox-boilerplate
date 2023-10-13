# Suit Up Boilerplate
This boilerplate should serve as a solid basis for starting a new project. It has the latest version of Knit established, as well as core Controllers and Services written by *Aaron Jay (seyai_one)* that handle player save data, character spawning, and basic client-server communication.

This README aims to introduce some patterns found in this boilerplate, as well as how to best take advantage of some of the modules found in it.

UI is not included in this template.

# Rojo default vs deploy
`deploy.project.json` should have a `servePlaceIds` of the main dev staging/production place on Roblox. This is to prevent syncing of WIP code to these places by accident. Additionally, it is recommended to create `default.project.json` file that is a copy of `deploy`, but using your development place id(s) in `servePlaceIds` instead of the main ones. `default.project.json` is ignored by git as well since it is meant to be a local dev environment.

# Installing Packages
It is recommended to install Packages locally via Wally. Install tools via `aftman install`, then install the packages with `wally run`

# Handling PlayerData
Player data is handled via `src/Server/Modules/PlayerContainer.lua` utilizing ProfileService and ReplicaService (see below).

To read player data, it is suggested to use the following:
```
local container = PlayerService:GetContainer(player)
local data = container.Profile.Data
local munny = data.Currency
-- perform money operations here
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
## Help! My data isn't saving in Studio!
This "issue" comes up a lot with teammates newly joining Suit Up Games, so I thought it'd be good to address here.

This is intended by default. ProfileService will utilize a **Mock DataStore** that simulates all features of a DataStore without making direct calls to the Roblox service. This is useful for quickly testing features without running into any read/write limits imposed by Roblox, as well as if services go down. This is also helpful for testing different stages of gameplay (FTUE vs long time player), and separating your live data from testing.

## Adding new keys
If new keys are needed in a player's data, these can be added to the `TEMPLATE_DATA` variable under `src/Server/Modules/PlayerContainer.lua`. The game will automatically reconcile existing profiles with any new keys added to this.

## Inventory
The DataWriteLib handles inventory management in such a way that allows "known-stackable" objects. What do these terms mean?
* Known: pre-defined item with set, immutable attributes (ex. consumables, quest key objects)
* Stackable: we can have many of this type of object

The ShopService and base inventory WriteLibs do not support *unique* objects that can change during gameplay, like pets in a pet simulator type of game. It is recommended to add a new key to the PlayerContainer's template data for a new dictionary to support these.

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

## BrainTracking

Please track events that may affect player behavior. Google A/B Testing for some ideas. 

Also track events that could give context to other events. For example, it would be good to know when the server starts a new round of game play and details about that round.

### Configuration
Update src/Server/Services/BrainTrackService/config.lua so that "campaign" is a short human-readable code describing the game. 

Turn on track_on_local and debug when you add new tracking to ensure that it works.

Put ad/logo asset ids into logo_assets in BrainTrackingContoller.lua to track ad/logo impressions.

```
-- client
BrainTrackService:track(trackData) 
BrainTrackService:track({'event' = 'open', 'choice' = 'box', 'subchoice' = 'birthdayPresent', 'scene' = 'chuckyCheese'}) 
-- // record event when player opened a box containing a birthday present at chucky cheese. 

-- server
BrainTrackService:track(player, trackData) 
BrainTrackService:track(nil, {'event' = 'beginRound', 'choice' = 'checkers'}) 
-- // record event when server starts a round of checkers
```

trackData should always contain key "event"
trackData may also contain keys 'choice','subchoice', 'scene', and 'context'

'choice' is truncated to 99 chars, other options are 64 or shorter so put important information in beginning of string. For example "1234_cabin_in_woods" is better than "cabin_in_woods_1234"

There is basic debouncing which prevents the same event with identical values from being sent multiple times per minute. Please avoid sending repetitive data -  Roblox limits the number of outgoing http calls per minute and we don't want to track junk data.

There is a 15-30 minute delay between event being recorded and it showing up in reports. Contact James Funk (stinkoDad20x6) if you need access to reports, need a new report specific to your game, or need a way to see events quicker.

BrainTrackService:GetSummaryEvent() and BrainTrackService:SetSummaryEvent() are used to store 
values that change during the lifetime of the user session are automatically sent when player
leaves. Currently used to track total session time and summary of ad/logo impressions.