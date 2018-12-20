import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import "lib"
import "lib/Requests.js" as Requests

Item {
	id: widget

	Logger {
		id: logger
		name: 'PhabRevisions'
		showDebug: true
	}

	Plasmoid.icon: plasmoid.file("", "icons/bug.svg")
	Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground
	Plasmoid.hideOnWindowDeactivate: !plasmoid.userConfiguring

	readonly property bool configIsSet: plasmoid.configuration.apiToken && plasmoid.configuration.domain
	readonly property string issueState: plasmoid.configuration.issueState

	property var issuesModel: []

	Octicons { id: octicons }

	Plasmoid.fullRepresentation: FullRepresentation {}

	function phabApiCall(apiMethod, data, callback) {
		var url = 'https://' + plasmoid.configuration.domain + '/api/' + apiMethod
		logger.debug('url', url)

		var args = {}
		args.url = url
		args.method = 'POST'
		args.headers = {}
		args.headers['Content-Type'] = 'application/x-www-form-urlencoded'
		args.data = data || {}
		args.data['api.token'] = plasmoid.configuration.apiToken
		Requests.encodeFormData(args)
		logger.debug('args.data', args.data)

		Requests.getJSON(args, callback)
	}

	function fetchRecentDiffs(callback) {
		var apiMethod = 'differential.revision.search'
		var reqData = {}
		phabApiCall(apiMethod, reqData, function(err, data, xhr){
			logger.debug(err)
			logger.debugJSON(data)
			if (err) {
				return callback(err)
			}

			if (data.error_code) {
				logger.debug('error_code', data.error_code, 'error_info', data.error_info)
				return callback(data.error_info)
			} else {
				return callback(null, data)
			}
		})
	}

	function fetchDiffListRepos(diffList, callback) {
		for (var i = 0; i < diffList.length; i++) {
			var diff = diffList
		}
		var apiMethod = 'diffusion.repository.search'
		var reqData = {}
		phabApiCall(apiMethod, reqData, function(err, data, xhr){
			logger.debug(err)
			logger.debugJSON(data)
			if (err) {
				return callback(err)
			}

			if (data.error_code) {
				logger.debug('error_code', data.error_code, 'error_info', data.error_info)
				return callback(data.error_info)
			} else {
				return callback(null, data)
			}
		})
	}

	function fetchDiffListUsers(diffList, callback) {
		var apiMethod = 'diffusion.repository.search'
		var reqData = {}
		phabApiCall(apiMethod, reqData, function(err, data, xhr){
			logger.debug(err)
			logger.debugJSON(data)
			if (err) {
				return callback(err)
			}

			if (data.error_code) {
				logger.debug('error_code', data.error_code, 'error_info', data.error_info)
				return callback(data.error_info)
			} else {
				return callback(null, data)
			}
		})
	}

	function updateIssuesModel() {
		if (widget.configIsSet) {
			fetchRecentDiffs(function(err, data) {
				var diffList = data.result.data
				// fetchReposForDiffs(diffList, function(err, data) {

				// })
				widget.issuesModel = diffList
			})
		} else {
			widget.issuesModel = []
		}
	}
	Timer {
		id: debouncedUpdateIssuesModel
		interval: 400
		onTriggered: {
			logger.debug('debouncedUpdateIssuesModel.onTriggered')
			widget.updateIssuesModel()
		}
	}
	Timer {
		id: updateModelTimer
		running: true
		repeat: true
		interval: plasmoid.configuration.updateIntervalInMinutes * 60 * 1000
		onTriggered: {
			logger.debug('updateModelTimer.onTriggered')
			debouncedUpdateIssuesModel.restart()
		}
	}

	Connections {
		target: plasmoid.configuration
		onDomainChanged: debouncedUpdateIssuesModel.restart()
		onProductChanged: debouncedUpdateIssuesModel.restart()
		onIssueStateChanged: debouncedUpdateIssuesModel.restart()
	}

	function action_refresh() {
		debouncedUpdateIssuesModel.restart()
	}

	Component.onCompleted: {
		plasmoid.setAction("refresh", i18n("Refresh"), "view-refresh")

		updateIssuesModel()

		// plasmoid.action("configure").trigger() // Uncomment to test config window
	}
}
