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
#define DIALOG_INV_MENU 9
#define DIALOG_MARKET_MENU 10
#define DIALOG_MISSION_MENU 11
#define DIALOG_BRANKAS_MENU 12
#define DIALOG_BRANKAS_DEPOSIT 13
#define DIALOG_BRANKAS_WITHDRAW 14

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
    pVehModel,
    pFood,
    pDrink,
    pPaydayTimer,
    pHouseID
};
new PlayerInfo[MAX_PLAYERS][pInfo];
new bool:IsLoggedIn[MAX_PLAYERS];

// Variabel Misi Sesi (Tidak di-save)
new bool:OnMission[MAX_PLAYERS];
new MissionType[MAX_PLAYERS]; // 1 = Ojol/Taksi, 2 = Kurir
new MissionStep[MAX_PLAYERS]; // 1 = Jemput, 2 = Antar
new MissionActor[MAX_PLAYERS]; // ID Actor pelanggan per player

// Variabel Penyimpanan ID Kendaraan Spawanan
new PlayerSpawnedVeh[MAX_PLAYERS] = {-1, ...};

// Lokasi valid untuk misi (X, Y, Z, Angle)
new Float:MissionPoints[][4] = {
    {1958.3783, 1343.1572, 15.3746, 269.1425}, // Contoh lokasi valid Las Venturas
    {1945.1633, 1338.4893, 10.3664, 0.0},
    {2036.0,    1344.0,    10.6719, 90.0},
    {2022.6105, 1008.2045, 10.8203, 180.0},
    {1985.4523, 1021.0594, 9.9453, 90.0}
};

// Struktur Data Rumah
enum hInfo
{
    Float:hExtX,
    Float:hExtY,
    Float:hExtZ,
    Float:hIntX,
    Float:hIntY,
    Float:hIntZ,
    hIntID,
    hPrice,
    hSafeMoney, // Saldo Brankas Uang
    hOwner[MAX_PLAYER_NAME]
};
#define MAX_HOUSES 3
new HouseInfo[MAX_HOUSES][hInfo] = {
    // Luar X, Luar Y, Luar Z, Dalam X, Dalam Y, Dalam Z, Interior ID, Harga, Saldo Brankas, Owner (Default: "None")
    {2496.0498, -1695.2388, 10.1484,  223.0439, 1289.2598, 1082.1999, 1, 5000, 0, "None"}, // Rumah 1 (Ganton)
    {2488.6658, -1645.7197, 14.0703,  223.0439, 1289.2598, 1082.1999, 1, 7500, 0, "None"}, // Rumah 2 (Ganton)
    {2444.6296, -1693.3618, 13.5186,  223.0439, 1289.2598, 1082.1999, 1, 6000, 0, "None"}  // Rumah 3 (Grove)
};

// Variabel untuk menyimpan ID Pickup dan 3DTextLabel
new HousePickup[MAX_HOUSES];
new Text3D:HouseLabel[MAX_HOUSES];

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

// Forward deklarasi strtok agar kompilator tidak eror array size
forward strtok(const string[], &index);

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
                    for(new j=0; j<strlen(readstr); j++) {
                        if(readstr[j] == '\n' || readstr[j] == '\r') readstr[j] = '\0';
                    }
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
        format(str, sizeof(str), "Owner=%s\n", HouseInfo[houseid][hOwner]);
        fwrite(handle, str);
        format(str, sizeof(str), "SafeMoney=%d\n", HouseInfo[houseid][hSafeMoney]);
        fwrite(handle, str);
        fclose(handle);
    }
}

