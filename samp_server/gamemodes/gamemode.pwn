#include <a_samp>
#include <zcmd>
#include <file>
#include <core>
#include <float>

native Float:floatstr(const string[]);

// --- Definitions ---
#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_RED   0xFF0000FF
#define COLOR_GREEN 0x00FF00FF
#define COLOR_YELLOW 0xFFFF00FF

#define DIALOG_REGISTER 1
#define DIALOG_LOGIN    2
#define DIALOG_BANK_MENU 3
#define DIALOG_BANK_DEPOSIT 4
#define DIALOG_BANK_WITHDRAW 5
#define DIALOG_VEHICLE_MARKET 6
#define DIALOG_HP_MENU 7

// --- Enums & Variables ---
enum pInfo
{
    pPassword[129],
    pMoney,
    pBank,
    pHunger,
    pThirst,
    pVehModel,
    Float:pVehX,
    Float:pVehY,
    Float:pVehZ,
    Float:pVehA,
    pLogged
}
new PlayerInfo[MAX_PLAYERS][pInfo];
new PlayerVehicle[MAX_PLAYERS];

new Text:PhoneTD[2]; // Textdraw handphone (Kotak dan Layar)
new bool:PhoneActive[MAX_PLAYERS];
new NeedsTimer;

// Job Variables
new bool:HasPackage[MAX_PLAYERS];
new Float:DropOffPoints[3][3] = {
    {2439.46, -1227.67, 24.87}, // East LS
    {2253.94, -1371.39, 23.99}, // Jefferson
    {2196.22, -1674.31, 15.08}  // Idlewood
};

// Ojol Job Variables
new OjolState[MAX_PLAYERS]; // 0: Idle, 1: Jemput, 2: Antar
new OjolActor[MAX_PLAYERS] = {-1, ...};
new Float:OjolPickup[3][3] = {
    {2452.93, -1661.12, 13.30},
    {2244.60, -1665.26, 15.47},
    {2095.34, -1698.81, 13.51}
};

// --- Forwards ---
forward DecreaseNeeds();
forward LoadAccount(playerid, const password[]);
forward SaveAccount(playerid);
forward StripNewLine(string[]);

// --- Callbacks ---

main()
{
    print("\n----------------------------------");
    print(" Realita Server (Non-Plugin)");
    print(" By Jules (Assistant)");
    print("----------------------------------\n");
}

public OnGameModeInit()
{
    SetGameModeText("Realita Roleplay");

    // Timer kebutuhan (Lapar & Haus) setiap 1 Menit (60000 ms)
    NeedsTimer = SetTimer("DecreaseNeeds", 60000, true);

    // Disable default nametags or settings if needed
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    SetNameTagDrawDistance(40.0);
    EnableStuntBonusForAll(0);
    DisableInteriorEnterExits();

    // Setup Handphone Textdraws
    PhoneTD[0] = TextDrawCreate(500.000000, 250.000000, "LD_SPAC:white");
    TextDrawLetterSize(PhoneTD[0], 0.000000, 0.000000);
    TextDrawTextSize(PhoneTD[0], 100.000000, 150.000000);
    TextDrawAlignment(PhoneTD[0], 1);
    TextDrawColor(PhoneTD[0], 255); // Black background
    TextDrawUseBox(PhoneTD[0], true);
    TextDrawBoxColor(PhoneTD[0], 255);
    TextDrawSetShadow(PhoneTD[0], 0);
    TextDrawSetOutline(PhoneTD[0], 0);
    TextDrawFont(PhoneTD[0], 4);

    PhoneTD[1] = TextDrawCreate(505.000000, 255.000000, "LD_SPAC:white");
    TextDrawLetterSize(PhoneTD[1], 0.000000, 0.000000);
    TextDrawTextSize(PhoneTD[1], 90.000000, 140.000000);
    TextDrawAlignment(PhoneTD[1], 1);
    TextDrawColor(PhoneTD[1], -1); // White screen
    TextDrawUseBox(PhoneTD[1], true);
    TextDrawBoxColor(PhoneTD[1], -1);
    TextDrawSetShadow(PhoneTD[1], 0);
    TextDrawSetOutline(PhoneTD[1], 0);
    TextDrawFont(PhoneTD[1], 4);

    return 1;
}

