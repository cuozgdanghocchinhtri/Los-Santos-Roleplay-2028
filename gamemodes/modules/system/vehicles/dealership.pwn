//-----------------------------------------------------------------------------
// Vehicle Dealership Showroom Prototype.
//
// Chịu trách nhiệm:
// - mở showroom preview riêng cho từng player;
// - spawn vehicle preview trong virtual world riêng;
// - điều khiển camera showroom;
// - hiển thị PlayerTextDraw interface;
// - chuyển xe bằng Previous / Next;
// - đóng showroom và trả player về vị trí cũ.
//
// Purchase hiện mới là prototype UI.
// Chưa trừ tiền hoặc INSERT vào player_vehicles.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Dealership Configuration
//-----------------------------------------------------------------------------

// Số lượng vehicle mẫu đang có trong showroom prototype.
#define DEALERSHIP_VEHICLE_COUNT       (18)

// Số màu preset cho Color Picker cách 1.
#define DEALERSHIP_COLOR_COUNT         (35)

// Virtual world riêng của showroom.
// Mỗi player được cộng playerid để không nhìn thấy preview vehicle của nhau.
#define DEALERSHIP_WORLD_BASE          (5000)

// Màu hover/click của TextDraw dealership.
#define DEALERSHIP_TD_HOVER_COLOR      (0x264A73FF)

// Màu nền charcoal của panel UI.
#define DEALERSHIP_TD_PANEL_COLOR      (0x17191CCC)

// Màu chữ chính.
#define DEALERSHIP_TD_TEXT_COLOR       (0xFFFFFFFF)

// Màu chữ phụ.
#define DEALERSHIP_TD_MUTED_COLOR      (0xBFC0C2FF)

// Màu cảnh báo / unavailable.
#define DEALERSHIP_TD_ERROR_COLOR      (0x7A2929FF)

// Vị trí vehicle preview trong showroom.
#define DEALERSHIP_PREVIEW_X           (2135.6500)
#define DEALERSHIP_PREVIEW_Y           (-1148.2500)
#define DEALERSHIP_PREVIEW_Z           (24.2270)
#define DEALERSHIP_PREVIEW_A           (182.0000)

// Vị trí camera showroom.
#define DEALERSHIP_CAMERA_X            (2144.0000)
#define DEALERSHIP_CAMERA_Y            (-1159.2000)
#define DEALERSHIP_CAMERA_Z            (29.0000)

// Điểm camera nhìn vào.
#define DEALERSHIP_LOOK_X              (2135.6500)
#define DEALERSHIP_LOOK_Y              (-1148.2500)
#define DEALERSHIP_LOOK_Z              (24.9500)

//-----------------------------------------------------------------------------
// Dealership Vehicle Data
//-----------------------------------------------------------------------------

// Dữ liệu UI của một mẫu xe đang bán trong showroom prototype.
enum E_DEALERSHIP_VEHICLE_DATA
{
    // GTA model ID.
    dvModelID,

    // Giá hiển thị trong showroom.
    dvPrice,

    // Điểm tốc độ 1-10 dùng cho UI.
    dvSpeed,

    // Điểm handling 1-10 dùng cho UI.
    dvHandling,

    // Dung tích bình nhiên liệu.
    Float:dvFuelCapacity,

    // Mức độ bền/khả năng chịu hư hỏng 1-10.
    dvDurability,

    // Số tháng bảo hành dealership.
    dvWarrantyMonths,

    // Vehicle class ngắn dùng cho UI.
    dvClass[20],

    // Tên category showroom.
    dvCategory[24]
};

// Danh sách vehicle mẫu.
// Sau này nên chuyển giá/stock/category sang database dealership_vehicles.
new const g_DealershipVehicles[DEALERSHIP_VEHICLE_COUNT][E_DEALERSHIP_VEHICLE_DATA] =
{
    {560,  85000, 8, 8, 65.0, 7, 24, "SPORT",   "Sports Sedan"},
    {562,  92000, 9, 8, 60.0, 6, 24, "SPORT",   "Sports Coupe"},
    {579,  68000, 6, 7, 75.0, 9, 36, "SUV",     "SUV"},
    {405,  42000, 6, 7, 60.0, 8, 24, "SEDAN",   "Sedan"},
    {496,  55000, 7, 8, 50.0, 6, 24, "COMPACT", "Compact"},
    {402,  78000, 8, 7, 70.0, 8, 24, "MUSCLE",  "Muscle"},
    {415, 145000, 9, 9, 70.0, 5, 12, "SUPER",   "Supercar"},
    {429, 135000, 9, 8, 65.0, 5, 12, "SPORT",   "Sports"},
    {541, 165000,10, 9, 75.0, 4, 12, "SUPER",   "Supercar"},
    {559,  88000, 8, 9, 60.0, 6, 24, "SPORT",   "Sports Coupe"},
    {411, 175000,10, 9, 72.0, 4, 12, "SUPER",   "Supercar"},
    {451, 158000, 9, 9, 68.0, 5, 12, "SUPER",   "Supercar"},
    {477,  97000, 8, 8, 62.0, 6, 24, "SPORT",   "Sports Coupe"},
    {480,  91000, 8, 8, 58.0, 6, 24, "SPORT",   "Roadster"},
    {506, 118000, 9, 8, 66.0, 5, 18, "SPORT",   "Sports"},
    {558,  84000, 8, 9, 58.0, 6, 24, "TUNER",   "Tuner"},
    {561,  74000, 7, 8, 64.0, 7, 24, "WAGON",   "Sports Wagon"},
    {587,  99000, 8, 8, 61.0, 6, 24, "SPORT",   "Sports Coupe"}
};

// GTA vehicle color IDs dùng cho Color Picker preset.
// Palette V9 dùng 35 màu và render 7 màu mỗi hàng x 5 hàng.
new const g_DealershipVehicleColors[DEALERSHIP_COLOR_COUNT] =
{
    1, 0, 25, 6, 36, 3, 79,
    126, 86, 7, 16, 53, 135, 147,
    103, 92, 101, 63, 93, 151, 64,
    27, 128, 158, 41, 11, 22, 31,
    58, 75, 14, 18, 32, 45, 87
};

