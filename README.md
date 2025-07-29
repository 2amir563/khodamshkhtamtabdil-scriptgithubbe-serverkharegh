

برای نصب 
```
bash <(curl -sL https://raw.githubusercontent.com/2amir563/khodamshkhtamtabdil-scriptgithubbe-serverkharegh/refs/heads/main/proxy.sh) URL_اسکریپت_مورد_نظر
```

فقط کافیست URL_اسکریپت_مورد_نظر را با آدرس اسکریپتی که می‌خواهید نصب کنید، جایگزین نمایید.


دستور یک خطی برای حذف اسکریپت‌ها
هر زمان که خواستید اسکریپت‌های دانلود شده را مدیریت یا حذف کنید، کافیست این دستور یک خطی را روی سرور خارج خود اجرا کنید:
 برای اجرای اسکریپت cleanup.sh از گیت‌هاب خودتان است.

این دستور را روی سرور خارج خود اجرا کنید:

```
bash <(curl -sL https://raw.githubusercontent.com/2amir563/khodamshkhtamtabdil-scriptgithubbe-serverkharegh/refs/heads/main/cleanup.sh)
```

دستور کامل برای پاک‌سازی
این دستور را به طور کامل کپی و در سرور خارج خود اجرا کنید:

```
pkill -f "python3 -m http.server 8000"; rm -rf ~/dl_files ~/proxy.sh ~/cleanup.sh; sudo ufw delete allow 8000/tcp
```
