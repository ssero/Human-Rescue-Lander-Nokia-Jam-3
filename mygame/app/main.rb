#$gtk.reset # helper for testing certain things fast early in development

##################################################################
# GLOBAL CONSTANTS / VARIABLES

BRIGHT = [199,240,216]
DARK = [67,82,61]

##################################################################
# MAIN LOOP


def tick args

	
	##################################################################
	# VARIABLES and INITIALIZATION


	args.state.scene ||= :title
	args.state.game_mode ||= :playing
	args.state.gameover_tick ||= 0
	gameover_wait_time = 180

	args.state.title_offset ||= 0

	args.state.camera_x ||= 0
	args.state.camera_y ||= 0
	args.state.screenshake ||= 0
	args.state.cargo_shake ||= 0

	args.state.player_x ||= 150
	args.state.player_y ||= 3
	args.state.player_dy ||= 0.5
	args.state.player_dx ||= 0
	args.state.player_angle ||= 0
	args.state.player_health ||= 1
	args.state.player_destroyed ||= false
	args.state.player_cargo ||= 0
	args.state.player_cargo_size ||= 2
	args.state.player_firing = false

	args.state.particles ||= []
	args.state.circle_particles ||= []
	args.state.cargo ||= []
	args.state.repair ||= []

	args.state.level_time ||= 30
	args.state.time_left ||= args.state.level_time
	args.state.level ||= 1
	args.state.cargo_per_level ||= 3

	crash_speed = 0.8
	ship_tilt_angle = 13
	gravity = 0.04
	air_friction = 0.97


	if args.state.tick_count == 0
		for i in 0...$args.state.cargo_per_level
			spawn_cargo 150+rand*280-140,150+rand*140-70
		end
		args.state.repair << {
			world_x: 10,
			world_y: 266,
			collected: false
		}
		args.state.repair << {
			world_x: 290,
			world_y: 9,
			collected: false
		}
	end


	##################################################################
	# INPUTS

	case args.state.scene
	when :title
		if args.inputs.keyboard.key_down.up or args.inputs.keyboard.key_down.left or args.inputs.keyboard.key_down.right or args.inputs.keyboard.key_down.enter or args.inputs.keyboard.key_down.space or args.inputs.keyboard.key_down.escape
			args.inputs.clear
			args.state.scene = :game
		end
	
	when :game
		case args.state.game_mode
		
		when :playing
			if args.inputs.keyboard.key_held.up
				args.state.player_dy += 0.075
				args.state.player_firing = true
			end
			
			if args.inputs.keyboard.key_held.left
				args.state.player_dx -= 0.1 if args.state.player_firing
				args.state.player_angle = ship_tilt_angle
			end

			if args.inputs.keyboard.key_held.right
				args.state.player_dx += 0.1 if args.state.player_firing
				args.state.player_angle = -ship_tilt_angle
			end

		when :gameover
			if args.state.tick_count >= args.state.gameover_tick + gameover_wait_time
				if args.inputs.keyboard.key_down.up or args.inputs.keyboard.key_down.left or args.inputs.keyboard.key_down.right or args.inputs.keyboard.key_down.enter or args.inputs.keyboard.key_down.space or args.inputs.keyboard.key_down.escape
					args.inputs.clear
					args.state.game_mode = :restart
				end
			end

		end
	end


	##################################################################
	# CALCULATIONS


	case args.state.scene
	
	when :title
		args.state.title_offset = Math.cos(args.state.tick_count/200)*100
	
	when :game
		args.state.time_left -= 1/60 if args.state.game_mode == :playing

		args.state.player_angle = args.state.player_angle * 0.9

		args.state.player_x += args.state.player_dx
		args.state.player_dx *= air_friction

		args.state.player_dy -= gravity
		args.state.player_y += args.state.player_dy

		player_speed = Math.sqrt(0.125*args.state.player_dx*args.state.player_dx+args.state.player_dy*args.state.player_dy)

		play_explosion = false

		if args.state.player_y <= 0
			if args.state.player_dy.abs > 0.3
				if player_speed > crash_speed
					args.state.player_health -= player_speed * 0.1
					args.state.screenshake = 5
					create_explosion(args.state.player_x,args.state.player_y,1)
					if args.state.player_health <= 0 and not args.state.player_destroyed
						play_explosion = true
						args.state.player_destroyed = true
					end
				end
				args.state.player_y = 0
				args.state.player_dy = -args.state.player_dy * 0.5
				args.state.player_dx *= 0.5

				if player_speed > crash_speed
					args.audio[:sfx] = {
						input: 'sounds/sfx_bump_hard.wav',
						looping: false
					}
				else
					args.audio[:sfx] = {
						input: 'sounds/sfx_bump_soft.wav',
						looping: false
					}
				end
				if play_explosion
					args.audio[:sfx] = {
							input: 'sounds/sfx_explosion.wav',
							looping: false
					}
				end
			elsif			
				args.state.player_y = 0
				args.state.player_dy = 0
				args.state.player_dx = 0
				args.state.player_angle = 0
			end
		end

		if args.state.player_y > 279
			args.state.player_y = 279
			args.state.player_dy = 0
		end
		
		if args.state.player_x < 6
			args.state.player_x = 6 
			args.state.player_dx = 0
		end

		if args.state.player_x > 293
			args.state.player_x = 293 
			args.state.player_dx = 0
		end

		if args.state.player_health <= 0 and args.state.game_mode == :playing
			args.state.player_health = 0
			gameover
		end

		if args.state.player_y.floor.to_i == 0 and args.state.player_speed.floor.to_i == 0 and args.state.player_cargo > 0
			if args.state.player_x > 139 and args.state.player_x < 161
				for i in 1..args.state.player_cargo
					spawn_circle_particle 151+rand*12-6,10+rand*12-6,1/40
				end
				args.state.player_cargo = 0
				if args.state.cargo.length == 0 and args.state.game_mode == :playing
					args.state.game_mode = :win
				end
				if args.audio[:sfx] == nil
					args.audio[:sfx] = {
						input: 'sounds/sfx_pickup.wav',
						looping: false
					}
				end
			end
		end


		args.state.particles.each do |p|
			p[:age] -= 1/60
			p[:dx] *= air_friction
			p[:world_x] += p[:dx]
			p[:dy] -= gravity
			p[:world_y] += p[:dy]

			if p[:world_y] < 0
				p[:world_y] = 0
				p[:dy] = -p[:dy]*0.9
			end
		end

		args.state.particles.reject! do |p|
			p[:age] <= 0
		end

		args.state.circle_particles.each do |p|
			p[:age] += p[:speed]
		end

		args.state.circle_particles.reject! do |p|
			p[:age] < 0 or p[:age] > 1
		end

		args.state.cargo.each do |c|
			dx = args.state.player_x - c[:world_x]
			dy = (args.state.player_y + 8) - c[:world_y]
			distance = Math.sqrt(dx*dx+dy*dy)
			if distance <= 13 and not c[:collected]
				if args.state.player_cargo < args.state.player_cargo_size
					c[:collected] = true
					args.state.player_cargo += 1
					spawn_circle_particle c[:world_x],c[:world_y],-1/30
					args.audio[:sfx] = {
							input: 'sounds/sfx_pickup.wav',
							looping: false
					}
				else
					args.state.cargo_shake = 4
					if args.audio[:sfx] == nil
						args.audio[:sfx] = {
								input: 'sounds/sfx_reject.wav',
								looping: false
						}
					end
				end
			end
			#args.render_target(:nokia_canvas).lines << [-args.state.camera_x+c[:world_x],-args.state.camera_y+c[:world_y],-args.state.camera_x+args.state.player_x,-args.state.camera_y+10+args.state.player_y]
		end

		args.state.cargo.reject! do |c|
			c[:collected] == true
		end

		args.state.repair.each do |r|
			dx = args.state.player_x - r[:world_x]
			dy = (args.state.player_y + 8) - r[:world_y]
			distance = Math.sqrt(dx*dx+dy*dy)
			if distance <= 13 and not r[:collected]
				if args.state.player_health < 1
					r[:collected] = true
					args.state.player_health += 0.7
					args.state.player_health = 1 if args.state.player_health > 1
					spawn_circle_particle r[:world_x],r[:world_y],1/30
					args.audio[:sfx] = {
						input: 'sounds/sfx_pickup.wav',
						looping: false
					}
				end
			end
		end

		args.state.repair.reject! do |r|
			r[:collected] == true
		end

		if args.state.time_left <= 0 and args.state.game_mode == :playing
			args.state.time_left = 0
			args.audio[:sfx] = {
				input: 'sounds/sfx_timeout.wav',
				looping: false
			}
			gameover
		end

		args.state.camera_x = args.state.player_x - 42
		args.state.camera_y = args.state.player_y - 12

		args.state.camera_x = 0 if args.state.camera_x < 0
		args.state.camera_x = 300-84 if args.state.camera_x > 300-84
		args.state.camera_y = -5 if args.state.camera_y < -5
		args.state.camera_y = 246 if args.state.camera_y > 246

		args.state.camera_x += rand * args.state.screenshake * 2 - args.state.screenshake
		args.state.camera_y += rand * args.state.screenshake * 2 - args.state.screenshake
		args.state.screenshake *= 0.5
		args.state.cargo_shake *= 0.5
	end
	

	##################################################################
	# RENDERING


	case args.state.scene
	
	when :title
		args.render_target(:nokia_canvas).solids << [0,0,320,240,*DARK]
		args.render_target(:nokia_canvas).sprites << [-100+args.state.title_offset,-200,300,300,'sprites/map.png']
		args.render_target(:nokia_canvas).sprites << {
			x: 60,
			y: 16,
			w: 15,
			h: 17,
			path: 'sprites/player_ship.png',
			angle: 0,
			angle_anchor_x: 0.5,
			angle_anchor_y: 0
		}
		args.render_target(:nokia_canvas).sprites << {
			x: 62,
			y: 11,
			w: 11,
			h: 7,
			path: "sprites/player_ship_flame_#{args.state.tick_count.div(2).mod(3)}.png",
			angle: 0,
			angle_anchor_x: 0.5,
			angle_anchor_y: 1
		}
		args.render_target(:nokia_canvas).sprites << [0,0,84,48,'sprites/ui_title.png']
	
	when :game
		args.render_target(:nokia_canvas).solids << [0,0,320,240,*DARK]
		args.render_target(:nokia_canvas).sprites << [-args.state.camera_x,-args.state.camera_y-6,300,300,'sprites/map.png']

		args.render_target(:nokia_canvas).sprites << args.state.cargo.map do |c|  
			{
				x: -args.state.camera_x - 6 + c[:world_x],
				y: -args.state.camera_y - 6 + c[:world_y],
				w: 12,
				h: 12,
				path: 'sprites/cargo_bubble.png',
			}
		end

		tick_offset = 0
		args.render_target(:nokia_canvas).sprites << args.state.cargo.map do |c|  
			tick_offset += 13
			{
				x: -args.state.camera_x - 3 + c[:world_x],
				y: -args.state.camera_y - 3 + c[:world_y],
				w: 5,
				h: 5,
				path: 'sprites/cargo_human.png',
				angle: Math.sin( (args.state.tick_count+tick_offset) / 9 ) * 30
			}
		end

		args.render_target(:nokia_canvas).sprites << args.state.repair.map do |r|  
			{
				x: -args.state.camera_x - 7 + r[:world_x],
				y: -args.state.camera_y - 7 + r[:world_y],
				w: 14,
				h: 14,
				path: 'sprites/repair.png',
				angle: args.state.tick_count*2
			}
		end

		ship_sprite = 'sprites/player_ship_landing.png'
		ship_sprite = 'sprites/player_ship.png' if player_speed > crash_speed
		ship_sprite = 'sprites/player_ship_destroyed.png' if args.state.player_health <= 0
		args.render_target(:nokia_canvas).sprites << {
			x: -args.state.camera_x+args.state.player_x-7,
			y: -args.state.camera_y+args.state.player_y-1,
			w: 15,
			h: 17,
			path: ship_sprite,
			angle: args.state.player_angle,
			angle_anchor_x: 0.5,
			angle_anchor_y: 0
		}
		if args.state.player_firing
			args.render_target(:nokia_canvas).sprites << {
					x: -args.state.camera_x+args.state.player_x-5,
					y: -args.state.camera_y+args.state.player_y-6,
					w: 11,
					h: 7,
					path: "sprites/player_ship_flame_#{args.state.tick_count.div(2).mod(3)}.png",
					angle: args.state.player_angle,
					angle_anchor_x: 0.5,
					angle_anchor_y: 1
				}
		end

		args.state.cargo.each do |c|
			dx = c[:world_x] - args.state.player_x
			dy = c[:world_y] - (args.state.player_y + 8)

			angle = Math.atan2(dy,dx)
			d = 10
			ax = -args.state.camera_x + args.state.player_x + Math.cos(angle) * d
			ay = -args.state.camera_y + args.state.player_y + 7 + Math.sin(angle) * d

			args.render_target(:nokia_canvas).sprites << {
				x: ax,
				y: ay,
				w: 6,
				h: 6,
				path: 'sprites/ui_cargo_arrow.png',
			}
		end

		args.render_target(:nokia_canvas).sprites << args.state.circle_particles.map do |p|  
			size = 29*p[:age]
			{
				x: -args.state.camera_x + p[:world_x] - size / 2,
				y: -args.state.camera_y + p[:world_y] - size / 2,
				w: size,
				h: size,
				path: 'sprites/circle_particle.png',
			}
		end

		args.render_target(:nokia_canvas).sprites << args.state.particles.map do |p|  
			{
				x: -args.state.camera_x-1 + p[:world_x],
				y: -args.state.camera_y-1 + p[:world_y],
				w: 3,
				h: 3,
				path: 'sprites/pixel_particle.png',
			}
		end

		args.render_target(:nokia_canvas).sprites << [1,38,82,9,'sprites/ui_status.png']
		
		# time
		time_width = (27*args.state.time_left/args.state.level_time).ceil
		args.render_target(:nokia_canvas).sprites << {
					x: 4+27-time_width,
					y: 42,
					w: time_width,
					h: 2,
					path: 'sprites/ui_status_bar.png',
					angle_anchor_x: 1
				}
		# health
		args.render_target(:nokia_canvas).sprites << {
					x: 53,
					y: 42,
					w: 27*args.state.player_health,
					h: 2,
					path: 'sprites/ui_status_bar.png',
					angle_anchor_x: 0
				}


		#debug text
		#draw_number 1,31,args.state.level_time

		case args.state.game_mode
		when :playing
			args.render_target(:nokia_canvas).sprites << [1,1,25,7,'sprites/ui_level.png']
			draw_number 27,1,args.state.level
		when :gameover
			args.render_target(:nokia_canvas).sprites << [11,29,57,7,'sprites/ui_gameover.png']
			draw_number 69,29,args.state.level
			message_offset = 5*8
			message_offset = 4*8 if args.state.level >= 2
			message_offset = 3*8 if args.state.level >= 4
			message_offset = 2*8 if args.state.level >= 10
			message_offset = 1*8 if args.state.level >= 16
			message_offset = 0*8 if args.state.level >= 20
			args.render_target(:nokia_canvas).sprites << {
				x: 0,
				y: 20,
				w: 84,
				h: 8,
				path: 'sprites/ui_gameover_messages.png',
				source_x: 0,
				source_y: message_offset,
				source_w: 84,
				source_h: 8
			}
			if args.state.tick_count >= args.state.gameover_tick + gameover_wait_time
				args.render_target(:nokia_canvas).sprites << [15,2,55,16,'sprites/ui_retry.png']
			end
		end

		cargo_offset_x = rand * args.state.cargo_shake * 2 - args.state.cargo_shake
		cargo_offset_y = rand * args.state.cargo_shake * 2 - args.state.cargo_shake

		for i in 0...args.state.player_cargo_size
			cargo_sprite = 'sprites/ui_cargo_empty.png'
			cargo_sprite = 'sprites/ui_cargo_full.png' if args.state.player_cargo > i
			args.render_target(:nokia_canvas).sprites << [77-i*5+cargo_offset_x,1+cargo_offset_y,6,6,cargo_sprite]
		end

		# debug singlepixel
		#args.render_target(:nokia_canvas).sprites << [-args.state.camera_x+args.state.player_x,-args.state.camera_y+args.state.player_y+7,1,1,'sprites/singlepixel.png']
	end

	# render small nokia canvas in big
	args.outputs.sprites << {
		x:0,
		y:0,
		w:1280,
		h:720,
		path: :nokia_canvas,
		source_x: 0,
		source_y: 0,
		source_w: 84,
		source_h: 48
	}


	##################################################################
	# AUDIO


	if args.state.player_firing and args.audio[:thrusters] == nil
		args.audio[:thrusters] = {
			input: 'sounds/sfx_thrusters_loop.wav',
			looping: true
		}
	elsif (not args.state.player_firing and args.audio[:thrusters] != nil)
		args.audio[:thrusters] = nil
	end


	##################################################################
	# VARIOUS DEBUG and FINISHING THINGIES


	if args.state.game_mode == :win
		next_level
	end

	if args.state.game_mode == :restart
		args.state.player_health = 1
		args.state.level = 0
		args.state.cargo_per_level = 0
		next_level
	end

	# if args.inputs.keyboard.key_down.z
	# 	args.state.player_health = 0
	# end

	# if args.inputs.keyboard.key_down.e
	# 	args.state.time_left = args.state.level_time
	# end

	# if args.inputs.keyboard.key_down.u
	# 	next_level
	# end

	# if args.inputs.keyboard.key_down.r
	# 	$gtk.reset
	# end

	# if args.inputs.keyboard.key_down.t
	# 	$gtk.reset_sprite 'sprites/ui_title.png'
	# end

