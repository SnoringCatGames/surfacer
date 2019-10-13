extends Panel
class_name DebugPanel

func add_section(section: Control) -> void:
    $VBoxContainer/Sections.add_child(section)
