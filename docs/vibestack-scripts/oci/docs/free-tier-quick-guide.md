# Oracle Cloud Free Tier - Quick Guide

## 🎯 The Golden Rule
**Stay in your HOME REGION** - Always Free resources only work in the region you choose during signup. Choose wisely - you can't change it later!

## 💳 What's Free Forever?

### Servers (Ampere A1 - ARM-based)
- **4 OCPUs + 24 GB RAM total** - Split however you want:
  - 1 big server (4 OCPU, 24GB RAM) OR
  - 2 medium servers (2 OCPU, 12GB RAM each) OR  
  - 4 small servers (1 OCPU, 6GB RAM each)

### Storage
- **200 GB** block storage (for your server hard drives)
- **20 GB** object storage (for backups/files)

### Network
- **10 TB/month** data transfer out (downloading from your servers)
- **1 Load Balancer** (10 Mbps)
- **2 Virtual Networks**
- Unlimited incoming traffic

### Databases
- **2 Autonomous Databases** (20 GB each)
- **1 MySQL HeatWave** (50 GB)

## ⚠️ Stay Free Checklist

✅ **DO:**
- Create everything in your HOME REGION
- Monitor your usage regularly  
- Set up alerts before hitting limits
- Use ARM-based (Ampere A1) instances
- Keep total OCPUs ≤ 4 and RAM ≤ 24 GB

❌ **DON'T:**
- Create resources outside your home region
- Exceed the limits above
- Use Intel/AMD instances (except the tiny free ones)
- Expect Oracle Support (community forums only)
- Forget that "Free Trial" ends after 30 days (but "Always Free" is permanent)

## 🚨 Common Mistakes

1. **"Out of capacity" error?** → Try again later or different availability zone
2. **Resources disappeared?** → Your 30-day trial ended; Always Free resources remain
3. **Getting charged?** → You exceeded limits or created resources outside home region
4. **Can't create 5th OCPU?** → Maximum is 4 OCPUs total across ALL servers

## 📊 Quick Math Examples

### ✅ Valid Free Configurations:
- 2 servers: 2 OCPU + 12 GB RAM each = 4 OCPU + 24 GB ✓
- 1 server: 4 OCPU + 24 GB RAM ✓
- 3 servers: 1 OCPU + 8 GB each = 3 OCPU + 24 GB ✓

### ❌ Will Cost Money:
- 2 servers: 3 OCPU + 12 GB each = 6 OCPU ✗ (exceeds 4 OCPU limit)
- 1 server: 4 OCPU + 32 GB RAM ✗ (exceeds 24 GB limit)
- Any servers in non-home region ✗

## 🎁 The Bottom Line

You get enough resources to run **2 decent servers** or **4 small servers** completely FREE, FOREVER - just follow the limits and stay in your home region!

---
*Remember: Free Trial (US$300 for 30 days) is different from Always Free (permanent). This guide covers Always Free only.*