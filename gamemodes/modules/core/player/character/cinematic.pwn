#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// LS:RP Cinematic + Fade System
//-----------------------------------------------------------------------------

#define CINEMATIC_FADE_STEP          (25)
#define CINEMATIC_FADE_INTERVAL      (25)

#define CINEMATIC_SELECTOR_TIME      (8500)
#define CINEMATIC_ZOOM_STAGE_1       (4200)
#define CINEMATIC_ZOOM_STAGE_2       (2600)
forward Cinematic_StartTravelToPlayer(playerid);

#define CINEMATIC_TRAVEL_TIME        (5500)
#define CINEMATIC_SKY_Z              (145.0)
#define CINEMATIC_SKY_RADIUS         (35.0)
enum
{
    CINEMATIC_ACTION_NONE,
    CINEMATIC_ACTION_SELECTOR,
    CINEMATIC_ACTION_SPAWN,
    CINEMATIC_ACTION_NEW_CHARACTER
};
new PlayerText:s_CinematicFadeTD[MAX_PLAYERS];
#define CINEMATIC_VIEW_COUNT (5)
new bool:s_CinematicNewCharacter[MAX_PLAYERS];
new
    Float:s_CinematicTargetX[MAX_PLAYERS],
    Float:s_CinematicTargetY[MAX_PLAYERS],
    Float:s_CinematicTargetZ[MAX_PLAYERS],
    Float:s_CinematicTargetA[MAX_PLAYERS];
new const Float:g_CinematicCamera[CINEMATIC_VIEW_COUNT][3] =
{
    {1545.0, -1350.0, 125.0},
    {1465.0, -1700.0, 110.0},
    {1830.0, -1680.0, 105.0},
    {2235.0, -1660.0, 115.0},
    {2515.0, -1630.0, 105.0}
};

new const Float:g_CinematicLook[CINEMATIC_VIEW_COUNT][3] =
{
    {1510.0, -1400.0, 35.0},
    {1480.0, -1730.0, 25.0},
    {1850.0, -1740.0, 25.0},
    {2200.0, -1710.0, 25.0},
    {2495.0, -1687.0, 20.0}
};
#define NEW_CHARACTER_SKY_COUNT (6)
#define NEW_CHARACTER_SKY_WAIT  (1500)
new bool:s_CinematicLoginPreparing[MAX_PLAYERS];
forward Cinematic_LoginBeginTravel(playerid);
new const Float:g_NewCharacterSkyCamera[NEW_CHARACTER_SKY_COUNT][3] =
{
    {1480.0, -1660.0, 235.0},
    {1830.0, -1750.0, 245.0},
    {2160.0, -1660.0, 230.0},
    {2490.0, -1700.0, 240.0},
    {1320.0, -1350.0, 250.0},
    {2030.0, -1200.0, 260.0}
};

