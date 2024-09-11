from django.urls import path

from . import views

app_name = "messaging"

urlpatterns = [
    path("room/<str:pk>/", views.room, name="room"),
    path("create-room/", views.create_room, name="create-room"),
    path("update-room/<str:pk>/", views.updateRoom, name="update-room"),
    path("delete-room/<str:pk>/", views.deleteRoom, name="delete-room"),
    path("delete-message/<str:pk>/", views.deleteMessage, name="delete-message"),
    path("topics/", views.topicsPage, name="topics"),
    path("activity/", views.activityPage, name="activity"),
    path("thread/", views.privateChats, name="messaging-thread")
]

