# LS:RP Owned Vehicles

The active implementation is `simple.pwn`. The older multi-file vehicle
implementation remains in this folder as a legacy reference and is not
included by `gamemodes/main.pwn`.

The active flow currently supports:

- `/vehicles` with the existing list dialog and vehicle names.
- Full vehicle information: health, fuel, mileage, damage, lock, trunk and
  parking position.
- Spawn/store, park, lock/unlock, GPS and basic trunk open/close.
- Engine toggle with the `N` key while sitting in the driver's seat.
- Runtime health/fuel/mileage persistence.
- Destroyed vehicles become `Hu hong` and cannot be spawned again.
- `/addvehicle [model_id]` remains a temporary development seed command.

## Install

Import migrations `001`, `002`, `003`, and `006` into the `lsrp` database.
Migration `006` adds the persistent `fuel_liters` column. Vehicles are owned
by `player_characters.character_id`, never by the master account.

Example development row:

```sql
INSERT INTO player_vehicles
    (owner_character_id, model_id, plate, color_1, color_2)
VALUES
    (1, 560, 'LSRP-001', 1, 1);
```

Change character ID `1` and ensure the plate is globally unique.

For an in-game smoke test, run:

```text
/addvehicle
/addvehicle 560
```

The optional argument is the vehicle model ID. The test vehicle is created
with full fuel and can then be exercised through the `/vehicles` dialog.

## Remove

1. Remove the `simple.pwn` include from `gamemodes/main.pwn`.
2. Remove `modules/system/vehicles` if desired.
3. Keep the table for later, or explicitly drop `player_vehicles`.

The migration is intentionally separate; removing the Pawn module never
deletes player data automatically.

## Extension points

- Replace only `Zone_IsParkingPositionValid` when adding ColAndreas or another
  ground/collision library.
- A dealership should insert rows into `player_vehicles`, then call
  `Vehicle_LoadForPlayer(playerid)`.
- A mechanic system should update health/component fields through the runtime
  slot, mark `ov_Dirty`, and call `Vehicle_SaveSlot`.
- An impound system only needs to set `ov_Storage = OV_STORAGE_IMPOUNDED`.
