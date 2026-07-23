#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Owned vehicle TABLIST_HEADERS dialogs
//-----------------------------------------------------------------------------

forward Vehicle_ShowListDeferred(playerid);

public Vehicle_ShowListDeferred(playerid)
{
    if (IsPlayerConnected(playerid) &&
        IsPlayerCharacterLoaded(playerid) &&
        s_OwnedVehiclesLoaded[playerid])
    {
        Vehicle_ShowList(playerid);
    }

    return 1;
}

stock Vehicle_ShowList(playerid)
{
    printf(
        "[VEHICLE DEBUG] ShowList p=%d loaded=%d owner=%d count=%d pending=%d",
        playerid,
        _:s_OwnedVehiclesLoaded[playerid],
        s_OwnedVehicleCharacterID[playerid],
        s_OwnedVehicleCount[playerid],
        _:s_OwnedVehicleShowPending[playerid]
    );

    if (!s_OwnedVehiclesLoaded[playerid])
    {
        if (IsPlayerCharacterLoaded(playerid))
        {
            new const characterID = GetPlayerCharacterID(playerid);

            // If the initial character load has not started yet, start it
            // here.  If it is already in flight, keep the existing query and
            // let its callback open the dialog once the rows are available.
            if (s_OwnedVehicleCharacterID[playerid] != characterID)
            {
                Vehicle_LoadForPlayer(playerid);
            }

            s_OwnedVehicleShowPending[playerid] = true;
        }

        SendClientMessage(playerid, COLOR_RED, "Du lieu xe dang duoc tai. Hay thu lai sau.");
        return 1;
    }

    new body[4096], row[192], filterName[24];
    format(body, sizeof(body), "Xe\tTrang thai\tVi tri\tQuang duong\n");
    Vehicle_GetFilterName(s_OwnedVehicleFilter[playerid], filterName, sizeof(filterName));
    format(
        row,
        sizeof(row),
        "{00008B}[Bo loc]{D9D9D9}\t%s\tChon de thay doi\t-\n",
        filterName
    );
    strcat(body, row, sizeof(body));

    for (new index = 0; index <= MAX_OWNED_VEHICLES; index++)
    {
        s_OwnedVehicleDialogSlots[playerid][index] = INVALID_OWNED_VEHICLE_SLOT;
    }

    new dialogRow = 1;

    // Two passes keep favorite vehicles at the top without sorting runtime data.
    for (new favoritePass = 1; favoritePass >= 0; favoritePass--)
    {
        for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
        {
            if (!Vehicle_IsValidSlot(playerid, slot) ||
                !Vehicle_MatchesFilter(playerid, slot) ||
                _:s_OwnedVehicle[playerid][slot][ov_Favorite] != favoritePass)
            {
                continue;
            }

            new modelName[32], storageName[24], location[40], damageText[20];
            printf(
                "[VEHICLE DEBUG] ShowList slot=%d model=%d favorite=%d",
                slot,
                s_OwnedVehicle[playerid][slot][ov_ModelID],
                _:s_OwnedVehicle[playerid][slot][ov_Favorite]
            );
            Vehicle_GetModelName(
                s_OwnedVehicle[playerid][slot][ov_ModelID],
                modelName,
                sizeof(modelName)
            );
            printf("[VEHICLE DEBUG] ShowList model_name=%s", modelName);
            Vehicle_GetStorageName(
                s_OwnedVehicle[playerid][slot][ov_Storage],
                storageName,
                sizeof(storageName)
            );
            printf("[VEHICLE DEBUG] ShowList storage=%s", storageName);
            Vehicle_GetLocationName(playerid, slot, location, sizeof(location));
            printf("[VEHICLE DEBUG] ShowList location=%s", location);

            if (Vehicle_IsDamaged(playerid, slot))
            {
                format(damageText, sizeof(damageText), " {8B0000}[HU HONG]");
            }
            else
            {
                damageText[0] = 0;
            }
            printf("[VEHICLE DEBUG] ShowList damage=%s", damageText);

            format(
                row,
                sizeof(row),
                "%s{D9D9D9}%s {8B0000}[%s]{D9D9D9}\t{00008B}%s%s{D9D9D9}\t%s\t%.1f km\n",
                s_OwnedVehicle[playerid][slot][ov_Favorite] ? "{8B0000}[YEU THICH] " : "",
                modelName,
                s_OwnedVehicle[playerid][slot][ov_Plate],
                storageName,
                damageText,
                location,
                s_OwnedVehicle[playerid][slot][ov_Mileage]
            );
            printf("[VEHICLE DEBUG] ShowList row_len=%d", strlen(row));
            strcat(body, row, sizeof(body));
            printf("[VEHICLE DEBUG] ShowList body_len=%d", strlen(body));
            s_OwnedVehicleDialogSlots[playerid][dialogRow] = slot;
            dialogRow++;
        }
    }

    if (dialogRow == 1)
    {
        strcat(
            body,
            "{D9D9D9}Khong co xe phu hop\t-\t-\t-\n",
            sizeof(body)
        );
    }

    new bool:dialogShown = ShowPlayerDialog(
        playerid,
        DIALOG_VEHICLE_LIST,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Vehicles - Phuong tien so huu",
        body,
        "Chon",
        "Dong"
    );
    printf(
        "[VEHICLE DEBUG] ShowList built p=%d rows=%d body_len=%d shown=%d",
        playerid,
        dialogRow,
        strlen(body),
        _:dialogShown
    );
    return dialogShown;
}

