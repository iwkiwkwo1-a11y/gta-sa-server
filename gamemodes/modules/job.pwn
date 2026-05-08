// ==========================================
// MODULE: JOB (Jobs, NPC Missions, Checkpoints)
// ==========================================

stock Job_OnDialogResponse(playerid, dialogid, response, listitem)
{
    if (dialogid == DIALOG_JOB_MENU)
    {
        if (!response) return 1;
        if (listitem == 0) return 1;

        if (listitem == 1) { PlayerInfo[playerid][pJob] = 1; SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda menjadi Supir Taksi."); }
        else if (listitem == 2) { PlayerInfo[playerid][pJob] = 2; SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda menjadi Kurir Paket."); }
        else if (listitem == 3) { PlayerInfo[playerid][pJob] = 0; SendClientMessage(playerid, 0x00FF00FF, "JOB: Anda resign."); }
        return 1;
    }

    if (dialogid == DIALOG_MISSION_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            if (PlayerInfo[playerid][pJob] == 1 && !IsPlayerInAnyVehicle(playerid))
                return SendClientMessage(playerid, 0xFF0000FF, "JOB: Harus di dalam kendaraan untuk mencari penumpang!");

            OnMission[playerid] = true;
            MissionType[playerid] = PlayerInfo[playerid][pJob];
            MissionStep[playerid] = 1;

            new rand = random(sizeof(MissionPoints));
            new Float:rx = MissionPoints[rand][0], Float:ry = MissionPoints[rand][1], Float:rz = MissionPoints[rand][2], Float:ra = MissionPoints[rand][3];
            SetPlayerCheckpoint(playerid, rx, ry, rz, 4.0);

            new skin = 10 + random(50);
            MissionActor[playerid] = CreateActor(skin, rx, ry, rz, ra);

            if (MissionType[playerid] == 1) SendClientMessage(playerid, 0x00FF00FF, "JOB: Jemput penumpang NPC di lokasi merah.");
            else if (MissionType[playerid] == 2) SendClientMessage(playerid, 0x00FF00FF, "JOB: Antar paket ke NPC pelanggan di lokasi merah.");
        }
        return 1;
    }
    return 0;
}

stock Job_OnPlayerEnterCheckpoint(playerid)
{
    if (OnMission[playerid])
    {
        if (MissionType[playerid] == 1)
        {
            if (!IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "JOB: Anda harus di dalam kendaraan!");

            if (MissionStep[playerid] == 1)
            {
                DisablePlayerCheckpoint(playerid);
                if (MissionActor[playerid] != -1) { DestroyActor(MissionActor[playerid]); MissionActor[playerid] = -1; }
                MissionStep[playerid] = 2;

                new rand = random(sizeof(MissionPoints));
                SetPlayerCheckpoint(playerid, MissionPoints[rand][0], MissionPoints[rand][1], MissionPoints[rand][2], 4.0);
                SendClientMessage(playerid, 0x00FF00FF, "JOB: Penumpang naik! Antar ke lokasi merah.");
            }
            else if (MissionStep[playerid] == 2)
            {
                DisablePlayerCheckpoint(playerid);
                OnMission[playerid] = false; MissionStep[playerid] = 0; MissionType[playerid] = 0;
                new reward = 80 + random(70);
                GivePlayerMoney(playerid, reward);

                new str[128]; format(str, sizeof(str), "JOB: Penumpang sampai. Bayaran: $%d!", reward);
                SendClientMessage(playerid, 0x00FF00FF, str);
            }
        }
        else if (MissionType[playerid] == 2)
        {
            if (IsPlayerInAnyVehicle(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "JOB: Turun dari kendaraan untuk memberi paket!");
            if (MissionStep[playerid] == 1)
            {
                DisablePlayerCheckpoint(playerid);
                if (MissionActor[playerid] != -1) { DestroyActor(MissionActor[playerid]); MissionActor[playerid] = -1; }

                OnMission[playerid] = false; MissionStep[playerid] = 0; MissionType[playerid] = 0;
                new reward = 50 + random(50);
                GivePlayerMoney(playerid, reward);

                new str[128]; format(str, sizeof(str), "JOB: Paket diserahkan. Bayaran: $%d!", reward);
                SendClientMessage(playerid, 0x00FF00FF, str);
            }
        }
    }
}
