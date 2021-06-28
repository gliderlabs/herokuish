import helloworld.views
from django.conf.urls import *

from django.contrib import admin
admin.autodiscover()

urlpatterns = [
    url(r'^$', helloworld.views.home, name='home'),
    url(r'^admin/', admin.site.urls),
]
