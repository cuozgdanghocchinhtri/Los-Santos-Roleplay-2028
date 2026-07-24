#!/usr/bin/env python3
from pathlib import Path
import shutil, re, sys
from datetime import datetime

ROOT = Path.cwd()
STAMP = datetime.now().strftime("%Y%m%d-%H%M%S")
BACKUP = ROOT / f".lsrp-message-backup-{STAMP}"

FILES = {
    "colors": ROOT / "gamemodes/modules/utils/colors.pwn",
    "stats": ROOT / "gamemodes/modules/core/player/stats.pwn",
    "controls": ROOT / "gamemodes/modules/system/vehicles/controls.pwn",
    "admin": ROOT / "gamemodes/modules/system/admin/commands.pwn",
    "pizza": ROOT / "gamemodes/modules/system/job/pizza/core.pwn",
    "cinematic": ROOT / "gamemodes/modules/core/player/character/cinematic.pwn",
    "character": ROOT / "gamemodes/modules/core/player/character/core.pwn",
}

missing = [str(p) for p in FILES.values() if not p.exists()]
if missing:
    print("Khong tim thay source LSRP. Hay chay script tu ROOT gamemode/repository.")
    for p in missing:
        print(" -", p)
    sys.exit(1)

for p in FILES.values():
    rel = p.relative_to(ROOT)
    dst = BACKUP / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(p, dst)

def read(key):
    return FILES[key].read_text(encoding="utf-8")

def write(key, text):
    FILES[key].write_text(text, encoding="utf-8", newline="\n")

def replace_many(text, pairs):
    for old, new in pairs:
        if old in text:
            text = text.replace(old, new)
        else:
            print("WARN: Khong tim thay chuoi:", old[:90])
    return text

colors = r'''//-----------------------------------------------------------------------------
// LS:RP unified color language
//-----------------------------------------------------------------------------
//
// 70-80% message: light gray / white
// Data highlight: dark navy blue
// Error / warning highlight: dark burgundy red
//-----------------------------------------------------------------------------

#define COLOR_WHITE          (0xFFFFFFFF)
#define COLOR_RED            (0x7A2929FF)
#define COLOR_GRAY           (0xBFC0C2FF)
#define COLOR_DARK_GRAY      (0x858585FF)
#define COLOR_LSRP_BLUE      (0x264A73FF)
#define COLOR_LSRP_RED       (0x7A2929FF)

//-----------------------------------------------------------------------------
// Roleplay chat colors - intentionally kept distinct from system messages.
//-----------------------------------------------------------------------------

#define COLOR_RP_CHAT        (0xFFFFFFFF)
#define COLOR_RP_ME          (0xC2A2DAFF)
#define COLOR_RP_DO          (0xD7A86EFF)
#define COLOR_RP_OOC         (0xB0B0B0FF)
#define COLOR_RP_SHOUT       (0xFFE08AFF)
#define COLOR_RP_TRY         (0xC2A2DAFF)

//-----------------------------------------------------------------------------
// Embedded dialog/chat colors
//-----------------------------------------------------------------------------

#define EMBED_WHITE          "{FFFFFF}"
#define EMBED_RED            "{7A2929}"

#define EMBED_LSRP_WHITE     "{FFFFFF}"
#define EMBED_LSRP_GRAY      "{BFC0C2}"
#define EMBED_LSRP_DARKGRAY  "{858585}"
#define EMBED_LSRP_BLUE      "{264A73}"
#define EMBED_LSRP_RED       "{7A2929}"

// Backward-compatible aliases.
#define EMBED_RP_LIGHT_GRAY  EMBED_LSRP_GRAY
#define EMBED_RP_DARK_RED    EMBED_LSRP_RED
#define EMBED_RP_DARK_BLUE   EMBED_LSRP_BLUE
'''
write("colors", colors)

