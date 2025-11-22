//
//  MessageBubbleView.swift
//  VisualChat
//
//  Created by Srinivasa Chaitanya Gopireddy on 11/22/25.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: ChatMessage
#if os(iOS)
    let incomingBubbleColor = Color(.secondarySystemBackground)
#else
    let incomingBubbleColor = Color(NSColor.windowBackgroundColor)
#endif

    var body: some View {
        HStack {
            if message.isFromUser {
                Spacer()
                bubble
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(Color.accentColor))
                    .foregroundStyle(.white)
            } else {
                bubble
                    .background(RoundedRectangle(cornerRadius: 16)
                        .fill(incomingBubbleColor))
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
    }

    private var bubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(message.text)
                .padding(10)

            Text(message.createdAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 10)
                .padding(.bottom, 6)
        }
    }
}
