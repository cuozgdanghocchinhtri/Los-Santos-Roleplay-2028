//-----------------------------------------------------------------------------
// LS:RP Injured / Downed / Dead System.
//
// Mục tiêu:
// - dùng pHealth/pArmour server-authoritative từ Player Health Core;
// - quản lý NORMAL / INJURED / DOWNED / DEAD bằng state machine;
// - hạn chế gameplay theo medical state qua một API dùng chung;
// - chống duplicate transition khi explosion/fall/burst damage xảy ra;
// - tạo downed countdown, stabilization, death và hospital recovery;
// - làm nền để EMS/wounds/bleeding có thể mở rộng mà không viết lại core.
//
// QUY TẮC TÍCH HỢP:
// Mọi system mới có action đáng kể nên gọi Medical_RequireAction() trước khi chạy.
// Ví dụ:
//     if (!Medical_RequireAction(playerid, MEDICAL_ACTION_JOB)) return 1;
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Configuration
//-----------------------------------------------------------------------------

// Health từ ngưỡng này trở xuống được coi là INJURED.
#define MEDICAL_INJURED_HEALTH               (50.0)

// Health từ ngưỡng này trở xuống sẽ chuyển DOWNED.
#define MEDICAL_DOWNED_HEALTH                (15.0)

// GTA client luôn được giữ ở HP này trong lúc DOWNED để tránh native death loop.
#define MEDICAL_DOWNED_CLIENT_HEALTH         (15.0)

// Damage đơn lẻ từ ngưỡng này trở lên được ghi nhận là severe.
#define MEDICAL_SEVERE_DAMAGE                (70.0)

// Thời gian tối đa player có thể nằm DOWNED trước khi chuyển DEAD.
#define MEDICAL_DOWNED_DURATION_SECONDS      (300)

// Player phải nằm ít nhất thời gian này mới được /acceptdeath.
#define MEDICAL_ACCEPT_DEATH_DELAY_SECONDS   (120)

// Tick medical state dùng để giữ animation/restriction/countdown đồng bộ.
#define MEDICAL_STATE_TICK_MS                (1000)

// Delay ngắn để sync lại health sau native damage callback.
#define MEDICAL_DAMAGE_RESYNC_DELAY_MS       (60)

// Health khi player tỉnh lại ở bệnh viện.
#define MEDICAL_HOSPITAL_HEALTH              (100.0)

// Armour bị reset khi hospital respawn.
#define MEDICAL_HOSPITAL_ARMOUR              (0.0)

// All Saints General Hospital spawn mặc định.
#define MEDICAL_HOSPITAL_X                   (1177.7500)
#define MEDICAL_HOSPITAL_Y                   (-1323.5680)
#define MEDICAL_HOSPITAL_Z                   (14.0810)
#define MEDICAL_HOSPITAL_A                   (270.0000)

// Animation DOWNED được medical tick duy trì.
#define MEDICAL_DOWNED_ANIM_LIB              "CRACK"
#define MEDICAL_DOWNED_ANIM_NAME             "crckdeth2"

//-----------------------------------------------------------------------------
// State / Action Enums
//-----------------------------------------------------------------------------

// Trạng thái medical chính của player.
enum E_PLAYER_MEDICAL_STATE
{
    MEDICAL_STATE_NORMAL = 0,
    MEDICAL_STATE_INJURED,
    MEDICAL_STATE_DOWNED,
    MEDICAL_STATE_DEAD
};

// Action categories dùng làm gate chung cho toàn bộ gamemode.
//
// System khác không cần hiểu chi tiết medical state;
// chỉ cần hỏi action nó muốn thực hiện có được phép hay không.
enum E_MEDICAL_ACTION
{
    // Chat RP cơ bản như /me, /do.
    MEDICAL_ACTION_RP_CHAT = 0,

    // Chat/communication thông thường.
    MEDICAL_ACTION_COMMUNICATION,

    // Đi bộ / di chuyển cơ bản.
    MEDICAL_ACTION_MOVE,

    // Sprint/jump hoặc movement nặng.
    MEDICAL_ACTION_SPRINT,

