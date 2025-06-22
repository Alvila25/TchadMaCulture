from googletrans import Translator
import polib
import os

translator = Translator()
languages = ['fr', 'es', 'ar']

for lang in languages:
    po_path = os.path.join('locale', lang, 'LC_MESSAGES', 'django.po')
    if os.path.exists(po_path):
        po_file = polib.pofile(po_path)
        for entry in po_file:
            if entry.msgid and not entry.msgstr:
                translation = translator.translate(entry.msgid, src='en', dest=lang).text
                entry.msgstr = translation
                print(f"[{lang}] Translated '{entry.msgid}' to '{translation}'")
        po_file.save()
    else:
        print(f"No .po file found for {lang}")