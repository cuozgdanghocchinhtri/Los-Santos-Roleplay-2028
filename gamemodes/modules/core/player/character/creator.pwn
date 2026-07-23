#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// LS:RP Character Creator
//-----------------------------------------------------------------------------

#define CREATOR_INTERIOR             (3)
#define CREATOR_WORLD_BASE           (15000)

// Johnson House
#define CREATOR_POS_X                (2496.0549)
#define CREATOR_POS_Y                (-1693.6500)
#define CREATOR_POS_Z                (1014.7422)
#define CREATOR_POS_A                (180.0)

#define CREATOR_CAMERA_X             (2496.0549)
#define CREATOR_CAMERA_Y             (-1696.6000)
#define CREATOR_CAMERA_Z             (1015.5500)

#define CREATOR_CAMERA_LOOK_X        (2496.0549)
#define CREATOR_CAMERA_LOOK_Y        (-1693.6500)
#define CREATOR_CAMERA_LOOK_Z        (1015.3500)

#define CREATOR_SKINS_PER_GROUP      (6)

#define CREATOR_COLOR_WHITE          (0xFFFFFFFF)
#define CREATOR_COLOR_GREY           (0xB8B8B8CC)
#define CREATOR_COLOR_RED            (0xE33131FF)
#define CREATOR_COLOR_PANEL          (0x000000A0)
#define CREATOR_COLOR_BUTTON         (0x151515DD)
#define CREATOR_COLOR_HOVER          (0xE33131FF)

//-----------------------------------------------------------------------------
// Skin groups
// gender -> skin tone -> skins
//-----------------------------------------------------------------------------

new const g_CreatorSkins[2][3][CREATOR_SKINS_PER_GROUP] =
{
    // Nam
    {
        {20, 46, 98, 147, 186, 187},
        {28, 29, 47, 48, 60, 120},
        {7, 21, 22, 25, 26, 67}
    },

    // Nu
    {
        {12, 40, 41, 55, 56, 91},
        {13, 69, 76, 89, 138, 139},
        {9, 10, 11, 63, 64, 190}
    }
};

new const g_SkinToneNames[][] =
{
    "Sang",
    "Trung binh",
    "Toi"
};

new const g_BirthPlaceNames[][] =
{
    "Los Santos",
    "San Fierro",
    "Las Venturas",
    "Noi khac"
};

new const g_MaleVoiceNames[][] =
{
    "Tram",
    "Trung",
    "Tre",
    "Khan"
};

new const g_FemaleVoiceNames[][] =
{
    "Diu",
    "Trung",
    "Tre",
    "Tram"
};

//-----------------------------------------------------------------------------
// Player TextDraws
//-----------------------------------------------------------------------------
enum
{
    CreatorTD_Panel,
    CreatorTD_Title,
    CreatorTD_Subtitle,
    CreatorTD_Name,

    CreatorTD_GenderLabel,
    CreatorTD_GenderLeft,
    CreatorTD_GenderValue,
    CreatorTD_GenderRight,

    CreatorTD_DayLabel,
    CreatorTD_DayLeft,
    CreatorTD_DayValue,
    CreatorTD_DayRight,

    CreatorTD_MonthLabel,
    CreatorTD_MonthLeft,
    CreatorTD_MonthValue,
    CreatorTD_MonthRight,

    CreatorTD_YearLabel,
    CreatorTD_YearLeft,
    CreatorTD_YearValue,
    CreatorTD_YearRight,

    CreatorTD_ToneLabel,
    CreatorTD_ToneLeft,
    CreatorTD_ToneValue,
    CreatorTD_ToneRight,

    CreatorTD_SkinLabel,
    CreatorTD_SkinLeft,
    CreatorTD_SkinValue,
    CreatorTD_SkinRight,

    CreatorTD_VoiceLabel,
    CreatorTD_VoiceLeft,
    CreatorTD_VoiceValue,
    CreatorTD_VoiceRight,

    CreatorTD_HeightLabel,
    CreatorTD_HeightLeft,
    CreatorTD_HeightValue,
    CreatorTD_HeightRight,

