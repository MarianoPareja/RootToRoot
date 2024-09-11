from django.contrib.auth.views import (
        PasswordChangeDoneView,
        PasswordChangeView,
        PasswordResetConfirmView,
        PasswordResetView,
        PasswordResetDoneView,
        PasswordResetConfirmView,
        PasswordResetCompleteView,
)
from django.urls import path

from . import views

app_name = "accounts"

urlpatterns = [
    path("login/", views.loginPage, name="login"),
    path("logout/", views.logoutUser, name="logout"),
    path("register/", views.registerUser, name="register"),
    path("profile/<str:pk>", views.userProfile, name="user-profile"),
    path("account-settings/", views.account_settings, name="account_settings"),
    path("update-user/", views.updateUser, name="update-user"),
    path(
        "password-change/",
        PasswordChangeView.as_view(),
        name="password_change",
    ),
    path(
        "password-change-done/",
        PasswordChangeDoneView.as_view(),
        name="password_change_done",
    ),
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
