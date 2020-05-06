extends WindowDialog
class_name CreditsPanel

const LEVI_URL := "https://levi.dev"
const GODOT_URL := "https://godotengine.org"

func _on_third_party_licenses_button_pressed():
    $ThirdPartyLicensesPanel.popup()

func _on_levi_link_pressed():
    OS.shell_open(LEVI_URL)

func _on_godot_link_pressed():
    OS.shell_open(GODOT_URL)
