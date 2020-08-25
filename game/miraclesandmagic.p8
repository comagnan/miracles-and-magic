pico-8 cartridge // http://www.pico-8.com
version 29
__lua__
-- miracles and magic
-- by comagnan

actors = {}

old_x_press, old_o_press = true, false
intro_played = false

fog_min_size, fog_max_size = 2, 10

is_text_shown = false
old_text_shown = false

old_is_boss_fight = false
is_boss_fight = false
is_fog_mode = false
current_boss_health = 0
player_max_hp, player_max_mp = 9, 50

first_boss_tile_positions = {{19, 7}, {28, 10}, {20, 10}, {23, 11}, {26, 7}}
second_boss_tile_positions = {{90, 35}, {83, 40}, {92, 44}, {83, 43}, {88, 35}}
third_boss_tile_positions = {{98, 45}, {100, 43}, {107, 45}, {109, 43}, {108, 35}, {98, 34}}

all_keys = {}
all_doors = {}

wall, damage, pit, text, fog, death = 0, 1, 3, 4, 6, 7
control, enemy, turret, bullet, bouncy_bullet, npc, boss, door, mana_tile, key = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
skelly, mutant, christopher = 0, 1, 2
basic_l, basic_r, basic_u, basic_d, count_clock, clockw, basic_c, cross_turret, aim_turret = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9
pl_spr, pl_roll, pl_aura = 48, 54, 61

function _init()
    player = make_actor(0, 0, 48, 2, control)
    create_doors()
    dtb_init()
    reset_palette()
    reset_bullet = {420, 420}

    -- disable rapid fire buttons.
    poke(0x5f5d,255)
    spawn_point = {8, 59}
    old_room_id = 0

    _update_method = update_game_start
    _draw_method = draw_start_screen
end

function reset_palette()
    is_fog_mode = false
    pal() -- reset
    palt(2, true) -- purple as transparent
    palt(0, false) -- black as opaque
end

function game_start()
    if fog_mode == false then
        reset_palette()
    end
    actors = {}
    player = make_actor(spawn_point[1], spawn_point[2], pl_spr, 2, control)
    player.hp = player_max_hp
    player.mp = player_max_mp
    player.is_attacking = false
    friend = make_actor(5, 58, 51, 1, npc)

    make_turret(12, 51, basic_l, 0.2, 30)
    make_turret(5, 38, basic_r, 0.3, 30)
    make_turret(21, 33, basic_d, 0.15, 45)
    make_turret(20, 54, count_clock, 0.1, 180)
    make_turret(27, 54, clockw, 0.1, 180)
    make_turret(29, 44, basic_l, 0.4, 4)
    make_turret(6, 21, basic_c, 0.15, 50)
    make_turret(8, 25, basic_c, 0.15, 50)
    make_turret(86, 25, basic_r, 0.2, 50)
    make_turret(92, 27, basic_u, 0.2, 50)
    make_turret(84, 22, basic_r, 0.2, 50)
    make_turret(33, 17, cross_turret, 0.2, 8)
    make_turret(36, 20, cross_turret, 0.2, 8)
    make_turret(41, 25, cross_turret, 0.2, 8)
    make_turret(44, 28, cross_turret, 0.2, 8)
    make_turret(51, 35, count_clock, 0.2, 120)
    make_turret(61, 41, clockw, 0.2, 120)
    make_turret(87, 10.5, basic_u, 0.2, 50)
    make_turret(88, 10.5, basic_u, 0.2, 50)
    make_turret(52, 53, basic_d, 0.2, 4)
    make_turret(53, 53, basic_d, 0.2, 4)
    make_turret(59.5, 58, basic_u, 0.2, 16)
    make_turret(67, 59, cross_turret, 0.15, 30)
    make_turret(72, 55, aim_turret, 0.1, 30)
    make_turret(86, 57, cross_turret, 0.15, 30)

    make_bullet(57.5, 17, 0, -0.5, bouncy_bullet)
    make_bullet(61, 17.5, 0.5, 0, bouncy_bullet)
    make_bullet(83, 54, 0.1, 0.1, bouncy_bullet)

    make_boss(23.5, 2, 24, 15, 45, 0, 3, 100, skelly, first_boss_tile_positions)
    make_boss(88, 40, 80.5, 40, 46, 0, 4, 120, mutant, second_boss_tile_positions)
    make_boss(103.5, 38.5, 103.5, 46, 47, 0, 5, 120, christopher, third_boss_tile_positions)

    current_fog_size = fog_min_size
    player.dodging = false
    player.invincible = false

    _update_method = update_game
    _draw_method = draw_game
end

function _update()
	_update_method()
    dtb_update()
end

function update_game()
    -- freeze the game when reading text
    if #dtb_queu == 0 then
        is_boss_fight = false
        has_been_closed = false
        control_player(player)
        foreach(all_keys, move_actor)
        foreach(all_doors, move_actor)
        foreach(actors, move_actor)
        sort_actors()

        if player.hp <= 0 then
            game_over()
        end

        old_is_boss_fight = is_boss_fight
        update_on_room_change()
    end
end

function update_on_room_change()
    local current_room_id = room_id(player)
    if old_room_id != current_room_id then
        old_room_id = current_room_id
        old_text_shown = false

        spawn_point = {player.x - 0.5, player.y - 0.5}
    end
end

function update_game_start()
    if btnp(❎) and not intro_played then
        intro_played = true
        txt_wr("wait, wait, wait. we can't just begin like this. not without an introduction.", 0, 0)
        txt_wr("ahem...", 0, 0)
        txt_wr("our story begins long ago, before the age of machine.", 0, 0)
        txt_wr("to say it was an uncivilized time would not be fully accurate, however.", 0, 0)
        txt_wr("after centuries of harnessing mana, the earth's natural energy...", 0, 0)
        txt_wr("we had mastered its use to a point undistinguishable from technology.", 0, 0)
        txt_wr("for war and peace alike, mages and healers were always aplenty.", 0, 0)
        txt_wr("it was truly an age of magic and miracles.", 0, 0)
        txt_wr("alas... things took a turn after the new millennium.", 0, 0)
        txt_wr("spellweavers lost focus and strength.", 0, 0)
        txt_wr("hospital staff became patients in turn.", 0, 0)
        txt_wr("it was as if the earth itself was poisoning its people.", 0, 0)
        txt_wr("common folk, while so far unaffected, were losing their protectors by the day.", 0, 0)
        txt_wr("thus two knights set out to seal the leylines, severing our link with mana.", 0, 0)
        txt_wr("and, by doing so, change the land forever.", game_start, 0)
    end
end

function update_game_over()
    if btnp(❎) then
        game_start()
    end
end

function an_update_about_nothing()
    player.x = 0
    player.y = 0
end

function _draw()
    cls()
    _draw_method()
    dtb_draw()
end

function draw_game()
    draw_map()
    foreach(all_keys, draw_actor)
    foreach(actors, draw_actor)
    foreach(all_doors, draw_actor)

    if is_text_shown and not old_text_shown then
        read_sign(room_id(player))
        old_text_shown = true
    end

    draw_fog()
    draw_ui()
end

function draw_start_screen()
    centered_print("mIRACLES AND MAGIC", 50, 7)
    centered_print("pRESS ❎ TO START", 60, 7)
end

function draw_game_over()
    camera(0, 0)
    centered_print("game over", 50, 7)
    centered_print("pRESS ❎ TO TRY AGAIN", 60, 7)
end

function draw_ending()
    camera(0, 0)
    ovalfill(62, 52, 97, 68, 13)
    ovalfill(66, 54, 95, 66, 6)
    spr(89, 80, 52, 2, 2)
end

function draw_fin()
    camera(0, 0)
    centered_print("fin", 50, 7)
end

function draw_ui()
    local room_x = room_x(player) * 8
    local room_y = room_y(player) * 8
    spr(64, 0 + room_x, 0 + room_y, 3, 1)
    spr(80, 104 + room_x, 0 + room_y, 3, 1)
    if old_is_boss_fight then
        spr(96, 42 + room_x, 0 + room_y, 5, 1)
        if current_boss_health < 1 then
            rect_edge = ((1 - current_boss_health) * 37) + 43 + room_x
            rectfill(43 + room_x, 1 + room_y, rect_edge, 6 + room_y, 13)
        end
    end
    print(player.hp, 14 + room_x, 2 + room_y, 8)
    print(ceil(player.mp), 107 + room_x, 2 + room_y, 3)
end

-->8
--map code

function create_doors()
    all_keys = {}
    all_doors = {}
    door_1 = make_door(2, 41)
    key_1 = make_key(29, 62, door_1)

    --level two
    door_2 = make_door(70, 28)
    key_2 = make_key(34.5, 18.5, door_2)
    door_3 = make_door(70, 29)
    key_3 = make_key(53, 43.5, door_3)
    door_4 = make_door(70, 30)
    key_4 = make_key(86, 21, door_4)
    door_5 = make_door(70, 31)
    key_5 = make_key(87.5, 7.5, door_5)
end

function make_door(x, y)
    local door_actor = make_actor(x, y, 33, 0, door)
    door_actor.open = false
    return door_actor
end

function make_key(x, y, door_actor)
    local key_actor = make_actor(x, y, 41, 0, key)
    key_actor.door = door_actor
    return key_actor
end

function draw_map()	
    local room_x = room_x(player) * 8
    local room_y = room_y(player) * 8
    camera(room_x, room_y)
    -- allow full map editor to be used (instead of default 32 rows)
    map(0, 0, 0, 0, 128, 64)
end

function draw_fog()
    if is_fog_mode then
        if #dtb_queu == 0 then
            if old_o_press and player.mp > 0 then
                player.mp -= 0.2
                if current_fog_size < fog_max_size then
                    current_fog_size += 1
                end
            else
                if current_fog_size > fog_min_size then
                    current_fog_size -= 0.1
                end
            end
        end

        local x_p = flr(player.x + 0.1)
        local y_p = flr(player.y)
        
        local room_x=room_x(player)
        local room_y=room_y(player)

        for x=room_x, (room_x+15) do
            for y=room_y, (room_y+15) do
                if (abs(x - x_p) + abs(y - y_p)) > current_fog_size then
                    rectfill(x*8, y*8, (x*8) + 7, (y*8) + 7, 0)
                end
            end
        end
    end
end

function is_player_collision(x, y, w, h)
    local is_outside = player.x > x + w or
        player.x + player.width < x or
        player.y > y + h or
        player.y + player.height < y

    return not is_outside
end

function is_collision(x, y, w, h, tiletype)
    return is_type(x + w, y + h, tiletype) or
        is_type(x - w, y + h, tiletype) or
        is_type(x + w, y - h, tiletype) or
        is_type(x - w, y - h, tiletype)
end

function is_type(x, y, tiletype)
    tile=mget(x-0.1, y)

    -- ignore fog wall if boss battle not underway
    if fget(tile, fog) and not old_is_boss_fight then
        return false
    end

    -- check if the tile is the given type.
    return fget(tile, tiletype)
