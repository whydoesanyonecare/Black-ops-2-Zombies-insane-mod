#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\zombies\_zm_weapons;
#include maps\mp\zombies\_zm_utility; 
#include maps\mp\zombies\_zm_perks;
init()
{
    level.TwoPerks = getdvarintdefault("2PERKS", 0);
    level.max_zombie_func = ::max_zombie_func;
    level thread timer_hud();
    level thread ZombiesCounter();
    level thread break_barriers();
    level thread new_pap_trigger();
    set_zombies();
    set_perk_prices();
}

set_zombies()
{
    level.player_starting_points = 3000;
    level.zombie_vars["zombie_spawn_delay"] = 0;
    level.zombie_vars["zombie_between_round_time"] = 0;
    level thread zombie_speed();
}

zombie_speed()
{
    level endon("end_game");
	for( ;; )
	{
		foreach(zombie in getaiarray(level.zombie_team))
		{
			if( !IsDefined( zombie.run_set ) )
			{
				zombie maps\mp\zombies\_zm_utility::set_zombie_run_cycle( "sprint" ); 
				zombie.run_set = 1;
			}
		}
		wait 1;
	}
}

timer_hud()
{
    level endon("end_game");
    flag_wait("initial_blackscreen_passed");
    timer_hud = Create_simple_hud();
    timer_hud.alignx = "right";
    timer_hud.aligny = "top";
    timer_hud.horzalign = "user_right";
    timer_hud.vertalign = "user_top";
    timer_hud.x = -5;
    timer_hud.y = 20;
    timer_hud.fontscale = 1.4;
    timer_hud.alpha = 0;
    timer_hud.color = (1, 1, 1);
    timer_hud.hidewheninmenu = 1;
    timer_hud.alpha = 1;
    timer_hud settimerup(0);
}

ZombiesCounter()
{
	flag_wait( "initial_blackscreen_passed" );
    level.zombiesCounter = newhudelem();
    level.zombiesCounter.fontscale = 2;
    level.zombiesCounter.foreground = true; 
    level.zombiesCounter.sort = 2; 
    level.zombiesCounter.hidewheninmenu = false; 
    level.zombiesCounter.alignX = "left";
    level.zombiesCounter.alignY = "bottom";
    level.zombiesCounter.horzAlign = "user_left";
    level.zombiesCounter.vertAlign = "user_bottom";
    level.zombiesCounter.x = 130;
    level.zombiesCounter.y = -15;
    level.zombiesCounter thread destroy_in_end();
    for(;;)
    {
        enemies = get_round_enemy_array().size + level.zombie_total;
        level.zombiesCounter.label = &"Zombies: ^1";
        level.zombiesCounter setValue( enemies );
        wait 0.05;
    }
}

destroy_in_end()
{
    level waittill("end_game");
    self destroy();
}

pap_off()
{
	wait 5;
	for(;;)
	{
		level waittill("Pack_A_Punch_on");
		wait 1;
		level notify("Pack_A_Punch_off");
	}
}

