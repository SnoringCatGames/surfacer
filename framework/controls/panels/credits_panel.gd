extends WindowDialog
class_name CreditsPanel

const LEVI_URL := "https://levi.dev"
const GODOT_URL := "https://godotengine.org"
const MIT_LICENSE_URL := "https://github.com/levilindsey/surfacer/blob/master/LICENSE"
const CC_LICENSE_URL := "https://creativecommons.org/publicdomain/zero/1.0/deed.en"

func _on_third_party_licenses_button_pressed():
    $ThirdPartyLicensesPanel.popup()

func _on_levi_link_pressed():
    OS.shell_open(LEVI_URL)

func _on_godot_link_pressed():
    OS.shell_open(GODOT_URL)

func _on_mit_license_link_pressed():
    OS.shell_open(MIT_LICENSE_URL)

func _on_cc_license_link_pressed():
    OS.shell_open(CC_LICENSE_URL)