end

-->8
--actor code

function make_actor(x, y, sprite, max_frame, type)
    actor = {
        x = x + 0.5,
        y = y + 0.5,
        sprite = sprite,
        original_sprite = sprite,
        frame = 0.0,
        max_frame = max_frame,
        friction = 0.25,
        dx = 0,
        dy = 0,
        width = 0.4,
        height = 0.4,
        flip = false,
        type = type,
        invincibility_frames = 0
    }
    if type == key then
        add(all_keys, actor)
    elseif type == door then
        add(all_doors, actor)
    else
        add(actors, actor)
    end
    return actor
end

function make_mana_tile(boss)
    local location = rnd(boss.tile_positions)
    local new_tile = make_actor(location[1], location[2], 26, 1, mana_tile)
    new_tile.boss = boss
    boss.tiles += 1
    new_tile.mp = 20
    new_tile.width = 0.6
    new_tile.height = 0.6
end

function make_bullet(x, y, dx, dy, type)
    local new_bullet = make_actor(x, y, 38, 2, type)
    new_bullet.width = 0.2
    new_bullet.height = 0.2
    new_bullet.dx = dx
    new_bullet.dy = dy
    new_bullet.friction = 0
end

function make_turret(x, y, turret_type, speed, frequency)
    local new_turret = make_actor(x, y, 23, 0, turret)
    new_turret.turret_type = turret_type
    new_turret.speed = speed
    new_turret.frequency = frequency
    new_turret.bullet_pointer = frequency - 2
end

function make_boss(x, y, player_x, player_y, sprite, max_frame, phases, life, id, tile_positions)
    local new_boss = make_actor(x, y, sprite, max_frame, boss)
    new_boss.player_x = player_x
    new_boss.player_y = player_y
    new_boss.id = id
    new_boss.phases = phases
    new_boss.bullet_pointer = 1
    new_boss.maxlife = life
    new_boss.life = life
    new_boss.tiles = 0
    new_boss.delay_since_last_tile = 0
    new_boss.tile_positions = tile_positions
end

function draw_actor(actor)
    local screen_x = flr(actor.x * 8) - 4
    local screen_y = flr(actor.y * 8) - 4
    actor.frame += 0.25

    if actor == player then
        if player.dodging and player.frame > 0.25 and player.frame < 2.75 then
            player.invincible = true
        else
            player.invincible = false
        end
    end

    if actor.type == door then
        if actor.open then
            actor.sprite = actor.original_sprite + 1
        end
    end

    is_moving = ((actor.dx != 0) or (actor.dy != 0))
    if (flr(actor.frame) > actor.max_frame) or not(is_moving) then
        actor.frame = 0
        if actor == player and player.dodging then
            player.dodging = false
            player.sprite = pl_spr
        end
    end

    if actor.dx != 0 then
        actor.flip = actor.dx < 0
    end

    if actor.invincibility_frames % 2 == 0 then
        if actor.type == control and player.is_attacking then
            spr(pl_aura, screen_x, screen_y, 1, 1, actor.flip, false)
        end
        spr(actor.sprite + flr(actor.frame), screen_x, screen_y, 1, 1, actor.flip, false)
    end
end

function move_actor(a)
    if room_id(a) != room_id(player) then
        -- pop bullets that leave the screen
        if a.type == bullet then
            del(actors, a)
        end
        return
    end

    if a.type == turret then
        local bullet_pattern = get_turret_pattern(a)

        for i=1, #bullet_pattern do
            if bullet_pattern[i] == reset_bullet then
                a.bullet_pointer = 0
            elseif bullet_pattern[i][1] != 0 or bullet_pattern[i][2] != 0 then
                make_bullet(a.x - 0.5, a.y - 0.5, bullet_pattern[i][1], bullet_pattern[i][2], bullet)
            end
        end
        
        a.bullet_pointer += 1
    elseif a.type == boss then
        if not(old_is_boss_fight) then
            -- change player spawn to avoid getting stuck in fog
            player.x = a.player_x
            player.y = a.player_y
            spawn_point = {a.player_x, a.player_y}
            last_phase = 2
        end

        is_boss_fight = true
        current_boss_health = a.life / a.maxlife
        current_boss = a

        if current_boss_health > 0 then
            local boss_damage = 1 - current_boss_health
            local current_phase = max(ceil(boss_damage * a.phases), 1)
            if current_phase != last_phase then
                last_phase = current_phase
                phase_change_callback(a.id, current_phase)
            end

            local bullet_pattern = get_boss_bullets(a, current_phase, a.bullet_pointer)

            for i=1, #bullet_pattern do
                if bullet_pattern[i] == reset_bullet then
                    a.bullet_pointer = 0
                elseif bullet_pattern[i][1] != 0 or bullet_pattern[i][2] != 0 then
                    make_bullet(a.x - 0.5, a.y - 0.5, bullet_pattern[i][1], bullet_pattern[i][2], bullet)
                end
            end

            if a.tiles == 0 then
                if a.delay_since_last_tile > 14 then
                    make_mana_tile(a)
                    a.delay_since_last_tile = 0
                else
                    a.delay_since_last_tile += 1
                end
            elseif a.tiles == 1 then
                if a.delay_since_last_tile > 59 then
                    make_mana_tile(a)
                    a.delay_since_last_tile = 0
                else
                    a.delay_since_last_tile += 1
                end
            end

            a.bullet_pointer += 1
        else
            boss_defeat_callback(a.id)
        end
    elseif a.type == door then
        if a.open and not has_been_closed then
            -- unlock the door.
            fset(112, 0, false)
        elseif a.open == false then
            -- block people as long as the door is closed.
            fset(112, 0, true)
            has_been_closed = true
        end
    elseif a.type == mana_tile then
        if player.mp < player_max_mp and is_player_collision(a.x, a.y - 0.5, a.width, a.height) then
            player.mp += 0.5
            a.mp -= 0.5
            if a.mp <= 0 then
                a.boss.tiles -= 1
                del(actors, a)
            end
        end
    elseif a.type == key then
        if is_player_collision(a.x, a.y, a.width, a.height) then
            a.door.open = true
            sfx(4)
            del(all_keys, a)
        end
    else
        if a.invincibility_frames > 0 then
            a.invincibility_frames -= 1
        end

        if a.dx != 0 or a.dy != 0 then
            x_move, y_move = false, false
            local x_collision = is_collision(a.x + a.dx, a.y, a.width, a.height, wall)

            if a == player then
                x_collision = x_collision or is_collision(a.x + a.dx, a.y, a.width, a.height, pit)
            end

            if not (x_collision) then
                a.x += a.dx
                x_move = true
                if (a.type != control and a.type != bullet) or not player.dodging then
                    a.dx = apply_friction(a.dx, a.friction)
                end
            else
                if a == player then
                    is_text_shown = is_collision(a.x + a.dx, a.y, a.width, a.height, text)
                end

                if a.type == bullet then
                    del(actors, a)
                elseif a.type == bouncy_bullet then
                    a.dx = -1 * a.dx
                else
                    a.dx = 0
                end
            end

            local y_collision = is_collision(a.x, a.y + a.dy, a.width, a.height, wall)
            if a == player then
                y_collision = y_collision or is_collision(a.x, a.y + a.dy, a.width, a.height, pit)
            end

            if not (y_collision) then
                a.y += a.dy
                y_move = true
                if (a.type != control and a.type != bullet) or not player.dodging then
                    a.dy = apply_friction(a.dy, a.friction)
                end
            else
                if a == player then
                    if not is_text_shown then
                        is_text_shown = is_collision(a.x, a.y + a.dy, a.width, a.height, text)
                    end
                end

                if a.type == bullet then
                    del(actors, a)
                elseif a.type == bouncy_bullet then
                    a.dy = -1 * a.dy
                else
                    a.dy = 0
                end
            end

            if a == player and x_move and y_move then
                is_text_shown = false
            end
        end

        if a.type == bullet or a.type == bouncy_bullet then
            if is_player_collision(a.x, a.y, a.width, a.height) and not is_player_invincible() then
                player.dx += a.dx
                player.dy += a.dy
                player.hp -= 1
                player.invincibility_frames = 30
                sfx(3)
                if a.type == bullet then
                    del(actors, a)
                end
            end
        end
    end
end

function control_player(pl)
    check_current_tile(pl)

    left_press = button_press(⬅️)
    right_press = button_press(➡️)
    up_press = button_press(⬆️)
    down_press = button_press(⬇️)

    is_diagonal = (left_press + right_press) * (up_press + down_press)

    if is_diagonal == 1 then
        accel = 0.06
        max_speed = 0.25
    else
        accel = 0.08
        max_speed = 0.375
    end

    if not player.dodging then
        pl.dx += (accel * button_press(1)) - (accel * button_press(0))
        x_sign = pl.dx/abs(pl.dx)
        pl.dx = min(max_speed, abs(pl.dx)) * x_sign
        
        pl.dy += (accel * button_press(3)) - (accel * button_press(2))
        y_sign = pl.dy/abs(pl.dy)
        pl.dy = min(max_speed, abs(pl.dy)) * y_sign
    end

    x_press = btn(❎)

    if x_press then
        if not old_x_press then
            if not player.dodging and (player.dx != 0 or player.dy != 0) then
                player.frame = 0
                player.dodging = true
                player.sprite = pl_roll
                sfx(2)
            end
            old_x_press = true
        end
        if player.dx == 0 and player.dy == 0 and old_is_boss_fight and player.mp > 0 then
            player.is_attacking = true
            current_boss.life -= 0.25
            player.mp -= 0.5
        else
            player.is_attacking = false
        end
    else
        old_x_press = false
        player.is_attacking = false
    end

    o_press = btn(🅾️)

    if o_press then
        if not old_o_press then
            old_o_press = true
        end
    else
        old_o_press = false
    end
end

function check_current_tile(pl)
    if is_collision(pl.x, pl.y, pl.width/2, 2*pl.height/3, death) and not player.invincible then
        game_over()
    end
end

function button_press(id)
    return btn(id) and 1 or 0
end

function apply_friction(vector, friction)
    new_vector = vector * (1 - friction)

    if abs(new_vector) < 0.01 then
        return 0
    end

    return new_vector
end

function sort_actors()
    for i=1,#actors do
        local j = i
        while j > 1 and (actors[j].type == mana_tile or (actors[j-1].y > actors[j].y and actors[j-1].type != mana_tile)) do
            actors[j],actors[j-1] = actors[j-1],actors[j]
            j = j - 1
        end
    end
end

-->8
--rare events
function game_over()
    _update_method = update_game_over
    _draw_method = draw_game_over
    actors = {}
end

function black()
    _update_method = an_update_about_nothing
    _draw_method = camera
end

function resume()
    _update_method = update_game
    _draw_method = draw_game
end

function ending()
    reset_palette()
    _update_method = an_update_about_nothing
    _draw_method = draw_ending
end

function fin()
    _update_method = an_update_about_nothing
    _draw_method = draw_fin
end

function is_player_invincible()
    return player.invincible or player.invincibility_frames > 0
