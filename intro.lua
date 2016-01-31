local Flux = require "lib/flux"
local Vector = require "lib/vector"
require "lib/swingers"

local Intro = {} 
local musicSource, localTime, background, offset, titleImg
local introTime = 8
local titleTime = 5
local things = {}
local ready = false

function Intro:init()
  background = {}
  background.img = love.graphics.newImage("images/cathedral.png")

  titleImg = love.graphics.newImage("images/title.png")

  musicSource = love.audio.newSource( "music/Intro.wav", "static")

  musicSource:setLooping(true)
end

function Intro:enter(previous)
  love.audio.rewind(musicSource)
  love.audio.play(musicSource)

  localTime = 0.0
  things.offset = 0
  things.titleAlpha = 0
  things.blackAlpha = 0

  maxOffset = 2800-love.graphics.getHeight()
  Flux.to(things,introTime,{offset=maxOffset}):ease("quadin")
  :after(titleTime,{titleAlpha = 255}):delay(0.5):oncomplete(function() ready = true end)
end

function Intro:update(dt) -- runs every frame
  Flux.update(dt)
  localTime = localTime + dt


end

local titleScale = 1.2
function Intro:draw()
  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(background.img,0,-things.offset)
  love.graphics.setColor(255,255,255,things.titleAlpha)
  love.graphics.draw(titleImg, (love.graphics.getWidth()-titleImg:getWidth()*titleScale)/2, (love.graphics.getHeight()-titleImg:getHeight()*titleScale)/2,0,titleScale,titleScale)
  love.graphics.setColor(0,0,0, things.blackAlpha)
  love.graphics.rectangle("fill", 0,0, love.graphics.getWidth(),love.graphics.getHeight())
end

function Intro:keyreleased(key)
  math.randomseed(os.time())
  if ready then
    Flux.to(things, 1.5, {blackAlpha = 255}):delay(0.2):oncomplete(function()
        musicSource:stop()
        Gamestate.switch(Game)
      end)
  end
end

return Intro