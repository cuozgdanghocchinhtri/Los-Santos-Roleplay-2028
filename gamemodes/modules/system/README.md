# LS:RP System Modules

Mỗi gameplay system nằm trong một thư mục riêng dưới `modules/system`.

Ví dụ:

```text
modules/
└── system/
    ├── mechanic/
    │   ├── core.pwn
    │   ├── commands.pwn
    │   ├── vehicles.pwn
    │   └── dialogs.pwn
    ├── vehicles/
    ├── jobs/
    └── factions/
```

Quy ước:

- `core.pwn`: state, lifecycle và logic chính của system.
- `commands.pwn`: command của system.
- `dialogs.pwn`: dialog, textdraw và menu.
- `data.pwn` hoặc `utils.pwn`: hằng số, getter/setter và helper.
- Mỗi system được include từ `gamemodes/main.pwn`.
- Không đặt dữ liệu gameplay lâu dài vào `modules/utils`.
- System tạm thời phải có cờ `*_ENABLED` và ghi rõ cách remove.