end

function boss_defeat_callback(boss_id)
    if boss_id == skelly then
        txt_wr("now!", 0, 48)
        txt_wr("[the earth rages beneath your feet]", 0, 0)
        txt_wr("AAAAAAaaaaaa!", 0, 51)
        txt_wr("[casting the spell shakes your body to the core]", 0, 0)
        txt_wr("[max hp down]", 0, 0)
        txt_wr("aaaaaaaaaaaaaaaaaaaaaa!", destroy_bullets, 51)
        txt_wr("[then, finally, calm]", 0, 0)
        txt_wr("[you can no longer feel the overbearing flow of mana around you]", 0, 0)
        txt_wr("phew...", 0, 48)
        txt_wr("we did it! hahaha, we did it!", 0, 51)
        txt_wr("one down, a few more to go... we can do this!", teleport_to_level_two, 48)
    elseif boss_id == mutant then
        txt_wr("now!", 0, 51)
        txt_wr("[the earth rages beneath your feet]", 0, 0)
        txt_wr("AAAAAAaaaaaa!", 0, 48)
        txt_wr("[casting the spell hurts in places you've never hurt before]", 0, 0)
        txt_wr("[sight down]", remove_sight, 0)
        txt_wr("aaaaaaaaaaaaaaaaaaaaaa!", destroy_bullets, 48)
        txt_wr("[calm]", 0, 0)
        txt_wr("[you can no longer feel the crushing weight of mana around you]", 0, 0)
        txt_wr("[the battle leaves a permanent mark, however]", 0, 0)
        txt_wr("i can't... see anything!", 0, 48)
        txt_wr("me neither... no matter where i look, i can't see a thing!", 0, 51)
        txt_wr("i never expected the curse to take a toll that quickly...", 0, 51)
        txt_wr("...is there a point for us to keep going?", 0, 48)
        txt_wr("...", 0, 51)
        txt_wr("we're basically useless in this state!", 0, 48)
        txt_wr("to think, only a bit more, and we could have been heroes!", 0, 48)
        txt_wr("you're wrong!", 0, 51)
        txt_wr("we don't have to rush it...", 0, 51)
        txt_wr("but we can't give up.", 0, 51)
        txt_wr("that's the one thing we cannot do!", 0, 51)
        txt_wr("because if we do, our sacrifices would have been in vain!", 0, 51)
        txt_wr("but in our situation, continuing would be suicide!", 0, 48)
        txt_wr("we will not... we will not know until we try, right?", 0, 51)
        txt_wr("i... i'm tired. i want to stop.", 0, 48)
        txt_wr("...", 0, 51)
        txt_wr("i know you would never live with yourself. if you gave up now.", 0, 51)
        txt_wr("...well. no matter your answer, i'm going.", 0, 51)
        txt_wr("no. wait.", 0, 48)
        txt_wr("i'll follow you. lead the way.", teleport_to_level_three, 48)
    else
        txt_wr("are you ready?", 0, 48)
        txt_wr("as ready as i can be!", 0, 51)
        txt_wr("then go ahead!", 0, 48)
        txt_wr("take us to a wonderful world where we don't need magic and miracles!", 0, 48) -- thoughts and prayers lol
        txt_wr("AAAAAAaaaaaa!", 0, 51)
        txt_wr("[the land moves like it's about to split in twain]", mana_down, 0)
        txt_wr("[it feels as if the whole world could come to an end]", remove_sight, 0)
        txt_wr("nooooooooooooooooooooooo!", destroy_bullets, 47)
        txt_wr("[then, finally, calm]", 0, 0)
        txt_wr("[for the first time ever, you can no longer feel the flow of mana anywhere]", 0, 0)
        txt_wr("[it's a little scary]", 0, 0)
        txt_wr("hah... haha...", 0, 48)
        txt_wr("can you see anything? it's all gone for me.", 0, 48)
        txt_wr("same here. same here! hahaha.", 0, 51)
        txt_wr("hahahaha. we did it! what a rush!", 0, 48)
        txt_wr("hahaha...", 0, 51)
        txt_wr("wish we could get this moment immortalized.", 0, 51)
        txt_wr("we should have brought a painter along!", 0, 51)
        txt_wr("hahaha, what for, genius? not like we could look at a painting.", 0, 48)
        txt_wr("haha, you got me there.", 0, 51)
        txt_wr("still, if we know it exists, that has to count for something!", 0, 51)
        txt_wr("...", 0, 51)
        txt_wr("do you think we will be hunted down for this?", 0, 51)
        txt_wr("no matter our exploits today, two blind fools are easy to strike down.", 0, 51)
        txt_wr("i'm not sure. i don't think so.", 0, 48)
        txt_wr("how would they know it was us?", 0, 48)
        txt_wr("it's not like the only person who saw us here would tell their story.", 0, 48)
        txt_wr("\"why yes, i know it was them because they stopped me from conquering the world!\"", 0, 48)
        txt_wr("true, true...", 0, 51)
        txt_wr("so... what now?", 0, 51)
        txt_wr("how about we slowly get out of here, figure out how to live our lives as we go.", 0, 48)
        txt_wr("sounds good to me, partner.", black, 51)
        txt_wr("miracles and magic", 0, 0)
        txt_wr("a flaming hot jam project by charles-olivier magnan", 0, 0)
        txt_wr("using pico-8 and with the help of oli414's dialogue template", 0, 0)
        txt_wr("that's it, that's the credits. thank you for playing!", 0, 0)
        txt_wr("a thousand years later...", ending, 0)
        txt_wr("hey.", 0, 89)
        txt_wr("i'm not really sure how to start a letter to myself, but here we go.", 0, 89)
        txt_wr("2020 has been rough. it's been real rough.", 0, 89)
        txt_wr("funny how life works.", 0, 89)
        txt_wr("when the awards ended i thought it was the sign of a fresh start.", 0, 89)
        txt_wr("i guess life had other plans.", 0, 89)
        txt_wr("but the year's been rough to everyone, and i don't want to add to that.", 0, 89)
        txt_wr("so, you know, i felt like ranting to future me might be a good idea.", 0, 89)
        txt_wr("are you holding up okay?", 0, 89)
        txt_wr("do you still have faith in the world?", 0, 89)
        txt_wr("did you find a way to make a difference? are you still looking?", 0, 89)
        txt_wr("if you're holding up fine now...", 0, 89)
        txt_wr("then i'm glad i get to become you.", 0, 89)
        txt_wr("...", 0, 89)
        txt_wr("and if you're not, well...", 0, 89)
        txt_wr("i hope reminiscing cheers you up a little.", 0, 89)
        txt_wr("so... see you on the flip side.", fin, 89)
    end
end

function phase_change_callback(boss_id, phase)
    if boss_id == skelly and phase == 1 then
        txt_wr("it looks like sir cecillus is still standing guard, countless moons later.", 0, 48)
        txt_wr("i wonder how you'd feel about the current situation, were you still alive.", 0, 48)
        txt_wr("there's a conversation i would have liked to have.", 0, 48)
        txt_wr("...after we seal this leyline, you'll finally find rest.", 0, 48)
    elseif boss_id == mutant and phase == 1 then
        txt_wr("lady corelia... the years have been most unkind.", 0, 51)
        txt_wr("was this tomb worth the suffering it has caused?", 0, 51)
        txt_wr("in your tale, were you the hero?", 0, 51)
        txt_wr("...leeeaave...", 0, 46)
        txt_wr("not until we get what we're here for.", 0, 51)
    elseif boss_id == mutant and phase == 4 then
        make_turret(91, 43, cross_turret, 0.15, 60)
        make_turret(85, 35, cross_turret, 0.15, 60)
    elseif boss_id == christopher and phase == 1 then
        txt_wr("gah!", 0, 47)
        txt_wr("i should have known my plans would be discovered eventually.", 0, 47)
        txt_wr("still, by now the world should feel enough unrest. see...", 0, 47)
        txt_wr("from the dawn of time, mankind has yearned for someone to lead them.", 0, 47)
    elseif boss_id == christopher and phase == 2 then
        txt_wr("from the dawn of time, mankind has yearned for someone to lead them.", 0, 47)
        txt_wr("kings, saints, oracles, prophets.", 0, 47)
        txt_wr("by saving the populace from this plague, i will bring hope to the masses.", 0, 47)
        txt_wr("[the floor shakes beneath you]", 0, 0)
        txt_wr("hmm?", 0, 47)
    elseif boss_id == christopher and phase == 3 then
        txt_wr("from the dawn of time, mankind has yearned for someone to lead them.", 0, 47)
        txt_wr("that's why i... i...", 0, 47)
        txt_wr("[the land rejects you]", 0, 0)
        txt_wr("[the tremors grow stronger]", 0, 0)
        txt_wr("you... you're not attacking me...", 0, 47)
        txt_wr("don't tell me you're...", 0, 47)
    elseif boss_id == christopher and phase == 4 then
        txt_wr("[you claim the land's rage as your own]", 0, 0)
        player.hp = player_max_hp
        player.mp = 0
        txt_wr("[hp restored]", reset_palette, 0)
        txt_wr("[sight restored]", reset_palette, 0)
        txt_wr("you... what made you think you had the right to do this?", 0, 47)
        txt_wr("you can't throw the world away! it works for the people!", 0, 47)
        txt_wr("i... will stop you!", 0, 47)
    end
end

function remove_sight()
    for x=1, 15 do
        if x != 7 then
            pal(0+x, 128+x, 1)
        end
    end
    is_fog_mode = true
end

function mana_down()
    player.mp = 0
    fog_max_size = 2
end

function teleport_to_level_two()
    player_max_hp = 8
    player_max_mp = 60
    player.hp = player_max_hp
    player.mp = player_max_mp
    player.x = 70.5
    player.y = 19.5
    player.sprite = 51
    pl_spr = 51
    pl_roll = 58
    pl_aura = 62
end

function teleport_to_level_three()
    player.hp = player_max_hp
    player.mp = player_max_mp
    player.x = 45
    player.y = 40
    player.sprite = 48
    pl_spr = 48
    pl_roll = 54
    pl_aura = 61
end

function destroy_bullets()
    local bullet_removal_array = {}
    for i=1, #actors do
        if actors[i].type == bullet or actors[i].type == mana_tile then
            add(bullet_removal_array, actors[i])
        end
    end

    for j=1, #bullet_removal_array do
        del(actors, bullet_removal_array[j])
    end
end

