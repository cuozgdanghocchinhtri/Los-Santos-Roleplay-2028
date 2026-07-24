// LSRP patch - white/gray /stats.
// Replace Character_ShowStats() in modules/core/player/stats.pwn with this version.

Character_ShowStats(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
        return 0;

    new body[2048], gender[8], voice[16], skinTone[16], birthPlace[32];

    format(gender, sizeof(gender), "%s", s_CharacterGender[playerid] == 0 ? "Nam" : "Nu");
    format(voice, sizeof(voice), "%s",
        s_CharacterGender[playerid] == 0 ?
        g_MaleVoiceNames[s_CharacterVoice[playerid]] :
        g_FemaleVoiceNames[s_CharacterVoice[playerid]]);
    format(skinTone, sizeof(skinTone), "%s", g_SkinToneNames[s_CharacterSkinTone[playerid]]);
    format(birthPlace, sizeof(birthPlace), "%s", g_BirthPlaceNames[s_CharacterBirthPlace[playerid]]);

    format(body, sizeof(body),
        "{FFFFFF}THONG TIN NHAN VAT\n"
        "{BDBDBD}--------------------------------\n"
        "{BDBDBD}Ten nhan vat: {FFFFFF}%s\n"
        "{BDBDBD}Ma nhan vat: {FFFFFF}%d\n"
        "{BDBDBD}Slot: {FFFFFF}%d\n"
        "{BDBDBD}Gioi tinh: {FFFFFF}%s\n"
        "{BDBDBD}Ngay sinh: {FFFFFF}%02d/%02d/%d\n"
        "{BDBDBD}Tuoi: {FFFFFF}%d\n"
        "{BDBDBD}Noi sinh: {FFFFFF}%s\n"
        "{BDBDBD}Giong noi: {FFFFFF}%s\n"
        "{BDBDBD}Mau da: {FFFFFF}%s\n"
        "{BDBDBD}Chieu cao: {FFFFFF}%d cm\n"
        "{BDBDBD}Can nang: {FFFFFF}%d kg\n"
        "{BDBDBD}Skin: {FFFFFF}%d\n\n"
        "{FFFFFF}TRANG THAI & TAI SAN\n"
        "{BDBDBD}--------------------------------\n"
        "{BDBDBD}Cap do: {FFFFFF}%d\n"
        "{BDBDBD}Tien mat: {FFFFFF}$%d\n"
        "{BDBDBD}Ngan hang: {FFFFFF}$%d\n"
        "{BDBDBD}Mau: {FFFFFF}%.1f\n"
        "{BDBDBD}Giap: {FFFFFF}%.1f",
        s_CharacterName[playerid], s_CharacterID[playerid], s_CharacterSlot[playerid],
        gender, s_CharacterBirthDay[playerid], s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid], GetPlayerCharacterAge(playerid), birthPlace,
        voice, skinTone, s_CharacterHeight[playerid], s_CharacterWeight[playerid],
        GetPlayerSkin(playerid), GetPlayerScore(playerid), GetPlayerMoney(playerid),
        s_CharacterBank[playerid], s_CharacterHealth[playerid], s_CharacterArmour[playerid]);

    ShowPlayerDialog(playerid, DIALOG_CHARACTER_STATS, DIALOG_STYLE_MSGBOX,
        "{FFFFFF}LS:RP - Character Statistics", body, "Dong", "");
    return 1;
}