    CreatorTD_WeightLabel,
    CreatorTD_WeightLeft,
    CreatorTD_WeightValue,
    CreatorTD_WeightRight,

    CreatorTD_BirthPlaceLabel,
    CreatorTD_BirthPlaceLeft,
    CreatorTD_BirthPlaceValue,
    CreatorTD_BirthPlaceRight,

    CreatorTD_Hint,
    CreatorTD_Confirm,

    CreatorTD_Count
};

new PlayerText:s_CreatorTD[MAX_PLAYERS][CreatorTD_Count];

new
    bool:s_CreatorActive[MAX_PLAYERS],
    bool:s_CreatorUIReady[MAX_PLAYERS],
    bool:s_CreatorSaving[MAX_PLAYERS],
    s_CreatorSkinIndex[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Callback
//-----------------------------------------------------------------------------

forward public OnCharacterCreatorSaved(playerid);

//-----------------------------------------------------------------------------
// Helpers
//-----------------------------------------------------------------------------

stock Creator_Wrap(value, minimum, maximum, change)
{
    value += change;

    if (value < minimum)
    {
        value = maximum;
    }
    else if (value > maximum)
    {
        value = minimum;
    }

    return value;
}

stock bool:Creator_IsLeapYear(year)
{
    if ((year % 400) == 0)
    {
        return true;
    }

    if ((year % 100) == 0)
    {
        return false;
    }

    return (year % 4) == 0;
}

stock Creator_GetDaysInMonth(month, year)
{
    switch (month)
    {
        case 2:
        {
            if (Creator_IsLeapYear(year))
            {
                return 29;
            }

            return 28;
        }

        case 4, 6, 9, 11:
        {
            return 30;
        }
    }

    return 31;
}

Creator_ClampBirthDay(playerid)
{
    new const maxDay = Creator_GetDaysInMonth(
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid]
    );

    if (s_CharacterBirthDay[playerid] > maxDay)
    {
        s_CharacterBirthDay[playerid] = maxDay;
    }

    if (s_CharacterBirthDay[playerid] < 1)
    {
        s_CharacterBirthDay[playerid] = 1;
    }

    return 1;
}

Creator_FindSkinIndex(playerid)
{
    new
        gender = s_CharacterGender[playerid],
        tone = s_CharacterSkinTone[playerid];

    for (new i = 0; i < CREATOR_SKINS_PER_GROUP; i++)
    {
        if (g_CreatorSkins[gender][tone][i] == s_CharacterSkin[playerid])
        {
            return i;
        }
    }

    return 0;
}

Creator_ApplySkin(playerid)
{
    new
        gender = s_CharacterGender[playerid],
        tone = s_CharacterSkinTone[playerid],
        index = s_CreatorSkinIndex[playerid];

    s_CharacterSkin[playerid] =
        g_CreatorSkins[gender][tone][index];

    SetPlayerSkin(
        playerid,
        s_CharacterSkin[playerid]
    );

    return 1;
}

