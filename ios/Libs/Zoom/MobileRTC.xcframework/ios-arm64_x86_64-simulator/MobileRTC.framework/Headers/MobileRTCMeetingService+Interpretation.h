//
//  MobileRTCMeetingService+Interpretation.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2020/10/15.
//  Copyright © 2020 Zoom Video Communications, Inc. All rights reserved.
//


#import <MobileRTC/MobileRTC.h>

/*!
@brief The information of interpretation language.
*/
@interface MobileRTCInterpretationLanguage : NSObject
- (NSInteger)getLanguageID;
- (NSString * _Nullable)getLanguageAbbreviations;
- (NSString * _Nullable)getLanguageName;
@end

/*!
@brief The information of interpreter.
*/
@interface MobileRTCMeetingInterpreter : NSObject
- (NSInteger)getUserID;
- (NSInteger)getLanguageID1;
- (NSInteger)getLanguageID2;
- (BOOL)isAvailable;

@end

@interface MobileRTCMeetingService (Interpretation)

//Common (for all)

/*!
 @brief Determine if interpretation feature is enabled in the meeting.
*/
- (BOOL)isInterpretationEnabled;

/*!
 @brief Determine if interpretation has been started by host.
*/
- (BOOL)isInterpretationStarted;

/*!
 @brief Determine if myself is interpreter.
*/
- (BOOL)isInterpreter;

/*!
 @brief Get the interpretation language object of specified language ID.
 @param lanID Specify the language ID for which you want to get the information.
 @return If the function succeeds, the return value is a pointer to the MobileRTCInterpretationLanguage, Otherwise failed, the return value is nil.
*/
- (MobileRTCInterpretationLanguage * _Nullable)getInterpretationLanguageByID:(NSInteger)lanID;

//Admin (only for host)

/*!
 @brief Get the all interpretation language list.
 @return If the function succeeds, the return value is a pointer to the NSArray <MobileRTCInterpretationLanguage *>, Otherwise failed, the return value is nil.
*/
- (NSArray <MobileRTCInterpretationLanguage *> * _Nullable)getAllLanguageList;

/*!
 @brief Get the interpreters list.
 @return If the function succeeds, the return value is a pointer to the NSArray <MobileRTCMeetingInterpreter *>, Otherwise failed, the return value is nil.
*/
- (NSArray <MobileRTCMeetingInterpreter *> * _Nullable)getInterpreterList;

/*!
 @brief Add someone as a interpreter.
 @param userID Specify the user.
 @param lanID1 Specify the language1.
 @param lanID2 Specify the language2.
 @return The result of the function.
*/
- (BOOL)addInterpreter:(NSUInteger)userID lan1:(NSInteger)lanID1 andLan2:(NSInteger)lanID2;

/*!
 @brief Remove some interpreter.
 @param userID Specify the interpreter.
 @return The result of the function.
*/
- (BOOL)removeInterpreter:(NSUInteger)userID;

/*!
 @brief modify the language of some interpreter.
 @param userID Specify the interpreter.
 @param lanID1 Specify the new language1.
 @param lanID2 Specify the new language2.
 @return The result of the function.
*/
- (BOOL)modifyInterpreter:(NSUInteger)userID lan1:(NSInteger)lanID1 andLan2:(NSInteger)lanID2;

/*!
 @brief Start interpretation.
 @return The result of the function.
*/
- (BOOL)startInterpretation;

/*!
 @brief Stop interpretation.
 @return The result of the function.
*/
- (BOOL)stopInterpretation;

//Listener (for non interpreter)

/*!
 @brief Get the available interpretation language list.
 @return If the function succeeds, the return value is a pointer to the NSArray <MobileRTCInterpretationLanguage *>, Otherwise failed, the return value is nil.
*/
- (NSArray <MobileRTCInterpretationLanguage *> * _Nullable)getAvailableLanguageList;

/*!
 @brief Join some language channel.
 @param lanID Specify the language channel.
 @return The result of the function.
*/
- (BOOL)joinLanguageChannel:(NSInteger)lanID;