new_pap_trigger()
{
    level waittill("Pack_A_Punch_on");
    wait 2;
	if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zstandard" )
	{	
	}
	else
	{
		level notify("Pack_A_Punch_off");
		level thread pap_off();
	}
	perk_machine = getent( "vending_packapunch", "targetname" );
	weapon_upgrade_trigger = getentarray( "specialty_weapupgrade", "script_noteworthy" );
	weapon_upgrade_trigger[0] trigger_off();
	if( getdvar( "mapname" ) == "zm_transit" && getdvar ( "g_gametype")  == "zclassic" )
	{
		if(!level.buildables_built[ "pap" ])
		{
			level waittill("pap_built");
			wait 1;
		}
	}
	self.perk_machine = perk_machine;
	packa_rollers = spawn( "script_origin", perk_machine.origin );
	packa_timer = spawn( "script_origin", perk_machine.origin );
	packa_rollers linkto( perk_machine );
	packa_timer linkto( perk_machine );
	if( getdvar( "mapname" ) == "zm_highrise" )
	{
		trigger = spawn( "trigger_radius", perk_machine.origin, 1, 60, 80 );
		Trigger enableLinkTo();
		Trigger linkto(self.perk_machine);
	}
	else
		trigger = spawn( "trigger_radius", perk_machine.origin, 1, 35, 80 );

	Trigger SetCursorHint( "HINT_NOICON" );
    Trigger sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", 10000 );
	Trigger usetriggerrequirelookat();
	perk_machine thread maps\mp\zombies\_zm_perks::activate_packapunch();
	for(;;)
	{
		Trigger waittill("trigger", player);
		current_weapon = player getcurrentweapon();
        /*if(current_weapon == "saritch_upgraded_zm+dualoptic" || current_weapon == "dualoptic_saritch_upgraded_zm+dualoptic" || current_weapon == "slowgun_upgraded_zm")
        {
            Trigger sethintstring( "^1This weapon doesn't have alternative ammo types." );
            continue;
        }*/
		if(player UseButtonPressed() && player.score >= 10000 && current_weapon != "riotshield_zm" && player can_buy() )
        {
			player.score -= 10000;
            player thread maps\mp\zombies\_zm_audio::play_jingle_or_stinger( "mus_perks_packa_sting" );
			trigger setinvisibletoall();
			upgrade_as_attachment = will_upgrade_weapon_as_attachment( current_weapon );
            
            player.restore_ammo = undefined;
            player.restore_clip = undefined;
            player.restore_stock = undefined;
            player.restore_clip_size = undefined;
            player.restore_max = undefined;
            
            player.restore_clip = player getweaponammoclip( current_weapon );
            player.restore_clip_size = weaponclipsize( current_weapon );
            player.restore_stock = player getweaponammostock( current_weapon );
            player.restore_max = weaponmaxammo( current_weapon );
            
			player thread maps\mp\zombies\_zm_perks::do_knuckle_crack();
			wait .1;
			player takeWeapon(current_weapon);
			current_weapon = player maps\mp\zombies\_zm_weapons::switch_from_alt_weapon( current_weapon );
			self.current_weapon = current_weapon;
			upgrade_name = maps\mp\zombies\_zm_weapons::get_upgrade_weapon( current_weapon, upgrade_as_attachment );
			player maps\mp\zombies\_zm_perks::third_person_weapon_upgrade( current_weapon, upgrade_name, packa_rollers, perk_machine, self );
			trigger sethintstring( &"ZOMBIE_GET_UPGRADED" );
			trigger thread wait_for_pick(player, current_weapon, self.upgrade_name);
			if ( isDefined( player ) )
			{
				trigger setinvisibletoall();
				trigger setvisibletoplayer( player );
			}
			self thread wait_for_timeout( current_weapon, packa_timer, player );
			self waittill_any( "pap_timeout", "pap_taken", "pap_player_disconnected" );
			self.current_weapon = "";

			if ( isDefined( self.worldgun ) && isDefined( self.worldgun.worldgundw ) )
				self.worldgun.worldgundw delete();

			if ( isDefined( self.worldgun ) )
				self.worldgun delete();

			trigger setinvisibletoplayer( player );
			wait 1.5;
			trigger setvisibletoall();
			self.pack_player = undefined;
			flag_clear( "pack_machine_in_use" );
		}
        trigger sethintstring( &"ZOMBIE_PERK_PACKAPUNCH", 10000 );
		wait .1;
	}
}

wait_for_pick(player, weapon, upgrade_weapon )
{
	level endon("end_game");
	level endon( "pap_timeout" );
	for (;;)
	{
		self playloopsound( "zmb_perks_packa_ticktock" );
		self waittill( "trigger", user );
		if(user UseButtonPressed() && player == user)
		{	
			self stoploopsound( 0.05 );
			player thread do_player_general_vox( "general", "pap_arm2", 15, 100 );
			gun = player maps\mp\zombies\_zm_weapons::get_upgrade_weapon( upgrade_weapon, 0 );
			if(is_weapon_upgraded( weapon ) )
			{
				player.restore_ammo = 1;
				if( weapon == "galil_upgraded_zm+reflex" || weapon  == "fnfal_upgraded_zm+reflex" )
				{
					//level thread aats(weapon, player); //Alternative ammo type for galil and fnfal upgraded
				}
				else
				{
					//level thread aats(upgrade_weapon, player); //Alternative ammo type for all other weapons
				}
			}
			if( weapon == "galil_upgraded_zm+reflex" || weapon  == "fnfal_upgraded_zm+reflex" )
			{
				player giveweapon( weapon, 0, player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( weapon ));
				player switchToWeapon( weapon );
				x = weapon;
			}
            else
            {
                weapon_limit = get_player_weapon_limit( player );
                player maps\mp\zombies\_zm_weapons::take_fallback_weapon();
                primaries = player getweaponslistprimaries();

                if ( isDefined( primaries ) && primaries.size >= weapon_limit )
                    player maps\mp\zombies\_zm_weapons::weapon_give( upgrade_weapon );
                else
                    player giveweapon( upgrade_weapon, 0, player maps\mp\zombies\_zm_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ));

			    player switchToWeapon( upgrade_weapon );
                x = upgrade_weapon;
            }
			/*if ( isDefined( player.restore_ammo ) && player.restore_ammo ) //does not give full ammo for already upgraded weapons
			{
				new_clip = player.restore_clip + ( weaponclipsize( x ) - player.restore_clip_size );
				new_stock = player.restore_stock + ( weaponmaxammo( x ) - player.restore_max );
				player setweaponammostock( x, new_stock );
				player setweaponammoclip( x, new_clip );
			}*/
			level notify( "pap_taken" );
			player notify( "pap_taken" );
			break;
		}
		wait .1;
	}
}