Creator_NormalizeProfile(playerid)
{
    if (s_CharacterGender[playerid] < 0 ||
        s_CharacterGender[playerid] > 1)
    {
        s_CharacterGender[playerid] = 0;
    }

    if (s_CharacterBirthMonth[playerid] < 1 ||
        s_CharacterBirthMonth[playerid] > 12)
    {
        s_CharacterBirthMonth[playerid] = 1;
    }

    if (s_CharacterBirthYear[playerid] < CHARACTER_MIN_BIRTH_YEAR ||
        s_CharacterBirthYear[playerid] > CHARACTER_MAX_BIRTH_YEAR)
    {
        s_CharacterBirthYear[playerid] = 2000;
    }

    if (s_CharacterSkinTone[playerid] < 0 ||
        s_CharacterSkinTone[playerid] > 2)
    {
        s_CharacterSkinTone[playerid] = 2;
    }

    if (s_CharacterVoice[playerid] < 0 ||
        s_CharacterVoice[playerid] > 3)
    {
        s_CharacterVoice[playerid] = 0;
    }

    if (s_CharacterHeight[playerid] < 150 ||
        s_CharacterHeight[playerid] > 210)
    {
        s_CharacterHeight[playerid] = 175;
    }

    if (s_CharacterWeight[playerid] < 45 ||
        s_CharacterWeight[playerid] > 150)
    {
        s_CharacterWeight[playerid] = 70;
    }

    if (s_CharacterBirthPlace[playerid] < 0 ||
        s_CharacterBirthPlace[playerid] > 3)
    {
        s_CharacterBirthPlace[playerid] = 0;
    }

    Creator_ClampBirthDay(playerid);

    s_CreatorSkinIndex[playerid] =
        Creator_FindSkinIndex(playerid);

    Creator_ApplySkin(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// TextDraw creation
//-----------------------------------------------------------------------------

stock PlayerText:Creator_CreateText(
    playerid,
    Float:x,
    Float:y,
    const text[],
    color = CREATOR_COLOR_WHITE,
    Float:sizeX = 0.21,
    Float:sizeY = 0.95)
{
    new PlayerText:td =
        CreatePlayerTextDraw(playerid, x, y, text);

    PlayerTextDrawFont(playerid, td, TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, td, sizeX, sizeY);

    PlayerTextDrawColor(playerid, td, color);
    PlayerTextDrawBackgroundColor(playerid, td, 0x000000FF);

    PlayerTextDrawSetOutline(playerid, td, 1);
    PlayerTextDrawSetShadow(playerid, td, 0);

    PlayerTextDrawSetProportional(playerid, td, true);

    return td;
}

stock PlayerText:Creator_CreateArrow(playerid, Float:x, Float:y, const text[])
{
    new PlayerText:td = Creator_CreateText(playerid, x, y, text, CREATOR_COLOR_WHITE, 0.22, 1.0);

    // Giảm vùng selectable để không chồng chéo
    PlayerTextDrawTextSize(playerid, td, x + 10.0, y + 10.0);
    PlayerTextDrawSetSelectable(playerid, td, true);

    return td;
}
Creator_CreateUI(playerid)
{
    if (s_CreatorUIReady[playerid])
    {
        return 1;
    }

    // =========================================================
    // PANEL NHO GON HON
    // =========================================================
    s_CreatorTD[playerid][CreatorTD_Panel] = CreatePlayerTextDraw(playerid, 414.0, 26.0, "_");
    PlayerTextDrawLetterSize(playerid, s_CreatorTD[playerid][CreatorTD_Panel], 0.0, 37.0);
    PlayerTextDrawTextSize(playerid, s_CreatorTD[playerid][CreatorTD_Panel], 620.0, 0.0);
    PlayerTextDrawUseBox(playerid, s_CreatorTD[playerid][CreatorTD_Panel], true);
    PlayerTextDrawBoxColor(playerid, s_CreatorTD[playerid][CreatorTD_Panel], CREATOR_COLOR_PANEL);

    // =========================================================
    // HEADER
    // =========================================================

    // Logo
    s_CreatorTD[playerid][CreatorTD_Title] = Creator_CreateText(playerid, 517.0, 43.0, "LOS SANTOS ROLEPLAY", CREATOR_COLOR_RED, 0.31, 1.38);
    PlayerTextDrawFont(playerid, s_CreatorTD[playerid][CreatorTD_Title], TEXT_DRAW_FONT_3);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Title], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawBackgroundColor(playerid, s_CreatorTD[playerid][CreatorTD_Title], 0x000000FF);
    PlayerTextDrawSetOutline(playerid, s_CreatorTD[playerid][CreatorTD_Title], 2);

    // Khởi tạo nhân vật - sát hơn
    s_CreatorTD[playerid][CreatorTD_Subtitle] = Creator_CreateText(playerid, 517.0, 63.0, "khoi tao nhan vat", CREATOR_COLOR_WHITE, 0.24, 1.15);
    PlayerTextDrawFont(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], TEXT_DRAW_FONT_3);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawSetOutline(playerid, s_CreatorTD[playerid][CreatorTD_Subtitle], 1);

    // Tên nhân vật - sát hơn
    s_CreatorTD[playerid][CreatorTD_Name] = Creator_CreateText(playerid, 517.0, 82.0, "Nhan vat: Test Character", CREATOR_COLOR_GREY, 0.19, 0.95);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Name], TEXT_DRAW_ALIGN_CENTER);

    // =========================================================
    // CAC DONG THONG TIN - SAT HON
    // =========================================================

    // Bắt đầu từ y = 117, mỗi dòng cách nhau 22
    s_CreatorTD[playerid][CreatorTD_GenderLabel]      = Creator_CreateText(playerid, 435.0, 117.0, "Gioi tinh:",   CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_GenderLeft]       = Creator_CreateArrow(playerid, 538.0, 116.0, "<");
    s_CreatorTD[playerid][CreatorTD_GenderValue]      = Creator_CreateText(playerid, 560.0, 117.0, "~g~Nam",       CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_GenderRight]      = Creator_CreateArrow(playerid, 596.0, 116.0, ">");

    s_CreatorTD[playerid][CreatorTD_DayLabel]         = Creator_CreateText(playerid, 435.0, 139.0, "Ngay sinh:",   CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_DayLeft]          = Creator_CreateArrow(playerid, 538.0, 138.0, "<");
    s_CreatorTD[playerid][CreatorTD_DayValue]         = Creator_CreateText(playerid, 560.0, 139.0, "~g~01",        CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_DayRight]         = Creator_CreateArrow(playerid, 596.0, 138.0, ">");

    s_CreatorTD[playerid][CreatorTD_MonthLabel]       = Creator_CreateText(playerid, 435.0, 161.0, "Thang sinh:",  CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_MonthLeft]        = Creator_CreateArrow(playerid, 538.0, 160.0, "<");
    s_CreatorTD[playerid][CreatorTD_MonthValue]       = Creator_CreateText(playerid, 560.0, 161.0, "~g~01",        CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_MonthRight]       = Creator_CreateArrow(playerid, 596.0, 160.0, ">");

    s_CreatorTD[playerid][CreatorTD_YearLabel]        = Creator_CreateText(playerid, 435.0, 183.0, "Nam sinh:",    CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_YearLeft]         = Creator_CreateArrow(playerid, 538.0, 182.0, "<");
    s_CreatorTD[playerid][CreatorTD_YearValue]        = Creator_CreateText(playerid, 560.0, 183.0, "~g~1964 (28 tuoi)", CREATOR_COLOR_WHITE, 0.18, 1.00);
    s_CreatorTD[playerid][CreatorTD_YearRight]        = Creator_CreateArrow(playerid, 596.0, 182.0, ">");

    s_CreatorTD[playerid][CreatorTD_ToneLabel]        = Creator_CreateText(playerid, 435.0, 205.0, "Mau da:",      CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_ToneLeft]         = Creator_CreateArrow(playerid, 538.0, 204.0, "<");
    s_CreatorTD[playerid][CreatorTD_ToneValue]        = Creator_CreateText(playerid, 560.0, 205.0, "~g~Toi",       CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_ToneRight]        = Creator_CreateArrow(playerid, 596.0, 204.0, ">");

    s_CreatorTD[playerid][CreatorTD_SkinLabel]        = Creator_CreateText(playerid, 435.0, 227.0, "Ngoai hinh:",  CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_SkinLeft]         = Creator_CreateArrow(playerid, 538.0, 226.0, "<");
    s_CreatorTD[playerid][CreatorTD_SkinValue]        = Creator_CreateText(playerid, 560.0, 227.0, "~g~26 (1/6)",  CREATOR_COLOR_WHITE, 0.18, 1.00);
    s_CreatorTD[playerid][CreatorTD_SkinRight]        = Creator_CreateArrow(playerid, 596.0, 226.0, ">");

    s_CreatorTD[playerid][CreatorTD_VoiceLabel]       = Creator_CreateText(playerid, 435.0, 249.0, "Giong noi:",   CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_VoiceLeft]        = Creator_CreateArrow(playerid, 538.0, 248.0, "<");
    s_CreatorTD[playerid][CreatorTD_VoiceValue]       = Creator_CreateText(playerid, 560.0, 249.0, "~g~Tram",      CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_VoiceRight]       = Creator_CreateArrow(playerid, 596.0, 248.0, ">");

    s_CreatorTD[playerid][CreatorTD_HeightLabel]      = Creator_CreateText(playerid, 435.0, 271.0, "Chieu cao:",   CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_HeightLeft]       = Creator_CreateArrow(playerid, 538.0, 270.0, "<");
    s_CreatorTD[playerid][CreatorTD_HeightValue]      = Creator_CreateText(playerid, 560.0, 271.0, "~g~175 cm",    CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_HeightRight]      = Creator_CreateArrow(playerid, 596.0, 270.0, ">");

    s_CreatorTD[playerid][CreatorTD_WeightLabel]      = Creator_CreateText(playerid, 435.0, 293.0, "Can nang:",    CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_WeightLeft]       = Creator_CreateArrow(playerid, 538.0, 292.0, "<");
    s_CreatorTD[playerid][CreatorTD_WeightValue]      = Creator_CreateText(playerid, 560.0, 293.0, "~g~70 kg",     CREATOR_COLOR_WHITE, 0.20, 1.00);
    s_CreatorTD[playerid][CreatorTD_WeightRight]      = Creator_CreateArrow(playerid, 596.0, 292.0, ">");

    s_CreatorTD[playerid][CreatorTD_BirthPlaceLabel]  = Creator_CreateText(playerid, 435.0, 315.0, "Noi sinh:",    CREATOR_COLOR_WHITE, 0.21, 1.00);
    s_CreatorTD[playerid][CreatorTD_BirthPlaceLeft]   = Creator_CreateArrow(playerid, 538.0, 314.0, "<");
    s_CreatorTD[playerid][CreatorTD_BirthPlaceValue]  = Creator_CreateText(playerid, 560.0, 315.0, "~g~Los Santos", CREATOR_COLOR_WHITE, 0.18, 1.00);
    s_CreatorTD[playerid][CreatorTD_BirthPlaceRight]  = Creator_CreateArrow(playerid, 596.0, 314.0, ">");

    // Credit nho hon
    s_CreatorTD[playerid][CreatorTD_Hint] = Creator_CreateText(playerid, 517.0, 344.0, "Developer by CHATGPT & Cuozg(ideas)", CREATOR_COLOR_GREY, 0.13, 0.70);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Hint], TEXT_DRAW_ALIGN_CENTER);

    // Nút xác nhận nhỏ gọn hơn
    s_CreatorTD[playerid][CreatorTD_Confirm] = Creator_CreateText(playerid, 517.0, 368.0, "~g~XAC NHAN NHAN VAT", CREATOR_COLOR_WHITE, 0.24, 1.10);
    PlayerTextDrawAlignment(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawUseBox(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], true);
    PlayerTextDrawBoxColor(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], CREATOR_COLOR_BUTTON);
    PlayerTextDrawTextSize(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], 16.0, 170.0);
    PlayerTextDrawSetSelectable(playerid, s_CreatorTD[playerid][CreatorTD_Confirm], true);

    s_CreatorUIReady[playerid] = true;
    return 1;
}

