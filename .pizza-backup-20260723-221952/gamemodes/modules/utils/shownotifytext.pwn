//-----------------------------------------------------------------------------
// Shared player notification TextDraws.
//
// Type 1: small text only at the bottom-center, with a black outline.
// Type 2: modern notification cards below the money HUD on the right.
// Up to ten notifications of each type can be visible at once.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

#define NOTIFY_TYPE_BASIC      (1)
#define NOTIFY_TYPE_MODERN     (2)
#define NOTIFY_MAX_SLOTS       (10)
#define NOTIFY_DEFAULT_TIME    (3500)
#define NOTIFY_MESSAGE_LENGTH  (144)

new
    PlayerText:s_NotifyBasicText[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    PlayerText:s_NotifyModernBody[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    PlayerText:s_NotifyModernAccent[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    PlayerText:s_NotifyModernTitle[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    PlayerText:s_NotifyModernText[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    s_NotifyModernMessage[MAX_PLAYERS][NOTIFY_MAX_SLOTS][NOTIFY_MESSAGE_LENGTH],
    s_NotifyModernExpireTick[MAX_PLAYERS][NOTIFY_MAX_SLOTS],
    s_NotifyTextTimer[MAX_PLAYERS][3][NOTIFY_MAX_SLOTS],
    bool:s_NotifyTextUsed[MAX_PLAYERS][3][NOTIFY_MAX_SLOTS],
    s_NotifyTextNextSlot[MAX_PLAYERS][3];

forward NotifyText_HideTimer(playerid, type, slot);

stock NotifyText_GetBasicY(slot, &Float:y)
{
    y = 396.0 - (slot * 11.0);
    return 1;
}

stock NotifyText_GetModernY(slot, &Float:y)
{
    y = 102.0 + (slot * 20.0);
    return 1;
}

stock NotifyText_Reset(playerid)
{
    for (new type = NOTIFY_TYPE_BASIC; type <= NOTIFY_TYPE_MODERN; type++)
    {
        s_NotifyTextNextSlot[playerid][type] = 0;
        for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
        {
            s_NotifyTextTimer[playerid][type][slot] = 0;
            s_NotifyTextUsed[playerid][type][slot] = false;
            s_NotifyBasicText[playerid][slot] = INVALID_PLAYER_TEXT_DRAW;
            s_NotifyModernBody[playerid][slot] = INVALID_PLAYER_TEXT_DRAW;
            s_NotifyModernAccent[playerid][slot] = INVALID_PLAYER_TEXT_DRAW;
            s_NotifyModernTitle[playerid][slot] = INVALID_PLAYER_TEXT_DRAW;
            s_NotifyModernText[playerid][slot] = INVALID_PLAYER_TEXT_DRAW;
            s_NotifyModernMessage[playerid][slot][0] = 0;
            s_NotifyModernExpireTick[playerid][slot] = 0;
        }
    }
    return 1;
}

stock NotifyText_Create(playerid)
{
    for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
    {
        new Float:basicY;
        new Float:modernY;
        NotifyText_GetBasicY(slot, basicY);
        NotifyText_GetModernY(slot, modernY);

        // Type 1: deliberately text only. There is no box, panel or background.
        new PlayerText:textdraw =
            CreatePlayerTextDraw(playerid, 320.0, basicY, "_");
        PlayerTextDrawAlignment(playerid, textdraw, TEXT_DRAW_ALIGN_CENTER);
        PlayerTextDrawLetterSize(playerid, textdraw, 0.14, 0.62);
        PlayerTextDrawColor(playerid, textdraw, 0xFFFFFFFF);
        PlayerTextDrawBackgroundColor(playerid, textdraw, 0x000000FF);
        PlayerTextDrawSetOutline(playerid, textdraw, 1);
        PlayerTextDrawSetShadow(playerid, textdraw, 0);
        PlayerTextDrawSetProportional(playerid, textdraw, true);
        PlayerTextDrawFont(playerid, textdraw, TEXT_DRAW_FONT_1);
        s_NotifyBasicText[playerid][slot] = textdraw;

        // Type 2: modern card, stacked below the money HUD.
        s_NotifyModernBody[playerid][slot] =
            CreatePlayerTextDraw(playerid, 468.0, modernY, "_");
        PlayerTextDrawLetterSize(playerid, s_NotifyModernBody[playerid][slot], 0.0, 1.62);
        PlayerTextDrawTextSize(playerid, s_NotifyModernBody[playerid][slot], 624.0, 0.0);
        PlayerTextDrawUseBox(playerid, s_NotifyModernBody[playerid][slot], true);
        PlayerTextDrawBoxColor(playerid, s_NotifyModernBody[playerid][slot], 0x09120FEE);

        s_NotifyModernAccent[playerid][slot] =
            CreatePlayerTextDraw(playerid, 468.0, modernY, "_");
        PlayerTextDrawLetterSize(playerid, s_NotifyModernAccent[playerid][slot], 0.0, 1.62);
        PlayerTextDrawTextSize(playerid, s_NotifyModernAccent[playerid][slot], 473.0, 0.0);
        PlayerTextDrawUseBox(playerid, s_NotifyModernAccent[playerid][slot], true);
        PlayerTextDrawBoxColor(playerid, s_NotifyModernAccent[playerid][slot], 0x1F9B60FF);

        s_NotifyModernTitle[playerid][slot] =
            CreatePlayerTextDraw(playerid, 480.0, modernY + 2.5, "THONG BAO");
        PlayerTextDrawLetterSize(playerid, s_NotifyModernTitle[playerid][slot], 0.11, 0.48);
        PlayerTextDrawColor(playerid, s_NotifyModernTitle[playerid][slot], 0x42D98EFF);
        PlayerTextDrawBackgroundColor(playerid, s_NotifyModernTitle[playerid][slot], 0x000000FF);
        PlayerTextDrawSetOutline(playerid, s_NotifyModernTitle[playerid][slot], 1);
        PlayerTextDrawSetShadow(playerid, s_NotifyModernTitle[playerid][slot], 0);
        PlayerTextDrawSetProportional(playerid, s_NotifyModernTitle[playerid][slot], true);
        PlayerTextDrawFont(playerid, s_NotifyModernTitle[playerid][slot], TEXT_DRAW_FONT_1);

        s_NotifyModernText[playerid][slot] =
            CreatePlayerTextDraw(playerid, 480.0, modernY + 10.0, "_");
        PlayerTextDrawLetterSize(playerid, s_NotifyModernText[playerid][slot], 0.13, 0.55);
        PlayerTextDrawTextSize(playerid, s_NotifyModernText[playerid][slot], 617.0, 0.0);
        PlayerTextDrawColor(playerid, s_NotifyModernText[playerid][slot], 0xE8EEE9FF);
        PlayerTextDrawBackgroundColor(playerid, s_NotifyModernText[playerid][slot], 0x000000FF);
        PlayerTextDrawSetOutline(playerid, s_NotifyModernText[playerid][slot], 1);
        PlayerTextDrawSetShadow(playerid, s_NotifyModernText[playerid][slot], 0);
        PlayerTextDrawSetProportional(playerid, s_NotifyModernText[playerid][slot], true);
        PlayerTextDrawFont(playerid, s_NotifyModernText[playerid][slot], TEXT_DRAW_FONT_1);
    }
    return 1;
}

stock NotifyText_HideSlot(playerid, type, slot)
{
    if (slot < 0 || slot >= NOTIFY_MAX_SLOTS)
    {
        return 0;
    }

    if (type == NOTIFY_TYPE_BASIC)
    {
        PlayerTextDrawHide(playerid, s_NotifyBasicText[playerid][slot]);
    }
    else if (type == NOTIFY_TYPE_MODERN)
    {
        PlayerTextDrawHide(playerid, s_NotifyModernBody[playerid][slot]);
        PlayerTextDrawHide(playerid, s_NotifyModernAccent[playerid][slot]);
        PlayerTextDrawHide(playerid, s_NotifyModernTitle[playerid][slot]);
        PlayerTextDrawHide(playerid, s_NotifyModernText[playerid][slot]);
        s_NotifyModernMessage[playerid][slot][0] = 0;
        s_NotifyModernExpireTick[playerid][slot] = 0;
    }

    if (type >= NOTIFY_TYPE_BASIC && type <= NOTIFY_TYPE_MODERN)
    {
        s_NotifyTextUsed[playerid][type][slot] = false;
        s_NotifyTextTimer[playerid][type][slot] = 0;
    }
    return 1;
}

stock NotifyText_ShowModernSlot(playerid, slot, const message[], duration)
{
    if (slot < 0 || slot >= NOTIFY_MAX_SLOTS || duration <= 0)
    {
        return 0;
    }

    if (s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot])
    {
        KillTimer(s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot]);
        s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot] = 0;
    }

    format(s_NotifyModernMessage[playerid][slot], NOTIFY_MESSAGE_LENGTH, "%s", message);
    s_NotifyModernExpireTick[playerid][slot] = GetTickCount() + duration;
    s_NotifyTextUsed[playerid][NOTIFY_TYPE_MODERN][slot] = true;

    PlayerTextDrawSetString(playerid, s_NotifyModernText[playerid][slot], message);
    PlayerTextDrawShow(playerid, s_NotifyModernBody[playerid][slot]);
    PlayerTextDrawShow(playerid, s_NotifyModernAccent[playerid][slot]);
    PlayerTextDrawShow(playerid, s_NotifyModernTitle[playerid][slot]);
    PlayerTextDrawShow(playerid, s_NotifyModernText[playerid][slot]);

    s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot] =
        SetTimerEx("NotifyText_HideTimer", duration, false, "ddd", playerid, NOTIFY_TYPE_MODERN, slot);
    return 1;
}

stock NotifyText_PushModern(playerid, const message[], duration)
{
    new const now = GetTickCount();

    // Moi notify luon nam o slot 0. Cac notify cu bi day xuong duoi.
    for (new slot = NOTIFY_MAX_SLOTS - 1; slot > 0; slot--)
    {
        new const source = slot - 1;

        if (!s_NotifyTextUsed[playerid][NOTIFY_TYPE_MODERN][source])
        {
            if (s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot])
            {
                KillTimer(s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot]);
            }

            NotifyText_HideSlot(playerid, NOTIFY_TYPE_MODERN, slot);
            continue;
        }

        new const remaining = s_NotifyModernExpireTick[playerid][source] - now;

        if (remaining <= 0)
        {
            if (s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot])
            {
                KillTimer(s_NotifyTextTimer[playerid][NOTIFY_TYPE_MODERN][slot]);
            }

            NotifyText_HideSlot(playerid, NOTIFY_TYPE_MODERN, slot);
            continue;
        }

        NotifyText_ShowModernSlot(playerid, slot, s_NotifyModernMessage[playerid][source], remaining);
    }

    NotifyText_ShowModernSlot(playerid, 0, message, duration);
    return 1;
}

