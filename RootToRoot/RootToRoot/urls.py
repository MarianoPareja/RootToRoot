from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("core.urls", namespace="core")),
    # path("api/", include("base.api.urls")),
    path("allatuh/", include("allauth.urls")),
    path("accounts/", include("accounts.urls", namespace="accounts")),
    path("messaging/", include("messaging.urls", namespace="messaging")),
]

urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
