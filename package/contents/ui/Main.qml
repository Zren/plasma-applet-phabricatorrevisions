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
	property var repoMap: ({})
	property var userMap: ({})

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

	function applyPhidsContraint(reqData, phidList) {
		// Workaround our incomplete 'form-urlencoded' serialization in Requests.js
		for (var i = 0; i < phidList.length; i++) {
			var phid = phidList[i]
			var key = 'constraints[phids][' + i + ']'
			reqData[key] = phid
		}
	}

	function fetchRepos(repoPhidList, callback) {
		logger.debug('repoPhidList', repoPhidList)

		var apiMethod = 'diffusion.repository.search'
		var reqData = {}
		applyPhidsContraint(reqData, repoPhidList)

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

	function fetchUsers(userPhidList, callback) {
		logger.debug('userPhidList', userPhidList)

		var apiMethod = 'user.search'
		var reqData = {}
		applyPhidsContraint(reqData, userPhidList)

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
		var repoPhidList = []
		for (var i = 0; i < diffList.length; i++) {
			var diff = diffList[i]
			var repoPhid = diff.fields.repositoryPHID
			if (repoMap[repoPhid]) {
				// skip
			} else {
				repoPhidList.push(repoPhid)
			}
		}

		fetchRepos(repoPhidList, function(err, data){
			if (err) {
				return callback(err)
			}

			var repoList = data.result.data

			for (var i = 0; i < repoList.length; i++) {
				var repo = repoList[i]
				repoMap[repo.phid] = repo
			}

			return callback(null, repoList)
		})
	}

	function fetchDiffListUsers(diffList, callback) {
		var userPhidList = []
		for (var i = 0; i < diffList.length; i++) {
			var diff = diffList[i]
			var userPhid = diff.fields.authorPHID
			if (userMap[userPhid]) {
				// skip
			} else {
				userPhidList.push(userPhid)
			}
		}

		fetchUsers(userPhidList, function(err, data){
			if (err) {
				return callback(err)
			}

			var userList = data.result.data

			for (var i = 0; i < userList.length; i++) {
				var user = userList[i]
				userMap[user.phid] = user
			}

			return callback(null, userList)
		})
	}

	function updateIssuesModel() {
		if (widget.configIsSet) {
			fetchRecentDiffs(function(err, data) {
				var diffList = data.result.data
				fetchDiffListRepos(diffList, function(err, data) {
					fetchDiffListUsers(diffList, function(err, data) {
						widget.issuesModel = diffList
					})
				})
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
