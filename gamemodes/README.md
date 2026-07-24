# LOS SANTOS ROLEPLAY 2028 — GAMEMODE DEVELOPMENT STANDARD

> Đây là tài liệu chuẩn cao nhất cho toàn bộ code bên trong thư mục `gamemodes/`.
>
> Mọi thay đổi mới, refactor, module mới, command mới, variable mới hoặc function mới
> phải tuân theo tài liệu này.
>
> Khi code hiện tại và README này mâu thuẫn nhau, code mới phải ưu tiên theo README này,
> trừ khi có lý do kỹ thuật rõ ràng và được ghi chú trực tiếp trong source.

---

# 1. Mục tiêu kiến trúc

Gamemode phải được phát triển theo hướng:

- Modular.
- Dễ đọc.
- Dễ mở rộng.
- Dễ debug.
- Hạn chế duplicate logic.
- Không để một module biết quá nhiều dữ liệu nội bộ của module khác.
- Mọi system lớn phải có một lớp data rõ ràng.
- Runtime data và persistent data phải được phân biệt rõ.
- Function dùng chung phải được đưa về core/API thay vì copy sang nhiều system.

Không ưu tiên viết code ngắn nếu làm code khó đọc.

**Ưu tiên code rõ nghĩa hơn code thông minh.**

---

# 2. QUY TẮC COMMENT — BẮT BUỘC

## 2.1. Mọi function phải có comment

Mỗi function, stock, public, callback helper hoặc command handler phải có `//`
giải thích ngắn gọn function đó làm gì.

Ví dụ đúng:

```pawn
// Trả về lượng xăng hiện tại của runtime vehicle dựa trên loại vehicle.
Float:Vehicle_GetFuel(vehicleid)
{
    ...
}
```

Không viết function mới kiểu:

```pawn
Float:Vehicle_GetFuel(vehicleid)
{
    ...
}
```

mà không có comment.

---

## 2.2. Function phức tạp phải ghi thêm input/output

Function có nhiều điều kiện, thao tác DB, runtime mapping hoặc thay đổi state nên ghi rõ:

```pawn
// Lưu trạng thái hiện tại của Player Vehicle xuống database.
//
// playerid:
//     Player đang giữ data vehicle trong memory.
//
// slot:
//     Slot của vehicle trong PlayerVehicle[playerid].
//
// updatePark:
//     true  = cập nhật vị trí đỗ hiện tại.
//     false = giữ nguyên vị trí đỗ.
//
// storage:
//     Storage state mới sau khi save.
//
// Return:
//     1 nếu request save hợp lệ.
//     0 nếu dữ liệu vehicle không hợp lệ.
stock PlayerVehicle_SaveState(playerid, slot, bool:updatePark, storage)
{
    ...
}
```

Không bắt buộc comment dài cho function đơn giản.

Nhưng **function nào cũng phải có ít nhất một dòng mô tả**.

---

# 3. Mọi variable quan trọng phải có comment

## 3.1. Global variable

Mọi global variable phải có comment mô tả nó lưu cái gì.

Ví dụ:

```pawn
// Số lượng Player Vehicle đã load của từng player.
new g_PlayerVehicleCount[MAX_PLAYERS];

// Slot Player Vehicle hiện đang được spawn của player.
new g_PlayerVehicleActiveSlot[MAX_PLAYERS];
```

Không được khai báo hàng loạt variable không rõ nghĩa.

Sai:

```pawn
new
    count[MAX_PLAYERS],
    slot[MAX_PLAYERS],
    state[MAX_PLAYERS];
```

Đúng:

```pawn
// Số lượng vehicle đã load cho player.
new g_PlayerVehicleCount[MAX_PLAYERS];

// Slot vehicle đang active trong thế giới game.
new g_PlayerVehicleActiveSlot[MAX_PLAYERS];

// Trạng thái load data vehicle của player.
new bool:g_PlayerVehicleLoaded[MAX_PLAYERS];
```

---

