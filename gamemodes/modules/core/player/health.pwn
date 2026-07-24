//-----------------------------------------------------------------------------
// Server-authoritative Player Health Core.
//
// Chịu trách nhiệm:
// - giữ pHealth / pArmour làm nguồn dữ liệu health phía server;
// - đồng bộ health hợp lệ xuống GTA client;
// - phát hiện client health/armour bị lệch và tự sửa lại;
// - cung cấp API duy nhất cho các system thay đổi health;
// - không tin GetPlayerHealth/GetPlayerArmour khi lưu persistent data.
//
// QUY TẮC:
// Code mới không được gọi SetPlayerHealth/SetPlayerArmour trực tiếp.
// Hãy đi qua PlayerHealth_* API trong file này.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

// Health thấp nhất mà server authority cho phép.
#define PLAYER_HEALTH_MIN                 (0.0)

// Health tối đa mặc định của character.
#define PLAYER_HEALTH_MAX                 (100.0)

// Armour thấp nhất mà server authority cho phép.
#define PLAYER_ARMOUR_MIN                 (0.0)

// Armour tối đa mặc định của character.
#define PLAYER_ARMOUR_MAX                 (100.0)

// Chu kỳ kiểm tra health client có bị lệch khỏi server authority hay không.
#define PLAYER_HEALTH_RECONCILE_INTERVAL  (750)

// Sai số nhỏ được bỏ qua để tránh sửa health vì floating-point noise.
#define PLAYER_HEALTH_RECONCILE_TOLERANCE (0.75)

// Sau mỗi số lần mismatch này, server ghi một warning vào console.
// Không tự kick player ở phase đầu để tránh false-positive.
#define PLAYER_HEALTH_LOG_EVERY_MISMATCH  (5)

// Health hợp lệ của character do server quản lý.
// Đây là source of truth; client health không được dùng để save database.
new Float:pHealth[MAX_PLAYERS];

// Armour hợp lệ của character do server quản lý.
new Float:pArmour[MAX_PLAYERS];

// Cho biết pHealth/pArmour đã được khởi tạo từ character data hay chưa.
new bool:pHealthReady[MAX_PLAYERS];

// Tổng số lần client health/armour bị phát hiện lệch khỏi server authority.
new pHealthMismatchCount[MAX_PLAYERS];

// Timer global dùng để reconcile health của toàn bộ player đang online.
new pHealthReconcileTimer;

// Clamp health vào giới hạn hợp lệ của server.
stock Float:PlayerHealth_Clamp(Float:health)
{
    if (health < PLAYER_HEALTH_MIN)
    {
        return PLAYER_HEALTH_MIN;
    }

    if (health > PLAYER_HEALTH_MAX)
    {
        return PLAYER_HEALTH_MAX;
    }

    return health;
}

// Clamp armour vào giới hạn hợp lệ của server.
stock Float:PlayerHealth_ClampArmour(Float:armour)
{
    if (armour < PLAYER_ARMOUR_MIN)
    {
        return PLAYER_ARMOUR_MIN;
    }

    if (armour > PLAYER_ARMOUR_MAX)
    {
        return PLAYER_ARMOUR_MAX;
    }

    return armour;
}

// Reset toàn bộ runtime health authority của một player.
// Được gọi khi connect trước khi character được load.
stock PlayerHealth_Reset(playerid)
{
    pHealth[playerid] = PLAYER_HEALTH_MAX;
    pArmour[playerid] = PLAYER_ARMOUR_MIN;

    pHealthReady[playerid] = false;
    pHealthMismatchCount[playerid] = 0;
    return 1;
}

// Khởi tạo server-authoritative health từ dữ liệu character trong database.
//
// health:
//     Health persistent đã load từ player_characters.health.
//
// armour:
//     Armour persistent đã load từ player_characters.armour.
stock PlayerHealth_LoadCharacter(
    playerid,
    Float:health,
    Float:armour
)
{
    pHealth[playerid] = PlayerHealth_Clamp(health);
    pArmour[playerid] = PlayerHealth_ClampArmour(armour);

    pHealthReady[playerid] = true;
    pHealthMismatchCount[playerid] = 0;
    return 1;
}

// Kiểm tra server-authoritative health đã sẵn sàng cho character hay chưa.
stock bool:PlayerHealth_IsReady(playerid)
{
    return pHealthReady[playerid];
}

// Trả về health server-side hiện tại.
// Không đọc health từ client trong getter này.
stock Float:PlayerHealth_Get(playerid)
{
    return pHealth[playerid];
}

// Trả về armour server-side hiện tại.
// Không đọc armour từ client trong getter này.
stock Float:PlayerHealth_GetArmour(playerid)
{
    return pArmour[playerid];
}

// Gán health server-side và đồng bộ xuống client.
//
// syncClient:
//     true  = gọi SetPlayerHealth ngay.
//     false = chỉ cập nhật source of truth, dùng cho flow cần defer.
stock PlayerHealth_Set(
    playerid,
    Float:health,
    bool:syncClient = true
)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    pHealth[playerid] = PlayerHealth_Clamp(health);

    if (syncClient)
    {
        SetPlayerHealth(playerid, pHealth[playerid]);
    }
    return 1;
}

// Gán armour server-side và đồng bộ xuống client.
stock PlayerHealth_SetArmour(
    playerid,
    Float:armour,
    bool:syncClient = true
)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    pArmour[playerid] = PlayerHealth_ClampArmour(armour);

    if (syncClient)
    {
        SetPlayerArmour(playerid, pArmour[playerid]);
    }
    return 1;
}

