local blockSize = 25
local areaWidth = 10
local areaHeight = 20

local shapes = {
  {
    { 0,1,0 },
    { 1,1,0 },
    { 0,1,0 }
  },
  {
    { 0,0,1,0 },
    { 0,0,1,0 },
    { 0,0,1,0 },
    { 0,0,1,0 }
  },
  {
    { 1,1 },
    { 1,1 }
  },
  {
    { 1,0,0 },
    { 1,1,0 },
    { 0,1,0 }
  },
  {
    { 0,1,0 },
    { 1,1,0 },
    { 1,0,0 }
  },
  {
    { 1,1,0 },
    { 0,1,0 },
    { 0,1,0 }
  },
  {
    { 0,1,0 },
    { 0,1,0 },
    { 1,1,0 }
  }
}

local colors = {
  { 1.0, 0.1, 0.1 },
  { 0.1, 0.5, 0.1 },
  { 0.1, 0.4, 1.0 },
  { 1.0, 0.5, 0.1 },
  { 0.1, 0.0, 0.9 },
  { 0.5, 0.0, 0.4 },
  { 0.7, 0.5, 1.0 },
  { 1.0, 1.0, 1.0 }
}
  
local shape
local shapePosX
local shapePosY
local shapeFall
local nextShape
local blocks
local gameOver

local timer
local interval = 0.05
local controlTimer
local controlInterval = 0.07
local collectTimer
local collectInterval = 0.15

function love.load()
  love.window.setMode(blockSize * areaWidth, blockSize * areaHeight)
  love.window.setTitle("Tetris")
  local font = love.graphics.newFont(blockSize)
  love.graphics.setFont(font)
  restart()
end

