#include <a_npc>

main() {}

public OnRecordingPlaybackEnd()
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "lvbus");
}

public OnNPCEnterVehicle(vehicleid, seatid)
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "lvbus");
}

public OnNPCExitVehicle()
{
    StopRecordingPlayback();
}
