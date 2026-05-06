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

// --- Enums & Variables ---
enum pInfo
{
    pPassword[129],
    pMoney,
    pLogged
}
new PlayerInfo[MAX_PLAYERS][pInfo];

new Text:PhoneTD[2]; // Textdraw handphone (Kotak dan Layar)
new bool:PhoneActive[MAX_PLAYERS];

// --- Forwards ---
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

    return 1;
}

public OnPlayerConnect(playerid)
{
    PlayerInfo[playerid][pMoney] = 0;
    PlayerInfo[playerid][pLogged] = 0;
    PhoneActive[playerid] = false;

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
            format(line, sizeof(line), "Password=%s\nMoney=500\n", inputtext);
            fwrite(f, line);
            fclose(f);

            SendClientMessage(playerid, COLOR_GREEN, "Registrasi berhasil! Anda sekarang login.");
            PlayerInfo[playerid][pLogged] = 1;
            PlayerInfo[playerid][pMoney] = 500;
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

    return 0;
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
        new storedPass[129], money;

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
            }
        }
        fclose(f);

        if(strcmp(storedPass, password, false) == 0)
        {
            PlayerInfo[playerid][pMoney] = money;
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
        format(line, sizeof(line), "Password=%s\nMoney=%d\n", PlayerInfo[playerid][pPassword], PlayerInfo[playerid][pMoney]);
        fwrite(f, line);
        fclose(f);
    }
    return 1;
}
