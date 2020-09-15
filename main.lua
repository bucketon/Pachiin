function love.load()
	math.randomseed(os.time())
	love.graphics.setBackgroundColor(1, 1, 1, 1)
	pegAsset = love.graphics.newImage("assets/peg.png")
	board = require('daruma')
	xspeed = 0.0
	yspeed = 0.0
	local spacing = 8
	pegs = {}
	for i=1,#board.pegs do
		local peg = board.pegs[i]
		pegs[#pegs+1] = {image = peg.image, x = peg.x + 100, y = peg.y + 40}
		pegs[#pegs+1] = {image = peg.image, x = 300 - peg.x, y = peg.y + 40}
	end
	pegs[#pegs+1] = {image = pegAsset, x = 245, y = 38}
	local segments = 100
	local startRadius = 110
	local endRadius = 100
	local xoffset = 200
	local yoffset = 130
	lines = {}
	for i=1,segments do
		local increment = 2.7*math.pi/segments
		local startAngle = i*increment+math.pi/2
		local endAngle = (i+1)*increment+math.pi/2
		local radius = lerp(startRadius, endRadius, i/segments)
		lines[i] = {x1 = radius*math.cos(startAngle)+xoffset, y1 = radius*math.sin(startAngle)+yoffset, 
		x2 = radius*math.cos(endAngle)+xoffset, y2 = radius*math.sin(endAngle)+yoffset}
	end
	ball = {image = love.graphics.newImage("assets/ball.png"), x = 200, y = 235}
	xspeed = -15
	yspeed = -4
	holes = {}
	holes[1] = {image = love.graphics.newImage("assets/hole.png"), x = 200, y = 228,
		method = function(ball)
			ball.y = 250
			ball.x = 0
		end
	}
	gravity = 0.2
	debugLog = ""
	closest = nil
end

function love.keypressed(key, scancode, isrepeat)
	if key == "z" then
		ball.x = 200
		ball.y = 235
		xspeed = -15+math.random(40)/10.0
		yspeed = -4
	end
end

function love.update(dt)
	local physicsResolution = 10
	for p=1,physicsResolution do
		yspeed = yspeed + gravity/physicsResolution
		ball.x = ball.x + xspeed/physicsResolution
		ball.y = ball.y + yspeed/physicsResolution
		for i=1,#pegs do
			if hitTest(ball, pegs[i]) then
				local normalVector = {x = pegs[i].x - ball.x, y = pegs[i].y - ball.y}
				if angle({x = xspeed, y = yspeed}, normalVector) < 0 then
					normalVector = {x = -normalVector.x, y = -normalVector.y}
				end
				local reflection = reflect({x = xspeed, y = yspeed}, normalVector)
				xspeed = reflection.x*0.85
				yspeed = reflection.y*0.85
				local length =  magnitude(normalVector)
				local overlap = length - ball.image:getWidth()/2 - pegs[i].image:getWidth()/2
				local offset = {x = overlap*normalVector.x/length, y = overlap*normalVector.y/length}
				ball.x = ball.x + offset.x
				ball.y = ball.y + offset.y
			end
		end
		for i=1,#lines do
			local hit = false
			hit, closest = hitTestLine(ball, lines[i])
			if hit then
				local normalVector = {x = closest.x - ball.x, y = closest.y - ball.y}
				if angle({x = xspeed, y = yspeed}, normalVector) < 0 then
					normalVector = {x = -normalVector.x, y = -normalVector.y}
				end
				local reflection = reflect({x = xspeed, y = yspeed}, normalVector)
				local length = magnitude(normalVector)
				local velocity = magnitude({x = xspeed, y = yspeed})
				local direction = {x = xspeed/velocity, y = yspeed/velocity}
				local unit = {x = normalVector.x/length, y =  normalVector.y/length}
				local perpendicular = dot(direction, unit)

				xspeed = reflection.x * 0.99
				yspeed = reflection.y * 0.99
				
				local overlap = length - ball.image:getWidth()/2
				local offset = {x = overlap*normalVector.x/length, y = overlap*normalVector.y/length}
				ball.x = ball.x + offset.x
				ball.y = ball.y + offset.y
			end
		end
		for i=1,#holes do
			if hitTest(ball, holes[i]) and magnitude({x = xspeed, y = yspeed}) <= 3 then
				holes[i].method(ball)
			end
		end
	end
end

function love.draw()
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.draw(ball.image, ball.x, ball.y, 0, 1, 1, 
		ball.image:getWidth()/2, ball.image:getHeight()/2)
	for i=1,#pegs do
		love.graphics.draw(pegs[i].image, pegs[i].x, pegs[i].y, 0, 1, 1, 
			pegs[i].image:getWidth()/2, pegs[i].image:getHeight()/2)
	end
	love.graphics.setColor(0, 0, 0, 1)
	for i=1,#lines do
		love.graphics.line(lines[i].x1, lines[i].y1, lines[i].x2, lines[i].y2)
	end
	for i=1,#holes do
		love.graphics.draw(holes[i].image, holes[i].x, holes[i].y, 0, 1, 1, 
			holes[i].image:getWidth()/2, holes[i].image:getHeight()/2)
	end
	love.graphics.print(debugLog, 0, 0)
end

function hitTest(left, right)
	return math.sqrt((left.x-right.x)*(left.x-right.x)+(left.y-right.y)*(left.y-right.y)) < 
	left.image:getWidth()/2+right.image:getWidth()/2
end

function hitTestLine(ball, line)
	local deltax = line.x2-line.x1
	local deltay = line.y2-line.y1
	local len = magnitude({x = deltax, y = deltay})
	local dot = dot({x = ball.x-line.x1, y = ball.y-line.y1}, {x = deltax, y = deltay})/(len*len);
	local closest = {x = line.x1 + (dot * deltax), y = line.y1 + (dot * deltay)}
	local distance = magnitude({x = ball.x - closest.x, y = ball.y - closest.y})
	local radius = ball.image:getWidth()/2
	local isWithinSegment = 
	math.min(line.x1, line.x2, closest.x) ~= closest.x and
	math.max(line.x1, line.x2, closest.x) ~= closest.x and
	math.min(line.y1, line.y2, closest.y) ~= closest.y and
	math.max(line.y1, line.y2, closest.y) ~= closest.y
	return distance < radius and isWithinSegment, closest
end

function normalize(vec)
	local len = magnitude(vec)
	return {x = vec.x/len, y = vec.y/len}
end

function lerp(startValue, endValue, t)
	return (endValue - startValue)*t + startValue
end

function dot(left, right)
	return left.x*right.x + left.y*right.y
end

function magnitude(vec)
	return math.sqrt(vec.x*vec.x+vec.y*vec.y)
end

function angle(left, right)
	return dot(left, right)/(magnitude(left)*magnitude(right))
end

function reflect(vec, normal)
	--r=d−2(d⋅n)n
	local normalizedNormal = normalize(normal)
	local dotProduct = dot(vec, normalizedNormal)
	local scaledNormal = {x = 2*dotProduct*normalizedNormal.x, y = 2*dotProduct*normalizedNormal.y}
	return {x = vec.x - scaledNormal.x, y = vec.y - scaledNormal.y}
end	
