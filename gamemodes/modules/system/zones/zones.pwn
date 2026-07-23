//-----------------------------------------------------------------------------
// LS:RP 3D zone helpers
//
// This module is independent from the vehicle system. A collision plugin can
// replace Zone_IsParkingPositionValid later without changing vehicle code.
//-----------------------------------------------------------------------------

#define PARK_REJECT_NONE        (0)
#define PARK_REJECT_WATER       (1)
#define PARK_REJECT_ROOFTOP     (2)
#define PARK_REJECT_RESTRICTED  (3)
#define PARK_REJECT_INTERIOR    (4)

enum E_LSRP_ZONE
{
    zone_Name[32],
    Float:zone_MinX,
    Float:zone_MinY,
    Float:zone_MinZ,
    Float:zone_MaxX,
    Float:zone_MaxY,
    Float:zone_MaxZ
};

// Specific zones are checked before the broad city/county fallback.
new const g_LSRPZones[][E_LSRP_ZONE] =
{
    {"Ganton", 2222.5, -1852.8, -20.0, 2632.8, -1628.5, 120.0},
    {"Idlewood", 1812.5, -1852.8, -20.0, 2222.5, -1449.5, 120.0},
    {"Jefferson", 1996.9, -1494.0, -20.0, 2281.4, -1126.3, 120.0},
    {"East Los Santos", 2222.5, -1628.5, -20.0, 2632.8, -1135.0, 120.0},
    {"East Beach", 2632.8, -1852.8, -20.0, 2959.3, -1120.0, 120.0},
    {"Las Colinas", 1994.3, -1154.5, -20.0, 2959.3, -920.8, 160.0},
    {"Glen Park", 1812.5, -1449.6, -20.0, 2056.8, -973.3, 140.0},
    {"Los Flores", 2581.7, -1454.3, -20.0, 2747.7, -1120.0, 120.0},
    {"Playa del Seville", 2703.5, -2126.9, -20.0, 2959.3, -1852.8, 120.0},
    {"Willowfield", 1970.6, -2179.2, -20.0, 2535.2, -1852.8, 120.0},
    {"El Corona", 1692.6, -2179.2, -20.0, 1970.6, -1842.2, 120.0},
    {"Little Mexico", 1701.9, -1842.2, -20.0, 1812.6, -1577.5, 120.0},
    {"Commerce", 1323.9, -1842.2, -20.0, 1812.6, -1577.5, 160.0},
    {"Pershing Square", 1440.9, -1722.2, -20.0, 1583.5, -1577.5, 160.0},
    {"Market", 787.5, -1416.2, -20.0, 1370.8, -1130.8, 180.0},
    {"Market Station", 787.5, -1410.9, -20.0, 866.0, -1310.2, 120.0},
    {"Downtown Los Santos", 1370.8, -1384.9, -20.0, 1812.6, -1130.8, 200.0},
    {"Conference Center", 1046.1, -1804.2, -20.0, 1323.9, -1577.5, 140.0},
    {"Verona Beach", 647.7, -2173.2, -20.0, 1161.5, -1722.2, 120.0},
    {"Santa Maria Beach", 342.6, -2173.2, -20.0, 647.7, -1684.6, 120.0},
    {"Marina", 647.7, -1804.2, -20.0, 1046.1, -1577.5, 120.0},
    {"Rodeo", 72.6, -1684.6, -20.0, 647.7, -1026.3, 200.0},
    {"Richman", 72.6, -1301.6, -20.0, 700.8, -954.6, 240.0},
    {"Temple", 952.6, -1130.8, -20.0, 1378.3, -954.6, 200.0},
    {"Vinewood", 787.5, -1310.2, -20.0, 1641.1, -768.0, 260.0},
    {"Mulholland", 1169.1, -910.2, -20.0, 2142.8, -452.4, 320.0},
    {"Ocean Docks", 2373.7, -2697.1, -20.0, 2809.2, -1852.8, 120.0},
    {"Los Santos International", 1249.6, -2697.1, -20.0, 2201.8, -2179.2, 120.0},
    {"Verdant Bluffs", 930.2, -2488.4, -20.0, 1249.6, -2006.8, 180.0},
    {"Unity Station", 1692.6, -1971.8, -20.0, 1812.6, -1842.2, 120.0}
};

