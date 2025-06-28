# settings.py
import os
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent

# i18n settings
LANGUAGE_CODE = 'en'  # Default language
LANGUAGES = [
    ('en', 'English'),
    ('fr', 'French'),
    ('ar', 'Arabic'),
    ('es', 'Spanish'),
]
USE_I18N = True
USE_L10N = True
USE_TZ = True
LOCALE_PATHS = [
    BASE_DIR / 'locale',
]

# Middleware
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',  # Required for language persistence
    'django.middleware.locale.LocaleMiddleware',  # Handles language detection
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
]

# Installed apps
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'yourapp',  # Replace with your actual app name
]

# Static and media files
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']  # If you have a static folder for CSS/images
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Session settings
SESSION_ENGINE = 'django.contrib.sessions.backends.db'  # Ensure sessions are stored
SESSION_COOKIE_SECURE = False  # Set to True for HTTPS in production
CSRF_COOKIE_SECURE = False  # Set to True for HTTPS in production

# Debug (set to False in production)
DEBUG = True