    // Dùng weapon hoặc combat action.
    MEDICAL_ACTION_WEAPON,

    // Lái vehicle.
    MEDICAL_ACTION_DRIVE,

    // Vào/ra vehicle hoặc vehicle interaction.
    MEDICAL_ACTION_VEHICLE,

    // Inventory interaction.
    MEDICAL_ACTION_INVENTORY,

    // Job interaction.
    MEDICAL_ACTION_JOB,

    // Faction duty/action.
    MEDICAL_ACTION_FACTION,

    // Property/business interaction.
    MEDICAL_ACTION_PROPERTY,

    // Generic interaction command.
    MEDICAL_ACTION_INTERACTION
};

//-----------------------------------------------------------------------------
// Runtime Data
//-----------------------------------------------------------------------------

// Runtime Medical data của một player.
enum E_PLAYER_MEDICAL_DATA
{
    // NORMAL / INJURED / DOWNED / DEAD hiện tại.
    E_PLAYER_MEDICAL_STATE:medicalState,

    // Khóa transition để burst damage không đổi state nhiều lần cùng lúc.
    bool:medicalTransitioning,

    // Sequence tăng mỗi damage event để callback deferred cũ tự vô hiệu.
    medicalDamageSequence,

    // Weapon/reason gần nhất.
    medicalLastWeapon,

    // Body part gần nhất.
    medicalLastBodyPart,

    // Player gây damage gần nhất hoặc INVALID_PLAYER_ID.
    medicalLastAttacker,

    // Damage amount gần nhất.
    Float:medicalLastDamage,

    // Damage gần nhất có vượt severe threshold hay không.
    bool:medicalLastDamageSevere,

    // Tổng số giây đã ở DOWNED.
    medicalDownedElapsed,

    // Số giây còn lại trước DEAD.
    medicalDownedRemaining,

    // EMS/medical treatment đã stabilize player hay chưa.
    bool:medicalStabilized,

    // Player đã đủ thời gian để dùng /acceptdeath hay chưa.
    bool:medicalCanAcceptDeath,

    // Đánh dấu native GTA death vừa xảy ra và cần khôi phục state sau spawn.
    bool:medicalPendingDownedRespawn,

    // Tick timestamp cuối dùng cho future wound/time calculations.
    medicalLastStateTick
};

// Medical runtime của từng player.
new PlayerMedical[MAX_PLAYERS][E_PLAYER_MEDICAL_DATA];

// Timer global xử lý countdown/restriction thay vì tạo một timer mỗi player.
new g_MedicalStateTimer;

//-----------------------------------------------------------------------------
// Forward Declarations
//-----------------------------------------------------------------------------

forward Medical_StateTick();
forward Medical_ResyncAfterDamage(playerid, sequence);

//-----------------------------------------------------------------------------
// Basic State API
//-----------------------------------------------------------------------------

// Reset toàn bộ medical runtime của player.
// Không thay đổi pHealth vì Health Core chịu trách nhiệm health authority.
stock Medical_Reset(playerid)
{
    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_NORMAL;
    PlayerMedical[playerid][medicalTransitioning] = false;
    PlayerMedical[playerid][medicalDamageSequence] = 0;

    PlayerMedical[playerid][medicalLastWeapon] = 0;
    PlayerMedical[playerid][medicalLastBodyPart] = 0;
    PlayerMedical[playerid][medicalLastAttacker] = INVALID_PLAYER_ID;
    PlayerMedical[playerid][medicalLastDamage] = 0.0;
    PlayerMedical[playerid][medicalLastDamageSevere] = false;

    PlayerMedical[playerid][medicalDownedElapsed] = 0;
    PlayerMedical[playerid][medicalDownedRemaining] = MEDICAL_DOWNED_DURATION_SECONDS;
    PlayerMedical[playerid][medicalStabilized] = false;
    PlayerMedical[playerid][medicalCanAcceptDeath] = false;
    PlayerMedical[playerid][medicalPendingDownedRespawn] = false;
    PlayerMedical[playerid][medicalLastStateTick] = 0;
    return 1;
}

