from django.contrib import admin
from .models import Event, Artisan, BlogPost, Subscriber

admin.site.register(Event)
admin.site.register(Artisan)
admin.site.register(BlogPost)
admin.site.register(Subscriber)
