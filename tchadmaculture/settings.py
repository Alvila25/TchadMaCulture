from django.utils.translation import gettext_lazy as _

LANGUAGES = [
    ('en', _('English')),
    ('fr', _('French')),
    ('ar', _('Arabic')),
    ('es', _('Spanish')),
]
LANGUAGE_CODE = 'en'  # Default language
USE_I18N = True
USE_L10N = True
LOCALE_PATHS = [BASE_DIR / 'locale']
MIDDLEWARE = [
    # ...
    'django.middleware.locale.LocaleMiddleware',
    # ...
]