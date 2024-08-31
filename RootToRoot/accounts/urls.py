from django.contrib.auth.views import PasswordChangeDoneView, PasswordChangeView
from django.urls import path

from . import views

app_name = "account"

urlpatterns = [
    path("account-settings/", views.account_settings, name="account_settings"),
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
]