// Trả về medical state hiện tại.
stock E_PLAYER_MEDICAL_STATE:Medical_GetState(playerid)
{
    return PlayerMedical[playerid][medicalState];
}

// Player có đang ở state NORMAL hay không.
stock bool:Medical_IsNormal(playerid)
{
    return (
        PlayerMedical[playerid][medicalState] ==
        MEDICAL_STATE_NORMAL
    );
}

// Player có đang INJURED hay không.
stock bool:Medical_IsInjured(playerid)
{
    return (
        PlayerMedical[playerid][medicalState] ==
        MEDICAL_STATE_INJURED
    );
}

// Player có đang DOWNED hay không.
stock bool:Medical_IsDowned(playerid)
{
    return (
        PlayerMedical[playerid][medicalState] ==
        MEDICAL_STATE_DOWNED
    );
}

// Player có đang DEAD hay không.
stock bool:Medical_IsDead(playerid)
{
    return (
        PlayerMedical[playerid][medicalState] ==
        MEDICAL_STATE_DEAD
    );
}

// Player có đang ở state hạn chế nặng hay không.
stock bool:Medical_IsIncapacitated(playerid)
{
    return (
        Medical_IsDowned(playerid) ||
        Medical_IsDead(playerid)
    );
}

//-----------------------------------------------------------------------------
// Shared Restriction Gate
//-----------------------------------------------------------------------------

// Kiểm tra medical state có cho phép action hay không.
//
// Đây là API chính để các system khác tích hợp.
// Không gửi message; phù hợp cho internal checks.
stock bool:Medical_CanPerform(
    playerid,
    E_MEDICAL_ACTION:action
)
{
    if (!IsPlayerConnected(playerid))
    {
        return false;
    }

    switch (PlayerMedical[playerid][medicalState])
    {
        case MEDICAL_STATE_NORMAL:
        {
            return true;
        }

        case MEDICAL_STATE_INJURED:
        {
            // Injured vẫn RP/chat/đi bộ và dùng interaction nhẹ.
            // Combat, sprint, job nặng và lái xe bị khóa.
            switch (action)
            {
                case MEDICAL_ACTION_RP_CHAT,
                     MEDICAL_ACTION_COMMUNICATION,
                     MEDICAL_ACTION_MOVE,
                     MEDICAL_ACTION_INVENTORY,
                     MEDICAL_ACTION_INTERACTION:
                {
                    return true;
                }
            }
            return false;
        }

        case MEDICAL_STATE_DOWNED:
        {
            // Downed chỉ còn RP chat và communication cần thiết.
            return (
                action == MEDICAL_ACTION_RP_CHAT ||
                action == MEDICAL_ACTION_COMMUNICATION
            );
        }

        case MEDICAL_STATE_DEAD:
        {
            // Dead chỉ giữ RP chat để mô tả body/death scene.
            return (
                action == MEDICAL_ACTION_RP_CHAT
            );
        }
    }

    return false;
}

// Trả về thông báo ngắn phù hợp với state/action bị từ chối.
stock Medical_GetRestrictionMessage(
    playerid,
    E_MEDICAL_ACTION:action,
    destination[],
    size
)
{
    #pragma unused action

    switch (PlayerMedical[playerid][medicalState])
    {
        case MEDICAL_STATE_INJURED:
        {
            format(
                destination,
                size,
                "Ban dang bi thuong va khong the thuc hien hanh dong nay."
            );
        }

        case MEDICAL_STATE_DOWNED:
        {
            format(
                destination,
                size,
                "Ban dang bi thuong nang va khong the thuc hien hanh dong nay."
            );
        }

        case MEDICAL_STATE_DEAD:
        {
            format(
                destination,
                size,
                "Ban da bat tinh/tu vong va khong the thuc hien hanh dong nay."
            );
        }

        default:
        {
            format(
                destination,
                size,
                "Ban khong the thuc hien hanh dong nay luc nay."
            );
        }
    }
    return 1;
}

