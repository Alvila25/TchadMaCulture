from django.shortcuts import render, redirect
from .models import Event, Artisan, BlogPost, Subscriber

def home(request):
    events = Event.objects.all()
    artisans = Artisan.objects.all()
    blog_posts = BlogPost.objects.all().order_by('-created_at')[:1]  # Latest post
    if request.method == 'POST':
        email = request.POST.get('email')
        if email:
            Subscriber.objects.get_or_create(email=email)
            return redirect('home')
    return render(request, 'home.html', {
        'events': events,
        'artisans': artisans,
        'blog_posts': blog_posts,
    })