new const Float:g_NewCharacterSkyLook[NEW_CHARACTER_SKY_COUNT][3] =
{
    {1500.0, -1700.0, 25.0},
    {1850.0, -1800.0, 25.0},
    {2200.0, -1700.0, 25.0},
    {2495.0, -1687.0, 20.0},
    {1450.0, -1450.0, 30.0},
    {2050.0, -1450.0, 30.0}
};
new
    bool:s_CinematicFadeReady[MAX_PLAYERS],
    bool:s_CinematicFadeActive[MAX_PLAYERS],
    s_CinematicFadeAlpha[MAX_PLAYERS],
    s_CinematicFadeDirection[MAX_PLAYERS],
    s_CinematicFadeAction[MAX_PLAYERS],
    s_CinematicFadeTimer[MAX_PLAYERS],

    bool:s_CinematicSelectorActive[MAX_PLAYERS],
    s_CinematicSelectorView[MAX_PLAYERS],
    s_CinematicSelectorTimer[MAX_PLAYERS],

    bool:s_CinematicSpawnActive[MAX_PLAYERS],
    s_CinematicSpawnTimer[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Camera points around Los Santos
//-----------------------------------------------------------------------------

#define CINEMATIC_VIEW_COUNT (5)


new s_NewCharacterIntroTimer[MAX_PLAYERS];
forward Cinematic_NewCharacterBeginTravel(playerid);
new Float:s_CurrentCameraX[MAX_PLAYERS];
new Float:s_CurrentCameraY[MAX_PLAYERS];
new Float:s_CurrentCameraZ[MAX_PLAYERS];

new Float:s_CurrentLookX[MAX_PLAYERS];
new Float:s_CurrentLookY[MAX_PLAYERS];
new Float:s_CurrentLookZ[MAX_PLAYERS];
//-----------------------------------------------------------------------------
// Forwards
//-----------------------------------------------------------------------------

forward Cinematic_FadeTick(playerid);
forward Cinematic_SelectorNext(playerid);

forward Cinematic_StartZoomStageOne(playerid);
forward Cinematic_StartZoomStageTwo(playerid);
forward Cinematic_FinishSpawn(playerid);

//-----------------------------------------------------------------------------
// Fade TextDraw
//-----------------------------------------------------------------------------

Cinematic_CreateFade(playerid)
{
    if (s_CinematicFadeReady[playerid])
    {
        return 1;
    }

    s_CinematicFadeTD[playerid] = CreatePlayerTextDraw(playerid, 0.0, 0.0, "_");

    PlayerTextDrawLetterSize(playerid, s_CinematicFadeTD[playerid], 0.0, 50.0);
    PlayerTextDrawTextSize(playerid, s_CinematicFadeTD[playerid], 640.0, 448.0);
    PlayerTextDrawUseBox(playerid, s_CinematicFadeTD[playerid], true);
    PlayerTextDrawBoxColor(playerid, s_CinematicFadeTD[playerid], 0x00000000);

    s_CinematicFadeReady[playerid] = true;
    return 1;
}

Cinematic_SetFadeAlpha(playerid, alpha)
{
    if (alpha < 0) alpha = 0;
    if (alpha > 255) alpha = 255;

    s_CinematicFadeAlpha[playerid] = alpha;

    // 0x000000AA -> black + alpha.
    PlayerTextDrawBoxColor(playerid, s_CinematicFadeTD[playerid], alpha);
    return 1;
}

//-----------------------------------------------------------------------------
// Fade control
//-----------------------------------------------------------------------------

Cinematic_FadeOut(playerid, action)
{
    Cinematic_CreateFade(playerid);

    if (s_CinematicFadeTimer[playerid])
    {
        KillTimer(s_CinematicFadeTimer[playerid]);
    }

    s_CinematicFadeAction[playerid] = action;
    s_CinematicFadeDirection[playerid] = 1;
    s_CinematicFadeActive[playerid] = true;
    s_CinematicFadeAlpha[playerid] = 0;

    Cinematic_SetFadeAlpha(playerid, 0);
    PlayerTextDrawShow(playerid, s_CinematicFadeTD[playerid]);

    s_CinematicFadeTimer[playerid] = SetTimerEx("Cinematic_FadeTick", CINEMATIC_FADE_INTERVAL, true, "d", playerid);
    return 1;
}

Cinematic_FadeIn(playerid)
{
    Cinematic_CreateFade(playerid);

    if (s_CinematicFadeTimer[playerid])
    {
        KillTimer(s_CinematicFadeTimer[playerid]);
    }

    s_CinematicFadeDirection[playerid] = -1;
    s_CinematicFadeActive[playerid] = true;
    s_CinematicFadeAlpha[playerid] = 255;

    Cinematic_SetFadeAlpha(playerid, 255);
    PlayerTextDrawShow(playerid, s_CinematicFadeTD[playerid]);

    s_CinematicFadeTimer[playerid] = SetTimerEx("Cinematic_FadeTick", CINEMATIC_FADE_INTERVAL, true, "d", playerid);
    return 1;
}

public Cinematic_FadeTick(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicFadeActive[playerid])
    {
        return 0;
    }

    s_CinematicFadeAlpha[playerid] += CINEMATIC_FADE_STEP * s_CinematicFadeDirection[playerid];

    if (s_CinematicFadeDirection[playerid] > 0 && s_CinematicFadeAlpha[playerid] >= 255)
    {
        Cinematic_SetFadeAlpha(playerid, 255);

        KillTimer(s_CinematicFadeTimer[playerid]);
        s_CinematicFadeTimer[playerid] = 0;
        s_CinematicFadeActive[playerid] = false;

        new const action = s_CinematicFadeAction[playerid];
        s_CinematicFadeAction[playerid] = CINEMATIC_ACTION_NONE;

       switch (action)
        {
            case CINEMATIC_ACTION_SELECTOR:
            {
                Cinematic_SetupSelector(playerid);
            }
         
            case CINEMATIC_ACTION_SPAWN:
            {
                Cinematic_SetupSpawn(playerid);
            }
         
            case CINEMATIC_ACTION_NEW_CHARACTER:
            {
                Cinematic_SetupNewCharacterSky(playerid);
            }
        }

        return 1;
    }

    if (s_CinematicFadeDirection[playerid] < 0 && s_CinematicFadeAlpha[playerid] <= 0)
    {
        Cinematic_SetFadeAlpha(playerid, 0);

        KillTimer(s_CinematicFadeTimer[playerid]);
        s_CinematicFadeTimer[playerid] = 0;
        s_CinematicFadeActive[playerid] = false;

        PlayerTextDrawHide(playerid, s_CinematicFadeTD[playerid]);
        return 1;
    }

    Cinematic_SetFadeAlpha(playerid, s_CinematicFadeAlpha[playerid]);
    return 1;
}