public OnGameModeExit()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerInfo[i][pLogged])
        {
            SaveAccount(i);
        }
    }

    TextDrawDestroy(PhoneTD[0]);
    TextDrawDestroy(PhoneTD[1]);
    KillTimer(NeedsTimer);

    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerInfo[playerid][pMoney] = 0;
    PlayerInfo[playerid][pBank] = 0;
    PlayerInfo[playerid][pHunger] = 100;
    PlayerInfo[playerid][pVehModel] = 0;
    PlayerInfo[playerid][pThirst] = 100;
    PlayerInfo[playerid][pLogged] = 0;
    PhoneActive[playerid] = false;
    HasPackage[playerid] = false;
    PlayerVehicle[playerid] = -1;
    OjolState[playerid] = 0;
    if(OjolActor[playerid] != -1)
    {
        DestroyActor(OjolActor[playerid]);
        OjolActor[playerid] = -1;
    }

    new name[MAX_PLAYER_NAME], file[128];
    GetPlayerName(playerid, name, sizeof(name));
    format(file, sizeof(file), "Accounts/%s.ini", name);

    if(fexist(file))
    {
        ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Akun Anda terdaftar.\nSilakan masukkan password Anda:", "Login", "Keluar");
    }
    else
    {
        ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Akun Anda belum terdaftar.\nSilakan buat password baru:", "Daftar", "Keluar");
    }

    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    if(PlayerInfo[playerid][pLogged])
    {
        SaveAccount(playerid);
    }

    if(PlayerVehicle[playerid] != -1)
    {
        DestroyVehicle(PlayerVehicle[playerid]);
        PlayerVehicle[playerid] = -1;
    }

    if(OjolActor[playerid] != -1)
    {
        DestroyActor(OjolActor[playerid]);
        OjolActor[playerid] = -1;
    }

    return 1;
}

public OnPlayerSpawn(playerid)
{
    if(!PlayerInfo[playerid][pLogged])
    {
        SendClientMessage(playerid, COLOR_RED, "Anda harus login terlebih dahulu!");
        Kick(playerid);
        return 1;
    }

    SetPlayerSkin(playerid, 0);
    SetPlayerPos(playerid, 2495.33, -1669.75, 13.33);
    SetPlayerFacingAngle(playerid, 0.0);
    SetPlayerInterior(playerid, 0);
    SetPlayerVirtualWorld(playerid, 0);
    SetCameraBehindPlayer(playerid);

    SendClientMessage(playerid, COLOR_YELLOW, "Hint: Anda bisa bekerja sebagai kurir (/ambilpaket) atau /ojol jika ada kendaraan.");

    // Spawn Player Vehicle if exists
    if(PlayerInfo[playerid][pVehModel] != 0 && PlayerVehicle[playerid] == -1)
    {
        PlayerVehicle[playerid] = CreateVehicle(PlayerInfo[playerid][pVehModel], PlayerInfo[playerid][pVehX], PlayerInfo[playerid][pVehY], PlayerInfo[playerid][pVehZ], PlayerInfo[playerid][pVehA], -1, -1, 0);
        new msg[128];
        format(msg, sizeof(msg), "Kendaraan anda di-spawn di lokasi parkir terakhir.");
        SendClientMessage(playerid, COLOR_YELLOW, msg);
    }

    return 1;
}

