// ==========================================
// MODULE: VEHICLE (Buying & Spawning)
// ==========================================

stock Vehicle_OnDialogResponse(playerid, dialogid, response, listitem)
{
    if (dialogid == DIALOG_VEH_MENU)
    {
        if (!response) return 1;
        if (listitem == 0)
        {
            if (PlayerInfo[playerid][pVehModel] == 0)
            {
                if (GetPlayerMoney(playerid) < 500) return SendClientMessage(playerid, 0xFF0000FF, "Uang tidak cukup!");
                GivePlayerMoney(playerid, -500);
                PlayerInfo[playerid][pVehModel] = 462;
                SendClientMessage(playerid, 0x00FF00FF, "VEHICLE: Berhasil beli Faggio.");
            }
            else
            {
                if (PlayerSpawnedVeh[playerid] != -1) DestroyVehicle(PlayerSpawnedVeh[playerid]);

                new Float:x, Float:y, Float:z, Float:a;
                GetPlayerPos(playerid, x, y, z);
                GetPlayerFacingAngle(playerid, a);
                new veh = CreateVehicle(PlayerInfo[playerid][pVehModel], x + 2.0, y, z, a, -1, -1, 600);
                PlayerSpawnedVeh[playerid] = veh;
                PutPlayerInVehicle(playerid, veh, 0);
                SendClientMessage(playerid, 0x00FF00FF, "VEHICLE: Kendaraan dipanggil.");
            }
        }
        return 1;
    }
    return 0;
}
