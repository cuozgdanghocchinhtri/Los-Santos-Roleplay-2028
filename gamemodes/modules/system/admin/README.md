# LS:RP Admin system

He thong quyen quan tri OOC duoc tach rieng de co the sua hoac go bo de dang.

## Cau truc

- `data.pwn`: cap do admin, trang thai runtime va tim nguoi choi.
- `persistence.pwn`: tai/luu `admin_level` theo tai khoan OOC.
- `commands.pwn`: cac lenh quan tri.
- `database/migrations/004_admin_system.sql`: them cot quyen vao database.

## Cap do

| Level | Ten |
|---:|---|
| 0 | Nguoi choi |
| 1 | Supporter |
| 2 | Moderator |
| 3 | Administrator |
| 4 | Senior Admin |
| 5 | Admin Manager |
| 6 | Owner |

RCON admin duoc xem nhu level 6 de co the cap quyen lan dau.

## Lenh

- `/a [noi dung]`: chat noi bo admin, level 1+.
- `/goto [ID/ten]`, `/gotoid [ID]`: dich chuyen den nguoi choi, level 2+.
- `/gethere [ID/ten]`: dua nguoi choi den vi tri admin, level 3+.
- `/admins`: xem admin dang truc tuyen.
- `/setadmin [ID/ten] [0-6]`: cap quyen, level 6/RCON.
- `/adminhelp`: dialog danh sach lenh.

## Cai dat va test

1. Import `database/migrations/004_admin_system.sql`.
2. Dang nhap RCON bang `/rcon login <mat_khau_rcon>`.
3. Dung `/setadmin <playerid> 6` de tao Owner dau tien.
4. Dang nhap lai va thu `/adminhelp`, `/a`, `/goto`.

## Go bo

Xoa ba dong include cua module Admin trong `gamemodes/main.pwn`. Neu khong con
can du lieu, co the xoa cot `admin_level` khoi bang `player_accounts`.
