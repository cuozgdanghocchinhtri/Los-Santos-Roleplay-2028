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
    format(
        body,
        sizeof(body),
        "{C62828}WELL STACKED PIZZA CO. - PHONG NHAN SU\n\n\
{FFFFFF}Vi tri tuyen dung: {FFD54F}Nhan vien giao banh Pizza Boy\n\
{FFFFFF}Loai hop dong: {E0E0E0}Nhan vien thoi vu, huong luong theo ngay\n\
{FFFFFF}Dia diem lam viec: {E0E0E0}Chi nhanh Idlewood, Los Santos\n\n\
{C62828}MO TA CONG VIEC\n\
{FFFFFF}- Tiep nhan, bao quan va giao pizza den dung dia chi khach hang.\n\
- Su dung Pizzaboy cua cong ty theo dung hop dong thue xe.\n\
- Chiu trach nhiem voi so banh da nhan va tinh trang phuong tien.\n\
- Hoan tra xe tai bai tap ket sau khi ket thuc ca.\n\n\
{C62828}QUYEN LOI DU KIEN\n\
{FFFFFF}- Luong co ban theo ngay: {66BB6A}$%d\n\
{FFFFFF}- Phu cap an ca: {66BB6A}$%d/ngay\n\
{FFFFFF}- Phu cap xang xe: {66BB6A}$%d/ngay\n\
{FFFFFF}- Thuong KPI toi da: {66BB6A}$%d/ngay\n\
{BDBDBD}(Khoan luong ngay/phu cap se duoc chi tra khi he thong Payday hoat dong.)\n\n\
{C62828}CAM KET NHAN VIEN\n\
{FFFFFF}Bang viec nop ho so, ban dong y tuan thu quy trinh giao nhan,\n\
khong su dung xe cong ty vao muc dich ca nhan va hoan tra tai san khi nghi ca.\n\n\
Nhan \"Nop ho so\" de xac nhan ung tuyen.",
        PIZZA_DAILY_SALARY,
        PIZZA_DAILY_FOOD_ALLOWANCE,
        PIZZA_DAILY_TRANSPORT_ALLOWANCE,
        PIZZA_MAX_KPI_BONUS
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_APPLICATION,
        DIALOG_STYLE_MSGBOX,
        "Pizza Stack - Ho so xin viec",
        body,
        "Nop ho so",
        "Dong"
    );
    return 1;
}

stock Pizza_ShowEmployeeMenu(playerid)
{
    new body[512];
    format(
        body,
        sizeof(body),
        "Muc\tTrang thai\n\
Ho so nhan vien\tXem thong tin hop dong\n\
Thue xe Pizzaboy\t%s\n\
Huong dan cong viec\tQuy trinh giao banh\n\
Xin nghi viec\tCham dut hop dong",
        Pizza_HasRentalVehicle(playerid) ? "Dang co xe thue" : "San sang"
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_EMPLOYEE_MENU,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Pizza Stack - Cong thong tin nhan vien",
        body,
        "Chon",
        "Dong"
    );
    return 1;
}