// Gate có message cho player.
//
// Dùng ở command/action entry point:
//     if (!Medical_RequireAction(playerid, MEDICAL_ACTION_JOB)) return 1;
stock bool:Medical_RequireAction(
    playerid,
    E_MEDICAL_ACTION:action,
    bool:notify = true
)
{
    if (Medical_CanPerform(playerid, action))
    {
        return true;
    }

    if (notify)
    {
        new message[112];
        Medical_GetRestrictionMessage(
            playerid,
            action,
            message,
            sizeof(message)
        );
        SendClientMessage(playerid, 0x7A2929FF, message);
    }

    return false;
}

//-----------------------------------------------------------------------------
// State Transitions
//-----------------------------------------------------------------------------

// Đưa player về NORMAL.
// Chỉ nên dùng khi treatment/hospital đã kết thúc.
stock Medical_SetNormal(playerid)
{
    if (!PlayerHealth_IsReady(playerid))
    {
        return 0;
    }

    PlayerMedical[playerid][medicalTransitioning] = true;
    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_NORMAL;

    PlayerMedical[playerid][medicalDownedElapsed] = 0;
    PlayerMedical[playerid][medicalDownedRemaining] = MEDICAL_DOWNED_DURATION_SECONDS;
    PlayerMedical[playerid][medicalStabilized] = false;
    PlayerMedical[playerid][medicalCanAcceptDeath] = false;
    PlayerMedical[playerid][medicalPendingDownedRespawn] = false;

    ClearAnimations(playerid, 1);
    TogglePlayerControllable(playerid, true);

    PlayerMedical[playerid][medicalTransitioning] = false;
    return 1;
}

// Chuyển player sang INJURED nếu chưa incapacitated.
stock Medical_SetInjured(playerid)
{
    if (Medical_IsIncapacitated(playerid))
    {
        return 0;
    }

    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_INJURED;
    return 1;
}

// Apply animation DOWNED.
// Tick sẽ gọi lại để chống module khác vô tình clear animation.
stock Medical_ApplyDownedAnimation(playerid)
{
    if (!Medical_IsDowned(playerid) ||
        GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        return 0;
    }

    ApplyAnimation(
        playerid,
        MEDICAL_DOWNED_ANIM_LIB,
        MEDICAL_DOWNED_ANIM_NAME,
        4.1,
        true,
        false,
        false,
        true,
        0,
        SYNC_ALL
    );
    return 1;
}

// Chuyển player sang DOWNED.
//
// resetTimer:
//     true khi vừa bị hạ;
//     false khi khôi phục DOWNED sau native GTA respawn.
stock Medical_SetDowned(
    playerid,
    bool:resetTimer = true
)
{
    if (!PlayerHealth_IsReady(playerid) ||
        Medical_IsDead(playerid))
    {
        return 0;
    }

    if (PlayerMedical[playerid][medicalTransitioning])
    {
        return 0;
    }

    PlayerMedical[playerid][medicalTransitioning] = true;
    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_DOWNED;

    if (resetTimer)
    {
        PlayerMedical[playerid][medicalDownedElapsed] = 0;
        PlayerMedical[playerid][medicalDownedRemaining] =
            MEDICAL_DOWNED_DURATION_SECONDS;

        PlayerMedical[playerid][medicalStabilized] = false;
        PlayerMedical[playerid][medicalCanAcceptDeath] = false;
    }

    // Server authority giữ player sống về mặt GTA engine,
    // trong khi medical state quyết định player đã incapacitated.
    PlayerHealth_Set(
        playerid,
        MEDICAL_DOWNED_CLIENT_HEALTH
    );
    PlayerHealth_SetArmour(playerid, 0.0);

    SetPlayerArmedWeapon(playerid, 0);
    TogglePlayerControllable(playerid, false);
    Medical_ApplyDownedAnimation(playerid);

    SendClientMessage(
        playerid,
        0xBFC0C2FF,
        "Ban da bi thuong nang. Hay cho cap cuu hoac su dung /acceptdeath khi du dieu kien."
    );

    PlayerMedical[playerid][medicalTransitioning] = false;
    return 1;
}

