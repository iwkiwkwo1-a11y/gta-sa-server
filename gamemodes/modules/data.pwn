// ==========================================
// MODULE: DATA & DEFINITIONS
// ==========================================

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
    pHouseID,
    Float:pPosX,
    Float:pPosY,
    Float:pPosZ,
    pInt,
    pVW
};
new PlayerInfo[MAX_PLAYERS][pInfo];
new bool:IsLoggedIn[MAX_PLAYERS];

// Variabel Misi Sesi
new bool:OnMission[MAX_PLAYERS];
new MissionType[MAX_PLAYERS]; // 1 = Ojol/Taksi, 2 = Kurir
new MissionStep[MAX_PLAYERS]; // 1 = Jemput, 2 = Antar
new MissionActor[MAX_PLAYERS];

// Variabel Kendaraan
new PlayerSpawnedVeh[MAX_PLAYERS] = {-1, ...};

// Lokasi valid misi
new Float:MissionPoints[][4] = {
    {1958.3783, 1343.1572, 15.3746, 269.1425},
    {1945.1633, 1338.4893, 10.3664, 0.0},
    {2036.0,    1344.0,    10.6719, 90.0},
    {2022.6105, 1008.2045, 10.8203, 180.0},
    {1985.4523, 1021.0594, 9.9453, 90.0}
};

// Struktur Rumah
enum hInfo
{
    Float:hExtX, Float:hExtY, Float:hExtZ,
    Float:hIntX, Float:hIntY, Float:hIntZ,
    hIntID, hPrice, hSafeMoney, hOwner[MAX_PLAYER_NAME]
};
#define MAX_HOUSES 3
new HouseInfo[MAX_HOUSES][hInfo] = {
    {2496.0498, -1695.2388, 10.1484,  223.0439, 1289.2598, 1082.1999, 1, 5000, 0, "None"},
    {2488.6658, -1645.7197, 14.0703,  223.0439, 1289.2598, 1082.1999, 1, 7500, 0, "None"},
    {2444.6296, -1693.3618, 13.5186,  223.0439, 1289.2598, 1082.1999, 1, 6000, 0, "None"}
};
new HousePickup[MAX_HOUSES];
new Text3D:HouseLabel[MAX_HOUSES];

// Forward deklarasi strtok
forward strtok(const string[], &index);
strtok(const string[], &index)
{
    new length = strlen(string);
    while ((index < length) && (string[index] <= ' ')) index++;
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
