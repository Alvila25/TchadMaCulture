# yourapp/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('', views.home, name='home'),  # Home page view
    # Add other paths for sections like about, contact, etc., if needed
]
