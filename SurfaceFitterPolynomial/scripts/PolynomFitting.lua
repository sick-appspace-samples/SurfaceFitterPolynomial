
--Start of Global Scope---------------------------------------------------------
local thicknessThreshold = 0.2
local minObjectSize = 20

local surfaceFitter = Image.SurfaceFitter.create()
surfaceFitter:setFitMode("RANSAC")
surfaceFitter:setOutlierMargin(thicknessThreshold)

-- Create a viewer
local viewer = View.create("viewer2D1")
local hmDeco = View.ImageDecoration.create()

--End of Global Scope-----------------------------------------------------------

--Start of Function and Event Scope---------------------------------------------

local function main()
  
  -- Load image
  local image = Object.load('resources/twoObjects.json')
  
  -- Find objects
  local zIm = image[1]    -- Heigth
  local im = image[2]     -- Intensity

  ----------------------------------------------
  -- Find tray region
  local imMedian = Image.getMedian(zIm)
  local roughTrayThreshold = 2   -- Rough height threshold to extract tray region
  local trayRegion = Image.threshold(zIm, imMedian + roughTrayThreshold)

  print("Heightmap with tray.")
  hmDeco:setRange(314, 323)
  viewer:clear()

  viewer:addHeightmap(zIm, hmDeco)
  viewer:present()
  Script.sleep(2000)

  ---------------------------------------------
  -- Crop image. Only keep tray parts
  print("Cutting out tray part.")
  local outsideTray = Image.PixelRegion.invert(trayRegion, zIm)
  local Orig = zIm:getOrigin()
  Image.fillRegionInplace(zIm, outsideTray, Point.getZ(Orig))
  zIm, trayRegion = Image.cropRegion(zIm, trayRegion)

  ---------------------------------------------
  -- Try fitting plane to tray region
  print("Try subtracting plane from tray.")
  surfaceFitter:setFitMode("RANSAC")
  local plane = surfaceFitter:fitPlane(zIm, trayRegion)
  local imDiff = Image.subtractPlane(zIm, plane, trayRegion, true)
  
  hmDeco:setRange(-2, 4)
  viewer:clear()
  viewer:addHeightmap(imDiff, hmDeco)
  viewer:present()
  Script.sleep(2000)

  ---------------------------------------------
  -- Fit polynom instead
  print("Try subtracting polynom instead.")
  surfaceFitter:setFitMode("RANSAC")
  local poly = surfaceFitter:fitPolynomial(zIm, trayRegion)
  imDiff = Image.subtractPolynomial(zIm, poly, trayRegion, true)

  hmDeco:setRange(-2, 4)
  viewer:clear()
  viewer:addHeightmap(imDiff, hmDeco)
  viewer:present()
  Script.sleep(2000)

  ---------------------------------------------
  -- Segment objects from tray
  local regions = imDiff:threshold(thicknessThreshold, nil, trayRegion)
  local objRegions = Image.PixelRegion.findConnected(regions, minObjectSize)

  viewer:clear()
  local imId = viewer:addHeightmap(imDiff, hmDeco)
  viewer:addPixelRegion(objRegions, nil, nil, imId)
  viewer:present()
  Script.sleep(2000)
  
  print('App finished.')
end
--The following registration is part of the global scope which runs once after startup
--Registration of the 'main' function to the 'Engine.OnStarted' event
Script.register("Engine.OnStarted", main)
--End of Function and Event Scope--------------------------------------------------
