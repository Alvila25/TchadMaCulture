import os


INSTALLED_APPS = [
    'culture.apps.CultureConfig',
    'django.contrib.staticfiles',
]

STATIC_URL = '/static/'
STATICFILES_DIRS = [BASE_DIR / "static"]
# Use this for production:
STATIC_ROOT = os.path.join(BASE_DIR, 'staticfiles')