function resetShape()
  local shapeType
  local shapeRot

  if nextShape ~= nil then
    shapeType = nextShape.type
    shapeRot = nextShape.rot
  else
    shapeType = love.math.random(1, #shapes)
    shapeRot = love.math.random(1, 4)
  end

  shape = createShape(shapeType, shapeRot)
  shapePosX = math.floor(areaWidth / 2 - (shape.maxX - shape.minX) / 2 - shape.minX + 0.5)
  shapePosY = -shape.minY + 1
  shapeFall = 0
  
  local nextShapeType = love.math.random(1, #shapes)
  local nextShapeRot = love.math.random(1, 4)
  nextShape = createShape(nextShapeType, nextShapeRot)
  
  if isShapeColliding(shapePosX, shapePosY) then
    gameOver = true
  end
end

function restart()
  gameOver = false
  clearBlocks()
  nextShape = nil
  resetShape()
  timer = 0
  controlTimer = 0
  collectTimer = 0
end

function clearBlocks()
  blocks = {}
  
  for j = 1, areaHeight do
    blocks[j] = {}
    
    for i = 1, areaWidth do
      blocks[j][i] = 0
    end
  end
end

function saveShape()
  for j = 1, shape.length do
    for i = 1, shape.length do
      if shape.data[j][i] == 1 then
        local x = shapePosX + i
        local y = shapePosY + j
        
        if x >= 1 and x <= areaWidth and y >= 1 and y <= areaHeight then
          blocks[y][x] = shape.type
        end
      end
    end
  end
end

function markBlocks()
  
  local temp = {}
  
  for j = 1, areaHeight do
    temp[j] = {}
    
    for i = 1, areaWidth do temp[j][i] = 0 end
  end
  
  
  local marked = false
  
  for j = areaHeight, 1, -1 do
    local mark = true
    
    for i = 1, areaWidth do
      if blocks[j][i] == 0 then mark = false; break end
    end
    
    if mark then
      for i = 1, areaWidth do temp[j][i] = 8 end
      marked = true
    else
      for i = 1, areaWidth do temp[j][i] = blocks[j][i] end
    end
  end
  
  for j = 1, areaHeight do
    for i = 1, areaWidth do blocks[j][i] = temp[j][i] end
  end
end

function collectBlocks()
  local temp = {}
  
  for j = 1, areaHeight do
    temp[j] = {}
    
    for i = 1, areaWidth do temp[j][i] = 0 end
  end
  
  local row = areaHeight
  
  for j = areaHeight, 1, -1 do
    local copy = false
    
    for i = 1, areaWidth do
      if blocks[j][i] < 8 then copy = true; break end
    end
    
    if copy then
      for i = 1, areaWidth do temp[row][i] = blocks[j][i] end
      row = row - 1
    end
  end
  
  for j = 1, areaHeight do
    for i = 1, areaWidth do blocks[j][i] = temp[j][i] end
  end
end

function createShape(t, r)
  local shape = {
    type = t,
    rot = r,
    length = #shapes[t][1],
    minX = 100,
    maxX = -100,
    minY = 100,
    maxY = -100,
    data = {}
  }

  for y = 1, shape.length do
    shape.data[y] = {}
    
    for x = 1, shape.length do
      local u = x
      local v = y
      
      if r == 2 then
        u = y
        v = shape.length - x + 1
      elseif r == 3 then
        u = shape.length - x + 1
        v = shape.length - y + 1
      elseif r == 4 then
        u = shape.length - y + 1
        v = x
      end
      
      shape.data[y][x] = shapes[t][v][u]
      
      if shape.data[y][x] == 1 then
        if x < shape.minX then shape.minX = x end
        if x > shape.maxX then shape.maxX = x end
        if y < shape.minY then shape.minY = y end
        if y > shape.maxY then shape.maxY = y end
      end
    end
  end
    
  return shape
end

function isShapeColliding(x, y)
  local minX = -shape.minX + 1
  local minY = -shape.minY + 1
  local maxX = areaWidth - shape.maxX
  local maxY = areaHeight - shape.maxY
  if x < minX then return true end
  if y < minY then return true end
  if x > maxX then return true end
  if y > maxY then return true end
  
  
  for j = 1, shape.length do
    for i = 1, shape.length do
      if shape.data[j][i] == 1 then
        local px = x + i
        local py = y + j
        
        if px >= 1 and px <= areaWidth and py >= 1 and py <= areaHeight and blocks[py][px] > 0 then
          return true
        end
      end
    end
  end
  
  return false
end

function love.keyreleased(key)
  if key == "escape" then love.event.quit() end
  if key == "return" and gameOver then restart() end
  if key == "r" then restart() end
  
  if key == "up" then
    
    local oldShapePosX = shapePosX
    local oldShapePosY = shapePosY
    local oldShapeType = shape.type
    local oldShapeRot = shape.rot
    
    shape.rot = shape.rot + 1
    if shape.rot > 4 then shape.rot = 1 end
    shape = createShape(shape.type, shape.rot)
  
    local minX = -shape.minX + 1
    local minY = -shape.minY + 1
    local maxX = areaWidth - shape.maxX
    local maxY = areaHeight - shape.maxY
    if shapePosX < minX then shapePosX = minX end
    if shapePosY < minY then shapePosY = minY end
    if shapePosX > maxX then shapePosX = maxX end
    if shapePosY > maxY then shapePosY = maxY end
  
    if isShapeColliding(shapePosX, shapePosY) then
      shape = createShape(oldShapeType, oldShapeRot)
      shapePosX = oldShapePosX
      shapePosY = oldShapePosY
    end
  end

  if key == "space" then
    shapeFall = 0
    
    while not isShapeColliding(shapePosX, shapePosY + 1) do
      shapePosY = shapePosY + 1
      score = score + 10
    end
    
    saveShape()
    markBlocks()
    resetShape()
  end
end

function love.update(dt)
  if gameOver then return end
  
  controlTimer = controlTimer + dt
  if controlTimer >= controlInterval then
    controlTimer = 0
    
    if love.keyboard.isDown("left") and not isShapeColliding(shapePosX - 1, shapePosY) then
      shapePosX = shapePosX - 1
    end
    
    if love.keyboard.isDown("right") and not isShapeColliding(shapePosX + 1, shapePosY) then
      shapePosX = shapePosX + 1
    end

    if love.keyboard.isDown("down") and not isShapeColliding(shapePosX, shapePosY + 1) then
      shapePosY = shapePosY + 1
    end
  end

  collectTimer = collectTimer + dt
  if collectTimer >= collectInterval then
    collectTimer = 0
    collectBlocks()
  end
  
  timer = timer + dt
  while timer >= interval do
    timer = timer - interval
    
    shapeFall = shapeFall + 1
    if shapeFall >= 20  then
      shapeFall = 0
      
      if isShapeColliding(shapePosX, shapePosY + 1) then
        saveShape()
        markBlocks()
        resetShape()
      else
        shapePosY = shapePosY + 1
      end
    end
  end
end

function drawBlock(t, x, y)
  love.graphics.setColor(colors[t][1] , colors[t][2] , colors[t][3] )
  love.graphics.rectangle("fill", blockSize * x, blockSize * y, blockSize, blockSize)
end

function drawShape(s, x, y)  
  for j = 1, s.length do
    for i = 1, s.length do
      if s.data[j][i] == 1 then drawBlock(s.type, x + i - 1, y + j - 1) end
    end
  end
end

function drawArea()
  for j = 1, areaHeight do
    for i = 1, areaWidth do
      if blocks[j][i] == 0 then
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", blockSize * (i - 1) , blockSize * (j - 1) , blockSize , blockSize )
      else
        drawBlock(blocks[j][i], i - 1, j - 1)
      end
    end
  end
end

function love.draw()
  if gameOver then
    local sw, sh = love.graphics.getDimensions()
    local sw2, sh2 = sw / 2, sh / 2
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("GAME OVER!", 0, sh2 - blockSize * 3.5, sw, "center")
    love.graphics.printf("Press ENTER to restart!", 0, sh2 + blockSize * 2.5, sw, "center")
  else
    drawArea()
    drawShape(shape, shapePosX, shapePosY)
  end
end