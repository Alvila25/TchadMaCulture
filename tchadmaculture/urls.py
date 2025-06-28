from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns
from django.urls import path, include

# Base URLs (outside i18n_patterns for non-translated endpoints)
urlpatterns = [
    # Language switch endpoint for set_language view
    path('i18n/', include('django.conf.urls.i18n')),
]

# Translated URLs with language prefixes (e.g., /en/, /fr/)
urlpatterns += i18n_patterns(
    path('', include('yourapp.urls')),  # Replace 'yourapp' with your actual app name
    # Add other app URLs here if needed
    prefix_default_language=False,  # Avoids redirecting / to /en/
)

# Serve static files in debug mode
if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)  # If using media files
