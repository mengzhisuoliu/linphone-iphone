/*
 * Copyright (c) 2010-2020 Belledonne Communications SARL.
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

import SwiftUI
import CallKit
import AVFAudio
import linphonesw
import UniformTypeIdentifiers

// swiftlint:disable function_body_length
// swiftlint:disable type_body_length
// swiftlint:disable line_length
// swiftlint:disable file_length
struct CallView: View {
	
	@ObservedObject private var coreContext = CoreContext.shared
	@ObservedObject private var telecomManager = TelecomManager.shared
	@ObservedObject private var contactsManager = ContactsManager.shared
	
	@ObservedObject var callViewModel: CallViewModel
	@ObservedObject var conversationViewModel: ConversationViewModel
	@ObservedObject var conversationsListViewModel: ConversationsListViewModel
	@ObservedObject var conversationForwardMessageViewModel: ConversationForwardMessageViewModel
	@ObservedObject var contactViewModel: ContactViewModel
	@ObservedObject var editContactViewModel: EditContactViewModel
	@ObservedObject var meetingViewModel: MeetingViewModel
	@ObservedObject var accountProfileViewModel: AccountProfileViewModel
	
	@State private var addParticipantsViewModel: AddParticipantsViewModel?
	
	private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
	@State private var orientation = UIDevice.current.orientation
	
	let pub = NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)
	
	@State var audioRouteSheet: Bool = false
	@State var changeLayoutSheet: Bool = false
	@State var mediaEncryptedSheet: Bool = false
	@State var callStatisticsSheet: Bool = false
	@State var optionsAudioRoute: Int = 1
	@State var optionsChangeLayout: Int = 2
	@State var imageAudioRoute: String = ""
	@State var angleDegree = 0.0
	@State var showingDialer = false
	@State var minBottomSheetHeight: CGFloat = 0.16
	@State var maxBottomSheetHeight: CGFloat = 0.5
	@State private var pointingUp: CGFloat = 0.0
	@State private var currentOffset: CGFloat = 0.0
	@State var displayVideo = false
	@State private var previewVideoOffset = CGSize.zero
	@State private var previewVideoOffsetPreviousDrag = CGSize.zero
	
	@Binding var fullscreenVideo: Bool
	@State var isShowCallsListFragment: Bool = false
	@State var isShowParticipantsListFragment: Bool = false
	@Binding var isShowStartCallFragment: Bool
	@Binding var isShowConversationFragment: Bool
	@Binding var isShowStartCallGroupPopup: Bool
	
	@State var buttonSize = 60.0
	
	@Binding var isShowEditContactFragment: Bool
	@Binding var indexPage: Int
	
	@Binding var isShowScheduleMeetingFragment: Bool
	
	var body: some View {
		GeometryReader { geo in
			ZStack {
				if #available(iOS 16.4, *), idiom != .pad {
					innerView(geometry: geo)
						.sheet(isPresented: $mediaEncryptedSheet, onDismiss: {
							mediaEncryptedSheet = false
						}, content: {
							MediaEncryptedSheetBottomSheet(callViewModel: callViewModel, mediaEncryptedSheet: $mediaEncryptedSheet)
								.presentationDetents([.medium])
						})
						.sheet(isPresented: $callStatisticsSheet, onDismiss: {
							callStatisticsSheet = false
						}, content: {
							CallStatisticsSheetBottomSheet(callViewModel: callViewModel, callStatisticsSheet: $callStatisticsSheet)
								.presentationDetents(!callViewModel.callStatsModel.isVideoEnabled ? [.fraction(0.3)] : [.medium])
						})
						.sheet(isPresented: $audioRouteSheet, onDismiss: {
							audioRouteSheet = false
						}, content: {
							AudioRouteBottomSheet(callViewModel: callViewModel, optionsAudioRoute: $optionsAudioRoute)
								.presentationDetents([.fraction(0.3)])
						})
						.sheet(isPresented: $changeLayoutSheet, onDismiss: {
							changeLayoutSheet = false
						}, content: {
							ChangeLayoutBottomSheet(callViewModel: callViewModel, changeLayoutSheet: $changeLayoutSheet, optionsChangeLayout: $optionsChangeLayout)
								.presentationDetents([.fraction(0.3)])
						})
						.sheet(isPresented: $showingDialer) {
							DialerBottomSheet(
								startCallViewModel: StartCallViewModel(),
								callViewModel: callViewModel,
								isShowStartCallFragment: $isShowStartCallFragment,
								showingDialer: $showingDialer,
								currentCall: callViewModel.currentCall
							)
							.presentationDetents([.medium])
							.presentationBackgroundInteraction(.enabled(upThrough: .medium))
						}
				} else if #available(iOS 16.0, *), idiom != .pad {
					innerView(geometry: geo)
						.sheet(isPresented: $mediaEncryptedSheet, onDismiss: {
							mediaEncryptedSheet = false
						}, content: {
							MediaEncryptedSheetBottomSheet(callViewModel: callViewModel, mediaEncryptedSheet: $mediaEncryptedSheet)
								.presentationDetents([.medium])
						})
						.sheet(isPresented: $callStatisticsSheet, onDismiss: {
							callStatisticsSheet = false
						}, content: {
							CallStatisticsSheetBottomSheet(callViewModel: callViewModel, callStatisticsSheet: $callStatisticsSheet)
								.presentationDetents(!callViewModel.callStatsModel.isVideoEnabled ? [.fraction(0.3)] : [.medium])
						})
						.sheet(isPresented: $audioRouteSheet, onDismiss: {
							audioRouteSheet = false
						}, content: {
							AudioRouteBottomSheet(callViewModel: callViewModel, optionsAudioRoute: $optionsAudioRoute)
								.presentationDetents([.fraction(0.3)])
						})
						.sheet(isPresented: $changeLayoutSheet, onDismiss: {
							changeLayoutSheet = false
						}, content: {
							ChangeLayoutBottomSheet(callViewModel: callViewModel, changeLayoutSheet: $changeLayoutSheet, optionsChangeLayout: $optionsChangeLayout)
								.presentationDetents([.fraction(0.3)])
						})
						.sheet(isPresented: $showingDialer) {
							DialerBottomSheet(
								startCallViewModel: StartCallViewModel(),
								callViewModel: callViewModel,
								isShowStartCallFragment: $isShowStartCallFragment,
								showingDialer: $showingDialer,
								currentCall: callViewModel.currentCall
							)
							.presentationDetents([.medium])
						}
				} else {
					innerView(geometry: geo)
						.halfSheet(showSheet: $mediaEncryptedSheet) {
							MediaEncryptedSheetBottomSheet(callViewModel: callViewModel, mediaEncryptedSheet: $mediaEncryptedSheet)
						} onDismiss: {
							mediaEncryptedSheet = false
						}
						.halfSheet(showSheet: $callStatisticsSheet) {
							CallStatisticsSheetBottomSheet(callViewModel: callViewModel, callStatisticsSheet: $callStatisticsSheet)
						} onDismiss: {
							callStatisticsSheet = false
						}
						.halfSheet(showSheet: $audioRouteSheet) {
							AudioRouteBottomSheet(callViewModel: callViewModel, optionsAudioRoute: $optionsAudioRoute)
						} onDismiss: {
							audioRouteSheet = false
						}
						.halfSheet(showSheet: $changeLayoutSheet) {
							ChangeLayoutBottomSheet(callViewModel: callViewModel, changeLayoutSheet: $changeLayoutSheet, optionsChangeLayout: $optionsChangeLayout)
						} onDismiss: {
							changeLayoutSheet = false
						}
						.halfSheet(showSheet: $showingDialer) {
							DialerBottomSheet(
								startCallViewModel: StartCallViewModel(),
								callViewModel: callViewModel,
								isShowStartCallFragment: $isShowStartCallFragment,
								showingDialer: $showingDialer,
								currentCall: callViewModel.currentCall
							)
						} onDismiss: {}
				}
				
				if isShowCallsListFragment {
					CallsListFragment(callViewModel: callViewModel, isShowCallsListFragment: $isShowCallsListFragment)
						.zIndex(4)
						.transition(.move(edge: .bottom))
				}
				
				if isShowParticipantsListFragment {
					ParticipantsListFragment(callViewModel: callViewModel, addParticipantsViewModel: addParticipantsViewModel ?? AddParticipantsViewModel(), isShowParticipantsListFragment: $isShowParticipantsListFragment)
						.zIndex(4)
						.transition(.move(edge: .bottom))
						.onAppear {
							addParticipantsViewModel = AddParticipantsViewModel()
						}
				}
				
				if isShowConversationFragment && conversationViewModel.displayedConversation != nil {
					ConversationFragment(
						conversationViewModel: conversationViewModel,
						conversationsListViewModel: conversationsListViewModel,
						conversationForwardMessageViewModel: conversationForwardMessageViewModel,
						contactViewModel: contactViewModel,
						editContactViewModel: editContactViewModel,
						meetingViewModel: meetingViewModel,
						accountProfileViewModel: accountProfileViewModel,
						isShowConversationFragment: $isShowConversationFragment,
						isShowStartCallGroupPopup: $isShowStartCallGroupPopup,
						isShowEditContactFragment: $isShowEditContactFragment,
						indexPage: $indexPage,
						isShowScheduleMeetingFragment: $isShowScheduleMeetingFragment
					)
					.frame(maxWidth: .infinity)
					.background(Color.gray100)
					.ignoresSafeArea(.keyboard)
					.zIndex(4)
					.transition(.move(edge: .bottom))
					.onDisappear {
						conversationViewModel.displayedConversation = nil
						isShowConversationFragment = false
					}
				}
				
				if callViewModel.zrtpPopupDisplayed == true {
					if idiom != .pad 
						&& (orientation == .landscapeLeft
							|| orientation == .landscapeRight
							|| UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height)
						&& buttonSize != 45 {
						ZRTPPopup(callViewModel: callViewModel, resizeView: 1.5)
							.background(.black.opacity(0.65))
							.frame(maxHeight: geo.size.height)
					} else {
						ZRTPPopup(callViewModel: callViewModel, resizeView: buttonSize == 45 ? 1.5 : 1)
							.background(.black.opacity(0.65))
							.frame(maxHeight: geo.size.height)
					}
				}
				
				if telecomManager.remainingCall {
					HStack {}
					.onAppear {
						callViewModel.resetCallView()
						callViewModel.getCallsList()
					}
				}
			}
			.onAppear {
				UIApplication.shared.endEditing()
				fullscreenVideo = false
				if geo.size.width < 350 || geo.size.height < 350 {
					buttonSize = 45.0
				}
			}
		}
	}
	
	@ViewBuilder
	func innerView(geometry: GeometryProxy) -> some View {
		ZStack {
			VStack {
				if !fullscreenVideo || (fullscreenVideo && telecomManager.isPausedByRemote) {
					ZStack {
						HStack {
							Button {
								withAnimation {
									telecomManager.callDisplayed = false
								}
							} label: {
								Image("caret-left")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 25, height: 25, alignment: .leading)
									.padding(.all, 10)
							}
							
							Text(callViewModel.displayName)
								.default_text_style_white_800(styleSize: 16)
							
							if !telecomManager.outgoingCallStarted && telecomManager.callInProgress {
								Text("|")
									.default_text_style_white_800(styleSize: 16)
								
								ZStack {
									Text(callViewModel.timeElapsed.convertDurationToString())
										.onReceive(callViewModel.timer) { _ in
											callViewModel.timeElapsed = callViewModel.currentCall?.duration ?? 0
										}
										.default_text_style_white_800(styleSize: 16)
										.if(callViewModel.isPaused || telecomManager.isPausedByRemote) { view in
											view.hidden()
										}
									
									if callViewModel.isPaused {
										Text("call_state_paused")
											.default_text_style_white_800(styleSize: 16)
									} else if telecomManager.isPausedByRemote {
										Text("call_state_paused_by_remote")
											.default_text_style_white_800(styleSize: 16)
									}
								}
							}
							
							Spacer()
							
							Button {
								callStatisticsSheet = true
							} label: {
								Image(callViewModel.qualityIcon)
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 30, height: 30)
									.padding(.all, 10)
							}
							
							if callViewModel.videoDisplayed {
								Button {
									callViewModel.switchCamera()
								} label: {
									Image("camera-rotate")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(.white)
										.frame(width: 30, height: 30)
										.padding(.horizontal)
								}
							}
						}
						.frame(height: 40)
						.zIndex(1)
						
						if !telecomManager.outgoingCallStarted && telecomManager.callInProgress {
							if callViewModel.isMediaEncrypted && callViewModel.isRemoteDeviceTrusted && callViewModel.isZrtp {
								HStack {
									Image("lock-key")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(Color.blueInfo500)
										.frame(width: 15, height: 15, alignment: .leading)
										.padding(.leading, 50)
										.padding(.top, 35)
									
									Text("call_zrtp_end_to_end_encrypted")
										.foregroundStyle(Color.blueInfo500)
										.default_text_style_white(styleSize: 12)
										.padding(.top, 35)
									
									Spacer()
								}
								.onTapGesture {
									mediaEncryptedSheet = true
								}
								.frame(height: 40)
								.zIndex(1)
							} else if callViewModel.isMediaEncrypted && !callViewModel.isZrtp {
								HStack {
									Image("lock_simple")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(Color.blueInfo500)
										.frame(width: 15, height: 15, alignment: .leading)
										.padding(.leading, 50)
										.padding(.top, 35)
									
									Text("call_srtp_point_to_point_encrypted")
										.foregroundStyle(Color.blueInfo500)
										.default_text_style_white(styleSize: 12)
										.padding(.top, 35)
									
									Spacer()
								}
								.onTapGesture {
									mediaEncryptedSheet = true
								}
								.frame(height: 40)
								.zIndex(1)
							} else if callViewModel.isMediaEncrypted && (!callViewModel.isRemoteDeviceTrusted && callViewModel.isZrtp) || callViewModel.cacheMismatch {
								HStack {
									Image("warning-circle")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(Color.orangeWarning600)
										.frame(width: 15, height: 15, alignment: .leading)
										.padding(.leading, 50)
										.padding(.top, 35)
									
									Text("call_zrtp_sas_validation_required")
										.foregroundStyle(Color.orangeWarning600)
										.default_text_style_white(styleSize: 12)
										.padding(.top, 35)
									
									Spacer()
								}
								.onTapGesture {
									mediaEncryptedSheet = true
								}
								.frame(height: 40)
								.zIndex(1)
							} else if callViewModel.isNotEncrypted {
								HStack {
									Image("lock_simple")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(.white)
										.frame(width: 15, height: 15, alignment: .leading)
										.padding(.leading, 50)
										.padding(.top, 35)
									
									Text("call_not_encrypted")
										.foregroundStyle(.white)
										.default_text_style_white(styleSize: 12)
										.padding(.top, 35)
									
									Spacer()
								}
								.onTapGesture {
									mediaEncryptedSheet = true
								}
								.frame(height: 40)
								.zIndex(1)
							} else {
								HStack {
									ProgressView()
										.controlSize(.mini)
										.progressViewStyle(CircularProgressViewStyle(tint: .white))
										.frame(width: 15, height: 15, alignment: .leading)
										.padding(.leading, 50)
										.padding(.top, 35)
									
									Text("call_waiting_for_encryption_info")
										.foregroundStyle(.white)
										.default_text_style_white(styleSize: 12)
										.padding(.top, 35)
									
									Spacer()
								}
								.frame(height: 40)
								.zIndex(1)
							}
						}
					}
				}
				
				simpleCallView(geometry: geometry)
				
				Spacer()
			}
			.frame(height: geometry.size.height)
			.frame(maxWidth: .infinity)
			.background(Color.gray900)
						
			if !fullscreenVideo || (fullscreenVideo && telecomManager.isPausedByRemote) {
				if telecomManager.callStarted {
					let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene
					let bottomInset = scene?.windows.first?.safeAreaInsets
					
					BottomSheetView(
						content: bottomSheetContent(geo: geometry),
						minHeight: (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78),
						maxHeight: (maxBottomSheetHeight * geometry.size.height),
						currentOffset: $currentOffset,
						pointingUp: $pointingUp,
						bottomSafeArea: bottomInset?.bottom ?? 0
					)
					.onAppear {
						currentOffset = (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78)
						pointingUp = -(((currentOffset - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78)) / ((maxBottomSheetHeight * geometry.size.height) - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78))) - 0.5) * 2
					}
					.onChange(of: optionsChangeLayout) { _ in
						currentOffset = (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78)
						pointingUp = -(((currentOffset - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78)) / ((maxBottomSheetHeight * geometry.size.height) - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78))) - 0.5) * 2
					}
					.edgesIgnoringSafeArea(.bottom)
				}
			}
		}
	}
	
	// swiftlint:disable:next cyclomatic_complexity
	func simpleCallView(geometry: GeometryProxy) -> some View {
		ZStack {
			if callViewModel.isOneOneCall {
				VStack {
					Spacer()
					ZStack {
						
						if callViewModel.isRemoteDeviceTrusted {
							Circle()
								.fill(Color.blueInfo500)
								.frame(width: 206, height: 206)
						}
						
						if callViewModel.avatarModel != nil {
							Avatar(contactAvatarModel: callViewModel.avatarModel!, avatarSize: 200, hidePresence: true)
						}
						
						if callViewModel.isRemoteDeviceTrusted {
							VStack {
								Spacer()
								HStack {
									Image("trusted")
										.resizable()
										.frame(width: 25, height: 25)
										.padding(.all, 15)
									Spacer()
								}
							}
							.frame(width: 200, height: 200)
						}
					}
					
					Text(callViewModel.displayName)
						.padding(.top)
						.default_text_style_white(styleSize: 22)
					
					Text(callViewModel.remoteAddressString)
						.default_text_style_white_300(styleSize: 16)
					
					Spacer()
				}
				
				if telecomManager.remoteConfVideo {
					LinphoneVideoViewHolder { view in
						coreContext.doOnCoreQueue { core in
							core.nativeVideoWindow = view
							DispatchQueue.main.async {
								CoreContext.shared.pipViewModel.setupPiPViewController(remoteView: view)
							}
						}
					}
					.frame(
						width: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						height: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
					)
					.scaledToFill()
					.clipped()
					.onTapGesture {
						if telecomManager.remoteConfVideo {
							fullscreenVideo.toggle()
						}
					}
					.onAppear {
						if callViewModel.videoDisplayed {
							if coreContext.pipViewModel.pipController?.isPictureInPictureActive ?? false {
								coreContext.pipViewModel.pipController?.stopPictureInPicture()
							}
							callViewModel.videoDisplayed = false
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
								callViewModel.videoDisplayed = true
							}
						}
					}
					.onDisappear {
						if callViewModel.videoDisplayed {
							if !callViewModel.isPaused && TelecomManager.shared.callInProgress
								&& !(coreContext.pipViewModel.pipController?.isPictureInPictureActive ?? false) {
								coreContext.pipViewModel.pipController?.startPictureInPicture()
							}
							callViewModel.videoDisplayed = false
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
								callViewModel.videoDisplayed = true
							}
						}
						
						fullscreenVideo = false
					}
				}
				
				if callViewModel.videoDisplayed {
					HStack {
						Spacer()
						VStack {
							Spacer()
							HStack {
								LinphoneVideoViewHolder { view in
									coreContext.doOnCoreQueue { core in
										core.nativePreviewWindow = view
									}
								}
								.aspectRatio(callViewModel.callStatsModel.sentVideoWindow.widthFactor/callViewModel.callStatsModel.sentVideoWindow.heightFactor, contentMode: .fill)
								.frame(maxWidth: callViewModel.callStatsModel.sentVideoWindow.widthFactor * 256,
									   maxHeight: callViewModel.callStatsModel.sentVideoWindow.heightFactor * 256)
								.clipped()
							}
							.frame(width: angleDegree == 0 ? 120*1.2 : 160*1.2, height: angleDegree == 0 ? 160*1.2 : 120*1.2) // 144*192
							.cornerRadius(20)
							.gesture(
								DragGesture(coordinateSpace: .global)
									.onChanged { value in
										previewVideoOffset = CGSize(width: previewVideoOffsetPreviousDrag.width + value.translation.width,
																	height: previewVideoOffsetPreviousDrag.height + value.translation.height)
									}
									.onEnded { _ in
										previewVideoOffsetPreviousDrag = previewVideoOffset
									}
							)
										
							.offset(x: previewVideoOffset.width, y: previewVideoOffset.height)
						}
						.padding(10)
						.padding(.trailing, abs(angleDegree/2))
					}
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
					)
				}
				if telecomManager.outgoingCallStarted {
					VStack {
						ActivityIndicator(color: .white)
							.frame(width: 20, height: 20)
							.padding(.top, 60)
						
						Text(callViewModel.counterToMinutes())
							.onAppear {
								callViewModel.timeElapsed = 0
							}
							.onReceive(callViewModel.timer) { _ in
								callViewModel.timeElapsed = callViewModel.currentCall?.duration ?? 0
								
							}
							.onDisappear {
								callViewModel.timeElapsed = 0
							}
							.padding(.top)
							.foregroundStyle(.white)
						
						Spacer()
					}
					.background(.clear)
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
					)
				}
			} else if callViewModel.isConference && !telecomManager.outgoingCallStarted && callViewModel.activeSpeakerParticipant != nil {
				let heightValue = (fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom)
				if optionsChangeLayout == 1 && callViewModel.participantList.count <= 5 {
					mosaicMode(geometry: geometry, height: heightValue)
				} else if optionsChangeLayout == 3 {
					audioOnlyMode(geometry: geometry, height: heightValue)
				} else {
					activeSpeakerMode(geometry: geometry)
				}
			} else if callViewModel.isConference && !telecomManager.outgoingCallStarted && callViewModel.participantList.isEmpty {
				VStack {
					Spacer()
					
					Text("conference_call_empty")
						.frame(maxWidth: .infinity, alignment: .center)
						.foregroundStyle(Color.white)
						.default_text_style_300(styleSize: 25)
						.lineLimit(1)
						.padding(.bottom, 4)
					
					Button(action: {
						UIPasteboard.general.setValue(
							callViewModel.remoteAddressString,
							forPasteboardType: UTType.plainText.identifier
						)
						
						DispatchQueue.main.async {
							ToastViewModel.shared.toastMessage = "Success_address_copied_into_clipboard"
							ToastViewModel.shared.displayToast = true
						}
					}, label: {
						HStack {
							Image("share-network")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle(Color.grayMain2c400)
								.frame(width: 30, height: 30)
							
							Text("conference_share_link_title")
								.foregroundStyle(Color.grayMain2c400)
								.default_text_style(styleSize: 25)
								.frame(height: 40)
						}
					})
					.padding(.horizontal, 20)
					.padding(.vertical, 10)
					.cornerRadius(60)
					.overlay(
						RoundedRectangle(cornerRadius: 60)
							.inset(by: 0.5)
							.stroke(Color.grayMain2c400, lineWidth: 1)
					)
					
					Spacer()
				}
				.onAppear {
					fullscreenVideo = false
				}
				
				HStack {
					Spacer()
					VStack {
						Spacer()
						HStack {
							LinphoneVideoViewHolder { view in
								coreContext.doOnCoreQueue { core in
									core.nativePreviewWindow = view
								}
							}
							.aspectRatio(callViewModel.callStatsModel.sentVideoWindow.widthFactor/callViewModel.callStatsModel.sentVideoWindow.heightFactor, contentMode: .fill)
							.frame(maxWidth: callViewModel.callStatsModel.sentVideoWindow.widthFactor * 256,
								   maxHeight: callViewModel.callStatsModel.sentVideoWindow.heightFactor * 256)
							.clipped()
						}
						.frame(width: angleDegree == 0 ? 120*1.2 : 160*1.2, height: angleDegree == 0 ? 160*1.2 : 120*1.2) // 144*192
						.cornerRadius(20)
						.gesture(
							DragGesture(coordinateSpace: .global)
								.onChanged { value in
									previewVideoOffset = CGSize(width: previewVideoOffsetPreviousDrag.width + value.translation.width,
																height: previewVideoOffsetPreviousDrag.height + value.translation.height)
								}
								.onEnded { _ in
									previewVideoOffsetPreviousDrag = previewVideoOffset
								}
						)
									
						.offset(x: previewVideoOffset.width, y: previewVideoOffset.height)
					}
					.padding(10)
					.padding(.trailing, abs(angleDegree/2))
				}
				.frame(
					maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
			} else if telecomManager.outgoingCallStarted {
				ProgressView()
					.progressViewStyle(CircularProgressViewStyle(tint: .white))
					.frame(width: 60, height: 60, alignment: .center)
					.onDisappear {
						callViewModel.resetCallView()
					}
			}
			
			if callViewModel.isRecording {
				HStack {
					VStack {
						Image("record-fill")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.redDanger500)
							.frame(width: 32, height: 32)
							.padding(10)
							.if(fullscreenVideo && !telecomManager.isPausedByRemote) { view in
								view.padding(.top, 30)
							}
						Spacer()
					}
					Spacer()
				}
				.frame(
					maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
			}
		}
		.frame(
			maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
			maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
		)
		.background(Color.gray900)
		.cornerRadius(20)
		.padding(.top, callViewModel.isOneOneCall && fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.safeAreaInsets.bottom + 10 : 0)
		.padding(.horizontal, fullscreenVideo && !telecomManager.isPausedByRemote ? 0 : 4)
		.onRotate { newOrientation in
			let oldOrientation = orientation
			orientation = newOrientation
			if orientation == .portrait || orientation == .portraitUpsideDown {
				angleDegree = 0
			} else {
				if orientation == .landscapeLeft {
					angleDegree = -90
				} else if orientation == .landscapeRight {
					angleDegree = 90
				} else if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
					angleDegree = 90
				}
			}
			
			if (oldOrientation != orientation && oldOrientation != .faceUp) || (oldOrientation == .faceUp && (orientation == .landscapeLeft || orientation == .landscapeRight)) {
				telecomManager.callStarted = false
				
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					telecomManager.callStarted = true
				}
			}
			
			callViewModel.orientationUpdate(orientation: orientation)
		}
		.onAppear {
			if orientation == .portrait && orientation == .portraitUpsideDown {
				angleDegree = 0
			} else {
				if orientation == .landscapeLeft {
					angleDegree = -90
				} else if orientation == .landscapeRight {
					angleDegree = 90
				} else if UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height {
					angleDegree = 90
				}
			}
			
			callViewModel.orientationUpdate(orientation: orientation)
		}
		.onReceive(telecomManager.$remoteConfVideo, perform: { videoOn in
			if videoOn {
				fullscreenVideo = videoOn
			}
		})
	}
	
	// swiftlint:disable:next cyclomatic_complexity
	func activeSpeakerMode(geometry: GeometryProxy) -> some View {
		ZStack {
			let isLandscapeMode = (orientation == .landscapeLeft || orientation == .landscapeRight || UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height)
			if callViewModel.activeSpeakerParticipant!.onPause {
				VStack {
					VStack {
						Spacer()
						
						Image("pause")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(.white)
							.frame(width: 40, height: 40)
						
						Text("conference_participant_paused_text")
							.frame(maxWidth: .infinity, alignment: .center)
							.foregroundStyle(Color.white)
							.default_text_style_500(styleSize: 14)
							.lineLimit(1)
							.padding(.horizontal, 10)
						
						Spacer()
					}
					.frame(
						width: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width - (isLandscapeMode ? 160 : 0) : geometry.size.width - 8 - (isLandscapeMode ? 160 : 0),
						height: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom  - (!isLandscapeMode ? 160 : 0) - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0) : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20  - (!isLandscapeMode ? 160 : 0) + geometry.safeAreaInsets.bottom - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0)
					)
					
					Spacer()
				}
				.frame(
					maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
			} else {
				VStack {
					HStack {
						VStack {
							Spacer()
							HStack {
								if callViewModel.activeSpeakerParticipant != nil {
									Avatar(contactAvatarModel: callViewModel.activeSpeakerParticipant!.avatarModel, avatarSize: 200, hidePresence: true)
									 .onAppear {
										 DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
											 displayVideo = true
										 }
									 }
								}
							}
							
							Spacer()
						}
						.frame(
							width: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width - (isLandscapeMode ? 160 : 0) : geometry.size.width - 8 - (isLandscapeMode ? 160 : 0),
							height: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom  - (!isLandscapeMode ? 160 : 0) - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0) : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20  - (!isLandscapeMode ? 160 : 0) - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0) + geometry.safeAreaInsets.bottom
						)
						
						if isLandscapeMode {
							Spacer()
						}
					}
					
					Spacer()
				}
				.frame(
					maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
				
				VStack {
					if telecomManager.remoteConfVideo && !telecomManager.outgoingCallStarted && callViewModel.activeSpeakerParticipant != nil && displayVideo {
						HStack {
							VStack {
								LinphoneVideoViewHolder { view in
									coreContext.doOnCoreQueue { core in
										core.nativeVideoWindow = view
										DispatchQueue.main.async {
											CoreContext.shared.pipViewModel.setupPiPViewController(remoteView: view)
										}
									}
								}
								.onAppear {
									if coreContext.pipViewModel.pipController?.isPictureInPictureActive ?? false {
										coreContext.pipViewModel.pipController?.stopPictureInPicture()
									}
								}
								.onDisappear {
									if !callViewModel.isPaused && TelecomManager.shared.callInProgress
										&& !(coreContext.pipViewModel.pipController?.isPictureInPictureActive ?? false) {
										coreContext.pipViewModel.pipController?.startPictureInPicture()
									}
								}
							}
							.frame(
								width: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width - (isLandscapeMode ? 160 : 0) : geometry.size.width - 8 - (isLandscapeMode ? 160 : 0),
								height: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom  - (!isLandscapeMode ? 160 : 0) - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0) : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20  - (!isLandscapeMode ? 160 : 0) - (isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? 40 : 0) + geometry.safeAreaInsets.bottom
							)
							.cornerRadius(20)
							
							if isLandscapeMode {
								Spacer()
							}
						}
					}
					Spacer()
				}
				.frame(
					width: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					height: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
			}
			
			if callViewModel.isConference && !telecomManager.outgoingCallStarted && callViewModel.activeSpeakerParticipant != nil && callViewModel.activeSpeakerParticipant!.isMuted {
				VStack {
					HStack {
						Spacer()
						
						HStack(alignment: .center) {
							Image("microphone-slash")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle(Color.grayMain2c800)
								.frame(width: 20, height: 20)
						}
						.padding(5)
						.background(.white)
						.cornerRadius(40)
						
						if isLandscapeMode {
							Spacer()
								.frame(width: 160)
						}
					}
					Spacer()
				}
				.frame(maxWidth: .infinity)
				.padding(.all, 20)
			}
			
			if callViewModel.isConference {
				HStack {
					Spacer()
					VStack {
						Spacer()
						
						Text(callViewModel.activeSpeakerName)
							.frame(maxWidth: .infinity, alignment: .leading)
							.foregroundStyle(Color.white)
							.default_text_style_500(styleSize: 20)
							.lineLimit(1)
							.padding(.horizontal, 10)
							.padding(.bottom, 6)
							.padding(.top, isLandscapeMode && fullscreenVideo && !telecomManager.isPausedByRemote ? -70 : 0)
						
						if !isLandscapeMode {
							ScrollView(.horizontal) {
								HStack {
									ZStack {
										VStack {
											Spacer()
											
											if callViewModel.myParticipantModel != nil {
												Avatar(contactAvatarModel: callViewModel.myParticipantModel!.avatarModel, avatarSize: 50, hidePresence: true)
											}
											
											Spacer()
										}
										.frame(width: 140, height: 140)
										
										if callViewModel.videoDisplayed {
											LinphoneVideoViewHolder { view in
												coreContext.doOnCoreQueue { core in
													core.nativePreviewWindow = view
												}
											}
											.frame(width: angleDegree == 0 ? 120*1.2 : 160*1.2, height: angleDegree == 0 ? 160*1.2 : 120*1.2)
											.scaledToFill()
											.clipped()
										}
										
										VStack(alignment: .leading) {
											Spacer()
											
											if callViewModel.myParticipantModel != nil {
												Text(callViewModel.myParticipantModel!.name)
													.frame(maxWidth: .infinity, alignment: .leading)
													.foregroundStyle(Color.white)
													.default_text_style_500(styleSize: 14)
													.lineLimit(1)
													.padding(.horizontal, 10)
													.padding(.bottom, 6)
											}
										}
										.frame(width: 140, height: 140)
									}
									.frame(width: 140, height: 140)
									.background(Color.gray600)
									.overlay(
										RoundedRectangle(cornerRadius: 20)
											.stroke(callViewModel.myParticipantModel != nil && callViewModel.myParticipantModel!.isSpeaking ? .white : .clear, lineWidth: 4)
									)
									.cornerRadius(20)
									
									ForEach(0..<callViewModel.participantList.count, id: \.self) { index in
										if callViewModel.activeSpeakerParticipant != nil && !callViewModel.participantList[index].address.equal(address2: callViewModel.activeSpeakerParticipant!.address) {
											ZStack {
												if callViewModel.participantList[index].isJoining {
													VStack {
														Spacer()
														
														ActivityIndicator(color: .white)
															.frame(width: 40, height: 40)
															.padding(.bottom, 5)
														
														Text("conference_participant_joining_text")
															.frame(maxWidth: .infinity, alignment: .center)
															.foregroundStyle(Color.white)
															.default_text_style_500(styleSize: 14)
															.lineLimit(1)
															.padding(.horizontal, 10)
														
														Spacer()
													}
												} else if callViewModel.participantList[index].onPause {
													VStack {
														Spacer()
														
														Image("pause")
															.renderingMode(.template)
															.resizable()
															.foregroundStyle(.white)
															.frame(width: 40, height: 40)
														
														Text("conference_participant_paused_text")
															.frame(maxWidth: .infinity, alignment: .center)
															.foregroundStyle(Color.white)
															.default_text_style_500(styleSize: 14)
															.lineLimit(1)
															.padding(.horizontal, 10)
														
														Spacer()
													}
												} else {
													VStack {
														Spacer()
														
														Avatar(contactAvatarModel: callViewModel.participantList[index].avatarModel, avatarSize: 50, hidePresence: true)
														
														Spacer()
													}
													
													LinphoneVideoViewHolder { view in
														coreContext.doOnCoreQueue { core in
															if index < callViewModel.participantList.count {
																let participantVideo = core.currentCall?.conference?.participantList.first(where: {$0.address!.equal(address2: callViewModel.participantList[index].address)})
																if participantVideo != nil && participantVideo!.devices.first != nil {
																	participantVideo!.devices.first!.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
																}
															}
														}
													}
													
													if callViewModel.participantList[index].isMuted {
														VStack {
															HStack {
																Spacer()
																
																HStack(alignment: .center) {
																	Image("microphone-slash")
																		.renderingMode(.template)
																		.resizable()
																		.foregroundStyle(Color.grayMain2c800)
																		.frame(width: 12, height: 12)
																}
																.padding(2)
																.background(.white)
																.cornerRadius(40)
															}
															Spacer()
														}
														.frame(maxWidth: .infinity)
														.padding(.all, 10)
													}
												}
												
												VStack(alignment: .leading) {
													Spacer()
													
													Text(callViewModel.participantList[index].name)
														.frame(maxWidth: .infinity, alignment: .leading)
														.foregroundStyle(Color.white)
														.default_text_style_500(styleSize: 14)
														.lineLimit(1)
														.padding(.horizontal, 10)
														.padding(.bottom, 6)
												}
												.frame(maxWidth: .infinity)
											}
											.frame(width: 140, height: 140)
											.background(Color.gray600)
											.overlay(
												RoundedRectangle(cornerRadius: 20)
													.stroke(callViewModel.participantList[index].isSpeaking ? .white : .clear, lineWidth: 4)
											)
											.cornerRadius(20)
										}
									}
								}
							}
						}
					}
				}
				.frame(
					maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
					maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
				)
				.padding(.bottom, 10)
				.padding(.leading, -10)
				
				if isLandscapeMode {
					HStack {
						Spacer()
						ScrollView(.vertical) {
							VStack {
								ZStack {
									VStack {
										Spacer()
										
										if callViewModel.myParticipantModel != nil {
											Avatar(contactAvatarModel: callViewModel.myParticipantModel!.avatarModel, avatarSize: 50, hidePresence: true)
										}
										
										Spacer()
									}
									.frame(width: 140, height: 140)
									
									if callViewModel.videoDisplayed {
										LinphoneVideoViewHolder { view in
											coreContext.doOnCoreQueue { core in
												core.nativePreviewWindow = view
											}
										}
										.frame(width: angleDegree == 0 ? 120*1.2 : 160*1.2, height: angleDegree == 0 ? 160*1.2 : 120*1.2)
										.scaledToFill()
										.clipped()
									}
									
									VStack(alignment: .leading) {
										Spacer()
										
										if callViewModel.myParticipantModel != nil {
											Text(callViewModel.myParticipantModel!.name)
												.frame(maxWidth: .infinity, alignment: .leading)
												.foregroundStyle(Color.white)
												.default_text_style_500(styleSize: 14)
												.lineLimit(1)
												.padding(.horizontal, 10)
												.padding(.bottom, 6)
										}
									}
									.frame(width: 140, height: 140)
								}
								.frame(width: 140, height: 140)
								.background(Color.gray600)
								.overlay(
									RoundedRectangle(cornerRadius: 20)
										.stroke(callViewModel.myParticipantModel != nil && callViewModel.myParticipantModel!.isSpeaking ? .white : .clear, lineWidth: 4)
								)
								.cornerRadius(20)
								
								ForEach(0..<callViewModel.participantList.count, id: \.self) { index in
									if callViewModel.activeSpeakerParticipant != nil && !callViewModel.participantList[index].address.equal(address2: callViewModel.activeSpeakerParticipant!.address) {
										ZStack {
											if callViewModel.participantList[index].isJoining {
												VStack {
													Spacer()
													
													ActivityIndicator(color: .white)
														.frame(width: 40, height: 40)
														.padding(.bottom, 5)
													
													Text("conference_participant_joining_text")
														.frame(maxWidth: .infinity, alignment: .center)
														.foregroundStyle(Color.white)
														.default_text_style_500(styleSize: 14)
														.lineLimit(1)
														.padding(.horizontal, 10)
													
													Spacer()
												}
											} else if callViewModel.participantList[index].onPause {
												VStack {
													Spacer()
													
													Image("pause")
														.renderingMode(.template)
														.resizable()
														.foregroundStyle(.white)
														.frame(width: 40, height: 40)
													
													Text("conference_participant_paused_text")
														.frame(maxWidth: .infinity, alignment: .center)
														.foregroundStyle(Color.white)
														.default_text_style_500(styleSize: 14)
														.lineLimit(1)
														.padding(.horizontal, 10)
													
													Spacer()
												}
											} else {
												VStack {
													Spacer()
													
													Avatar(contactAvatarModel: callViewModel.participantList[index].avatarModel, avatarSize: 50, hidePresence: true)
													
													Spacer()
												}
												
												LinphoneVideoViewHolder { view in
													coreContext.doOnCoreQueue { core in
														if index < callViewModel.participantList.count {
															let participantVideo = core.currentCall?.conference?.participantList.first(where: {$0.address!.equal(address2: callViewModel.participantList[index].address)})
															if participantVideo != nil && participantVideo!.devices.first != nil {
																participantVideo!.devices.first!.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
															}
														}
													}
												}
												
												if callViewModel.participantList[index].isMuted {
													VStack {
														HStack {
															Spacer()
															
															HStack(alignment: .center) {
																Image("microphone-slash")
																	.renderingMode(.template)
																	.resizable()
																	.foregroundStyle(Color.grayMain2c800)
																	.frame(width: 12, height: 12)
															}
															.padding(2)
															.background(.white)
															.cornerRadius(40)
														}
														Spacer()
													}
													.frame(maxWidth: .infinity)
													.padding(.all, 10)
												}
											}
											
											VStack(alignment: .leading) {
												Spacer()
												
												Text(callViewModel.participantList[index].name)
													.frame(maxWidth: .infinity, alignment: .leading)
													.foregroundStyle(Color.white)
													.default_text_style_500(styleSize: 14)
													.lineLimit(1)
													.padding(.horizontal, 10)
													.padding(.bottom, 6)
											}
											.frame(maxWidth: .infinity)
										}
										.frame(width: 140, height: 140)
										.background(Color.gray600)
										.overlay(
											RoundedRectangle(cornerRadius: 20)
												.stroke(callViewModel.participantList[index].isSpeaking ? .white : .clear, lineWidth: 4)
										)
										.cornerRadius(20)
									}
								}
							}
						}
					}
					.frame(
						maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
						maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
					)
					.padding(.bottom, 10)
					.padding(.leading, -10)
				}
			}
		}
		.padding(.top, fullscreenVideo && !telecomManager.isPausedByRemote && (orientation == .landscapeLeft || orientation == .landscapeRight || UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height) ? 50 : 10)
		.frame(
			maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
			maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom - ((orientation == .landscapeLeft || orientation == .landscapeRight || UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height) ? 50 : 10) : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom - ((orientation == .landscapeLeft || orientation == .landscapeRight || UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height) ? 50 : 10)
		)
		.contentShape(Rectangle())
		.onTapGesture {
			fullscreenVideo.toggle()
		}
		.onAppear {
			optionsChangeLayout = 2
		}
	}
	
	// swiftlint:disable:next cyclomatic_complexity
	func mosaicMode(geometry: GeometryProxy, height: Double) -> some View {
		VStack {
			if geometry.size.width < geometry.size.height {
				let maxValue = max(
					((geometry.size.width/2) - 10.0) * ceil(Double(callViewModel.participantList.count + 1) / 2.0) > height ? ((height / 3) - 10.0) : ((geometry.size.width/2) - 10.0),
				 ((height / Double(callViewModel.participantList.count + 1)) - 10.0)
				)
				
				LazyVGrid(columns: [
					GridItem(.adaptive(
						minimum: maxValue
					))
				], spacing: 10) {
					if callViewModel.myParticipantModel != nil {
						ZStack {
							if callViewModel.myParticipantModel!.isJoining {
								VStack {
									Spacer()
									
									ActivityIndicator(color: .white)
										.frame(width: maxValue/4, height: maxValue/4)
										.padding(.bottom, 5)
									
									Text("conference_participant_joining_text")
										.frame(maxWidth: .infinity, alignment: .center)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
									
									Spacer()
								}
							} else if callViewModel.myParticipantModel!.onPause {
								VStack {
									Spacer()
									
									Image("pause")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(.white)
										.frame(width: maxValue/4, height: maxValue/4)
									
									Text("conference_participant_paused_text")
										.frame(maxWidth: .infinity, alignment: .center)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
									
									Spacer()
								}
							} else {
								VStack {
									Spacer()
									
									if callViewModel.myParticipantModel != nil {
										Avatar(contactAvatarModel: callViewModel.myParticipantModel!.avatarModel, avatarSize: maxValue/2, hidePresence: true)
									}
									
									Spacer()
								}
								.frame(width: maxValue, height: maxValue)
								
								if callViewModel.videoDisplayed {
									LinphoneVideoViewHolder { view in
										coreContext.doOnCoreQueue { core in
											core.nativePreviewWindow = view
										}
									}
									.frame(
										width: 120 * ceil(maxValue / 120),
										height: 160 * ceil(maxValue / 120)
									)
									.scaledToFill()
									.clipped()
								}
								
								if callViewModel.myParticipantModel!.isMuted {
									VStack {
										HStack {
											Spacer()
											
											HStack(alignment: .center) {
												Image("microphone-slash")
													.renderingMode(.template)
													.resizable()
													.foregroundStyle(Color.grayMain2c800)
													.frame(width: 12, height: 12)
											}
											.padding(2)
											.background(.white)
											.cornerRadius(40)
										}
										Spacer()
									}
									.frame(maxWidth: .infinity)
									.padding(.all, 10)
								}
							}
							
							VStack(alignment: .leading) {
								Spacer()
								
								if callViewModel.myParticipantModel != nil {
									Text(callViewModel.myParticipantModel!.name)
										.frame(maxWidth: .infinity, alignment: .leading)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
										.padding(.bottom, 6)
								}
							}
							.frame(width: maxValue, height: maxValue)
						}
						.frame(
							width: maxValue,
							height: maxValue,
							alignment: .center
						)
						.background(Color.gray600)
						.overlay(
		  					RoundedRectangle(cornerRadius: 20)
								.stroke(callViewModel.myParticipantModel!.isSpeaking ? .white : .clear, lineWidth: 4)
	  					)
						.cornerRadius(20)
					}
					
					ForEach(0..<callViewModel.participantList.count, id: \.self) { index in
						if index < callViewModel.participantList.count {
							ZStack {
								if callViewModel.participantList[index].isJoining {
									VStack {
										Spacer()
										
										ActivityIndicator(color: .white)
											.frame(width: maxValue/4, height: maxValue/4)
											.padding(.bottom, 5)
										
										Text("conference_participant_joining_text")
											.frame(maxWidth: .infinity, alignment: .center)
											.foregroundStyle(Color.white)
											.default_text_style_500(styleSize: 14)
											.lineLimit(1)
											.padding(.horizontal, 10)
										
										Spacer()
									}
								} else if callViewModel.participantList[index].onPause {
									VStack {
										Spacer()
										
										Image("pause")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: maxValue/4, height: maxValue/4)
										
										Text("conference_participant_paused_text")
											.frame(maxWidth: .infinity, alignment: .center)
											.foregroundStyle(Color.white)
											.default_text_style_500(styleSize: 14)
											.lineLimit(1)
											.padding(.horizontal, 10)
										
										Spacer()
									}
								} else {
									VStack {
										Spacer()
										
										Avatar(contactAvatarModel: callViewModel.participantList[index].avatarModel, avatarSize: maxValue/2, hidePresence: true)
										
										Spacer()
									}
									.frame(width: maxValue, height: maxValue)
									
									LinphoneVideoViewHolder { view in
										coreContext.doOnCoreQueue { core in
											if index < callViewModel.participantList.count {
												let participantVideo = core.currentCall?.conference?.participantList.first(where: {$0.address!.equal(address2: callViewModel.participantList[index].address)})
												if participantVideo != nil && participantVideo!.devices.first != nil {
													participantVideo!.devices.first!.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
												}
											}
										}
									}
									
									if callViewModel.participantList[index].isMuted {
										VStack {
											HStack {
												Spacer()
												
												HStack(alignment: .center) {
													Image("microphone-slash")
														.renderingMode(.template)
														.resizable()
														.foregroundStyle(Color.grayMain2c800)
														.frame(width: 12, height: 12)
												}
												.padding(2)
												.background(.white)
												.cornerRadius(40)
											}
											Spacer()
										}
										.frame(maxWidth: .infinity)
										.padding(.all, 10)
									}
								}
								
								VStack(alignment: .leading) {
									Spacer()
									
									Text(callViewModel.participantList[index].name)
										.frame(maxWidth: .infinity, alignment: .leading)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
										.padding(.bottom, 6)
								}
								.frame(width: maxValue, height: maxValue)
							}
							.frame(
								width: maxValue,
								height: maxValue,
								alignment: .center
							)
							.background(Color.gray600)
							.overlay(
								RoundedRectangle(cornerRadius: 20)
									.stroke(callViewModel.participantList[index].isSpeaking ? .white : .clear, lineWidth: 4)
							)
							.cornerRadius(20)
						}
					}
				}
			} else {
				let maxValue = max(
					((geometry.size.width/3) - 10.0) * ceil(Double(callViewModel.participantList.count + 1) / 3.0) > height ? ((height / 2) - 10.0) : ((geometry.size.width/3) - 10.0),
					((geometry.size.width/Double(callViewModel.participantList.count + 1)) - 10.0) > height ? height - 20 : ((geometry.size.width/Double(callViewModel.participantList.count + 1)) - 10.0)
				)
				
				LazyHGrid(rows: [
					GridItem(.adaptive(
						minimum: maxValue
					))
				], spacing: 10) {
					if callViewModel.myParticipantModel != nil {
						ZStack {
							if callViewModel.myParticipantModel!.isJoining {
								VStack {
									Spacer()
									
									ActivityIndicator(color: .white)
										.frame(width: maxValue/4, height: maxValue/4)
										.padding(.bottom, 5)
									
									Text("conference_participant_joining_text")
										.frame(maxWidth: .infinity, alignment: .center)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
									
									Spacer()
								}
							} else if callViewModel.myParticipantModel!.onPause {
								VStack {
									Spacer()
									
									Image("pause")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(.white)
										.frame(width: maxValue/4, height: maxValue/4)
									
									Text("conference_participant_paused_text")
										.frame(maxWidth: .infinity, alignment: .center)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
									
									Spacer()
								}
							} else {
								VStack {
									Spacer()
									
									if callViewModel.myParticipantModel != nil {
										Avatar(contactAvatarModel: callViewModel.myParticipantModel!.avatarModel, avatarSize: maxValue/2, hidePresence: true)
									}
									
									Spacer()
								}
								.frame(width: maxValue, height: maxValue)
								
								if callViewModel.videoDisplayed {
									LinphoneVideoViewHolder { view in
										coreContext.doOnCoreQueue { core in
											core.nativePreviewWindow = view
										}
									}
									.frame(
										width: 160 * ceil(maxValue / 120),
										height: 120 * ceil(maxValue / 120)
									)
									.scaledToFill()
									.clipped()
								}
								
								if callViewModel.myParticipantModel!.isMuted {
									VStack {
										HStack {
											Spacer()
											
											HStack(alignment: .center) {
												Image("microphone-slash")
													.renderingMode(.template)
													.resizable()
													.foregroundStyle(Color.grayMain2c800)
													.frame(width: 12, height: 12)
											}
											.padding(2)
											.background(.white)
											.cornerRadius(40)
										}
										Spacer()
									}
									.frame(maxWidth: .infinity)
									.padding(.all, 10)
								}
							}
							
							VStack(alignment: .leading) {
								Spacer()
								
								if callViewModel.myParticipantModel != nil {
									Text(callViewModel.myParticipantModel!.name)
										.frame(maxWidth: .infinity, alignment: .leading)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
										.padding(.bottom, 6)
								}
							}
							.frame(width: maxValue, height: maxValue)
						}
						.frame(
							width: maxValue,
							height: maxValue,
							alignment: .center
						)
						.background(Color.gray600)
						.overlay(
							RoundedRectangle(cornerRadius: 20)
								.stroke(callViewModel.myParticipantModel!.isSpeaking ? .white : .clear, lineWidth: 4)
						)
						.cornerRadius(20)
					}
					
					ForEach(0..<callViewModel.participantList.count, id: \.self) { index in
						if index < callViewModel.participantList.count {
							ZStack {
								if callViewModel.participantList[index].isJoining {
									VStack {
										Spacer()
										
										ActivityIndicator(color: .white)
											.frame(width: maxValue/4, height: maxValue/4)
											.padding(.bottom, 5)
										
										Text("conference_participant_joining_text")
											.frame(maxWidth: .infinity, alignment: .center)
											.foregroundStyle(Color.white)
											.default_text_style_500(styleSize: 14)
											.lineLimit(1)
											.padding(.horizontal, 10)
										
										Spacer()
									}
								} else if callViewModel.participantList[index].onPause {
									VStack {
										Spacer()
										
										Image("pause")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: maxValue/4, height: maxValue/4)
										
										Text("conference_participant_paused_text")
											.frame(maxWidth: .infinity, alignment: .center)
											.foregroundStyle(Color.white)
											.default_text_style_500(styleSize: 14)
											.lineLimit(1)
											.padding(.horizontal, 10)
										
										Spacer()
									}
								} else {
									VStack {
										Spacer()
										
										Avatar(contactAvatarModel: callViewModel.participantList[index].avatarModel, avatarSize: maxValue/2, hidePresence: true)
										
										Spacer()
									}
									.frame(width: maxValue, height: maxValue)
									
									LinphoneVideoViewHolder { view in
										coreContext.doOnCoreQueue { core in
											if index < callViewModel.participantList.count {
												let participantVideo = core.currentCall?.conference?.participantList.first(where: {$0.address!.equal(address2: callViewModel.participantList[index].address)})
												if participantVideo != nil && participantVideo!.devices.first != nil {
													participantVideo!.devices.first!.nativeVideoWindowId = UnsafeMutableRawPointer(Unmanaged.passRetained(view).toOpaque())
												}
											}
										}
									}
									
									if callViewModel.participantList[index].isMuted {
										VStack {
											HStack {
												Spacer()
												
												HStack(alignment: .center) {
													Image("microphone-slash")
														.renderingMode(.template)
														.resizable()
														.foregroundStyle(Color.grayMain2c800)
														.frame(width: 12, height: 12)
												}
												.padding(2)
												.background(.white)
												.cornerRadius(40)
											}
											Spacer()
										}
										.frame(maxWidth: .infinity)
										.padding(.all, 10)
									}
								}
								
								VStack(alignment: .leading) {
									Spacer()
									
									Text(callViewModel.participantList[index].name)
										.frame(maxWidth: .infinity, alignment: .leading)
										.foregroundStyle(Color.white)
										.default_text_style_500(styleSize: 14)
										.lineLimit(1)
										.padding(.horizontal, 10)
										.padding(.bottom, 6)
								}
								.frame(width: maxValue, height: maxValue)
							}
							.frame(
								width: maxValue,
								height: maxValue,
								alignment: .center
							)
							.background(Color.gray600)
							.overlay(
								RoundedRectangle(cornerRadius: 20)
									.stroke(callViewModel.participantList[index].isSpeaking ? .white : .clear, lineWidth: 4)
							)
							.cornerRadius(20)
						}
					}
				}
			}
		}
		.frame(
			maxWidth: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.width : geometry.size.width - 8,
			maxHeight: fullscreenVideo && !telecomManager.isPausedByRemote ? geometry.size.height : geometry.size.height - (minBottomSheetHeight * geometry.size.height > 80 ? minBottomSheetHeight * geometry.size.height : 78) - 40 - 20 + geometry.safeAreaInsets.bottom
		)
		.contentShape(Rectangle())
		.onTapGesture {
			fullscreenVideo.toggle()
		}
	}
	
	func audioOnlyMode(geometry: GeometryProxy, height: Double) -> some View {
		VStack {
			let layout = [
				GridItem(.fixed((geometry.size.width/2)-10)),
				GridItem(.fixed((geometry.size.width/2)-10))
			]
			ScrollView {
				LazyVGrid(columns: layout) {
					if callViewModel.myParticipantModel != nil {
						HStack {
							Avatar(contactAvatarModel: callViewModel.myParticipantModel!.avatarModel, avatarSize: 50, hidePresence: true)
							
							Text(callViewModel.myParticipantModel!.name)
								.frame(maxWidth: .infinity, alignment: .leading)
								.foregroundStyle(Color.white)
								.default_text_style_500(styleSize: 14)
								.lineLimit(1)
								.padding(.horizontal, 10)
							
							if callViewModel.myParticipantModel!.isMuted {
								HStack(alignment: .center) {
									Image("microphone-slash")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(Color.grayMain2c800)
										.frame(width: 20, height: 20)
								}
								.padding(2)
								.background(.white)
								.cornerRadius(40)
							}
							
							if callViewModel.myParticipantModel!.onPause {
								Image("pause")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 25, height: 25)
							}
						}
						.frame(height: 80)
						.padding(.all, 10)
						.background(Color.gray600)
						.overlay(
							RoundedRectangle(cornerRadius: 20)
								.stroke(callViewModel.myParticipantModel!.isSpeaking ? .white : .clear, lineWidth: 4)
						)
						.cornerRadius(20)
					}
					
					ForEach(0..<callViewModel.participantList.count, id: \.self) { index in
						HStack {
							Avatar(contactAvatarModel: callViewModel.participantList[index].avatarModel, avatarSize: 50, hidePresence: true)
							
							Text(callViewModel.participantList[index].name)
								.frame(maxWidth: .infinity, alignment: .leading)
								.foregroundStyle(Color.white)
								.default_text_style_500(styleSize: 14)
								.lineLimit(1)
								.padding(.horizontal, 10)
							
							if callViewModel.participantList[index].isMuted {
								HStack(alignment: .center) {
									Image("microphone-slash")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(Color.grayMain2c800)
										.frame(width: 20, height: 20)
								}
								.padding(2)
								.background(.white)
								.cornerRadius(40)
							}
							
							if callViewModel.participantList[index].onPause {
								Image("pause")
									.renderingMode(.template)
									.resizable()
									.foregroundStyle(.white)
									.frame(width: 25, height: 25)
							}
						}
						.frame(height: 80)
						.padding(.all, 10)
						.background(Color.gray600)
						.overlay(
							RoundedRectangle(cornerRadius: 20)
								.stroke(callViewModel.participantList[index].isSpeaking ? .white : .clear, lineWidth: 4)
						)
						.cornerRadius(20)
					}
				}
			}
			.frame(width: geometry.size.width, height: height)
		}
	}
	
	// swiftlint:disable:next cyclomatic_complexity
	func bottomSheetContent(geo: GeometryProxy) -> some View {
		GeometryReader { _ in
			VStack(spacing: 0) {
				Button {
					withAnimation {
						if currentOffset < (maxBottomSheetHeight * geo.size.height) {
							currentOffset = (maxBottomSheetHeight * geo.size.height)
						} else {
							currentOffset = (minBottomSheetHeight * geo.size.height > 80 ? minBottomSheetHeight * geo.size.height : 78)
						}
						
						pointingUp = -(((currentOffset - (minBottomSheetHeight * geo.size.height > 80 ? minBottomSheetHeight * geo.size.height : 78)) / ((maxBottomSheetHeight * geo.size.height) - (minBottomSheetHeight * geo.size.height > 80 ? minBottomSheetHeight * geo.size.height : 78))) - 0.5) * 2
					}
				} label: {
					ChevronShape(pointingUp: pointingUp)
						.stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
						.frame(width: 40, height: 6)
						.foregroundStyle(.white)
						.contentShape(Rectangle())
						.padding(.top, 15)
				}
				
				HStack(spacing: 12) {
					Button {
						callViewModel.terminateCall()
					} label: {
						Image("phone-disconnect")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(.white)
							.frame(width: 32, height: 32)
						
					}
					.frame(width: buttonSize == 60 ? 90 : 70, height: buttonSize)
					.background(Color.redDanger500)
					.cornerRadius(40)
					
					Spacer()
					
					Button {
						if optionsChangeLayout == 3 {
							optionsChangeLayout = 2
							callViewModel.toggleVideoMode(isAudioOnlyMode: false)
						} else {
							callViewModel.displayMyVideo()
						}
					} label: {
						HStack {
							Image(callViewModel.videoDisplayed ? "video-camera" : "video-camera-slash")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
								.frame(width: 32, height: 32)
						}
					}
					.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
					.frame(width: buttonSize, height: buttonSize)
					.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? .white : Color.gray500)
					.cornerRadius(40)
					.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
					
					Button {
						callViewModel.toggleMuteMicrophone()
					} label: {
						HStack {
							Image(callViewModel.micMutted ? "microphone-slash" : "microphone")
							 .renderingMode(.template)
							 .resizable()
							 .foregroundStyle(.white)
							 .frame(width: 32, height: 32)
						}
					}
					.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
					.frame(width: buttonSize, height: buttonSize)
					.background(callViewModel.micMutted ? Color.redDanger500 : Color.gray500)
					.cornerRadius(40)
					
					Button {
						if AVAudioSession.sharedInstance().availableInputs != nil
							&& !AVAudioSession.sharedInstance().availableInputs!.filter({ $0.portType.rawValue.contains("Bluetooth") }).isEmpty {
							
							DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
								audioRouteSheet = true
							}
						} else {
							do {
								try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue == "Speaker" }).isEmpty ? .speaker : .none)
							} catch _ {
								
							}
						}
						
					} label: {
						HStack {
							Image(imageAudioRoute)
							 .renderingMode(.template)
							 .resizable()
							 .foregroundStyle(.white)
							 .frame(width: 32, height: 32)
							 .onAppear(perform: getAudioRouteImage)
							 .onReceive(pub) { _ in
								 self.getAudioRouteImage()
							 }
						}
					}
					.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
					.frame(width: buttonSize, height: buttonSize)
					.background(Color.gray500)
					.cornerRadius(40)
				}
				.frame(height: geo.size.height * 0.15)
				.padding(.horizontal, 20)
				.padding(.top, -5)
				
				if orientation != .landscapeLeft && orientation != .landscapeRight {
					HStack(spacing: 0) {
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									if callViewModel.callsCounter < 2 {
										withAnimation {
											callViewModel.isTransferInsteadCall = true
											MagicSearchSingleton.shared.searchForSuggestions()
											isShowStartCallFragment.toggle()
										}
										
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
											telecomManager.callStarted = false
											DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
												telecomManager.callStarted = true
											}
										}
									} else {
										callViewModel.transferClicked()
									}
								} label: {
									HStack {
										Image("phone-transfer")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text(callViewModel.callsCounter < 2 ? "call_action_blind_transfer" : "call_action_attended_transfer")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
							
							VStack {
								Button {
									withAnimation {
										MagicSearchSingleton.shared.searchForSuggestions()
										isShowStartCallFragment.toggle()
									}
									
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("phone-plus")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_start_new_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						} else {
							VStack {
								Button {
								} label: {
									HStack {
										Image("screencast")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(Color.gray500)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(.white)
								.cornerRadius(40)
								.disabled(true)
								
								Text("conference_action_screen_sharing")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
							
							VStack {
								Button {
									withAnimation {
										isShowParticipantsListFragment.toggle()
									}
								} label: {
									HStack {
										Image("users")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("conference_action_show_participants")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						}
						VStack {
							ZStack {
								Button {
									callViewModel.getCallsList()
									withAnimation {
										isShowCallsListFragment.toggle()
									}
									
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("phone-list")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								if callViewModel.callsCounter > 1 {
									VStack {
										HStack {
											Spacer()
											
											VStack {
												Text("\(callViewModel.callsCounter)")
													.foregroundStyle(.white)
													.default_text_style(styleSize: 15)
											}
											.frame(width: 20, height: 20)
											.background(Color.redDanger500)
											.cornerRadius(10)
										}
										
										Spacer()
									}
									.frame(width: buttonSize, height: buttonSize)
								}
							}
							
							Text("call_action_go_to_calls_list")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									showingDialer.toggle()
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("dialer")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_show_dialer")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						} else {
							VStack {
								Button {
									changeLayoutSheet = true
								} label: {
									HStack {
										Image("notebook")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_change_layout")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						}
					}
					.frame(height: geo.size.height * 0.15)
					
					HStack(spacing: 0) {
						VStack {
							Button {
								callViewModel.createConversation()
							} label: {
								HStack {
									if !callViewModel.operationInProgress {
										Image("chat-teardrop-text")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									} else {
										ProgressView()
											.controlSize(.mini)
											.progressViewStyle(CircularProgressViewStyle(tint: .white))
											.frame(width: 32, height: 32, alignment: .center)
											.onDisappear {
												if callViewModel.displayedConversation != nil {
													indexPage = 2
													self.conversationViewModel.changeDisplayedChatRoom(conversationModel: callViewModel.displayedConversation!)
													callViewModel.displayedConversation = nil
													withAnimation {
														telecomManager.callDisplayed = false
													}
												}
											}
									}
								}
							}
							.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
							.frame(width: buttonSize, height: buttonSize)
							.background(Color.gray500)
							.cornerRadius(40)
							
							Text("call_action_show_messages")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						
						VStack {
							Button {
								callViewModel.togglePause()
							} label: {
								HStack {
									Image(callViewModel.isPaused ? "play" : "pause")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(telecomManager.isPausedByRemote ? Color.gray500 : .white)
										.frame(width: 32, height: 32)
								}
							}
							.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
							.frame(width: buttonSize, height: buttonSize)
							.background(telecomManager.isPausedByRemote ? .white : (callViewModel.isPaused ? Color.greenSuccess500 : Color.gray500))
							.cornerRadius(40)
							.disabled(telecomManager.isPausedByRemote)
							
							Text("call_action_pause_call")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									callViewModel.toggleRecording()
								} label: {
									HStack {
										Image("record-fill")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? .white : (callViewModel.isRecording ? Color.redDanger500 : Color.gray500))
								.cornerRadius(40)
								.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
								
								Text("call_action_record_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						} else {
							VStack {
								Button {
								} label: {
									HStack {
										Image("record-fill")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(Color.gray500)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(.white)
								.cornerRadius(40)
								.disabled(true)
								
								Text("call_action_record_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						}
						
						VStack {
							Button {
							} label: {
								HStack {
									Image("video-camera")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(.white)
										.frame(width: 32, height: 32)
								}
							}
							.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
							.frame(width: buttonSize, height: buttonSize)
							.background(Color.gray500)
							.cornerRadius(40)
							
							Text("call_action_change_layout")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.24, height: geo.size.width * 0.24)
						.hidden()
					}
					.frame(height: geo.size.height * 0.15)
				} else {
					HStack {
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									if callViewModel.callsCounter < 2 {
										withAnimation {
											callViewModel.isTransferInsteadCall = true
											MagicSearchSingleton.shared.searchForSuggestions()
											isShowStartCallFragment.toggle()
										}
										
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
											telecomManager.callStarted = false
											DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
												telecomManager.callStarted = true
											}
										}
									} else {
										callViewModel.transferClicked()
									}
								} label: {
									HStack {
										Image("phone-transfer")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text(callViewModel.callsCounter < 2 ? "call_action_blind_transfer" : "call_action_attended_transfer")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
							
							VStack {
								Button {
									withAnimation {
										MagicSearchSingleton.shared.searchForSuggestions()
										isShowStartCallFragment.toggle()
									}
									
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("phone-plus")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_start_new_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						} else {
							VStack {
								VStack {
									Button {
									} label: {
										HStack {
											Image("screencast")
												.renderingMode(.template)
												.resizable()
												.foregroundStyle(Color.gray500)
												.frame(width: 32, height: 32)
										}
									}
									.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
									.frame(width: buttonSize, height: buttonSize)
									.background(.white)
									.cornerRadius(40)
									.disabled(true)
									
									Text("conference_action_screen_sharing")
										.foregroundStyle(.white)
										.default_text_style(styleSize: 15)
								}
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
							
							VStack {
								Button {
									withAnimation {
										isShowParticipantsListFragment.toggle()
									}
								} label: {
									HStack {
										Image("users")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("conference_action_show_participants")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						}
						
						VStack {
							ZStack {
								Button {
									callViewModel.getCallsList()
									withAnimation {
										isShowCallsListFragment.toggle()
									}
									
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("phone-list")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								if callViewModel.callsCounter > 1 {
									VStack {
										HStack {
											Spacer()
											
											VStack {
												Text("\(callViewModel.callsCounter)")
													.foregroundStyle(.white)
													.default_text_style(styleSize: 15)
											}
											.frame(width: 20, height: 20)
											.background(Color.redDanger500)
											.cornerRadius(10)
										}
										
										Spacer()
									}
									.frame(width: buttonSize, height: buttonSize)
								}
							}
							
							Text("call_action_go_to_calls_list")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									showingDialer.toggle()
									DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
										telecomManager.callStarted = false
										DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
											telecomManager.callStarted = true
										}
									}
								} label: {
									HStack {
										Image("dialer")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_show_dialer")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						} else {
							VStack {
								Button {
									changeLayoutSheet = true
								} label: {
									HStack {
										Image("notebook")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(Color.gray500)
								.cornerRadius(40)
								
								Text("call_action_change_layout")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						}
						
						VStack {
							Button {
								callViewModel.createConversation()
							} label: {
								HStack {
									if !callViewModel.operationInProgress {
										Image("chat-teardrop-text")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(.white)
											.frame(width: 32, height: 32)
									} else {
										ProgressView()
											.controlSize(.mini)
											.progressViewStyle(CircularProgressViewStyle(tint: .white))
											.frame(width: 32, height: 32, alignment: .center)
											.onDisappear {
												if callViewModel.displayedConversation != nil {
													conversationViewModel.changeDisplayedChatRoom(conversationModel: callViewModel.displayedConversation!)
												}
											}
									}
								}
							}
							.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
							.frame(width: buttonSize, height: buttonSize)
							.background(Color.gray500)
							.cornerRadius(40)
							
							Text("call_action_show_messages")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						VStack {
							Button {
								callViewModel.togglePause()
							} label: {
								HStack {
									Image(callViewModel.isPaused ? "play" : "pause")
										.renderingMode(.template)
										.resizable()
										.foregroundStyle(telecomManager.isPausedByRemote ? Color.gray500 : .white)
										.frame(width: 32, height: 32)
								}
							}
							.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
							.frame(width: buttonSize, height: buttonSize)
							.background(telecomManager.isPausedByRemote ? .white : (callViewModel.isPaused ? Color.greenSuccess500 : Color.gray500))
							.cornerRadius(40)
							.disabled(telecomManager.isPausedByRemote)
							
							Text("call_action_pause_call")
								.foregroundStyle(.white)
								.default_text_style(styleSize: 15)
						}
						.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						
						if callViewModel.isOneOneCall {
							VStack {
								Button {
									callViewModel.toggleRecording()
								} label: {
									HStack {
										Image("record-fill")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle((callViewModel.isPaused || telecomManager.isPausedByRemote) ? Color.gray500 : .white)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background((callViewModel.isPaused || telecomManager.isPausedByRemote) ? .white : (callViewModel.isRecording ? Color.redDanger500 : Color.gray500))
								.cornerRadius(40)
								.disabled(callViewModel.isPaused || telecomManager.isPausedByRemote)
								
								Text("call_action_record_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						} else {
							VStack {
								Button {
								} label: {
									HStack {
										Image("record-fill")
											.renderingMode(.template)
											.resizable()
											.foregroundStyle(Color.gray500)
											.frame(width: 32, height: 32)
									}
								}
								.buttonStyle(PressedButtonStyle(buttonSize: buttonSize))
								.frame(width: buttonSize, height: buttonSize)
								.background(.white)
								.cornerRadius(40)
								.disabled(true)
								
								Text("call_action_record_call")
									.foregroundStyle(.white)
									.default_text_style(styleSize: 15)
							}
							.frame(width: geo.size.width * 0.125, height: geo.size.width * 0.125)
						}
					}
					.frame(height: geo.size.height * 0.15)
					.padding(.horizontal, 20)
					.padding(.top, 30)
				}
				
				Spacer()
			}
			.background(Color.gray600)
			.frame(maxHeight: .infinity, alignment: .top)
		}
	}
	
	func getAudioRouteImage() {
		if !AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue == "Speaker" }).isEmpty {
			imageAudioRoute = "speaker-high"
			optionsAudioRoute = 2
		} else if !AVAudioSession.sharedInstance().currentRoute.outputs.filter({ $0.portType.rawValue.contains("Bluetooth") }).isEmpty {
			imageAudioRoute = "bluetooth"
			optionsAudioRoute = 3
		} else {
			imageAudioRoute = callViewModel.isHeadPhoneAvailable() ? "headset" : "speaker-slash"
			optionsAudioRoute = 1
		}
	}
}

struct BottomSheetView<Content: View>: View {
	let content: Content
	
	@State var minHeight: CGFloat
	@State var maxHeight: CGFloat
	
	@Binding var currentOffset: CGFloat
	@Binding var pointingUp: CGFloat
	
	@State var bottomSafeArea: CGFloat
	
	var body: some View {
		GeometryReader { geometry in
			VStack(spacing: 0.0) {
				content
			}
			.frame(
				width: geometry.size.width,
				height: maxHeight,
				alignment: .top
			)
			.clipShape(
				Path(
					UIBezierPath(
						roundedRect: CGRect(x: 0.0, y: 0.0, width: geometry.size.width, height: maxHeight),
						byRoundingCorners: [.topLeft, .topRight],
						cornerRadii: CGSize(width: 16.0, height: 16.0)
					)
					.cgPath
				)
			)
			.frame(
				height: geometry.size.height,
				alignment: .bottom
			)
			.highPriorityGesture(
				DragGesture()
					.onChanged { value in
						currentOffset -= value.translation.height
						currentOffset = min(max(currentOffset, minHeight), maxHeight)
						pointingUp = -(((currentOffset - minHeight) / (maxHeight - minHeight)) - 0.5) * 2
					}
					.onEnded { _ in
						withAnimation {
							currentOffset = (currentOffset - minHeight <= maxHeight - currentOffset) ? minHeight : maxHeight
							pointingUp = -(((currentOffset - minHeight) / (maxHeight - minHeight)) - 0.5) * 2
						}
					}
			)
			.offset(y: maxHeight - currentOffset)
		}
	}
}

struct ChevronShape: Shape {
	var pointingUp: CGFloat
	
	var animatableData: CGFloat {
		get { return pointingUp }
		set { pointingUp = newValue }
	}
	
	func path(in rect: CGRect) -> Path {
		var path = Path()
		
		let width = rect.width
		let height = rect.height
		
		let horizontalCenter = width / 2
		let horizontalCenterOffset = width * 0.05
		let arrowTipStartingPoint = height - pointingUp * height * 0.9
		
		path.move(to: .init(x: 0, y: height))
		
		path.addLine(to: .init(x: horizontalCenter - horizontalCenterOffset, y: arrowTipStartingPoint))
		path.addQuadCurve(to: .init(x: horizontalCenter + horizontalCenterOffset, y: arrowTipStartingPoint), control: .init(x: horizontalCenter, y: height * (1 - pointingUp)))
		
		path.addLine(to: .init(x: width, y: height))

		return path
	}
}

struct PressedButtonStyle: ButtonStyle {
	var buttonSize: CGFloat
	func makeBody(configuration: Self.Configuration) -> some View {
		configuration.label
		.frame(width: buttonSize, height: buttonSize)
		.background(configuration.isPressed ? .white : .clear)
		.cornerRadius(40)
	}
}

#Preview {
	CallView(
		callViewModel: CallViewModel(),
		conversationViewModel: ConversationViewModel(),
		conversationsListViewModel: ConversationsListViewModel(),
		conversationForwardMessageViewModel: ConversationForwardMessageViewModel(),
		contactViewModel: ContactViewModel(),
		editContactViewModel: EditContactViewModel(),
		meetingViewModel: MeetingViewModel(),
		accountProfileViewModel: AccountProfileViewModel(),
		fullscreenVideo: .constant(false),
		isShowStartCallFragment: .constant(false),
		isShowConversationFragment: .constant(false),
		isShowStartCallGroupPopup: .constant(false),
		isShowEditContactFragment: .constant(false),
		indexPage: .constant(0),
		isShowScheduleMeetingFragment: .constant(false)
	)
}
// swiftlint:enable type_body_length
// swiftlint:enable line_length
// swiftlint:enable function_body_length
// swiftlint:enable file_length
