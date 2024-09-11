from django.shortcuts import redirect, render
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib import messages

from messaging.models import Topic

from .models import User
from .forms import MyUserCreationForm, UserForm

# Create your views here.

def loginPage(request):
    page = "login"

    if request.user.is_authenticated:
        return redirect("core:home")

    if request.method == "POST":
        email = request.POST.get("email").lower()
        password = request.POST.get("password")

        try:
            user = User.objects.get(username=email)
        except:
            messages.error(request, "User does not exist")

        user = authenticate(request, username=email, password=password)

        if user is not None:
            login(request, user)
            return redirect("core:home")
        else:
            messages.error(request, "Username or password does not exist")

    context = {"page": page}
    return render(request, "accounts/login_register.html", context)


def logoutUser(request):
    logout(request)
    return redirect("core:home")


def registerUser(request):
    form = MyUserCreationForm()

    if request.method == "POST":
        form = MyUserCreationForm(request.POST)
        if form.is_valid():
            user = form.save(commit=False)
            user.username = user.username.lower()
            user.save()
            login(request, user)
            return redirect("core:home")
        else:
            messages.error(request, form.errors)

    return render(request, "accounts/login_register.html", {"form": form})

def account_settings(request):
    return render(request, "accounts/account_settings.html")


def userProfile(request, pk):
    user = User.objects.get(id=pk)
    rooms = user.room_set.all()
    room_messages = user.message_set.all()
    topics = Topic.objects.all()
    context = {
        "user": user,
        "rooms": rooms,
        "room_messages": room_messages,
        "topics": topics,
    }
    return render(request, "accounts/profile.html", context)


@login_required(login_url="login")
def updateUser(request):
    user = request.user
    form = UserForm(instance=user)

    if request.method == "POST":
        form = UserForm(request.POST, request.FILES, instance=user)
        if form.is_valid():
            form.save()
            return redirect("accounts:user-profile", pk=user.id)

    context = {"form": form}
    return render(request, "accounts/update-user.html", context)
