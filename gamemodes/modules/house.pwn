// ==========================================
// MODULE: HOUSE (Housing, Safes, Sleep)
// ==========================================

stock LoadHouseData()
{
    new file[128], readstr[256], key[64], val[129];
    for(new i = 0; i < MAX_HOUSES; i++)
    {
        format(file, sizeof(file), "Users/House_%d.ini", i);
        if (fexist(file))
        {
            new File:handle = fopen(file, io_read);
            if (handle)
            {
                while (fread(handle, readstr))
                {
                    for(new j=0; j<strlen(readstr); j++) { if(readstr[j] == '\n' || readstr[j] == '\r') readstr[j] = '\0'; }
                    new splitPos = strfind(readstr, "=");
                    if (splitPos != -1)
                    {
                        strmid(key, readstr, 0, splitPos);
                        strmid(val, readstr, splitPos + 1, strlen(readstr));
                        if (!strcmp(key, "Owner", true)) format(HouseInfo[i][hOwner], MAX_PLAYER_NAME, "%s", val);
                        else if (!strcmp(key, "SafeMoney", true)) HouseInfo[i][hSafeMoney] = strval(val);
                    }
                }
                fclose(handle);
            }
        }
    }
}

stock SaveHouseData(houseid)
{
    new file[128];
    format(file, sizeof(file), "Users/House_%d.ini", houseid);
    new File:handle = fopen(file, io_write);
    if (handle)
    {
        new str[128];
        format(str, sizeof(str), "Owner=%s\n", HouseInfo[houseid][hOwner]); fwrite(handle, str);
        format(str, sizeof(str), "SafeMoney=%d\n", HouseInfo[houseid][hSafeMoney]); fwrite(handle, str);
        fclose(handle);
    }
}

stock House_Init()
{
    LoadHouseData();
    for(new i = 0; i < MAX_HOUSES; i++)
    {
        new str[128];
        if (strcmp(HouseInfo[i][hOwner], "None", true) == 0)
        {
            HousePickup[i] = CreatePickup(1273, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);
            format(str, sizeof(str), "[Rumah Dijual]\nHarga: $%d\nTekan ENTER untuk membeli", HouseInfo[i][hPrice]);
        }
        else
        {
            HousePickup[i] = CreatePickup(1272, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);
            format(str, sizeof(str), "[Rumah Pribadi]\nPemilik: %s\nTekan ENTER untuk masuk", HouseInfo[i][hOwner]);
        }
        HouseLabel[i] = Create3DTextLabel(str, 0x00FF00FF, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ] + 0.5, 20.0, 0, 0);
    }
}