// Màu UI tương ứng với 35 GTA vehicle color preset.
new const g_DealershipUIColor[DEALERSHIP_COLOR_COUNT] =
{
    0x111111FF, 0xF4F4F4FF, 0xA5A7AAFF, 0xE8C82AFF, 0xE77A28FF, 0xE33D3DFF, 0x842D2DFF,
    0x2EC9CBFF, 0x4CA7DEFF, 0x365FD1FF, 0x49AA4CFF, 0x246A39FF, 0x9E43C9FF, 0xE066A6FF,
    0x81563CFF, 0xD2C2A2FF, 0xC5A03AFF, 0x55585CFF, 0xC5C8CBFF, 0x34D9E2FF, 0x253A78FF,
    0x77A7CFFF, 0x4E3529FF, 0x70D84AFF, 0xB85C3AFF, 0xD8D1B0FF, 0x5F7C8AFF, 0x8C6B9EFF,
    0x4B4B4BFF, 0xB7A06AFF, 0x6D8F3CFF, 0x3E6E73FF, 0xB04A7DFF, 0x8D6CB8FF, 0x4A7B9CFF
};

//-----------------------------------------------------------------------------
// Player Runtime State
//-----------------------------------------------------------------------------

// Player hiện có đang ở dealership showroom hay không.
new bool:g_DealershipActive[MAX_PLAYERS];

// Index vehicle hiện player đang preview.
new g_DealershipIndex[MAX_PLAYERS];

// Index màu preset hiện player đang chọn.
// Index này trỏ vào g_DealershipVehicleColors.
new g_DealershipColorIndex[MAX_PLAYERS];

// Runtime vehicle ID của preview vehicle.
// Vehicle này không phải Player Vehicle và không được save database.
new g_DealershipPreviewVehicle[MAX_PLAYERS];

// Vị trí player trước khi bước vào showroom.
// Dùng để trả player về đúng nơi khi đóng UI.
new Float:g_DealershipReturnX[MAX_PLAYERS];
new Float:g_DealershipReturnY[MAX_PLAYERS];
new Float:g_DealershipReturnZ[MAX_PLAYERS];
new Float:g_DealershipReturnA[MAX_PLAYERS];

// Interior của player trước khi vào showroom.
new g_DealershipReturnInterior[MAX_PLAYERS];

// Virtual world của player trước khi vào showroom.
new g_DealershipReturnWorld[MAX_PLAYERS];

// Timer đang dùng cho cinematic camera sweep của showroom.
// Timer này chỉ sống trong lúc player đang ở dealership.
new g_DealershipCameraTimer[MAX_PLAYERS];

// Stage hiện tại của camera orbit PREVIEW.
// 0-15 = hai vòng quanh xe, 16 = trở về camera showroom.
new g_DealershipCameraStage[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// PlayerTextDraw Handles
//-----------------------------------------------------------------------------

// Panel thông tin bên trái.
new PlayerText:g_DealerTDPanel[MAX_PLAYERS];

// Panel danh sách vehicle bên phải.
new PlayerText:g_DealerTDListPanel[MAX_PLAYERS];

// Panel trung tâm gom giá, tên xe, navigation, PREVIEW và BUY.
new PlayerText:g_DealerTDCenterPanel[MAX_PLAYERS];

// Header dealership bên trái.
new PlayerText:g_DealerTDHeader[MAX_PLAYERS];

// Tên vehicle hiện tại ở giữa dưới.
new PlayerText:g_DealerTDVehicleName[MAX_PLAYERS];

// Category vehicle hiện tại.
new PlayerText:g_DealerTDCategory[MAX_PLAYERS];

// Giá vehicle hiện tại.
new PlayerText:g_DealerTDPrice[MAX_PLAYERS];

// Thông số vehicle.
new PlayerText:g_DealerTDStats[MAX_PLAYERS];

// Counter hiện tại, ví dụ 03 / 05.
new PlayerText:g_DealerTDCounter[MAX_PLAYERS];

// Nút previous vehicle.
new PlayerText:g_DealerTDPrevious[MAX_PLAYERS];

// Nút next vehicle.
new PlayerText:g_DealerTDNext[MAX_PLAYERS];

// Nút PREVIEW chạy camera 360 độ hai vòng quanh vehicle.
new PlayerText:g_DealerTDTestDrive[MAX_PLAYERS];

// Nút Purchase prototype.
new PlayerText:g_DealerTDPurchase[MAX_PLAYERS];

// Nút thoát showroom.
new PlayerText:g_DealerTDExit[MAX_PLAYERS];

// Tiêu đề khu Color Picker.
new PlayerText:g_DealerTDColorTitle[MAX_PLAYERS];

// Text hiển thị màu preset đang chọn.
new PlayerText:g_DealerTDColorSelected[MAX_PLAYERS];

// 35 ô Color Picker preset có thể click.
new PlayerText:g_DealerTDColor[MAX_PLAYERS][DEALERSHIP_COLOR_COUNT];

// Tiêu đề danh sách vehicle bên phải.
new PlayerText:g_DealerTDListTitle[MAX_PLAYERS];

// Subtitle số lượng xe đang có trong list phải.
new PlayerText:g_DealerTDListSubTitle[MAX_PLAYERS];

// Danh sách vehicle bên phải, click trực tiếp để preview.
new PlayerText:g_DealerTDVehicleList[MAX_PLAYERS][DEALERSHIP_VEHICLE_COUNT];

// Footer/hint của showroom.
new PlayerText:g_DealerTDHint[MAX_PLAYERS];

//-----------------------------------------------------------------------------
// Forward Declarations
//-----------------------------------------------------------------------------

forward Dealership_Open(playerid);
forward Dealership_Close(playerid);
forward Dealership_RefreshPreview(playerid);
forward Dealership_CreateUI(playerid);
forward Dealership_DestroyUI(playerid);
forward Dealership_ShowUI(playerid);
forward Dealership_HideUI(playerid);
forward Dealership_CameraSweepStage(playerid);

//-----------------------------------------------------------------------------
// Utility
//-----------------------------------------------------------------------------

// Trả về tên GTA vehicle model để hiển thị trong dealership.
stock Dealership_GetModelName(modelID, destination[], size)
{
    if (modelID < 400 || modelID > 611)
    {
        format(destination, size, "Unknown Vehicle");
        return 0;
    }

    new modelName[32];
    Model_GetName(modelID, modelName);
    format(destination, size, "%s", modelName);
    return 1;
}

// Format integer thành chuỗi tiền dạng $85,000.
// Hàm prototype hỗ trợ giá dưới một triệu một cách dễ đọc.
stock Dealership_FormatPrice(value, destination[], size)
{
    if (value >= 1000000)
    {
        format(
            destination,
            size,
            "$%d,%03d,%03d",
            value / 1000000,
            (value / 1000) % 1000,
            value % 1000
        );
        return 1;
    }

    if (value >= 1000)
    {
        format(
            destination,
            size,
            "$%d,%03d",
            value / 1000,
            value % 1000
        );
        return 1;
    }

    format(destination, size, "$%d", value);
    return 1;
}

// Destroy preview vehicle hiện tại của player nếu nó còn tồn tại.
stock Dealership_DestroyPreviewVehicle(playerid)
{
    new const vehicleid = g_DealershipPreviewVehicle[playerid];

    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        DestroyVehicle(vehicleid);
    }

    g_DealershipPreviewVehicle[playerid] = INVALID_VEHICLE_ID;
    return 1;
}