end


##################################################################
# VARIOUS FUNCTIONS


def spawn_cargo x,y
	$args.state.cargo << {
		world_x: x,
		world_y: y,
		collected: false
	}
end

def spawn_particle(x,y,dx,dy,age)
	$args.state.particles << {
		world_x: x,
		world_y: y,
		dx: dx,
		dy: dy,
		age: age
	}
end

def create_explosion(x,y,age)
	5.times do |i|
		speed_x = 1
		speed_y = 1.2
		spawn_particle(x,y,rand*speed_x*2-speed_x,rand*speed_y,1)
	end
end

def spawn_circle_particle x,y,speed=1/60
	age = 0
	age = 1 if speed < 0

	$args.state.circle_particles << {
		world_x: x,
		world_y: y,
		speed: speed,
		age: age
	}
end

def gameover
	if $args.state.game_mode != :gameover
		$args.state.game_mode = :gameover
		$args.state.gameover_tick = $args.state.tick_count
	end
end

def draw_number x,y,draw_number
	numbers = draw_number.to_s
	sprites = []
	for i in 0...numbers.length()
		sprites << {
			x: x+4*i,
			y: y,
			w: 5,
			h: 7,
			path: 'sprites/ui_font_numbers.png',
			source_x: numbers[i].to_i*5,
			source_y: 0,
			source_w: 5,
			source_h: 7
		}
	end

	$args.render_target(:nokia_canvas).sprites << sprites
