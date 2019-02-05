import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0
import org.kde.kirigami 2.5 as Kirigami

import "../lib"

ColumnLayout {
	property alias cfg_apiToken: apiTokenTextField.text
	property alias cfg_domain: domainTextField.text
	property alias cfg_updateIntervalInMinutes: updateIntervalInMinutesSpinBox.value

	readonly property string baseDomainUrl: "https://" + (cfg_domain || "phabricator.kde.org")

	ColumnLayout {
		Layout.alignment: Qt.AlignTop

		Kirigami.FormLayout {
			Layout.fillWidth: true
			wideMode: true

			LinkText {
				readonly property string settingsUrl: baseDomainUrl + "/settings/"
				text: i18n("Visit your <a href=\"%1\">Phabricator Settings</a>. Under the Conduit API Tokens section, generate a new token and paste it here.", settingsUrl)
				wrapMode: Text.Wrap
				Layout.fillWidth: true
			}

			TextField {
				id: apiTokenTextField
				Kirigami.FormData.label: i18n("API Token:")
				Layout.fillWidth: true
			}

			TextField {
				id: domainTextField
				Kirigami.FormData.label: i18n("Domain:")
				Layout.fillWidth: true
			}

			ConfigString {
				id: queryKeyTextField1
				Kirigami.FormData.label: i18n("Query Key:")
				configKey: "queryKey"
				before: baseDomainUrl + "/query/"
				placeholderText: "zm2vHZxBkky_" // plasma-workspace
				after: "/"
			}

			ConfigRadioButtonGroup {
				id: queryKeyButtonGroup
				configKey: "queryKey"
				model: [
					{ value: "active", text: i18n("Active") },
					{ value: "authored", text: i18n("Authored") },
					{ value: "all", text: i18n("All") },
				]
			}
			RowLayout {
				RadioButton {
					property string configKey: "queryKey"
					readonly property string configValue: plasmoid.configuration[configKey]
					text: i18n("Custom")
					checked: configValue != "active" && configValue != "authored" && configValue != "all"
					exclusiveGroup: queryKeyButtonGroup.exclusiveGroup
					onClicked: {
						plasmoid.configuration[configKey] = ""
					}
				}

				ConfigString {
					configKey: "queryKey"
					placeholderText: queryKeyTextField1.placeholderText
				}
			}

			SpinBox {
				id: updateIntervalInMinutesSpinBox
				Kirigami.FormData.label: i18n("Update Every:")
				stepSize: 5
				minimumValue: 5
				maximumValue: 24 * 60
				suffix: i18nc("Polling interval in minutes", "min")
			}

			// ConfigCheckBox {
			// 	configKey: "showHeading"
			// 	text: i18n("Show Heading")
			// }

			ConfigCheckBox {
				configKey: "showBackground"
				text: i18n("Desktop Widget: Show background")
			}
		}
	}
}
