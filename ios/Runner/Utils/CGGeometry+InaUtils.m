//
//  CGGeometry+InaUtils.m
//  InaUtils
//
//  Created by mac mini on 2/17/10.
//  Copyright 2020 Board of Trustees of the University of Illinois.
    
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at

//    http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "CGGeometry+InaUtils.h"

CGSize InaSizeScaleToFit(CGSize size, CGSize boundsSize) {
	CGSize sizeFit = boundsSize;
	float fltW = (0.0f < boundsSize.width) ? (size.width / boundsSize.width) : FLT_MAX;
	float fltH = (0.0f < boundsSize.height) ? (size.height / boundsSize.height) : FLT_MAX;
	if(fltW < fltH)
		sizeFit.width = (0.0f < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
	else if(fltH < fltW)
		sizeFit.height = (0.0f < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
	return sizeFit;
}

CGSize InaSizeScaleToFill(CGSize size, CGSize boundsSize) {
	CGSize sizeFit = boundsSize;
	float fltW = (0.0f < boundsSize.width) ? (size.width / boundsSize.width) : FLT_MAX;
	float fltH = (0.0f < boundsSize.height) ? (size.height / boundsSize.height) : FLT_MAX;
	if(fltW < fltH)
		sizeFit.height = (0.0f < size.width) ? (size.height * boundsSize.width / size.width) : boundsSize.height;
	else if(fltH < fltW)
		sizeFit.width = (0.0f < size.height) ? (size.width * boundsSize.height / size.height) : boundsSize.width;
	return sizeFit;
}

CGSize InaSizeShrinkToFit(CGSize size, CGSize boundsSize) {
	// scale size only if exceeds bound size
	return ((boundsSize.width < size.width) || (boundsSize.height < size.height)) ? InaSizeScaleToFit(size, boundsSize) : size;
}