//-----------------------------------------------------------------------------
// Character Selection camera
//-----------------------------------------------------------------------------

stock bool:Cinematic_IsSelectorActive(playerid)
{
    return s_CinematicSelectorActive[playerid];
}

Cinematic_StartSelector(playerid)
{
    Cinematic_StopSpawn(playerid);
    Cinematic_StopSelector(playerid);

    TogglePlayerSpectating(playerid, true);

    s_CinematicSelectorActive[playerid] = true;
    s_CinematicSelectorView[playerid] = random(CINEMATIC_VIEW_COUNT);

    Cinematic_FadeOut(playerid, CINEMATIC_ACTION_SELECTOR);
    return 1;
}

Cinematic_SetupSelector(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    TogglePlayerSpectating(playerid, true);

    new const view = s_CinematicSelectorView[playerid];
    s_CurrentCameraX[playerid] = g_CinematicCamera[view][0];
    s_CurrentCameraY[playerid] = g_CinematicCamera[view][1];
    s_CurrentCameraZ[playerid] = g_CinematicCamera[view][2];
    
    s_CurrentLookX[playerid] = g_CinematicLook[view][0];
    s_CurrentLookY[playerid] = g_CinematicLook[view][1];
    s_CurrentLookZ[playerid] = g_CinematicLook[view][2];

    SetPlayerCameraPos(playerid,
        g_CinematicCamera[view][0],
        g_CinematicCamera[view][1],
        g_CinematicCamera[view][2]
    );

    SetPlayerCameraLookAt(playerid,
        g_CinematicLook[view][0],
        g_CinematicLook[view][1],
        g_CinematicLook[view][2],
        CAMERA_CUT
    );

    CharacterSelector_OpenUI(playerid);

    s_CinematicSelectorTimer[playerid] = SetTimerEx("Cinematic_SelectorNext", CINEMATIC_SELECTOR_TIME, false, "d", playerid);

    Cinematic_FadeIn(playerid);
    return 1;
}

public Cinematic_SelectorNext(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicSelectorActive[playerid])
    {
        return 0;
    }

    new const oldView = s_CinematicSelectorView[playerid];

    s_CinematicSelectorView[playerid]++;

    if (s_CinematicSelectorView[playerid] >= CINEMATIC_VIEW_COUNT)
    {
        s_CinematicSelectorView[playerid] = 0;
    }

    new const newView = s_CinematicSelectorView[playerid];

    InterpolateCameraPos(playerid,
        g_CinematicCamera[oldView][0],
        g_CinematicCamera[oldView][1],
        g_CinematicCamera[oldView][2],
        g_CinematicCamera[newView][0],
        g_CinematicCamera[newView][1],
        g_CinematicCamera[newView][2],
        CINEMATIC_SELECTOR_TIME,
        CAMERA_MOVE
    );

    InterpolateCameraLookAt(playerid,
        g_CinematicLook[oldView][0],
        g_CinematicLook[oldView][1],
        g_CinematicLook[oldView][2],
        g_CinematicLook[newView][0],
        g_CinematicLook[newView][1],
        g_CinematicLook[newView][2],
        CINEMATIC_SELECTOR_TIME,
        CAMERA_MOVE
    );
    s_CurrentCameraX[playerid] = g_CinematicCamera[newView][0];
    s_CurrentCameraY[playerid] = g_CinematicCamera[newView][1];
    s_CurrentCameraZ[playerid] = g_CinematicCamera[newView][2];
    
    s_CurrentLookX[playerid] = g_CinematicLook[newView][0];
    s_CurrentLookY[playerid] = g_CinematicLook[newView][1];
    s_CurrentLookZ[playerid] = g_CinematicLook[newView][2];

    s_CinematicSelectorTimer[playerid] = SetTimerEx("Cinematic_SelectorNext", CINEMATIC_SELECTOR_TIME, false, "d", playerid);
    return 1;
}

