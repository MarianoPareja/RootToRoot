from django import template

register = template.Library()


@register.filter(name="addclass")
def addclass(value, args):
    class_name = f"{args}__{value.label}".replace(" ", "")
    return value.as_widget(attrs={"class": class_name})