## 3.2. Local variable

Không cần comment cho variable quá hiển nhiên:

```pawn
new playerid;
new vehicleid;
new slot;
new Float:x, Float:y, Float:z;
```

Nhưng local variable mang ý nghĩa business/state đặc biệt phải có comment.

Ví dụ:

```pawn
// Database ID của character đang sở hữu vehicle.
new const characterID = GetPlayerCharacterID(playerid);

// Lượng fuel tiêu hao trong tick hiện tại.
new Float:fuelConsumption;
```

---

# 4. Enum phải có comment rõ ràng

Enum lớn phải ghi mục đích chung.

Các field không hiển nhiên phải có comment.

Ví dụ:

```pawn
// Persistent data của một Player Vehicle.
//
// Đây là nguồn dữ liệu chính của vehicle thuộc character.
// Runtime Vehicle chỉ giữ reference về character + slot.
enum E_PLAYER_VEHICLE_DATA
{
    // Primary key trong bảng player_vehicles.
    pvDatabaseID,

    // open.mp runtime vehicle ID.
    // INVALID_VEHICLE_ID khi xe chưa được spawn.
    pvServerID,

    // GTA vehicle model ID.
    pvModelID,

    // Màu primary/secondary của vehicle.
    pvColor1,
    pvColor2,

    // Trạng thái stored/spawned/impounded/destroyed.
    pvStorage,

    // Trạng thái persistent của khóa cửa.
    bool:pvLocked,

    // Trạng thái engine runtime được cache vào Player Vehicle.
    bool:pvEngine,

    // Trạng thái trunk runtime được cache vào Player Vehicle.
    bool:pvTrunk,

    // Lượng xăng hiện tại.
    Float:pvFuel,

    // Tổng số kilomet vehicle đã chạy.
    Float:pvMileage,

    // Vehicle health cuối cùng được lưu.
    Float:pvHealth,

    // Vị trí đỗ persistent.
    Float:pvParkX,
    Float:pvParkY,
    Float:pvParkZ,
    Float:pvParkA,

    // Interior và virtual world của vị trí đỗ.
    pvInterior,
    pvVirtualWorld,

    // GTA damage state.
    VEHICLE_PANEL_STATUS:pvPanels,
    VEHICLE_DOOR_STATUS:pvDoors,
    VEHICLE_LIGHT_STATUS:pvLights,
    VEHICLE_TYRE_STATUS:pvTyres,

    // Biển số vehicle.
    pvPlate[SIMPLE_VEHICLE_PLATE_LENGTH]
};
```

---

# 5. Define và constant phải có comment

Define không hiển nhiên phải được mô tả.

Ví dụ:

```pawn
// Khoảng cách tối đa để player thao tác với vehicle đang đứng gần.
#define VEHICLE_INTERACT_DISTANCE (5.0)

// Chu kỳ cập nhật runtime fuel/mileage của vehicle.
#define VEHICLE_RUNTIME_TICK_MS (5000)
```

Không cần comment cho constant quá rõ trong một block đã có header mô tả.

---

# 6. Callback và hook phải ghi mục đích

Ví dụ:

```pawn
// Reset runtime Player Vehicle data khi player vừa connect.
hook OnPlayerConnect(playerid)
{
    ...
}
```

```pawn
// Load Player Vehicle sau khi character đã load hoàn chỉnh.
hook OnCharacterLoaded(playerid)
{
    ...
}
```

Callback dài phải comment các đoạn xử lý lớn bên trong.

---

# 7. Command phải có comment

Mỗi command phải ghi rõ mục đích và permission nếu có.

Ví dụ:

```pawn
// /veh
// Tạo temporary admin vehicle.
// Chỉ Admin Level 3+ được sử dụng.
// Vehicle này không được lưu vào database.
CMD:veh(playerid, params[])
{
    ...
}
```

```pawn
// /car
// Điều khiển runtime vehicle thông qua Vehicle Core.
CMD:car(playerid, params[])
{
    ...
}
```