Cinematic_StopSelector(playerid)
{
    if (s_CinematicSelectorTimer[playerid])
    {
        KillTimer(s_CinematicSelectorTimer[playerid]);
        s_CinematicSelectorTimer[playerid] = 0;
    }

    s_CinematicSelectorActive[playerid] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// GTA V style spawn transition
//-----------------------------------------------------------------------------

stock bool:Cinematic_IsSpawnActive(playerid)
{
    return s_CinematicSpawnActive[playerid];
}
Cinematic_StartSpawn(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    // Lay dung vi tri camera dang hien tren man hinh.
    Cinematic_CaptureCurrentCamera(playerid);

    CharacterSelector_CloseUI(playerid);

    if (s_CinematicSelectorTimer[playerid])
    {
        KillTimer(s_CinematicSelectorTimer[playerid]);
        s_CinematicSelectorTimer[playerid] = 0;
    }

    s_CinematicSelectorActive[playerid] = false;

    s_CinematicSpawnActive[playerid] = true;
    s_CinematicLoginPreparing[playerid] = true;
    s_CinematicNewCharacter[playerid] = false;

    s_CinematicTargetX[playerid] = s_CharacterPosX[playerid];
    s_CinematicTargetY[playerid] = s_CharacterPosY[playerid];
    s_CinematicTargetZ[playerid] = s_CharacterPosZ[playerid];
    s_CinematicTargetA[playerid] = s_CharacterPosA[playerid];

    // Spawn khi man hinh da den.
    Cinematic_FadeOut(playerid, CINEMATIC_ACTION_SPAWN);
    return 1;
}

Cinematic_SetupSpawn(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    if (!Character_SetPlayerICName(playerid))
    {
        Kick(playerid);
        return 0;
    }

    SetPlayerInterior(playerid, s_CharacterInterior[playerid]);
    SetPlayerVirtualWorld(playerid, s_CharacterVirtualWorld[playerid]);

    SetSpawnInfo(playerid, NO_TEAM, s_CharacterSkin[playerid],
        s_CinematicTargetX[playerid],
        s_CinematicTargetY[playerid],
        s_CinematicTargetZ[playerid],
        s_CinematicTargetA[playerid]
    );

    // Luc nay man hinh dang den hoan toan.
    // Camera co bi GTA reset cung khong the nhin thay.
    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        TogglePlayerSpectating(playerid, false);
    }
    else
    {
        SpawnPlayer(playerid);
    }

    return 1;
}

Cinematic_PreparePlayer(playerid)
{
    SetPlayerInterior(playerid, s_CharacterInterior[playerid]);
    SetPlayerVirtualWorld(playerid, s_CharacterVirtualWorld[playerid]);

    SetPlayerSkin(playerid, s_CharacterSkin[playerid]);

    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, s_CharacterCash[playerid]);

    SetPlayerScore(playerid, s_CharacterLevel[playerid]);
    SetPlayerHealth(playerid, s_CharacterHealth[playerid]);
    SetPlayerArmour(playerid, s_CharacterArmour[playerid]);

    SetPlayerPos(playerid, s_CinematicTargetX[playerid], s_CinematicTargetY[playerid], s_CinematicTargetZ[playerid]);
    SetPlayerFacingAngle(playerid, s_CinematicTargetA[playerid]);

    TogglePlayerControllable(playerid, false);

    // Camera hien tai DA o tren khong sau stage Travel.
    // Khong SetPlayerCameraPos lai nua.

    s_CinematicSpawnTimer[playerid] = SetTimerEx("Cinematic_StartZoomStageOne", 300, false, "d", playerid);
    return 1;
}