//-----------------------------------------------------------------------------
// Refresh text
//-----------------------------------------------------------------------------

Creator_RefreshUI(playerid)
{
    if (!s_CreatorUIReady[playerid])
    {
        return 0;
    }

    new text[96];

    format(
        text,
        sizeof(text),
        "Nhan vat: %s",
        s_CharacterName[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_Name],
        text
    );

    if (s_CharacterGender[playerid] == 0)
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_GenderValue],
            "Nam"
        );
    }
    else
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_GenderValue],
            "Nu"
        );
    }

    format(
        text,
        sizeof(text),
        "%02d",
        s_CharacterBirthDay[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_DayValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%02d",
        s_CharacterBirthMonth[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_MonthValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%d (%d tuoi)",
        s_CharacterBirthYear[playerid],
        GetPlayerCharacterAge(playerid)
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_YearValue],
        text
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_ToneValue],
        g_SkinToneNames[s_CharacterSkinTone[playerid]]
    );

    format(
        text,
        sizeof(text),
        "%d (%d/%d)",
        s_CharacterSkin[playerid],
        s_CreatorSkinIndex[playerid] + 1,
        CREATOR_SKINS_PER_GROUP
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_SkinValue],
        text
    );

    if (s_CharacterGender[playerid] == 0)
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_VoiceValue],
            g_MaleVoiceNames[s_CharacterVoice[playerid]]
        );
    }
    else
    {
        PlayerTextDrawSetString(
            playerid,
            s_CreatorTD[playerid][CreatorTD_VoiceValue],
            g_FemaleVoiceNames[s_CharacterVoice[playerid]]
        );
    }

    format(
        text,
        sizeof(text),
        "%d cm",
        s_CharacterHeight[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_HeightValue],
        text
    );

    format(
        text,
        sizeof(text),
        "%d kg",
        s_CharacterWeight[playerid]
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_WeightValue],
        text
    );

    PlayerTextDrawSetString(
        playerid,
        s_CreatorTD[playerid][CreatorTD_BirthPlaceValue],
        g_BirthPlaceNames[s_CharacterBirthPlace[playerid]]
    );

    return 1;
}