---

# 8. Database query phải có comment

Query quan trọng phải ghi rõ nó đang đọc/ghi cái gì.

Ví dụ:

```pawn
// Lưu persistent state của Player Vehicle hiện tại.
mysql_format(
    g_DatabaseHandle,
    query,
    sizeof(query),
    "UPDATE `player_vehicles` ..."
);
```

Query phức tạp phải được format dễ đọc.

Không build SQL khó hiểu mà không ghi mục đích.

---

# 9. Timer phải có comment

Mọi timer phải ghi:

- chạy bao lâu một lần;
- dùng để làm gì;
- dữ liệu nào nó thay đổi.

Ví dụ:

```pawn
// Chạy mỗi 5 giây.
// Cập nhật fuel, mileage, health và runtime state của vehicle đang active.
forward PlayerVehicle_RuntimeTick();
```

---

# 10. Quy tắc đặt tên

## 10.1. Function

Dùng:

```text
System_Action
```

Ví dụ:

```pawn
Vehicle_GetFuel
Vehicle_SetFuel
VehicleRuntime_Register
PlayerVehicle_SaveState
FactionVehicle_Load
PizzaVehicle_CreateRental
```

Không dùng tên mơ hồ:

```pawn
DoVehicle
HandleData
UpdateThing
Func1
```

---

## 10.2. Enum field

Dùng prefix theo system.

Ví dụ:

```text
pv = Player Vehicle
fv = Faction Vehicle
famv = Family Vehicle
jv = Job Vehicle
vr = Vehicle Runtime
```

Ví dụ:

```pawn
pvFuel
pvMileage
fvFuel
vrSourceID
vrSourceSlot
```

---

## 10.3. Boolean

Tên phải thể hiện trạng thái.

Ví dụ:

```pawn
bool:pvLocked
bool:pvEngine
bool:pvTrunk
bool:vrExists
```

Tránh:

```pawn
bool:status
bool:value
bool:check
```

---

# 11. Module ownership

Một module chỉ nên trực tiếp thay đổi data mà nó sở hữu.

Ví dụ:

`PlayerVehicle` sở hữu:

```text
PlayerVehicle[playerid][slot]
```

`FactionVehicle` sở hữu:

```text
FactionVehicle[factionid][slot]
```

Vehicle Core không được tự ý truy cập mọi field từ mọi module nếu có thể dùng API.

Ưu tiên:

```pawn
Vehicle_GetFuel(vehicleid);
```

thay vì:

```pawn
PlayerVehicle[playerid][slot][pvFuel];
```

ở các system bên ngoài Player Vehicle.

---

# 12. Vehicle Architecture

Vehicle được chia thành hai lớp:

```text
PERSISTENT DATA
      │
      ▼
RUNTIME VEHICLE
```

Persistent data trả lời:

> Vehicle này là vehicle gì?

Runtime data trả lời:

> Vehicle đang tồn tại trong game này lấy dữ liệu từ đâu?

---

# 13. E_RUNTIME_VEHICLE_DATA

Runtime Vehicle là registry chung của mọi vehicle được spawn.

Các loại dự kiến:

```pawn
enum E_RUNTIME_VEHICLE_TYPE
{
    VEHICLE_TYPE_NONE,
    VEHICLE_TYPE_PLAYER,
    VEHICLE_TYPE_JOB,
    VEHICLE_TYPE_FACTION,
    VEHICLE_TYPE_FAMILY,
    VEHICLE_TYPE_ADMIN
};
```

Runtime không được duplicate toàn bộ persistent data.

Nó chỉ giữ reference cần thiết.

Ví dụ:

```pawn
// Reference chung của một vehicle đang tồn tại trong server.
enum E_RUNTIME_VEHICLE_DATA
{
    // Runtime slot này có đang được sử dụng hay không.
    bool:vrExists,

    // Vehicle thuộc Player / Job / Faction / Family / Admin.
    E_RUNTIME_VEHICLE_TYPE:vrType,

    // ID của data source.
    //
    // PLAYER  = character_id.
    // JOB     = job_id hoặc rental session source.
    // FACTION = faction_id.
    // FAMILY  = family_id.
    vrSourceID,

    // Slot vehicle bên trong data source.
    vrSourceSlot,

    // Database vehicle ID nếu loại vehicle có persistent record.
    // Có thể bằng 0 đối với temporary vehicle.
    vrDatabaseID
};
```

---

# 14. Player Vehicle

Player Vehicle persistent data nằm trong:

```pawn
PlayerVehicle[playerid][slot][E_PLAYER_VEHICLE_DATA]
```

Runtime vehicle không được thay thế Player Vehicle data.

Khi spawn:

```text
PlayerVehicle[playerid][slot]
        │
        ▼
CreateVehicle()
        │
        ▼
vehicleid
        │
        ▼
VehicleRuntime[vehicleid]

vrType       = VEHICLE_TYPE_PLAYER
vrSourceID   = character_id
vrSourceSlot = slot
vrDatabaseID = player_vehicles.vehicle_id
```

---

# 15. Runtime source ID không dùng playerid làm identity

Không dùng:

```text
vrSourceID = playerid
```

cho Player Vehicle.

Phải dùng:

```text
vrSourceID = character_id
```

Lý do:

`playerid` chỉ tồn tại trong session.

Player disconnect thì playerid có thể được người khác sử dụng lại.

`character_id` mới là identity persistent.

---

# 16. Shared Vehicle API

System bên ngoài không nên tự check:

```pawn
if (vehicle player)
else if (vehicle faction)
else if (vehicle job)
```

ở mọi nơi.

Tạo API chung.

Ví dụ:

```pawn
// Trả về lượng fuel của vehicle bất kể vehicle thuộc system nào.
Float:Vehicle_GetFuel(vehicleid);
```

```pawn
// Cập nhật fuel vào đúng data source của runtime vehicle.
Vehicle_SetFuel(vehicleid, Float:amount);
```

Sau này:

```pawn
switch (VehicleRuntime[vehicleid][vrType])
{
    case VEHICLE_TYPE_PLAYER:
    {
        ...
    }

    case VEHICLE_TYPE_JOB:
    {
        ...
    }

    case VEHICLE_TYPE_FACTION:
    {
        ...
    }

    case VEHICLE_TYPE_FAMILY:
    {
        ...
    }
}
```

Switch này nằm trong Vehicle Core/API.

Không duplicate switch ở nhiều system.

---

# 17. Player Vehicle Database

Hiện tại giữ bảng:

```text
player_vehicles
```

Không migration DB chỉ vì refactor code.

Player Vehicle persistent fields gồm các nhóm:

### Identity

```text
vehicle_id
owner_character_id
model_id
plate
```

### Appearance

```text
color_1
color_2
```

### Parking

```text
park_x
park_y
park_z
park_a
interior_id
virtual_world
```

### Vehicle state

```text
health
fuel_liters
mileage_km
is_locked
storage_state
```

### Damage

```text
panels_damage
doors_damage
lights_damage
tyres_damage
```

---

# 18. Job Vehicle

Job rental vehicle phải sử dụng Vehicle Runtime chung.

Ví dụ Pizza:

```text
VEHICLE_TYPE_JOB
```

Job vehicle có thể là temporary.

Không bắt buộc phải có database vehicle ID.

Ví dụ runtime:

```text
vrType       = VEHICLE_TYPE_JOB
vrSourceID   = JOB_PIZZA
vrSourceSlot = rental slot/session
vrDatabaseID = 0
```

Job system chịu trách nhiệm lifecycle rental:

```text
rent
spawn
assign
return
destroy
disconnect cleanup
```

Vehicle Core chịu trách nhiệm behavior chung.

---

# 19. Faction Vehicle

Faction Vehicle persistent data thuộc Faction system.

Runtime:

