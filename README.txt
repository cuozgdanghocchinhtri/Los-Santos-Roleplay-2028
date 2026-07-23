LSRP DEPENDENCY MANAGER
=======================

Dat tat ca file trong ZIP vao root LSRP_SERVER.

Lan sau muon them plugin moi:
1. Mo dependencies.json.
2. Them mot object vao mang "dependencies".
3. Ghi repo GitHub, tag va ten file can copy.
4. Chay INSTALL_DEPS.bat.

Vi du plugin co:
  abc.inc
  abc.dll

Them:

{
    "name": "ABC Plugin",
    "type": "github_release",
    "repo": "author/abc-plugin",
    "tag": "v1.0.0",
    "asset_patterns": [
        "win32.*\\.zip$",
        ".*\\.zip$"
    ],
    "copies": [
        {
            "find": "abc.inc",
            "to": "qawno/include/abc.inc"
        },
        {
            "find": "abc.dll",
            "to": "plugins/abc.dll"
        }
    ]
}

Sau do chay INSTALL_DEPS.bat.

Luu y:
- Tag phai dung tag GitHub Release.
- Package release hien tai can la ZIP.
- Ten DLL/INC trong "find" phai dung ten file that su trong ZIP.
- Plugin runtime legacy thuong vao plugins/.
- Include compile vao qawno/include/.
- Component open.mp co the can destination components/ thay vi plugins/.
