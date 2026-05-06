#include <a_samp>
#include <zcmd>
#include <file>

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

// --- Enums & Variables ---
enum pInfo
{
    pPassword[129],
    pMoney,
    pBank,
    pHunger,
    pThirst,
    pLogged
}
new PlayerInfo[MAX_PLAYERS][pInfo];

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
    PlayerInfo[playerid][pThirst] = 100;
    PlayerInfo[playerid][pLogged] = 0;
    PhoneActive[playerid] = false;
    HasPackage[playerid] = false;

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

    SendClientMessage(playerid, COLOR_YELLOW, "Hint: Anda bisa bekerja sebagai kurir. Gunakan /ambilpaket di area Grove Street.");

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
            format(line, sizeof(line), "Password=%s\nMoney=500\nBank=0\nHunger=100\nThirst=100\n", inputtext);
            fwrite(f, line);
            fclose(f);

            SendClientMessage(playerid, COLOR_GREEN, "Registrasi berhasil! Anda sekarang login.");
            PlayerInfo[playerid][pLogged] = 1;
            PlayerInfo[playerid][pMoney] = 500;
            PlayerInfo[playerid][pBank] = 0;
            PlayerInfo[playerid][pHunger] = 100;
            PlayerInfo[playerid][pThirst] = 100;
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
        if(!response) return 1;
        if(listitem == 0) // Cek Saldo
        {
            new msg[128];
            format(msg, sizeof(msg), "Saldo Bank Anda saat ini: $%d", PlayerInfo[playerid][pBank]);
            ShowPlayerDialog(playerid, 0, DIALOG_STYLE_MSGBOX, "Bank", msg, "Tutup", "");
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
        if(!response) return 1;
        new amount = strval(inputtext);
        if(amount < 1) return SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, COLOR_RED, "Uang cash Anda tidak cukup!");

        GivePlayerMoney(playerid, -amount);
        PlayerInfo[playerid][pBank] += amount;

        new msg[128];
        format(msg, sizeof(msg), "Anda telah menyetor $%d. Saldo saat ini: $%d", amount, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SaveAccount(playerid);
        return 1;
    }

    if(dialogid == DIALOG_BANK_WITHDRAW)
    {
        if(!response) return 1;
        new amount = strval(inputtext);
        if(amount < 1) return SendClientMessage(playerid, COLOR_RED, "Jumlah tidak valid!");
        if(PlayerInfo[playerid][pBank] < amount) return SendClientMessage(playerid, COLOR_RED, "Saldo bank Anda tidak cukup!");

        PlayerInfo[playerid][pBank] -= amount;
        GivePlayerMoney(playerid, amount);

        new msg[128];
        format(msg, sizeof(msg), "Anda telah menarik $%d. Saldo saat ini: $%d", amount, PlayerInfo[playerid][pBank]);
        SendClientMessage(playerid, COLOR_GREEN, msg);
        SaveAccount(playerid);
        return 1;
    }

    return 0;
}

CMD:bank(playerid, params[])
{
    if(!PlayerInfo[playerid][pLogged]) return SendClientMessage(playerid, COLOR_RED, "Anda harus login!");

    // Asumsi: Bisa diakses di mana saja karena konsep hp modern (M-Banking via HP)
    // Jika ingin dibatasi di lokasi ATM, tambahkan IsPlayerInRangeOfPoint di sini.
    ShowPlayerDialog(playerid, DIALOG_BANK_MENU, DIALOG_STYLE_LIST, "Aplikasi Bank", "1. Cek Saldo\n2. Setor Uang\n3. Tarik Uang", "Pilih", "Tutup");
    return 1;
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
        new storedPass[129], money, bank, hunger, thirst;

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
            }
        }
        fclose(f);

        if(strcmp(storedPass, password, false) == 0)
        {
            PlayerInfo[playerid][pMoney] = money;
            PlayerInfo[playerid][pBank] = bank;
            PlayerInfo[playerid][pHunger] = hunger == 0 ? 100 : hunger;
            PlayerInfo[playerid][pThirst] = thirst == 0 ? 100 : thirst;
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
        format(line, sizeof(line), "Password=%s\nMoney=%d\nBank=%d\nHunger=%d\nThirst=%d\n",
            PlayerInfo[playerid][pPassword], PlayerInfo[playerid][pMoney], PlayerInfo[playerid][pBank], PlayerInfo[playerid][pHunger], PlayerInfo[playerid][pThirst]);
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
