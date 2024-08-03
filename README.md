# Ultimate Arrow Simulator 

The main repo for the Roblox game Ultimate Arrow Simulator

## Project Setup
Wally package manager is for dependencies and managed in wally.toml
Rojo project tree managed by default.project.json
Selene linting managed in selene.toml
Systems are spun up via Main.server.lua and Main.client.lua for the server and client respectively

## Codebase Philosphy 
Store and modify game state in the Roblox DOM via attributes. 
Use top level services to control the flow of the state
Most of the GUI state should be managed by React-lua 

## Service Directory

# Server
Bows.lua - transactions and replication of bow actions 
Playerdata - loading the playerdata and listening for changes via attributes
Moderation.lua - tracking and dealing with exploit reports 
Network.lua - gets remote events and scramble the names via UUIDs for security
ShootingRange.lua - transactions and replication of shooting range actions 

# Client
Gui - mounts and stores the react DOM for React-lua
BowFiring - Stores client side actions for bow firing
Cutscene - cutscene tweens and cleanup
Network -  gets remote events along with associated UUID
[ShootingRange](src/client/Systems/ShootingRange.lua) - transactions and rendering of shooting range actions