public Cinematic_StartZoomStageOne(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }

    new Float:targetX = s_CinematicTargetX[playerid];
    new Float:targetY = s_CinematicTargetY[playerid];
    new Float:targetZ = s_CinematicTargetZ[playerid];

    InterpolateCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid],
        targetX + 5.0,
        targetY - 8.0,
        targetZ + 30.0,
        3000,
        CAMERA_MOVE
    );

    InterpolateCameraLookAt(playerid,
        targetX,
        targetY,
        targetZ,
        targetX,
        targetY,
        targetZ + 1.0,
        3000,
        CAMERA_MOVE
    );

    s_CurrentCameraX[playerid] = targetX + 5.0;
    s_CurrentCameraY[playerid] = targetY - 8.0;
    s_CurrentCameraZ[playerid] = targetZ + 30.0;

    s_CinematicSpawnTimer[playerid] = SetTimerEx("Cinematic_StartZoomStageTwo", 3000, false, "d", playerid);
    return 1;
}
public Cinematic_StartZoomStageTwo(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }

    new Float:targetX = s_CinematicTargetX[playerid];
    new Float:targetY = s_CinematicTargetY[playerid];
    new Float:targetZ = s_CinematicTargetZ[playerid];

    InterpolateCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid],
        targetX,
        targetY - 4.0,
        targetZ + 2.0,
        2200,
        CAMERA_MOVE
    );

    InterpolateCameraLookAt(playerid,
        targetX,
        targetY,
        targetZ + 1.0,
        targetX,
        targetY,
        targetZ + 1.0,
        2200,
        CAMERA_MOVE
    );

    s_CurrentCameraX[playerid] = targetX;
    s_CurrentCameraY[playerid] = targetY - 4.0;
    s_CurrentCameraZ[playerid] = targetZ + 2.0;

    s_CinematicSpawnTimer[playerid] = SetTimerEx("Cinematic_FinishSpawn", 2200, false, "d", playerid);
    return 1;
}
public Cinematic_FinishSpawn(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }

    s_CinematicSpawnActive[playerid] = false;
    s_CinematicLoginPreparing[playerid] = false;
    s_CinematicNewCharacter[playerid] = false;
    s_CinematicSpawnTimer[playerid] = 0;

    SetCameraBehindPlayer(playerid);
    TogglePlayerControllable(playerid, true);

    SendClientMessage(playerid, COLOR_WHITE, "Chao mung tro lai Los Santos.");
    return 1;
}
Cinematic_StopSpawn(playerid)
{
    if (s_CinematicSpawnTimer[playerid])
    {
        KillTimer(s_CinematicSpawnTimer[playerid]);
        s_CinematicSpawnTimer[playerid] = 0;
    }

    s_CinematicSpawnActive[playerid] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// Cleanup
//-----------------------------------------------------------------------------

hook OnPlayerConnect(playerid)
{
    s_CinematicLoginPreparing[playerid] = false;
    s_NewCharacterIntroTimer[playerid] = 0;
    s_CinematicFadeReady[playerid] = false;
    s_CinematicNewCharacter[playerid] = false;
    s_CinematicFadeActive[playerid] = false;
    s_CinematicFadeTimer[playerid] = 0;

    s_CinematicSelectorActive[playerid] = false;
    s_CinematicSelectorTimer[playerid] = 0;
    s_CinematicSelectorView[playerid] = 0;

    s_CinematicSpawnActive[playerid] = false;
    s_CinematicSpawnTimer[playerid] = 0;

    s_CinematicTargetX[playerid] = GANTON_SPAWN_X;
    s_CinematicTargetY[playerid] = GANTON_SPAWN_Y;
    s_CinematicTargetZ[playerid] = GANTON_SPAWN_Z;
    s_CinematicTargetA[playerid] = GANTON_SPAWN_A;

    s_CinematicFadeTD[playerid] = PlayerText:INVALID_TEXT_DRAW;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    if (s_NewCharacterIntroTimer[playerid])
    {
        KillTimer(s_NewCharacterIntroTimer[playerid]);
        s_NewCharacterIntroTimer[playerid] = 0;
    }

    if (s_CinematicFadeTimer[playerid]) KillTimer(s_CinematicFadeTimer[playerid]);
    if (s_CinematicSelectorTimer[playerid]) KillTimer(s_CinematicSelectorTimer[playerid]);
    if (s_CinematicSpawnTimer[playerid]) KillTimer(s_CinematicSpawnTimer[playerid]);

    if (s_CinematicFadeReady[playerid])
    {
        PlayerTextDrawDestroy(playerid, s_CinematicFadeTD[playerid]);
    }
    s_CinematicNewCharacter[playerid] = false;

    return 1;
}

public Cinematic_StartTravelToPlayer(playerid)
{
    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }
    

    new Float:targetX = s_CinematicTargetX[playerid];
    new Float:targetY = s_CinematicTargetY[playerid];
    new Float:targetZ = s_CinematicTargetZ[playerid];

    new Float:skyX = targetX + CINEMATIC_SKY_RADIUS;
    new Float:skyY = targetY - CINEMATIC_SKY_RADIUS;
    new Float:skyZ = targetZ + CINEMATIC_SKY_Z;

    InterpolateCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid],
        skyX,
        skyY,
        skyZ,
        CINEMATIC_TRAVEL_TIME,
        CAMERA_MOVE
    );

    InterpolateCameraLookAt(playerid,
        s_CurrentLookX[playerid],
        s_CurrentLookY[playerid],
        s_CurrentLookZ[playerid],
        targetX,
        targetY,
        targetZ,
        CINEMATIC_TRAVEL_TIME,
        CAMERA_MOVE
    );

    s_CurrentCameraX[playerid] = skyX;
    s_CurrentCameraY[playerid] = skyY;
    s_CurrentCameraZ[playerid] = skyZ;

    s_CurrentLookX[playerid] = targetX;
    s_CurrentLookY[playerid] = targetY;
    s_CurrentLookZ[playerid] = targetZ;

    s_CinematicSpawnTimer[playerid] = SetTimerEx("Cinematic_StartZoomStageOne", CINEMATIC_TRAVEL_TIME, false, "d", playerid);

    return 1;
}
//-----------------------------------------------------------------------------
// New Character Intro
//-----------------------------------------------------------------------------