```text
vrType       = VEHICLE_TYPE_FACTION
vrSourceID   = faction_id
vrSourceSlot = faction vehicle slot
vrDatabaseID = faction vehicle database id
```

Permission không hard-code vào controls.

Phải đi qua permission layer.

---

# 20. Family Vehicle

Family Vehicle hoạt động cùng nguyên tắc với Faction Vehicle.

Runtime:

```text
vrType       = VEHICLE_TYPE_FAMILY
vrSourceID   = family_id
vrSourceSlot = family vehicle slot
```

Không duplicate Vehicle Core.

---

# 21. Vehicle Permission Layer

Các action dự kiến:

```text
DRIVE
ENGINE
LIGHTS
WINDOWS
LOCK
TRUNK
HOOD
PARK
STORE
GIVE_KEY
RESPAWN
CONFIG
```

Cuối cùng nên có API dạng:

```pawn
// Kiểm tra player có quyền thực hiện action trên vehicle hay không.
bool:Vehicle_HasPermission(playerid, vehicleid, E_VEHICLE_PERMISSION:permission);
```

`/car` chỉ gọi permission API.

Không tự viết ownership logic riêng bên trong command.

---

# 22. `/car` Architecture

`/car` là interface điều khiển Vehicle Core.

Các subcommand:

```text
/car engine
/car stats
/car lights
/car windows
/car lock
/car hood
/car trunk
```

Controls không được trở thành nơi lưu persistent ownership logic.

Controls chỉ:

1. tìm vehicle;
2. check permission;
3. gọi Vehicle Core;
4. gửi message.

---

# 23. Message Style

System message ưu tiên:

```text
White
Light Gray
Dark Gray
Dark Navy
Burgundy Red
```

Palette:

```text
White       #FFFFFF
Light Gray  #BFC0C2
Dark Gray   #858585
Dark Navy   #264A73
Burgundy    #7A2929
```

Nguyên tắc:

- Trắng/xám: nội dung hệ thống.
- Navy: player name, vehicle, ID, command, tiền hoặc value quan trọng.
- Burgundy: warning/error.
- Không lạm dụng màu neon.
- Không spam `[SUCCESS]`, `[ERROR]` nếu câu chữ tự giải thích được.
- Roleplay chat giữ màu riêng.

---

# 24. Client Message và Notify

Thông báo gameplay/system dài nên ưu tiên:

```pawn
SendClientMessage
```

`ShowNotifyText` chỉ dùng khi notification ngắn thực sự phù hợp UI.

Không dùng color tag embedded trong TextDraw nếu renderer không hỗ trợ ổn định.

---

# 25. Error handling

Function phải fail an toàn.

Ví dụ:

```pawn
// Không thao tác với runtime vehicle không hợp lệ.
if (!IsValidVehicle(vehicleid))
{
    return 0;
}
```

Không tiếp tục chạy với:

```text
INVALID_PLAYER_ID
INVALID_VEHICLE_ID
INVALID_CHARACTER_ID
invalid slot
invalid database id
```

---

# 26. Không dùng magic number

Sai:

```pawn
if (distance <= 5.0)
```

ở nhiều nơi.

Đúng:

```pawn
#define VEHICLE_INTERACT_DISTANCE (5.0)
```

và:

```pawn
if (distance <= VEHICLE_INTERACT_DISTANCE)
```

---

# 27. Không duplicate logic

Nếu cùng một đoạn logic xuất hiện từ 2–3 nơi trở lên, xem xét tách function.

Ví dụ không nên duplicate:

```text
vehicle validity check
character lookup
fuel clamp
runtime source resolver
permission check
vehicle model name
distance check
```

---

# 28. Không tạo thêm README trong module

Toàn gamemode chỉ sử dụng:

```text
gamemodes/README.md
```

Không tạo:

```text
gamemodes/modules/system/vehicles/README.md
gamemodes/modules/system/job/README.md
gamemodes/modules/system/faction/README.md
```

Nếu một system cần tài liệu kiến trúc:

**cập nhật vào README này.**

---

# 29. Khi thêm system mới phải cập nhật README

Những thay đổi kiến trúc lớn phải cập nhật tài liệu này.

Ví dụ:

- Vehicle architecture.
- Faction architecture.
- Family architecture.
- Inventory architecture.
- Economy.
- Business.
- Property.
- Phone.
- Admin.
- Character.
- Job.
- Database convention.

Không cần ghi từng bugfix nhỏ.

---

# 30. Quy tắc refactor

Không rewrite system lớn một lần nếu system đang hoạt động.

Ưu tiên:

```text
Phase 1
→ tạo data structure mới

Phase 2
→ tạo bridge/API

Phase 3
→ chuyển logic cũ qua API

Phase 4
→ xóa legacy

Phase 5
→ mở rộng system mới
```

Phải giữ compatibility trong quá trình migration nếu có thể.

---

# 31. Include order

Module phải được include theo dependency.

Ví dụ Vehicle:

```text
vehicle data/runtime
        ↓
player/faction/job data
        ↓
vehicle API
        ↓
vehicle controls
```

Không để module được include trước dependency mà nó cần.

---

# 32. Source file header

File system quan trọng nên có header.

Ví dụ:

```pawn
//-----------------------------------------------------------------------------
// Player Vehicle persistence.
//
// Chịu trách nhiệm:
// - load player_vehicles từ database;
// - lưu persistent state;
// - spawn/store personal vehicles;
// - bridge Player Vehicle với Vehicle Runtime.
//-----------------------------------------------------------------------------
```

---

# 33. Section comment

File dài phải chia section.

Ví dụ:

```pawn
//-----------------------------------------------------------------------------
// Data
//-----------------------------------------------------------------------------
```

```pawn
//-----------------------------------------------------------------------------
// Database Persistence
//-----------------------------------------------------------------------------
```

```pawn
//-----------------------------------------------------------------------------
// Runtime
//-----------------------------------------------------------------------------
```

```pawn
//-----------------------------------------------------------------------------
// Commands
//-----------------------------------------------------------------------------
```

```pawn
//-----------------------------------------------------------------------------
// Hooks
//-----------------------------------------------------------------------------
```

---

# 34. Comment phải giải thích WHY khi cần

Không viết comment vô nghĩa.

Sai:

```pawn
// Set fuel.
fuel = 100.0;
```

Tốt hơn:

```pawn
// Vehicle mới được tạo test với bình xăng đầy để không phụ thuộc fuel station.
fuel = VEHICLE_MAX_FUEL;
```

Comment cần giúp người sau hiểu:

- tại sao code tồn tại;
- data này đại diện cho gì;
- ai sở hữu state;
- điều kiện đặc biệt nào đang được xử lý.

---

# 35. Không comment từng dòng vô nghĩa

Không cần:

```pawn
// Tạo biến.
new vehicleid;

// Lấy vehicle ID.
vehicleid = GetPlayerVehicleID(playerid);

// Return 1.
return 1;
```

Comment phải có giá trị.

---

# 36. Quy chuẩn function mới

Trước khi thêm function mới, phải xác định:

```text
System nào sở hữu function?
Function có thay đổi persistent data không?
Function có thay đổi runtime state không?
Function có cần save DB không?
Function có thể dùng chung không?
Function có permission requirement không?
```

Tên và comment phải phản ánh đúng câu trả lời.

---

# 37. Quy chuẩn variable mới

Trước khi thêm variable:

```text
Variable thuộc persistent hay runtime?
Ai sở hữu variable?
Lifetime của variable?
Có thể derive từ data khác không?
Có đang duplicate data không?
```

Không thêm cache nếu không cần thiết.

Nếu cache, comment phải ghi rõ đó là cache.

---

# 38. Quy chuẩn state

Không dùng integer không giải thích.

Sai:

```pawn
state = 2;
```

Đúng:

```pawn
state = PLAYER_VEHICLE_IMPOUNDED;
```

