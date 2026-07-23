//-----------------------------------------------------------------------------
// Pizza job - recruitment and employee dialogs
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

stock Pizza_GetRankName(level, destination[], size)
{
    switch (level)
    {
        case 1: format(destination, size, "Nhan vien thu viec");
        case 2: format(destination, size, "Nhan vien giao hang");
        case 3: format(destination, size, "Nhan vien chinh thuc");
        case 4: format(destination, size, "Nhan vien cao cap");
        default: format(destination, size, "To truong giao van");
    }
    return 1;
}

stock Pizza_ShowApplication(playerid)
{
    new body[2048];

    format(body, sizeof(body),
        "{C62828}WELL STACKED PIZZA CO. - PHONG NHAN SU\n\n\
{FFFFFF}Vi tri tuyen dung: {FFD54F}Nhan vien giao banh - Pizza Boy\n\
{FFFFFF}Hinh thuc: {E0E0E0}Nhan vien theo ca, ho so luu theo nhan vat\n\
{FFFFFF}Chi nhanh: {E0E0E0}Idlewood, Los Santos\n\n\
{C62828}MO TA CONG VIEC\n\
{FFFFFF}- Tiep nhan pizza tai khu giao nhan cua chi nhanh.\n\
- Bao quan hang hoa va giao dung dia chi khach hang.\n\
- Su dung Pizzaboy cua cong ty trong pham vi cong viec.\n\
- Kiem tra so luong banh truoc va sau moi don giao.\n\
- Hoan tra phuong tien tai bai xe khi ket thuc ca.\n\n\
{C62828}CHE DO NHAN VIEN\n\
{FFFFFF}Luong co ban: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap an ca: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap di lai: {66BB6A}$%d/ngay\n\
{FFFFFF}Thuong KPI toi da: {66BB6A}$%d/ngay\n\
{BDBDBD}Luong ngay va phu cap se duoc ket noi vao Payday sau.\n\n\
{C62828}YEU CAU VA CAM KET\n\
{FFFFFF}- Tuan thu quy trinh giao nhan va quy dinh an toan.\n\
- Khong chuyen giao xe cong ty cho nguoi khac.\n\
- Chiu trach nhiem voi hang hoa dang mang theo.\n\
- Dong y de he thong thu hoi xe/hang tam khi chet, thoat game hoac xe bi pha huy.\n\n\
Nhan \"Nop ho so\" de gui ho so den bo phan nhan su.",
        PIZZA_DAILY_SALARY,
        PIZZA_DAILY_FOOD_ALLOWANCE,
        PIZZA_DAILY_TRANSPORT_ALLOWANCE,
        PIZZA_MAX_KPI_BONUS
    );

    ShowPlayerDialog(playerid, PIZZA_DIALOG_APPLICATION, DIALOG_STYLE_MSGBOX, "Pizza Stack - Ho so xin viec", body, "Nop ho so", "Dong");
    return 1;
}

stock Pizza_ShowEmployeeMenu(playerid)
{
    new body[512];
    format(body, sizeof(body),
        "Muc\tTrang thai\n\
Ho so nhan vien\tThong tin hop dong\n\
Thue xe Pizzaboy\t%s\n\
Huong dan cong viec\tQuy trinh giao banh\n\
Xin nghi viec\tCham dut hop dong",
        Pizza_HasRentalVehicle(playerid) ? "Dang co xe thue" : "San sang"
    );

    ShowPlayerDialog(playerid, PIZZA_DIALOG_EMPLOYEE_MENU, DIALOG_STYLE_TABLIST_HEADERS, "Pizza Stack - Cong thong tin nhan vien", body, "Chon", "Dong");
    return 1;
}

