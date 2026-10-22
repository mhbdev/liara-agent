**فارسی** · [English](../en/04-providers.md)

# ۴. اجرای ایجنت‌ها روی هر سرویس هوش مصنوعی

این پکیج عمداً ساده است: دستورالعمل‌های Markdown به‌علاوه اسکریپت‌های POSIX
shell. هر ایجنت کدنویسی می‌تواند اجرایش کند. تفاوت بین سرویس‌ها در این است که
**چقدر از قوانین به‌صورت خودکار اعمال می‌شود** در برابر چقدر به انضباط خود ایجنت
وابسته است.

این جدول را قبل از انتخاب بخوانید. خلاصه صادقانه همین است.

| | Claude Code | Codex CLI | Cursor / Windsurf | Aider | Gemini CLI |
|---|---|---|---|---|---|
| خواندن `AGENTS.md` | از طریق `CLAUDE.md` | بله، خودکار | بله | با `--read` | بله |
| نقش‌های جدا | **زیرایجنت واقعی** | پروفایل + پرامپت | فقط پرامپت | فقط پرامپت | فقط پرامپت |
| دستورهای `/` | **بله** | نه | نه | نه | نه |
| **اعمال خودکار قفل امنیتی** | **بله** | **نه** | **نه** | **نه** | **نه** |
| مسدودسازی مسیر فایل | **بله** | فقط sandbox | نه | نه | نه |
| Sandbox | لیست مجاز هر ابزار | **بله، قوی** | نه | نه | محدود |

**تنها نتیجه‌گیری مهم:** `scripts/guard.sh` **فقط روی Claude Code** خودکار اجرا
می‌شود. در بقیه، محافظت در برابر دستورهای مخرب و خواندن رمزها خودکار نیست.
اسکریپت‌ها کار می‌کنند؛ اما *اجبار* وجود ندارد.

اگر قرار است یک مبتدی این سیستم را اداره کند، از Claude Code استفاده کنید. این
سلیقه نیست — تنها حالتی است که محافظ‌ها بدون نیاز به اینکه ایجنت خودش بخواهد
رعایت کند، کار می‌کنند.

---

## Claude Code — کاملاً اعمال‌شده

چیزی برای تنظیم نیست؛ از قبل وصل است.

```
/liara-setup          # بار اول
/liara-status         # سایت بالاست؟
/liara-deploy staging
/liara-plan
/liara-diagnose
/liara-report
```

چه چیزی فعال است:

- `scripts/guard.sh` به‌عنوان **هوک PreToolUse روی Bash** — دستورهای مخرب،
  خواندن رمز، صدا زدن مستقیم `liara` و نوشتن بدون تأیید روی محیط اصلی را مسدود
  می‌کند
- `permissions.deny` — خواندن `.liara/**` و `.env` و ویرایش `guard.sh`،
  `approve.sh`، `preflight.sh` و `settings.json` را می‌بندد
- پنج زیرایجنت، هر کدام با فهرست ابزار مخصوص خودش

خودتان مطمئن شوید واقعاً روشن است — به حرف این سند اکتفا نکنید:

```bash
sh scripts/doctor.sh       # شامل تست خودکار قفل
sh scripts/test-guard.sh   # مجموعه کامل تست
```

**ویندوز:** هوک‌ها با `sh` (Git Bash) اجرا می‌شوند. اگر `sh` در PATH نباشد،
**هوک اجرا نمی‌شود و دستورها بدون محافظ اجرا می‌شوند.** `doctor.sh` دقیقاً همین
را چک می‌کند. ردش نکنید.

---

## Codex CLI — به‌جای هوک، sandbox

Codex فایل `AGENTS.md` را خودکار می‌خواند. اما **هوک PreToolUse ندارد**، پس
جایش از sandbox استفاده کنید:

```bash
codex --profile liara-sre     "وضعیت سایت چطور است؟"
codex --profile liara-deploy  "روی محیط آزمایشی منتشر کن و تأیید بگیر"
codex --profile liara-prod    "روی محیط اصلی منتشر کن"
```

پروفایل‌ها در [`.codex/config.toml`](../../.codex/config.toml):