stock bool:Zone_IsPointInside(
    Float:x,
    Float:y,
    Float:z,
    Float:minX,
    Float:minY,
    Float:minZ,
    Float:maxX,
    Float:maxY,
    Float:maxZ
)
{
    return (
        x >= minX && x <= maxX &&
        y >= minY && y <= maxY &&
        z >= minZ && z <= maxZ
    );
}

stock Zone_GetNameAt(Float:x, Float:y, Float:z, destination[], size)
{
    for (new zone = 0; zone < sizeof(g_LSRPZones); zone++)
    {
        if (!Zone_IsPointInside(
            x,
            y,
            z,
            g_LSRPZones[zone][zone_MinX],
            g_LSRPZones[zone][zone_MinY],
            g_LSRPZones[zone][zone_MinZ],
            g_LSRPZones[zone][zone_MaxX],
            g_LSRPZones[zone][zone_MaxY],
            g_LSRPZones[zone][zone_MaxZ]
        ))
        {
            continue;
        }

        format(destination, size, "%s", g_LSRPZones[zone][zone_Name]);
        return 1;
    }

    if (x >= 44.6 && x <= 2997.0 && y >= -2892.9 && y <= -768.0)
    {
        format(destination, size, "Los Santos");
    }
    else if (x >= -2997.0 && x <= -1213.9 && y >= -1115.5 && y <= 1659.6)
    {
        format(destination, size, "San Fierro");
    }
    else if (x >= 869.4 && x <= 2997.0 && y >= 596.3 && y <= 2993.8)
    {
        format(destination, size, "Las Venturas");
    }
    else if (y < -1115.5)
    {
        format(destination, size, "Flint County");
    }
    else if (x > 0.0 && y < 596.3)
    {
        format(destination, size, "Red County");
    }
    else if (x < -1213.9)
    {
        format(destination, size, "Tierra Robada");
    }
    else
    {
        format(destination, size, "Bone County");
    }

    return 1;
}

stock bool:Zone_IsRestrictedParkingArea(Float:x, Float:y, Float:z)
{
    // Airport runway and apron.
    if (Zone_IsPointInside(x, y, z, 1249.6, -2697.1, -10.0, 2201.8, -2350.0, 80.0))
    {
        return true;
    }

    // Ocean Docks loading basin.
    if (Zone_IsPointInside(x, y, z, 2660.0, -2570.0, -10.0, 2870.0, -2140.0, 80.0))
    {
        return true;
    }

    return false;
}

stock Zone_IsParkingPositionValid(
    Float:x,
    Float:y,
    Float:z,
    interior,
    virtualWorld,
    &rejectReason
)
{
    rejectReason = PARK_REJECT_NONE;

    // Interior garages will become explicit safe zones in the property system.
    if (interior != 0 || virtualWorld != 0)
    {
        rejectReason = PARK_REJECT_INTERIOR;
        return 0;
    }

    // San Andreas water level is approximately Z 0.
    if (z < 1.5)
    {
        rejectReason = PARK_REJECT_WATER;
        return 0;
    }

    if (Zone_IsRestrictedParkingArea(x, y, z))
    {
        rejectReason = PARK_REJECT_RESTRICTED;
        return 0;
    }

    // Conservative rooftop guard for the flat, dense part of Los Santos.
    if (x >= 1200.0 && x <= 2800.0 &&
        y >= -2300.0 && y <= -1120.0 &&
        z > 55.0)
    {
        rejectReason = PARK_REJECT_ROOFTOP;
        return 0;
    }

    return 1;
}