stock Vehicle_ShowFilter(playerid)
{
    new body[768];
    format(body, sizeof(body), "Bo loc\tNoi dung\n");
    strcat(body, "{D9D9D9}Tat ca\tTat ca xe so huu\n", sizeof(body));
    strcat(body, "{00008B}Dang hoat dong\tXe da spawn\n", sizeof(body));
    strcat(body, "{D9D9D9}Da cat\tXe chua spawn\n", sizeof(body));
    strcat(body, "{8B0000}Hu hong\tXe can sua chua\n", sizeof(body));
    strcat(body, "{8B0000}Impound\tXe bi tam giu\n", sizeof(body));
    strcat(body, "{00008B}Yeu thich\tXe duoc danh dau\n", sizeof(body));

    ShowPlayerDialog(
        playerid,
        DIALOG_VEHICLE_FILTER,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Vehicles - Bo loc",
        body,
        "Ap dung",
        "Quay lai"
    );
    return 1;
}

stock Vehicle_AddActionRow(
    playerid,
    E_OWNED_VEHICLE_ACTION:action,
    const title[],
    const detail[],
    body[],
    size
)
{
    if (s_OwnedVehicleActionCount[playerid] >= 10)
    {
        return 0;
    }

    new row[160];
    format(row, sizeof(row), "{D9D9D9}%s\t{00008B}%s\n", title, detail);
    strcat(body, row, size);
    s_OwnedVehicleDialogActions[playerid][s_OwnedVehicleActionCount[playerid]] = action;
    s_OwnedVehicleActionCount[playerid]++;
    return 1;
}

stock Vehicle_ShowActions(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return Vehicle_ShowList(playerid);
    }

    s_OwnedVehicleSelectedSlot[playerid] = slot;
    s_OwnedVehicleActionCount[playerid] = 0;

    new body[2048], title[80], modelName[32];
    Vehicle_GetModelName(
        s_OwnedVehicle[playerid][slot][ov_ModelID],
        modelName,
        sizeof(modelName)
    );
    format(body, sizeof(body), "Thao tac\tChi tiet\n");

    Vehicle_AddActionRow(
        playerid,
        OV_ACTION_INFO,
        "Thong tin chi tiet",
        "Tinh trang, GPS, quang duong",
        body,
        sizeof(body)
    );

    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_STORED)
    {
        Vehicle_AddActionRow(
            playerid,
            OV_ACTION_SPAWN,
            "Spawn xe",
            "Tai vi tri dau cuoi cung",
            body,
            sizeof(body)
        );
    }
    else if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_SPAWNED)
    {
        Vehicle_AddActionRow(
            playerid,
            OV_ACTION_STORE,
            "Cat xe",
            "Phai dung gan xe",
            body,
            sizeof(body)
        );
    }

    Vehicle_AddActionRow(
        playerid,
        OV_ACTION_FIND,
        "Tim xe bang GPS",
        "Danh dau vi tri hien tai",
        body,
        sizeof(body)
    );

    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_SPAWNED)
    {
        Vehicle_AddActionRow(
            playerid,
            OV_ACTION_PARK,
            "Dau xe tai day",
            "Luu vi tri spawn lan sau",
            body,
            sizeof(body)
        );
    }

    Vehicle_AddActionRow(
        playerid,
        OV_ACTION_LOCK,
        s_OwnedVehicle[playerid][slot][ov_Locked] ? "Mo khoa xe" : "Khoa xe",
        s_OwnedVehicle[playerid][slot][ov_Locked] ? "Trang thai: da khoa" : "Trang thai: dang mo",
        body,
        sizeof(body)
    );
    Vehicle_AddActionRow(
        playerid,
        OV_ACTION_FAVORITE,
        s_OwnedVehicle[playerid][slot][ov_Favorite] ? "Bo yeu thich" : "Danh dau yeu thich",
        "Xe yeu thich nam tren dau",
        body,
        sizeof(body)
    );

    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_STORED ||
        s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_DESTROYED)
    {
        Vehicle_AddActionRow(
            playerid,
            OV_ACTION_DELETE,
            "{8B0000}Xoa xe",
            "Xoa mem, can nhap bien so",
            body,
            sizeof(body)
        );
    }

    format(
        title,
        sizeof(title),
        "Vehicles - %s [%s]",
        modelName,
        s_OwnedVehicle[playerid][slot][ov_Plate]
    );
    ShowPlayerDialog(
        playerid,
        DIALOG_VEHICLE_ACTIONS,
        DIALOG_STYLE_TABLIST_HEADERS,
        title,
        body,
        "Chon",
        "Quay lai"
    );
    return 1;
}

