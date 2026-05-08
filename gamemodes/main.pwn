// ==========================================
// GTA SA-MP ROLEPLAY SERVER (MODULAR BASE)
// ==========================================

// 1. Data Utama (Include pertama agar variabel dikenal oleh modul lain)
#include "modules/data.pwn"

// 2. Modul Fitur
#include "modules/core.pwn"
#include "modules/economy.pwn"
#include "modules/job.pwn"
#include "modules/house.pwn"
#include "modules/vehicle.pwn"

main()
{
    print("\n----------------------------------");
    print(" GTA SA-MP Modular RP Server");
    print(" Base Gamemode (Loaded Successfully)");
    print("----------------------------------\n");
}

public OnGameModeInit()
{
    SetGameModeText("RP Mode v2.0 Modular");
    AddPlayerClass(0, 1958.3783, 1343.1572, 15.3746, 269.1425, 0, 0, 0, 0, 0, 0);

    House_Init();
    SetTimer("Economy_GlobalTimer", 60000, true);
    return 1;
}

public OnPlayerConnect(playerid)
{
    Core_OnPlayerConnect(playerid);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if (IsLoggedIn[playerid]) SavePlayerData(playerid);

    if (OnMission[playerid] && MissionActor[playerid] != -1)
    {
        DestroyActor(MissionActor[playerid]);
        MissionActor[playerid] = -1;
    }

    if (PlayerSpawnedVeh[playerid] != -1)
    {
        DestroyVehicle(PlayerSpawnedVeh[playerid]);
        PlayerSpawnedVeh[playerid] = -1;
    }
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if (!IsLoggedIn[playerid]) { SendClientMessage(playerid, 0xFF0000FF, "Anda harus login!"); Kick(playerid); return 1; }

    // 1. Cek apakah memiliki Last Position (Bukan 0.0 dari registrasi awal)
    if (PlayerInfo[playerid][pPosX] != 0.0 && PlayerInfo[playerid][pPosY] != 0.0)
    {
        SetPlayerPos(playerid, PlayerInfo[playerid][pPosX], PlayerInfo[playerid][pPosY], PlayerInfo[playerid][pPosZ]);
        SetPlayerInterior(playerid, PlayerInfo[playerid][pInt]);
        SetPlayerVirtualWorld(playerid, PlayerInfo[playerid][pVW]);
        SendClientMessage(playerid, 0x00FF00FF, "SERVER: Anda spawn di posisi terakhir Anda keluar.");
    }
    // 2. Jika tidak ada posisi terakhir, tapi punya rumah (Misal akun lama yang belum save posisi)
    else if (PlayerInfo[playerid][pHouseID] > 0)
    {
        new houseIdx = PlayerInfo[playerid][pHouseID] - 1;
        if (houseIdx >= 0 && houseIdx < MAX_HOUSES)
        {
            SetPlayerPos(playerid, HouseInfo[houseIdx][hExtX], HouseInfo[houseIdx][hExtY], HouseInfo[houseIdx][hExtZ]);
            SetPlayerInterior(playerid, 0);
            SetPlayerVirtualWorld(playerid, 0);
            SendClientMessage(playerid, 0x00FF00FF, "HOUSE: Anda spawn di rumah Anda.");
        }
    }
    // 3. Posisi dasar server (default) sudah ditangani oleh AddPlayerClass di OnGameModeInit
    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (Core_OnDialogResponse(playerid, dialogid, response, listitem, inputtext)) return 1;
    if (Economy_OnDialogResponse(playerid, dialogid, response, listitem, inputtext)) return 1;
    if (Job_OnDialogResponse(playerid, dialogid, response, listitem)) return 1;
    if (House_OnDialogResponse(playerid, dialogid, response, listitem, inputtext)) return 1;
    if (Vehicle_OnDialogResponse(playerid, dialogid, response, listitem)) return 1;

    if (dialogid == DIALOG_HP_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            new str[256]; format(str, sizeof(str), "Informasi Saldo (Saldo Anda: $%d)\nSimpan Uang\nTarik Uang", PlayerInfo[playerid][pBankMoney]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "Bank Mobile", str, "Pilih", "Kembali");
        }
        else if (listitem == 1)
        {
            new str[256]; format(str, sizeof(str), "Pekerjaan: %s\nSupir Taksi\nKurir Paket\nResign", (PlayerInfo[playerid][pJob] == 0) ? "Pengangguran" : (PlayerInfo[playerid][pJob] == 1) ? "Supir Taksi" : "Kurir Paket");
            ShowPlayerDialog(playerid, DIALOG_JOB_MENU, DIALOG_STYLE_LIST, "Lowongan Pekerjaan", str, "Pilih", "Kembali");
        }
        else if (listitem == 2)
        {
            new str[256]; format(str, sizeof(str), (PlayerInfo[playerid][pVehModel] == 0) ? "Beli Motor Faggio ($500)" : "Panggil Kendaraan");
            ShowPlayerDialog(playerid, DIALOG_VEH_MENU, DIALOG_STYLE_LIST, "Kendaraan Pribadi", str, "Pilih", "Kembali");
        }
        else if (listitem == 3) ShowPlayerDialog(playerid, DIALOG_MARKET_MENU, DIALOG_STYLE_LIST, "E-Commerce Market", "1x Makanan ($15)\n1x Minuman ($10)", "Beli", "Kembali");
        else if (listitem == 4)
        {
            if (PlayerInfo[playerid][pJob] == 0) return SendClientMessage(playerid, 0xFF0000FF, "Anda tidak punya pekerjaan!");
            if (OnMission[playerid]) return SendClientMessage(playerid, 0xFF0000FF, "Sedang menjalankan misi!");
            ShowPlayerDialog(playerid, DIALOG_MISSION_MENU, DIALOG_STYLE_LIST, "Misi Pekerja", "Mulai Cari Orderan/Misi", "Mulai", "Batal");
        }
        return 1;
    }
    return 0;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (Core_OnPlayerCommandText(playerid, cmdtext)) return 1;
    if (House_OnPlayerCommandText(playerid, cmdtext)) return 1;
    return 0;
}

public OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if (newkeys & KEY_YES)
    {
        if (IsLoggedIn[playerid]) ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Aplikasi Handphone", "1. Bank Mobile\n2. Lowongan Pekerjaan\n3. Kendaraan Pribadi\n4. E-Commerce Market\n5. Aplikasi Misi Pekerja", "Pilih", "Tutup");
    }
    if (newkeys & KEY_NO)
    {
        if (IsLoggedIn[playerid])
        {
            new str[256]; format(str, sizeof(str), "Makan (Miliki: %d)\nMinum (Miliki: %d)", PlayerInfo[playerid][pFood], PlayerInfo[playerid][pDrink]);
            ShowPlayerDialog(playerid, DIALOG_INV_MENU, DIALOG_STYLE_LIST, "Isi Tas", str, "Gunakan", "Tutup");
        }
    }
    if (House_OnPlayerKeyStateChange(playerid, newkeys)) return 1;
    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    Job_OnPlayerEnterCheckpoint(playerid);
    return 1;
}