stats = read("stats")
new_stats_func = r'''Character_ShowStats(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new
        body[CHARACTER_STATS_BODY_SIZE],
        gender[8],
        voice[16],
        skinTone[16],
        birthPlace[32];

    format(gender, sizeof(gender), "%s", s_CharacterGender[playerid] == 0 ? "Nam" : "Nu");
    format(
        voice,
        sizeof(voice),
        "%s",
        s_CharacterGender[playerid] == 0 ?
            g_MaleVoiceNames[s_CharacterVoice[playerid]] :
            g_FemaleVoiceNames[s_CharacterVoice[playerid]]
    );
    format(skinTone, sizeof(skinTone), "%s", g_SkinToneNames[s_CharacterSkinTone[playerid]]);
    format(birthPlace, sizeof(birthPlace), "%s", g_BirthPlaceNames[s_CharacterBirthPlace[playerid]]);

    format(
        body,
        sizeof(body),
        "{FFFFFF}THONG TIN NHAN VAT\n"
        "{858585}------------------------------------------------------------\n"
        "{BFC0C2}Ten nhan vat: {264A73}%s\n"
        "{BFC0C2}Ma nhan vat: {264A73}%d    {BFC0C2}Slot: {264A73}%d\n"
        "{BFC0C2}Gioi tinh: {FFFFFF}%s    {BFC0C2}Tuoi: {FFFFFF}%d\n"
        "{BFC0C2}Ngay sinh: {FFFFFF}%02d/%02d/%d\n"
        "{BFC0C2}Noi sinh: {FFFFFF}%s\n"
        "{BFC0C2}Giong noi: {FFFFFF}%s    {BFC0C2}Mau da: {FFFFFF}%s\n"
        "{BFC0C2}Chieu cao: {FFFFFF}%d cm    {BFC0C2}Can nang: {FFFFFF}%d kg\n"
        "{BFC0C2}Skin hien tai: {264A73}%d\n\n"
        "{FFFFFF}TAI CHINH VA TRANG THAI\n"
        "{858585}------------------------------------------------------------\n"
        "{BFC0C2}Cap do: {264A73}%d\n"
        "{BFC0C2}Tien mat: {264A73}$%d\n"
        "{BFC0C2}Ngan hang: {264A73}$%d\n"
        "{BFC0C2}Mau: {FFFFFF}%.1f    {BFC0C2}Giap: {FFFFFF}%.1f\n\n"
        "{858585}Day la thong tin hien tai cua nhan vat. Mot so du lieu co the thay doi sau khi "
        "ban hoan tat cong viec, giao dich hoac su dung cac he thong khac trong thanh pho.",
        s_CharacterName[playerid],
        s_CharacterID[playerid],
        s_CharacterSlot[playerid],
        gender,
        GetPlayerCharacterAge(playerid),
        s_CharacterBirthDay[playerid],
        s_CharacterBirthMonth[playerid],
        s_CharacterBirthYear[playerid],
        birthPlace,
        voice,
        skinTone,
        s_CharacterHeight[playerid],
        s_CharacterWeight[playerid],
        GetPlayerSkin(playerid),
        GetPlayerScore(playerid),
        GetPlayerMoney(playerid),
        s_CharacterBank[playerid],
        s_CharacterHealth[playerid],
        s_CharacterArmour[playerid]
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_CHARACTER_STATS,
        DIALOG_STYLE_MSGBOX,
        "{FFFFFF}Los Santos Roleplay - Thong tin nhan vat",
        body,
        "Dong",
        ""
    );

    return 1;
}'''

pattern = re.compile(r'Character_ShowStats\(playerid\)\s*\{.*?\n\}\n\nhook OnPlayerCommandText', re.S)
if not pattern.search(stats):
    print("ERROR: Khong thay Character_ShowStats trong stats.pwn")
    sys.exit(2)
stats = pattern.sub(new_stats_func + "\n\nhook OnPlayerCommandText", stats, count=1)
write("stats", stats)

controls = read("controls")
controls = replace_many(controls, [
    ("Ban phai ngoi o ghe lai cua phuong tien.",
     "Ban khong the dieu khien phuong tien luc nay. Hay ngoi vao ghe lai truoc khi su dung lenh dieu khien xe."),
    ("Khong tim thay phuong tien dang dieu khien.",
     "He thong khong tim thay phuong tien ban dang dieu khien. Hay vao lai ghe lai va thu lai lenh."),
    ("Phuong tien dang duoc khoi dong.",
     "Dong co dang trong qua trinh khoi dong. Hay cho den khi qua trinh nay hoan tat truoc khi thao tac lai."),
    ("Khoi dong phuong tien da bi huy.",
     "Qua trinh khoi dong da bi huy vi ban da roi ghe lai hoac phuong tien khong con hop le."),
    ("Da khoi dong phuong tien thanh cong",
     "Dong co da khoi dong thanh cong. Phuong tien hien da san sang de di chuyen."),
    ("Da tat dong co phuong tien.",
     "Ban da tat dong co cua phuong tien. Dong co se ngung hoat dong cho den khi duoc khoi dong lai."),
    ("Da bat den phuong tien.",
     "Ban da bat he thong den cua phuong tien. Den xe hien dang duoc su dung."),
    ("Da tat den phuong tien.",
     "Ban da tat he thong den cua phuong tien. Den xe hien da duoc tat."),
    ("Da ha cua kinh phuong tien.",
     "Ban da ha cac cua kinh cua phuong tien. Su dung /car windows mot lan nua de dong lai."),
    ("Da dong cua kinh phuong tien.",
     "Ban da dong cac cua kinh cua phuong tien. Su dung /car windows mot lan nua de ha xuong."),
    ("Da khoa cua phuong tien.",
     "Ban da khoa toan bo cua cua phuong tien. Nguoi choi ben ngoai se khong the vao xe cho den khi duoc mo khoa."),
    ("Da mo khoa cua phuong tien.",
     "Ban da mo khoa cua phuong tien. Cac cua xe hien co the duoc su dung binh thuong."),
    ("Da mo nap capo.",
     "Ban da mo nap capo cua phuong tien. Su dung /car hood mot lan nua khi ban muon dong lai."),
    ("Da dong nap capo.",
     "Ban da dong nap capo cua phuong tien va dua no ve trang thai binh thuong."),
    ("Da mo cop phuong tien.",
     "Ban da mo cop sau cua phuong tien. Su dung /car trunk mot lan nua khi ban muon dong cop."),
    ("Da dong cop phuong tien.",
     "Ban da dong cop sau cua phuong tien va dua no ve trang thai binh thuong."),
    ("Su dung: /car [engine/lights/windows/lock/hood/trunk]",
     "Su dung /car [engine/lights/windows/lock/hood/trunk] de dieu khien tung bo phan cua phuong tien.")
])
write("controls", controls)