// Cộng health hợp lệ vào server authority.
stock PlayerHealth_Add(playerid, Float:amount)
{
    if (amount <= 0.0)
    {
        return 0;
    }

    return PlayerHealth_Set(
        playerid,
        pHealth[playerid] + amount
    );
}

// Trừ health trực tiếp khỏi server authority.
// Medical damage nên ưu tiên PlayerHealth_ApplyDamage để armour được xử lý trước.
stock PlayerHealth_Remove(playerid, Float:amount)
{
    if (amount <= 0.0)
    {
        return 0;
    }

    return PlayerHealth_Set(
        playerid,
        pHealth[playerid] - amount
    );
}

// Áp damage phía server.
//
// Armour hấp thụ damage trước.
// Phần còn lại mới trừ vào pHealth.
//
// Return:
//     Lượng damage thực sự đi vào health sau armour.
stock Float:PlayerHealth_ApplyDamage(
    playerid,
    Float:amount
)
{
    if (!pHealthReady[playerid] ||
        amount <= 0.0)
    {
        return 0.0;
    }

    new Float:healthDamage = amount;

    // Armour hiện được dùng như một lớp absorb 1:1.
    // Sau này có thể thay policy theo weapon/vest mà không đổi Medical API.
    if (pArmour[playerid] > 0.0)
    {
        new Float:absorbed = amount;

        if (absorbed > pArmour[playerid])
        {
            absorbed = pArmour[playerid];
        }

        pArmour[playerid] -= absorbed;
        healthDamage -= absorbed;
    }

    if (healthDamage > 0.0)
    {
        pHealth[playerid] = PlayerHealth_Clamp(
            pHealth[playerid] - healthDamage
        );
    }

    // Luôn ép client về state vừa được server tính.
    SetPlayerArmour(playerid, pArmour[playerid]);
    SetPlayerHealth(playerid, pHealth[playerid]);
    return healthDamage;
}

// Đồng bộ pHealth/pArmour hiện tại xuống GTA client.
// Dùng sau spawn hoặc khi medical state vừa thay đổi.
stock PlayerHealth_SyncClient(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !pHealthReady[playerid])
    {
        return 0;
    }

    SetPlayerHealth(playerid, pHealth[playerid]);
    SetPlayerArmour(playerid, pArmour[playerid]);
    return 1;
}

// Kiểm tra một player có đang cố hiển thị health/armour khác server authority không.
//
// Đây là anti-desync/anti-health-hack correction.
// Phase đầu chỉ correct + log, KHÔNG auto kick.
stock PlayerHealth_ReconcilePlayer(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        !pHealthReady[playerid])
    {
        return 0;
    }

    // Spectator/cinematic chưa cần reconcile vì player chưa thực sự ở gameplay world.
    if (GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        return 1;
    }

    new
        Float:clientHealth,
        Float:clientArmour;

    GetPlayerHealth(playerid, clientHealth);
    GetPlayerArmour(playerid, clientArmour);

    new bool:mismatch = false;

    if (floatabs(clientHealth - pHealth[playerid]) >
        PLAYER_HEALTH_RECONCILE_TOLERANCE)
    {
        SetPlayerHealth(playerid, pHealth[playerid]);
        mismatch = true;
    }

    if (floatabs(clientArmour - pArmour[playerid]) >
        PLAYER_HEALTH_RECONCILE_TOLERANCE)
    {
        SetPlayerArmour(playerid, pArmour[playerid]);
        mismatch = true;
    }

    if (!mismatch)
    {
        return 1;
    }

    pHealthMismatchCount[playerid]++;

    // Chỉ log định kỳ để console không bị spam khi client đang desync liên tục.
    if ((pHealthMismatchCount[playerid] %
        PLAYER_HEALTH_LOG_EVERY_MISMATCH) == 0)
    {
        printf(
            "[HEALTH] Player %d health mismatch x%d. Server H: %.1f A: %.1f | Client H: %.1f A: %.1f",
            playerid,
            pHealthMismatchCount[playerid],
            pHealth[playerid],
            pArmour[playerid],
            clientHealth,
            clientArmour
        );
    }
    return 1;
}

// Timer global reconcile toàn bộ player.
// Một timer chung nhẹ hơn tạo một timer riêng cho từng player.
forward PlayerHealth_ReconcileAll();
public PlayerHealth_ReconcileAll()
{
    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid))
        {
            continue;
        }

        PlayerHealth_ReconcilePlayer(playerid);
    }
    return 1;
}

// Khởi tạo timer anti-desync khi gamemode start.
hook OnGameModeInit()
{
    pHealthReconcileTimer = SetTimer(
        "PlayerHealth_ReconcileAll",
        PLAYER_HEALTH_RECONCILE_INTERVAL,
        true
    );
    return 1;
}

// Cleanup timer global khi gamemode unload.
hook OnGameModeExit()
{
    if (pHealthReconcileTimer)
    {
        KillTimer(pHealthReconcileTimer);
        pHealthReconcileTimer = 0;
    }
    return 1;
}

// Reset health authority khi player vừa connect.
hook OnPlayerConnect(playerid)
{
    PlayerHealth_Reset(playerid);
    return 1;
}

// Sau mỗi spawn hợp lệ, ép client về health server authority.
// Medical module có thể override state ngay sau callback nếu đang DOWNED.
hook OnPlayerSpawn(playerid)
{
    if (PlayerHealth_IsReady(playerid))
    {
        PlayerHealth_SyncClient(playerid);
    }
    return 1;
}