/*!
 @brief Get the language ID which myself is in.
 @return The LanguageID.
*/
- (NSInteger)getJoinedLanguageID;

/*!
 @brief Turn off the major audio, if you are in some interpreter language channel.
 @return The result of the function.
*/
- (BOOL)turnOffMajorAudio;

/*!
 @brief Turn on the major audio, if you are in some interpreter language channel.
 @return The result of the function.
*/
- (BOOL)turnOnMajorAudio;

/*!
 @brief Determine if the major audio is off.
 @return The result of the function.
*/
- (BOOL)isMajorAudioTurnOff;

//interpreter (only for interpreter)

/*!
 @brief Get languages if myself is a interpreter.
 @return If the function succeeds, the return value is a pointer to the NSArray NSArray <MobileRTCInterpretationLanguage *>, Otherwise failed, the return value is nil.
*/
- (NSArray <MobileRTCInterpretationLanguage *> * _Nullable)getInterpreterLans;

/*!
 @brief Set a language channel which myself will be in, if myself is a interpreter.
 @param activeLanID Specify the active language.
 @return The result of the function.
*/
- (BOOL)setInterpreterActiveLan:(NSInteger)activeLanID;

/*!
 @brief Get the active language ID, if myself is a interpreter.
 @return The Active LanguageID..
*/
- (NSInteger)getInterpreterActiveLan;

/*!
 @brief Get the list of available languages that interpreters can hear.
 @return If the function succeeds, the return value is a pointer to the NSArray NSArray <MobileRTCInterpretationLanguage *>, Otherwise failed, the return value is nil.
*/
- (NSArray <MobileRTCInterpretationLanguage *> * _Nullable)getInterpreterAvailableLanguages;

/*!
 @brief Set a language that I can hear as an interpreter.
 @param lanID Specify the selected language that I can hear as an interpreter.
 @return The result of the function.
*/
- (BOOL)setInterpreterListenLan:(NSInteger)lanID;

/*!
 @brief Get a language that I can hear as an interpreter.
 @return Specify the selected language that I can hear as an interpreter.Otherwise failed, the return value is -1.
*/
- (NSInteger)getInterpreterListenLan;

@end

#pragma mark  MobileRTCSignInterpreter

@interface  MobileRTCSignInterpreterLanguage : NSObject

/**
 @brief Get sign language id.
 */
@property (copy, nonatomic, nullable) NSString *  languageName;
/**
 @brief Get sign language name.
 */
@property (copy, nonatomic, nullable) NSString *  languageID;

@end

@interface  MobileRTCSignInterpreter : NSObject
/**
 @brief Get the user ID.
 */
@property (assign, nonatomic)           NSUInteger userID;
/**
 @brief Determine if the sign interpreter is available.
 */
@property (assign, nonatomic)           BOOL available;
/**
 @brief Get sign user name.
 */
@property (copy, nonatomic, nullable)    NSString *  userName;
/**
 @brief Get sign email.
 */
@property (copy, nonatomic, nullable)    NSString *  email;
/**
 @brief Get sign language name.
 */
@property (copy, nonatomic, nullable)    NSString *  languageName;
/**
 @brief Get the language id of the sign interpreter support.
 */
@property (copy, nonatomic, nullable)    NSString *  languageID;

@end


@interface MobileRTCMeetingService (SignInterpreter)

/**
 @brief Determine if the sign interpretation function is enabled.
 @return YES means sign interpretation function is enable,otherwise not.
 */
- (BOOL)isSignInterpretationEnabled;

/**
 @brief Get sign interpretation status of current meeting.
 @return If the function succeeds, the return value is the sign interpretation status of current meeting.For more details, see {@link MobileRTCSignInterpretationStatus}.
 */
- (MobileRTCSignInterpretationStatus)getSignInterpretationStatus;

/**
 @brief Determine if self is sign interpreter.
 @return YES means self is sign interpreter,otherwise not.
 */
- (BOOL)isSignInterpreter;