admin = read("admin")
admin = replace_many(admin, [
    ("Khong tim thay nguoi choi.",
     "Khong tim thay nguoi choi phu hop voi ID hoac ten da cung cap. Hay kiem tra lai thong tin va thu lai."),
    ("Ban dang o vi tri cua chinh minh.",
     "Ban khong can dich chuyen den chinh minh. Hay nhap ID hoac ten cua mot nguoi choi khac."),
    ("Ban khong the keo chinh minh.",
     "Ban khong the su dung lenh nay len chinh minh. Hay nhap ID hoac ten cua nguoi choi can dich chuyen."),
    ("Da dich chuyen nguoi choi den vi tri cua ban.",
     "Nguoi choi da duoc dich chuyen den vi tri hien tai cua ban. Interior va Virtual World da duoc dong bo."),
    ("Nguoi choi chua dang nhap tai khoan.",
     "Nguoi choi nay chua hoan tat qua trinh dang nhap, vi vay cap do quan tri chua the duoc thay doi."),
    ("Dang luu quyen admin vao database...",
     "Cap do quan tri moi dang duoc luu vao co so du lieu. Thay doi se tiep tuc duoc ap dung trong nhung lan dang nhap sau."),
    ("Cap do admin phai nam trong khoang 0-6.",
     "Cap do quan tri khong hop le. Gia tri duoc phep nam trong khoang tu 0 den 6.")
])
write("admin", admin)

