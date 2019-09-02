from prompt_toolkit.application.current import get_app
from prompt_toolkit.filters import Condition


@Condition
def is_buffer_empty():
    return get_app().current_buffer.text.strip() == ""


def register_key_bindings(ip):
    try:
        add = ip.pt_app.key_bindings.add
    except AttributeError:
        return lambda: None

    @add("c-h", filter=is_buffer_empty, eager=True)
    def exit_with_backspace(event):
        ip.ask_exit()
        event.app.exit()

    def unregister():
        ip.pt_app.key_bindings.remove(exit_with_backspace)

    return unregister
