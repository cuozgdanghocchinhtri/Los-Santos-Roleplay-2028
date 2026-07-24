// LSRP patch - clear chat after character finishes loading/spawning.
// Insert these lines in Cinematic_FinishSpawn(), immediately before
// "Chao mung tro lai Los Santos."

for (new i = 0; i < 20; i++)
{
    SendClientMessage(playerid, COLOR_WHITE, " ");
}
