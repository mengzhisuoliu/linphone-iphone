/*
 * Copyright (c) 2010-2024 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation
import linphonesw
import Combine

class MeetingsListViewModel: ObservableObject {
	
	private var coreContext = CoreContext.shared
	private var mCoreSuscriptions = Set<AnyCancellable?>()
	var selectedMeeting: ConversationModel?
	
	@Published var meetingsList: [MeetingsListItemModel] = []
	
	init() {
		computeMeetingsList(filter: "")
	}
	
	func computeMeetingsList(filter: String) {
		coreContext.doOnCoreQueue { core in
			var confInfoList: [ConferenceInfo] = []
			
			if let account = core.defaultAccount {
				confInfoList = account.conferenceInformationList
			}
			if confInfoList.isEmpty {
				confInfoList = core.conferenceInformationList
			}
			
			var meetingsListTmp: [MeetingsListItemModel] = []
			var previousModel: MeetingModel? = nil
			var meetingForTodayFound = false
			
			for confInfo in confInfoList {
				if (confInfo.duration == 0) { continue }// This isn't a scheduled conference, don't display it
				var add = true
				if !filter.isEmpty {
					let organizerCheck = confInfo.organizer?.asStringUriOnly().range(of: filter, options: .caseInsensitive) != nil
					let subjectCheck = confInfo.subject?.range(of: filter, options: .caseInsensitive) != nil
					let descriptionCheck = confInfo.description?.range(of: filter, options: .caseInsensitive) != nil
					let participantsCheck = confInfo.participantInfos.first(where: {$0.address?.asStringUriOnly().range(of: filter, options: .caseInsensitive) != nil}) != nil
					
					add = organizerCheck || subjectCheck || descriptionCheck || participantsCheck
				}
				
				if add {
					let model = MeetingModel(conferenceInfo: confInfo)
					let firstMeetingOfTheDay = (previousModel != nil) ? previousModel?.day != model.day || previousModel?.dayNumber != model.dayNumber : true
					model.firstMeetingOfTheDay = firstMeetingOfTheDay
					
					// Insert "Today" fake model before the first one of today
					if firstMeetingOfTheDay && model.isToday {
						meetingsListTmp.append(MeetingsListItemModel(meetingModel: nil))
						meetingForTodayFound = true
					}
					
					// If no meeting was found for today, insert "Today" fake model before the next meeting to come
					if !meetingForTodayFound && model.isAfterToday {
						meetingsListTmp.append(MeetingsListItemModel(meetingModel: nil))
						meetingForTodayFound = true
					}
					
					meetingsListTmp.append(MeetingsListItemModel(meetingModel: model))
					previousModel = model
				}
			}
			
			// If no meeting was found after today, insert "Today" fake model at the end
			if !meetingForTodayFound {
				meetingsListTmp.append(MeetingsListItemModel(meetingModel: nil))
			}
			
			self.meetingsList = meetingsListTmp
		}
	}

	
}
