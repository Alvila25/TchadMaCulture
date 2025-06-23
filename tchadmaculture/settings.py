import os

BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DEBUG = True  # Set to False for production after testing
ALLOWED_HOSTS = ['localhost', '127.0.0.1']
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, 'templates')],
        'APP_DIRS': True,
        ...
    },
]
LANGUAGES = [
    ('en', 'English'),
    ('fr', 'French'),
    ('ar', 'Arabic'),
    ('es', 'Spanish'),
]
LOCALE_PATHS = [os.path.join(BASE_DIR, 'locale')]
USE_I18N = True
STATIC_URL = '/static/'
STATICFILES_DIRS = [os.path.join(BASE_DIR, 'static')]
STATIC_ROOT = os.path.join(BASE_DIR, 'staticbuild')