public OnPlayerEnterCheckpoint(playerid)
{
    if(HasPackage[playerid])
    {
        HasPackage[playerid] = false;
        DisablePlayerCheckpoint(playerid);

        new reward = 100 + random(100); // 100 - 199
        GivePlayerMoney(playerid, reward);

        new msg[128];
        format(msg, sizeof(msg), "Kerja bagus! Anda telah mengantar paket dan mendapatkan $%d.", reward);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        PlayerInfo[playerid][pHunger] -= 5;
        PlayerInfo[playerid][pThirst] -= 5;
        if(PlayerInfo[playerid][pHunger] < 0) PlayerInfo[playerid][pHunger] = 0;
        if(PlayerInfo[playerid][pThirst] < 0) PlayerInfo[playerid][pThirst] = 0;
        return 1;
    }

    if(OjolState[playerid] == 1) // Sampai di titik jemput
    {
        OjolState[playerid] = 2; // Ganti ke fase antar
        if(OjolActor[playerid] != -1)
        {
            DestroyActor(OjolActor[playerid]);
            OjolActor[playerid] = -1;
        }

        new rand = random(sizeof(DropOffPoints));
        SetPlayerCheckpoint(playerid, DropOffPoints[rand][0], DropOffPoints[rand][1], DropOffPoints[rand][2], 4.0);

        SendClientMessage(playerid, COLOR_YELLOW, "Pelanggan telah naik! Antarkan ke titik merah (tujuan).");
        return 1;
    }
    else if(OjolState[playerid] == 2) // Sampai di titik antar
    {
        OjolState[playerid] = 0;
        DisablePlayerCheckpoint(playerid);

        new reward = 150 + random(150); // 150 - 299
        GivePlayerMoney(playerid, reward);

        new msg[128];
        format(msg, sizeof(msg), "Perjalanan selesai. Anda menerima ongkos sebesar $%d.", reward);
        SendClientMessage(playerid, COLOR_GREEN, msg);

        PlayerInfo[playerid][pHunger] -= 5;
        PlayerInfo[playerid][pThirst] -= 5;
        if(PlayerInfo[playerid][pHunger] < 0) PlayerInfo[playerid][pHunger] = 0;
        if(PlayerInfo[playerid][pThirst] < 0) PlayerInfo[playerid][pThirst] = 0;
        return 1;
    }

    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if(dialogid == DIALOG_REGISTER)
    {
        if(!response) return Kick(playerid);

        if(strlen(inputtext) < 3)
        {
            ShowPlayerDialog(playerid, DIALOG_REGISTER, DIALOG_STYLE_INPUT, "Register", "Password terlalu pendek!\nSilakan buat password baru:", "Daftar", "Keluar");
            return 1;
        }

        new name[MAX_PLAYER_NAME], file[128];
        GetPlayerName(playerid, name, sizeof(name));
        format(file, sizeof(file), "Accounts/%s.ini", name);

        new File:f = fopen(file, io_write);
        if(f)
        {
            new line[256];
            format(line, sizeof(line), "Password=%s\nMoney=500\nBank=0\nHunger=100\nThirst=100\nVehModel=0\nVehX=0.0\nVehY=0.0\nVehZ=0.0\nVehA=0.0\n", inputtext);
            fwrite(f, line);
            fclose(f);

            SendClientMessage(playerid, COLOR_GREEN, "Registrasi berhasil! Anda sekarang login.");
            PlayerInfo[playerid][pLogged] = 1;
            PlayerInfo[playerid][pMoney] = 500;
            PlayerInfo[playerid][pBank] = 0;
            PlayerInfo[playerid][pHunger] = 100;
            PlayerInfo[playerid][pThirst] = 100;
            PlayerInfo[playerid][pVehModel] = 0;
            format(PlayerInfo[playerid][pPassword], 129, "%s", inputtext);

            GivePlayerMoney(playerid, 500);
            SpawnPlayer(playerid);
        }
        else
        {
            SendClientMessage(playerid, COLOR_RED, "ERROR: Gagal membuat akun (cek folder scriptfiles/Accounts).");
            Kick(playerid);
        }
        return 1;
    }

    if(dialogid == DIALOG_LOGIN)
    {
        if(!response) return Kick(playerid);

        if(strlen(inputtext) < 1)
        {
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Silakan masukkan password Anda:", "Login", "Keluar");
            return 1;
        }

        LoadAccount(playerid, inputtext);
        return 1;
    }

    if(dialogid == DIALOG_BANK_MENU)
    {
        if(!response)
        {
            // Kembali ke Menu HP
            ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Handphone App", "1. M-Banking\n2. Toko Kendaraan Online\n3. Aplikasi Ojol\n4. Tutup Handphone", "Pilih", "Tutup");
            return 1;
        }

        if(listitem == 0) // Cek Saldo
        {
            new msg[128];
            format(msg, sizeof(msg), "Saldo Bank Anda saat ini: $%d", PlayerInfo[playerid][pBank]);
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_MSGBOX, "M-Banking", msg, "Kembali", "");
        }
        else if(listitem == 1) // Setor
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_DEPOSIT, DIALOG_STYLE_INPUT, "Setor Uang", "Masukkan jumlah uang yang ingin disetor:", "Setor", "Batal");
        }
        else if(listitem == 2) // Tarik
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_WITHDRAW, DIALOG_STYLE_INPUT, "Tarik Uang", "Masukkan jumlah uang yang ingin ditarik:", "Tarik", "Batal");
        }
        return 1;
    }

    if(dialogid == DIALOG_BANK_DEPOSIT)
    {
        if(!response)
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "M-Banking", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Kembali");
            return 1;
        }
        new amount = strval(inputtext);
        if(amount < 1) return SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, COLOR_RED, "Uang cash Anda tidak cukup!");

        GivePlayerMoney(playerid, -amount);
        PlayerInfo[playerid][pBank] += amount;

        new msg[128];
        format(msg, sizeof(msg), "Anda telah menyetor $%d. Saldo saat ini: $%d", amount, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SaveAccount(playerid);

        ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "M-Banking", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Kembali");
        return 1;
    }

    if(dialogid == DIALOG_BANK_WITHDRAW)
    {
        if(!response)
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "M-Banking", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Kembali");
            return 1;
        }
        new amount = strval(inputtext);
        if(amount < 1) return SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(PlayerInfo[playerid][pBank] < amount) return SendClientMessage(playerid, COLOR_RED, "Saldo bank Anda tidak cukup!");

        PlayerInfo[playerid][pBank] -= amount;
        GivePlayerMoney(playerid, amount);

        new msg[128];
        format(msg, sizeof(msg), "Anda telah menarik $%d. Saldo saat ini: $%d", amount, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SaveAccount(playerid);

        ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "M-Banking", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Kembali");
        return 1;
    }

    if(dialogid == DIALOG_VEHICLE_MARKET)
    {
        if(!response)
        {
            // Kembali ke Menu HP
            ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Handphone App", "1. M-Banking\n2. Toko Kendaraan Online\n3. Aplikasi Ojol\n4. Tutup Handphone", "Pilih", "Tutup");
            return 1;
        }
        new model = 0, cost = 0;
        new vname[32];
        if(listitem == 0) { model = 462; cost = 300; format(vname, sizeof(vname), "Faggio"); } // Faggio
        else if(listitem == 1) { model = 468; cost = 800; format(vname, sizeof(vname), "Sanchez"); } // Sanchez
        else if(listitem == 2) { model = 405; cost = 1500; format(vname, sizeof(vname), "Sentinel"); } // Sentinel
        else if(listitem == 3) { model = 566; cost = 1200; format(vname, sizeof(vname), "Tahoma"); } // Tahoma

        if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, COLOR_RED, "Uang Anda tidak cukup!");

        if(PlayerVehicle[playerid] != -1)
        {
            DestroyVehicle(PlayerVehicle[playerid]);
            PlayerVehicle[playerid] = -1;
        }

        GivePlayerMoney(playerid, -cost);
        PlayerInfo[playerid][pVehModel] = model;

        new Float:x, Float:y, Float:z, Float:a;
        GetPlayerPos(playerid, x, y, z);
        GetPlayerFacingAngle(playerid, a);

        PlayerInfo[playerid][pVehX] = x;
        PlayerInfo[playerid][pVehY] = y;
        PlayerInfo[playerid][pVehZ] = z;
        PlayerInfo[playerid][pVehA] = a;

        PlayerVehicle[playerid] = CreateVehicle(model, x, y, z, a, -1, -1, 0);
        PutPlayerInVehicle(playerid, PlayerVehicle[playerid], 0);

        new msg[128];
        format(msg, sizeof(msg), "Anda telah membeli %s seharga $%d.", vname, cost);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SaveAccount(playerid);

        // Return to HP menu after buy
        ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Handphone App", "1. M-Banking\n2. Toko Kendaraan Online\n3. Aplikasi Ojol\n4. Tutup Handphone", "Pilih", "Tutup");
        return 1;
    }

    if(dialogid == DIALOG_HP_MENU)
    {
        if(!response)
        {
            // Tutup HP via button
            TextDrawHideForPlayer(playerid, PhoneTD[0]);
            TextDrawHideForPlayer(playerid, PhoneTD[1]);
            PhoneActive[playerid] = false;
            SendClientMessage(playerid, COLOR_YELLOW, "* Anda menyimpan handphone.");
            return 1;
        }

        if(listitem == 0) // M-Banking
        {
            ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "M-Banking", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Kembali");
        }
        else if(listitem == 1) // Toko Kendaraan Online
        {
            ShowPlayerDialog(playerid, DIALOG_VEHICLE_MARKET, DIALOG_STYLE_LIST, "Dealership App", "Faggio (Motor) - $300\nSanchez (Motor) - $800\nSentinel (Mobil) - $1500\nTahoma (Mobil) - $1200", "Beli", "Kembali");
        }
        else if(listitem == 2) // Aplikasi Ojol
        {
            if(!IsPlayerInAnyVehicle(playerid))
            {
                SendClientMessage(playerid, COLOR_RED, "Anda harus berada di dalam kendaraan (motor/mobil) untuk menerima orderan ojol.");
                return 1;
            }
            if(OjolState[playerid] != 0)
            {
                SendClientMessage(playerid, COLOR_RED, "Anda sedang menjalankan orderan ojol!");
                return 1;
            }

            new rand = random(sizeof(OjolPickup));
            SetPlayerCheckpoint(playerid, OjolPickup[rand][0], OjolPickup[rand][1], OjolPickup[rand][2], 4.0);

            // Spawn Actor (NPC Pelanggan)
            OjolActor[playerid] = CreateActor(random(299), OjolPickup[rand][0], OjolPickup[rand][1], OjolPickup[rand][2], 0.0);

            OjolState[playerid] = 1;
            SendClientMessage(playerid, COLOR_YELLOW, "Orderan ojol diterima! Jemput pelanggan di titik merah di minimap.");

            // Tutup UI HP otomatis
            TextDrawHideForPlayer(playerid, PhoneTD[0]);
            TextDrawHideForPlayer(playerid, PhoneTD[1]);
            PhoneActive[playerid] = false;
        }
        else if(listitem == 3) // Tutup Handphone
        {
            TextDrawHideForPlayer(playerid, PhoneTD[0]);
            TextDrawHideForPlayer(playerid, PhoneTD[1]);
            PhoneActive[playerid] = false;
            SendClientMessage(playerid, COLOR_YELLOW, "* Anda menyimpan handphone.");
        }
        return 1;
    }

    return 0;
}