can_buy()
{
    if ( isDefined( self.is_drinking ) && self.is_drinking > 0)
        return 0;
    if ( self IsSwitchingWeapons() )
        return 0;
    if ( self isthrowinggrenade() )
        return 0;
    if ( self maps\mp\zombies\_zm_laststand::player_is_in_laststand() )
        return 0;
    current_weapon = self getcurrentweapon();
    if ( is_placeable_mine( current_weapon ) || is_equipment_that_blocks_purchase( current_weapon ) || is_equipment( current_weapon ) )
        return 0;
    if ( self in_revive_trigger() || level.revive_tool == current_weapon )
        return 0;
    if ( current_weapon == "none" )
        return 0;
    if ( self hacker_active() )
        return 0;
    if ( !is_player_valid( self ) )
        return 0;
    if ( self isreloading() )
        return 0;
        
    return 1;
}

set_perk_prices()
{
    flag_wait("initial_blackscreen_passed");

    if(isdefined(level.TwoPerks) && level.TwoPerks)
    {
        vending_triggers = getentarray( "zombie_vending", "targetname" );
        for ( i=0;i<vending_triggers.size;i++ )
        {
            if ( isDefined( vending_triggers[ i ].script_noteworthy ) && vending_triggers[ i ].script_noteworthy == "specialty_weapupgrade" )
            {
            }

            if ( isDefined( vending_triggers[ i ].script_noteworthy ) && vending_triggers[ i ].script_noteworthy == "vending_jugg" )
            {
            }

            if ( isDefined( vending_triggers[ i ].script_noteworthy ) && vending_triggers[ i ].script_noteworthy == "vending_marathon" )
            {
            }
            vending_triggers[ i ] delete();
        }

        jugg_machine = getentarray( "vending_jugg", "targetname" );
        jugg_machine_trigger = getentarray( "vending_jugg", "target" );
        jugg_machine_trigger[0] trigger_off();
        new_jugg_trigger = spawn( "trigger_radius", jugg_machine[0].origin, 1, 35, 80 );
        new_jugg_trigger SetCursorHint( "HINT_NOICON" );
        new_jugg_trigger usetriggerrequirelookat();
        new_jugg_trigger thread perk_machine("specialty_armorvest", &"ZOMBIE_PERK_JUGGERNAUT", "mus_perks_jugganog_sting");

        stamin_machine = getentarray( "vending_marathon", "targetname" );
        stamin_machine_trigger = getentarray( "vending_marathon", "target" );
        stamin_machine_trigger[0] trigger_off();
        stamin_machine_trigger = spawn( "trigger_radius", stamin_machine[0].origin, 1, 35, 80 );
        stamin_machine_trigger SetCursorHint( "HINT_NOICON" );
        stamin_machine_trigger usetriggerrequirelookat();
        stamin_machine_trigger thread perk_machine("specialty_longersprint", &"ZOMBIE_PERK_MARATHON", "mus_perks_stamin_sting");
    }
    else // this shit did not work in loop.. 
    {

        vending = "vending_jugg";
        perk = "specialty_armorvest";
        hint = &"ZOMBIE_PERK_JUGGERNAUT";
        sound = "mus_perks_jugganog_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);

        vending = "vending_marathon";
        perk = "specialty_longersprint";
        hint = &"ZOMBIE_PERK_MARATHON";
        sound = "mus_perks_stamin_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);

        vending = "vending_doubletap";
        perk = "specialty_rof";
        hint = &"ZOMBIE_PERK_DOUBLETAP";
        sound = "mus_perks_doubletap_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);

        vending = "vending_deadshot";
        perk = "specialty_deadshot";
        hint = &"ZOMBIE_PERK_DEADSHOT";
        sound = "mus_perks_deadshot_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);


        vending = "vending_additionalprimaryweapon";
        perk = "specialty_additionalprimaryweapon";
        hint = &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON";
        sound = "mus_perks_mulekick_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);


        vending = "vending_revive";
        perk = "specialty_quickrevive";
        solo = use_solo_revive();
        if(solo)
            hint = &"ZOMBIE_PERK_QUICKREVIVE_SOLO";
        else
            hint = &"ZOMBIE_PERK_QUICKREVIVE";

        sound = "mus_perks_revive_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);


        vending = "vending_sleight";
        perk = "specialty_fastreload";
        hint = &"ZOMBIE_PERK_FASTRELOAD";
        sound = "mus_perks_speed_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);

        if(!solo)
        {
            vending = "vending_tombstone";
            perk = "specialty_scavenger";
            hint = &"ZOMBIE_PERK_TOMBSTONE";
            sound = "mus_perks_tombstone_sting";

            machine = getentarray( vending, "targetname" );
            machine_trigger = getentarray( vending, "target" );
            machine_trigger[0] trigger_off();

            machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
            machine_trigger SetCursorHint( "HINT_NOICON" );
            machine_trigger usetriggerrequirelookat();
            machine_trigger thread perk_machine(perk, hint, sound);
        }

        vending = "vending_chugabud";
        perk = "specialty_finalstand";
        hint = &"ZOMBIE_PERK_CHUGABUD";
        sound = "mus_perks_whoswho_sting";

        machine = getentarray( vending, "targetname" );
        machine_trigger = getentarray( vending, "target" );
        machine_trigger[0] trigger_off();

        machine_trigger = spawn( "trigger_radius", machine[0].origin, 1, 35, 80 );
        machine_trigger SetCursorHint( "HINT_NOICON" );
        machine_trigger usetriggerrequirelookat();
        machine_trigger thread perk_machine(perk, hint, sound);
    }
}

