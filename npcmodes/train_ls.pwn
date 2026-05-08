#include <a_npc>

main() {}

public OnRecordingPlaybackEnd()
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "train_ls");
}

public OnNPCEnterVehicle(vehicleid, seatid)
{
    StartRecordingPlayback(PLAYER_RECORDING_TYPE_DRIVER, "train_ls");
}

public OnNPCExitVehicle()
{
    StopRecordingPlayback();
}
