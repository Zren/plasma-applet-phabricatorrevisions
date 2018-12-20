import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

import "lib"
import "lib/TimeUtils.js" as TimeUtils

IssueListView {
	id: issueListView

	isSetup: widget.configIsSet
	showHeading: plasmoid.configuration.showHeading
	headingText: ''

	delegate: IssueListItem {
		readonly property var author: widget.userMap[issue.fields.authorPHID]
		readonly property var repo: widget.repoMap[issue.fields.repositoryPHID]

		property bool issueClosed: issue.fields.status.closed
		issueOpen: !issueClosed
		issueId: issue.id
		issueIdStr: 'D' + issueId
		issueSummary: issue.fields.title
		tagBefore: ""
		category: repo ? '' + repo.fields.shortName : ''
		issueCreatorName: author ? author.fields.username : "Submitter"
		issueHtmlLink: 'https://' + plasmoid.configuration.domain + '/D' + issue.id

		showNumComments: false
		numComments: 0

		dateTime: {
			if (issueOpen) {
				return issue.fields.dateCreated * 1000
			} else { // Closed
				// Phab doesn't have a dedicated dataClosed property.
				// This should suffice I guess, but we probably need
				// to parse every diff's "events" to get the proper
				// closed timestamp.
				return issue.fields.dateModified * 1000
			}
		}

		issueState: {
			var statusValue = issue.fields.status.value
			if (issueOpen) {
				return 'openPullRequest'
			} else { // Closed
				if (statusValue == "published") {
					return 'merged'
				} else { // Eg: 'abandoned'
					return 'closedPullRequest'
				}
			}
		}
	}
}