CMD:belimakan(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");

    // Sebagai permulaan kita jadikan global, nanti bisa pakai IsPlayerInRangeOfPoint ke restoran
    new cost = 20;
    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, COLOR_RED, "Uang Anda tidak cukup ($20).");
    if(PlayerInfo[playerid][pHunger] >= 100) return SendClientMessage(playerid, COLOR_RED, "Anda belum merasa lapar.");

    GivePlayerMoney(playerid, -cost);
    PlayerInfo[playerid][pHunger] += 40;
    if(PlayerInfo[playerid][pHunger] > 100) PlayerInfo[playerid][pHunger] = 100;

    SendClientMessage(playerid, COLOR_GREEN, "Anda telah membeli makanan seharga $20.");

    // Tambah darah jika makan
    new Float:hp;
    GetPlayerHealth(playerid, hp);
    hp += 10.0;
    if(hp > 100.0) hp = 100.0;
    SetPlayerHealth(playerid, hp);

    return 1;
}

CMD:beliminum(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");

    new cost = 10;
    if(GetPlayerMoney(playerid) < cost) return SendClientMessage(playerid, COLOR_RED, "Uang Anda tidak cukup ($10).");
    if(PlayerInfo[playerid][pThirst] >= 100) return SendClientMessage(playerid, COLOR_RED, "Anda belum merasa haus.");

    GivePlayerMoney(playerid, -cost);
    PlayerInfo[playerid][pThirst] += 50;
    if(PlayerInfo[playerid][pThirst] > 100) PlayerInfo[playerid][pThirst] = 100;

    SendClientMessage(playerid, COLOR_GREEN, "Anda telah membeli minuman seharga $10.");
    return 1;
}

