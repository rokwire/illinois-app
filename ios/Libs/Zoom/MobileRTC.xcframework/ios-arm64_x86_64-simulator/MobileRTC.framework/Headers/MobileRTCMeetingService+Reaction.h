//
//  MobileRTCMeetingService+Reaction.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2020/12/3.
//  Copyright © 2020 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>

NS_ASSUME_NONNULL_BEGIN


@interface MobileRTCMeetingService (Reaction)

/*!
 @brief Determine if the Reaction feature is enabled.
 @return YES means Reaction feature is enabled, otherwise not.
 */
- (BOOL)isEmojiReactionEnabled;

/*!
 @brief Send emoji reaction.
 @param type - The type of the emoji reaction.
 @param skinTone - The skintone of the emoji reaction
 @return If the function succeeds, it will return MobileRTCMeetError_Success, otherwise not.
 @deprecated replace with {@link sendEmojiReaction:}
 */
- (MobileRTCMeetError)sendEmojiReaction:(MobileRTCEmojiReactionType)type reactionSkinTone:(MobileRTCEmojiReactionSkinTone)skinTone  DEPRECATED_MSG_ATTRIBUTE("Use -sendEmojiReaction: instead");

/**
 * @brief Send emoji reaction.
 * @param type - The type of the emoji reaction.
 * @return If the function succeeds, it will return ZoomSDKError_succuss, otherwise not.
 * @warning MobileRTCEmojiReactionSkinTone doesn't work for MobileRTCEmojiReactionType_Heart type. To set MobileRTCEmojiReactionSkinTone, use -[MobileRTCMeetingSettings setReactionSkinTone] in MobileRTCMeetingSettings.h file
 */
- (MobileRTCMeetError)sendEmojiReaction:(MobileRTCEmojiReactionType)type;

@end

NS_ASSUME_NONNULL_END