// Chuyển player sang DEAD.
// DEAD không tự respawn; /acceptdeath sẽ đưa player về hospital.
stock Medical_SetDead(playerid)
{
    if (Medical_IsDead(playerid))
    {
        return 1;
    }

    PlayerMedical[playerid][medicalTransitioning] = true;
    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_DEAD;
    PlayerMedical[playerid][medicalStabilized] = false;
    PlayerMedical[playerid][medicalCanAcceptDeath] = true;

    SetPlayerArmedWeapon(playerid, 0);
    TogglePlayerControllable(playerid, false);

    SendClientMessage(
        playerid,
        0x7A2929FF,
        "Tinh trang cua ban da tro nen nguy kich. Ban co the su dung /acceptdeath."
    );

    PlayerMedical[playerid][medicalTransitioning] = false;
    return 1;
}

// EMS/treatment foundation: stabilize player đang DOWNED.
// Khi stabilized, countdown DEAD tạm dừng nhưng player vẫn DOWNED.
stock bool:Medical_Stabilize(playerid)
{
    if (!Medical_IsDowned(playerid))
    {
        return false;
    }

    PlayerMedical[playerid][medicalStabilized] = true;

    SendClientMessage(
        playerid,
        0xBFC0C2FF,
        "Tinh trang cua ban da duoc on dinh. Thoi gian nguy kich tam thoi dung lai."
    );
    return true;
}

// Bỏ stabilization khi wound/treatment thay đổi.
// Phase EMS sau có thể dùng khi player nhận damage mới.
stock Medical_RemoveStabilization(playerid)
{
    PlayerMedical[playerid][medicalStabilized] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// Character Load / Hospital
//-----------------------------------------------------------------------------

// Khởi tạo medical state từ pHealth sau khi character load.
//
// Persistent medical state chưa được lưu riêng ở phase này;
// health thấp sẽ map sang INJURED/DOWNED.
stock Medical_LoadCharacter(playerid)
{
    if (!PlayerHealth_IsReady(playerid))
    {
        return 0;
    }

    Medical_Reset(playerid);

    new const Float:health = PlayerHealth_Get(playerid);

    if (health <= MEDICAL_DOWNED_HEALTH)
    {
        PlayerMedical[playerid][medicalState] = MEDICAL_STATE_DOWNED;

        PlayerHealth_Set(
            playerid,
            MEDICAL_DOWNED_CLIENT_HEALTH,
            false
        );
        return 1;
    }

    if (health <= MEDICAL_INJURED_HEALTH)
    {
        PlayerMedical[playerid][medicalState] = MEDICAL_STATE_INJURED;
        return 1;
    }

    return 1;
}

// Respawn player tại hospital và reset medical state.
//
// Character_Save() dùng pHealth nên health hospital sẽ được persist an toàn.
stock Medical_HospitalRespawn(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    PlayerMedical[playerid][medicalTransitioning] = true;

    PlayerHealth_Set(playerid, MEDICAL_HOSPITAL_HEALTH, false);
    PlayerHealth_SetArmour(playerid, MEDICAL_HOSPITAL_ARMOUR, false);

    PlayerMedical[playerid][medicalState] = MEDICAL_STATE_NORMAL;
    PlayerMedical[playerid][medicalDownedElapsed] = 0;
    PlayerMedical[playerid][medicalDownedRemaining] =
        MEDICAL_DOWNED_DURATION_SECONDS;
    PlayerMedical[playerid][medicalStabilized] = false;
    PlayerMedical[playerid][medicalCanAcceptDeath] = false;
    PlayerMedical[playerid][medicalPendingDownedRespawn] = false;

    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);

    SetSpawnInfo(
        playerid,
        NO_TEAM,
        GetPlayerSkin(playerid),
        MEDICAL_HOSPITAL_X,
        MEDICAL_HOSPITAL_Y,
        MEDICAL_HOSPITAL_Z,
        MEDICAL_HOSPITAL_A
    );

    SpawnPlayer(playerid);

    PlayerMedical[playerid][medicalTransitioning] = false;
    return 1;
}

//-----------------------------------------------------------------------------
// Damage Processing
//-----------------------------------------------------------------------------