stock Pizza_ShowEmployeeProfile(playerid)
{
    new body[2048], rankName[32], vehicleStatus[64], deliveryStatus[64];
    new const level = Job_GetLevel(playerid, JOB_PIZZA);
    new const nextXP = Job_GetNextLevelExperience(level);

    Pizza_GetRankName(level, rankName, sizeof(rankName));

    if (Pizza_HasRentalVehicle(playerid))
        format(vehicleStatus, sizeof(vehicleStatus), "Pizzaboy #%d - Hang %d/%d", Pizza_GetRentalVehicle(playerid), s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);
    else
        format(vehicleStatus, sizeof(vehicleStatus), "Chua thue xe");

    if (s_PizzaDeliveryPoint[playerid] >= 0)
        format(deliveryStatus, sizeof(deliveryStatus), "Dang giao tai %s", g_PizzaDeliveryPoints[s_PizzaDeliveryPoint[playerid]][PIZZA_DELIVERY_ZONE]);
    else
        format(deliveryStatus, sizeof(deliveryStatus), "Khong co don dang giao");

    format(body, sizeof(body),
        "{C62828}HO SO NHAN VIEN - PIZZA STACK\n\n\
{FFFFFF}Ma nhan vien: {FFD54F}PZ-%06d\n\
{FFFFFF}Ten nhan vien: {FFD54F}%s\n\
{FFFFFF}Chi nhanh: {E0E0E0}Idlewood, Los Santos\n\
{FFFFFF}Chuc danh: {E0E0E0}%s\n\
{FFFFFF}Ngay nhan viec: {E0E0E0}%s\n\
{FFFFFF}Tinh trang hop dong: {66BB6A}Dang lam viec\n\
{FFFFFF}Trang thai ho so: {66BB6A}Hop le\n\n\
{C62828}LUONG - PHU CAP - PHUC LOI\n\
{FFFFFF}Luong co ban: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap an ca: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap di lai: {66BB6A}$%d/ngay\n\
{FFFFFF}Tong phu cap: {66BB6A}$%d/ngay\n\
{FFFFFF}Thuong KPI toi da: {66BB6A}$%d/ngay\n\
{FFFFFF}Ky thanh toan: {FFB74D}Cho he thong Payday\n\n\
{C62828}NANG LUC VA HIEU SUAT\n\
{FFFFFF}Cap nghe: {FFD54F}%d/%d\n\
{FFFFFF}Kinh nghiem: {FFD54F}%d%s\n\
{FFFFFF}Chuyen hoan thanh: {E0E0E0}%d\n\
{FFFFFF}Banh da giao: {E0E0E0}%d\n\
{FFFFFF}Streak tot nhat: {E0E0E0}%d\n\
{FFFFFF}Tong thu nhap nghe: {66BB6A}$%d\n\n\
{C62828}CA LAM HIEN TAI\n\
{FFFFFF}Phuong tien: {E0E0E0}%s\n\
{FFFFFF}Don hang: {E0E0E0}%s",
        GetPlayerCharacterID(playerid),
        s_CharacterName[playerid],
        rankName,
        pJobHiredAt[playerid][0] ? pJobHiredAt[playerid] : "Chua co",
        pJobSalary[playerid],
        PIZZA_DAILY_FOOD_ALLOWANCE,
        PIZZA_DAILY_TRANSPORT_ALLOWANCE,
        pJobAllowance[playerid],
        PIZZA_MAX_KPI_BONUS,
        level,
        MAX_JOB_LEVEL,
        s_PlayerJobExperience[playerid][JOB_PIZZA],
        nextXP > 0 ? "" : " (toi da)",
        s_PlayerJobCompletedRuns[playerid][JOB_PIZZA],
        s_PlayerJobCompletedTasks[playerid][JOB_PIZZA],
        s_PlayerJobBestStreak[playerid][JOB_PIZZA],
        s_PlayerJobTotalEarnings[playerid][JOB_PIZZA],
        vehicleStatus,
        deliveryStatus
    );

    ShowPlayerDialog(playerid, PIZZA_DIALOG_PROFILE, DIALOG_STYLE_MSGBOX, "Pizza Stack - Ho so nhan vien", body, "Quay lai", "Dong");
    return 1;
}

