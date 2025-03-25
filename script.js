
console.log("🚀 script.js loaded");

// Language translations (simplified for brevity, expand as needed)
const languages = {
    en: {
        'site-title': 'Chadian Cultural Heritage',
        'menu_about': 'About',
        'menu_history': 'History & Heritage',
        'menu_art': 'Art & Literature',
        'menu_music': 'Music & Performing Arts',
        'menu_gallery': 'Gallery',
        'menu_contact': 'Contact',
        'hero_title': 'Celebrate and Preserve Chadian Culture',
        'hero_text': 'Explore Chad’s rich cultural heritage, engage with local traditions, and contribute to preserving our history.',
        'hero_button': 'Join Us',
        'section_about': 'About Chad & Our Mission',
    },
    fr: {
        'site-title': 'Patrimoine Culturel Tchadien',
        'menu_about': 'À Propos',
        'menu_history': 'Histoire & Patrimoine',
        'menu_art': 'Art & Littérature',
        'menu_music': 'Musique & Arts Scéniques',
        'menu_gallery': 'Galerie',
        'menu_contact': 'Contact',
        'hero_title': 'Célébrez et Préservez la Culture Tchadienne',
        'hero_text': 'Explorez le riche patrimoine culturel du Tchad, engagez-vous avec les traditions locales et contribuez à préserver notre histoire.',
        'hero_button': 'Rejoignez-nous',
        'section_about': 'À Propos du Tchad & Notre Mission',
    },
    ar: {
        'site-title': 'التراث الثقافي التشادي',
        'menu_about': 'عن',
        'menu_history': 'التاريخ والتراث',
        'menu_art': 'الفن والأدب',
        'menu_music': 'الموسيقى وفنون الأداء',
        'menu_gallery': 'معرض',
        'menu_contact': 'اتصل',
        'hero_title': 'احتفل بالثقافة التشادية وحافظ عليها',
        'hero_text': 'استكشف التراث الثقافي الغني لتشاد، وتفاعل مع التقاليد المحلية وساهم في الحفاظ على تاريخنا.',
        'hero_button': 'انضم إلينا',
        'section_about': 'عن تشاد ومهمتنا',
    }
};

function setLanguage(lang) {
    console.log(`🌍 Switching to language: ${lang}`);
    if (!languages[lang]) {
        console.warn(`⚠️ Language '${lang}' not supported, defaulting to 'en'`);
        lang = 'en';
    }

    const elements = document.querySelectorAll('[data-lang]');
    console.log(`🔍 Found ${elements.length} elements to translate`);
    elements.forEach(element => {
        const key = element.getAttribute('data-lang');
        element.textContent = languages[lang][key] || languages['en'][key] || `[Missing: ${key}]`;
    });

    document.documentElement.dir = lang === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.lang = lang;

    const select = document.getElementById('language-select');
    if (select) {
        select.value = lang;
        // Use localStorage instead of cookies to avoid cross-site issues
        localStorage.setItem('language', lang);
        console.log(`✅ Language set to '${lang}' and saved in localStorage`);
    } else {
        console.error('❌ #language-select not found');
    }
}

document.addEventListener('DOMContentLoaded', () => {
    console.log('✅ DOM fully loaded');
    const select = document.getElementById('language-select');
    if (!select) {
        console.error('❌ Language selector not found');
        return;
    }

    // Single event listener for language change
    select.addEventListener('change', (e) => {
        const newLang = e.target.value;
        console.log(`🔄 Language changed to: ${newLang}`);
        setLanguage(newLang);
    });

    // Load saved language from localStorage
    const savedLang = localStorage.getItem('language') || 'en';
    console.log(`🔄 Initializing with language: ${savedLang}`);
    setLanguage(savedLang);

    // Smooth scrolling with modern syntax
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', (e) => {
            e.preventDefault();
            const target = document.querySelector(anchor.getAttribute('href'));
            target?.scrollIntoView({ behavior: 'smooth' });
        });
    });
});

// Error handling
window.onerror = (msg, src, line, col, error) => {
    console.error(`❌ Error: ${msg} at ${src}:${line}:${col}`);
    console.error(error);
};
