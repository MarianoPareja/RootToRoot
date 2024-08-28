from django.shortcuts import redirect, render

# Create your views here.


def account_settings(request):
    return render(request, "accounts/account_settings.html")
