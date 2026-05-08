// ==========================================
// MODULE: ECONOMY (Bank, Stats, Market, Paycheck)
// ==========================================

forward Economy_GlobalTimer();
public Economy_GlobalTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && IsLoggedIn[i] && !IsPlayerNPC(i))
        {
            PlayerInfo[i][pHunger] -= 2;
            PlayerInfo[i][pThirst] -= 3;
            if(PlayerInfo[i][pHunger] < 0) PlayerInfo[i][pHunger] = 0;
            if(PlayerInfo[i][pThirst] < 0) PlayerInfo[i][pThirst] = 0;

            if(PlayerInfo[i][pHunger] == 0 || PlayerInfo[i][pThirst] == 0)
            {
                new Float:hp; GetPlayerHealth(i, hp);
                SetPlayerHealth(i, hp - 5.0);
                SendClientMessage(i, 0xFF0000FF, "Anda merasa sangat lapar/haus! Darah Anda berkurang.");
            }

            PlayerInfo[i][pPaydayTimer]++;
            if(PlayerInfo[i][pPaydayTimer] >= 60)
            {
                PlayerInfo[i][pPaydayTimer] = 0;
                new salary = 100;
                if(PlayerInfo[i][pJob] == 1) salary = 350;
                else if(PlayerInfo[i][pJob] == 2) salary = 300;

                PlayerInfo[i][pBankMoney] += salary;
                SendClientMessage(i, 0x00FF00FF, "================= PAYCHECK =================");
                SendClientMessage(i, 0xFFFFFFFF, "Anda telah bermain selama 1 Jam.");

                new str[128];
                format(str, sizeof(str), "Gaji Pekerjaan: $%d (Telah ditransfer ke Saldo Bank Anda)", salary);
                SendClientMessage(i, 0xFFFFFFFF, str);
                format(str, sizeof(str), "Saldo Bank Saat Ini: $%d", PlayerInfo[i][pBankMoney]);
                SendClientMessage(i, 0xFFFFFFFF, str);
                SendClientMessage(i, 0x00FF00FF, "============================================");
                SavePlayerData(i);
            }
        }
    }
}

stock Economy_OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_BANK_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            new str[256]; format(str, sizeof(str), "Informasi Saldo (Saldo Anda: $%d)\nSimpan Uang\nTarik Uang", PlayerInfo[playerid][pBankMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "Bank Mobile", str, "Pilih", "Kembali");
        }
        else if (listitem == 1) ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang", "Berapa uang yang ingin disimpan?", "Simpan", "Batal");
        else if (listitem == 2) ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang", "Berapa saldo yang ingin ditarik?", "Tarik", "Batal");
        return 1;
    }

    if (dialogid == DIALOG_BANK_DEPOSIT)
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");
        if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, 0xFF0000FF, "Uang Anda tidak cukup!");

        GivePlayerMoney(playerid, -amount);
        PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);
        PlayerInfo[playerid][pBankMoney] += amount;

        new msg[128]; format(msg, sizeof(msg), "BANK: Menyimpan $%d. Saldo Bank: $%d", amount, PlayerInfo[playerid][pBankMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        SavePlayerData(playerid);
        return 1;
    }

    if (dialogid == DIALOG_BANK_WITHDRAW)
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");
        if (PlayerInfo[playerid][pBankMoney] < amount) return SendClientMessage(playerid, 0xFF0000FF, "Saldo bank tidak cukup!");

        PlayerInfo[playerid][pBankMoney] -= amount;
        GivePlayerMoney(playerid, amount);
        PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);

        new msg[128]; format(msg, sizeof(msg), "BANK: Menarik $%d. Saldo Bank tersisa: $%d", amount, PlayerInfo[playerid][pBankMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        SavePlayerData(playerid);
        return 1;
    }

    if (dialogid == DIALOG_MARKET_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            if (GetPlayerMoney(playerid) < 15) return SendClientMessage(playerid, 0xFF0000FF, "Butuh $15!");
            GivePlayerMoney(playerid, -15); PlayerInfo[playerid][pFood]++;
            SendClientMessage(playerid, 0x00FF00FF, "MARKET: Membeli Makanan.");
        }
        else if (listitem == 1)
        {
            if (GetPlayerMoney(playerid) < 10) return SendClientMessage(playerid, 0xFF0000FF, "Butuh $10!");
            GivePlayerMoney(playerid, -10); PlayerInfo[playerid][pDrink]++;
            SendClientMessage(playerid, 0x00FF00FF, "MARKET: Membeli Minuman.");
        }
        return 1;
    }

    if (dialogid == DIALOG_INV_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            if (PlayerInfo[playerid][pFood] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Tidak ada makanan!");
            PlayerInfo[playerid][pFood]--; PlayerInfo[playerid][pHunger] += 50;
            if (PlayerInfo[playerid][pHunger] > 100) PlayerInfo[playerid][pHunger] = 100;
            SendClientMessage(playerid, 0x00FF00FF, "INVENTORY: Memakan makanan.");
        }
        else if (listitem == 1)
        {
            if (PlayerInfo[playerid][pDrink] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Tidak ada minuman!");
            PlayerInfo[playerid][pDrink]--; PlayerInfo[playerid][pThirst] += 50;
            if (PlayerInfo[playerid][pThirst] > 100) PlayerInfo[playerid][pThirst] = 100;
            SendClientMessage(playerid, 0x00FF00FF, "INVENTORY: Meminum air.");
        }
        return 1;
    }
    return 0;
}
