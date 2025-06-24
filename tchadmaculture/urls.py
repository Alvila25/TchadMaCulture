from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns
from django.urls import path, include

urlpatterns = [
    # Language switch POST endpoint (used by Django’s set_language view)
    path('i18n/', include('django.conf.urls.i18n')),
]

urlpatterns += i18n_patterns(
    # Your app URLs here, e.g.:
    path('', include('yourapp.urls')),
    # Add other apps here if needed
)

if settings.DEBUG:
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