State phải dùng define hoặc enum có tên.

---

# 39. Quy chuẩn temporary vehicle

Temporary vehicle phải ghi rõ lifecycle.

Ví dụ:

```text
Admin temporary vehicle
Job rental vehicle
Event vehicle
Test vehicle
```

Phải xác định rõ:

```text
Ai tạo?
Ai được dùng?
Khi nào destroy?
Có save DB không?
Disconnect có cleanup không?
Server restart có cần restore không?
```

---

# 40. Quy chuẩn ownership

Không coi runtime playerid là ownership persistent.

Player ownership:

```text
character_id
```

Faction ownership:

```text
faction_id
```

Family ownership:

```text
family_id
```

Job source:

```text
job_id / rental session
```

Runtime chỉ reference các identity này.

---

# 41. Quy chuẩn database ID

Luôn phân biệt:

```text
runtime vehicleid
```

và:

```text
database vehicle ID
```

Ví dụ:

```pawn
vehicleid
databaseID
```

Không dùng một tên `id` cho cả hai.

---

# 42. Quy chuẩn save

Không query DB mỗi frame/tick quá ngắn.

Persistent save phải có chiến lược rõ:

```text
on important state change
on store
on park
on disconnect
periodic safe save khi thực sự cần
```

Nếu timer save, phải comment lý do.

---

# 43. Quy chuẩn module API

Module nên expose function có nghĩa.

Ví dụ:

```pawn
PlayerVehicle_GetFuelBySource
PlayerVehicle_SetFuelBySource
VehicleRuntime_Register
VehicleRuntime_Reset
Vehicle_GetFuel
Vehicle_SetFuel
```

Không expose toàn bộ internal implementation nếu không cần.

---

# 44. Quy chuẩn legacy code

Legacy code chưa migrate phải được đánh dấu.

Ví dụ:

```pawn
// LEGACY:
// Tạm giữ trong Phase 1 để /vehicles vẫn hoạt động.
// Sẽ chuyển sang Vehicle Permission API ở Phase 3.
```

Không để người sau tưởng đó là kiến trúc cuối.

---

# 45. Checklist trước khi hoàn thành feature

Trước khi coi feature hoàn tất, kiểm tra:

- [ ] Function mới có comment.
- [ ] Variable quan trọng có comment.
- [ ] Enum/define mới có giải thích.
- [ ] Không dùng magic number không cần thiết.
- [ ] Không duplicate logic đáng kể.
- [ ] Runtime và persistent data không bị trộn.
- [ ] Ownership dùng đúng persistent identity.
- [ ] Có invalid ID/slot checks.
- [ ] Database query có mục đích rõ.
- [ ] Timer/callback mới có comment.
- [ ] Command có permission check nếu cần.
- [ ] Module đúng ownership boundary.
- [ ] README này được cập nhật nếu có thay đổi kiến trúc.
- [ ] Compile không error.
- [ ] Test path chính và error path.

---

# 46. Quy tắc bắt buộc cho mọi code từ thời điểm này

**Từ thời điểm áp dụng README này:**

> Bất kỳ function, feature, variable quan trọng, enum, define, callback,
> timer hoặc state mới nào được thêm vào gamemode đều phải có `//`
> giải thích rõ nó dùng để làm gì.

Code không có comment theo chuẩn này được coi là **chưa hoàn thiện**.

Mục tiêu không phải để source có thật nhiều comment.

Mục tiêu là:

> Mở một file bất kỳ sau vài tháng vẫn hiểu system đang làm gì,
> data thuộc về đâu, và tại sao đoạn code đó tồn tại.

---

# 47. Nguyên tắc cuối cùng

```text
Readable > Clever
Explicit > Implicit
Shared API > Duplicate Logic
Persistent Identity > Runtime ID
Small Safe Refactor > Big Rewrite
Documented Code > Mystery Code
```

**Gamemode phải được viết để người khác có thể tiếp tục phát triển,
không chỉ để compiler hiểu.**