pizza = read("pizza")
pizza = replace_many(pizza, [
    ("Ban chua phai nhan vien Pizza Stack.",
     "Ban chua duoc tuyen dung tai Pizza Stack. Hay noi chuyen voi quan ly tuyen dung truoc khi bat dau giao hang."),
    ("Hay thue Pizzaboy va bat dau ca lam viec truoc.",
     "Ban chua bat dau ca lam viec. Hay thue mot chiec Pizzaboy tai cua hang truoc khi nhan don giao hang."),
    ("Pizzaboy khong co banh. Hay quay ve Pizza Stack de lay hang.",
     "Chiec Pizzaboy cua ban hien khong con hop pizza nao. Hay quay ve Pizza Stack de lay them hang truoc khi nhan don moi."),
    ("Hay cat hop pizza dang cam truoc khi nhan don.",
     "Ban dang cam mot hop pizza tren tay. Hay cat hop vao xe hoac hoan tat thao tac hien tai truoc khi nhan don moi."),
    ("Ban dang co mot don giao chua hoan tat.",
     "Ban dang co mot don giao hang chua hoan tat. Hay giao don hien tai truoc khi yeu cau mot dia chi moi."),
    ("Ban can thue Pizzaboy truoc khi nhan banh.",
     "Ban can thue mot chiec Pizzaboy va bat dau ca lam viec truoc khi co the lay pizza tu khu chuan bi."),
    ("Hay xuong xe de nhan hop pizza.",
     "Ban phai roi khoi phuong tien va dung tai khu lay hang de nhan mot hop pizza."),
    ("Ban dang cam mot hop pizza.",
     "Ban dang cam mot hop pizza tren tay. Hay chat hop hien tai len Pizzaboy truoc khi lay them."),
    ("Pizzaboy da du 5/5 hop. Su dung /giaobanh de nhan don.",
     "Kho hang tren Pizzaboy da day 5/5 hop. Ban co the su dung /giaobanh de nhan mot dia chi giao hang."),
    ("Hay dua Pizzaboy lai gan khu lay banh truoc.",
     "Hay dua chiec Pizzaboy lai gan khu lay hang cua Pizza Stack truoc khi nhan them pizza."),
    ("Da nhan mot hop pizza. Den gan Pizzaboy va nhan Y de chat len xe.",
     "Ban da nhan mot hop pizza tu cua hang. Hay mang no den gan Pizzaboy va nhan Y de chat hop len xe."),
    ("Da co 1 banh tren xe. Ban co the dung /giaobanh ngay hoac lay them.",
     "Pizzaboy hien co 1 hop pizza. Ban co the su dung /giaobanh de nhan don ngay, hoac tiep tuc lay them hang."),
    ("Kho xe da day 5/5. Su dung /giaobanh de nhan dia chi giao.",
     "Kho hang tren Pizzaboy da day 5/5 hop. Su dung /giaobanh de nhan dia chi giao hang tiep theo."),
    ("Chi lay hop giao hang khi da den gan dia chi khach.",
     "Ban chi co the lay hop pizza giao cho khach khi da den gan dia chi duoc danh dau tren ban do."),
    ("Da lay hop giao hang. Mang den checkpoint va nhan Y.",
     "Ban da lay hop pizza can giao. Hay mang den diem giao duoc danh dau va nhan Y de ban giao cho khach."),
    ("Da dat hop pizza tro lai Pizzaboy.",
     "Ban da dat hop pizza tro lai Pizzaboy. Don hang van duoc giu va co the tiep tuc khi ban lay hop ra lai."),
    ("Hay quay lai Pizzaboy, nhan Y de lay hop pizza giao cho khach.",
     "Ban chua cam hop pizza cua don hang nay. Hay quay lai Pizzaboy, dung gan xe va nhan Y de lay hop giao cho khach."),
    ("Su dung /giaobanh de nhan don tiep theo.",
     "Tren xe van con pizza. Su dung /giaobanh khi ban san sang nhan dia chi giao hang tiep theo."),
    ("Xe da het banh. Quay ve lay them hoac dua xe den khu tra xe.",
     "Pizzaboy da het pizza. Hay quay ve Pizza Stack de lay them hang, hoac dua xe den khu tra xe neu ban muon ket thuc ca."),
    ("Dang tai ho so cong viec. Hay nhan Y lai sau giay lat.",
     "Ho so cong viec cua nhan vat dang duoc tai. Hay cho trong giay lat va nhan Y lai de tiep tuc.")
])
pizza = pizza.replace(
    'format(message, sizeof(message), "Don moi: %s. Den diem giao, xuong xe va nhan Y gan Pizzaboy de lay banh.", g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_ZONE]);',
    'format(message, sizeof(message), "Ban da nhan mot don giao hang moi tai %s. Hay di den diem duoc danh dau, xuong xe va nhan Y gan Pizzaboy de lay hop pizza.", g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_ZONE]);'
)
pizza = pizza.replace(
    'format(message, sizeof(message), "Da chat banh len Pizzaboy: %d/%d hop.", s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);',
    'format(message, sizeof(message), "Ban da chat hop pizza len Pizzaboy. Kho hang hien co %d/%d hop va san sang cho cac don giao.", s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);'
)
pizza = pizza.replace(
    'format(message, sizeof(message), "Giao banh thanh cong +$%d. Con %d/%d hop tren xe.", PIZZA_DELIVERY_BASE_PAY, s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);',
    'format(message, sizeof(message), "Ban da giao don hang thanh cong va nhan duoc $%d tien cong. Pizzaboy hien con %d/%d hop pizza.", PIZZA_DELIVERY_BASE_PAY, s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);'
)
write("pizza", pizza)

cinematic = read("cinematic")
old = 'SendClientMessage(playerid, COLOR_WHITE, "Chao mung tro lai Los Santos.");'
new = '''for (new line = 0; line < 20; line++)
    {
        SendClientMessage(playerid, COLOR_WHITE, " ");
    }

    SendClientMessage(
        playerid,
        COLOR_GRAY,
        "Chao mung tro lai Los Santos. Nhan vat cua ban da duoc tai hoan tat va ban co the tiep tuc phien Roleplay hien tai."
    );'''
if old in cinematic:
    cinematic = cinematic.replace(old, new, 1)
else:
    print("WARN: Khong thay welcome trong cinematic.pwn")
write("cinematic", cinematic)

character = read("character")
character = character.replace(
    '"Chao mung den voi Los Santos Roleplay."',
    '"Chao mung den voi Los Santos Roleplay. Ho so nhan vat da san sang; hay bat dau hanh trinh cua ban mot cach tu nhien va ton trong Roleplay."'
)
write("character", character)

print()
print("DA AP DUNG LSRP MESSAGE STYLE.")
print("Backup:", BACKUP)
for p in FILES.values():
    print(" -", p.relative_to(ROOT))
print()
print("Script chi sua message/UI text, khong thay doi logic gameplay.")