//-----------------------------------------------------------------------------
// UI show/hide
//-----------------------------------------------------------------------------

Creator_ShowUI(playerid)
{
    Creator_CreateUI(playerid);
    Creator_RefreshUI(playerid);

    SelectTextDraw(
        playerid,
        CREATOR_COLOR_HOVER
    );

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        PlayerTextDrawShow(
            playerid,
            s_CreatorTD[playerid][i]
        );
    }

    return 1;
}

Creator_DestroyUI(playerid)
{
    if (!s_CreatorUIReady[playerid])
    {
        return 1;
    }

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        PlayerTextDrawDestroy(
            playerid,
            s_CreatorTD[playerid][i]
        );

        s_CreatorTD[playerid][i] =
            PlayerText:INVALID_TEXT_DRAW;
    }

    s_CreatorUIReady[playerid] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// World / Camera
//-----------------------------------------------------------------------------

CharacterCreator_ApplyWorld(playerid)
{
    SetPlayerInterior(
        playerid,
        CREATOR_INTERIOR
    );

    SetPlayerVirtualWorld(
        playerid,
        CREATOR_WORLD_BASE + playerid
    );

    SetPlayerPos(
        playerid,
        CREATOR_POS_X,
        CREATOR_POS_Y,
        CREATOR_POS_Z
    );

    SetPlayerFacingAngle(
        playerid,
        CREATOR_POS_A
    );

    SetPlayerSkin(
        playerid,
        s_CharacterSkin[playerid]
    );

    ResetPlayerWeapons(playerid);

    TogglePlayerControllable(
        playerid,
        false
    );

    SetPlayerCameraPos(
        playerid,
        CREATOR_CAMERA_X,
        CREATOR_CAMERA_Y,
        CREATOR_CAMERA_Z
    );

    SetPlayerCameraLookAt(
        playerid,
        CREATOR_CAMERA_LOOK_X,
        CREATOR_CAMERA_LOOK_Y,
        CREATOR_CAMERA_LOOK_Z,
        CAMERA_CUT
    );

    Creator_ShowUI(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Start creator
//-----------------------------------------------------------------------------

stock bool:CharacterCreator_IsActive(playerid)
{
    return s_CreatorActive[playerid];
}

CharacterCreator_Start(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    Creator_NormalizeProfile(playerid);

    if (!Character_SetPlayerICName(playerid))
    {
        Kick(playerid);
        return 0;
    }

    s_CreatorActive[playerid] = true;
    s_CreatorSaving[playerid] = false;

    SetSpawnInfo(
        playerid,
        NO_TEAM,
        s_CharacterSkin[playerid],
        CREATOR_POS_X,
        CREATOR_POS_Y,
        CREATOR_POS_Z,
        CREATOR_POS_A
    );

    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        TogglePlayerSpectating(
            playerid,
            false
        );
    }
    else
    {
        SpawnPlayer(playerid);
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Save profile
//-----------------------------------------------------------------------------

CharacterCreator_Confirm(playerid)
{
    if (!s_CreatorActive[playerid] ||
        s_CreatorSaving[playerid])
    {
        return 0;
    }

    new const age = GetPlayerCharacterAge(playerid);

    if (age < CHARACTER_MIN_AGE ||
        age > CHARACTER_MAX_AGE)
    {
        SendClientMessage(
            playerid,
            COLOR_RED,
            "Do tuoi nhan vat khong hop le."
        );

        return 0;
    }

    s_CreatorSaving[playerid] = true;

    CancelSelectTextDraw(playerid);

    new query[1024];

    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `character_created`=1,`gender`=%d,`birth_day`=%d,`birth_month`=%d,`birth_year`=%d,`skin_tone`=%d,`skin`=%d,`voice`=%d,`height_cm`=%d,`weight_kg`=%d,`birth_place`=%d WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;",
        s_CharacterGender[playerid],
        s_CharacterBirthDay[playerid],
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid],
        s_CharacterSkinTone[playerid],
        s_CharacterSkin[playerid],
        s_CharacterVoice[playerid],
        s_CharacterHeight[playerid],
        s_CharacterWeight[playerid],
        s_CharacterBirthPlace[playerid],
        s_CharacterID[playerid],
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnCharacterCreatorSaved",
        "d",
        playerid
    );

    return 1;
}

public OnCharacterCreatorSaved(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    s_CharacterCreated[playerid] = 1;
    s_CreatorSaving[playerid] = false;
    s_CreatorActive[playerid] = false;
    
    Creator_DestroyUI(playerid);
    
    TogglePlayerControllable(playerid, false);
    
    SendClientMessage(playerid, COLOR_WHITE, "Ho so nhan vat da duoc khoi tao thanh cong.");
    
    Cinematic_StartNewCharacter(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Clicks
//-----------------------------------------------------------------------------

hook OnPlayerClickPlayerTextDraw( playerid, PlayerText:playertextid)
{
    if (!s_CreatorActive[playerid] ||
        s_CreatorSaving[playerid])
    {
        return 0;
    }

    // Gender
    if (playertextid == s_CreatorTD[playerid][CreatorTD_GenderLeft] ||
        playertextid == s_CreatorTD[playerid][CreatorTD_GenderRight])
    {
        s_CharacterGender[playerid] =
            Creator_Wrap(
                s_CharacterGender[playerid],
                0,
                1,
                1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);

        return 1;
    }

    // Day -
    if (playertextid == s_CreatorTD[playerid][CreatorTD_DayLeft])
    {
        new const maxDay =
            Creator_GetDaysInMonth(
                s_CharacterBirthMonth[playerid],
                s_CharacterBirthYear[playerid]
            );

        s_CharacterBirthDay[playerid] =
            Creator_Wrap(
                s_CharacterBirthDay[playerid],
                1,
                maxDay,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Day +
    if (playertextid == s_CreatorTD[playerid][CreatorTD_DayRight])
    {
        new const maxDay =
            Creator_GetDaysInMonth(
                s_CharacterBirthMonth[playerid],
                s_CharacterBirthYear[playerid]
            );

        s_CharacterBirthDay[playerid] =
            Creator_Wrap(
                s_CharacterBirthDay[playerid],
                1,
                maxDay,
                1);

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Month
    if (playertextid == s_CreatorTD[playerid][CreatorTD_MonthLeft])
    {
        s_CharacterBirthMonth[playerid] =
            Creator_Wrap(
                s_CharacterBirthMonth[playerid],
                1,
                12,
                -1);

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_MonthRight])
    {
        s_CharacterBirthMonth[playerid] =
            Creator_Wrap(
                s_CharacterBirthMonth[playerid],
                1,
                12,
                1 );

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Year
    if (playertextid == s_CreatorTD[playerid][CreatorTD_YearLeft])
    {
        s_CharacterBirthYear[playerid] =
            Creator_Wrap(
                s_CharacterBirthYear[playerid],
                CHARACTER_MIN_BIRTH_YEAR,
                CHARACTER_MAX_BIRTH_YEAR,
                -1);

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_YearRight])
    {
        s_CharacterBirthYear[playerid] =
            Creator_Wrap(
                s_CharacterBirthYear[playerid],
                CHARACTER_MIN_BIRTH_YEAR,
                CHARACTER_MAX_BIRTH_YEAR,
                1
            );

        Creator_ClampBirthDay(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Skin tone
    if (playertextid == s_CreatorTD[playerid][CreatorTD_ToneLeft])
    {
        s_CharacterSkinTone[playerid] =
            Creator_Wrap(
                s_CharacterSkinTone[playerid],
                0,
                2,
                -1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_ToneRight])
    {
        s_CharacterSkinTone[playerid] =
            Creator_Wrap(
                s_CharacterSkinTone[playerid],
                0,
                2,
                1
            );

        s_CreatorSkinIndex[playerid] = 0;

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Skin
    if (playertextid == s_CreatorTD[playerid][CreatorTD_SkinLeft])
    {
        s_CreatorSkinIndex[playerid] =
            Creator_Wrap(
                s_CreatorSkinIndex[playerid],
                0,
                CREATOR_SKINS_PER_GROUP - 1,
                -1
            );

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_SkinRight])
    {
        s_CreatorSkinIndex[playerid] =
            Creator_Wrap(
                s_CreatorSkinIndex[playerid],
                0,
                CREATOR_SKINS_PER_GROUP - 1,
                1
            );

        Creator_ApplySkin(playerid);
        Creator_RefreshUI(playerid);
        return 1;
    }

    // Voice
    if (playertextid == s_CreatorTD[playerid][CreatorTD_VoiceLeft])
    {
        s_CharacterVoice[playerid] =
            Creator_Wrap(
                s_CharacterVoice[playerid],
                0,
                3,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_VoiceRight])
    {
        s_CharacterVoice[playerid] =
            Creator_Wrap(
                s_CharacterVoice[playerid],
                0,
                3,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Height
    if (playertextid == s_CreatorTD[playerid][CreatorTD_HeightLeft])
    {
        s_CharacterHeight[playerid] =
            Creator_Wrap(
                s_CharacterHeight[playerid],
                150,
                210,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_HeightRight])
    {
        s_CharacterHeight[playerid] =
            Creator_Wrap(
                s_CharacterHeight[playerid],
                150,
                210,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Weight
    if (playertextid == s_CreatorTD[playerid][CreatorTD_WeightLeft])
    {
        s_CharacterWeight[playerid] =
            Creator_Wrap(
                s_CharacterWeight[playerid],
                45,
                150,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_WeightRight])
    {
        s_CharacterWeight[playerid] =
            Creator_Wrap(
                s_CharacterWeight[playerid],
                45,
                150,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Birth place
    if (playertextid == s_CreatorTD[playerid][CreatorTD_BirthPlaceLeft])
    {
        s_CharacterBirthPlace[playerid] =
            Creator_Wrap(
                s_CharacterBirthPlace[playerid],
                0,
                3,
                -1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    if (playertextid == s_CreatorTD[playerid][CreatorTD_BirthPlaceRight])
    {
        s_CharacterBirthPlace[playerid] =
            Creator_Wrap(
                s_CharacterBirthPlace[playerid],
                0,
                3,
                1
            );

        Creator_RefreshUI(playerid);
        return 1;
    }

    // Confirm
    if (playertextid == s_CreatorTD[playerid][CreatorTD_Confirm])
    {
        CharacterCreator_Confirm(playerid);
        return 1;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Connection cleanup
//-----------------------------------------------------------------------------

hook OnPlayerConnect(playerid)
{
    s_CreatorActive[playerid] = false;
    s_CreatorUIReady[playerid] = false;
    s_CreatorSaving[playerid] = false;
    s_CreatorSkinIndex[playerid] = 0;

    for (new i = 0; i < CreatorTD_Count; i++)
    {
        s_CreatorTD[playerid][i] =
            PlayerText:INVALID_TEXT_DRAW;
    }

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    Creator_DestroyUI(playerid);

    s_CreatorActive[playerid] = false;
    s_CreatorSaving[playerid] = false;

    return 1;
}
Creator_SetCentered(playerid, PlayerText:td)
{
    PlayerTextDrawAlignment(playerid, td, TEXT_DRAW_ALIGN_CENTER);
    return 1;
}