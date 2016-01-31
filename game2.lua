local Flux = require "lib/flux"
local Vector = require "lib/vector"
require "lib/swingers"
require "lib/class"
require "lib/trailmesh"
require "lib/postshader"
require "lib/light"
require "lib/edit-distance"

local Game2 = {} 
local jefe, musicSource, failMusicSource, bpm, beat, halfBeat, localTime, beatIndex, currentSteps, minions, background, fireImg, blueFireImg, mahand
local moves = {"l","r","u","d","c"}
local fps = 0
local handPositions = {}
local deathTime 
local death
local countNumbers = {}

local circles = {
  {"w","nw","n","ne","e","se","s","sw"},
  {"n","ne","e","se","s","sw","w","nw"},
  {"e","se","s","sw","w","nw","n","ne"},
  {"s","sw","w","nw","n","ne","e","se"}
}

handPositions.l =  Vector(250,love.graphics.getHeight()-100)
handPositions.r = Vector(love.graphics.getWidth() - 250,love.graphics.getHeight()-100)
handPositions.u =    Vector(love.graphics.getWidth()/2,300)
handPositions.d =  Vector(love.graphics.getWidth()/2,750)
handPositions.idle = Vector(love.graphics.getWidth()/2,love.graphics.getHeight()/2 + 350)

function Game2:init()
  jefe = {}
  jefe.img = love.graphics.newImage("images/jefe.png")
  jefe.scale = Vector(0.7,0.7)
  jefe.originalPos = Vector(love.graphics.getWidth()/2,love.graphics.getHeight()/2 + 150)

  jefe.hand = {}
  jefe.hand.img = love.graphics.newImage("images/liderhand.png")
  jefe.hand.scale = Vector(0.7,0.7)
  jefe.hand.originalPos = handPositions.idle

  minions = {}
  minions.img = love.graphics.newImage("images/minions.png")

  background = {}
  background.img = love.graphics.newImage("images/background.png")

  musicSource = love.audio.newSource( "music/level1.wav", "static")
  failMusicSource = love.audio.newSource( "music/hpitch.mp3")

  musicSource:setLooping(true)
  failMusicSource:setLooping(false)

  bpm = (16) * 60 / (8)
  beat = 60 / bpm 
  gameBeat = beat*2
  halfBeat = beat/2
  sequenceLen = 4

  fireImg = love.graphics.newImage("images/fire.png")
  blueFireImg = love.graphics.newImage("images/blue-fire.png")

  lightWorld = love.light.newWorld()
  lightWorld.setAmbientColor(128, 128, 128)

  mahand = {}
  mahand.img = love.graphics.newImage("images/mahand.png")
  mahand.scale = 0.7

  mahand.pos = Vector(580, 450) * mahand.scale
  mahand.light = lightWorld.newLight(0, 0, 126, 175, 255, 800)

  mahand.light.setGlowSize(0.0)

  handPositions.lights = {}

  handPositions.lights[1] = new_light(Vector(268,194))
  handPositions.lights[2] = new_light(Vector(402,202))
  handPositions.lights[3] = new_light(Vector(532,208))

  countNumbers[1] = love.graphics.newImage("images/1.png")
  countNumbers[2] = love.graphics.newImage("images/2.png")
  countNumbers[3] = love.graphics.newImage("images/3.png")
  countNumbers[4] = love.graphics.newImage("images/4.png")
end

function new_light(p)
  local halfHandSize = Vector(jefe.hand.img:getWidth()/2,jefe.hand.img:getHeight()/2)
  local t = {pos = (p - halfHandSize) * jefe.hand.scale.x , trail = trailmesh:new(0,0,fireImg,20,0.5,.01)} 
  t.light = lightWorld.newLight(jefe.hand.originalPos.x+t.pos.x, jefe.hand.originalPos.y+t.pos.y, 105, 103, 03, 600)
  return t
end


function Game2:enter(previous)
  math.randomseed(os.time())

  swingers.start()
  love.audio.rewind(musicSource)
  love.audio.play(musicSource)

  jefe.pos = jefe.originalPos:clone()

  jefe.hand.originalPos = handPositions.idle
  jefe.hand.lightOn = false
  jefe.hand.pos = jefe.hand.originalPos:clone()

  minions.originalPos = Vector(love.graphics.getWidth()/2,love.graphics.getHeight()/2 + 150)
  minions.pos = minions.originalPos:clone()
  minions.scale = Vector(1,1)
  localTime = 0.0

  mahand.trail = trailmesh:new(love.mouse.getX(),love.mouse.getY(),blueFireImg,10,0.2,.01)

  completedLastMove = true
  deathTime = 0.0
  death = false
  start_game()