stock Vehicle_ShowInfo(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return Vehicle_ShowList(playerid);
    }

    new body[2048], row[192], modelName[32], storageName[24], location[40];
    Vehicle_GetModelName(
        s_OwnedVehicle[playerid][slot][ov_ModelID],
        modelName,
        sizeof(modelName)
    );
    Vehicle_GetStorageName(
        s_OwnedVehicle[playerid][slot][ov_Storage],
        storageName,
        sizeof(storageName)
    );
    Vehicle_GetLocationName(playerid, slot, location, sizeof(location));

    format(body, sizeof(body), "Thuoc tinh\tGia tri\n");
    format(row, sizeof(row), "{D9D9D9}Mau xe\t{8B0000}%s\n", modelName);
    strcat(body, row, sizeof(body));
    format(row, sizeof(row), "{D9D9D9}Bien so\t{8B0000}%s\n", s_OwnedVehicle[playerid][slot][ov_Plate]);
    strcat(body, row, sizeof(body));
    format(row, sizeof(row), "{D9D9D9}Trang thai\t{00008B}%s\n", storageName);
    strcat(body, row, sizeof(body));
    format(row, sizeof(row), "{D9D9D9}Vi tri\t{00008B}%s\n", location);
    strcat(body, row, sizeof(body));
    format(row, sizeof(row), "{D9D9D9}Quang duong\t{8B0000}%.3f km\n", s_OwnedVehicle[playerid][slot][ov_Mileage]);
    strcat(body, row, sizeof(body));
    format(row, sizeof(row), "{D9D9D9}Do ben\t{8B0000}%.1f / 1000.0\n", s_OwnedVehicle[playerid][slot][ov_Health]);
    strcat(body, row, sizeof(body));
    format(
        row,
        sizeof(row),
        "{D9D9D9}Hu hong chi tiet\t{8B0000}P:%d D:%d L:%d T:%d\n",
        _:s_OwnedVehicle[playerid][slot][ov_Panels],
        _:s_OwnedVehicle[playerid][slot][ov_Doors],
        _:s_OwnedVehicle[playerid][slot][ov_Lights],
        _:s_OwnedVehicle[playerid][slot][ov_Tyres]
    );
    strcat(body, row, sizeof(body));
    format(
        row,
        sizeof(row),
        "{D9D9D9}Khoa xe\t{00008B}%s\n",
        s_OwnedVehicle[playerid][slot][ov_Locked] ? "Da khoa" : "Dang mo"
    );
    strcat(body, row, sizeof(body));
    format(
        row,
        sizeof(row),
        "{D9D9D9}GPS\t{00008B}%s\n",
        (s_OwnedVehicle[playerid][slot][ov_GPSInstalled] &&
        s_OwnedVehicle[playerid][slot][ov_GPSActive]) ? "Dang hoat dong" : "Khong co tin hieu"
    );
    strcat(body, row, sizeof(body));
    format(
        row,
        sizeof(row),
        "{D9D9D9}Canh bao trom\t{8B0000}%s\n",
        s_OwnedVehicle[playerid][slot][ov_Stolen] ? "Xe dang bi nguoi khac lai" : "Khong"
    );
    strcat(body, row, sizeof(body));

    ShowPlayerDialog(
        playerid,
        DIALOG_VEHICLE_INFO,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Vehicles - Thong tin chi tiet",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock Vehicle_ShowDeleteConfirmation(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return Vehicle_ShowList(playerid);
    }

    s_OwnedVehicleDeleteSlot[playerid] = slot;

    new body[384];
    format(
        body,
        sizeof(body),
        "{D9D9D9}Hanh dong nay se xoa xe khoi nhan vat.\n\nNhap chinh xac bien so {8B0000}%s{D9D9D9} de xac nhan:",
        s_OwnedVehicle[playerid][slot][ov_Plate]
    );
    ShowPlayerDialog(
        playerid,
        DIALOG_VEHICLE_DELETE,
        DIALOG_STYLE_INPUT,
        "Vehicles - Xac nhan xoa",
        body,
        "Xoa xe",
        "Huy"
    );
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    switch (dialogid)
    {
        case DIALOG_VEHICLE_LIST:
        {
            if (!response)
            {
                return 1;
            }

            if (listitem == 0)
            {
                Vehicle_ShowFilter(playerid);
                return 1;
            }

            if (listitem < 1 || listitem > MAX_OWNED_VEHICLES)
            {
                return Vehicle_ShowList(playerid);
            }

            new const slot = s_OwnedVehicleDialogSlots[playerid][listitem];
            return Vehicle_ShowActions(playerid, slot);
        }
        case DIALOG_VEHICLE_FILTER:
        {
            if (!response)
            {
                return Vehicle_ShowList(playerid);
            }

            if (listitem < _:OV_FILTER_ALL || listitem > _:OV_FILTER_FAVORITE)
            {
                return Vehicle_ShowFilter(playerid);
            }

            s_OwnedVehicleFilter[playerid] = E_OWNED_VEHICLE_FILTER:listitem;
            return Vehicle_ShowList(playerid);
        }
        case DIALOG_VEHICLE_ACTIONS:
        {
            if (!response)
            {
                return Vehicle_ShowList(playerid);
            }

            new const slot = s_OwnedVehicleSelectedSlot[playerid];

            if (!Vehicle_IsValidSlot(playerid, slot) ||
                listitem < 0 ||
                listitem >= s_OwnedVehicleActionCount[playerid])
            {
                return Vehicle_ShowList(playerid);
            }

            switch (s_OwnedVehicleDialogActions[playerid][listitem])
            {
                case OV_ACTION_INFO:
                {
                    return Vehicle_ShowInfo(playerid, slot);
                }
                case OV_ACTION_SPAWN:
                {
                    Vehicle_SpawnOwned(playerid, slot);
                }
                case OV_ACTION_STORE:
                {
                    Vehicle_StoreOwned(playerid, slot);
                }
                case OV_ACTION_FIND:
                {
                    Vehicle_FindOwned(playerid, slot);
                }
                case OV_ACTION_PARK:
                {
                    Vehicle_ParkOwned(playerid, slot);
                }
                case OV_ACTION_LOCK:
                {
                    Vehicle_ToggleLock(playerid, slot);
                }
                case OV_ACTION_FAVORITE:
                {
                    Vehicle_ToggleFavorite(playerid, slot);
                }
                case OV_ACTION_DELETE:
                {
                    return Vehicle_ShowDeleteConfirmation(playerid, slot);
                }
            }

            return Vehicle_ShowActions(playerid, slot);
        }
        case DIALOG_VEHICLE_INFO:
        {
            if (!response)
            {
                return 1;
            }

            return Vehicle_ShowActions(
                playerid,
                s_OwnedVehicleSelectedSlot[playerid]
            );
        }
        case DIALOG_VEHICLE_DELETE:
        {
            new const slot = s_OwnedVehicleDeleteSlot[playerid];

            if (!response)
            {
                return Vehicle_ShowActions(playerid, slot);
            }

            if (!Vehicle_IsValidSlot(playerid, slot) ||
                (s_OwnedVehicle[playerid][slot][ov_Storage] != OV_STORAGE_STORED &&
                s_OwnedVehicle[playerid][slot][ov_Storage] != OV_STORAGE_DESTROYED))
            {
                SendClientMessage(playerid, COLOR_RED, "Xe phai duoc cat truoc khi xoa.");
                return Vehicle_ShowList(playerid);
            }

            if (strcmp(inputtext, s_OwnedVehicle[playerid][slot][ov_Plate], true) != 0)
            {
                SendClientMessage(playerid, COLOR_RED, "Bien so xac nhan khong dung.");
                return Vehicle_ShowDeleteConfirmation(playerid, slot);
            }

            Vehicle_RequestDelete(playerid, slot);
            SendClientMessage(playerid, COLOR_WHITE, "Dang xac nhan xoa xe voi database...");
            return 1;
        }
    }

    return 0;
}
