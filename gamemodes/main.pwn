#include <a_samp>

// Dialog IDs
#define DIALOG_REGISTER 1
#define DIALOG_LOGIN    2
#define DIALOG_HP_MENU  3
#define DIALOG_BANK_MENU 4
#define DIALOG_BANK_DEPOSIT 5
#define DIALOG_BANK_WITHDRAW 6
#define DIALOG_JOB_MENU 7
#define DIALOG_VEH_MENU 8

// Data enum pemain
enum pInfo
{
    pPassword[129],
    pMoney,
    pScore,
    pBankMoney,
    pHunger,
    pThirst,
    pJob,
    pAdmin,
    pVehModel
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

// Forward deklarasi timer
forward GlobalTimer();

public OnGameModeInit()
{
    // Konfigurasi dasar saat server menyala
    SetGameModeText("RP Mode v1.0");
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

    // Timer berjalan setiap 60 detik (60000 ms)
    SetTimer("GlobalTimer", 60000, true);
    return 1;
}

public GlobalTimer()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && IsLoggedIn[i])
        {
            // Kurangi Lapar & Haus
            PlayerInfo[i][pHunger] -= 2;
            PlayerInfo[i][pThirst] -= 3;

            // Limit bawah
            if(PlayerInfo[i][pHunger] < 0) PlayerInfo[i][pHunger] = 0;
            if(PlayerInfo[i][pThirst] < 0) PlayerInfo[i][pThirst] = 0;

            // Jika mencapai 0, kurangi darah
            if(PlayerInfo[i][pHunger] == 0 || PlayerInfo[i][pThirst] == 0)
            {
                new Float:hp;
                GetPlayerHealth(i, hp);
                SetPlayerHealth(i, hp - 5.0);
                SendClientMessage(i, 0xFF0000FF, "Anda merasa sangat lapar/haus! Darah Anda berkurang.");
            }
        }
    }
    return 1;
}

