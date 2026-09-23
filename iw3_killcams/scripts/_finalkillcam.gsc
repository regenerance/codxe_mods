#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init_finallkillcam()
{
    level.killcam_style = 0;
    level.fk = false;
    level.showFinalKillcam = false;
    level.waypoint = false;
    level.lastKillInfo = undefined;

    level.KillInfo = [];
    level.KillInfo["axis"] = [];
    level.KillInfo["allies"] = [];

    level.doFK = [];
    level.doFK["axis"] = false;
    level.doFK["allies"] = false;
    
    level.slowmotstart = undefined;
    
    level thread OnPlayerConnectHook();
}

OnPlayerConnectHook()
{
    while(true)
    {
        level waittill("connected", player);
        player thread beginFK();
    }
}    
        
beginFK()
{
    self endon("disconnect");
    
    while(true)
    {
        self waittill("beginFK", winner);
        
        self notify ( "reset_outcome" );

        if ( isDefined( level.lastKillInfo ) )
        {
            killInfo = level.lastKillInfo;

            if ( isDefined( killInfo["attacker"] ) && isDefined( killInfo["victim"] ) )
                self finalkillcam(killInfo["attacker"], killInfo["attackerNumber"], killInfo["deathTime"], killInfo["victim"]);
        }
    }
}

finalkillcam( attacker, attackerNum, deathtime, victim)
{
    self endon("disconnect");
    level endon("end_killcam");
    
    self SetClientDvar("ui_ShowMenuOnly", "none");

    camtime = 5;
    predelay = getTime()/1000 - deathtime;
    postdelay = 2;
    killcamlength = camtime + postdelay;
    killcamoffset = camtime + predelay;
    
    visionSetNaked( getdvar("mapname") );
    
    self notify ( "begin_killcam", getTime() );
    
    self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
    
    self.sessionstate = "spectator";
	self.spectatorclient = attackerNum;
	self.killcamentity = -1;
	self.archivetime = killcamoffset;
	self.killcamlength = killcamlength;
	self.psoffsettime = 0;
    
    if(!isDefined(level.slowmostart))
        level.slowmostart = killcamlength - 2.5;
    
    self.killcam = true;
    
    wait 0.05;
    
    if(!isDefined(self.top_fk_shader))
        self CreateFKMenu(victim , attacker);
    else
    {
        self.fk_title.alpha = 1;
        self.fk_title_low.alpha = 1;
        self.top_fk_shader.alpha = 0.5;
        self.bottom_fk_shader.alpha = 0.5;
    }
    
    self thread WaitEnd(killcamlength);
    
    wait 0.05;
    
    self waittill("end_killcam");
    
    self thread CleanFK();
    
    self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
    
    wait 0.05;
    
    self.sessionstate = "spectator";
	spawnpointname = "mp_global_intermission";
	spawnpoints = getentarray(spawnpointname, "classname");
	assert( spawnpoints.size );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);

	self spawn(spawnpoint.origin, spawnpoint.angles);

    wait 0.05;
    
    self.killcam = undefined;
    self thread maps\mp\gametypes\_spectating::setSpectatePermissions();

    level notify("end_killcam");

    level.fk = false;  
}

CleanFK()
{
    self.fk_title.alpha = 0;
    self.fk_title_low.alpha = 0;
    self.top_fk_shader.alpha = 0;
    self.bottom_fk_shader.alpha = 0;
    
    self SetClientDvar("ui_ShowMenuOnly", "");
    
    visionSetNaked( "mpOutro", 1.0 );
}

WaitEnd( killcamlength )
{
    self endon("disconnect");
	self endon("end_killcam");
    
    wait killcamlength;
    
    self notify("end_killcam");
}