// Ghi metadata của damage gần nhất.
stock Medical_RecordDamage(
    playerid,
    issuerid,
    Float:amount,
    weaponid,
    bodypart
)
{
    PlayerMedical[playerid][medicalDamageSequence]++;

    PlayerMedical[playerid][medicalLastWeapon] = weaponid;
    PlayerMedical[playerid][medicalLastBodyPart] = bodypart;
    PlayerMedical[playerid][medicalLastAttacker] = issuerid;
    PlayerMedical[playerid][medicalLastDamage] = amount;
    PlayerMedical[playerid][medicalLastDamageSevere] = (
        amount >= MEDICAL_SEVERE_DAMAGE
    );

    return PlayerMedical[playerid][medicalDamageSequence];
}

// Đánh giá state mới dựa trên pHealth server authority.
stock Medical_UpdateStateFromHealth(playerid)
{
    if (!PlayerHealth_IsReady(playerid) ||
        PlayerMedical[playerid][medicalTransitioning] ||
        Medical_IsDead(playerid))
    {
        return 0;
    }

    new const Float:health = PlayerHealth_Get(playerid);

    if (health <= MEDICAL_DOWNED_HEALTH)
    {
        return Medical_SetDowned(playerid);
    }

    if (health <= MEDICAL_INJURED_HEALTH)
    {
        return Medical_SetInjured(playerid);
    }

    // Không auto recover từ INJURED về NORMAL vì health heal phải đi qua treatment.
    // NORMAL chỉ giữ nguyên nếu player chưa từng injured.
    return 1;
}

