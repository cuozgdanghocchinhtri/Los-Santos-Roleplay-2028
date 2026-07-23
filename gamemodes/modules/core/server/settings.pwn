#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Global roleplay server settings
//-----------------------------------------------------------------------------

hook OnGameModeInit()
{
    SetGameModeText("Los Santos Roleplay");

    // Use the regular pedestrian movement set for every player skin instead
    // of CJ's single-player movement animations.
    UsePlayerPedAnims();

    return 1;
}

