# Ultimate Arrow Simulator 

The main repo for the Roblox game Ultimate Arrow Simulator

## Service Directory

# Server
[Bows](src/server/Systems/Bows.lua) - transactions and replication of bow actions\
[Playerdata](src/server/Systems/Playerdata/init.lua) - loading the playerdata and listening for changes via attributes\
[Moderation](src/server/Systems/Moderation.lua) - tracking and dealing with exploit reports\ 
[Network](src/server/Systems/Network.lua) - gets remote events and scramble the names via UUIDs for security\
[ShootingRange](src/server/Systems/ShootingRange.lua) - transactions and replication of shooting range actions\ 

# Client
[Gui](src/client/Systems/BowFiring.lua) - mounts and stores the react DOM for React-lua\
[BowFiring](src/client/Systems/BowFiring.lua) - Stores client side actions for bow firing\
[Cutscene](src/client/Systems/Cutscene.lua) - cutscene tweens and cleanup\
[Network](src/client/Systems/Network.lua) -  gets remote events along with associated UUID\
[ShootingRange](src/client/Systems/ShootingRange.lua) - transactions and rendering of shooting range actions\


## Project Setup
Wally package manager is for dependencies and managed in wally.toml\
Rojo project tree managed by default.project.json\
Selene linting managed in selene.toml\
Systems are spun up via Main.server.lua and Main.client.lua for the server and client respectively\

## Codebase Philosphy 
Store and modify game state in the Roblox DOM via attributes\
Use top level services to control the flow of the state\
Most of the GUI state should be managed by React-lua\