// Re-sync client health sau native damage callback.
//
// sequence chống callback cũ ghi đè state sau burst damage mới.
public Medical_ResyncAfterDamage(playerid, sequence)
{
    if (!IsPlayerConnected(playerid) ||
        !PlayerHealth_IsReady(playerid))
    {
        return 1;
    }

    if (sequence !=
        PlayerMedical[playerid][medicalDamageSequence])
    {
        return 1;
    }

    PlayerHealth_SyncClient(playerid);
    Medical_UpdateStateFromHealth(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// Command Restriction Helpers
//-----------------------------------------------------------------------------

// Trích command name từ cmdtext.
// Ví dụ "/car engine" -> "car".
stock Medical_GetCommandName(
    const cmdtext[],
    destination[],
    size
)
{
    if (cmdtext[0] != '/')
    {
        destination[0] = EOS;
        return 0;
    }

    new writeIndex = 0;

    for (new index = 1;
         cmdtext[index] != EOS &&
         cmdtext[index] != ' ' &&
         writeIndex < (size - 1);
         index++)
    {
        destination[writeIndex++] = cmdtext[index];
    }

    destination[writeIndex] = EOS;
    return writeIndex;
}

// Command whitelist khi DOWNED.
// Chỉ giữ RP/chat, emergency và death flow.
stock bool:Medical_IsDownedCommandAllowed(
    const command[]
)
{
    return (
        !strcmp(command, "me", true) ||
        !strcmp(command, "do", true) ||
        !strcmp(command, "b", true) ||
        !strcmp(command, "pm", true) ||
        !strcmp(command, "call", true) ||
        !strcmp(command, "911", true) ||
        !strcmp(command, "acceptdeath", true)
    );
}

// Command whitelist khi DEAD.
// DEAD chỉ được mô tả RP và accept death.
stock bool:Medical_IsDeadCommandAllowed(
    const command[]
)
{
    return (
        !strcmp(command, "me", true) ||
        !strcmp(command, "do", true) ||
        !strcmp(command, "b", true) ||
        !strcmp(command, "acceptdeath", true)
    );
}

//-----------------------------------------------------------------------------
// Global Medical Tick
//-----------------------------------------------------------------------------

// Tick một player đang INJURED.
// Weapon bị ép về fists và sprint/combat actions bị gate ở callback khác.
stock Medical_TickInjured(playerid)
{
    if (!Medical_IsInjured(playerid))
    {
        return 0;
    }

    // Injured không được giữ weapon để tránh bypass command restriction.
    if (GetPlayerWeapon(playerid) != 0)
    {
        SetPlayerArmedWeapon(playerid, 0);
    }

    return 1;
}

// Tick một player đang DOWNED.
// Giữ animation, weapon lock và countdown.
stock Medical_TickDowned(playerid)
{
    if (!Medical_IsDowned(playerid))
    {
        return 0;
    }

    SetPlayerArmedWeapon(playerid, 0);
    TogglePlayerControllable(playerid, false);
    Medical_ApplyDownedAnimation(playerid);

    PlayerMedical[playerid][medicalDownedElapsed]++;

    if (PlayerMedical[playerid][medicalDownedElapsed] >=
        MEDICAL_ACCEPT_DEATH_DELAY_SECONDS)
    {
        PlayerMedical[playerid][medicalCanAcceptDeath] = true;
    }

    // Stabilized player không mất thêm critical time.
    if (PlayerMedical[playerid][medicalStabilized])
    {
        return 1;
    }

    if (PlayerMedical[playerid][medicalDownedRemaining] > 0)
    {
        PlayerMedical[playerid][medicalDownedRemaining]--;
    }

    if (PlayerMedical[playerid][medicalDownedRemaining] <= 0)
    {
        Medical_SetDead(playerid);
    }

    return 1;
}

// Tick DEAD giữ player incapacitated.
stock Medical_TickDead(playerid)
{
    if (!Medical_IsDead(playerid))
    {
        return 0;
    }

    SetPlayerArmedWeapon(playerid, 0);
    TogglePlayerControllable(playerid, false);
    return 1;
}

// Timer global xử lý state của toàn bộ online players.
public Medical_StateTick()
{
    new const now = gettime();

    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid) ||
            !IsPlayerCharacterLoaded(playerid))
        {
            continue;
        }

        PlayerMedical[playerid][medicalLastStateTick] = now;

        switch (PlayerMedical[playerid][medicalState])
        {
            case MEDICAL_STATE_INJURED:
            {
                Medical_TickInjured(playerid);
            }

            case MEDICAL_STATE_DOWNED:
            {
                Medical_TickDowned(playerid);
            }

            case MEDICAL_STATE_DEAD:
            {
                Medical_TickDead(playerid);
            }
        }
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Hooks
//-----------------------------------------------------------------------------

// Khởi tạo global medical timer.
hook OnGameModeInit()
{
    g_MedicalStateTimer = SetTimer(
        "Medical_StateTick",
        MEDICAL_STATE_TICK_MS,
        true
    );
    return 1;
}

// Cleanup global medical timer.
hook OnGameModeExit()
{
    if (g_MedicalStateTimer)
    {
        KillTimer(g_MedicalStateTimer);
        g_MedicalStateTimer = 0;
    }
    return 1;
}

// Reset medical runtime khi player connect.
hook OnPlayerConnect(playerid)
{
    Medical_Reset(playerid);
    return 1;
}

// Server-authoritative damage entry.
//
// pHealth/pArmour là nguồn truth.
// Native client health chỉ bị sync lại sau damage.
hook OnPlayerTakeDamage(
    playerid,
    issuerid,
    Float:amount,
    WEAPON:weaponid,
    bodypart
)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        !PlayerHealth_IsReady(playerid))
    {
        return 1;
    }

    if (Medical_IsDead(playerid))
    {
        return 1;
    }

    new const sequence = Medical_RecordDamage(
        playerid,
        issuerid,
        amount,
        _:weaponid,
        bodypart
    );

    // Damage mới làm mất stabilization.
    if (Medical_IsDowned(playerid))
    {
        Medical_RemoveStabilization(playerid);
    }

    PlayerHealth_ApplyDamage(playerid, amount);
    Medical_UpdateStateFromHealth(playerid);

    SetTimerEx(
        "Medical_ResyncAfterDamage",
        MEDICAL_DAMAGE_RESYNC_DELAY_MS,
        false,
        "dd",
        playerid,
        sequence
    );
    return 1;
}