// Hủy camera timer cũ để không có nhiều cinematic chạy chồng lên nhau.
stock Dealership_StopCameraSweep(playerid)
{
    if (g_DealershipCameraTimer[playerid])
    {
        KillTimer(g_DealershipCameraTimer[playerid]);
        g_DealershipCameraTimer[playerid] = 0;
    }

    g_DealershipCameraStage[playerid] = 0;
    return 1;
}

// Tính vị trí camera trên một vòng tròn quanh preview vehicle.
//
// angle:
//     Góc tính theo degree.
//
// radius:
//     Bán kính orbit quanh vehicle.
//
// Camera cao hơn tâm vehicle để giữ góc showroom 3/4 tự nhiên.
stock Dealership_GetSmoothOrbitPoint(
    Float:angle,
    Float:radius,
    &Float:x,
    &Float:y,
    &Float:z
)
{
    x = DEALERSHIP_LOOK_X + (radius * floatsin(angle, degrees));
    y = DEALERSHIP_LOOK_Y + (radius * floatcos(angle, degrees));
    z = DEALERSHIP_LOOK_Z + 2.70;
    return 1;
}

// Bắt đầu PREVIEW camera 360 độ x 2 vòng.
//
// Bản V6 chia mỗi vòng thành 32 đoạn thay vì 8 đoạn.
// Các đoạn ngắn khiến đường đi gần hình tròn hơn và giảm cảm giác giật ở góc.
stock Dealership_StartCameraPreview(playerid)
{
    if (!g_DealershipActive[playerid])
    {
        return 0;
    }

    Dealership_StopCameraSweep(playerid);

    // Stage 0 bắt đầu tại 0 degree.
    g_DealershipCameraStage[playerid] = 0;

    new Float:startX, Float:startY, Float:startZ;
    Dealership_GetSmoothOrbitPoint(0.0, 8.4, startX, startY, startZ);

    SetPlayerCameraPos(playerid, startX, startY, startZ);
    SetPlayerCameraLookAt(
        playerid,
        DEALERSHIP_LOOK_X,
        DEALERSHIP_LOOK_Y,
        DEALERSHIP_LOOK_Z,
        CAMERA_CUT
    );

    Dealership_CameraSweepStage(playerid);
    return 1;
}

// Chạy từng đoạn của smooth camera orbit.
//
// 32 đoạn = một vòng.
// 64 đoạn = hai vòng.
// Mỗi đoạn chỉ 11.25 độ nên ít thấy góc gãy hơn bản 8 điểm.
public Dealership_CameraSweepStage(playerid)
{
    g_DealershipCameraTimer[playerid] = 0;

    if (!IsPlayerConnected(playerid) ||
        !g_DealershipActive[playerid])
    {
        return 1;
    }

    new const stage = g_DealershipCameraStage[playerid];

    // Sau hai vòng, camera trở về góc browse mặc định.
    if (stage >= 64)
    {
        new Float:lastX, Float:lastY, Float:lastZ;
        Dealership_GetSmoothOrbitPoint(0.0, 8.4, lastX, lastY, lastZ);

        InterpolateCameraPos(
            playerid,
            lastX,
            lastY,
            lastZ,
            DEALERSHIP_CAMERA_X,
            DEALERSHIP_CAMERA_Y,
            DEALERSHIP_CAMERA_Z,
            500,
            CAMERA_MOVE
        );

        InterpolateCameraLookAt(
            playerid,
            DEALERSHIP_LOOK_X,
            DEALERSHIP_LOOK_Y,
            DEALERSHIP_LOOK_Z,
            DEALERSHIP_LOOK_X,
            DEALERSHIP_LOOK_Y,
            DEALERSHIP_LOOK_Z,
            500,
            CAMERA_MOVE
        );

        g_DealershipCameraStage[playerid] = 0;
        return 1;
    }

    // Mỗi stage di chuyển 11.25 degree.
    new Float:fromAngle = float(stage) * 11.25;
    new Float:toAngle = float(stage + 1) * 11.25;

    new Float:fromX, Float:fromY, Float:fromZ;
    new Float:toX, Float:toY, Float:toZ;

    Dealership_GetSmoothOrbitPoint(
        fromAngle,
        8.4,
        fromX,
        fromY,
        fromZ
    );
    Dealership_GetSmoothOrbitPoint(
        toAngle,
        8.4,
        toX,
        toY,
        toZ
    );

    InterpolateCameraPos(
        playerid,
        fromX,
        fromY,
        fromZ,
        toX,
        toY,
        toZ,
        115,
        CAMERA_MOVE
    );

    // LookAt giữ cố định ở tâm xe trong toàn bộ orbit.
    InterpolateCameraLookAt(
        playerid,
        DEALERSHIP_LOOK_X,
        DEALERSHIP_LOOK_Y,
        DEALERSHIP_LOOK_Z,
        DEALERSHIP_LOOK_X,
        DEALERSHIP_LOOK_Y,
        DEALERSHIP_LOOK_Z,
        115,
        CAMERA_MOVE
    );

    g_DealershipCameraStage[playerid]++;

    // Timer cao hơn interpolation một chút để tránh hai segment chồng nhau.
    g_DealershipCameraTimer[playerid] =
        SetTimerEx("Dealership_CameraSweepStage", 120, false, "d", playerid);

    return 1;
}

//-----------------------------------------------------------------------------
// UI Creation
//-----------------------------------------------------------------------------