CreateFKMenu( victim , attacker)
{
    self.top_fk_shader = newClientHudElem(self);
    self.top_fk_shader.elemType = "shader";
    self.top_fk_shader.archived = false;
    self.top_fk_shader.horzAlign = "fullscreen";
    self.top_fk_shader.vertAlign = "fullscreen";
    self.top_fk_shader.sort = 0;
    self.top_fk_shader.foreground = true;
    self.top_fk_shader.color	= (.15, .15, .15);
    self.top_fk_shader setShader("white",640,112);
    
    self.bottom_fk_shader = newClientHudElem(self);
    self.bottom_fk_shader.elemType = "shader";
    self.bottom_fk_shader.y = 368;
    self.bottom_fk_shader.archived = false;
    self.bottom_fk_shader.horzAlign = "fullscreen";
    self.bottom_fk_shader.vertAlign = "fullscreen";
    self.bottom_fk_shader.sort = 0; 
    self.bottom_fk_shader.foreground = true;
    self.bottom_fk_shader.color	= (.15, .15, .15);
    self.bottom_fk_shader setShader("white",640,112);
    
    self.fk_title = newClientHudElem(self);
    self.fk_title.archived = false;
    self.fk_title.y = 45;
    self.fk_title.alignX = "center";
    self.fk_title.alignY = "middle";
    self.fk_title.horzAlign = "center";
    self.fk_title.vertAlign = "top";
    self.fk_title.sort = 1; // force to draw after the bars
    self.fk_title.font = "objective";
    self.fk_title.fontscale = 3.5;
    self.fk_title.foreground = true;
    self.fk_title.shadown = 1;
    
    self.fk_title_low = newClientHudElem(self);
    self.fk_title_low.archived = false;
    self.fk_title_low.x = 0;
    self.fk_title_low.y = -45;
    self.fk_title_low.alignX = "center";
    self.fk_title_low.alignY = "bottom";
    self.fk_title_low.horzAlign = "center_safearea";
    self.fk_title_low.vertAlign = "bottom";
    self.fk_title_low.sort = 1; // force to draw after the bars
    self.fk_title_low.font = "objective";
    self.fk_title_low.fontscale = 2;
    self.fk_title_low.foreground = true;

    self.fk_title.alpha = 1;
    self.fk_title_low.alpha = 1;
    self.top_fk_shader.alpha = 0.5;
    self.bottom_fk_shader.alpha = 0.5;

    self.fk_title_low setText(attacker.name);
    
    if( !level.killcam_style )
        self.fk_title setText("GAME WINNING KILL");
    else
        self.fk_title setText("ROUND WINNING KILL");
}

onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
    if ( isDefined( level.gameEnded ) && level.gameEnded )
        return;

    if ( !isPlayer( attacker ) || attacker == self )
        return;

    team = attacker.pers["team"];
    if ( !isDefined( team ) || team == "spectator" )
        return;

    killInfo = [];
    killInfo["attacker"] = attacker;
    killInfo["attackerNumber"] = attacker getEntityNumber();
    killInfo["victim"] = self;
    killInfo["deathTime"] = GetTime()/1000;
    killInfo["attackerTeam"] = team;

    if ( isDefined( game["roundsplayed"] ) )
        killInfo["roundsPlayed"] = game["roundsplayed"] + 1;

    level.lastKillInfo = killInfo;
    level.showFinalKillcam = true;

    if ( level.teamBased && (team == "axis" || team == "allies") )
    {
        level.doFK[team] = true;
        level.KillInfo[team] = killInfo;
    }
    else if ( !level.teamBased )
        attacker.KillInfo = killInfo;
}

startFK( winner, roundKillcam )
{
    if ( !canStartFK( roundKillcam ) )
        return;

    killInfo = level.lastKillInfo;
    
    level.fk = true;
    
    for( i = 0; i < level.players.size; i ++)
    {
        player = level.players[i];
        
        player notify("beginFK", winner);
    }
    
    slowMotion();

}

canStartFK( roundKillcam )
{
    if ( !level.showFinalKillcam || !isDefined( level.lastKillInfo ) )
        return false;

    killInfo = level.lastKillInfo;

    if ( !isDefined( killInfo["attacker"] ) || !isDefined( killInfo["victim"] ) )
        return false;

    if ( !isPlayer( killInfo["attacker"] ) )
        return false;

    if ( roundKillcam && isDefined( killInfo["roundsPlayed"] ) && isDefined( game["roundsplayed"] ) && killInfo["roundsPlayed"] != game["roundsplayed"] )
        return false;

    return true;
}

resetFinalKillcam()
{
    level.lastKillInfo = undefined;
    level.showFinalKillcam = false;
    level.fk = false;
}

slowMotion()
{
   /* while(!isDefined(level.slowmostart))
        wait 0.05;
    
    wait level.slowmostart;
    
    SetDvar("timescale", ".3");
    for(i=0;i<level.players.size;i++)
        level.players[i] setclientdvar("timescale", ".3");
    
    wait 1.7;
    
    SetDvar("timescale", "1");
    for(i=0;i<level.players.size;i++)
        level.players[i] setclientdvar("timescale", "1");*/
}