stock Pizza_ShowEmployeeProfile(playerid)
{
    new
        body[2048],
        hireDate[MAX_JOB_HIRE_DATE_LENGTH],
        rankName[32],
        vehicleStatus[64],
        deliveryStatus[64];

    Job_GetHiredAt(playerid, JOB_PIZZA, hireDate, sizeof(hireDate));

    new const level = Job_GetLevel(playerid, JOB_PIZZA);
    new const nextXP = Job_GetNextLevelExperience(level);
    Pizza_GetRankName(level, rankName, sizeof(rankName));

    if (Pizza_HasRentalVehicle(playerid))
    {
        format(
            vehicleStatus,
            sizeof(vehicleStatus),
            "Pizzaboy #%d - Hang %d/%d",
            Pizza_GetRentalVehicle(playerid),
            s_PizzaVehicleCargo[playerid],
            PIZZA_MAX_CARGO
        );
    }
    else
    {
        format(vehicleStatus, sizeof(vehicleStatus), "Chua thue xe");
    }

    if (s_PizzaDeliveryPoint[playerid] >= 0)
    {
        format(
            deliveryStatus,
            sizeof(deliveryStatus),
            "Dang giao tai %s",
            g_PizzaDeliveryPoints[
                s_PizzaDeliveryPoint[playerid]
            ][PIZZA_DELIVERY_ZONE]
        );
    }
    else
    {
        format(deliveryStatus, sizeof(deliveryStatus), "Khong co don dang giao");
    }

    format(
        body,
        sizeof(body),
        "{C62828}THONG TIN NHAN VIEN\n\n\
{FFFFFF}Ma nhan vien: {FFD54F}PZ-%06d\n\
{FFFFFF}Ten nhan vien: {FFD54F}%s\n\
{FFFFFF}Chi nhanh: {E0E0E0}Pizza Stack Idlewood\n\
{FFFFFF}Chuc danh: {E0E0E0}%s\n\
{FFFFFF}Ngay nhan viec: {E0E0E0}%s\n\
{FFFFFF}Tinh trang hop dong: {66BB6A}Dang lam viec\n\
{FFFFFF}Trang thai ho so: {66BB6A}Hop le\n\n\
{C62828}LUONG VA PHUC LOI DU KIEN\n\n\
{FFFFFF}Luong co ban: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap an ca: {66BB6A}$%d/ngay\n\
{FFFFFF}Phu cap xang xe: {66BB6A}$%d/ngay\n\
{FFFFFF}Tong phu cap: {66BB6A}$%d/ngay\n\
{FFFFFF}Thuong KPI toi da: {66BB6A}$%d/ngay\n\
{FFFFFF}Ky tra luong: {FFB74D}Cho he thong Payday\n\n\
{C62828}NANG LUC VA HIEU SUAT\n\n\
{FFFFFF}Cap nghe: {FFD54F}%d/%d\n\
{FFFFFF}Kinh nghiem: {FFD54F}%d%s\n\
{FFFFFF}So chuyen hoan thanh: {E0E0E0}%d\n\
{FFFFFF}So banh da giao: {E0E0E0}%d\n\
{FFFFFF}Streak tot nhat: {E0E0E0}%d\n\
{FFFFFF}Tong thu nhap hoa hong: {66BB6A}$%d\n\n\
{C62828}CA LAM HIEN TAI\n\n\
{FFFFFF}Phuong tien: {E0E0E0}%s\n\
{FFFFFF}Don hang: {E0E0E0}%s",
        GetPlayerCharacterID(playerid),
        s_CharacterName[playerid],
        rankName,
        hireDate,
        Job_GetDailySalary(playerid, JOB_PIZZA),
        PIZZA_DAILY_FOOD_ALLOWANCE,
        PIZZA_DAILY_TRANSPORT_ALLOWANCE,
        Job_GetDailyAllowance(playerid, JOB_PIZZA),
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

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_PROFILE,
        DIALOG_STYLE_MSGBOX,
        "Pizza Stack - Ho so nhan vien",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock Pizza_ShowGuide(playerid)
{
    new const body[] =
        "{C62828}QUY TRINH GIAO BANH PIZZA STACK\n\n\
{FFFFFF}1. Gap quan ly tuyen dung va mo Cong thong tin nhan vien.\n\
2. Chon \"Thue xe Pizzaboy\"; ban se duoc dua thang vao xe cua minh.\n\
3. Lai xe toi pickup Lay banh, xuong xe va nhan {FFD54F}Y{FFFFFF}.\n\
4. Khi dang cam hop pizza, dung gan Pizzaboy va nhan {FFD54F}Y{FFFFFF} de chat len xe.\n\
5. Xe cho toi da {FFD54F}5/5{FFFFFF} hop. Chi can co it nhat mot hop la co the giao.\n\
6. Dung lenh {FFD54F}/giaobanh{FFFFFF} de nhan ngau nhien mot dia chi khach hang.\n\
7. Tai diem giao, do xe gan nha va nhan {FFD54F}Y{FFFFFF} gan xe de lay mot hop.\n\
8. Cam hop den cua nha/checkpoint va nhan {FFD54F}Y{FFFFFF} de ban giao.\n\
9. Khi xe het banh, dua Pizzaboy ve pickup Tra xe va nhan {FFD54F}Y{FFFFFF}.\n\n\
{FFB74D}LUU Y AN TOAN DU LIEU\n\
{FFFFFF}- Moi xe chi co mot owner; nguoi khac khong the su dung.\n\
- Banh chi bi tru kho sau khi giao thanh cong.\n\
- Thoat game, chet, huy ca hoac xe no se thu hoi xe va xoa hang tam.\n\
- Khong vao xe khi dang cam hop; hay chat/cat hop bang phim Y.";

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_GUIDE,
        DIALOG_STYLE_MSGBOX,
        "Pizza Stack - So tay nhan vien",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock Pizza_ShowRentConfirmation(playerid)
{
    new const body[] =
        "{C62828}HOP DONG THUE PIZZABOY THEO CA\n\n\
{FFFFFF}- Phi thue hien tai: {66BB6A}$0{FFFFFF} (phuong tien cong ty).\n\
- Suc chua: {FFD54F}5 hop pizza{FFFFFF}.\n\
- Xe duoc gan owner theo nhan vat va khong duoc chuyen giao.\n\
- Xe se bi thu hoi khi tra xe, nghi viec, chet, disconnect hoac bi pha huy.\n\
- Toan bo hang tam tren xe se duoc xoa khi ca bi huy.\n\n\
Nhan \"Thue xe\" de bat dau ca lam viec.";

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_RENT,
        DIALOG_STYLE_MSGBOX,
        "Pizza Stack - Hop dong thue xe",
        body,
        "Thue xe",
        "Quay lai"
    );
    return 1;
}

stock Pizza_ShowResignConfirmation(playerid)
{
    new const body[] =
        "{C62828}XAC NHAN CHAM DUT HOP DONG\n\n\
{FFFFFF}Khi xin nghi viec:\n\
- Ca hien tai va xe thue se bi thu hoi ngay lap tuc.\n\
- Banh dang cam/nam tren xe se bi huy.\n\
- Luong va phu cap ngay chua den ky Payday se khong duoc thanh toan.\n\
- Lich su kinh nghiem va thong ke giao hang van duoc luu trong ho so cu.\n\n\
Ban co chac muon cham dut hop dong voi Pizza Stack?";

    ShowPlayerDialog(
        playerid,
        DIALOG_PIZZA_RESIGN,
        DIALOG_STYLE_MSGBOX,
        "Pizza Stack - Xin nghi viec",
        body,
        "Nghi viec",
        "Quay lai"
    );
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    switch (dialogid)
    {
        case DIALOG_PIZZA_APPLICATION:
        {
            if (!response)
            {
                return 1;
            }

            Pizza_HireEmployee(playerid);
            return 1;
        }

        case DIALOG_PIZZA_EMPLOYEE_MENU:
        {
            if (!response)
            {
                return 1;
            }

            switch (listitem)
            {
                case 0: Pizza_ShowEmployeeProfile(playerid);
                case 1: Pizza_ShowRentConfirmation(playerid);
                case 2: Pizza_ShowGuide(playerid);
                case 3: Pizza_ShowResignConfirmation(playerid);
                default: Pizza_ShowEmployeeMenu(playerid);
            }
            return 1;
        }

        case DIALOG_PIZZA_PROFILE,
             DIALOG_PIZZA_GUIDE:
        {
            if (response)
            {
                Pizza_ShowEmployeeMenu(playerid);
            }
            return 1;
        }

        case DIALOG_PIZZA_RENT:
        {
            if (!response)
            {
                Pizza_ShowEmployeeMenu(playerid);
                return 1;
            }

            Pizza_RentVehicle(playerid);
            return 1;
        }

        case DIALOG_PIZZA_RESIGN:
        {
            if (!response)
            {
                Pizza_ShowEmployeeMenu(playerid);
                return 1;
            }

            Pizza_ResignEmployee(playerid);
            return 1;
        }
    }
    return 0;
}

