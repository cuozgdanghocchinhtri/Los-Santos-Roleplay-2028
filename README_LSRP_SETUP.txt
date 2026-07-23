LS:RP - OMP BASE READY
======================

Base: midosvt/omp-base-script
Target: Windows x86 open.mp

DEPENDENCIES USED BY THIS BASE
------------------------------
1. MySQL R41-4
   - plugins\mysql.dll
   - qawno\include\a_mysql.inc
   - libmariadb.dll
   - log-core.dll

2. samp-bcrypt 0.4.1
   - plugins\samp_bcrypt.dll
   - qawno\include\samp_bcrypt.inc

3. YSI-Includes 5.10.0006 (library, not a runtime plugin)
   - qawno\include\YSI_*\...
   - gamemode currently uses YSI_Coding\y_hooks

KHONG CAN THEM STREAMER / SSCANF / PAWN.CMD DE CHAY BASE HIEN TAI.
Chi them khi source bat dau su dung chung.

BAN CHI CAN LAM
---------------
A. Setup MySQL/MariaDB/XAMPP cua ban.
B. Import: database_structure.sql
   File SQL nay da duoc chinh de tao/use database `lsrp`.
C. Sua mysql.ini:

   hostname = 127.0.0.1
   username = root
   password = MAT_KHAU_CUA_BAN
   database = lsrp
   auto_reconnect = true

D. Double-click RUN_LSRP.bat

Lan dau RUN_LSRP.bat se:
- Tai MySQL R41-4 tu GitHub chinh thuc.
- Tai samp-bcrypt 0.4.1 tu GitHub chinh thuc.
- Tai YSI 5.10.0006 tu GitHub chinh thuc.
- Dat DLL/include dung vi tri.
- Compile gamemodes\main.pwn -> gamemodes\main.amx.
- Chay omp-server.exe.

Lan sau neu dependencies va main.amx da co thi se vao server nhanh hon.

SERVER LOCAL
------------
127.0.0.1:7777

CONFIG.JSON DA DUOC CHINH
-------------------------
- main_scripts = main 1
- legacy_plugins = mysql, samp_bcrypt
- max_players = 50
- MAX_PLAYERS trong main.pwn = 50
- name = LS:RP Development
- stunt bonus off
- player marker off
- manual engine/lights on
- default entry/exit markers off

COMPILE BANG VS CODE
--------------------
Open Folder chinh thu muc nay, sau do:
Ctrl + Shift + B

Hoac double-click COMPILE.bat.

NEU MYSQL PLUGIN LOAD FAIL TREN WINDOWS
---------------------------------------
Kiem tra Microsoft Visual C++ Redistributable x86 va xem:
- plugins\mysql.dll
- libmariadb.dll
- log-core.dll
co ton tai hay khong.

RCON
----
config.json dang dung password development:
LSRP_DEV_CHANGE_ME_9274
Hay doi truoc khi public server.
