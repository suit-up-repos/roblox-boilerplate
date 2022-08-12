# Suit Up Boilerplate
This boilerplate should serve as a solid basis for starting a new project. It has the latest version of Knit established, as well as core Controllers and Services written by *Aaron Jay (seyai)* that handle player save data, character spawning, and basic client-server communication.

This README aims to introduce some patterns found in this boilerplate, as well as how to best take advantage of some of the modules found in it.

## Third-Party Modules
### Profile+ReplicaService (modified)
[ProfileService]() and [ReplicaService]() are modules created by Roblox developer veteran [loleris]() as a way to safely store player data and reflect that data as it changes across the client-server boundary with minimal network traffic, respectively.

ReplicaService has been minimally modified by Aaron Jay (seyai) to include quality of life methods like IncrementValue when operating on numeric data.

### WriteLibs
ReplicaService features WriteLibs, which are collections of predefined functions that predictably mutate data. Updating user data using WriteLibs is preferred because they also function as RemoteEvents that can be specifically listened for on the client using ReplicaService's API. This is great for accurate updates to player state with simple implementation.