stock Pizza_ShowGuide(playerid)
{
    new const body[] =
        "{C62828}SO TAY NHAN VIEN PIZZA STACK\n\n\
{FFFFFF}1. Gap quan ly tuyen dung va nhan {FFD54F}Y{FFFFFF}.\n\
2. Trong Cong thong tin nhan vien, chon \"Thue xe Pizzaboy\".\n\
3. Ban se duoc dua thang vao xe thue cua minh.\n\
4. Lai den khu Lay banh, xuong xe va nhan {FFD54F}Y{FFFFFF}.\n\
5. Khi dang cam hop pizza, den gan Pizzaboy va nhan {FFD54F}Y{FFFFFF} de chat len xe.\n\
6. Pizzaboy chua toi da {FFD54F}5/5{FFFFFF} hop.\n\
7. Co tu 1 hop tro len, dung {FFD54F}/giaobanh{FFFFFF} de nhan dia chi ngau nhien.\n\
8. Den gan dia chi, xuong xe, den gan Pizzaboy va nhan {FFD54F}Y{FFFFFF} de lay hop giao.\n\
9. Mang hop toi checkpoint va nhan {FFD54F}Y{FFFFFF} de giao.\n\
10. Khi het hang, quay ve lay them hoac dua xe den khu Tra xe va nhan {FFD54F}Y{FFFFFF}.\n\n\
{FFB74D}AN TOAN DU LIEU\n\
{FFFFFF}- Moi xe thue gan owner va token rieng.\n\
- Nguoi khac khong the su dung xe cua ban.\n\
- Banh chi bi tru kho khi giao thanh cong.\n\
- Chet, disconnect, xe no hoac dung ca se thu hoi xe va xoa hang tam.";

    ShowPlayerDialog(playerid, PIZZA_DIALOG_GUIDE, DIALOG_STYLE_MSGBOX, "Pizza Stack - Huong dan cong viec", body, "Quay lai", "Dong");
    return 1;
}

stock Pizza_ShowRentConfirmation(playerid)
{
    new const body[] =
        "{C62828}HOP DONG THUE PIZZABOY THEO CA\n\n\
{FFFFFF}Phi thue hien tai: {66BB6A}$0\n\
{FFFFFF}Suc chua: {FFD54F}5 hop pizza\n\
{FFFFFF}Phuong tien: {E0E0E0}Pizzaboy cua cong ty\n\n\
{FFFFFF}- Xe duoc gan rieng cho nhan vien thue.\n\
- Khong duoc giao xe cho nguoi khac.\n\
- Xe bi thu hoi khi ket thuc ca, chet, disconnect hoac bi pha huy.\n\
- Hang tren xe la du lieu tam cua ca lam viec.\n\n\
Nhan \"Thue xe\" de bat dau ca.";

    ShowPlayerDialog(playerid, PIZZA_DIALOG_RENT, DIALOG_STYLE_MSGBOX, "Pizza Stack - Hop dong thue xe", body, "Thue xe", "Quay lai");
    return 1;
}

stock Pizza_ShowResignConfirmation(playerid)
{
    new const body[] =
        "{C62828}XAC NHAN XIN NGHI VIEC\n\n\
{FFFFFF}Khi cham dut hop dong:\n\
- Ca hien tai se ket thuc.\n\
- Pizzaboy dang thue se bi thu hoi.\n\
- Banh dang cam va hang tam tren xe se bi xoa.\n\
- Lich su XP, so chuyen va thu nhap nghe van duoc giu lai.\n\
- Luong/phu cap Payday chua den ky se khong duoc xu ly o phien ban hien tai.\n\n\
Ban co chac muon nghi viec tai Pizza Stack?";

    ShowPlayerDialog(playerid, PIZZA_DIALOG_RESIGN, DIALOG_STYLE_MSGBOX, "Pizza Stack - Xin nghi viec", body, "Nghi viec", "Quay lai");
    return 1;
}

