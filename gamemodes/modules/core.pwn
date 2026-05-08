// ==========================================
// MODULE: CORE (Login, Register, Save, Admin)
// ==========================================

stock GetAccountFile(playerid, filename[], len)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(filename, len, "Users/%s.ini", name);
}

stock Core_OnPlayerConnect(playerid)
{
    IsLoggedIn[playerid] = false;
    PlayerInfo[playerid][pMoney] = 0;
    PlayerInfo[playerid][pScore] = 0;
    PlayerInfo[playerid][pBankMoney] = 0;
    PlayerInfo[playerid][pHunger] = 100;
    PlayerInfo[playerid][pThirst] = 100;
    PlayerInfo[playerid][pJob] = 0;
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pVehModel] = 0;
    PlayerInfo[playerid][pFood] = 0;
    PlayerInfo[playerid][pDrink] = 0;
    PlayerInfo[playerid][pPaydayTimer] = 0;
    PlayerInfo[playerid][pHouseID] = 0;
    PlayerInfo[playerid][pPosX] = 0.0;
    PlayerInfo[playerid][pPosY] = 0.0;
    PlayerInfo[playerid][pPosZ] = 0.0;
    PlayerInfo[playerid][pInt] = 0;
    PlayerInfo[playerid][pVW] = 0;
    format(PlayerInfo[playerid][pPassword], 129, "");

    OnMission[playerid] = false;
    MissionType[playerid] = 0;
    MissionStep[playerid] = 0;
    MissionActor[playerid] = -1;
    DisablePlayerCheckpoint(playerid);

    new file[128];
    GetAccountFile(playerid, file, sizeof(file));

    if (fexist(file))
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Selamat datang kembali!\nSilakan masukkan password Anda:", "Login", "Keluar");
    else
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Selamat datang!\nAkun belum terdaftar.\nBuat password baru:", "Daftar", "Keluar");
}

stock SavePlayerData(playerid)
{
    if (!IsLoggedIn[playerid]) return;
    new file[128];
    GetAccountFile(playerid, file, sizeof(file));

    PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);
    PlayerInfo[playerid][pScore] = GetPlayerScore(playerid);

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    PlayerInfo[playerid][pPosX] = x;
    PlayerInfo[playerid][pPosY] = y;
    PlayerInfo[playerid][pPosZ] = z;
    PlayerInfo[playerid][pInt] = GetPlayerInterior(playerid);
    PlayerInfo[playerid][pVW] = GetPlayerVirtualWorld(playerid);

    new File:handleWrite = fopen(file, io_write);
    if (handleWrite)
    {
        new writestr[256];
        format(writestr, sizeof(writestr), "Password=%s\n", PlayerInfo[playerid][pPassword]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Money=%d\n", PlayerInfo[playerid][pMoney]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Score=%d\n", PlayerInfo[playerid][pScore]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "BankMoney=%d\n", PlayerInfo[playerid][pBankMoney]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Hunger=%d\n", PlayerInfo[playerid][pHunger]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Thirst=%d\n", PlayerInfo[playerid][pThirst]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Job=%d\n", PlayerInfo[playerid][pJob]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Admin=%d\n", PlayerInfo[playerid][pAdmin]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "VehModel=%d\n", PlayerInfo[playerid][pVehModel]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Food=%d\n", PlayerInfo[playerid][pFood]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Drink=%d\n", PlayerInfo[playerid][pDrink]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "PaydayTimer=%d\n", PlayerInfo[playerid][pPaydayTimer]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "HouseID=%d\n", PlayerInfo[playerid][pHouseID]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "PosX=%f\n", PlayerInfo[playerid][pPosX]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "PosY=%f\n", PlayerInfo[playerid][pPosY]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "PosZ=%f\n", PlayerInfo[playerid][pPosZ]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "Int=%d\n", PlayerInfo[playerid][pInt]); fwrite(handleWrite, writestr);
        format(writestr, sizeof(writestr), "VW=%d\n", PlayerInfo[playerid][pVW]); fwrite(handleWrite, writestr);
        fclose(handleWrite);
    }
}