perk_machine(perk, hint, sound)
{
    level endon("end_game");
    for(;;)
    {
        self sethintstring( hint, 10000 );
        self waittill("trigger", player);
    
        if(player hasperk( perk ))
            self setinvisibletoplayer(player);
        else
            self setvisibletoplayer(player);

        if(!player can_buy())
        {
            wait .1;
            continue;
        }
        else if(player UseButtonPressed() && player.score >= 10000 && player can_buy() && !player hasperk( perk ) )
        {
            self sethintstring( " " );
            player.score -= 10000;
            player playsound( "zmb_cha_ching" );
            player playsound( sound );
            player dogiveperk( perk );
            wait 4;
        }
        else if(player UseButtonPressed() && player.score < 10000 && player can_buy() && !player hasperk( perk ))
            player maps\mp\zombies\_zm_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );

        wait .1;
    }
}

dogiveperk(perk)
{
    self endon("disconnect");
    level endon("end_game");
    if(!self hasperk(perk) || self maps\mp\zombies\_zm_perks::has_perk_paused(perk))
    {
        gun = self maps\mp\zombies\_zm_perks::perk_give_bottle_begin(perk);
        evt = self waittill_any_return("fake_death", "death", "player_downed", "weapon_change_complete");

        if(evt == "weapon_change_complete")
            self thread maps\mp\zombies\_zm_perks::wait_give_perk(perk, 1);

        self maps\mp\zombies\_zm_perks::perk_give_bottle_end(gun, perk);

        if(self maps\mp\zombies\_zm_laststand::player_is_in_laststand() || isdefined(self.intermission) && self.intermission)
            return;

        self notify("burp");
    }
}

break_barriers()
{
    level endon("end_game");
    flag_wait("initial_blackscreen_passed");
    for(;;)
    {
        level waittill("start_of_round");
        level thread maps\mp\zombies\_zm_blockers::open_all_zbarriers();
    }
}

max_zombie_func( max_num )
{
    if ( level.round_number < 2 )
        max = 31;
    else
        max = level.round_number * max_num;

    return max;
}