stock Pizza_HireEmployee(playerid)
{
    if (!pJobLoaded[playerid])
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ho so cong viec dang duoc tai. Hay thu lai sau giay lat.", 4000);
        return 0;
    }

    if (pJob[playerid] != JOB_NONE)
    {
        if (pJob[playerid] == JOB_PIZZA)
        {
            return Pizza_ShowEmployeeMenu(playerid);
        }

        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Nhan vat dang co mot cong viec khac. Hay nghi viec truoc.", 4500);
        return 0;
    }

    new year, month, day, hour, minute, second;
    getdate(year, month, day);
    gettime(hour, minute, second);

    pJob[playerid] = JOB_PIZZA;
    pJobSalary[playerid] = PIZZA_DAILY_SALARY;
    pJobAllowance[playerid] = PIZZA_DAILY_ALLOWANCE_TOTAL;
    format(pJobHiredAt[playerid], sizeof(pJobHiredAt[]), "%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second);

    new query[512];
    mysql_format(g_DatabaseHandle, query, sizeof(query), "UPDATE `player_characters` SET `job`=%d,`job_hired_at`=CURRENT_TIMESTAMP,`job_salary`=%d,`job_allowance`=%d WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;", JOB_PIZZA, PIZZA_DAILY_SALARY, PIZZA_DAILY_ALLOWANCE_TOTAL, GetPlayerCharacterID(playerid), GetPlayerAccountID(playerid));
    mysql_tquery(g_DatabaseHandle, query);

    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ho so da duoc duyet. Chao mung ban gia nhap Pizza Stack.", 5500);
    Pizza_ShowEmployeeProfile(playerid);
    return 1;
}

stock Pizza_ResignEmployee(playerid)
{
    if (!Pizza_IsEmployee(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban khong co hop dong lao dong voi Pizza Stack.", 4000);
        return 0;
    }

    if (Job_IsActive(playerid, JOB_PIZZA))
    {
        Job_Stop(playerid, JOB_STOP_QUIT);
    }
    else if (Pizza_HasRentalVehicle(playerid))
    {
        Pizza_DestroyRentalVehicle(playerid);
    }

    pJob[playerid] = JOB_NONE;
    pJobHiredAt[playerid][0] = 0;
    pJobSalary[playerid] = 0;
    pJobAllowance[playerid] = 0;

    new query[384];
    mysql_format(g_DatabaseHandle, query, sizeof(query), "UPDATE `player_characters` SET `job`=0,`job_hired_at`=NULL,`job_salary`=0,`job_allowance`=0 WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;", GetPlayerCharacterID(playerid), GetPlayerAccountID(playerid));
    mysql_tquery(g_DatabaseHandle, query);

    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hop dong Pizza Stack da duoc cham dut. Thanh tich nghe cu van duoc luu.", 5000);
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    switch (dialogid)
    {
        case PIZZA_DIALOG_APPLICATION:
        {
            if (response) Pizza_HireEmployee(playerid);
            return 1;
        }

        case PIZZA_DIALOG_EMPLOYEE_MENU:
        {
            if (!response) return 1;

            switch (listitem)
            {
                case 0: Pizza_ShowEmployeeProfile(playerid);
                case 1: Pizza_ShowRentConfirmation(playerid);
                case 2: Pizza_ShowGuide(playerid);
                case 3: Pizza_ShowResignConfirmation(playerid);
            }
            return 1;
        }

        case PIZZA_DIALOG_PROFILE, PIZZA_DIALOG_GUIDE:
        {
            if (response) Pizza_ShowEmployeeMenu(playerid);
            return 1;
        }

        case PIZZA_DIALOG_RENT:
        {
            if (response) Pizza_RentVehicle(playerid);
            else Pizza_ShowEmployeeMenu(playerid);
            return 1;
        }

        case PIZZA_DIALOG_RESIGN:
        {
            if (response) Pizza_ResignEmployee(playerid);
            else Pizza_ShowEmployeeMenu(playerid);
            return 1;
        }
    }
    return 0;
}
