from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.conf.urls.i18n import i18n_patterns

urlpatterns = [
    path('i18n/', include('django.conf.urls.i18n')),  # language switching views
]

urlpatterns += i18n_patterns(
    path('admin/', admin.site.urls),
    path('', include('culture.urls')),
)

urlpatterns += static(settings.STATIC_URL, document_root=settings.STATICFILES_DIRS[0])
