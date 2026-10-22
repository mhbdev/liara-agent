**فارسی** · [English](../en/04-providers.md)

# ۴. تنظیم محیط کدنویسی

اول [پکیج را در مخزن وب‌سایت خودتان نصب کنید](00-installation.md). همه مسیرها
و دستورهای این صفحه نسبت به ریشه همان مخزن هستند. پس از افزودن فایل‌ها،
ایجنت را در همان پوشه شروع یا دوباره اجرا کنید.

این صفحه **اتصال‌هایی را توضیح می‌دهد که این پکیج آماده کرده است**، نه تمام
قابلیت‌های هر سرویس. شش فایل نقش و اسکریپت‌ها در محیط‌های دیگر هم قابل
استفاده‌اند؛ ولی اطلاعات مخصوص Claude در فایل‌ها، خودکار ایجنت و دستور
بومی در سرویس دیگر ایجاد نمی‌کند.

| اتصال پکیج | Claude Code | Codex CLI / IDE / desktop | Cursor / Windsurf | Aider | Gemini CLI |
|---|---|---|---|---|---|
| دستورالعمل پروژه | `CLAUDE.md` ← `AGENTS.md` | `AGENTS.md` | `AGENTS.md` یا قوانین ویرایشگر | `--read` | وارد کردن در `GEMINI.md` |
| نقش‌های پکیج | شش زیرایجنت بومی | خواندن فایل نقش | خواندن فایل نقش | `--read` نقش | خواندن فایل نقش |
| دستورهای `/liara-*` پکیج | بله | پرامپت متنی | پرامپت متنی | پرامپت متنی | پرامپت متنی |
| هوک قفل پکیج | با فعال بودن تنظیمات ادغام‌شده | متصل نیست | متصل نیست | متصل نیست | متصل نیست |

فقط تنظیمات Claude این پکیج، `scripts/guard.sh` را به اجرای ابزار Bash وصل
می‌کند. سرویس‌های دیگر ممکن است هوک داشته باشند، ولی پکیج آن‌ها را تنظیم
نمی‌کند. پیش از دسترسی به محیط اصلی، حتی در Claude Code،
[شکاف‌های امنیتی شناخته‌شده](07-security.md) را بخوانید.

## Claude Code

۱. `CLAUDE.md`، کل `.claude/` و اسکریپت‌های مشترک را طبق راهنمای نصب اضافه
   یا ادغام کنید. کپی فقط `.claude/agents/`، هوک و مجوزها را نصب نمی‌کند.
۲. اگر پروژه `.claude/settings.json` دارد، ورودی‌های فعلی را هنگام ادغام
   `hooks.PreToolUse` و آرایه‌های مجوز نگه دارید. دستور قفل
   `sh "$CLAUDE_PROJECT_DIR/scripts/guard.sh"` را دست‌نخورده نگه دارید.
۳. نشست تازه Claude Code را در مخزن وب‌سایت باز کنید. پیام‌های اعتماد به
   پروژه یا بازبینی هوک را بررسی کنید؛ سپس فهرست شش نقش `liara-*` و توضیح
   قرارداد `AGENTS.md` را بخواهید.
۴. بررسی‌های نصب را در ترمینال انجام دهید. فعال بودن هوک را در خود محیط هم
   بررسی کنید؛ وجود فایل‌ها به‌تنهایی اثبات فعال بودن نیست.

سپس از دستورهای پروژه استفاده کنید:

```text
/liara-login          # اتصال؛ توکن را خودتان در ترمینال واقعی وارد می‌کنید
/liara-setup          # تنظیم وب‌سایت
/liara-status
/liara-deploy staging
/liara-plan
/liara-diagnose
/liara-report
```

می‌توانید بگویید: «با نقش liara-connect کمک کن حساب محیط آزمایشی را وصل کنم».
اجرای `sh scripts/setup.sh connect staging` باید به خود شما واگذار شود.

