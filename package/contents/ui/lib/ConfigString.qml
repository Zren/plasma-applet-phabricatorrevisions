// Version 1

import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

RowLayout {
	id: configString
	Layout.fillWidth: true

	property string configKey: ''

	property alias enabled: textField.enabled

	readonly property var configValue: configKey ? plasmoid.configuration[configKey] : ""
	onConfigValueChanged: deserialize()

	property alias textField: textField
	property alias textFieldText: textField.text
	property alias textFieldFocus: textField.focus
	property alias placeholderText: textField.placeholderText

	function parseValue(value) {
		return value
	}
	function parseText(text) {
		return text
	}

	function setValue(val) {
		var newText = parseValue(val)
		if (textField.text != newText) {
			textField.text = newText
		}
	}

	function deserialize() {
		// console.log('deserialize', configValue)
		if (!textField.focus) {
			setValue(configValue)
		}
	}
	function serialize() {
		var newValue = parseText(textField.text)
		// console.log('serialize', configKey, newValue)
		if (plasmoid.configuration[configKey] != newValue) {
			plasmoid.configuration[configKey] = newValue
		}
	}

	property alias before: labelBefore.text
	property alias after: labelAfter.text

	Label {
		id: labelBefore
		text: ""
		visible: text
	}
	
	TextField {
		id: textField
		Layout.fillWidth: true

		onTextChanged: serializeTimer.restart()
	}

	Label {
		id: labelAfter
		text: ""
		visible: text
	}

	Timer { // throttle
		id: serializeTimer
		interval: 300
		onTriggered: serialize()
	}
}
