@icon("res://icons/ScaffolderNode.svg")
class_name ScaffolderLogsDisplay
extends PanelContainer


@export var label_settings: LabelSettings


func _ready() -> void:
    S.settings.property_changed.connect(_on_property_changed)
    var show_logs: bool = S.settings.get("show_logs")
    _on_property_changed("show_logs", show_logs, show_logs)


func _on_property_changed(name: String, new_value: Variant, old_value: Variant) -> void:
    match name:
        "show_logs":
            visible = new_value
        _:
            # Do nothing.
            return


func add_log(text: String, max_log_count: int) -> void:
    var label := Label.new()
    label.label_settings = label_settings
    label.text = text
    %Logs.add_child(label)

    _trim_logs(max_log_count)

    # Auto-scroll to the end.
    %ScrollContainer.scroll_vertical = %ScrollContainer.get_v_scroll_bar().max_value


func _trim_logs(max_count: int) -> void:
    var log_labels := %Logs.get_children()
    while log_labels.size() > max_count:
        var label: Label = log_labels.pop_front()
        label.queue_free()