stock NotifyText_Hide(playerid, type)
{
    for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
    {
        NotifyText_HideSlot(playerid, type, slot);
    }
    return 1;
}

stock NotifyText_FindSlot(playerid, type)
{
    for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
    {
        if (!s_NotifyTextUsed[playerid][type][slot])
        {
            return slot;
        }
    }

    new const slot = s_NotifyTextNextSlot[playerid][type];
    s_NotifyTextNextSlot[playerid][type] =
        (s_NotifyTextNextSlot[playerid][type] + 1) % NOTIFY_MAX_SLOTS;
    if (s_NotifyTextTimer[playerid][type][slot])
    {
        KillTimer(s_NotifyTextTimer[playerid][type][slot]);
    }
    NotifyText_HideSlot(playerid, type, slot);
    return slot;
}

stock ShowNotifyText(
    playerid,
    type,
    const message[],
    duration = NOTIFY_DEFAULT_TIME
)
{
    if (!IsPlayerConnected(playerid) ||
        (type != NOTIFY_TYPE_BASIC && type != NOTIFY_TYPE_MODERN))
    {
        return 0;
    }

    if (duration < 500)
    {
        duration = 500;
    }

    if (type == NOTIFY_TYPE_MODERN)
    {
        return NotifyText_PushModern(playerid, message, duration);
    }

    new const slot = NotifyText_FindSlot(playerid, type);
    s_NotifyTextUsed[playerid][type][slot] = true;

    PlayerTextDrawSetString(
        playerid,
        s_NotifyBasicText[playerid][slot],
        message
    );

    PlayerTextDrawShow(playerid, s_NotifyBasicText[playerid][slot]);

    s_NotifyTextTimer[playerid][type][slot] =
        SetTimerEx("NotifyText_HideTimer", duration, false, "ddd", playerid, type, slot);
    return 1;
}