| پروفایل | sandbox | تأیید | برای |
|---|---|---|---|
| `liara-sre` | `read-only` | on-request | پایش، لاگ، پلن — **اصلاً نمی‌تواند چیزی را عوض کند** |
| `liara-deploy` | `workspace-write` | on-request | انتشار، وصله |
| `liara-prod` | `workspace-write` | `untrusted` (هر دستور) | محیط اصلی |

`liara-sre` را پیش‌فرض کنید. یک sandbox فقط‌خواندنی یک کنترل ساختاری واقعی است
و بیشتر چیزی که یک مبتدی لازم دارد را پوشش می‌دهد.

اجرای یک نقش با ارجاع:

```
از .claude/agents/liara-sre.md پیروی کن و وضعیت فعلی را گزارش بده
```

اجرای دستی قفل قبل از یک دستور تغییردهنده:

```bash
CMD='LIARA_ENV=staging sh scripts/liara.sh deploy --app my-site --path .'
printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$CMD" \
  | sh scripts/guard.sh && eval "$CMD"
```

نام فیلدها برای Codex CLI حدود نسخه ۰.۱۲۵ درست بود؛ اگر کلیدی رد شد، در
<https://developers.openai.com/codex> بررسی کنید.

---

## Cursor / Windsurf

فایل قوانین را به قرارداد ارجاع بدهید، نه اینکه تکرارش کنید:

`.cursor/rules/liara.mdc`
```markdown
---
description: Liara operations
alwaysApply: true
---
دقیقاً از @AGENTS.md پیروی کن. فقط از `sh scripts/liara.sh` استفاده کن — هرگز
`liara` خالی. پیش‌فرض LIARA_ENV=staging. نوشتن روی محیط اصلی نیاز به تأیید
انسان دارد. هرگز توکن نخواه و نخوان.
```

**هیچ اجبار هوکی وجود ندارد.** آن را یک دستیار توانا بدانید، نه یک اپراتور
محافظت‌شده — و رمز محیط اصلی را روی آن دستگاه نگذارید.

---

## Aider

```bash
aider --read AGENTS.md --read .claude/skills/liara-ops/SKILL.md
```

در `.aider.conf.yml`:
```yaml
read: [AGENTS.md, .claude/skills/liara-ops/SKILL.md]
```

بدون هوک. ولی اینکه Aider برای هر تغییر یک کامیت می‌سازد با قانون «تعمیر = وصله»
خوب جور درمی‌آید، چون هر تغییر در گیت قابل بازبینی است.

---

## Gemini CLI

در `GEMINI.md`:

```markdown
# GEMINI.md
دقیقاً از AGENTS.md این مخزن پیروی کن، از جمله هر پنج قانون.
```

بدون اجبار هوکی.

---

## اگر مجبورید روی سرویس بدون هوک کار کنید

اجبار را با محدود کردن دامنه جایگزین کنید:

۱. **رمز محیط اصلی را روی آن دستگاه ذخیره نکنید.** فقط
   `sh scripts/creds.sh set staging`. این قوی‌ترین کنترل موجود است و هیچ ابزاری
   لازم ندارد.
۲. روی اپ اصلی **حالت فقط‌خواندنی** را فعال کنید:
   `POST /v1/projects/{id}/read-only/enable`
۳. از sandbox خود آن سرویس در سخت‌گیرانه‌ترین حالت استفاده کنید.
۴. `sh scripts/test-guard.sh` را دستی اجرا کنید و گزارش را بخوانید:
   `cat state/audit.log`
۵. به‌جای ایجنت، از CI منتشر کنید — آن‌وقت توکن در CI می‌ماند و ایجنت فقط نتیجه
   را می‌خواند.

## مستقل از سرویس، از روی طراحی

| بخش | قالب | وابسته به یک سرویس؟ |
|---|---|---|
| `AGENTS.md` | Markdown | نه |
| `.claude/agents/*.md` | Markdown + frontmatter | frontmatter در بقیه نادیده گرفته می‌شود |
| `scripts/*.sh` | POSIX sh | نه |
| `.claude/skills/liara-ops/` | Markdown | نه |
| `.claude/settings.json` | JSON | فقط Claude Code |
| `.codex/config.toml` | TOML | فقط Codex |

اگر سرویس را عوض کنید، فقط «اجبار» را از دست می‌دهید؛ بقیه سر جایش می‌ماند.