/**
 @brief Get the sign interpretation language object of specified sign language ID.
 @param signLanguageID Specify the sign language ID for which you want to get the information.
 @return If the function succeeds, the return value is MobileRTCSignInterpreterLanguage object.
 */
- (MobileRTCSignInterpreterLanguage *_Nullable)getSignInterpretationLanguageInfoByID:(NSString *_Nullable)signLanguageID;

/**
 @brief Get the available sign interpretation language list.
 @return If the function succeeds, the return array contain available language object.
 */
- (NSArray<MobileRTCSignInterpreterLanguage *> *_Nullable)getAvailableSignLanguageInfoList;

/**
 @brief Get the all supported sign interpretation language list.only for host.
 @return If the function succeeds, the return array contain support language object.
 @warning the interface for host only.
 */
- (NSArray<MobileRTCSignInterpreterLanguage *> *_Nullable)getAllSupportedSignLanguageInfoList;

/**
 @brief Get the sign interpreters list.
 @return If the function succeeds, the return array contain sign interpreter object.
 */
- (NSArray<MobileRTCSignInterpreter *> *_Nullable)getSignInterpreterList;

/**
 @brief Add someone as a sign interpreter.
 @param userID The unique identity of the user.
 @param signLanID The id of sign language.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 @warning the interface for host only.
 */
- (MobileRTCSDKError)addSignInterpreter:(NSUInteger)userID signLanId:(NSString *_Nullable)signLanID;

/**
 @brief Remove interpreter.
 @param userID The unique identity of the user.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 @warning the interface for host only.
 */
- (MobileRTCSDKError)removeSignInterpreter:(NSUInteger)userID;

/**
 @brief Modify the language of some sign interpreter.
 @param userID The unique identity of the user.
 @param signLanID The id of sign language.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 @warning the interface for host only.
 */
- (MobileRTCSDKError)modifySignInterpreter:(NSUInteger)userID signLanId:(NSString *_Nullable)signLanID;

/**
 @brief Determine if I can start the sign interpretation in the meeting.
 @warning the interface for host only.
 */
- (BOOL)canStartSignInterpretation;

/**
 @brief Start sign interpretation.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 @warning the interface for host only.
 */
- (MobileRTCSDKError)startSignInterpretation;

/**
 @brief Stop sign interppretation.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 @warning the interface for host only.
 */
- (MobileRTCSDKError)stopSignInterpretation;

/**
 @brief Host allow sign language interpreter to talk.
 @param userID The unique identity of the user.
 @param allowToTalk YES indicates to allow to talk, otherwise not.
 @return If the function succeeds, it will return MobileRTCSDKError_Success, otherwise not.
 */
- (MobileRTCSDKError)requestSignLanuageInterpreterToTalk:(NSUInteger)userID allowToTalk:(BOOL)allowToTalk;

/**
 @brief Determine if the sign language interpreter be allowed to talk.
 @param userID The unique identity of the user.
 @return YES indicates to allow to talk, otherwise not.
 */
- (BOOL)isAllowSignLanuageInterpreterToTalk:(NSUInteger)userID;

/**
 @brief Get sign language id if myself is a sign interpreter.only for interpreter.
 @return If the function succeeds, the return value is the current assigned sign language id, otherwise not.
 */
- (NSString *_Nullable)getSignInterpreterAssignedLanID;

/**
 @brief Join some sign language channel if myself is not a sign interpreter.only for non-interpreter.
 @return If the function succeeds, it will return MobileRTCSDKError_succuss, otherwise not.
 @warning the inferface only for ZOOM UI
 */
- (MobileRTCSDKError)joinSignLanguageChannel:(NSString *_Nullable)signLanID;

/**
 @brief Leave current sign language channel if myself is not a sign interpreter.only for non-interpreter.
 @return If the function succeeds, it will return MobileRTCSDKError_succuss, otherwise not.
 @warning the inferface only for ZOOM UI
 */
- (MobileRTCSDKError)leaveSignLanguageChannel;
@end

