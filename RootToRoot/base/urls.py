from django.contrib.auth.views import (
    PasswordResetCompleteView,
    PasswordResetConfirmView,
    PasswordResetDoneView,
    PasswordResetView,
)
from django.urls import path

from . import views

app_name = "base"

urlpatterns = [
    path("login/", views.loginPage, name="login"),
    path("logout/", views.logoutUser, name="logout"),
    path("register/", views.registerUser, name="register"),
    path("", views.home, name="home"),
    path("room/<str:pk>/", views.room, name="room"),
    path("profile/<str:pk>", views.userProfile, name="user-profile"),
    path("create-room/", views.create_room, name="create-room"),
    path("update-room/<str:pk>/", views.updateRoom, name="update-room"),
    path("delete-room/<str:pk>/", views.deleteRoom, name="delete-room"),
    path("delete-message/<str:pk>/", views.deleteMessage, name="delete-message"),
    path("update-user/", views.updateUser, name="update-user"),
    path("topics/", views.topicsPage, name="topics"),
    path("activity/", views.activityPage, name="activity"),
    # Password Configurations
    # path("password-reset/", views.passwordReset, name="password-reset"),
    # path("password-reset/done", views.passwordResetDone, name="password-reset-done"),
    # path(
    #     "password-reset/<uidb64>/<token>/",
    #     views.passwordResetConfirm,
    #     name="password-reset-confirm",
    # ),
    # path(
    #     "password-reset/complete/",
    #     views.passwordResetComplete,
    #     name="password-reset-confirm",
    # ),
    # Auth paths
    path("password-reset/", PasswordResetView.as_view(), name="password_reset"),
    path(
        "password-reset/done",
        PasswordResetDoneView.as_view(),
        name="password_reset_done",
    ),
    path(
        "password-reset/<uidb64>/<token>/",
        PasswordResetConfirmView.as_view(),
        name="password_reset_confirm",
    ),
    path(
        "password-reset/complete/",
        PasswordResetCompleteView.as_view(),
        name="password_reset_complete",
    ),
]