Cinematic_StartNewCharacter(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    Cinematic_StopSelector(playerid);
    Cinematic_StopSpawn(playerid);

    if (s_NewCharacterIntroTimer[playerid])
    {
        KillTimer(s_NewCharacterIntroTimer[playerid]);
        s_NewCharacterIntroTimer[playerid] = 0;
    }

    s_CinematicSpawnActive[playerid] = true;
    s_CinematicNewCharacter[playerid] = true;

    s_CinematicTargetX[playerid] = GANTON_SPAWN_X;
    s_CinematicTargetY[playerid] = GANTON_SPAWN_Y;
    s_CinematicTargetZ[playerid] = GANTON_SPAWN_Z;
    s_CinematicTargetA[playerid] = GANTON_SPAWN_A;

    // Dang o interior Character Creator.
    // Fade den truoc khi chuyen ra Los Santos.
    Cinematic_FadeOut(playerid, CINEMATIC_ACTION_NEW_CHARACTER);
    return 1;
}
Cinematic_SetupNewCharacterSky(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new const view = random(NEW_CHARACTER_SKY_COUNT);

    // Man hinh dang den nen chuyen player ra ngoai ngay luc nay.
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    SetPlayerSkin(playerid, s_CharacterSkin[playerid]);

    SetPlayerPos(playerid, s_CinematicTargetX[playerid], s_CinematicTargetY[playerid], s_CinematicTargetZ[playerid]);
    SetPlayerFacingAngle(playerid, s_CinematicTargetA[playerid]);

    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, s_CharacterCash[playerid]);

    SetPlayerScore(playerid, s_CharacterLevel[playerid]);
    SetPlayerHealth(playerid, s_CharacterHealth[playerid]);
    SetPlayerArmour(playerid, s_CharacterArmour[playerid]);

    // Player da ton tai trong world, chi khoa dieu khien.
    TogglePlayerControllable(playerid, false);

    // KHONG TogglePlayerSpectating o day.
    // KHONG SpawnPlayer o day.

    s_CurrentCameraX[playerid] = g_NewCharacterSkyCamera[view][0];
    s_CurrentCameraY[playerid] = g_NewCharacterSkyCamera[view][1];
    s_CurrentCameraZ[playerid] = g_NewCharacterSkyCamera[view][2];

    s_CurrentLookX[playerid] = g_NewCharacterSkyLook[view][0];
    s_CurrentLookY[playerid] = g_NewCharacterSkyLook[view][1];
    s_CurrentLookZ[playerid] = g_NewCharacterSkyLook[view][2];

    SetPlayerCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid]
    );

    SetPlayerCameraLookAt(playerid,
        s_CurrentLookX[playerid],
        s_CurrentLookY[playerid],
        s_CurrentLookZ[playerid],
        CAMERA_CUT
    );

    Cinematic_FadeIn(playerid);

    s_NewCharacterIntroTimer[playerid] = SetTimerEx(
        "Cinematic_NewCharacterBeginTravel",
        NEW_CHARACTER_SKY_WAIT,
        false,
        "d",
        playerid
    );

    return 1;
}

