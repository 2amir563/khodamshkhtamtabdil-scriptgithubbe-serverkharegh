در ادامه به صورت شفاف و برای هر مثالی که قبلاً مطرح کردید، نشان می‌دهم که دستور نصب اصلی چگونه با استفاده از سیستم جدید شما تغییر می‌کند.

یادآوری: شما همیشه از یک دستور اصلی روی سرور خارج خود استفاده می‌کنید که اسکریپت manager.sh شما را فراخوانی می‌کند:
bash <(curl -sL https://raw.githubusercontent.com/2amir563/khodamshkhtamtabdil-scriptgithubbe-serverkharegh/main/manager.sh)

مثال ۱: اسکریپت ساده (rgt_manager.sh)
دستور اصلی (قبل):

Bash

bash <(curl -Ls https://raw.githubusercontent.com/black-sec/RGT/main/rgt_manager.sh)
روش جدید (بعد):

در سرور خارج اجرا کنید:

Bash

bash <(curl -sL https://.../manager.sh) https://raw.githubusercontent.com/black-sec/RGT/main/rgt_manager.sh
خروجی برای اجرا در سرور ایران:
اسکریپت شما دستوری مشابه زیر تولید می‌کند که آن را در سرور ایران اجرا می‌کنید:

Bash

bash <(curl -Ls http://IP_سرور_خارج:PORT/e5f6g7h8/rgt_manager.sh)
مثال ۲: اسکریپت زنجیره‌ای (FreeIRANbarestartsystem.sh)
دستور اصلی (قبل):

Bash

curl -O https://.../FreeIRANbarestartsystem.sh && chmod +x ... && ./FreeIRANbarestartsystem.sh
روش جدید (بعد):

در سرور خارج اجرا کنید:

Bash

bash <(curl -sL https://.../manager.sh) https://raw.githubusercontent.com/2amir563/freeIranbarestartsystem/refs/heads/main/FreeIRANbarestartsystem.sh
خروجی و دستور نهایی برای سرور ایران:
اسکریپت شما یک لینک دانلود تولید می‌کند (نه یک دستور کامل bash). مثلاً: http://IP_سرور_خارج:PORT/a1b2c3d4/FreeIRANbarestartsystem.sh

حالا شما باید بخش اول دستور اصلی را با این لینک جدید جایگزین کنید:

Bash

curl -O http://IP_سرور_خارج:PORT/a1b2c3d4/FreeIRANbarestartsystem.sh && chmod +x FreeIRANbarestartsystem.sh && sed ... && ./FreeIRANbarestartsystem.sh
مثال ۳: اسکریپت با لینک کوتاه (bit.ly)
دستور اصلی (قبل):

Bash

bash <(curl -fsSL https://bit.ly/config-installer)
روش جدید (بعد):

در سرور خارج اجرا کنید:

Bash

bash <(curl -sL https://.../manager.sh) https://bit.ly/config-installer
خروجی برای اجرا در سرور ایران:
اسکریپت شما دستوری مشابه زیر تولید می‌کند:

Bash

bash <(curl -Ls http://IP_سرور_خارج:PORT/b2c3d4e5/config-installer)
مثال ۴: اسکریپت ساخت تانل (install.sh)
دستور اصلی (قبل):

Bash

bash <(curl -Ls https://raw.githubusercontent.com/Mehdi682007/PDIPV6TUN/main/install.sh)
روش جدید (بعد):

در سرور خارج اجرا کنید:

Bash

bash <(curl -sL https://.../manager.sh) https://raw.githubusercontent.com/Mehdi682007/PDIPV6TUN/main/install.sh
خروجی برای اجرا در سرور ایران:
اسکریپت شما دستوری مشابه زیر تولید می‌کند:

Bash

bash <(curl -Ls http://IP_سرور_خارج:PORT/c3d4e5f6/install.sh)
مثال ۵: اسکریپت بلاک چندخطی (restart_scheduler.py)
دستور اصلی (قبل):

Bash

sudo bash -c '
    ...
    SCRIPT_URL="https://raw.githubusercontent.com/.../restart_scheduler.py";
    ...
'
روش جدید (بعد):

در سرور خارج اجرا کنید:

Bash

bash <(curl -sL https://.../manager.sh) https://raw.githubusercontent.com/2amir563/restart-at-moultitime/refs/heads/main/restart_scheduler.py
خروجی و دستور نهایی برای سرور ایران:
اسکریپت شما یک لینک دانلود تولید می‌کند. مثلاً: http://IP_سرور_خارج:PORT/d4e5f6g7/restart_scheduler.py

شما باید مقدار متغیر SCRIPT_URL را در بلاک کد اصلی با این لینک جدید جایگزین کنید:

Bash

sudo bash -c '
    ...
    SCRIPT_URL="http://IP_سرور_خارج:PORT/d4e5f6g7/restart_scheduler.py";
    ...
'
