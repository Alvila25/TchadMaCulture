INSTALLED_APPS = [
    ...
    'culture.apps.CultureConfig',
    'django.contrib.staticfiles',
]

STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
