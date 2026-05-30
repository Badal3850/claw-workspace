# HEARTBEAT.md — Proactive Checks

> Jab bhi heartbeat fire ho, yeh checklist follow karo. Sirf tab reach out karo jab kuch genuinely important ho.

---

## ⏰ Time Check Pehle

**Raat 23:00 se subah 08:00:** Sirf emergency mein reach out karo. Kuch aur nahi.
**Agar sir se 30 min pehle baat hui:** Chup raho.
**Agar last check mein kuch nahi badla:** Chup raho.

---

## 📋 Quick Checklist (2-3 min max)

### 1. System Health Check
```bash
# Check disk space — report sirf >80% usage ho toh
wmic logicaldisk get size,freespace,caption

# Check uptime
net stats workstation | find "Statistics since"
```
**Reach out sirf:** Disk >90% full ho, ya system 7+ days se reboot nahi hua.

### 2. Workspace Git Status
```bash
cd ~/.openclaw/workspace && git status --short
```
**Reach out sirf:** Koi unstaged changes ho jo commit kiye ja sakte hain. (Khud commit mat karo bina poochhe.)

### 3. Critical Services Check
```bash
# Check if Telegram gateway is running
openclaw gateway status
```
**Reach out sirf:** Gateway down ho.

### 4. Memory Maintenance (Every 3-4 heartbeats)
- Check `memory/` directory for any notes
- Agar recent sessions ki koi important baat yaad rakhni hai, toh note karo
- Prune outdated info from MEMORY.md

---

## ✅ Response Templates

**Sab theek hai:**
> HEARTBEAT_OK

**Kuch issue hai:**
> "Sir, maine dekha ki [issue]. Aapka dhyan chahta hai."

**Late night check (23:00-08:00, no emergency):**
> HEARTBEAT_OK

---

## 📊 State Tracking

Check frequency track rakhne ke liye, jaise bhi check karo, `memory/heartbeat-state.json` mein update karo:

```json
{
  "lastDiskCheck": "2026-05-31",
  "lastGitCheck": "2026-05-31", 
  "lastMemoryMaintenance": "2026-05-30"
}
```

Yeh track karega ki kab kya check kiya, taake har heartbeat mein sab kuch repeat na ho. Ek din mein 1-2 baar system health kaafi hai.