در ویندوز از Git Bash استفاده کنید؛ محیطی که Claude را اجرا می‌کند باید
`sh` را پیدا کند. قبل از موفقیت بررسی‌ها و فعال‌سازی در محیط، به هوک تکیه
نکنید. مرجع رسمی: [زیرایجنت‌های Claude](https://code.claude.com/docs/en/sub-agents)
و [تنظیمات پروژه](https://code.claude.com/docs/en/settings).

## Codex CLI، افزونه و برنامه دسکتاپ

مخزن وب‌سایت را به‌عنوان پروژه باز کنید. Codex فایل `AGENTS.md` ریشه را
شناسایی می‌کند. نشست تازه‌ای باز کنید و خلاصه پنج قانون و مسیر نقش انتخابی
را بخواهید. وجود `AGENTS.override.md` را بررسی کنید؛ در همان پوشه می‌تواند
جای قرارداد را بگیرد. مرجع رسمی:
[راهنمای AGENTS.md](https://developers.openai.com/codex/guides/agents-md/).

برای **CLI** با دسترسی محلی فقط‌خواندنی شروع کنید:

```bash
codex --sandbox read-only --ask-for-approval on-request \
  "AGENTS.md و .claude/agents/liara-connect.md را بخوان. روش اتصال محیط آزمایشی را توضیح بده؛ ورود توکن با خودم است."
```

برای تنظیم پروژه، وصله یا انتشار آزمایشی که به نوشتن فایل و شبکه نیاز دارد:

```bash
codex --sandbox workspace-write --ask-for-approval on-request \
  -c sandbox_workspace_write.network_access=true \
  "طبق AGENTS.md و .claude/agents/liara-onboarding.md این وب‌سایت را برای محیط آزمایشی تنظیم کن."
```

`on-request` یعنی ایجنت در صورت نیاز می‌تواند تأیید بخواهد؛ به معنی سؤال
قبل از هر دستور نیست. حالت فقط‌خواندنی نوشتن محلی را محدود می‌کند، نه تغییر
حساب از راه شبکه را. حتی اسکریپت‌های وضعیت، گزارش و فایل محلی می‌نویسند و
ممکن است درخواست مجوز بررسی‌شده لازم داشته باشند؛ برای اجرا، دسترسی را
بی‌اطلاع گسترده نکنید.

در **افزونه یا دسکتاپ** همان پوشه وب‌سایت را باز کنید، محدودسازی و تأییدهای
در دسترس را انتخاب کنید و نقش را با پرامپت متنی بخواهید. گزینه‌های بالا
مخصوص CLI هستند. پکیج، زیرایجنت‌ها یا دستورهای `/liara-*` مربوط به Claude
را در این محیط‌ها ثبت نمی‌کند.

### تنظیمات اختیاری Codex و شناسایی مهارت

اگر پروژه تنظیمات ندارد، می‌توانید [`.codex/config.toml`](../../.codex/config.toml)
پکیج را در `.codex/` پروژه کپی کنید؛ در غیر این صورت سه تنظیم آن را با فایل
فعلی ادغام کنید. پیش‌فرض فقط‌خواندنی با تأیید `on-request` است و مدل انتخابی
شما حفظ می‌شود. تنظیمات پروژه فقط برای پروژه مورد اعتماد بارگذاری می‌شوند.
Codex فعلی پروفایل‌های تنظیمات داخل فایل پروژه را نادیده می‌گیرد و دیگر
`approval_policy = "untrusted"` را نمی‌پذیرد؛ دستورهای صریح بالا جایگزین
مثال‌های قدیمی پروفایل `liara-*` شده‌اند. مرجع رسمی:
[تنظیمات Codex](https://developers.openai.com/codex/config-reference/).

برای شناسایی خودکار **مهارت**، پوشه کامل `.claude/skills/liara-ops/` را
همچنین به `.agents/skills/liara-ops/` در مخزن وب‌سایت کپی کنید. مهارت موجود
در مقصد را حفظ کنید و این کپی را با هر به‌روزرسانی پکیج تازه کنید. سپس
می‌توانید `$liara-ops` را در پرامپت ذکر کنید. بدون این کپی اختیاری، صریحاً
بخواهید قبل از عملیات `.claude/skills/liara-ops/SKILL.md` خوانده شود.
مرجع رسمی: [راهنمای مهارت‌ها](https://developers.openai.com/codex/skills/).

این تنظیمات و مهارت، هوک Claude پکیج را در Codex فعال نمی‌کنند. پیش از
تغییر، روش بررسی دستی قفل در انتهای این صفحه را انجام دهید.

## Cursor و Windsurf

مخزن وب‌سایت را باز کنید. هر دو از دستورالعمل پروژه در `AGENTS.md` پشتیبانی
می‌کنند. برای قانون صریح ویرایشگر، فایل مناسب زیر را با حفظ قوانین فعلی
اضافه کنید؛ قالب Cursor با Windsurf فرق دارد.

**Cursor:** فایل `.cursor/rules/liara.mdc`

```markdown
---
description: Liara operations
alwaysApply: true
---
Before any Liara task, read and follow AGENTS.md and
.claude/skills/liara-ops/SKILL.md. Read the chosen role in .claude/agents/.
Use LIARA_ENV=staging sh scripts/liara.sh for CLI operations.
Leave token entry and approval grants to the human.
```

**Windsurf:** فایل `.windsurf/rules/liara.md`

```markdown
---
trigger: always_on
---
Before any Liara task, read and follow AGENTS.md and
.claude/skills/liara-ops/SKILL.md. Read the chosen role in .claude/agents/.
Use LIARA_ENV=staging sh scripts/liara.sh for CLI operations.
Leave token entry and approval grants to the human.
```

چت تازه‌ای باز کنید و معرفی قرارداد و پیروی از
`.claude/agents/liara-connect.md` برای محیط آزمایشی را بخواهید. بررسی کنید
قانون در زمینه چت آمده باشد. این فایل‌ها دستورالعمل می‌دهند؛ قفل اجرای
دستور پکیج را متصل نمی‌کنند. مراجع رسمی:
[قوانین Cursor](https://cursor.com/docs/context/rules) و
[قوانین Windsurf](https://docs.windsurf.com/windsurf/cascade/memories).

## Aider

از مخزن وب‌سایت، قرارداد، مرجع و نقش را به‌صورت زمینه فقط‌خواندنی بارگذاری کنید:

```bash
aider --read AGENTS.md --read .claude/skills/liara-ops/SKILL.md \
  --read .claude/agents/liara-connect.md
```

یا این ورودی‌ها را به فهرست `read` فعلی در `.aider.conf.yml` اضافه کنید:

```yaml
read:
  - AGENTS.md
  - .claude/skills/liara-ops/SKILL.md
  - .claude/agents/liara-connect.md
```

توضیح روند اتصال آزمایشی را بخواهید. برای نقش دیگر، مسیر آخر را عوض کنید.
گزینه `--read` جلوی ویرایش فایل‌های زمینه را می‌گیرد؛ محیط اجرای دستورها را
محدود نمی‌کند. پکیج هوک Aider نصب نمی‌کند. مرجع رسمی:
[گزینه‌های Aider](https://aider.chat/docs/config/options.html).

## Gemini CLI

با حفظ دستورالعمل‌های فعلی، این ارجاع صریح را به `GEMINI.md` وب‌سایت اضافه کنید:

```markdown
@./AGENTS.md

Before Liara operations, read .claude/skills/liara-ops/SKILL.md and the
chosen role in .claude/agents/. Default to staging; token entry and approval
grants belong to the human.
```

Gemini را در مخزن وب‌سایت دوباره اجرا کنید. با `/memory show` بارگذاری
قرارداد را بررسی کنید؛ سپس پیروی از `.claude/agents/liara-connect.md` را
بخواهید. پکیج هوک Gemini نصب نمی‌کند. مرجع رسمی:
[راهنمای GEMINI.md](https://geminicli.com/docs/cli/gemini-md/).

## ایجنت‌های کدنویسی دیگر

از نشست پروژه با دسترسی به فایل و اجرای POSIX shell استفاده کنید. متن زیر
را به دستورالعمل پروژه اضافه کنید یا در اولین پرامپت بفرستید:

```text
اول AGENTS.md و .claude/skills/liara-ops/SKILL.md را بخوان.
برای این کار از .claude/agents/liara-connect.md پیروی کن.
از ریشه مخزن وب‌سایت کار کن و پیش‌فرض را محیط آزمایشی بگذار.
برای ابزار لیارا فقط از LIARA_ENV=staging sh scripts/liara.sh استفاده کن.
پیش از تغییر، قفل دستور را بررسی کن. ورود توکن و ساخت تأییدیه با انسان است.
قدم بعدی را بدون درخواست توکن توضیح بده.
```

برای تنظیم، انتشار، وضعیت، پلن یا تعمیر، مسیر نقش را عوض کنید. قبل از عملیات
فهرست فایل‌های بارگذاری‌شده را بخواهید. چت بدون دسترسی به فایل یا shell
می‌تواند راهنما را توضیح بدهد ولی پکیج را اجرا نمی‌کند.

## بررسی دستی قفل بیرون از Claude Code

قرارداد پیش از هر دستور تغییردهنده بررسی قفل را لازم می‌داند. برای مثال،
پس از اتصال آزمایشی و موفقیت بررسی پیش از انتشار، این دستور ثابت را بررسی کنید:

```bash
CMD='LIARA_ENV=staging sh scripts/liara.sh deploy --app my-site-staging --path .'
printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$CMD" \
  | sh scripts/guard.sh && eval "$CMD"
```

نام برنامه نمونه را با برنامه آزمایشی تنظیم‌شده عوض کنید. ساخت JSON بالا
مخصوص همین دستور ثابت است؛ دستور دارای نقل‌قول، بک‌اسلش یا خط جدید به
کدگذاری درست JSON نیاز دارد. فقط همان دستوری را اجرا کنید که بررسی شده و
اگر قفل رد کرد متوقف شوید. بررسی دستی، دستورهای بعدی ابزار را خودکار کنترل
نمی‌کند.

از محدودسازی محیط اجرا و بازبینی تغییرهای مهم استفاده کنید. رمز محیط اصلی
را در محیطی که قفل پکیج فعال نیست نگه ندارید. نوشتن روی محیط اصلی همچنان
نیاز به تأییدیه یک‌بارمصرف انسان طبق [راهنمای دسترسی‌ها](02-credentials.md)
دارد؛ پیام مجوز محیط کدنویسی جای آن تأییدیه را نمی‌گیرد. پس از انتشار، پیش
از اعلام موفقیت، بررسی سلامت را انجام دهید.