CMD:parkir(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");
    if(PlayerInfo[playerid][pVehModel] == 0) return SendClientMessage(playerid, COLOR_RED, "Anda tidak memiliki kendaraan!");

    if(!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, COLOR_RED, "Anda harus berada di dalam kendaraan Anda untuk memarkirnya.");

    new veh = GetPlayerVehicleID(playerid);
    if(veh == PlayerVehicle[playerid])
    {
        new Float:x, Float:y, Float:z, Float:a;
        GetVehiclePos(veh, x, y, z);
        GetVehicleZAngle(veh, a);

        PlayerInfo[playerid][pVehX] = x;
        PlayerInfo[playerid][pVehY] = y;
        PlayerInfo[playerid][pVehZ] = z;
        PlayerInfo[playerid][pVehA] = a;

        SaveAccount(playerid);
        SendClientMessage(playerid, COLOR_GREEN, "Kendaraan Anda berhasil diparkir! Kendaraan akan spawn di sini saat Anda login kembali.");
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Ini bukan kendaraan Anda!");
    }
    return 1;
}

CMD:ambilpaket(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");

    if(HasPackage[playerid]) return SendClientMessage(playerid, COLOR_RED, "Anda sedang membawa paket! Antarkan dulu ke tujuan.");

    // Asumsi pusat paket di dekat rumah CJ (Grove Street)
    if(IsPlayerInRangeOfPoint(playerid, 15.0, 2495.33, -1669.75, 13.33))
    {
        HasPackage[playerid] = true;

        new rand = random(sizeof(DropOffPoints));
        SetPlayerCheckpoint(playerid, DropOffPoints[rand][0], DropOffPoints[rand][1], DropOffPoints[rand][2], 3.0);

        SendClientMessage(playerid, COLOR_YELLOW, "Anda telah mengambil paket. Antarkan ke titik merah di minimap!");
    }
    else
    {
        SendClientMessage(playerid, COLOR_RED, "Anda harus berada di titik pengambilan paket (Rumah Grove Street).");
    }
    return 1;
}