end

def next_level
	srand(rand*1000000000)
	$args.state.game_mode = :playing

	$args.state.level += 1
	$args.state.cargo_per_level += 3
	$args.state.cargo.clear

	$args.state.level_time = 30
	$args.state.level_time = 35 if $args.state.level >= 3
	$args.state.level_time = 40 if $args.state.level >= 4
	$args.state.level_time = 45 if $args.state.level >= 4
	$args.state.level_time = 50 if $args.state.level >= 5
	$args.state.level_time = 55 if $args.state.level >= 7
	$args.state.level_time = 60 if $args.state.level >= 8
	$args.state.level_time = 65 if $args.state.level >= 9
	$args.state.level_time = 70 if $args.state.level >= 13
	$args.state.level_time = 75 if $args.state.level >= 16
	$args.state.level_time = 80 if $args.state.level >= 17
	$args.state.level_time = 85 if $args.state.level >= 19
	$args.state.level_time = 90 if $args.state.level >= 20
	$args.state.time_left = $args.state.level_time
	
	$args.state.player_cargo_size = 2
	$args.state.player_cargo_size = 3 if $args.state.level >= 3
	$args.state.player_cargo_size = 4 if $args.state.level >= 6
	$args.state.player_cargo_size = 5 if $args.state.level >= 10
	$args.state.player_cargo_size = 6 if $args.state.level >= 12
	$args.state.player_cargo_size = 7 if $args.state.level >= 15
	$args.state.player_cargo_size = 8 if $args.state.level >= 17
	$args.state.player_cargo_size = 9 if $args.state.level >= 19

	$args.state.player_x = 150
	$args.state.player_y = 3
	$args.state.player_dy = 0.5
	$args.state.player_dx = 0
	$args.state.player_angle = 0
	$args.state.player_destroyed = false
	$args.state.player_cargo = 0

	for i in 0...$args.state.cargo_per_level
		spawn_cargo 150+rand*280-140,150+rand*140-70
	end

	$args.audio[:sfx] = {
		input: 'sounds/sfx_next_level.wav',
		looping: false
	}
end
