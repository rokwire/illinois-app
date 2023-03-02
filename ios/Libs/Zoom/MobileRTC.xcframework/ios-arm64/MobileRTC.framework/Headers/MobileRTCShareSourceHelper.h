//
//  MobileRTCShareSourceHelper.h
//  MobileRTC
//
//  Created by Zoom on 2022/6/30.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MobileRTCShareSourceHelper : NSObject

/*!
@brief This method is used to send your own share rawdata.
@param delegate please See MobileRTCShareSourceDelegate.
@warning Set nil for Switch to internal video source.
*/
-(MobileRTCRawDataError)setExternalShareSource:(id<MobileRTCShareSourceDelegate>)delegate;

@end

