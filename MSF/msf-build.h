//
//  msf-build.h
//  UNHCR
//
//  Created by Sean Conrad on 1/2/14.
//  Copyright (c) 2014 Sean Conrad. All rights reserved.
//

#ifndef UNHCR_msf_build_h
#define UNHCR_msf_build_h

#define TARGET_MSF

#include "HCRDataManager.h"

#ifdef DEBUG

//#define HCR_WIPE_NSUD

#endif



#define PRODUCTION

#ifndef PRODUCTION
#warning NOT USING PRODUCTION SETTINGS
#endif

#endif
