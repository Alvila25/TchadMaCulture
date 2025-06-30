from django.shortcuts import render, redirect
from django.contrib import messages
from django.utils.translation import gettext as _

def contact(request):
    if request.method == 'POST':
        # Process form (e.g., send to Formspree via requests or save to database)
        name = request.POST.get('name')
        email = request.POST.get('email')
        message = request.POST.get('message')
        # Example: Send to Formspree or custom logic
        messages.success(request, _("Your message has been sent successfully!"))
        return redirect('index')
    return render(request, 'index.html')