public Cinematic_NewCharacterBeginTravel(playerid)
{
    s_NewCharacterIntroTimer[playerid] = 0;

    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }

    // Reuse stage:
    // camera hien tai -> tren troi khu vuc nhan vat -> zoom xuong player.
    Cinematic_StartTravelToPlayer(playerid);
    return 1;
}
Cinematic_CaptureCurrentCamera(playerid)
{
    new Float:frontX;
    new Float:frontY;
    new Float:frontZ;

    GetPlayerCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid]
    );

    GetPlayerCameraFrontVector(playerid, frontX, frontY, frontZ);

    s_CurrentLookX[playerid] = s_CurrentCameraX[playerid] + (frontX * 100.0);
    s_CurrentLookY[playerid] = s_CurrentCameraY[playerid] + (frontY * 100.0);
    s_CurrentLookZ[playerid] = s_CurrentCameraZ[playerid] + (frontZ * 100.0);

    return 1;
}
Cinematic_PrepareLoginPlayer(playerid)
{
    SetPlayerInterior(playerid, s_CharacterInterior[playerid]);
    SetPlayerVirtualWorld(playerid, s_CharacterVirtualWorld[playerid]);

    SetPlayerSkin(playerid, s_CharacterSkin[playerid]);

    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, s_CharacterCash[playerid]);

    SetPlayerScore(playerid, s_CharacterLevel[playerid]);
    SetPlayerHealth(playerid, s_CharacterHealth[playerid]);
    SetPlayerArmour(playerid, s_CharacterArmour[playerid]);

    SetPlayerPos(playerid, s_CinematicTargetX[playerid], s_CinematicTargetY[playerid], s_CinematicTargetZ[playerid]);
    SetPlayerFacingAngle(playerid, s_CinematicTargetA[playerid]);

    TogglePlayerControllable(playerid, false);

    // QUAN TRONG:
    // Spawn vua reset camera, nhung man hinh dang den.
    // Dua camera tro lai dung vi tri selector da luu.
    SetPlayerCameraPos(playerid,
        s_CurrentCameraX[playerid],
        s_CurrentCameraY[playerid],
        s_CurrentCameraZ[playerid]
    );

    SetPlayerCameraLookAt(playerid,
        s_CurrentLookX[playerid],
        s_CurrentLookY[playerid],
        s_CurrentLookZ[playerid],
        CAMERA_CUT
    );

    s_CinematicSpawnTimer[playerid] = SetTimerEx("Cinematic_LoginBeginTravel", 150, false, "d", playerid);
    return 1;
}
public Cinematic_LoginBeginTravel(playerid)
{
    s_CinematicSpawnTimer[playerid] = 0;

    if (!IsPlayerConnected(playerid) || !s_CinematicSpawnActive[playerid])
    {
        return 0;
    }

    s_CinematicLoginPreparing[playerid] = false;

    // Bay tu camera selector ve nhan vat.
    Cinematic_StartTravelToPlayer(playerid);

    // Man hinh sang dan trong luc camera bat dau bay.
    Cinematic_FadeIn(playerid);

    return 1;
}
