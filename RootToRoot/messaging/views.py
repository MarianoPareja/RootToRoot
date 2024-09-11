from django.contrib.auth.views import login_required
from django.http import HttpResponse
from django.shortcuts import render, redirect

from .models import Room, Topic, Message
from .forms import RoomForm

# Create your views here.

def room(request, pk):
    room = Room.objects.get(id=pk)
    room_messages = room.message_set.all().order_by("-created")
    participant = room.participants.all()

    if request.method == "POST":
        Message.objects.create(
            user=request.user, room=room, body=request.POST.get("body")
        )
        room.participants.add(request.user)
        return redirect("messaging:room", pk=room.id)

    context = {"room": room, "room_messages": room_messages, "participant": participant}
    return render(request, "messaging/room.html", context)


@login_required(login_url="login")
def create_room(request):
    form = RoomForm()
    topics = Topic.objects.all()

    if request.method == "POST":
        topic_name = request.POST.get("topic")
        topic, created = Topic.objects.get_or_create(name=topic_name)

        Room.objects.create(
            host=request.user,
            topic=topic,
            name=request.POST.get("name"),
            description=request.POST.get("description"),
        )

        return redirect("core:home")

    context = {"form": form, "topics": topics}
    return render(request, "messaging/room_form.html", context)


@login_required(login_url="login")
def updateRoom(request, pk):
    room = Room.objects.get(id=pk)
    form = RoomForm(instance=room)
    topics = Topic.objects.all()

    if request.user != room.host:
        return HttpResponse(b"You are not allowed here")

    if request.method == "POST":
        topic_name = request.POST.get("topic")
        topic, _  = Topic.objects.get_or_create(name=topic_name)
        room.name = request.POST.get("name")
        room.topic = topic
        room.description = request.POST.get("description")
        room.save()
        return redirect("core:home")

    context = {"form": form, "topics": topics, "room": room}
    return render(request, "messaging/room_form.html", context)


@login_required(login_url="login")
def deleteRoom(request, pk):
    room = Room.objects.get(id=pk)

    if request.user != room.host:
        return HttpResponse(b"You are not allowed here")

    if request.method == "POST":
        room.delete()
        return redirect("core:home")
    return render(request, "messaging/delete.html", {"obj": room})


@login_required(login_url="login")
def deleteMessage(request, pk):
    message = Message.objects.get(id=pk)

    if request.user != message.user:
        return HttpResponse(b"You are not allowed here")

    if request.method == "POST":
        message.delete()
        return redirect("core:home")
    return render(request, "messaging/delete.html", {"obj": message})

def topicsPage(request):
    q = request.GET.get("q") if request.GET.get("q") != None else ""

    topics = Topic.objects.filter(name__icontains=q)
    context = {"topics": topics}
    return render(request, "messaging/topics.html", context)


def activityPage(request):
    room_messages = Message.objects.all()

    context = {"room_messages": room_messages}
    return render(request, "messaging/activity.html", context)

@login_required(login_url="accounts:login")
def privateChats(request):
   # Retrieve top 10 recent chats for user (use pagination)

    # Retrieve messages for the
    return render(request, "messaging/thread.html")