end

function start_game()
  localTime = 0.0
  love.audio.rewind(musicSource)
  love.audio.play(musicSource)
  beatIndex = -1
  currentSteps = {}
end


function new_lights()
  for _,light in pairs(handPositions.lights) do
    light.trail = trailmesh:new(jefe.hand.pos.x+light.pos.x+math.cos(localTime*32)*5*math.cos(localTime*2),  jefe.hand.pos.y+light.pos.y+math.sin(localTime*32)*5*math.sin(localTime*2),fireImg,20,0.5,.01)
  end
end

function hand_move(start, finish)
  Flux.to(jefe.hand.pos, gameBeat/6, handPositions[start])
  :oncomplete(function() 
      jefe.hand.lightOn = true
      new_lights()
    end)
  :after((gameBeat/6)*4,handPositions[finish])
  :oncomplete(function() jefe.hand.lightOn = false end)
  :after(gameBeat/7,handPositions.idle)
end

function hand_circle()

  local precision = 16
  local c = Vector(love.graphics.getWidth()/2, love.graphics.getHeight()/2)
  local r = (handPositions.idle - c):len()/3

  local arcTime = (gameBeat - gameBeat/3)/(precision*2)

  local offset = math.pi/2
  local nx = c.x + r * math.cos(offset)
  local ny = c.y+200 + r * math.sin(offset)

  local lastween = Flux.to(jefe.hand.pos,gameBeat/6,{x=nx,y=ny})
  for i=0,precision do
    local a = ((2*math.pi)/precision)*i + offset
    local nx = c.x + r * math.cos(a)
    local ny = c.y+200 + r * math.sin(a)
    if i == 0 then 
      jefe.hand.lightOn = true
      new_lights()
    end
    lastween = lastween:after(arcTime,{x=nx,y=ny}) 
  end
  lastween:oncomplete(function()jefe.hand.lightOn = false end):after(jefe.hand.pos,gameBeat/6,{x=handPositions.idle.x,y=handPositions.idle.y})
end

function update_trails(dt) 
  for i,light in pairs(handPositions.lights) do
    light.trail.x, light.trail.y = jefe.hand.pos.x+light.pos.x+math.cos(localTime*32)*5*math.cos(localTime*2),  jefe.hand.pos.y+light.pos.y+math.sin(localTime*32)*5*math.sin(localTime*2)
    light.trail:update(dt)
    light.light.setPosition(jefe.hand.pos.x+light.pos.x, jefe.hand.pos.x+light.pos.x)
    light.light.setRange(math.sin(40*localTime%(math.cos(localTime*i)*24.645))*30+650)
  end
  mahand.trail.x = love.mouse.getX()
  mahand.trail.y = love.mouse.getY()
  mahand.trail:update(dt)
  mahand.light.setPosition(love.mouse.getX(), love.mouse.getY())
  mahand.light.setRange(math.sin(40*localTime%(math.cos(localTime)*21.45))*20+200)
end