CMD:hp(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");

    if(!PhoneActive[playerid])
    {
        TextDrawShowForPlayer(playerid, PhoneTD[0]);
        TextDrawShowForPlayer(playerid, PhoneTD[1]);
        PhoneActive[playerid] = true;
        SendClientMessage(playerid, COLOR_YELLOW, "* Anda mengeluarkan handphone.");

        // Buka menu HP
        ShowPlayerDialog(playerid, DIALOG_HP_MENU, DIALOG_STYLE_LIST, "Handphone App", "1. M-Banking\n2. Toko Kendaraan Online\n3. Aplikasi Ojol\n4. Tutup Handphone", "Pilih", "Tutup");
    }
    else
    {
        TextDrawHideForPlayer(playerid, PhoneTD[0]);
        TextDrawHideForPlayer(playerid, PhoneTD[1]);
        PhoneActive[playerid] = false;
        SendClientMessage(playerid, COLOR_YELLOW, "* Anda menyimpan handphone.");
    }
    return 1;
}

public StripNewLine(string[])
{
    new len = strlen(string);
    if(len > 0 && (string[len - 1] == '\n' || string[len - 1] == '\r')) string[len - 1] = '\0';
    if(len > 1 && (string[len - 2] == '\n' || string[len - 2] == '\r')) string[len - 2] = '\0';
}

