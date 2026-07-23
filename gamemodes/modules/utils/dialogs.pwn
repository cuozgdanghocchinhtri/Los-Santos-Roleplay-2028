// Defines dialog IDs using an enum.  Enums are preferred since they automatically
// assign unique values (IDs), eliminating the need to manually track them.
//
// Avoid using magic numbers for dialog IDs - it quickly becomes unclear what
// each value represents.
enum
{
    DIALOG_NO_RESPONSE,

    DIALOG_ACCOUNT_USERNAME,
    DIALOG_REGISTRATION,
    DIALOG_LOGIN,

    DIALOG_CHARACTER_SELECT,
    DIALOG_CHARACTER_NAME,
    DIALOG_CHARACTER_STATS,

    DIALOG_HELP_MAIN,
    DIALOG_ADMIN_HELP,
    DIALOG_JOB_STATUS,

    DIALOG_VEHICLE_LIST,
    DIALOG_VEHICLE_FILTER,
    DIALOG_VEHICLE_ACTIONS,
    DIALOG_VEHICLE_INFO,
    DIALOG_VEHICLE_DELETE
};
