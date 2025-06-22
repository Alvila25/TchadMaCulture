from django.urls import path, include
from django.conf.urls.i18n import i18n_patterns
from culture.views import home

urlpatterns = i18n_patterns(
    path('', home, name='home'),
    path('i18n/', include('django.conf.urls.i18n')),
)