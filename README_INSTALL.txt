MEDICAL PHASE 2 - PATCH-FREE INSTALL
====================================

Đặt toàn bộ folder/bộ cài này ở ROOT repository, nơi có:

gamemodes/
qawno/
...

Sau đó chạy:

INSTALL_MEDICAL_PHASE2.bat

Hoặc PowerShell:

powershell -ExecutionPolicy Bypass -File .\INSTALL_MEDICAL_PHASE2.ps1

Script sẽ:
1. Backup medical/core.pwn hiện tại thành core.pwn.phase1.bak.
2. Copy đè full Phase 2 core.pwn.
3. Copy commands.pwn.
4. Kiểm tra main.pwn.
5. Tự thêm health/core/commands include nếu thiếu.
6. Không thêm include trùng nếu chạy lại.

KHÔNG CHẠY MEDICAL_PHASE2_EXISTING_FILES.patch NỮA.

Sau khi cài, compile gamemode.
