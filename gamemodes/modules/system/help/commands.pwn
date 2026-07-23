//-----------------------------------------------------------------------------
// Player command help
//-----------------------------------------------------------------------------

stock Help_ShowMain(playerid)
{
    new body[2048];
    format(body, sizeof(body), "Lenh\tNhom\tMo ta\n");
    strcat(body, "/help [nhom]\tHe thong\tMo danh sach lenh\n", sizeof(body));
    strcat(body, "/me [hanh dong]\tNhap vai\tMo ta hanh dong cua nhan vat\n", sizeof(body));
    strcat(body, "/do [mo ta]\tNhap vai\tMo ta tinh huong/xung quanh\n", sizeof(body));
    strcat(body, "/ame [hanh dong]\tNhap vai\tHanh dong tren dau nhan vat\n", sizeof(body));
    strcat(body, "/b [noi dung]\tChat\tChat OOC trong pham vi gan\n", sizeof(body));
    strcat(body, "/s [noi dung]\tChat\tLa lon trong pham vi xa\n", sizeof(body));
    strcat(body, "/w [noi dung]\tChat\tNoi nho trong pham vi gan\n", sizeof(body));
    strcat(body, "/try [hanh dong]\tNhap vai\tThu mot hanh dong ngau nhien\n", sizeof(body));
    strcat(body, "/roll\tNhap vai\tTung so ngau nhien 1-100\n", sizeof(body));
    strcat(body, "/thongtin\tNhan vat\tXem thong tin chi tiet\n", sizeof(body));
    strcat(body, "/job\tNghe nghiep\tXem tien do va nghi ca\n", sizeof(body));
    strcat(body, "/vehicles\tPhuong tien\tQuan ly xe so huu\n", sizeof(body));
    strcat(body, "/car [tuy chon]\tPhuong tien\tDieu khien dong co, den, cua kinh...\n", sizeof(body));
    strcat(body, "/admins\tQuan tri\tXem admin dang truc tuyen\n", sizeof(body));

    if (Admin_HasLevel(playerid, ADMIN_LEVEL_SUPPORTER))
    {
        strcat(body, "/adminhelp\tQuan tri\tDanh sach lenh admin\n", sizeof(body));
    }

    ShowPlayerDialog(
        playerid,
        DIALOG_HELP_MAIN,
        DIALOG_STYLE_TABLIST_HEADERS,
        "LS:RP - Danh sach lenh",
        body,
        "Dong",
        ""
    );
    return 1;
}

CMD:help(playerid, params[])
{
    if (params[0] != 0 &&
        (!strcmp(params, "admin", true) ||
        !strcmp(params, "quantri", true)))
    {
        if (Admin_HasLevel(playerid, ADMIN_LEVEL_SUPPORTER))
        {
            return Admin_ShowHelp(playerid);
        }

        SendClientMessage(playerid, COLOR_RED, "Ban khong co quyen xem danh sach lenh admin.");
        return 1;
    }

    return Help_ShowMain(playerid);
}

CMD:commands(playerid, params[])
{
    return cmd_help(playerid, params);
}

CMD:cmds(playerid, params[])
{
    return cmd_help(playerid, params);
}

CMD:lenh(playerid, params[])
{
    return cmd_help(playerid, params);
}
