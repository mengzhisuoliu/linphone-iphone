/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
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
import UniformTypeIdentifiers

struct ContactListBottomSheet: View {
	
	private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
	
	@ObservedObject private var sharedMainViewModel = SharedMainViewModel.shared
	
	@ObservedObject var contactViewModel: ContactViewModel
	
	@State private var orientation = UIDevice.current.orientation
	
	@Environment(\.dismiss) var dismiss
	
	@Binding var showingSheet: Bool
	
	var body: some View {
		VStack(alignment: .leading) {
			if idiom != .pad && (orientation == .landscapeLeft
				|| orientation == .landscapeRight
				|| UIScreen.main.bounds.size.width > UIScreen.main.bounds.size.height) {
				Spacer()
				HStack {
					Spacer()
					Button("dialog_close") {
						if #available(iOS 16.0, *) {
							showingSheet.toggle()
						} else {
							showingSheet.toggle()
							dismiss()
						}
					}
				}
				.padding(.trailing)
			}
			
			Spacer()
			Button {
				UIPasteboard.general.setValue(
					contactViewModel.stringToCopy.prefix(4) == "sip:"
					? contactViewModel.stringToCopy.dropFirst(4)
					: contactViewModel.stringToCopy,
							forPasteboardType: UTType.plainText.identifier)
				
				if #available(iOS 16.0, *) {
					showingSheet.toggle()
				} else {
					showingSheet.toggle()
					dismiss()
				}
				
				ToastViewModel.shared.toastMessage = "Success_address_copied_into_clipboard"
				ToastViewModel.shared.displayToast.toggle()
				
			} label: {
				HStack {
					Image("copy")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(Color.grayMain2c500)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
					Text(contactViewModel.stringToCopy.prefix(4) == "sip:"
						 ? "menu_copy_sip_address" : "menu_copy_phone_number")
					.default_text_style(styleSize: 16)
					Spacer()
				}
				.frame(maxHeight: .infinity)
			}
			.padding(.horizontal, 30)
			.background(Color.gray100)
			
			VStack {
				Divider()
			}
			.frame(maxWidth: .infinity)
			
			if contactViewModel.stringToCopy.prefix(4) != "sip:" {
				Button {
					if #available(iOS 16.0, *) {
						if idiom != .pad {
							showingSheet.toggle()
						} else {
							showingSheet.toggle()
							dismiss()
						}
					} else {
						showingSheet.toggle()
						dismiss()
					}
				} label: {
					HStack {
						Image("envelope-simple-open")
							.renderingMode(.template)
							.resizable()
							.foregroundStyle(Color.grayMain2c500)
							.frame(width: 25, height: 25, alignment: .leading)
							.padding(.all, 10)
						Text("menu_invite")
							.default_text_style(styleSize: 16)
						Spacer()
					}
					.frame(maxHeight: .infinity)
				}
				.padding(.horizontal, 30)
				.background(Color.gray100)
				
				VStack {
					Divider()
				}
				.frame(maxWidth: .infinity)
			}
			
			Button {
				if #available(iOS 16.0, *) {
					showingSheet.toggle()
				} else {
					showingSheet.toggle()
					dismiss()
				}
			} label: {
				HStack {
					Image("x-circle")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(Color.grayMain2c500)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
					Text(contactViewModel.stringToCopy.prefix(4) == "sip:"
						 ? "menu_block_address" : "menu_block_number")
						.default_text_style(styleSize: 16)
					Spacer()
				}
				.frame(maxHeight: .infinity)
			}
			.padding(.horizontal, 30)
			.background(Color.gray100)
			
		}
		.onRotate { newOrientation in
			orientation = newOrientation
		}
		.background(Color.gray100)
		.frame(maxWidth: .infinity)
	}
}

#Preview {
	ContactListBottomSheet(contactViewModel: ContactViewModel(), showingSheet: .constant(false))
}
