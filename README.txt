LS:RP - FIX PIZZA "DU LIEU NGHE NGHIEP DANG DUOC TAI"

Nguyen nhan:
Pizza_RentVehicle -> Job_Start -> Job_CanStart.
Job_CanStart dang bat buoc Job_IsProgressReady, trong khi pJob moi la employment.
XP/history trong character_jobs khong nen chan viec thue xe/bat dau ca.

Fix:
- Job_CanStart khong return false khi progress dang load.
- Progress van load ngam.
- character_jobs chi SELECT progression/history:
  experience, completed_runs, completed_tasks, best_streak, total_earnings.
- pJob load xong se kick-off Job_LoadProgress.
- Neu progress chua ready khi giao/tra xe, tien van duoc tra; chi bo qua XP/history cho lan do.

CACH DUNG:
- Giai nen vao ROOT project.
- FIX_ONLY.bat: chi fix code.
- FIX_AND_PUSH.bat: fix + git add 3 file + commit + push.

Commit:
fix(job): prevent pizza rental from waiting on progression

Script chi stage:
gamemodes/modules/system/job/core.pwn
gamemodes/modules/system/job/persistence.pwn
gamemodes/modules/system/job/pizza/core.pwn

Khong stage cac file khac.
File Pawn duoc ghi UTF-8 WITHOUT BOM.