stock Core_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_REGISTER)
    {
        if (!response) { Kick(playerid); return 1; }
        if (strlen(inputtext) < 3)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Password terlalu pendek!\nMinimal 3 karakter:", "Daftar", "Keluar");
            return 1;
        }

        new file[128];
        GetAccountFile(playerid, file, sizeof(file));
        format(PlayerInfo[playerid][pPassword], 129, "%s", inputtext);

        new File:handle = fopen(file, io_write);
        if (handle)
        {
            new writestr[256];
            format(writestr, sizeof(writestr), "Password=%s\n", PlayerInfo[playerid][pPassword]); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Money=500\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Score=1\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "BankMoney=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Hunger=100\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Thirst=100\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Job=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Admin=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "VehModel=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Food=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Drink=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "PaydayTimer=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "HouseID=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "PosX=0.0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "PosY=0.0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "PosZ=0.0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "Int=0\n"); fwrite(handle, writestr);
            format(writestr, sizeof(writestr), "VW=0\n"); fwrite(handle, writestr);
            fclose(handle);

            SendClientMessage(playerid, 0x00FF00FF, "Registrasi berhasil! Silakan login.");
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Masukkan password Anda untuk login:", "Login", "Keluar");
        }
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (!response) { Kick(playerid); return 1; }
        new file[128];
        GetAccountFile(playerid, file, sizeof(file));

        new File:handle = fopen(file, io_read);
        if (handle)
        {
            new readstr[256], key[64], val[129], bool:passMatch = false;
            while (fread(handle, readstr))
            {
                for(new i=0; i<strlen(readstr); i++) { if(readstr[i] == '\n' || readstr[i] == '\r') readstr[i] = '\0'; }
                new splitPos = strfind(readstr, "=");
                if (splitPos != -1)
                {
                    strmid(key, readstr, 0, splitPos);
                    strmid(val, readstr, splitPos + 1, strlen(readstr));

                    if (!strcmp(key, "Password", true)) { if (!strcmp(val, inputtext, false)) passMatch = true; }
                    else if (!strcmp(key, "Money", true)) PlayerInfo[playerid][pMoney] = strval(val);
                    else if (!strcmp(key, "Score", true)) PlayerInfo[playerid][pScore] = strval(val);
                    else if (!strcmp(key, "BankMoney", true)) PlayerInfo[playerid][pBankMoney] = strval(val);
                    else if (!strcmp(key, "Hunger", true)) PlayerInfo[playerid][pHunger] = strval(val);
                    else if (!strcmp(key, "Thirst", true)) PlayerInfo[playerid][pThirst] = strval(val);
                    else if (!strcmp(key, "Job", true)) PlayerInfo[playerid][pJob] = strval(val);
                    else if (!strcmp(key, "Admin", true)) PlayerInfo[playerid][pAdmin] = strval(val);
                    else if (!strcmp(key, "VehModel", true)) PlayerInfo[playerid][pVehModel] = strval(val);
                    else if (!strcmp(key, "Food", true)) PlayerInfo[playerid][pFood] = strval(val);
                    else if (!strcmp(key, "Drink", true)) PlayerInfo[playerid][pDrink] = strval(val);
                    else if (!strcmp(key, "PaydayTimer", true)) PlayerInfo[playerid][pPaydayTimer] = strval(val);
                    else if (!strcmp(key, "HouseID", true)) PlayerInfo[playerid][pHouseID] = strval(val);
                    else if (!strcmp(key, "PosX", true)) PlayerInfo[playerid][pPosX] = floatstr(val);
                    else if (!strcmp(key, "PosY", true)) PlayerInfo[playerid][pPosY] = floatstr(val);
                    else if (!strcmp(key, "PosZ", true)) PlayerInfo[playerid][pPosZ] = floatstr(val);
                    else if (!strcmp(key, "Int", true)) PlayerInfo[playerid][pInt] = strval(val);
                    else if (!strcmp(key, "VW", true)) PlayerInfo[playerid][pVW] = strval(val);
                }
            }
            fclose(handle);

            if (passMatch)
            {
                IsLoggedIn[playerid] = true;
                format(PlayerInfo[playerid][pPassword], 129, "%s", inputtext);
                GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
                SetPlayerScore(playerid, PlayerInfo[playerid][pScore]);
                SendClientMessage(playerid, 0x00FF00FF, "Login berhasil! Selamat bermain.");
                SpawnPlayer(playerid);
            }
            else
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Password salah!\nSilakan masukkan kembali:", "Login", "Keluar");
            }
        }
        return 1;
    }
    return 0;
}

stock Core_OnPlayerCommandText(playerid, cmdtext[])
{
    new cmd[128], idx;
    cmd = strtok(cmdtext, idx);

    if (strcmp(cmd, "/makeadmin", true) == 0)
    {
        if (!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Hanya RCON Admin yang bisa menggunakan ini!");
        new tmp[128]; tmp = strtok(cmdtext, idx);
        if(!strlen(tmp)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /makeadmin [playerid]");

        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan atau belum login!");

        PlayerInfo[targetid][pAdmin] = 1;
        SendClientMessage(targetid, 0x00FF00FF, "ADMIN: Anda telah dijadikan Admin oleh RCON!");
        SendClientMessage(playerid, 0x00FF00FF, "ADMIN: Berhasil.");
        return 1;
    }

    if (strcmp(cmd, "/agivemoney", true) == 0)
    {
        if (PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda bukan Admin!");
        new tmp[128], tmp2[128];
        tmp = strtok(cmdtext, idx); tmp2 = strtok(cmdtext, idx);
        if(!strlen(tmp) || !strlen(tmp2)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /agivemoney [playerid] [jumlah]");

        new targetid = strval(tmp), amount = strval(tmp2);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan!");

        GivePlayerMoney(targetid, amount);
        PlayerInfo[targetid][pMoney] = GetPlayerMoney(targetid);
        SendClientMessage(targetid, 0x00FF00FF, "ADMIN: Admin telah memberi Anda uang tunai.");
        return 1;
    }

    if (strcmp(cmd, "/akick", true) == 0)
    {
        if (PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda bukan Admin!");
        new tmp[128]; tmp = strtok(cmdtext, idx);
        if(!strlen(tmp)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /akick [playerid]");

        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan!");

        SendClientMessage(targetid, 0xFF0000FF, "ADMIN: Anda telah di-kick!");
        Kick(targetid);
        return 1;
    }
    return 0;
}