// Safety net cho native GTA death do explosion/fall/burst damage.
//
// Native death không được phép persist HP 0.
// Sau spawn, medical state được khôi phục thành DOWNED.
hook OnPlayerDeath(
    playerid,
    killerid,
    WEAPON:reason
)
{
    #pragma unused killerid

    if (!IsPlayerCharacterLoaded(playerid) ||
        !PlayerHealth_IsReady(playerid))
    {
        return 1;
    }

    PlayerMedical[playerid][medicalLastWeapon] = _:reason;
    PlayerMedical[playerid][medicalPendingDownedRespawn] = true;

    // Giữ authority ở downed HP, không lưu native 0 health.
    pHealth[playerid] = MEDICAL_DOWNED_CLIENT_HEALTH;
    pArmour[playerid] = 0.0;

    // Nếu chưa DEAD thì native death luôn được chuyển thành DOWNED.
    if (!Medical_IsDead(playerid))
    {
        PlayerMedical[playerid][medicalState] =
            MEDICAL_STATE_DOWNED;
    }

    return 1;
}

// Spawn hook xử lý:
// - hospital respawn NORMAL;
// - native death safety respawn trở lại DOWNED;
// - đồng bộ pHealth/pArmour.
hook OnPlayerSpawn(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        !PlayerHealth_IsReady(playerid))
    {
        return 1;
    }

    if (PlayerMedical[playerid][medicalPendingDownedRespawn])
    {
        PlayerMedical[playerid][medicalPendingDownedRespawn] = false;

        Medical_SetDowned(
            playerid,
            false
        );
        return 1;
    }

    if (Medical_IsNormal(playerid))
    {
        TogglePlayerControllable(playerid, true);
        PlayerHealth_SyncClient(playerid);
    }

    return 1;
}

// Global command gate.
//
// INJURED:
//     không block toàn bộ command vì mỗi system có thể có interaction nhẹ;
//     các module mới phải dùng Medical_RequireAction.
//
// DOWNED/DEAD:
//     block toàn bộ command không nằm whitelist để không có bypass từ module cũ.
hook OnPlayerCommandText(
    playerid,
    cmdtext[]
)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        Medical_IsNormal(playerid))
    {
        return 0;
    }

    new command[32];
    Medical_GetCommandName(
        cmdtext,
        command,
        sizeof(command)
    );

    if (Medical_IsDowned(playerid))
    {
        if (Medical_IsDownedCommandAllowed(command))
        {
            return 0;
        }

        Medical_RequireAction(
            playerid,
            MEDICAL_ACTION_INTERACTION
        );
        return ~1;
    }

    if (Medical_IsDead(playerid))
    {
        if (Medical_IsDeadCommandAllowed(command))
        {
            return 0;
        }

        Medical_RequireAction(
            playerid,
            MEDICAL_ACTION_INTERACTION
        );
        return ~1;
    }

    return 0;
}

// Key restriction.
//
// INJURED:
//     không cho sprint/jump/fire/aim.
//
// DOWNED/DEAD:
//     clear toàn bộ combat/movement key có thể gây bypass animation.
hook OnPlayerKeyStateChange(
    playerid,
    KEY:newkeys,
    KEY:oldkeys
)
{
    #pragma unused oldkeys

    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    if (Medical_IsInjured(playerid))
    {
        if ((newkeys & KEY_FIRE) ||
            (newkeys & KEY_AIM) ||
            (newkeys & KEY_SPRINT) ||
            (newkeys & KEY_JUMP))
        {
            SetPlayerArmedWeapon(playerid, 0);
        }

        return 1;
    }

    if (Medical_IsIncapacitated(playerid))
    {
        SetPlayerArmedWeapon(playerid, 0);
        TogglePlayerControllable(playerid, false);
    }

    return 1;
}

// Vehicle state restriction.
//
// Player injured/downed/dead không được lái vehicle.
// Nếu module khác đưa player vào driver seat, callback này eject player ngay.
hook OnPlayerStateChange(
    playerid,
    PLAYER_STATE:newstate,
    PLAYER_STATE:oldstate
)
{
    #pragma unused oldstate

    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    if (newstate == PLAYER_STATE_DRIVER &&
        !Medical_CanPerform(
            playerid,
            MEDICAL_ACTION_DRIVE
        ))
    {
        RemovePlayerFromVehicle(playerid);

        Medical_RequireAction(
            playerid,
            MEDICAL_ACTION_DRIVE
        );
    }

    return 1;
}