public OnGameModeInit()
{
    // Konfigurasi dasar saat server menyala
    SetGameModeText("RP Mode v1.0");
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

    // Load Data Pemilik Rumah
    LoadHouseData();

    // Inisialisasi Sistem Rumah (Membuat Pickup dan Label)
    for(new i = 0; i < MAX_HOUSES; i++)
    {
        new str[128];
        if (strcmp(HouseInfo[i][hOwner], "None", true) == 0)
        {
            // Rumah belum terjual (Pickup Hijau 1273)
            HousePickup[i] = CreatePickup(1273, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);
            format(str, sizeof(str), "[Rumah Dijual]\nHarga: $%d\nTekan ENTER untuk membeli", HouseInfo[i][hPrice]);
        }
        else
        {
            // Rumah sudah terjual (Pickup Merah 1272)
            HousePickup[i] = CreatePickup(1272, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);
            format(str, sizeof(str), "[Rumah Pribadi]\nPemilik: %s\nTekan ENTER untuk masuk", HouseInfo[i][hOwner]);
        }
        HouseLabel[i] = Create3DTextLabel(str, 0x00FF00FF, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ] + 0.5, 20.0, 0, 0);
    }

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

            // Paycheck System (Timer bertambah 1 setiap menit)
            PlayerInfo[i][pPaydayTimer]++;
            if(PlayerInfo[i][pPaydayTimer] >= 60)
            {
                PlayerInfo[i][pPaydayTimer] = 0; // Reset waktu

                new salary = 100; // Gaji dasar pengangguran
                if(PlayerInfo[i][pJob] == 1) salary = 350; // Supir Taksi
                else if(PlayerInfo[i][pJob] == 2) salary = 300; // Kurir Paket

                // Tambahkan gaji ke Bank
                PlayerInfo[i][pBankMoney] += salary;

                SendClientMessage(i, 0x00FF00FF, "================= PAYCHECK =================");
                SendClientMessage(i, 0xFFFFFFFF, "Anda telah bermain selama 1 Jam.");

                new str[128];
                format(str, sizeof(str), "Gaji Pekerjaan: $%d (Telah ditransfer ke Saldo Bank Anda)", salary);
                SendClientMessage(i, 0xFFFFFFFF, str);

                format(str, sizeof(str), "Saldo Bank Saat Ini: $%d", PlayerInfo[i][pBankMoney]);
                SendClientMessage(i, 0xFFFFFFFF, str);
                SendClientMessage(i, 0x00FF00FF, "============================================");

                SavePlayerData(i); // Simpan otomatis setiap payday
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
    PlayerInfo[playerid][pFood] = 0;
    PlayerInfo[playerid][pDrink] = 0;
    PlayerInfo[playerid][pPaydayTimer] = 0;
    PlayerInfo[playerid][pHouseID] = 0;
    format(PlayerInfo[playerid][pPassword], 129, "");

    OnMission[playerid] = false;
    MissionType[playerid] = 0;
    MissionStep[playerid] = 0;
    MissionActor[playerid] = -1;
    DisablePlayerCheckpoint(playerid);

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

    // Pembersihan Actor jika pemain keluar saat misi
    if (OnMission[playerid] && MissionActor[playerid] != -1)
    {
        DestroyActor(MissionActor[playerid]);
        MissionActor[playerid] = -1;
    }

    // Pembersihan kendaraan yang dispawn pemain
    if (PlayerSpawnedVeh[playerid] != -1)
    {
        DestroyVehicle(PlayerSpawnedVeh[playerid]);
        PlayerSpawnedVeh[playerid] = -1;
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

    // Spawn di rumah jika punya
    if (PlayerInfo[playerid][pHouseID] > 0)
    {
        new houseIdx = PlayerInfo[playerid][pHouseID] - 1;
        if (houseIdx >= 0 && houseIdx < MAX_HOUSES)
        {
            SetPlayerPos(playerid, HouseInfo[houseIdx][hExtX], HouseInfo[houseIdx][hExtY], HouseInfo[houseIdx][hExtZ]);
            SetPlayerInterior(playerid, 0); // Di luar rumah
            SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Anda spawn di depan rumah Anda.");
        }
    }

    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (strcmp(cmdtext, "/tidur", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;

        // Cek apakah pemain berada di dalam rumah miliknya
        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid >= 0 && hid < MAX_HOUSES)
        {
            if (IsPlayerInRangeOfPoint(playerid, 10.0, HouseInfo[hid][hIntX], HouseInfo[hid][hIntY], HouseInfo[hid][hIntZ]) && GetPlayerInterior(playerid) == HouseInfo[hid][hIntID] && GetPlayerVirtualWorld(playerid) == (hid + 1))
            {
                SetPlayerHealth(playerid, 100.0);
                PlayerInfo[playerid][pHunger] = 100;
                PlayerInfo[playerid][pThirst] = 100;
                SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Anda beristirahat di kasur. Darah, Lapar, dan Haus Anda terisi penuh.");
                return 1;
            }
        }
        SendClientMessage(playerid, 0xFF0000FF, "HOUSE: Anda harus berada di dalam rumah milik Anda untuk tidur!");
        return 1;
    }

    if (strcmp(cmdtext, "/brankas", true) == 0)
    {
        if (!IsLoggedIn[playerid]) return 1;

        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid >= 0 && hid < MAX_HOUSES)
        {
            if (IsPlayerInRangeOfPoint(playerid, 10.0, HouseInfo[hid][hIntX], HouseInfo[hid][hIntY], HouseInfo[hid][hIntZ]) && GetPlayerInterior(playerid) == HouseInfo[hid][hIntID] && GetPlayerVirtualWorld(playerid) == (hid + 1))
            {
                new str[256];
                format(str, sizeof(str), "Brankas Rumah\nSaldo: $%d\n\n1. Simpan Uang\n2. Tarik Uang", HouseInfo[hid][hSafeMoney]);
                ShowPlayerDialog(playerid, DIALOG_BRANKAS_MENU, DIALOG_STYLE_LIST, "Brankas", str, "Pilih", "Tutup");
                return 1;
            }
        }
        SendClientMessage(playerid, 0xFF0000FF, "HOUSE: Anda harus berada di dalam rumah milik Anda untuk membuka brankas!");
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

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    // Cek Tombol Y (KEY_YES) untuk HP
    if (newkeys & KEY_YES)
    {
        if (IsLoggedIn[playerid])
        {
            ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi\n4. E-Commerce Market\n5. Aplikasi Misi Pekerja", "Pilih", "Tutup");
        }
    }

    // Cek Tombol N (KEY_NO) untuk Inventory Tas
    if (newkeys & KEY_NO)
    {
        if (IsLoggedIn[playerid])
        {
            new str[256];
            format(str, sizeof(str), "Makan (Miliki: %d)\nMinum (Miliki: %d)", PlayerInfo[playerid][pFood], PlayerInfo[playerid][pDrink]);
            ShowPlayerDialog(playerid, DIALOG_INV_MENU, DIALOG_STYLE_LIST, "Isi Tas (Inventory)", str, "Gunakan", "Tutup");
        }
    }

    // Cek Tombol ENTER (KEY_SECONDARY_ATTACK) untuk Interaksi Rumah
    if (newkeys & KEY_SECONDARY_ATTACK)
    {
        if (IsLoggedIn[playerid])
        {
            new Float:px, Float:py, Float:pz;
            GetPlayerPos(playerid, px, py, pz);

            for(new i = 0; i < MAX_HOUSES; i++)
            {
                // Jarak dengan Eksterior (Luar Rumah)
                if (IsPlayerInRangeOfPoint(playerid, 3.0, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ]))
                {
                    if (strcmp(HouseInfo[i][hOwner], "None", true) == 0) // Jika belum ada yang punya
                    {
                        if (PlayerInfo[playerid][pHouseID] != 0) return SendClientMessage(playerid, 0xFF0000FF, "Anda sudah memiliki rumah!");
                        if (GetPlayerMoney(playerid) < HouseInfo[i][hPrice]) return SendClientMessage(playerid, 0xFF0000FF, "Uang tunai Anda tidak cukup untuk membeli rumah ini!");

                        // Proses Beli
                        GivePlayerMoney(playerid, -HouseInfo[i][hPrice]);
                        PlayerInfo[playerid][pHouseID] = i + 1; // Simpan ID (index + 1)

                        new name[MAX_PLAYER_NAME];
                        GetPlayerName(playerid, name, sizeof(name));
                        format(HouseInfo[i][hOwner], MAX_PLAYER_NAME, "%s", name);

                        // Update Pickup & Label
                        DestroyPickup(HousePickup[i]);
                        HousePickup[i] = CreatePickup(1272, 1, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ], -1);

                        new str[128];
                        format(str, sizeof(str), "[Rumah Pribadi]\nPemilik: %s\nTekan ENTER untuk masuk", HouseInfo[i][hOwner]);
                        Update3DTextLabelText(HouseLabel[i], 0x00FF00FF, str);

                        SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Selamat! Anda telah membeli rumah ini.");
                        SaveHouseData(i);
                        SavePlayerData(playerid);
                    }
                    else // Jika sudah ada yang punya
                    {
                        new name[MAX_PLAYER_NAME];
                        GetPlayerName(playerid, name, sizeof(name));

                        if (strcmp(HouseInfo[i][hOwner], name, true) == 0) // Milik sendiri
                        {
                            SetPlayerPos(playerid, HouseInfo[i][hIntX], HouseInfo[i][hIntY], HouseInfo[i][hIntZ]);
                            SetPlayerInterior(playerid, HouseInfo[i][hIntID]);
                            SetPlayerVirtualWorld(playerid, i + 1); // Agar tidak bertabrakan interior dengan pemain lain
                            SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Anda masuk ke dalam rumah Anda. (Tekan ENTER untuk keluar)");
                            SendClientMessage(playerid, 0x00FF00FF, "Ketik /tidur untuk istirahat, atau /brankas untuk menyimpan/mengambil uang.");
                        }
                        else
                        {
                            SendClientMessage(playerid, 0xFF0000FF, "Rumah ini terkunci milik orang lain!");
                        }
                    }
                    return 1;
                }

                // Jarak dengan Interior (Dalam Rumah, mau keluar)
                if (IsPlayerInRangeOfPoint(playerid, 3.0, HouseInfo[i][hIntX], HouseInfo[i][hIntY], HouseInfo[i][hIntZ]) && GetPlayerInterior(playerid) == HouseInfo[i][hIntID] && GetPlayerVirtualWorld(playerid) == (i + 1))
                {
                    SetPlayerPos(playerid, HouseInfo[i][hExtX], HouseInfo[i][hExtY], HouseInfo[i][hExtZ]);
                    SetPlayerInterior(playerid, 0); // Kembali ke dunia luar
                    SetPlayerVirtualWorld(playerid, 0);
                    return 1;
                }
            }
        }
    }

    return 1;
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

            format(writestr, sizeof(writestr), "Food=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "Drink=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "PaydayTimer=0\n");
            fwrite(handle, writestr);

            format(writestr, sizeof(writestr), "HouseID=0\n");
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
                    else if (!strcmp(key, "Food", true))
                    {
                        PlayerInfo[playerid][pFood] = strval(val);
                    }
                    else if (!strcmp(key, "Drink", true))
                    {
                        PlayerInfo[playerid][pDrink] = strval(val);
                    }
                    else if (!strcmp(key, "PaydayTimer", true))
                    {
                        PlayerInfo[playerid][pPaydayTimer] = strval(val);
                    }
                    else if (!strcmp(key, "HouseID", true))
                    {
                        PlayerInfo[playerid][pHouseID] = strval(val);
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
        else if (listitem == 3) // E-Commerce Market
        {
            ShowPlayerDialog(playerid, DIALOG_MARKET_MENU, DIALOG_STYLE_LIST, "E-Commerce Market", "1x Makanan ($15)\n1x Minuman ($10)", "Beli", "Kembali");
        }
        else if (listitem == 4) // Misi Pekerja
        {
            if (PlayerInfo[playerid][pJob] == 0) return SendClientMessage(playerid, 0xFF0000FF, "Anda sedang tidak memiliki pekerjaan!");
            if (OnMission[playerid]) return SendClientMessage(playerid, 0xFF0000FF, "Anda sedang menjalankan misi!");

            ShowPlayerDialog(playerid, DIALOG_MISSION_MENU, DIALOG_STYLE_LIST, "Aplikasi Misi Pekerja", "Mulai Cari Orderan/Misi", "Mulai", "Batal");
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
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi\n4. E-Commerce Market\n5. Aplikasi Misi Pekerja", "Pilih", "Tutup");

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
                // Hapus kendaraan lama jika ada untuk mencegah memory leak
                if (PlayerSpawnedVeh[playerid] != -1)
                {
                    DestroyVehicle(PlayerSpawnedVeh[playerid]);
                }

                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);
                new veh = CreateVehicle(PlayerInfo[playerid][pVehModel], x + 2.0, y, z, a, -1, -1, 600);
                PlayerSpawnedVeh[playerid] = veh; // Simpan ID

                PutPlayerInVehicle(playerid, veh, 0);
                SendClientMessage(playerid, 0x00FF00FF, "VEHICLE: Kendaraan pribadi Anda telah dikirim.");
            }
        }
        return 1;
    }

    if (dialogid == DIALOG_MARKET_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi\n4. E-Commerce Market\n5. Aplikasi Misi Pekerja", "Pilih", "Tutup");

        if (listitem == 0) // Beli Makanan
        {
            if (GetPlayerMoney(playerid) < 15) return SendClientMessage(playerid, 0xFF0000FF, "Anda butuh $15 untuk membeli Makanan!");
            GivePlayerMoney(playerid, -15);
            PlayerInfo[playerid][pFood]++;
            SendClientMessage(playerid, 0x00FF00FF, "MARKET: Berhasil membeli Makanan, masuk ke dalam tas.");
        }
        else if (listitem == 1) // Beli Minuman
        {
            if (GetPlayerMoney(playerid) < 10) return SendClientMessage(playerid, 0xFF0000FF, "Anda butuh $10 untuk membeli Minuman!");
            GivePlayerMoney(playerid, -10);
            PlayerInfo[playerid][pDrink]++;
            SendClientMessage(playerid, 0x00FF00FF, "MARKET: Berhasil membeli Minuman, masuk ke dalam tas.");
        }
        return 1;
    }

    if (dialogid == DIALOG_INV_MENU)
    {
        if (!response) return 1;

        if (listitem == 0) // Konsumsi Makanan
        {
            if (PlayerInfo[playerid][pFood] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda tidak memiliki makanan di tas!");
            PlayerInfo[playerid][pFood]--;
            PlayerInfo[playerid][pHunger] += 50;
            if (PlayerInfo[playerid][pHunger] > 100) PlayerInfo[playerid][pHunger] = 100;
            SendClientMessage(playerid, 0x00FF00FF, "INVENTORY: Anda memakan sebungkus makanan. Rasa lapar berkurang.");
        }
        else if (listitem == 1) // Konsumsi Minuman
        {
            if (PlayerInfo[playerid][pDrink] < 1) return SendClientMessage(playerid, 0xFF0000FF, "Anda tidak memiliki minuman di tas!");
            PlayerInfo[playerid][pDrink]--;
            PlayerInfo[playerid][pThirst] += 50;
            if (PlayerInfo[playerid][pThirst] > 100) PlayerInfo[playerid][pThirst] = 100;
            SendClientMessage(playerid, 0x00FF00FF, "INVENTORY: Anda meminum sebotol air. Rasa haus berkurang.");
        }
        return 1;
    }

    if (dialogid == DIALOG_BRANKAS_MENU) // Brankas Menu
    {
        if (!response) return 1;
        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;

        if (listitem == 0) // Info Saldo (Kembali ke dialog)
        {
            new str[256];
            format(str, sizeof(str), "Brankas Rumah\nSaldo: $%d\n\n1. Simpan Uang\n2. Tarik Uang", HouseInfo[hid][hSafeMoney]);
            ShowPlayerDialog(playerid, DIALOG_BRANKAS_MENU, DIALOG_STYLE_LIST, "Brankas", str, "Pilih", "Tutup");
        }
        else if (listitem == 1) // Deposit
        {
            ShowPlayerDialog(playerid, DIALOG_BRANKAS_DEPOSIT, DIALOG_STYLE_INPUT, "Simpan Uang ke Brankas", "Masukkan jumlah uang yang ingin disimpan:", "Simpan", "Batal");
        }
        else if (listitem == 2) // Withdraw
        {
            ShowPlayerDialog(playerid, DIALOG_BRANKAS_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang dari Brankas", "Masukkan jumlah uang yang ingin ditarik:", "Tarik", "Batal");
        }
        return 1;
    }

    if (dialogid == DIALOG_BRANKAS_DEPOSIT) // Brankas Deposit
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");
        if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, 0xFF0000FF, "Uang tunai Anda tidak cukup!");

        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;

        GivePlayerMoney(playerid, -amount);
        HouseInfo[hid][hSafeMoney] += amount;
        SaveHouseData(hid);

        new msg[128];
        format(msg, sizeof(msg), "HOUSE: Anda menyimpan $%d ke dalam brankas. Saldo saat ini: $%d", amount, HouseInfo[hid][hSafeMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        return 1;
    }

    if (dialogid == DIALOG_BRANKAS_WITHDRAW) // Brankas Withdraw
    {
        if (!response) return 1;
        new amount = strval(inputtext);
        if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Jumlah tidak valid!");

        new hid = PlayerInfo[playerid][pHouseID] - 1;
        if (hid < 0 || hid >= MAX_HOUSES) return 1;
        if (HouseInfo[hid][hSafeMoney] < amount) return SendClientMessage(playerid, 0xFF0000FF, "Saldo brankas Anda tidak cukup!");

        HouseInfo[hid][hSafeMoney] -= amount;
        GivePlayerMoney(playerid, amount);
        SaveHouseData(hid);

        new msg[128];
        format(msg, sizeof(msg), "HOUSE: Anda menarik $%d dari brankas. Saldo tersisa: $%d", amount, HouseInfo[hid][hSafeMoney]);
        SendClientMessage(playerid, 0x00FF00FF, msg);
        return 1;
    }

    if (dialogid == DIALOG_MISSION_MENU)
    {
        if (!response) return ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi\n4. E-Commerce Market\n5. Aplikasi Misi Pekerja", "Pilih", "Tutup");

        if (listitem == 0) // Mulai Misi
        {
            if (PlayerInfo[playerid][pJob] == 1 && !IsPlayerInAnyVehicle(playerid))
            {
                return SendClientMessage(playerid, 0xFF0000FF, "JOB: Anda harus berada di dalam kendaraan (Taksi/Ojol) untuk mencari penumpang!");
            }

            OnMission[playerid] = true;
            MissionType[playerid] = PlayerInfo[playerid][pJob]; // 1 = Taksi, 2 = Kurir
            MissionStep[playerid] = 1; // Mulai dari fase 1 (Jemput Pelanggan / Antar Paket ke Pelanggan)

            // Pilih lokasi random dari MissionPoints
            new rand = random(sizeof(MissionPoints));
            new Float:rx = MissionPoints[rand][0];
            new Float:ry = MissionPoints[rand][1];
            new Float:rz = MissionPoints[rand][2];
            new Float:ra = MissionPoints[rand][3];

            SetPlayerCheckpoint(playerid, rx, ry, rz, 4.0);

            // Spawn NPC/Actor di lokasi
            new skin = 10 + random(50); // Skin NPC Acak
            MissionActor[playerid] = CreateActor(skin, rx, ry, rz, ra);

            if (MissionType[playerid] == 1)
            {
                SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda mendapat orderan penumpang! Jemput penumpang NPC di lokasi merah (Minimap).");
            }
            else if (MissionType[playerid] == 2)
            {
                SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda mendapat orderan pengiriman paket! Antar paket ke NPC pelanggan di lokasi merah.");
            }
        }
        return 1;
    }

    return 0;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if (OnMission[playerid])
    {
        if (MissionType[playerid] == 1) // TAKSI / OJOL
        {
            if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "JOB: Anda harus tetap di dalam kendaraan untuk melayani penumpang!");

            if (MissionStep[playerid] == 1) // Fase Jemput Pelanggan (Ada NPC)
            {
                DisablePlayerCheckpoint(playerid);
                if (MissionActor[playerid] != -1)
                {
                    DestroyActor(MissionActor[playerid]);
                    MissionActor[playerid] = -1;
                }

                MissionStep[playerid] = 2; // Lanjut ke fase antar

                // Beri lokasi tujuan (baru)
                new rand = random(sizeof(MissionPoints));
                new Float:rx = MissionPoints[rand][0];
                new Float:ry = MissionPoints[rand][1];
                new Float:rz = MissionPoints[rand][2];
                SetPlayerCheckpoint(playerid, rx, ry, rz, 4.0);

                SendClientMessage(playerid, 0x00FF00FF, "JOB: Penumpang telah naik ke kendaraan! Antar ke lokasi merah (Minimap).");
            }
            else if (MissionStep[playerid] == 2) // Fase Antar ke Tujuan
            {
                DisablePlayerCheckpoint(playerid);
                OnMission[playerid] = false;
                MissionStep[playerid] = 0;
                MissionType[playerid] = 0;

                new reward = 80 + random(70); // Gaji Taksi $80 - $150
                GivePlayerMoney(playerid, reward);

                new str[128];
                format(str, sizeof(str), "JOB: Penumpang telah sampai di tujuan. Anda dibayar tunai sebesar $%d!", reward);
                SendClientMessage(playerid, 0x00FF00FF, str);
            }
        }
        else if (MissionType[playerid] == 2) // KURIR PAKET
        {
            if (IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "JOB: Anda harus turun dari kendaraan untuk memberikan paket ke pelanggan!");

            if (MissionStep[playerid] == 1) // Bertemu Pelanggan NPC
            {
                DisablePlayerCheckpoint(playerid);
                if (MissionActor[playerid] != -1)
                {
                    DestroyActor(MissionActor[playerid]);
                    MissionActor[playerid] = -1;
                }

                OnMission[playerid] = false;
                MissionStep[playerid] = 0;
                MissionType[playerid] = 0;

                new reward = 50 + random(50); // Gaji Kurir $50 - $100
                GivePlayerMoney(playerid, reward);

                new str[128];
                format(str, sizeof(str), "JOB: Paket berhasil diserahkan ke pelanggan. Anda menerima pembayaran $%d!", reward);
                SendClientMessage(playerid, 0x00FF00FF, str);
            }
        }
    }
    return 1;
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

        format(writestr, sizeof(writestr), "Food=%d\n", PlayerInfo[playerid][pFood]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "Drink=%d\n", PlayerInfo[playerid][pDrink]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "PaydayTimer=%d\n", PlayerInfo[playerid][pPaydayTimer]);
        fwrite(handleWrite, writestr);

        format(writestr, sizeof(writestr), "HouseID=%d\n", PlayerInfo[playerid][pHouseID]);
        fwrite(handleWrite, writestr);

        fclose(handleWrite);
    }
}
