LOI:
gamemodes\modules\system\job\pizza\data.pwn(1) : error 010: invalid function or declaration

NGUYEN NHAN:
Script fix truoc da dung PowerShell Set-Content -Encoding UTF8.
Tren Windows PowerShell 5.1, cach nay co the them UTF-8 BOM vao dau file include .pwn.
Pawn compiler gap BOM o giua main source (tai file #include) co the bao error 010 ngay line 1.

CACH FIX:
1. Giai nen vao root project.
2. Chay FIX_ENCODING.bat.
3. Compile lai.

Script chi rewrite tat ca file .pwn thanh UTF-8 WITHOUT BOM.
No KHONG sua logic/code.

Cac warning 217 loose indentation va warning 203 never used KHONG lam compilation fail.
Xu ly sau khi error 010 bien mat.
