# EasyAdmin-ox
> A heavily modified version of [Blumlaut's EasyAdmin](https://github.com/Blumlaut/EasyAdmin) for FiveM, built around [ox_lib](https://github.com/overextended/ox_lib).

---

> [!IMPORTANT]
> The resource folder **must** be named exactly `EasyAdmin-ox` or it will not work.
> [ox_lib](https://github.com/overextended/ox_lib) is **required**. Without it the duty system and other features will break.

---

## 📖 Documentation

Full setup guide, ConVars, ACE permissions, Original Permission List Included, Bot Setup, and more:

**➜ https://liam-3.gitbook.io/easyadmin-ox**

For the original EasyAdmin permission list:
**➜ https://easyadmin.readthedocs.io/en/latest/permissions/**

---

## 🎬 Preview

https://github.com/user-attachments/assets/75fefa1f-dea6-45e2-8855-7cf27cd67ad5

---

## ✨ What's New

> **Important:** Updates have been pushed since **06/05/2026**. Please update to the newest version.

- **Staff Tags** — Clocked-in staff members now display their rank above their name. Name turns green when on duty. Configure in `plugins/rank_config.lua`
- **Hide Own Rank** — Staff with the correct ACE can hide their own tag from other players
- **ox_target Integration** — Ban, kick, revive, respawn and more directly through [ox_target](https://github.com/overextended/ox_target) while clocked in
- **Kill/Death Log** — View a player's recent kills and deaths within the last 30 minutes directly from the menu — useful for tracking RDM/VDM
- **Remove All Player Weapons** — Clears the inventory of a selected player from the misc options
- **Show Player Names** — See other players' names through EasyAdmin (disable noclip in vMenu to avoid conflicts)
- **Staff Duty System** — Full clock in/out system with webhooks, DMs, abuse detection, hour tracking, and suspension management
- **Action/Punishment History** — Every ban is logged with Ban ID, duration, and moderator info, viewable in-menu and via Discord bot

---

## ⚡ Quick Install

1. Download the zip
2. Extract and place the folder in your server's `resources` directory
3. **Rename the folder to `EasyAdmin-ox`**
4. Add to your `server.cfg`:
   ```
   ensure EasyAdmin-ox
   ```
5. Add your ACE permissions — see the [documentation](https://liam-3.gitbook.io/easyadmin-ox)
6. Restart your server

---

## 🤝 Contributing

Found a bug? Have a fix?

- [Open an issue](https://github.com/IOwnSpaceX/EasyAdmin-ox/issues)
- [Submit a pull request](https://github.com/IOwnSpaceX/EasyAdmin-ox/pulls)

---

## 🙏 Credits

- [Blumlaut](https://github.com/Blumlaut) — Original EasyAdmin
- [overextended](https://github.com/overextended) — ox_lib & ox_target
- [ItsAmmarB](https://github.com/ItsAmmarB) — DeathScript base
- [Liam](https://github.com/IOwnSpaceX) (IOwnSpaceX) — EasyAdmin-ox modifications