function Game2:update(dt) -- runs every frame
  update_trails(dt)
  localTime = localTime + dt

  if not death then

    swingers.update()
    Flux.update(dt)


    local moveDist = 15
    local beatDist = math.abs(localTime % beat) 
    if beatDist < beat/5*4 then
      jefe.pos.y = jefe.originalPos.y - (beatDist / ((beat/5)*4)) * moveDist
      minions.pos.y = minions.originalPos.y - (beatDist / ((beat/5)*4)) * moveDist *0.4
    else
      jefe.pos.y = jefe.originalPos.y - (beat - (beat/5*4)) /(beat/5) * moveDist
      minions.pos.y = minions.originalPos.y - (beatDist / ((beat/5)*4)) * moveDist *0.4
    end

    if countdown then
      local waitLen = gameBeat*sequenceLen*2
      if localTime >= waitLen then
        start_game()
      end
    else
      local newIndex = math.floor(localTime * bpm * (1/60) * (0.5))

      local indexChanged = newIndex ~= beatIndex
      beatIndex = newIndex

      if (indexChanged and not completedLastMove) then lose() end
      if (beatIndex % (sequenceLen*2) < sequenceLen)  then
        if indexChanged then
          local move = moves[math.random(1,5)]
          if beatIndex%4 == 0 then currentSteps = {} end
          currentSteps[#currentSteps+1] = move
          if move == "l" then
            hand_move("r","l")
          elseif move == "r" then
            hand_move("l","r")
          elseif move == "u" then
            hand_move("d","u")
          elseif move == "d" then
            hand_move("u","d")
          elseif move == "c" then
            hand_circle()
          end
        end
      else
        local move = currentSteps[beatIndex%4 + 1]
        if indexChanged then 
          swingers.start()
          completedLastMove = false
        end

        if swingers.checkGesture() then
          if move == "c" then
            local gesture = swingers.getExtGesture()
            local found = false
            for _,circle in pairs(circles) do
              if EditDistance(circle, gesture,3) < 3 then found = true end
            end
            if found then
              completedLastMove = true
              Score = Score + 1
            else
              lose()
            end
          else
            if move ~= swingers.getGesture() then
              lose()
            else
              completedLastMove = true
              Score = Score + 1
            end
          end
        end  
      end
    end
  else
    deathTime = deathTime + dt
    if deathTime >= 2 then

      Gamestate.switch(Kill)
    end
  end
end

function lose() 
  love.audio.stop(musicSource)
  love.audio.play(failMusicSource)
  death = true
end


function Game2:draw()
  
  lightWorld.update()
  love.postshader.setBuffer("render")

  love.graphics.setColor(255,255,255,255)
  love.graphics.draw(background.img,0,-2800 + love.graphics.getHeight())

  love.graphics.draw(minions.img, minions.pos.x, minions.pos.y, 0, minions.scale.x,minions.scale.y, minions.img:getWidth()/2, minions.img:getHeight()/2)
  love.graphics.draw(jefe.img, jefe.pos.x, jefe.pos.y, 0, jefe.scale.x,jefe.scale.y, jefe.img:getWidth()/2, jefe.img:getHeight()/2)
  love.graphics.draw(jefe.hand.img, jefe.hand.pos.x, jefe.hand.pos.y, 0, jefe.hand.scale.x,jefe.hand.scale.y, jefe.hand.img:getWidth()/2, jefe.hand.img:getHeight()/2-100)


  local fireBlendMode = "additive"
  if ( jefe.hand.lightOn) then
    love.graphics.setBlendMode(fireBlendMode)
    handPositions.lights[1].trail:draw()
    handPositions.lights[2].trail:draw()
    handPositions.lights[3].trail:draw()
  end

  love.graphics.setBlendMode(fireBlendMode)
  mahand.trail:draw()
  love.graphics.setBlendMode("alpha")

  lightWorld.drawShadow()
  lightWorld.drawShine()
  lightWorld.drawPixelShadow()
  lightWorld.drawGlow()

  love.graphics.setBlendMode("alpha")
  love.graphics.draw(mahand.img, love.mouse.getX() - mahand.pos.x, love.mouse.getY() - mahand.pos.y, 0, mahand.scale,mahand.scale)
  
  love.graphics.setNewFont("fonts/Gypsy_Curse.ttf", 80)
  love.graphics.print(Score, 20,15)
  
  if countdown then
    local waitLen = gameBeat*sequenceLen*2
    for i=4,1,-1 do
      if localTime >= waitLen - gameBeat*i and localTime < waitLen - gameBeat*(i-1) then
        local img = countNumbers[i]
        love.graphics.draw(img,love.graphics.getWidth()/2,love.graphics.getHeight()/2,0,1,1,img:getWidth()/2,img:getHeight()/2)
      end
    end
  end
  love.postshader.draw()
end

function Game2:mousepressed(x,y, mouse_btn)
  if mouse_btn == "l" then
    mahand.trail = trailmesh:new(love.mouse.getX(),love.mouse.getY(),blueFireImg,20,0.6,.01)
  end
end

function Game2:mousereleased(x,y, mouse_btn)
  if mouse_btn == "l" then
    mahand.trail = trailmesh:new(love.mouse.getX(),love.mouse.getY(),blueFireImg,10,0.2,.01)
  end
end

return Game2