public NotifyText_HideTimer(playerid, type, slot)
{
    if (IsPlayerConnected(playerid))
    {
        NotifyText_HideSlot(playerid, type, slot);
    }
    return 1;
}

hook OnGameModeInit()
{
    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        NotifyText_Reset(playerid);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    NotifyText_Reset(playerid);
    NotifyText_Create(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    for (new type = NOTIFY_TYPE_BASIC; type <= NOTIFY_TYPE_MODERN; type++)
    {
        for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
        {
            if (s_NotifyTextTimer[playerid][type][slot])
            {
                KillTimer(s_NotifyTextTimer[playerid][type][slot]);
            }
        }
    }

    for (new slot = 0; slot < NOTIFY_MAX_SLOTS; slot++)
    {
        PlayerTextDrawDestroy(playerid, s_NotifyBasicText[playerid][slot]);
        PlayerTextDrawDestroy(playerid, s_NotifyModernBody[playerid][slot]);
        PlayerTextDrawDestroy(playerid, s_NotifyModernAccent[playerid][slot]);
        PlayerTextDrawDestroy(playerid, s_NotifyModernTitle[playerid][slot]);
        PlayerTextDrawDestroy(playerid, s_NotifyModernText[playerid][slot]);
    }
    NotifyText_Reset(playerid);
    return 1;
}
