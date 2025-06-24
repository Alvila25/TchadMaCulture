from django.conf import settings

def current_language(request):
    lang_code = request.LANGUAGE_CODE
    lang_display = dict(settings.LANGUAGES).get(lang_code, lang_code)
    return {'lang': (lang_code, lang_display)}
