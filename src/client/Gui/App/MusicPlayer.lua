local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Shared.Packages

local React = require(Packages.React)
local RoactCompat = require(Packages.RoactCompat)
local ReactSpring = require(Packages.ReactSpring)
local RoactTemplate = require(Packages.RoactTemplate)

local MusicPlayerTemplate = RoactTemplate.fromInstance(RoactCompat, ReplicatedStorage.Assets.Gui.Templates.MusicPlayer)

local e = React.createElement

return function(props)

    local songInfo, setSongInfo = React.useState({
        AlbumName = "Album Name",
        SongName = "Song Name"
    })

    local styles, api = ReactSpring.useSpring(function()
        return {
            position = UDim2.new(-0.5, 0, 0.851, 0),
            config = ReactSpring.config.gentle
        }
    end)

    local musicNoteRotation, setMusicNoteRotation = React.useState(0)

    local musicNoteStyle, musicNoteApi = ReactSpring.useSpring(function()
        return {
            size = UDim2.new(0.312, 0, 0.788, 0),
            config = {
                damping = 0.8,
                frequency = 0.1
            }
        }
    end)

    React.useEffect(function()
        local playMusicThread = task.spawn(function()
            while true do
                
                local usedSongs = {}

                if #usedSongs == #ReplicatedStorage.Assets.Sounds.AmbientMusic:GetChildren() then
                    usedSongs = {}
                end

                local selectedSong

                while selectedSong == nil do
                    local randomSong = ReplicatedStorage.Assets.Sounds.AmbientMusic:GetChildren()[math.random(1, #ReplicatedStorage.Assets.Sounds.AmbientMusic:GetChildren())]

                    if table.find(usedSongs, randomSong) then
                        continue
                    end

                    selectedSong = randomSong
                    table.insert(usedSongs, selectedSong)
                end

                setSongInfo({
                    AlbumName = selectedSong:GetAttribute("AlbumName"),
                    SongName = selectedSong:GetAttribute("SongName")
                })

                selectedSong:Play()

                api.start({
                    position = UDim2.new(0.124, 0, 0.851, 0)
                })

                task.wait(3)

                api.start({
                    position = UDim2.new(-0.5, 0, 0.851, 0)
                })

                selectedSong.Ended:Wait()
            end
        end)

        local spinThread = task.spawn(function()
            while true do
                task.wait()
                setMusicNoteRotation(function(prev)
                    return prev + 1
                end)
            end
        end)

        local bopThread = task.spawn(function()
            while true do
                task.wait(1)
                
                musicNoteApi.start({
                    size = UDim2.new(0.312 * 1.5, 0, 0.788 * 1.5, 0)
                })

                task.wait(0.3)

                musicNoteApi.start({
                    size = UDim2.new(0.3125, 0, 0.788, 0)
                })
            end
        end)

        return function()
            task.cancel(playMusicThread)
            task.cancel(spinThread)
            task.cancel(bopThread)
        end
    end, {})
    
    return e(MusicPlayerTemplate, {
        Main = {
            Visible = props.visible
        },

        AlbumName = {
            Text = songInfo.AlbumName
        },

        SongName = {
            Text = songInfo.SongName
        },

        Holder = {
            Position = styles.position
        },

        MusicNote = {
            Rotation = musicNoteRotation,
            Size = musicNoteStyle.size
        }
    })
end