// Tạo toàn bộ PlayerTextDraw của showroom cho một player.
// Layout V10:
// - Camera được dời để giảm vật cản ở foreground;
// - 35 màu vẫn theo 7 cột x 5 hàng, có highlight cho màu đang chọn;
// - Panel giữa thu gọn lại, list phải thêm subtitle rõ số lượng xe.
public Dealership_CreateUI(playerid)
{
    // Panel thông tin trái.
    g_DealerTDPanel[playerid] = CreatePlayerTextDraw(playerid, 15.0, 76.0, "_");
    PlayerTextDrawUseBox(playerid, g_DealerTDPanel[playerid], true);
    PlayerTextDrawBoxColor(playerid, g_DealerTDPanel[playerid], 0x101317D8);
    PlayerTextDrawTextSize(playerid, g_DealerTDPanel[playerid], 180.0, 0.0);
    PlayerTextDrawLetterSize(playerid, g_DealerTDPanel[playerid], 0.0, 29.2);

    // Panel danh sách vehicle phải.
    g_DealerTDListPanel[playerid] = CreatePlayerTextDraw(playerid, 469.0, 63.0, "_");
    PlayerTextDrawUseBox(playerid, g_DealerTDListPanel[playerid], true);
    PlayerTextDrawBoxColor(playerid, g_DealerTDListPanel[playerid], 0x101317D8);
    PlayerTextDrawTextSize(playerid, g_DealerTDListPanel[playerid], 628.0, 0.0);
    PlayerTextDrawLetterSize(playerid, g_DealerTDListPanel[playerid], 0.0, 30.8);

    // Header dealership.
    g_DealerTDHeader[playerid] = CreatePlayerTextDraw(playerid, 25.0, 86.0, "JEFFERSON MOTORS");
    PlayerTextDrawFont(playerid, g_DealerTDHeader[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDHeader[playerid], 0.30, 1.05);
    PlayerTextDrawColor(playerid, g_DealerTDHeader[playerid], 0x3ED7E6FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDHeader[playerid], 0);

    // Counter.
    g_DealerTDCounter[playerid] = CreatePlayerTextDraw(playerid, 169.0, 87.0, "01 / 18");
    PlayerTextDrawAlignment(playerid, g_DealerTDCounter[playerid], TEXT_DRAW_ALIGN_RIGHT);
    PlayerTextDrawFont(playerid, g_DealerTDCounter[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, g_DealerTDCounter[playerid], 0.17, 0.80);
    PlayerTextDrawColor(playerid, g_DealerTDCounter[playerid], 0x858585FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDCounter[playerid], 0);

    // Category.
    g_DealerTDCategory[playerid] = CreatePlayerTextDraw(playerid, 25.0, 108.0, "Sports Sedan");
    PlayerTextDrawFont(playerid, g_DealerTDCategory[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDCategory[playerid], 0.22, 0.90);
    PlayerTextDrawColor(playerid, g_DealerTDCategory[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDCategory[playerid], 0);

    // Stats sát dòng hơn.
    g_DealerTDStats[playerid] = CreatePlayerTextDraw(
        playerid,
        25.0,
        130.0,
        "CLASS        SPORT~n~PERFORMANCE  8/10~n~HANDLING     8/10~n~DURABILITY   7/10~n~FUEL TANK    65 L~n~WARRANTY     24 MONTHS~n~CONDITION    NEW"
    );
    PlayerTextDrawFont(playerid, g_DealerTDStats[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, g_DealerTDStats[playerid], 0.145, 0.58);
    PlayerTextDrawColor(playerid, g_DealerTDStats[playerid], 0xBFC0C2FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDStats[playerid], 0);

    // Color Picker title.
    g_DealerTDColorTitle[playerid] = CreatePlayerTextDraw(playerid, 25.0, 191.0, "CHOOSE COLOR");
    PlayerTextDrawFont(playerid, g_DealerTDColorTitle[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDColorTitle[playerid], 0.22, 0.88);
    PlayerTextDrawColor(playerid, g_DealerTDColorTitle[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDColorTitle[playerid], 0);

    // Selected color indicator.
    g_DealerTDColorSelected[playerid] = CreatePlayerTextDraw(playerid, 25.0, 207.0, "COLOR 01 / 35");
    PlayerTextDrawFont(playerid, g_DealerTDColorSelected[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, g_DealerTDColorSelected[playerid], 0.16, 0.70);
    PlayerTextDrawColor(playerid, g_DealerTDColorSelected[playerid], 0x858585FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDColorSelected[playerid], 0);

    // 35 màu: 7 màu mỗi hàng x 5 hàng.
    // Mỗi ô có PlayerTextDraw riêng và clickable bounds riêng.
    for (new colorIndex = 0; colorIndex < DEALERSHIP_COLOR_COUNT; colorIndex++)
    {
        new const column = colorIndex % 7;
        new const row = colorIndex / 7;

        new const Float:colorX = 24.0 + (column * 18.7);
        new const Float:colorY = 226.0 + (row * 14.8);

        g_DealerTDColor[playerid][colorIndex] =
            CreatePlayerTextDraw(playerid, colorX, colorY, "_");

        PlayerTextDrawUseBox(
            playerid,
            g_DealerTDColor[playerid][colorIndex],
            true
        );
        PlayerTextDrawBoxColor(
            playerid,
            g_DealerTDColor[playerid][colorIndex],
            g_DealershipUIColor[colorIndex]
        );

        // Left alignment: TextSize là góc phải-dưới tuyệt đối của vùng click.
        PlayerTextDrawTextSize(
            playerid,
            g_DealerTDColor[playerid][colorIndex],
            colorX + 15.3,
            colorY + 9.5
        );
        PlayerTextDrawLetterSize(
            playerid,
            g_DealerTDColor[playerid][colorIndex],
            0.0,
            0.90
        );
        PlayerTextDrawSetSelectable(
            playerid,
            g_DealerTDColor[playerid][colorIndex],
            true
        );
    }

    // Exit.
    g_DealerTDExit[playerid] = CreatePlayerTextDraw(playerid, 25.0, 309.0, "EXIT SHOWROOM");
    PlayerTextDrawFont(playerid, g_DealerTDExit[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDExit[playerid], 0.18, 0.86);
    PlayerTextDrawColor(playerid, g_DealerTDExit[playerid], 0x7A2929FF);
    PlayerTextDrawTextSize(playerid, g_DealerTDExit[playerid], 116.0, 321.0);
    PlayerTextDrawSetShadow(playerid, g_DealerTDExit[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, g_DealerTDExit[playerid], true);

    // Panel trung tâm gom toàn bộ control của vehicle hiện tại.
    g_DealerTDCenterPanel[playerid] =
        CreatePlayerTextDraw(playerid, 273.0, 326.0, "_");
    PlayerTextDrawUseBox(
        playerid,
        g_DealerTDCenterPanel[playerid],
        true
    );
    PlayerTextDrawBoxColor(
        playerid,
        g_DealerTDCenterPanel[playerid],
        0x101317D8
    );
    PlayerTextDrawTextSize(
        playerid,
        g_DealerTDCenterPanel[playerid],
        371.0,
        0.0
    );
    PlayerTextDrawLetterSize(
        playerid,
        g_DealerTDCenterPanel[playerid],
        0.0,
        6.1
    );

    // Giá.
    g_DealerTDPrice[playerid] = CreatePlayerTextDraw(playerid, 322.0, 331.0, "$85,000");
    PlayerTextDrawAlignment(playerid, g_DealerTDPrice[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawFont(playerid, g_DealerTDPrice[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDPrice[playerid], 0.31, 1.08);
    PlayerTextDrawColor(playerid, g_DealerTDPrice[playerid], 0x76D843FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDPrice[playerid], 0);

    // Tên vehicle.
    g_DealerTDVehicleName[playerid] = CreatePlayerTextDraw(playerid, 322.0, 346.0, "SULTAN");
    PlayerTextDrawAlignment(playerid, g_DealerTDVehicleName[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawFont(playerid, g_DealerTDVehicleName[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDVehicleName[playerid], 0.40, 1.32);
    PlayerTextDrawColor(playerid, g_DealerTDVehicleName[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDVehicleName[playerid], 0);

    // Previous.
    g_DealerTDPrevious[playerid] = CreatePlayerTextDraw(playerid, 296.0, 363.0, "<");
    PlayerTextDrawFont(playerid, g_DealerTDPrevious[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDPrevious[playerid], 0.34, 1.10);
    PlayerTextDrawColor(playerid, g_DealerTDPrevious[playerid], 0xFFFFFFFF);
    PlayerTextDrawTextSize(playerid, g_DealerTDPrevious[playerid], 310.0, 374.0);
    PlayerTextDrawSetShadow(playerid, g_DealerTDPrevious[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, g_DealerTDPrevious[playerid], true);

    // Next.
    g_DealerTDNext[playerid] = CreatePlayerTextDraw(playerid, 349.0, 363.0, ">");
    PlayerTextDrawFont(playerid, g_DealerTDNext[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDNext[playerid], 0.34, 1.10);
    PlayerTextDrawColor(playerid, g_DealerTDNext[playerid], 0xFFFFFFFF);
    PlayerTextDrawTextSize(playerid, g_DealerTDNext[playerid], 363.0, 374.0);
    PlayerTextDrawSetShadow(playerid, g_DealerTDNext[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, g_DealerTDNext[playerid], true);

    // PREVIEW: camera 360 độ hai vòng.
    g_DealerTDTestDrive[playerid] = CreatePlayerTextDraw(playerid, 281.0, 379.0, "      PREVIEW");
    PlayerTextDrawUseBox(playerid, g_DealerTDTestDrive[playerid], true);
    PlayerTextDrawBoxColor(playerid, g_DealerTDTestDrive[playerid], 0xF2F2F2E6);
    PlayerTextDrawTextSize(playerid, g_DealerTDTestDrive[playerid], 363.0, 390.0);
    PlayerTextDrawFont(playerid, g_DealerTDTestDrive[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDTestDrive[playerid], 0.16, 0.80);
    PlayerTextDrawColor(playerid, g_DealerTDTestDrive[playerid], 0x17191CFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDTestDrive[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, g_DealerTDTestDrive[playerid], true);

    // Buy Vehicle.
    g_DealerTDPurchase[playerid] = CreatePlayerTextDraw(playerid, 281.0, 396.0, "    BUY VEHICLE");
    PlayerTextDrawUseBox(playerid, g_DealerTDPurchase[playerid], true);
    PlayerTextDrawBoxColor(playerid, g_DealerTDPurchase[playerid], 0x68C83BE8);
    PlayerTextDrawTextSize(playerid, g_DealerTDPurchase[playerid], 363.0, 407.0);
    PlayerTextDrawFont(playerid, g_DealerTDPurchase[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDPurchase[playerid], 0.16, 0.82);
    PlayerTextDrawColor(playerid, g_DealerTDPurchase[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDPurchase[playerid], 0);
    PlayerTextDrawSetSelectable(playerid, g_DealerTDPurchase[playerid], true);

    // List title.
    g_DealerTDListTitle[playerid] = CreatePlayerTextDraw(playerid, 480.0, 72.0, "VEHICLES");
    PlayerTextDrawFont(playerid, g_DealerTDListTitle[playerid], TEXT_DRAW_FONT_2);
    PlayerTextDrawLetterSize(playerid, g_DealerTDListTitle[playerid], 0.27, 1.0);
    PlayerTextDrawColor(playerid, g_DealerTDListTitle[playerid], 0xFFFFFFFF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDListTitle[playerid], 0);

    g_DealerTDListSubTitle[playerid] = CreatePlayerTextDraw(playerid, 480.0, 85.0, "18 AVAILABLE");
    PlayerTextDrawFont(playerid, g_DealerTDListSubTitle[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, g_DealerTDListSubTitle[playerid], 0.18, 0.72);
    PlayerTextDrawColor(playerid, g_DealerTDListSubTitle[playerid], 0x3ED7E6FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDListSubTitle[playerid], 0);

    // 10 vehicle row cực sát nhau, gần như một list liên tục.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        new const Float:listY = 96.0 + (vehicleIndex * 12.9);

        g_DealerTDVehicleList[playerid][vehicleIndex] =
            CreatePlayerTextDraw(playerid, 480.0, listY, "Vehicle");

        PlayerTextDrawUseBox(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            true
        );
        PlayerTextDrawBoxColor(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            0x202429C4
        );

        // Click area chỉ cao 11 units để không đè row kế tiếp.
        PlayerTextDrawTextSize(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            617.0,
            listY + 8.0
        );
        PlayerTextDrawFont(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            TEXT_DRAW_FONT_2
        );
        PlayerTextDrawLetterSize(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            0.152,
            0.64
        );
        PlayerTextDrawColor(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            0xBFC0C2FF
        );
        PlayerTextDrawSetShadow(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            0
        );
        PlayerTextDrawSetSelectable(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            true
        );
    }

    // Footer.
    g_DealerTDHint[playerid] = CreatePlayerTextDraw(
        playerid,
        547.0,
        327.0,
        "18 VEHICLES"
    );
    PlayerTextDrawAlignment(playerid, g_DealerTDHint[playerid], TEXT_DRAW_ALIGN_CENTER);
    PlayerTextDrawFont(playerid, g_DealerTDHint[playerid], TEXT_DRAW_FONT_1);
    PlayerTextDrawLetterSize(playerid, g_DealerTDHint[playerid], 0.14, 0.64);
    PlayerTextDrawColor(playerid, g_DealerTDHint[playerid], 0x858585FF);
    PlayerTextDrawSetShadow(playerid, g_DealerTDHint[playerid], 0);

    return 1;
}

// Hiển thị toàn bộ dealership PlayerTextDraw và bật cursor.
public Dealership_ShowUI(playerid)
{
    PlayerTextDrawShow(playerid, g_DealerTDPanel[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDListPanel[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDCenterPanel[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDHeader[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDCounter[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDVehicleName[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDCategory[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDPrice[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDStats[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDPrevious[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDNext[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDTestDrive[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDPurchase[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDExit[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDColorTitle[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDColorSelected[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDListTitle[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDListSubTitle[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDHint[playerid]);

    // Hiển thị toàn bộ ô màu preset.
    for (new colorIndex = 0; colorIndex < DEALERSHIP_COLOR_COUNT; colorIndex++)
    {
        PlayerTextDrawShow(playerid, g_DealerTDColor[playerid][colorIndex]);
    }

    // Hiển thị toàn bộ vehicle row bên phải.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        PlayerTextDrawShow(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex]
        );
    }

    SelectTextDraw(playerid, DEALERSHIP_TD_HOVER_COLOR);
    return 1;
}

// Ẩn toàn bộ dealership UI và tắt cursor TextDraw.
public Dealership_HideUI(playerid)
{
    CancelSelectTextDraw(playerid);

    PlayerTextDrawHide(playerid, g_DealerTDPanel[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDListPanel[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDCenterPanel[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDHeader[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDCounter[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDVehicleName[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDCategory[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDPrice[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDStats[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDPrevious[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDNext[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDTestDrive[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDPurchase[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDExit[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDColorTitle[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDColorSelected[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDListTitle[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDListSubTitle[playerid]);
    PlayerTextDrawHide(playerid, g_DealerTDHint[playerid]);

    // Ẩn toàn bộ ô màu preset.
    for (new colorIndex = 0; colorIndex < DEALERSHIP_COLOR_COUNT; colorIndex++)
    {        PlayerTextDrawHide(playerid, g_DealerTDColor[playerid][colorIndex]);
    }

    // Ẩn toàn bộ vehicle row bên phải.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        PlayerTextDrawHide(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex]
        );
    }

    return 1;
}

// Destroy toàn bộ dealership PlayerTextDraw của player.
public Dealership_DestroyUI(playerid)
{
    PlayerTextDrawDestroy(playerid, g_DealerTDPanel[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDListPanel[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDCenterPanel[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDHeader[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDCounter[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDVehicleName[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDCategory[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDPrice[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDStats[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDPrevious[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDNext[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDTestDrive[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDPurchase[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDExit[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDColorTitle[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDColorSelected[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDListTitle[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDListSubTitle[playerid]);
    PlayerTextDrawDestroy(playerid, g_DealerTDHint[playerid]);

    // Destroy toàn bộ ô màu preset.
    for (new colorIndex = 0; colorIndex < DEALERSHIP_COLOR_COUNT; colorIndex++)
    {        PlayerTextDrawDestroy(playerid, g_DealerTDColor[playerid][colorIndex]);
    }

    // Destroy toàn bộ vehicle row bên phải.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        PlayerTextDrawDestroy(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex]
        );
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Preview
//-----------------------------------------------------------------------------

// Spawn lại vehicle preview dựa trên index hiện tại.
// Đồng thời apply màu preset và refresh toàn bộ UI/list highlight.
public Dealership_RefreshPreview(playerid)
{
    if (!g_DealershipActive[playerid])
    {
        return 0;
    }

    Dealership_DestroyPreviewVehicle(playerid);

    new const index = g_DealershipIndex[playerid];
    new const colorIndex = g_DealershipColorIndex[playerid];
    new const modelID = g_DealershipVehicles[index][dvModelID];
    new const vehicleColor = g_DealershipVehicleColors[colorIndex];

    // Preview vehicle chỉ dùng để trưng bày và không được save database.
    new const vehicleid = CreateVehicle(
        modelID,
        DEALERSHIP_PREVIEW_X,
        DEALERSHIP_PREVIEW_Y,
        DEALERSHIP_PREVIEW_Z,
        DEALERSHIP_PREVIEW_A,
        vehicleColor,
        vehicleColor,
        -1
    );

    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, 0x7A2929FF, "Khong the tao xe preview luc nay.");
        return 0;
    }

    g_DealershipPreviewVehicle[playerid] = vehicleid;

    // Preview vehicle được cô lập theo virtual world của player.
    SetVehicleVirtualWorld(
        vehicleid,
        DEALERSHIP_WORLD_BASE + playerid
    );

    // Khóa preview vehicle để nó chỉ là vật thể showroom.
    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_ON,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF
    );

    new modelName[32];
    new priceText[32];
    // Buffer lớn hơn để không cắt dòng CONDITION/WARRANTY.
    new statsText[192];
    new counterText[24];
    new colorText[32];

    Dealership_GetModelName(modelID, modelName, sizeof(modelName));
    Dealership_FormatPrice(
        g_DealershipVehicles[index][dvPrice],
        priceText,
        sizeof(priceText)
    );

    // Thông số showroom chỉ mang tính gameplay/UI.
    // Durability và warranty hiện là dealership metadata, chưa ảnh hưởng mechanics.
    format(
        statsText,
        sizeof(statsText),
        "CLASS        %s~n~PERFORMANCE  %d/10~n~HANDLING     %d/10~n~DURABILITY   %d/10~n~FUEL TANK    %.0f L~n~WARRANTY     %d MONTHS~n~CONDITION    NEW",
        g_DealershipVehicles[index][dvClass],
        g_DealershipVehicles[index][dvSpeed],
        g_DealershipVehicles[index][dvHandling],
        g_DealershipVehicles[index][dvDurability],
        g_DealershipVehicles[index][dvFuelCapacity],
        g_DealershipVehicles[index][dvWarrantyMonths]
    );

    format(
        counterText,
        sizeof(counterText),
        "%02d / %02d",
        index + 1,
        DEALERSHIP_VEHICLE_COUNT
    );

    format(
        colorText,
        sizeof(colorText),
        "COLOR %02d / %02d",
        colorIndex + 1,
        DEALERSHIP_COLOR_COUNT
    );

    PlayerTextDrawSetString(playerid, g_DealerTDVehicleName[playerid], modelName);
    PlayerTextDrawSetString(
        playerid,
        g_DealerTDCategory[playerid],
        g_DealershipVehicles[index][dvCategory]
    );
    PlayerTextDrawSetString(playerid, g_DealerTDPrice[playerid], priceText);
    PlayerTextDrawSetString(playerid, g_DealerTDStats[playerid], statsText);
    PlayerTextDrawSetString(playerid, g_DealerTDCounter[playerid], counterText);
    PlayerTextDrawSetString(playerid, g_DealerTDColorSelected[playerid], colorText);
    PlayerTextDrawColor(
        playerid,
        g_DealerTDColorSelected[playerid],
        g_DealershipUIColor[colorIndex]
    );
    PlayerTextDrawHide(playerid, g_DealerTDColorSelected[playerid]);
    PlayerTextDrawShow(playerid, g_DealerTDColorSelected[playerid]);

    new availableText[32];
    format(availableText, sizeof(availableText), "%d AVAILABLE", DEALERSHIP_VEHICLE_COUNT);
    PlayerTextDrawSetString(playerid, g_DealerTDListSubTitle[playerid], availableText);

    // Refresh text và highlight của từng vehicle row bên phải.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        new listModelName[32];
        new listPrice[32];
        new listText[96];

        Dealership_GetModelName(
            g_DealershipVehicles[vehicleIndex][dvModelID],
            listModelName,
            sizeof(listModelName)
        );
        Dealership_FormatPrice(
            g_DealershipVehicles[vehicleIndex][dvPrice],
            listPrice,
            sizeof(listPrice)
        );

        format(
            listText,
            sizeof(listText),
            "%s  %s",
            listModelName,
            listPrice
        );

        PlayerTextDrawSetString(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex],
            listText
        );

        // Vehicle đang chọn dùng xanh lá để đồng bộ với nút BUY.
        if (vehicleIndex == index)
        {
            PlayerTextDrawColor(
                playerid,
                g_DealerTDVehicleList[playerid][vehicleIndex],
                0xFFFFFFFF
            );
            PlayerTextDrawBoxColor(
                playerid,
                g_DealerTDVehicleList[playerid][vehicleIndex],
                0x4FAF35E8
            );
        }
        else
        {
            PlayerTextDrawColor(
                playerid,
                g_DealerTDVehicleList[playerid][vehicleIndex],
                0xBFC0C2FF
            );
            PlayerTextDrawBoxColor(
                playerid,
                g_DealerTDVehicleList[playerid][vehicleIndex],
                0x202429C4
            );
        }

        // Textdraw phải được show lại để client nhận màu mới ngay lập tức.
        PlayerTextDrawHide(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex]
        );
        PlayerTextDrawShow(
            playerid,
            g_DealerTDVehicleList[playerid][vehicleIndex]
        );
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Showroom Lifecycle
//-----------------------------------------------------------------------------

// Mở showroom và lưu lại vị trí hiện tại để có thể restore khi player thoát.
public Dealership_Open(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return 0;
    }

    if (!IsPlayerCharacterLoaded(playerid))
    {
        SendClientMessage(playerid, 0x7A2929FF, "Ban chua tai nhan vat.");
        return 0;
    }

    if (g_DealershipActive[playerid])
    {
        return 1;
    }

    // Lưu vị trí/world hiện tại trước khi chuyển player vào showroom riêng.
    GetPlayerPos(
        playerid,
        g_DealershipReturnX[playerid],
        g_DealershipReturnY[playerid],
        g_DealershipReturnZ[playerid]
    );
    GetPlayerFacingAngle(playerid, g_DealershipReturnA[playerid]);

    g_DealershipReturnInterior[playerid] = GetPlayerInterior(playerid);
    g_DealershipReturnWorld[playerid] = GetPlayerVirtualWorld(playerid);

    g_DealershipActive[playerid] = true;
    g_DealershipIndex[playerid] = 0;

    // Mặc định showroom mở với màu đen.
    g_DealershipColorIndex[playerid] = 0;

    g_DealershipPreviewVehicle[playerid] = INVALID_VEHICLE_ID;

    // Đưa player vào virtual world showroom riêng.
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, DEALERSHIP_WORLD_BASE + playerid);
    SetPlayerPos(
        playerid,
        DEALERSHIP_PREVIEW_X,
        DEALERSHIP_PREVIEW_Y - 8.0,
        DEALERSHIP_PREVIEW_Z
    );

    // Freeze player để trải nghiệm tập trung hoàn toàn vào showroom/camera.
    TogglePlayerControllable(playerid, false);

    SetPlayerCameraPos(
        playerid,
        DEALERSHIP_CAMERA_X,
        DEALERSHIP_CAMERA_Y,
        DEALERSHIP_CAMERA_Z
    );
    SetPlayerCameraLookAt(
        playerid,
        DEALERSHIP_LOOK_X,
        DEALERSHIP_LOOK_Y,
        DEALERSHIP_LOOK_Z,
        CAMERA_CUT
    );

    Dealership_CreateUI(playerid);
    Dealership_RefreshPreview(playerid);
    Dealership_ShowUI(playerid);

    return 1;
}

// Đóng showroom, destroy preview/UI và đưa player về vị trí trước đó.
public Dealership_Close(playerid)
{
    if (!g_DealershipActive[playerid])
    {
        return 0;
    }

    // Dừng cinematic trước khi restore camera/player.
    Dealership_StopCameraSweep(playerid);

    Dealership_HideUI(playerid);
    Dealership_DestroyPreviewVehicle(playerid);
    Dealership_DestroyUI(playerid);

    g_DealershipActive[playerid] = false;
    g_DealershipIndex[playerid] = 0;

    SetPlayerInterior(playerid, g_DealershipReturnInterior[playerid]);
    SetPlayerVirtualWorld(playerid, g_DealershipReturnWorld[playerid]);
    SetPlayerPos(
        playerid,
        g_DealershipReturnX[playerid],
        g_DealershipReturnY[playerid],
        g_DealershipReturnZ[playerid]
    );
    SetPlayerFacingAngle(playerid, g_DealershipReturnA[playerid]);

    SetCameraBehindPlayer(playerid);
    TogglePlayerControllable(playerid, true);

    return 1;
}

//-----------------------------------------------------------------------------
// Commands
//-----------------------------------------------------------------------------

// /dealer
// Mở prototype showroom ở bất kỳ đâu để test giao diện.
// Sau này command này sẽ được thay bằng dealership checkpoint/NPC interaction.
CMD:dealer(playerid, params[])
{
    #pragma unused params

    Dealership_Open(playerid);
    return 1;
}

// /dealerexit
// Fallback command để thoát showroom trong trường hợp player không dùng nút EXIT.
CMD:dealerexit(playerid, params[])
{
    #pragma unused params

    Dealership_Close(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// TextDraw Interaction
//-----------------------------------------------------------------------------

// Xử lý click vào toàn bộ interactive PlayerTextDraw của dealership.
hook OnPlayerClickPlayerTextDraw(playerid, PlayerText:playertextid)
{
    if (!g_DealershipActive[playerid])
    {
        return 1;
    }

    // Chọn một trong 24 màu preset.
    for (new colorIndex = 0; colorIndex < DEALERSHIP_COLOR_COUNT; colorIndex++)
    {
        if (playertextid != g_DealerTDColor[playerid][colorIndex])
        {
            continue;
        }

        g_DealershipColorIndex[playerid] = colorIndex;

        new const vehicleid = g_DealershipPreviewVehicle[playerid];
        if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
        {
            new const vehicleColor = g_DealershipVehicleColors[colorIndex];
            ChangeVehicleColor(vehicleid, vehicleColor, vehicleColor);
        }

        new colorText[32];
        format(
            colorText,
            sizeof(colorText),
            "COLOR %02d / %02d",
            colorIndex + 1,
            DEALERSHIP_COLOR_COUNT
        );
        PlayerTextDrawSetString(
            playerid,
            g_DealerTDColorSelected[playerid],
            colorText
        );
        PlayerTextDrawColor(
            playerid,
            g_DealerTDColorSelected[playerid],
            g_DealershipUIColor[colorIndex]
        );
        PlayerTextDrawHide(playerid, g_DealerTDColorSelected[playerid]);
        PlayerTextDrawShow(playerid, g_DealerTDColorSelected[playerid]);
        return 1;
    }

    // Click trực tiếp một vehicle row bên phải.
    for (new vehicleIndex = 0; vehicleIndex < DEALERSHIP_VEHICLE_COUNT; vehicleIndex++)
    {
        if (playertextid != g_DealerTDVehicleList[playerid][vehicleIndex])
        {
            continue;
        }

        Dealership_StopCameraSweep(playerid);
        g_DealershipIndex[playerid] = vehicleIndex;
        Dealership_RefreshPreview(playerid);

        SetPlayerCameraPos(
            playerid,
            DEALERSHIP_CAMERA_X,
            DEALERSHIP_CAMERA_Y,
            DEALERSHIP_CAMERA_Z
        );
        SetPlayerCameraLookAt(
            playerid,
            DEALERSHIP_LOOK_X,
            DEALERSHIP_LOOK_Y,
            DEALERSHIP_LOOK_Z,
            CAMERA_CUT
        );
        return 1;
    }

    if (playertextid == g_DealerTDPrevious[playerid])
    {
        Dealership_StopCameraSweep(playerid);

        g_DealershipIndex[playerid]--;
        if (g_DealershipIndex[playerid] < 0)
        {
            g_DealershipIndex[playerid] = DEALERSHIP_VEHICLE_COUNT - 1;
        }

        Dealership_RefreshPreview(playerid);
        SetPlayerCameraPos(
            playerid,
            DEALERSHIP_CAMERA_X,
            DEALERSHIP_CAMERA_Y,
            DEALERSHIP_CAMERA_Z
        );
        SetPlayerCameraLookAt(
            playerid,
            DEALERSHIP_LOOK_X,
            DEALERSHIP_LOOK_Y,
            DEALERSHIP_LOOK_Z,
            CAMERA_CUT
        );
        return 1;
    }

    if (playertextid == g_DealerTDNext[playerid])
    {
        Dealership_StopCameraSweep(playerid);

        g_DealershipIndex[playerid]++;
        if (g_DealershipIndex[playerid] >= DEALERSHIP_VEHICLE_COUNT)
        {
            g_DealershipIndex[playerid] = 0;
        }

        Dealership_RefreshPreview(playerid);
        SetPlayerCameraPos(
            playerid,
            DEALERSHIP_CAMERA_X,
            DEALERSHIP_CAMERA_Y,
            DEALERSHIP_CAMERA_Z
        );
        SetPlayerCameraLookAt(
            playerid,
            DEALERSHIP_LOOK_X,
            DEALERSHIP_LOOK_Y,
            DEALERSHIP_LOOK_Z,
            CAMERA_CUT
        );
        return 1;
    }

    // PREVIEW chỉ điều khiển camera, không spawn test-drive vehicle.
    if (playertextid == g_DealerTDTestDrive[playerid])
    {
        Dealership_StartCameraPreview(playerid);
        return 1;
    }

    // Purchase vẫn là prototype, chưa đụng economy/database.
    if (playertextid == g_DealerTDPurchase[playerid])
    {
        new const index = g_DealershipIndex[playerid];

        new modelName[32];
        new priceText[32];

        Dealership_GetModelName(
            g_DealershipVehicles[index][dvModelID],
            modelName,
            sizeof(modelName)
        );
        Dealership_FormatPrice(
            g_DealershipVehicles[index][dvPrice],
            priceText,
            sizeof(priceText)
        );

        new message[180];
        format(
            message,
            sizeof(message),
            "{BFC0C2}Purchase prototype: {FFFFFF}%s {858585}(%s), {BFC0C2}Color #%d. Transaction chua duoc ket noi.",
            modelName,
            priceText,
            g_DealershipColorIndex[playerid] + 1
        );
        SendClientMessage(playerid, 0xFFFFFFFF, message);
        return 1;
    }

    if (playertextid == g_DealerTDExit[playerid])
    {
        Dealership_Close(playerid);
        return 1;
    }

    return 1;
}

//-----------------------------------------------------------------------------
// Hooks
//-----------------------------------------------------------------------------

// Reset dealership runtime state khi player kết nối.
hook OnPlayerConnect(playerid)
{
    g_DealershipActive[playerid] = false;
    g_DealershipIndex[playerid] = 0;
    g_DealershipColorIndex[playerid] = 0;
    g_DealershipPreviewVehicle[playerid] = INVALID_VEHICLE_ID;
    g_DealershipCameraTimer[playerid] = 0;
    g_DealershipCameraStage[playerid] = 0;
    return 1;
}

// Cleanup showroom khi player disconnect để không leak preview vehicle.
hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (g_DealershipActive[playerid])
    {
        Dealership_StopCameraSweep(playerid);
        Dealership_DestroyPreviewVehicle(playerid);
        g_DealershipActive[playerid] = false;
    }
    return 1;
}
