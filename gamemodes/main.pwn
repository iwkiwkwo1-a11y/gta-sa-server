#include <a_samp>

// Dialog IDs
#define DIALOG_REGISTER 1
#define DIALOG_LOGIN    2
#define DIALOG_HP_MENU  3
#define DIALOG_BANK_MENU 4
#define DIALOG_BANK_DEPOSIT 5
#define DIALOG_BANK_WITHDRAW 6

// Data enum pemain
enum pInfo
{
    pPassword[129],
    pMoney,
    pScore,
    pBankMoney
};
new PlayerInfo[MAX_PLAYERS][pInfo];
new bool:IsLoggedIn[MAX_PLAYERS];

// Helper: Format letak file akun berdasarkan nama
stock GetAccountFile(playerid, filename[], len)
{
    new name[MAX_PLAYER_NAME];
    GetPlayerName(playerid, name, sizeof(name));
    format(filename, len, "Users/%s.ini", name);
}

// Fungsi utama Server
main()
{
    print("\n----------------------------------");
    print(" GTA SA-MP Roleplay Server");
    print(" Base Gamemode (Login/Register)");
    print("----------------------------------\n");
}

public OnGameModeInit()
{
    // Konfigurasi dasar saat server menyala
    SetGameModeText("RP Mode v1.0");
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Reset data
    IsLoggedIn[playerid] = false;
    PlayerInfo[playerid][pMoney] = 0;
    PlayerInfo[playerid][pScore] = 0;
    PlayerInfo[playerid][pBankMoney] = 0;
    format(PlayerInfo[playerid][pPassword], 129, "");

    new file[128];
    GetAccountFile(playerid, file, sizeof(file));

    // Cek apakah akun sudah terdaftar
    if (fexist(file))
    {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Selamat datang kembali!\nSilakan masukkan password Anda untuk login:", "Login", "Keluar");
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Selamat datang di server!\nAkun Anda belum terdaftar.\nSilakan buat password baru:", "Daftar", "Keluar");
    }
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (IsLoggedIn[playerid])
    {
        SavePlayerData(playerid);
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if (!IsLoggedIn[playerid])
    {
        SendClientMessage(playerid, 0xFF0000FF, "Anda harus login terlebih dahulu!");
        Kick(playerid);
        return 1;
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (strcmp(cmdtext, "/hp", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return SendClientMessage(playerid, 0xFF0000FF, "Anda harus login terlebih dahulu!");
        ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Pekerjaan (Segera)\n3. Kendaraan (Segera)", "Pilih", "Tutup");
        return 1;
    }
    return 0;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (dialogid == DIALOG_REGISTER)
    {
        if (!response) return Kick(playerid);

        if (strlen(inputtext) < 3)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Password terlalu pendek!\nSilakan masukkan minimal 3 karakter:", "Daftar", "Keluar");
            return 1;
        }

        // Register akun baru
        new file[128];
        GetAccountFile(playerid, file, sizeof(file));

        new File:handle = fopen(file, io_write);
        if (handle)
        {
            new writestr[256];
            format(writestr, sizeof(writestr), "Password=%s\n", inputtext);
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Money=500\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Score=1\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "BankMoney=0\n");
            fwrite(handle, writestr);

            fclose(handle);

            SendClientMessage(playerid, 0x00FF00FF, "Registrasi berhasil! Silakan login.");
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Silakan masukkan password Anda untuk login:", "Login", "Keluar");
        }
        else
        {
            SendClientMessage(playerid, 0xFF0000FF, "Terjadi kesalahan sistem saat membuat akun.");
            Kick(playerid);
        }
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (!response) return Kick(playerid);

        new file[128];
        GetAccountFile(playerid, file, sizeof(file));

        new File:handle = fopen(file, io_read);
        if (handle)
        {
            new readstr[256], key[64], val[129];
            new bool:passMatch = false;

            while (fread(handle, readstr))
            {
                // Menghapus newline
                for(new i=0; i<strlen(readstr); i++) {
                    if(readstr[i] == '\n' || readstr[i] == '\r') readstr[i] = '\0';
                }

                new splitPos = strfind(readstr, "=");
                if (splitPos != -1)
                {
                    strmid(key, readstr, 0, splitPos);
                    strmid(val, readstr, splitPos + 1, strlen(readstr));

                    if (!strcmp(key, "Password", true))
                    {
                        if (!strcmp(val, inputtext, false))
                        {
                            passMatch = true;
                        }
                    }
                    else if (!strcmp(key, "Money", true))
                    {
                        PlayerInfo[playerid][pMoney] = strval(val);
                    }
                    else if (!strcmp(key, "Score", true))
                    {
                        PlayerInfo[playerid][pScore] = strval(val);
                    }
                    else if (!strcmp(key, "BankMoney", true))
                    {
                        PlayerInfo[playerid][pBankMoney] = strval(val);
                    }
                }
            }
            fclose(handle);

            if (passMatch)
            {
                IsLoggedIn[playerid] = true;
                GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
                SetPlayerScore(playerid, PlayerInfo[playerid][pScore]);
                SendClientMessage(playerid, 0x00FF00FF, "Login berhasil! Selamat bermain.");
                SpawnPlayer(playerid);
            }
            else
            {
                ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Password salah!\nSilakan masukkan kembali password Anda:", "Login", "Keluar");
            }
        }
        return 1;
    }

    if (dialogid == DIALOG_HP_MENU)
    {
        if (!response) return 1;

        if (listitem == 0) // Bank Mobile
        {
            new str[256];
            format(str, sizeof(str), "Informasi Saldo (Saldo Anda: $%d)\nSimpan Uang\nTarik Uang", PlayerInfo[playerid][pBankMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "Bank Mobile", str, "Pilih", "Kembali");
        }
        else if (listitem == 1) // Pekerjaan
        {
            SendClientMessage(playerid, 0xFFFF00FF, "Fitur Pekerjaan sedang dalam pengembangan.");
        }
        else if (listitem == 2) // Kendaraan
        {
            SendClientMessage(playerid, 0xFFFF00FF, "Fitur Kendaraan sedang dalam pengembangan.");
        }
        return 1;
    }

    if (dialogid == DIALOG_BANK_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Pekerjaan (Segera)\n3. Kendaraan (Segera)", "Pilih", "Tutup");

        if (listitem == 0) // Info Saldo (tidak memicu dialog input, hanya kembali me-refresh)
        {
            new str[256];
            format(str, sizeof(str), "Informasi Saldo (Saldo Anda: $%d)\nSimpan Uang\nTarik Uang", PlayerInfo[playerid][pBankMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "Bank Mobile", str, "Pilih", "Kembali");
        }
        else if (listitem == 1) // Simpan Uang
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang", "Berapa jumlah uang tunai yang ingin disimpan ke bank?", "Simpan", "Batal");
        }
        else if (listitem == 2) // Tarik Uang
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang", "Berapa jumlah saldo bank yang ingin ditarik tunai?", "Tarik", "Batal");
        }
        return 1;
    }

    if (dialogid == DIALOG_BANK_DEPOSIT)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Pekerjaan (Segera)\n3. Kendaraan (Segera)", "Pilih", "Tutup");

        new amount = strval(inputtext);
        if (amount <= 0) return ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang", "Jumlah tidak valid!\nBerapa jumlah uang tunai yang ingin disimpan?", "Simpan", "Batal");
        if (GetPlayerMoney(playerid) < amount) return ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang", "Uang tunai Anda tidak cukup!\nBerapa jumlah uang tunai yang ingin disimpan?", "Simpan", "Batal");

        GivePlayerMoney(playerid, -amount);
        PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);
        PlayerInfo[playerid][pBankMoney] += amount;

        new msg[128];
        format(msg, sizeof(msg), "BANK: Anda telah menyimpan uang sebesar $%d. Saldo Bank saat ini: $%d", amount, PlayerInfo[playerid][pBankMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        SavePlayerData(playerid);
        return 1;
    }

    if (dialogid == DIALOG_BANK_WITHDRAW)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Pekerjaan (Segera)\n3. Kendaraan (Segera)", "Pilih", "Tutup");

        new amount = strval(inputtext);
        if (amount <= 0) return ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang", "Jumlah tidak valid!\nBerapa jumlah saldo bank yang ingin ditarik tunai?", "Tarik", "Batal");
        if (PlayerInfo[playerid][pBankMoney] < amount) return ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang", "Saldo bank Anda tidak cukup!\nBerapa jumlah saldo bank yang ingin ditarik tunai?", "Tarik", "Batal");

        PlayerInfo[playerid][pBankMoney] -= amount;
        GivePlayerMoney(playerid, amount);
        PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);

        new msg[128];
        format(msg, sizeof(msg), "BANK: Anda telah menarik uang tunai sebesar $%d. Saldo Bank tersisa: $%d", amount, PlayerInfo[playerid][pBankMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        SavePlayerData(playerid);
        return 1;
    }

    return 0;
}

// Fungsi bantu menyimpan data (bisa dipanggil saat disconnect)
stock SavePlayerData(playerid)
{
    if (!IsLoggedIn[playerid]) return;

    new file[128];
    GetAccountFile(playerid, file, sizeof(file));

    // Mengambil uang terbaru (ini karena SA-MP internal money bisa berubah)
    PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);
    PlayerInfo[playerid][pScore] = GetPlayerScore(playerid);

    // Buka file awal untuk baca password (agar tidak kerest)
    new File:handleRead = fopen(file, io_read);
    new currentPass[129];
    if (handleRead)
    {
        new readstr[256], key[64], val[129];
        while (fread(handleRead, readstr))
        {
            for(new i=0; i<strlen(readstr); i++) {
                if(readstr[i] == '\n' || readstr[i] == '\r') readstr[i] = '\0';
            }
            new splitPos = strfind(readstr, "=");
            if (splitPos != -1)
            {
                strmid(key, readstr, 0, splitPos);
                strmid(val, readstr, splitPos + 1, strlen(readstr));
                if (!strcmp(key, "Password", true))
                {
                    format(currentPass, sizeof(currentPass), "%s", val);
                }
            }
        }
        fclose(handleRead);
    }

    // Timpa ulang isi file
    new File:handleWrite = fopen(file, io_write);
    if (handleWrite)
    {
        new writestr[256];
        format(writestr, sizeof(writestr), "Password=%s\n", currentPass);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Money=%d\n", PlayerInfo[playerid][pMoney]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Score=%d\n", PlayerInfo[playerid][pScore]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "BankMoney=%d\n", PlayerInfo[playerid][pBankMoney]);
        fwrite(handleWrite, writestr);

        fclose(handleWrite);
    }
}