-->8
--tools
function centered_print(text, y, textcolor)
    print(text, (64-#text*2), y, textcolor)
end

function draw_dialogue_sprite(id, dx, dy, mult)
    sx = 8 * (id % 16)
    sy = 8 * flr(id / 16)
    sw = 8
    sh = 8
    dw = sw * mult
    dh = sh * mult
    sspr(sx,sy,sw,sh,dx,dy,dw,dh)
end

function room_id(actor)
    return flr(actor.x/16) + (flr(actor.y/16) * 8)
end

function room_x(actor)
    return flr(actor.x/16) * 16
end

function room_y(actor)
    return flr(actor.y/16) * 16
end

-->8
-- dialogue
function dtb_init()
    dtb_queu={}
    dtb_queuf={}
    dtb_queue_sprites={}
    dtb_numlines=3
    _dtb_clean()
end

-- this will add a piece of text to the queue. the queue is processed automatically.
function txt_wr(txt, callback, sprite)
    local lines={}
    local currline=""
    local curword=""
    local curchar=""
    local upt=function()
        if #curword+#currline>29 then
            add(lines,currline)
            currline=""
        end
        currline=currline..curword
        curword=""
    end
    for i=1,#txt do
        curchar=sub(txt,i,i)
        curword=curword..curchar
        if curchar==" " then
            upt()
        elseif #curword>28 then
            curword=curword.."-"
            upt()
        end
    end
    upt()
    if currline~="" then
        add(lines,currline)
    end
    add(dtb_queu,lines)
    if callback==nil then
        callback=0
    end
    add(dtb_queuf,callback)
    if sprite==nil then
        sprite=0
    end
    add(dtb_queue_sprites,sprite)
end

-- functions with an underscore prefix are meant for internal use.
function _dtb_clean()
    dtb_dislines={}
    for i=1,dtb_numlines do
        add(dtb_dislines,"")
    end
    dtb_curline=0
    dtb_ltime=0
end

function _dtb_nextline()
    dtb_curline+=1
    for i=1,#dtb_dislines-1 do
        dtb_dislines[i]=dtb_dislines[i+1]
    end
    dtb_dislines[#dtb_dislines]=""
    sfx(1)
end

function _dtb_nexttext()
    if dtb_queuf[1]~=0 then
        dtb_queuf[1]()
    end
    del(dtb_queuf,dtb_queuf[1])
    del(dtb_queue_sprites, dtb_queue_sprites[1])
    del(dtb_queu,dtb_queu[1])
    _dtb_clean()
    sfx(1)
end

-- make sure that this function is called each update.
function dtb_update()
    if #dtb_queu>0 then
        if dtb_curline==0 then
            dtb_curline=1
        end
        local dislineslength=#dtb_dislines
        local curlines=dtb_queu[1]
        local curlinelength=#dtb_dislines[dislineslength]
        local complete=curlinelength>=#curlines[dtb_curline]
        if complete and dtb_curline>=#curlines then
            if btnp(4) then
                _dtb_nexttext()
                return
            end
        elseif dtb_curline>0 then
            dtb_ltime-=1
            if not complete then
                if dtb_ltime<=0 then
                    local curchari=curlinelength+1
                    local curchar=sub(curlines[dtb_curline],curchari,curchari)
                    dtb_ltime=1
                    if curchar~=" " then
                        sfx(0)
                    end
                    if curchar=="." then
                        dtb_ltime=6
                    end
                    dtb_dislines[dislineslength]=dtb_dislines[dislineslength]..curchar
                end
                if btnp(4) then
                    dtb_dislines[dislineslength]=curlines[dtb_curline]
                end
            else
                _dtb_nextline()
            end
        end
    end
end

-- make sure to call this function everytime you draw.
function dtb_draw()
    if #dtb_queu>0 then
        local dislineslength=#dtb_dislines
        local offset=0
        if dtb_curline then
            offset=dislineslength-dtb_curline
        end

        local room_x = room_x(player) * 8
        local room_y = room_y(player) * 8

        if dtb_queue_sprites[1]~=0 then
            draw_dialogue_sprite(dtb_queue_sprites[1], 5 + room_x, 50 + room_y, 8)
        end

        rectfill(room_x + 2, room_y + 125 - dislineslength*8, room_x + 125, room_y + 125, 0)
        print("\x8e",118 + room_x,120 + room_y,1)

        for i=1,dislineslength do
            print(dtb_dislines[i], room_x + 4, room_y + i*8+119-(dislineslength+offset)*8, 7)
        end
    end
end

-->8
-- signs
function read_sign(room_id)
    if room_id == 2 then
        txt_wr("the little lady came back.", 0, 0)
        txt_wr("again she stared at us with the same distant gaze.", 0, 0)
        txt_wr("but when i gave her my creation, something changed.", 0, 0)
        txt_wr("she didn't smile. but she shed a tear, and hugged it tight.", 0, 0)
        txt_wr("looking at her back then, it felt like...", 0, 0)
        txt_wr("for some reason, our work hurt her even more than us.", 0, 0)
        txt_wr("like we were breaking something that should never have been broken.", 0, 0)
        txt_wr("it made me think about how this place will be remembered.", 0, 0)
        txt_wr("what kinds of suffering are hiding behind our greatest achievements?", 0, 0)
        txt_wr("you know, they say the world will end in a little over a thousand years.", 0, 0)
        txt_wr("do you think we'll have figured it out by then...?", 0, 0)
        txt_wr("in any case, the little lady said she'd pay me back before leaving.", 0, 0)
        txt_wr("while i was only doing this to cheer her up, i have to admit.", 0, 0)
        txt_wr("hearing these words made the days spent here hurt a little bit less.", 0, 0)
    elseif room_id == 5 then
        txt_wr("i leave this sign for thee, trespasser who came this far.", 0, 0)
        txt_wr("i am but one of many humble workers who built the walls of this temple.", 0, 0)
        txt_wr("over a dozen, of those i considered friends, died creating this place.", 0, 0)
        txt_wr("just to build the walls being defied today.", 0, 0)
        txt_wr("to create a future we're told is everlasting.", 0, 0)
        txt_wr("i leave this sign for thee, trespasser who came this far.", 0, 0)
        txt_wr("were our assumptions wrong? was this everlasting future undesirable?", 0, 0)
        txt_wr("for thee must have reason to be here.", 0, 0)
        txt_wr("i cannot shake the feeling that our sacrifices were in vain.", 0, 0)
        txt_wr("that these stone walls were either unneeded, or unwanted.", 0, 0)
        txt_wr("thus, i leave this sign for thee, trespasser who came this far.", 0, 0)
        txt_wr("so that thee, if thee exist, think about us.", 0, 0)
        txt_wr("...", 0, 51)
    elseif room_id == 8 then
        txt_wr("since discovering the wonders of mana, one thing has terrified us.", 0, 0)
        txt_wr("the thought of losing this wonderful gift.", 0, 0)
        txt_wr("so a search expedition, led by talented mage sir cecillus, led us here.", 0, 0)
        txt_wr("to the source, so we can protect it with all we have.", 0, 0)
        txt_wr("so this gift may remain as it is for generations to come.", 0, 0)
        txt_wr("do you believe the blight we're facing is man-made?", 0, 51)
        txt_wr("man-made or not, our goal is the same.", 0, 48)
        txt_wr("hmm...", 0, 51)
    elseif room_id == 9 then
        txt_wr("you're about to reach the heart of the leyline.", 0, 0)
        txt_wr("to you who can read this: we can only pray your intentions are pure.", 0, 0)
        txt_wr("it is not too late to turn back.", 0, 0)
        txt_wr("let us go over the plan again, okay?", 0, 48)
        txt_wr("sure.", 0, 51)
        txt_wr("the heart should be rich in mana.", 0, 48)
        txt_wr("this should let you charge a spell strong enough to seal it.", 0, 48)
        txt_wr("but in all likelihood, it will be protected.", 0, 51)
        txt_wr("hard to focus on a spell like that while you're being attacked.", 0, 51)
        txt_wr("that is why you should charge it from outside.", 0, 48)
        txt_wr("i will assist you as best as i can from the inside.", 0, 48)
        txt_wr("(to assist the spell, press ❎ while standing still.)", 0, 0)
    elseif room_id == 11 then
        txt_wr("a little lady came to visit the construction site today.", 0, 0)
        txt_wr("that was, by itself, already surprising.", 0, 0)
        txt_wr("if i had a say, kids of that age would always be playing outside.", 0, 0)
        txt_wr("in any case, she was clearly in no condition to work.", 0, 0)
        txt_wr("frail arms, pale skin... and these piercing brown eyes.", 0, 0)
        txt_wr("she just stared at us while we were working.", 0, 0)
        txt_wr("i couldn't quite tell if it was a glance of pity, or disdain.", 0, 0)
        txt_wr("what did she see that we didn't? what did she feel that we didn't?", 0, 0)
        txt_wr("in any case, i did not have the courage to meet her stare for long.", 0, 0)
        txt_wr("eventually, she simply left, without saying a word.", 0, 0)
        txt_wr("rumors say that she's lady corelia's daughter.", 0, 0)
        txt_wr("but that can't be right, can it? that girl should have everything.", 0, 0)
        txt_wr("well, in my spare time i made her a wooden toy.", 0, 0)
        txt_wr("if she ever comes back, i hope it makes her smile.", 0, 0)
        txt_wr("at least for a little while.", 0, 0)
    elseif room_id == 12 then
        txt_wr("this is the naples leyline.", 0, 0)
        txt_wr("within this holy land lies the foundation of the world as we know it...", 0, 0)
        txt_wr("this all seems very familiar.", 0, 51)
    elseif room_id == 13 then
        txt_wr("it's hard to keep track of how many days we've worked on this temple.", 0, 0)
        txt_wr("that's why i came up with a system.", 0, 0)
        txt_wr("there's a brick in the other room, and every day i scratch a line on it.", 0, 0)
        txt_wr("with my brick, i could finally keep track of time!", 0, 0)
        txt_wr("at least, until my brick got replaced some time ago.", 0, 0)
        txt_wr("lady corelia found out about it and asked an immediate replacement.", 0, 0)
        txt_wr("and you know what? losing my brick actually cheered me up a little.", 0, 0)
        txt_wr("it was getting a little painful, looking at the number of lines on it.", 0, 0)
    elseif room_id == 16 then
        txt_wr("this is the tarragona leyline.", 0, 0)
        txt_wr("within this holy land lies the foundation of the world as we know it.", 0, 0)
        txt_wr("from the heart of these studied halls springs forth mana.", 0, 0)
        txt_wr("from this well, do our mages find the strength to fend off evildoers.", 0, 0)
        txt_wr("from this spring, do our healers find blessings to help the weak recover.", 0, 0)
        txt_wr("she is our muse, our ally, our guardian angel.", 0, 0)
        txt_wr("she is a gift we received from the lord above.", 0, 0)
        txt_wr("to keep her graces everlasting, many traps have been laid in this temple.", 0, 0)
        txt_wr("this danger will only get stronger towards the center.", 0, 0)
        txt_wr("now that you've understood the significance of this land, begone!", 0, 0)
        txt_wr("leave this sacred place be.", 0, 0)
        txt_wr("an appropriate warning, but one i cannot heed.", 0, 48)
    elseif room_id == 17 then
        txt_wr("the next room is off limits. so is this one, but the next one even moreso.", 0, 0)
        txt_wr("do not even think about using your dodge ability to avoid the bullets.", 0, 0)
    elseif room_id == 18 then
        txt_wr("what's on the sign?", 0, 51)
        txt_wr("how should i know, i'm as blind as you.", 0, 48)
        txt_wr("then how about we pretend to read the signs we come across?", 0, 51)
        txt_wr("...haha, sure.", 0, 48)
        txt_wr("then i'll start. maybe this one is like the first one we came across?", 0, 51)
        txt_wr("\"press 🅾️ to map your surroundings with magic\"!", 0, 51)
        txt_wr("...heh.", 0, 48)
        txt_wr("we never did find that contraption, right?", 0, 48)
        txt_wr("it could still exist!", 0, 51)
    elseif room_id == 19 then
        txt_wr("our lineage is one of misfortune.", 0, 0)
        txt_wr("generation after generation of poverty. of magic eluding us.", 0, 0)
        txt_wr("but i've never been one to complain.", 0, 0)
        txt_wr("there are enough simple pleasures in life to get by.", 0, 0)
        txt_wr("for example, my wife got pregnant but a few months ago. ", 0, 0)
        txt_wr("a joy many get to experience, right? but for me, it was special.", 0, 0)
        txt_wr("like things finally started looking my way.", 0, 0)
        txt_wr("alas, she has fallen gravely ill.", 0, 0)
        txt_wr("she has been feverish and bed-ridden for the past few days...", 0, 0)
        txt_wr("and i cannot afford to take her to the healers.", 0, 0)
        txt_wr("so i went everywhere i could find for a way to get a coin or two.", 0, 0)
        txt_wr("unlike most here, i will get paid, but my condition's not much better.", 0, 0)
        txt_wr("i can only hope i can save you, mirai.", 0, 0)
        txt_wr("i can only hope that, for once...", 0, 0)
        txt_wr("magic and miracles will be on my side.", 0, 0)
    elseif room_id == 20 then
        txt_wr("this temple was lady corelia's life mission.", 0, 0)
        txt_wr("she worked her slaves to the bone to make her creation come to life.", 0, 0)
        txt_wr("with each corner exactly as she envisionned it. every detail perfectly crafted.", 0, 0)
        txt_wr("so she could forever tie the leyline, source of our world, to her legacy.", 0, 0)
        txt_wr("here she remains, forever.", 0, 0)
    elseif room_id == 24 then
        txt_wr("this sign says we can dodge using the ❎ button...", 0, 48)
        txt_wr("but only if we're moving. otherwise, it's used to charge a magic spell.", 0, 48)
        txt_wr("how cryptic. perhaps instructions for a contraption?", 0, 51)
        txt_wr("are contraptions able to wield magic?", 0, 48)
        txt_wr("hmm... maybe pretend magic to reenact historic battles?", 0, 51)
        txt_wr("somehow i don't believe you.", 0, 48)
    elseif room_id == 25 then
        txt_wr("the decision to use these protective contraptions puzzles me.", 0, 0)
        txt_wr("it is rather ingenious how the leyline's natural energy powers them, but...", 0, 0)
        txt_wr("what's wrong with a good old seal spell?", 0, 0)
        txt_wr("there has to be a way to keep mana flowing but humans out.", 0, 0)
        txt_wr("maybe our king has no faith in his mages...?", 0, 0)
    elseif room_id == 26 then
        txt_wr("i'll take this one. stop me if you've heard this before.", 0, 48)
        txt_wr("\"this is the montpellier leyline.\"", 0, 48)
        txt_wr("\"within this holy land lies the foundation of the world as we know it...\"", 0, 48)
        txt_wr("stop, stop! we don't need the whole thing.", 0, 51)
    elseif room_id == 27 then
        txt_wr("my turn!", 0, 51)
        txt_wr("we are out of easy ones, though.", 0, 51)
        txt_wr("maybe it's something about this leyline being the most important of all?", 0, 51)
        txt_wr("the most powerful one, right in the center of everything, the true beacon of hope.", 0, 51)
        txt_wr("...hey. how do you think people are holding up after we sealed the previous ones?", 0, 48)
        txt_wr("...", 0, 51)
        txt_wr("if there's something people are good at, it's adapting.", 0, 51)
        txt_wr("i hope you're right.", 0, 48)
    elseif room_id == 28 then
        txt_wr("your go!", 0, 51)
        txt_wr("...", 0, 48)
        txt_wr("can't think of anything?", 0, 51)
        txt_wr("alright, i can go again.", 0, 51)
        txt_wr("there's usually some stories about how the place was built, right?", 0, 51)
        txt_wr("so, maybe this one is something like...", 0, 51)
        txt_wr("\"for years i've kept a ring as a memento of my late father.\"", 0, 51)
        txt_wr("\"unfortunately, i dropped it in one of the bottomless pits of this temple.\"", 0, 51)
        txt_wr("\"which made me realize the real ring was in my heart all along!\"", 0, 51)
        txt_wr("...heh. i don't remember seeing any sign this sappy.", 0, 48)
    elseif room_id == 30 then
        txt_wr("now this one is definitely yours.", 0, 51)
        txt_wr("i... would rather not keep playing this game.", 0, 48)
        txt_wr("it's better at making me feel sad than anything.", 0, 48)
        txt_wr("oh. okay.", 0, 51)
        txt_wr("besides, we must nearly be at the heart of the leyline.", 0, 48)
        txt_wr("you can feel it too, can't you? it's even stronger than the ones before.", 0, 48)
        txt_wr("i sure can. let us deal with this just like the previous ones.", 0, 51)
        txt_wr("right.", 0, 48)
    else
    end
end

-->8
--patterns
function get_boss_bullets(boss, phase, bullet_pointer)
    if boss.id == skelly then
        if phase == 1 then
            if bullet_pointer % 12 == 0 then
                local base_array = get_aim_pattern(boss, 0.15)
                add(base_array, reset_bullet)
                return base_array
            end
        elseif phase == 2 then
            if bullet_pointer == 1 or bullet_pointer == 3 then
                local starting_angle = 0.25 + (bullet_pointer % 13)/30
                local ending_angle = 1.25 - (bullet_pointer % 13)/30
                return get_circle_pattern(starting_angle, ending_angle, 20, 0.15)
            elseif bullet_pointer == 30 then
                return get_aim_pattern(boss, 0.15)
            end
            if bullet_pointer == 45 then
                return {reset_bullet}
            end
        else
            local base_bullets = {}
            if bullet_pointer < 60 then
                local x_value = cos(bullet_pointer/30)/10
                local y_value = sin(bullet_pointer/30)/10
                add(base_bullets, {x_value, y_value})
                add(base_bullets, {-x_value, y_value})
            end

            if bullet_pointer % 90 == 0 then
                add(base_bullets, reset_bullet)
            end
            return base_bullets
        end
    elseif boss.id == mutant then
        if phase == 1 then
            if bullet_pointer == 10 then
                return get_aim_pattern(boss, 0.2)
            elseif (bullet_pointer % 4 == 0 and bullet_pointer > 60 and bullet_pointer < 76) then
                local rotation = (bullet_pointer - 60) * 0.015
                return get_circle_pattern(0 + rotation, 1 + rotation, 20, 0.15)
            elseif bullet_pointer > 180 then
                return {reset_bullet}
            end
        elseif phase == 2 then
            if bullet_pointer < 41 and bullet_pointer % 10 == 9 then
                local bullet_speed = (bullet_pointer + 1)/10
                return get_aim_pattern(boss, 0.1 + 0.06 * bullet_speed)
            elseif bullet_pointer > 180 then
                return {reset_bullet}
            elseif bullet_pointer > 70 and bullet_pointer < 120 then
                if bullet_pointer % 20 == 0 then
                    return get_circle_pattern(-0.25, 0.25, 10, 0.2)
                elseif bullet_pointer % 10 == 0 then
                    return get_circle_pattern(0.25, 0.75, 10, 0.2)
                end
            end
        elseif phase == 3 then
            if bullet_pointer % 4 == 0 then
                local offset = (bullet_pointer % 180)/180
                if bullet_pointer < 90 then
                    return get_circle_pattern(0 + offset, 1 + offset, 4, 0.1)
                elseif bullet_pointer > 129 and bullet_pointer < 230 then            
                    return get_circle_pattern(0 - offset, 1 - offset, 4, 0.1)
                elseif bullet_pointer > 279 then
                    return {reset_bullet}
                end
            end
        else
            if bullet_pointer % 4 == 0 then
                local offset = (bullet_pointer % 180)/180
                if bullet_pointer < 140 then
                    return get_circle_pattern(0 + offset, 1 + offset, 4, 0.1)
                elseif bullet_pointer > 279 then
                    return {reset_bullet}
                end
            end
        end
    else
        if phase == 1 then
            if bullet_pointer % 80 == 0 then
                return get_circle_pattern(0, 1, 20, 0.15)
            elseif bullet_pointer > 150 then
                return {reset_bullet}
            end
        elseif phase == 2 then
            if bullet_pointer % 4 == 0 then
                local offset = (bullet_pointer % 180)/180
                if bullet_pointer < 280 then
                    return get_circle_pattern(0 + offset, 1 + offset, 4, 0.1)
                elseif bullet_pointer > 360 then
                    return {reset_bullet}
                end
            end
        elseif phase == 3 then
            if bullet_pointer % 60 == 0 then
                local offset = rnd()
                return get_circle_pattern(offset, min(1 + offset, 1 + rnd()), 30, 0.15)
            elseif bullet_pointer % 15 == 0 then
                return get_aim_pattern(boss, 0.15)
            elseif bullet_pointer > 116 then
                return {reset_bullet}
            end
        elseif phase == 4 then
            if bullet_pointer > 500 then
                return {reset_bullet}
            elseif bullet_pointer % 4 == 0 then
                local offset = (bullet_pointer % 180)/180
                if bullet_pointer == 120 or bullet_pointer == 240 then
                    return get_circle_pattern(0, 1, 20, 0.2)
                elseif bullet_pointer < 180 then
                    return get_circle_pattern(0 + offset, 1 + offset, 3, 0.1)
                elseif bullet_pointer < 280 then
                    return get_circle_pattern(0 - offset, 1 - offset, 3, 0.1)
                elseif bullet_pointer == 440 or bullet_pointer == 452 then
                    local new_offset = rnd()
                    return get_circle_pattern(new_offset, new_offset + 1, 30, 0.15)
                end
            elseif bullet_pointer > 358 and bullet_pointer < 390 and bullet_pointer % 10 == 9 then
                local bullet_speed = (bullet_pointer - 349)/10
                return get_aim_pattern(boss, 0.1 + 0.06 * bullet_speed)
            end
        else
            if bullet_pointer % 30 == 0 then
                local offset = rnd()
                local base_array = get_circle_pattern(offset, min(1 + offset, 1 + rnd()), 30, 0.15)
                add(base_array, reset_bullet)
                return base_array
            end
        end
    end

    return {}
end

function get_turret_pattern(a)
    local type, frequency, speed, bullet_pointer = a.turret_type, a.frequency, a.speed, a.bullet_pointer
    local is_match = (frequency == bullet_pointer)
    local is_doubled_match = false
    local bullets = {}

    if type < count_clock and (bullet_pointer + 2) == frequency then
        is_doubled_match = true
    end

    if type == basic_l then
        if is_match or is_doubled_match then
            add(bullets, { -speed, 0})
        end
    elseif type == basic_r then
        if is_match or is_doubled_match then
            add(bullets, { speed, 0})
        end
    elseif type == basic_u then
        if is_match or is_doubled_match then
            add(bullets, { 0, -speed })
        end
    elseif type == basic_d then
        if is_match or is_doubled_match then
            add(bullets, { 0, speed })
        end
    elseif type == count_clock or type == clockw then
        local base_angle = (bullet_pointer + (bullet_pointer % 3) * 2)/frequency
        local local_x = cos(base_angle) * speed
        if type == clockw then
            local_x *= -1
        end
        local local_y = sin(base_angle) * speed
        add(bullets, {local_x, local_y})
    elseif type == basic_c then
        if is_match then
            local circle_pattern = get_circle_pattern(0, 1, 12, speed)
            for i=1,#circle_pattern do
                add(bullets, circle_pattern[i])
            end
        end
    elseif type == cross_turret then
        if is_match then
            add(bullets, { -speed, 0})
            add(bullets, { speed, 0})
            add(bullets, { 0, -speed })
            add(bullets, { 0, speed })
        end
    elseif type == aim_turret then
        if is_match then
            local aim_pattern = get_aim_pattern(a, speed)
            for i=1,#aim_pattern do
                add(bullets, aim_pattern[i])
            end
        end
    end

    if is_match then
        add(bullets, reset_bullet)
    end

    return bullets
end

function get_aim_pattern(actor, speed)
    local angle = atan2(player.x - actor.x, player.y - actor.y)
    return { get_bullet(angle - 0.1, speed), get_bullet(angle, speed), get_bullet(angle + 0.1, speed) }
end

function get_circle_pattern(starting_angle, ending_angle, number_bullets, speed)
    local bullets = {}
    local increment = (ending_angle - starting_angle)/number_bullets
    for i=0,(number_bullets - 1) do
        add(bullets, get_bullet(starting_angle + (i * increment), speed))
    end

    return bullets
end

function get_bullet(angle, speed)
    return {speed * cos(angle), speed * sin(angle)}
end


__gfx__
000000006661666111111111111111111111111111111111000100016161616144444444444444444446544444444444cccccccc000000000000000000000000
000000001191119100000000000000000000000013133331111111111616161644444444444444445555555544444444cccccccc000000000000000000000000
007007001989198944444444444444449999999913111131010001006161616144444444444b44445677767544444444ccccc7cc000000000000000000000000
0007700011411141bbbbbbbbcccccccc88888888131111311111111116161616444444444444b4445767676544444444cccc7c7c000000000000000000000000
0007700066466646bbbbbbbbcccccccc88888888131111311000100061616161444444444b44b4b45555555544444444cccccccc000000000000000000000000
0070070011411141bbbbbbbbcccccccc888888881111111111111111161616164444444444b444b44446504444444444cc7ccccc000000000000000000000000
0000000066616666bbbbbbbbcccccccc8888888813133331001000106161616144444444444444444446504444cc4444c7c7cccc000000000000000000000000
0000000011111111bbbbbbbbcccccccc888888881111111111111111161616164444444444444444444650444cccc4cccccccccc000000000000000000000000
1111111166616661bbbbbbbbcccccccc888888881119411122222222222662221010101055555555111111110000000000000000000000000000000000000000
1111111111111111bbbbbbbbccc333cc8888888844444444222222222666666201010101555555551b1bbbb10000007000000000000000000000000000000000
1111111116661666bbbbbbbbcc32bb3c8888888846777674228228222886688200000000555555551b1111b10000000000070000000000000000000000000000
1111111111111111bbbbbbbbc32e23cc88880088476767642228a2222228822200000000555555551b1bb1b10000000000000000000000000000000000000000
1111111166166616bbbbbbbbc3b2b3cc8880550844444444222282222265552200000000555555551b1bb1b10000000000000000000000000000000000000000
1111111111111111bbbbbbbbcc3bbb3c880555581119401122822822276655520000000055555555111111110000000000000000000000000000000000000000
1111111166616666bbbbbbbbccc333cc8888888811194011222222222766555200000000555555551b1bbbb10070000000007000000000000000000000000000
1111111111111111bbbbbbbbcccccccc888888881119401122222222276655520000000055555555111111110000000000000000000000000000000000000000
888888886664466666666666cccccccc888888885055550522222222222222222222222222222222bbbbbbbb0000000000000000222222222255552222333222
888888881144441111222211cccccccc888888880605506022222222222222222222222222222222bbbbbb7b0007000000000070226662222555555223333322
888888886444444664222226cccccccc88888888555555552228822222298222222882222222a992bbbbb777070000000700000026666622255bbb52233ff332
888888881444444114222221cccccccc88888888505555052288a8222289a8222298a82299999292bbbbbb7b0000000000000000266060222550b05223f8f832
8888888864449a4664222226cccccccc888888880605506022888822228899222299882292929992bb7bbbbb00000000000070002266662222bbbb2222ffff32
888888881444444114222221cccccccc888888885555555522288222222882222229922222222222b777bbbb0000000000000000225656222233382222455422
888888886444444664222226cccccccc888888885055550522222222222222222222222222222222bb7bbbbb0000000000000000226555222233832222444422
888888881444444114222221cccccccc888888880605506022222222222222222222222222222222bbbbbbbb0000700000000000226226222232232222422422
22299222222992222229922222000022220000222200002222999222222262222222222222299222222002222222d22222222222227777222777777222000022
22999922229999222299992220000002200000022000000229999922222266262299992222999922220000222222dd2d22200022277777727777777720000002
2999f9922999f9922999f992200444022004440220044402999f999222226666229999222999f992200400022222dddd22000022777777777777777720055502
2991f1222991f1222991f12220404022204040222040402299f1f992229fff62299ff1222991f12220404402222444dd20044022777777727777777220555522
29ffff2229ffff2229ffff2222444422224444222244442296fff1922291fff22991ff2229ffff222d4440222040444220404422777777722777777222555522
22666622226666222266662222dddd2222dddd2222dddd22266fff222299f1f22999f666226666222dd444222004404020044ddd277777722777777222dddd22
22666622226666622666662222dddd2222ddddd22ddddd22266662222999999922996622226666222dddd222220004002200dd22277777722777777222dddd22
22622622226222222222262222d22d2222d2222222222d22262262222929999222226662226226222d22d222222000022222ddd2277777722777777222d22d22
66666666666666666666622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000000000000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600606600000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600606060000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60666606600000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600606000000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60600606000000000000622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
66666666666666666666622200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
266666666666666666666666000000000000000000000000000000000000000000000000222aa222222222222229422200000000000000000000000000000000
26000000000000000000000600000000000000000000000000000000000000000000000022aaaa22255555524444444400000000000000000000000000000000
2600000000000600060660060000000000000000000000000000000000000000000000002aafffa225cc6c554677767400000000000000000000000000000000
2600000000000660660606060000000000000000000000000000000000000000000000002af1f12225bbbb554767676400000000000000000000000000000000
2600000000000606060660060000000000000000000000000000000000000000000000002aafff22253111554444444400000000000000000000000000000000
26000000000006000606000600000000000000000000000000000000000000000000000025111122255555522229402200000000000000000000000000000000
26000000000006000606000600000000000000000000000000000000000000000000000025144442225555222229402200000000000000000000000000000000
26666666666666666666666600000000000000000000000000000000000000000000000025555542255555522229402200000000000000000000000000000000
66666666666666666666666666666666666666660000000000000000000000000000000022252222244444420000000000000000000000000000000000000000
60000000000000000000000000000000000000060000000000000000000000000000000022525222242222420000000000000000000000000000000000000000
6000000000000dd0ddd00dd00d000000000000060000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
600000000000d000d000d00d0d000000000000060000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
600000000000ddd0ddd0dddd0d000000000000060000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
60000000000000d0d000d00d0d000000000000060000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
600000000000ddd0ddd0d00d0ddd0000000000060000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
66666666666666666666666666666666666666660000000000000000000000000000000022222222222222220000000000000000000000000000000000000000
22222222111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000022111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20222202111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20222202111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20222202111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20222202111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20000022111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
22222222111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111010111606060606000000000001111110000000000000000000000000000000000000000000000000000000000110101110000000000000000
00000000001101110000000000000000000000111111111111111111111100001111111111111111111111111111111100000000000000000000000000000000
00110101010101010111606060606000000000001101110000000000000000000000000000000000000000000000000000000000110101010101010000000000
00000000001101110000000000000000000011110101010101010101011111001101010101010101010101010101011100000000000000000000000000000000
00110101010101010111000000000000111110111130110000000000000000000000000000000000000000000000000000000000110101010101010000000000
00000000001101110000000000000000001111010101010101010101010111111101010101010101010101010101011100000000000000000000000000000000
00110111111111111111000000000000110101010101110000000000000000000000000000000000000000000000000000000000818181818101010000000000
00000000001101110000000000000000001101010140010101010101010101111101010101012020202001010101011100000000000000000000000000000000
00100110606060606060000000000000110101010101110000000000000000000000000000000000000000000000000000000000000000000001010000000000
00000000001101110000000000000000001101014042010101010101010101111101010101202121a22120010101011100000000000000000000000000000000
00110111111111111111111111111111113001301101111110111011101111000000000000000000000000000000000000000101010101010101010000000000
00000000001101110000000000000000001101010101010101010101010101111101010120212101012121200101011100000000000000000000000000000000
0010011011018101010101010101011111c001321101110101010101010111000000000000000000111111111111110000000101010101010101010001010100
00111111111101111111111111111111111101010101010140010101010101111101010121210101010121210101011100000000000000000000000000000000
00110111111111010111111111010111113201321101110101015101010111000000000000000000110101010101110000000101818181818181810101010101
00111001010101010101010101010170010101010101014042400101010101111101010121a20101010121210101011100000000000000000000000000000000
00100110606011010111101011110111110101011101110101010101010111000000111110111011100101510101110000000101010101010101010101810101
00110101010101010101010101010170010101010101404201424001010101111101010121212001012021210101011100000000000000000000000000000000
00110711000011010101010101110101010101011101010101010101010111000000110101010101010101010101110000000101010101010101010181008101
00110101510101111111111111111111111101010101014140420101010101111101010101212120202121010101011100000000000000000000000000000000
00110111111111010101010101110101010101011101010101010101010111000000110101010101010101012020110000008181818181818181818100000001
0011010101010111606060606060606060110101010101014201010140010111110101010101212121a201010101011100000000000000000000000000000000
00110101010101010101510101111111111111111111111101011111111111000000110101015001010101202121110000000000010101010101010101010101
00110101010110110000000000000000001101010101010101010140420101111101010101010101010101010101011100000000000000000000000000000000
00110101010101010101010101116060606060606060601101018181810111000000110101010150010101212101110000000000010101010101010101010101
00111111111111110000000000000000001101010101010101010142010101111101010101010101010101010101011100000000000000000000000000000000
00111111111111010101010101116060606060606060601101011111111111000000601101010101010101015011600000000000818181010101818181818181
00606060606060600000000000000000001111010101010101010101010111111101010101010101010101010101011100000000000000000000000000000000
00606060606011010101010101110000000000000000001101010101011160000000006011010101010101011160000000000000000000015101000000000000
00000000000000000000000000000000006011110101010101010101011111601101010101010101010101010101011100000000000000000000000000000000
00606060606011010111111111110000000000000000001111111101011160000000000060110101010101116000000000000000000000010101000000000000
00000000000000000000000000000000000060111111111111111111111160001111111111111101011111111111111100000000000000000000000000000000
00000000000011010111606060600000111111111111111111111101011111110000000000110101010101110000000000000000000000000000000000000000
00000000000000000000000000000000111111111111111100000000000000006060606060601170701160606060606000000000000000000000000000000000
00000000000011010111606060600000110101010101010101010101011151110000000000110101010101110000000000000000000000000000000000000000
00000000000000000000000000000000110101010101011100000000000000000000000000001101011100000000000000000000000000000000000000000000
00000000000011010111000000000000110101010101010111111111111101110000000000110101015111000000000000000000000000000000000000000000
00000000000000000000000000000000110101010101011100000000000000000000000000001101011100000000000000000000000000000000000000000000
00000000000011010101000001000000110101818181818181818181818101110000000000115201521100000000000000000000000000000000000000000000
00000000000000000000000000000000110101202001011100000000000000000000000000001101011100000000000000000000000000000000000000000000
00000000000011010111000060000000110101000000000000000000000001110000000000110101011100000000000000000000000000000000000000000000
00111111111111111111111111111111110101212101011100000000000000000000000000001101011100000000000000000000000000000000000000000000
00000000000011010111000000000000110101013001010101010130010101110000000000110101011100000000000000000000010100000000000000000000
00010101110101010101010101010101010101212101011100000000000000000000000000111101011111110000000000000000000000000000000000000000
00000000000060010160000000000000110101300130010101013001300101110000000000110152011100000000000000000000818100000000010101010000
00015101110101010101010101010101010101212101011111111111111111111111111111110101010101110000000000000000000000000000000000000000
00000000000060808060000000000000110101323032010101013230320101110000000000110101010101015201010101010101010101010101018181010101
01010101110101012020202020111111111111111101012101010101010101010101010101010101010101110000000000000000000000000000000000000000
00000000000080808080000000000000110101010101010101010101010101110000000000110101010101010101010101010101010101010101010000010101
010101011101010121a2212121116060601101010101012101010101010101010101010101010101510101110000000000000000000000000000000000000000
0000000000808080a080800000000000110101010101010101010101010101110000000000111111111181818181818181818181818181015101810000818181
810101111101010101010121a2110000001101010101202101011111111111111111111111110101010101110000000000000000000000000000000000000000
00000000808080808080908000000000118181818181818181818181010101110000000000000000000000000000000000000000000000010101000101000000
00010120202020202001012121110000001101012020212101011160606060606060606060110101010101110000000000000000000000000000000000000000
00000080908080808080808080000000110000000000000000000000010101110000000000000000000000000000000000000000000000818181008181000000
00010121a22121212101012121110000001101010101010101011100000000000000000000111111111111110000000000000000000000000000000000000000
000080b08080b0b08090b080b0b00000110000000000000000000000010101110000000000000000000000000000000000000000000000000000000000000000
00010121212121a22101012121110000001101010101010101011100000000000000000000606060606060600000000000000000000000000000000000000000
0032c032323232c0323232313232c000110000000000000000000000010101110000000000000000000000000000000000000000000000000000000000000000
000101010101010101010121a2110000001111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000110000000000000000000000010101110000000000000000000000000000000000000000000000000000000000000000
00010101010101010101012121110000006060606060606060606000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
66666666666666666666666166616661666166616661666166616661666166616661666166616661666166611111111111111111666666666666666666666666
60000000000000000000611111111111111111111111111111111111111111111111111111111111111111111111111111111111160000000000000000000006
60600606600000888000666616661666166616661666166616661666166616661666166616661666166616661111111111111111160333033300060006066006
60600606060000008000611111111111111111111111111111111111111111111111111111111111111111111111111111111111160300030300066066060606
60666606600000888000661666166616661666166616661666166616661666166616661666166616661666161111111111111111660333030300060606066006
60600606000000800000611111111111111111111111111111111111111111111111111111111111111111111111111111111111160003030300060006060006
60600606000000888000666666616666666166666661666666616666666166666661666666616666666166661111111111111111660333033300060006060006
66666666666666666666611111111111111111111111111111111111111111111111111111111111111111111111111111111111166666666666666666666666
66616661111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111666166611119411166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114444444411111111
16661666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111166616664677767416661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111114767676411111111
66166616111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111661666164444444466166616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119401111111111
66616666111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111666166661119401166616666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111119401111111111
66616661111111111111111111111111111111111111111111111111111111116661666166616661666166616661666166616661666166611111111166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16661666111111111111111111111111111111111111111111111111111111111666166616661666166616661666166616661666166616661111111116661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66166616111111111111111111111111111111111111111111111111111111116616661666166616661666166616661666166616661666161111111166166616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66616666111111111111111111111111111111111111111111111111111111116661666666616666666166666661666666616666666166661111111166616666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66616661111111111111111110101010101010101010101010101010101010101010101010101010101010101010101010101010101010101111111166616661
11111111111111111111111101010101010101010101010101010101010101010101010101010101010101010101010101010101010101011111111111111111
16661666111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111116661666
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111
66166616111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111166166616
11111111111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111
66616666111111111111111100000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111166616666
11111111111111111111111100000000000000000000000098098008800000000000008800890890000000000000000000000000000000001111111111111111
6661666111111111111111110000000000000000000088089a98a888a8880000000888a888a89a98088000000000000000000000000000001111111166616661
111111111111111111111111000000000000000000888a88888a988a888a8000008a888a889a88888a8880000000000000000000000000001111111111111111
1666166611111111111111110000000000000000098a888888a89a8888a888888888a8888a98a888888a89000000000000000000000000001111111116661666
11111111111111111111111100000000000000098888888a888889998a8888a8a8888a899988888a888888890000000000000000000000001111111111111111
66166616111111111111111100000000000000899898a8888880880998889898989888990880888888a898998000000000000000000000001111111166166616
11111111111111111111111100000000000009898a89888800000000998a8a888a8a89900000000888898a898900000000000000000000001111111111111111
6661666611111111111111110000000000008988a899900000000000889998a88899988000000000009998a88980000000000000000000001111111166616666
111111111111111111111111000000000000888a8900000000000008a8889888889888a8000000000000098a8880000000000000000000001111111111111111
666166611111111111111111111111111118888881111111111111188a8a9888889a8a8811111111111111888888111111111111111111111111111166616661
1111111111111111111111111111111100088a881111111111118811889988111889988118811111111111188a88000011111111111111111111111111111111
1666166611111111111111111111111144988884111111111118a888899881111188998888a81111111111118888844411111111111111111111111116661666
11111111111111111111111111111111cc9888cc111111111118888a891111111111198a8888111111111111c8a888cc11111111111111111111111111111111
66166616111111111111111111111111cc89a8cc111111111111888899111111111119988881111111111111c89988cc11111111111111111111111166166616
11111111111111111111111111111111c8a988cc111111111898889991111111111111999888981111111111cc8988cc11111111111111111111111111111111
66616666111111111111111111111111c989a8cc111111118a88a881111111111111111188a88a8111111111cc8988cc11111111111111111111111166616666
11111111111111111111111111111111c88889cc111111119988888111111111111111118888899111111111cc8888cc11111111111111111111111111111111
66616661111111111111111111111111188661111111111118888811111111111111111118888811111111111186681111111111111111111111111166616661
11111111111111111111111100000000166666610000000011111111111111111111111111111111000000001666666100000000111111111111111111111111
16661666111111111111111144444444188668814444444889881111111111111111111111188988444444441886688144444444111111111111111116661666
111111111111111111111111cccccccc18888111cccccc88a8a8811111111111111111111188a8a88ccccccc11888811cccccccc111111111111111111111111
661666161111111111111111cccccccc11655511cccccc99988881111111111111111111118888999ccccccc11655511cccccccc111111111111111166166616
111111111111111111111111cccccccc17665551ccccccc888881111111111111111111111188888cccccccc17665551cccccccc111111111111111111111111
666166661111111111111111cccccccc17665551cccc888889111111111111111111111111111988888ccccc17665551cccccccc111111111111111166616666
111111111111111111111111cccccccc17665551ccc8a8989981111111111111111111111111899898a8cccc17665551cccccccc111111111111111111111111
666166611111111111111111cccccccc11111111ccc88999988111111111111111111111111188999988cccc11111111cccccccc111111111111111166616661
111111111111111111111111cccccccc00000000cccc999988111111111111111111111111111889999ccccc00000000cccccccc111111111111111111111111
166616661111111111111111cccccccc44444444cccccccc11111111111111111111111111111111cccccccc44444444cccccccc111111111111111116661666
111111111111111111111111cccccccccccccccccccc888811111111111111111111111111111118888ccccccccccccccccccccc111111111111111111111111
661666161111111111111111ccccccccccccccccccc88898911111111111111111111111111111989888cccccccccccccccccccc111111111111111166166616
111111111111111111111111cccccccccccccccccc8a889991111111111111111111111111111199988a8ccccccccccccccccccc111111111111111111111111
666166661111111111111111cccccccccccccccccc8888991111111111111111111111111111111998888ccccccccccccccccccc111111111111111166616666
111111111111111111111111ccccccccccccccccccc88ccc11111111111111111111111111111111cc88cccccccccccccccccccc111111111111111111111111
66616661111111111111111111111111111111111111188111111111111111111111111111111111881111111111111111111111111111111111111166616661
111111111111111111111111111111111111111111898a88111111111111111111111111111111188a8981111111111111111111111111111111111111111111
166616661111111111111111111111111111111118a98888111111111111111111111111111111188889a8111111111111111111111111111111111116661666
11111111111111111111111111111111111111111998888111111111111111111111111111111111888899111111111111111111111111111111111111111111
66166616111111111111111111111111111111111188811111111111111111111111111111111111118881111111111111111111111111111111111166166616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66616666111111111111111111111111111111111111881111111111111111111111111111111111188111111111111111111111111111111111111166616666
11111111111111111111111111111111111111111189988111111111111111111111111111111111889981111111111111111111111111111111111111111111
666166611111111111111111111111111111111118a98881111111111119911111111111111111118889a8111111111111111111111111111111111166616661
11111111111111111111111111111111111111111998881111111111119999111111111111111111188899111111111111111111111111111111111111111111
166616661111111111111111111111111111111111888111111111111999f9911111111111111111118881111111111111111111111111111111111116661666
111111111111111111111111111111111111111111111111111111111991f1111111111111111111111111111111111111111111111111111111111111111111
6616661611111111111111111111111111111111111118911111111119ffff111111111111111111981111111111111111111111111111111111111166166616
111111111111111111111111111111111111111111888a98111111111166661111111111111111189a8881111111111111111111111111111111111111111111
666166661111111111111111111111111111111118a89988111111111166661111111111111111188998a8111111111111111111111111111111111166616666
11111111111111111111111111111111111111111889998111111111116116111111111111111111899988111111111111111111111111111111111111111111
66616661101010101010101010101010101010101099901010101010101010101010101010101010109990101010101011111111111111111111111166616661
11111111010101010101010101010101010101010101010101010101010101010101010101010101010101010101010111111111111111111111111111111111
16661666000000000000000000000000000000000000008800000000000000000000000000000008800000000000000011111111111111111111111116661666
11111111000000000000000000000000000000000000088890000000000000000000000000000098880000000000000011111111111111111111111111111111
661666160000000000000000000000000000000000088a89900000000000000000000000000000998a8800000000000011111111111111111111111166166616
1111111100000000000000000000000000000000008a889900000000000000000000000000000009988a80000000000011111111111111111111111111111111
66616666000000000000000000000000000000000088889000000000000000000000000000000000988880000000000011111111111111111111111166616666
11111111000000000000000000000000000000000008800000000000000000000000000000000000008800000000000011111111111111111111111111111111
66616661000000000000000000000000000000000000000088000000000000000000000000000880000000000000000011111111111111111111111166616661
111111110000000000000000000000000000000000000088a88000000000000000000000000088a8800000000000000011111111111111111111111111111111
16661666000000000000000000000000000000000000089888800000000000000000000000008888980000000000000011111111111111111111111116661666
111111110000000000000000000000000000000000008a98880000000000000000000000000008889a8000000000000011111111111111111111111111111111
66166616000000000000000000000000000000000000998800000000000000000000000000000008899000000000000011111111111111111111111166166616
11111111000000000000000000000000000000000000088000000000000000000000000000000000880000000000000011111111111111111111111111111111
66616666000000000000000000000000000000000000000000880000000000000000000000088000000000000000000011111111111111111111111166616666
11111111000000000000000000000000000000000000000008988000000000000000000000889800000000000000000011111111111111111111111111111111
66616661000000000000000000000000000000000000000089988000000000000000000000889980000000000000000011111111111111111111111166616661
111111110000000000000000000000000000000000000008a98800000000000000000000000889a8000000000000000011111111111111111111111111111111
16661666000000000000000000000000000000000000000998800000000000000000000000008899000000000000000011111111111111111111111116661666
11111111000000000000000000000000000000000000000088000000000000000000000000000880000000000000000011111111111111111111111111111111
66166616000000000000000000000000000000000000000000000089000000000000000980000000000000000000000011111111111111111111111166166616
11111111000000000000000000000000000000000000000000000889800000000000008988000000000000000000000011111111111111111111111111111111
66616666000000000000000000000000000000000000000000008a8980000000000000898a800000000000000000000011111111111111111111111166616666
11111111000000000000000000000000000000000000000000008899000000000000000998800000000000000000000011111111111111111111111111111111
6661666100000000000000000000000000000000000000000008a890000000000000000098a80000000000000000000011111111111111111111111166616661
11111111000000000000000000000000000000000000000000088990000000000000000099880000000000000000000011111111111111111111111111111111
16661666000000000000000000000000000000000000000000009900008800000008800009900000000000000000000011111111111111111111111116661666
11111111000000000000000000000000000000000000000000000000088890000098880000000000000000000000000011111111111111111111111111111111
66166616000000000000000000000000000000000000000000000000888990000099888000000000000000000000000011111111111111111111111166166616
111111110000000000000000000000000000000000000000000000008a88000000088a8000000000000000000000000011111111111111111111111111111111
66616666000000000000000000000000000000000000000000000000888800000008888000000000000000000000000011111111111111111111111166616666
11111111000000000000000000000000000000000000000000000000088000888000880000000000000000000000000011111111111111111111111111111111
66616661000000000000000000000000000000000000000000000000000008888800000000000000000000000000000011111111111111111111111166616661
111111110000000000000000000000000000000000000000000000000000088a8800000000000000000000000000000011111111111111111111111111111111
166616660000000000000000000000000000000000000000000000000000088988000000000000000000000000000000111111111111a9911111111116661666
11111111000000000000000000000000000000000000000000000000000008a98800000000000000000000000000000011111111999991911111111111111111
66166616000000000000000000000000000000000000000000000000880009988900088000000000000000000000000011111111919199911111111166166616
111111110000000000000000000000000000000000000000000000088a80008880008a8800000000000000000000000011111111111111111111111111111111
66616666000000000000000000000000000000000000000000000008888000000000888800000000000000000000000011111111111111111111111166616666
11111111000000000000000000000000000000000000000000000000880000000000088000000000000000000000000011111111111111111111111111111111
66616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
16661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616661666166616
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
66616666666166666661666666616666666166666661666666616666666166666661666666616666666166666661666666616666666166666661666666616666
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__gff__
0801080808200141000011000800000000010808081100010800000000000000010100080880024100000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000011232323232323232323232323232311000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111023230c232310102323231323101100000000002c0000002c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111010232323101010102323231010110000001c0000000000000000001c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000111010102323031010030c23101010110000000000001c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000011101010102323030323231010101011002b000000002c000010100000001b000000000000000000000000000000000000000000000000000000000000000000000000001010101010101010000000000000000000000000000000000000000000000000000000000000000000000000
0000101010101010101010101000000011101010101010101010101010101011000000000000000010101510000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000
0000101010101010101010101000000011101010101010101010101010101011000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000010101004041010040410101000000000000000000000000000000000000000000000000000000000000000000000
00001010101010151010101010000000111010101010101010101010101010110000001c0000000010101010002b00000000000000000000000000000000000000000000000000000000000000000000000010100420101010102004101000000000000000000000000000000000000000000000000000000000000000000000
00001010101010051010101010000000111010101010101010101010101010110000000000002b00101010100000001c0000000000000000000000000000000000000000000000000000000000000000000010102424101010152024101000000000000000000000000000000000000000000000000000000000000000000000
0000101010101010101010101000000011101010101010101010101010101011000000001b00000010101010000000000000000000000000000000000000000000000000000000000000000000000000000010101024041010041410101000000000000000000000000000000000000000000000000000000000000000000000
0000101010101010101010101000000011101010101010101010101010101011000000000000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000018101010240404241010101800000000000000000000000000000000000000000000000000000000000000000000
0000101010101010101010101000000011101010101010101010101010101011001c000000001c0010101010000000000000000000000000000000000000000000000000000000000000000000000000000000181010102424101010180000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000001103101010101010101010101010031100000000000000001010101000001c000000000000000000000000000000000000000000000000000000000000000000000000001810101010101018000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000112303101010101010101010100323110000002b0000000010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000018101010101800000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000011111111111110101010111111111111000000000000000010101010002b00000000000000000000000000000000000000000000000000000000000000000000000000000000181010180000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000006060606061110101010110606060606000000000000000006101006000000000000000000000000000000000000000000000000000000000000000000000000000000000000111010110000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111111100060606060611070707071106060606061111111111000000007f7f00000000000011111111111111111111111111111100000000001121110000000000000000111111111111111010110000000000000000000000000000000000000000000000000000000000000000000000000000
00012510101010101010101010101100000000000011101010101100000000001110101010000000007f7f00000000000011101010101010101010101010101100111111111110111111111111111100111010101010101010110000000000000000000000000000000000000000000000000000000000000000000000000000
001110101010101010101010101011000000000000111010101011000000000011101010107f7f7f7f7f7f00000000000011101010101010101010101010101100111010101010101010101011111100111010101010101010110000000000000000000000000000000000000000000000000000000000000000000000000000
000110101003030303030310101011000000000000111010101011000000000011101010107f7f7f7f7f7f00000000000011101004040404040404040410101100111015101010101010101010111100111010111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
0011101025232323232323101010110000000000001110101010110000000000111010101000000000000000000000000011101024242424242424242410101100111010101010101010101010101100111010111818181818181818181818110000000000000000000000000000000000000000000000000000000000000000
000110101023100c232323251025110000000000001110101010110000000000111010101000111111111111111111111111101024101010101010242410101100111010101018181818101010101100111010110000100000000000101500110000000000000000000000000000000000000000000000000000000000000000
0011101010230323232313101010111111111111111110101010110000000000111010101800101010101010101010101010101024101010101010142410101111111010101800000000181010101100111010111000101010101010101000110000000000000000000000000000000000000000000000000000000000000000
0001101010232323232323101010101010101010101010101010011101110000111010100000101010101010101010101010101024101004041010242410101010101010100000000000101010101100111010111800181818181818101000110000000000000000000000000000000000000000000000000000000000000000
0011101010231323232323101010101010101010101010101010101010010000111010100000101018181818181010101010101024101024241010242410101010101010100000000010101010101100111010110000000000000010101800110000000000000000000000000000000000000000000000000000000000000000
0001102510232323102323101010101010101010101010101010101010110000111010100000101000101010101111111111040424101024241010242410101111111010100000001010101010101100111010110000100010101010100000110000000000000000000000000000000000000000000000000000000000000000
0011101010232323030c23101010111111111111111111011010151010010000111010100000101000101010101106060611242424101024141010242410101106111010101010101010101010101100111010110000180010181818180000110000000000000000000000000000000000000000000000000000000000000000
0001101010232323112323030303110606060606060606111010101010110000111010100000101000101010101100000011101010101024241010242410101100111010101010101010101010101111111010110000000010000000100000110000000000000000000000000000000000000000000000000000000000000000
0011101010232323032323232323110606060606060606011010101010010000111010101010101000101010101100000011101510101024241010101010101100111111111170111110101010101010101010101010101010000000180000110000000000000000000000000000000000000000000000000000000000000000
0001101010101010101010101510110000000000000000110111011101110000111010101010101011111111111100000011101010101024241010101010101100111111111170111111101010101010101010101010101010000000000000110000000000000000000000000000000000000000000000000000000000000000
0011101010101010101010101010110000000000000000060606060606060000111111111111111111060606060600000011111111101011111111111111111100060606061170111111111111111111111111111111111111111111111111110000000000000000000000000000000000000000000000000000000000000000
0011111111111110101111111111110000000000000000060606060606060000060606060606060606000000000000000006060611101011060606060606060600000000001170110606060606060606060606060606060606060606060606060000000000000000000000000000000000000000000000000000000000000000
__sfx__
000200000e0101003011050100500f0500d0500b05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400000113001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00080000060200a0200a0300802004020030000000000000000000000000000000001d10000000000002410027100291002b1002d1002a100241001e1001b10000000161001310000000101000f100000000e100
000300000a07003070010700007000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000500002f020340202f0203402036020000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