public OnPlayerConnect(playerid)
{
    // Reset data
    IsLoggedIn[playerid] = false;
    PlayerInfo[playerid][pMoney] = 0;
    PlayerInfo[playerid][pScore] = 0;
    PlayerInfo[playerid][pBankMoney] = 0;
    PlayerInfo[playerid][pHunger] = 100;
    PlayerInfo[playerid][pThirst] = 100;
    PlayerInfo[playerid][pJob] = 0;
    PlayerInfo[playerid][pAdmin] = 0;
    PlayerInfo[playerid][pVehModel] = 0;
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
        ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");
        return 1;
    }

    if (strcmp(cmdtext, "/makan", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;
        if (GetPlayerMoney(playerid) < 10) return SendClientMessage(playerid, 0xFF0000FF, "Anda butuh $10 untuk makan!");

        GivePlayerMoney(playerid, -10);
        PlayerInfo[playerid][pHunger] += 50;
        if (PlayerInfo[playerid][pHunger] > 100) PlayerInfo[playerid][pHunger] = 100;
        SendClientMessage(playerid, 0x00FF00FF, "Anda memakan sebuah burger. Rasa lapar berkurang.");
        return 1;
    }

    if (strcmp(cmdtext, "/minum", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;
        if (GetPlayerMoney(playerid) < 5) return SendClientMessage(playerid, 0xFF0000FF, "Anda butuh $5 untuk minum!");

        GivePlayerMoney(playerid, -5);
        PlayerInfo[playerid][pThirst] += 50;
        if (PlayerInfo[playerid][pThirst] > 100) PlayerInfo[playerid][pThirst] = 100;
        SendClientMessage(playerid, 0x00FF00FF, "Anda meminum sebotol air. Rasa haus berkurang.");
        return 1;
    }

    // ======== SISTEM ADMIN ========
    new cmd[128], idx;
    cmd = strtok(cmdtext, idx);

    if (strcmp(cmd, "/makeadmin", true) == 0)
    {
        if (!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Hanya RCON Admin yang bisa menggunakan ini!");

        new tmp[128];
        tmp = strtok(cmdtext, idx);
        if(!strlen(tmp)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /makeadmin [playerid]");

        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan atau belum login!");

        PlayerInfo[targetid][pAdmin] = 1;
        SendClientMessage(targetid, 0x00FF00FF, "ADMIN: Anda telah dijadikan Admin oleh RCON!");
        SendClientMessage(playerid, 0x00FF00FF, "ADMIN: Anda berhasil memberikan status Admin ke pemain.");
        return 1;
    }

    if (strcmp(cmd, "/agivemoney", true) == 0)
    {
        if (PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda bukan Admin!");

        new tmp[128], tmp2[128];
        tmp = strtok(cmdtext, idx);
        tmp2 = strtok(cmdtext, idx);

        if(!strlen(tmp) || !strlen(tmp2)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /agivemoney [playerid] [jumlah]");

        new targetid = strval(tmp);
        new amount = strval(tmp2);

        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan atau belum login!");

        GivePlayerMoney(targetid, amount);
        PlayerInfo[targetid][pMoney] = GetPlayerMoney(targetid);

        new msg[128];
        format(msg, sizeof(msg), "ADMIN: Admin telah memberi Anda uang tunai sebesar $%d", amount);
        SendClientMessage(targetid, 0x00FF00FF, msg);
        format(msg, sizeof(msg), "ADMIN: Anda memberi $%d ke pemain %d", amount, targetid);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        return 1;
    }

    if (strcmp(cmd, "/akick", true) == 0)
    {
        if (PlayerInfo[playerid][pAdmin] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda bukan Admin!");

        new tmp[128];
        tmp = strtok(cmdtext, idx);

        if(!strlen(tmp)) return SendClientMessage(playerid, 0xFFFFFFFF, "PENGGUNAAN: /akick [playerid]");

        new targetid = strval(tmp);
        if(!IsPlayerConnected(targetid) || !IsLoggedIn[targetid]) return SendClientMessage(playerid, 0xFF0000FF, "Pemain tidak ditemukan atau belum login!");

        SendClientMessage(targetid, 0xFF0000FF, "ADMIN: Anda telah di-kick dari server!");
        Kick(targetid);
        SendClientMessage(playerid, 0x00FF00FF, "ADMIN: Anda berhasil melakukan kick ke pemain.");
        return 1;
    }

    return 0;
}

// Fungsi strtok untuk memecah string (native tanpa sscanf plugin)
strtok(const string[], &index)
{
    new length = strlen(string);
    while ((index < length) && (string[index] <= ' '))
    {
        index++;
    }

    new offset = index;
    new result[128];
    while ((index < length) && (string[index] > ' ') && ((index - offset) < (sizeof(result) - 1)))
    {
        result[index - offset] = string[index];
        index++;
    }
    result[index - offset] = EOS;
    return result;
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

        format(PlayerInfo[playerid][pPassword], 129, "%s", inputtext);

        new File:handle = fopen(file, io_write);
        if (handle)
        {
            new writestr[256];
            format(writestr, sizeof(writestr), "Password=%s\n", PlayerInfo[playerid][pPassword]);
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Money=500\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Score=1\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "BankMoney=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Hunger=100\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Thirst=100\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Job=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Admin=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "VehModel=0\n");
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
                    else if (!strcmp(key, "Hunger", true))
                    {
                        PlayerInfo[playerid][pHunger] = strval(val);
                    }
                    else if (!strcmp(key, "Thirst", true))
                    {
                        PlayerInfo[playerid][pThirst] = strval(val);
                    }
                    else if (!strcmp(key, "Job", true))
                    {
                        PlayerInfo[playerid][pJob] = strval(val);
                    }
                    else if (!strcmp(key, "Admin", true))
                    {
                        PlayerInfo[playerid][pAdmin] = strval(val);
                    }
                    else if (!strcmp(key, "VehModel", true))
                    {
                        PlayerInfo[playerid][pVehModel] = strval(val);
                    }
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
            new str[256];
            format(str, sizeof(str), "Pekerjaan Saat Ini: %s\nSupir Taksi\nKurir Paket\nResign (Keluar)", (PlayerInfo[playerid][pJob] == 0) ? "Pengangguran" : (PlayerInfo[playerid][pJob] == 1) ? "Supir Taksi" : "Kurir Paket");
            ShowPlayerDialog(playerid, DIALOG_JOB_MENU, DIALOG_STYLE_LIST, "Lowongan Pekerjaan", str, "Pilih", "Kembali");
        }
        else if (listitem == 2) // Kendaraan
        {
            new str[256];
            if (PlayerInfo[playerid][pVehModel] == 0)
            {
                format(str, sizeof(str), "Beli Motor Faggio ($500)");
            }
            else
            {
                format(str, sizeof(str), "Panggil Kendaraan Anda");
            }
            ShowPlayerDialog(playerid, DIALOG_VEH_MENU, DIALOG_STYLE_LIST, "Kendaraan Pribadi", str, "Pilih", "Kembali");
        }
        return 1;
    }

    if (dialogid == DIALOG_BANK_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");

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
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");

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
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");

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

    if (dialogid == DIALOG_JOB_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");

        if (listitem == 0) return 1; // Info pekerjaan, bukan tombol

        if (listitem == 1) // Supir Taksi
        {
            PlayerInfo[playerid][pJob] = 1;
            SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda kini bekerja sebagai Supir Taksi.");
        }
        else if (listitem == 2) // Kurir Paket
        {
            PlayerInfo[playerid][pJob] = 2;
            SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda kini bekerja sebagai Kurir Paket.");
        }
        else if (listitem == 3) // Resign
        {
            PlayerInfo[playerid][pJob] = 0;
            SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda telah mengundurkan diri dan kini menganggur.");
        }
        return 1;
    }

    if (dialogid == DIALOG_VEH_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi", "Pilih", "Tutup");

        if (listitem == 0)
        {
            if (PlayerInfo[playerid][pVehModel] == 0) // Jika belum punya kendaraan, beli faggio (model 462)
            {
                if (GetPlayerMoney(playerid) < 500) return SendClientMessage(playerid, 0xFF0000FF, "Uang tunai Anda tidak cukup untuk membeli motor ($500)!");
                GivePlayerMoney(playerid, -500);
                PlayerInfo[playerid][pVehModel] = 462;
                SendClientMessage(playerid, 0x00FF00FF, "VEHICLE: Anda berhasil membeli motor Faggio. Gunakan menu HP untuk memanggilnya.");
            }
            else // Spawn kendaraan
            {
                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);
                // CreateVehicle(modelid, Float:x, Float:y, Float:z, Float:angle, color1, color2, respawn_delay, addsiren=0)
                new veh = CreateVehicle(PlayerInfo[playerid][pVehModel], x + 2.0, y, z, a, -1, -1, 600);
                PutPlayerInVehicle(playerid, veh, 0);
                SendClientMessage(playerid, 0x00FF00FF, "VEHICLE: Kendaraan pribadi Anda telah dikirim.");
            }
        }
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

    // Timpa ulang isi file
    new File:handleWrite = fopen(file, io_write);
    if (handleWrite)
    {
        new writestr[256];
        format(writestr, sizeof(writestr), "Password=%s\n", PlayerInfo[playerid][pPassword]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Money=%d\n", PlayerInfo[playerid][pMoney]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Score=%d\n", PlayerInfo[playerid][pScore]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "BankMoney=%d\n", PlayerInfo[playerid][pBankMoney]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Hunger=%d\n", PlayerInfo[playerid][pHunger]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Thirst=%d\n", PlayerInfo[playerid][pThirst]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Job=%d\n", PlayerInfo[playerid][pJob]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Admin=%d\n", PlayerInfo[playerid][pAdmin]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "VehModel=%d\n", PlayerInfo[playerid][pVehModel]);
        fwrite(handleWrite, writestr);

        fclose(handleWrite);
    }
}