public LoadAccount(playerid, const password[])
{
    new name[MAX_PLAYER_NAME], file[128];
    GetPlayerName(playerid, name, sizeof(name));
    format(file, sizeof(file), "Accounts/%s.ini", name);

    new File:f = fopen(file, io_read);
    if(f)
    {
        new line[256], key[64], val[129];
        new storedPass[129], money, bank, hunger, thirst, vmod;
        new Float:vx, Float:vy, Float:vz, Float:va;

        while(fread(f, line))
        {
            StripNewLine(line);
            new splitPos = strfind(line, "=");
            if(splitPos != -1)
            {
                strmid(key, line, 0, splitPos);
                strmid(val, line, splitPos + 1, strlen(line));

                if(strcmp(key, "Password", true) == 0) format(storedPass, sizeof(storedPass), "%s", val);
                else if(strcmp(key, "Money", true) == 0) money = strval(val);
                else if(strcmp(key, "Bank", true) == 0) bank = strval(val);
                else if(strcmp(key, "Hunger", true) == 0) hunger = strval(val);
                else if(strcmp(key, "Thirst", true) == 0) thirst = strval(val);
                else if(strcmp(key, "VehModel", true) == 0) vmod = strval(val);
                else if(strcmp(key, "VehX", true) == 0) vx = floatstr(val);
                else if(strcmp(key, "VehY", true) == 0) vy = floatstr(val);
                else if(strcmp(key, "VehZ", true) == 0) vz = floatstr(val);
                else if(strcmp(key, "VehA", true) == 0) va = floatstr(val);
            }
        }
        fclose(f);

        if(strcmp(storedPass, password, false) == 0)
        {
            PlayerInfo[playerid][pMoney] = money;
            PlayerInfo[playerid][pBank] = bank;
            PlayerInfo[playerid][pHunger] = hunger == 0 ? 100 : hunger;
            PlayerInfo[playerid][pThirst] = thirst == 0 ? 100 : thirst;
            PlayerInfo[playerid][pVehModel] = vmod;
            PlayerInfo[playerid][pVehX] = vx;
            PlayerInfo[playerid][pVehY] = vy;
            PlayerInfo[playerid][pVehZ] = vz;
            PlayerInfo[playerid][pVehA] = va;
            PlayerInfo[playerid][pLogged] = 1;
            format(PlayerInfo[playerid][pPassword], 129, "%s", password);

            GivePlayerMoney(playerid, PlayerInfo[playerid][pMoney]);
            SendClientMessage(playerid, COLOR_GREEN, "Login berhasil!");
            SpawnPlayer(playerid);
        }
        else
        {
            ShowPlayerDialog(playerid, DIALOG_LOGIN, DIALOG_STYLE_PASSWORD, "Login", "Password SALAH!\nSilakan masukkan password Anda:", "Login", "Keluar");
        }
    }
    return 1;
}

public SaveAccount(playerid)
{
    if(!PlayerInfo[playerid][pLogged]) return 1;

    new name[MAX_PLAYER_NAME], file[128];
    GetPlayerName(playerid, name, sizeof(name));
    format(file, sizeof(file), "Accounts/%s.ini", name);

    PlayerInfo[playerid][pMoney] = GetPlayerMoney(playerid);

    new File:f = fopen(file, io_write);
    if(f)
    {
        new line[256];
        format(line, sizeof(line), "Password=%s\nMoney=%d\nBank=%d\nHunger=%d\nThirst=%d\nVehModel=%d\nVehX=%f\nVehY=%f\nVehZ=%f\nVehA=%f\n",
            PlayerInfo[playerid][pPassword], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pBank], PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst],
            PlayerInfo[playerid][pVehModel], PlayerInfo[playerid][pVehX], PlayerInfo[playerid][pVehY], PlayerInfo[playerid][pVehZ], PlayerInfo[playerid][pVehA]);
        fwrite(f, line);
        fclose(f);
    }
    return 1;
}

public DecreaseNeeds()
{
    for(new i = 0; i < MAX_PLAYERS; i++)
    {
        if(IsPlayerConnected(i) && PlayerInfo[i][pLogged])
        {
            PlayerInfo[i][pHunger] -= 2;
            PlayerInfo[i][pThirst] -= 3;

            if(PlayerInfo[i][pHunger] <= 0) PlayerInfo[i][pHunger] = 0;
            if(PlayerInfo[i][pThirst] <= 0) PlayerInfo[i][pThirst] = 0;

            if(PlayerInfo[i][pHunger] == 0 || PlayerInfo[i][pThirst] == 0)
            {
                new Float:hp;
                GetPlayerHealth(i, hp);
                SetPlayerHealth(i, hp - 5.0);
                SendClientMessage(i, COLOR_RED, "Anda merasa sangat lapar / haus! Darah anda berkurang.");
            }
        }
    }
    return 1;
}
