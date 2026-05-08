// ==========================================
// MODULE: NPC (Bot System)
// ==========================================

new BusVehicleID;
new TrainVehicleID;

stock NPC_OnGameModeInit()
{
    // Konek NPC saat server hidup
    ConnectNPC("Supir_Bus", "lvbus"); // Membaca script npcmodes/lvbus.pwn
    ConnectNPC("Masinis_Kereta", "train_ls"); // Membaca script npcmodes/train_ls.pwn (akan dibuat)

    // Spawn kendaraan untuk NPC (431 = Bus, 538 = Brown Streak Train)
    BusVehicleID = CreateVehicle(431, 0.0, 0.0, 5.0, 0.0, -1, -1, 60000);
    TrainVehicleID = CreateVehicle(538, 0.0, 0.0, 5.0, 0.0, -1, -1, 60000);
}

stock NPC_OnPlayerSpawn(playerid)
{
    if (IsPlayerNPC(playerid))
    {
        new npcname[MAX_PLAYER_NAME];
        GetPlayerName(playerid, npcname, sizeof(npcname));

        if (strcmp(npcname, "Supir_Bus", true) == 0)
        {
            PutPlayerInVehicle(playerid, BusVehicleID, 0);
            SetPlayerColor(playerid, 0xFFFFFF00); // Warna Transparan/Putih
        }
        else if (strcmp(npcname, "Masinis_Kereta", true) == 0)
        {
            PutPlayerInVehicle(playerid, TrainVehicleID, 0);
            SetPlayerColor(playerid, 0xFFFFFF00);
        }
        return 1;
    }
    return 0;
}