stock House_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_BRANKAS_MENU)
    {
        if (!response) return 1;
        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;

        if (listitem == 0)
        {
            new str[256]; format(str, sizeof(str), "Brankas Rumah\nSaldo: $%d\n\n1. Simpan Uang\n2. Tarik Uang", HouseInfo[hid][hSafeMoney]);
            ShowPlayerDialog(playerid, DIALOG_BRANKAS_MENU, DIALOG_STYLE_LIST, "Brankas", str, "Pilih", "Tutup");
        }
        else if (listitem == 1) ShowPlayerDialog(playerid, DIALOG_BRANKAS_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang ke Brankas", "Masukkan jumlah uang yang ingin disimpan:", "Simpan", "Batal");
        else if (listitem == 2) ShowPlayerDialog(playerid, DIALOG_BRANKAS_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang dari Brankas", "Masukkan jumlah uang yang ingin ditarik:", "Tarik", "Batal");
        return 1;
    }

    if (dialogid == DIALOG_BRANKAS_DEPOSIT)
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");
        if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, 0xFF0000FF, "Uang tunai tidak cukup!");

        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;

        GivePlayerMoney(playerid, -amount); HouseInfo[hid][hSafeMoney] += amount; SaveHouseData(hid);
        new msg[128]; format(msg, sizeof(msg), "HOUSE: Menyimpan $%d ke brankas. Saldo: $%d", amount, HouseInfo[hid][hSafeMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        return 1;
    }

    if (dialogid == DIALOG_BRANKAS_WITHDRAW)
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");

        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;
        if (HouseInfo[hid][hSafeMoney] < amount) return SendClientMessage(playerid, 0xFF0000FF, "Saldo brankas tidak cukup!");

        HouseInfo[hid][hSafeMoney] -= amount; GivePlayerMoney(playerid, amount); SaveHouseData(hid);
        new msg[128]; format(msg, sizeof(msg), "HOUSE: Menarik $%d dari brankas. Saldo tersisa: $%d", amount, HouseInfo[hid][hSafeMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        return 1;
    }
    return 0;
}

stock House_OnPlayerCommandText(playerid, cmd[])
{
    if (strcmp(cmd, "/tidur", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;
        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid >= 0 && hid < MAX_HOUSES)
        {
            if (IsPlayerInRangeOfPoint(playerid, 10.0, HouseInfo[hid][hIntX], HouseInfo[hid][hIntY], HouseInfo[hid][hIntZ]) && GetPlayerVirtualWorld(playerid) == (hid + 1))
            {
                SetPlayerHealth(playerid, 100.0);
                PlayerInfo[playerid][pHunger] = 100;
                PlayerInfo[playerid][pThirst] = 100;
                SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Anda beristirahat. Darah, Lapar, dan Haus terisi penuh.");
                return 1;
            }
        }
        SendClientMessage(playerid, 0xFF0000FF, "HOUSE: Harus di dalam rumah sendiri!");
        return 1;
    }

    if (strcmp(cmd, "/brankas", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;
        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid >= 0 && hid < MAX_HOUSES)
        {
            if (IsPlayerInRangeOfPoint(playerid, 10.0, HouseInfo[hid][hIntX], HouseInfo[hid][hIntY], HouseInfo[hid][hIntZ]) && GetPlayerVirtualWorld(playerid) == (hid + 1))
            {
                new str[256];
                format(str, sizeof(str), "Brankas Rumah\nSaldo: $%d\n\n1. Simpan Uang\n2. Tarik Uang", HouseInfo[hid][hSafeMoney]);
                ShowPlayerDialog(playerid, DIALOG_BRANKAS_MENU, DIALOG_STYLE_LIST, "Brankas", str, "Pilih", "Tutup");
                return 1;
            }
        }
        SendClientMessage(playerid, 0xFF0000FF, "HOUSE: Harus di dalam rumah sendiri!");
        return 1;
    }
    return 0;
}

stock House_OnPlayerKeyStateChange(playerid, newkeys)
{
    if (newkeys & KEY_SECONDARY_ATTACK)
    {
        if (IsLoggedIn[playerid])
        {
            for(new i = 0; i < MAX_HOUSES; i++)
            {
                if (IsPlayerInRangeOfPoint(playerid, 3.0, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ]))
                {
                    if (strcmp(HouseInfo[i][hOwner], "None", true) == 0)
                    {
                        if (PlayerInfo[playerid][pHouseID] != 0) return SendClientMessage(playerid, 0xFF0000FF, "Anda sudah punya rumah!");
                        if (GetPlayerMoney(playerid) < HouseInfo[i][hPrice]) return SendClientMessage(playerid, 0xFF0000FF, "Uang tidak cukup!");

                        GivePlayerMoney(playerid, -HouseInfo[i][hPrice]);
                        PlayerInfo[playerid][pHouseID] = i + 1;
                        new name[MAX_PLAYER_NAME]; GetPlayerName(playerid, name, sizeof(name));
                        format(HouseInfo[i][hOwner], MAX_PLAYER_NAME, "%s", name);

                        DestroyPickup(HousePickup[i]);
                        HousePickup[i] = CreatePickup(1272, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);
                        new str[128]; format(str, sizeof(str), "[Rumah Pribadi]\nPemilik: %s\nTekan ENTER untuk masuk", HouseInfo[i][hOwner]);
                        Update3DTextLabelText(HouseLabel[i], 0x00FF00FF, str);

                        SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Rumah terbeli.");
                        SaveHouseData(i); SavePlayerData(playerid);
                    }
                    else
                    {
                        new name[MAX_PLAYER_NAME]; GetPlayerName(playerid, name, sizeof(name));
                        if (strcmp(HouseInfo[i][hOwner], name, true) == 0)
                        {
                            SetPlayerPos(playerid, HouseInfo[i][hIntX], HouseInfo[i][hIntY], HouseInfo[i][hIntZ]);
                            SetPlayerInterior(playerid, HouseInfo[i][hIntID]);
                            SetPlayerVirtualWorld(playerid, i + 1);
                            SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Masuk rumah. (Tekan ENTER keluar, /tidur, /brankas)");
                        }
                        else SendClientMessage(playerid, 0xFF0000FF, "Rumah terkunci!");
                    }
                    return 1;
                }

                if (IsPlayerInRangeOfPoint(playerid, 3.0, HouseInfo[i][hIntX], HouseInfo[i][hIntY], HouseInfo[i][hIntZ]) && GetPlayerVirtualWorld(playerid) == (i + 1))
                {
                    SetPlayerPos(playerid, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ]);
                    SetPlayerInterior(playerid, 0); SetPlayerVirtualWorld(playerid, 0);
                    return 1;
                }
            }
        }
    }
    return 0;
}
