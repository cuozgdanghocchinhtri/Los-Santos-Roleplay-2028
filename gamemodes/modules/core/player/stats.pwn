#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Character statistics
//-----------------------------------------------------------------------------

#define CHARACTER_STATS_BODY_SIZE (2048)

Character_ShowStats(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new
        body[CHARACTER_STATS_BODY_SIZE],
        gender[8],
        voice[16],
        skinTone[16],
        birthPlace[32];

    format(
        gender,
        sizeof(gender),
        "%s",
        s_CharacterGender[playerid] == 0 ? "Nam" : "Nu"
    );

    format(
        voice,
        sizeof(voice),
        "%s",
        s_CharacterGender[playerid] == 0 ?
            g_MaleVoiceNames[s_CharacterVoice[playerid]] :
            g_FemaleVoiceNames[s_CharacterVoice[playerid]]
    );

    format(
        skinTone,
        sizeof(skinTone),
        "%s",
        g_SkinToneNames[s_CharacterSkinTone[playerid]]
    );

    format(
        birthPlace,
        sizeof(birthPlace),
        "%s",
        g_BirthPlaceNames[s_CharacterBirthPlace[playerid]]
    );

    format(
        body,
        sizeof(body),
        "{00008B}THONG TIN NHAN VAT\n\n%sTen nhan vat: %s%s\n%sMa nhan vat: %s%d\n%sSlot nhan vat: %s%d\n%sGioi tinh: %s%s\n%sNgay sinh: %s%02d/%02d/%d\n%sTuoi: %s%d\n%sNoi sinh: %s%s\n%sGiong noi: %s%s\n%sMau da: %s%s\n%sChieu cao: %s%d cm\n%sCan nang: %s%d kg\n%sSkin: %s%d\n\n{00008B}TRANG THAI VA TAI SAN\n\n%sCap do: %s%d\n%sTien mat: %s$%d\n%sNgan hang: %s$%d\n%sMau: %s%.1f\n%sGiap: %s%.1f",
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, s_CharacterName[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, s_CharacterID[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, s_CharacterSlot[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, gender,
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED,
        s_CharacterBirthDay[playerid],
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, GetPlayerCharacterAge(playerid),
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, birthPlace,
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, voice,
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, skinTone,
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, s_CharacterHeight[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, s_CharacterWeight[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_RED, GetPlayerSkin(playerid),
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, GetPlayerScore(playerid),
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, GetPlayerMoney(playerid),
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, s_CharacterBank[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, s_CharacterHealth[playerid],
        EMBED_RP_LIGHT_GRAY, EMBED_RP_DARK_BLUE, s_CharacterArmour[playerid]
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_CHARACTER_STATS,
        DIALOG_STYLE_MSGBOX,
        "Thong tin nhan vat",
        body,
        "Dong",
        ""
    );

    return 1;
}

hook OnPlayerCommandText(playerid, cmdtext[])
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    if (!strcmp(cmdtext, "/thongtin", true) ||
        !strcmp(cmdtext, "/stats", true))
    {
        Character_ShowStats(playerid);
        return ~1;
    }

    return 0;
}
