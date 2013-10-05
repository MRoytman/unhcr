//
//  HCRDataSource.m
//  UNHCR
//
//  Created by Sean Conrad on 10/1/13.
//  Copyright (c) 2013 Sean Conrad. All rights reserved.
//

#import "HCRDataSource.h"

////////////////////////////////////////////////////////////////////////////////

@interface HCRDataSource ()

@end

////////////////////////////////////////////////////////////////////////////////

@implementation HCRDataSource

+ (NSArray *)globalDataArray {
    
    return @[
             @{@"Category": @"Syria Emergency",
               @"Countries": @[
                       @{ @"Name": @"Iraq",
                          @"Latitude": @34,
                          @"Longitude": @44,
                          @"Span": @1750000,
                          @"Persons": @193631,
                          @"Funding": @0.36,
                          @"Camps": @[
                                  [HCRDataSource _domizData],
                                  @{@"Name": @"Erbil",
                                    @"Latitude": @36.1995815,
                                    @"Longitude": @44.0226888,
                                    @"Span": @20000,
                                    @"Persons": @67322},
                                  @{@"Name": @"Suleimaniya",
                                    @"Latitude": @35.5626992,
                                    @"Longitude": @45.4365392,
                                    @"Span": @20000,
                                    @"Persons": @19693}]},
                       @{ @"Name": @"Turkey",
                          @"Persons": @494361},
                       @{ @"Name": @"Lebanon",
                          @"Persons": @773281},
                       @{ @"Name": @"Jordan",
                          @"Persons": @525231},
                       @{ @"Name": @"Egypt",
                          @"Persons": @126727}
                       ]},
               
             @{@"Category": @"Horn of Africa",
               @"Countries": @[
                       @{ @"Name": @"Uganda",
                          @"Latitude": @1,
                          @"Longitude": @32,
                          @"Span": @1000000,
                          @"Persons": @18253,
                          @"Camps": @[
                                  @{@"Name": @"Nakivale",
                                    @"Latitude": @-0.6041135,
                                    @"Longitude": @30.6517214,
                                    @"Span": @10000,
                                    @"Persons": @18253}]},
                       @{ @"Name": @"Kenya",
                          @"Persons": @474602},
                       @{ @"Name": @"Ethiopia",
                          @"Persons": @245068},
                       @{ @"Name": @"Yemen",
                          @"Persons": @230855},
                       @{ @"Name": @"Djibouti",
                          @"Persons": @18725},
                       @{ @"Name": @"Egypt",
                          @"Persons": @7957},
                       @{ @"Name": @"Eritrea",
                          @"Persons": @3468},
                       @{ @"Name": @"Tanzania",
                          @"Persons": @2103}
                       ]},
             
             @{@"Category": @"Burmese Refugees",
               @"Countries": @[
                       @{ @"Name": @"Thailand",
                          @"Latitude": @15,
                          @"Longitude": @101.5,
                          @"Span": @1500000,
                          @"Persons": @140000,
                          @"Camps": @[
                                  @{@"Name": @"Umpiem Mai",
                                    @"Latitude": @16.6047072,
                                    @"Longitude": @98.6652615,
                                    @"Span": @20000,
                                    @"Persons": @17159}]}
                       ]}
             ];
             
}

+ (NSArray *)clusterImagesArray {
    
    // https://clusters.humanitarianresponse.info/sites/clusters.humanitarianresponse.info/files/clusterapproach.png
    // http://business.un.org/en/documents/249
    // http://www.unocha.org/what-we-do/coordination-tools/cluster-coordination
    
    return @[
             @{@"Name": @"Protection",
               @"Image": @"cluster-protection"},
             @{@"Name": @"Food Security",
               @"Image": @"cluster-food"},
             @{@"Name": @"Health",
               @"Image": @"cluster-health"},
             @{@"Name": @"Emergency Telecom",
               @"Image": @"cluster-telecoms"},
             @{@"Name": @"Camp Coordination",
               @"Image": @"cluster-coordination"},
             @{@"Name": @"Early Recovery",
               @"Image": @"cluster-recovery"},
             @{@"Name": @"Emergency Shelter",
               @"Image": @"cluster-shelter"},
             @{@"Name": @"Education",
               @"Image": @"cluster-education"},
             @{@"Name": @"Nutrition",
               @"Image": @"cluster-nutrition"},
             @{@"Name": @"Water/Sanitation",
               @"Image": @"cluster-water"},
             @{@"Name": @"Logistics",
               @"Image": @"cluster-logistics"}
             ];
}

+ (NSDictionary *)_domizData {
    
    // http://data.unhcr.org/
    
    return @{@"Name": @"Domiz",
             @"Latitude": @35.3923733,
             @"Longitude": @44.3757963,
             @"Span": @20000,
             @"Persons": @96272,
             @"Clusters": @{
                     @"Camp Coordination": @[
                             [HCRDataSource _ddmData],
                             [HCRDataSource _modmData],
                             [HCRDataSource _unhcrIraqData],
                             ]
                     }
             
             };
}

#pragma mark - Agencies

+ (NSDictionary *)_ddmData {
    return @{@"Agency": @"Directorate of Displacment and Migration",
             @"Abbr": @"DDM",
             @"About": @"Directorate of Displacment and Migration (DDM) mandate is concerned with providing basic needs of daily life, and make sure that the IDPs, Refugees, and Returnees, have access to all humanitarian needs.",
             @"Contact": @{@"Name": @"Mohammed M. Hamo",
                           @"Phone": @"7504502395",
                           @"Email": @"ddm.duhok@gmail.com"}};
}

+ (NSDictionary *)_modmData {
    return @{@"Agency": @"Minsitry of Migration and Displacment",
             @"Abbr": @"MODM",
             @"About": @"The Minsitry of Migration and Displacment (MODM) is the official government body in Iraq that deals with the IDPs, Returnees and Refugees since it's establishment in 2004.",
             @"Website": @"momd.gov.iq"};
}

+ (NSDictionary *)_unhcrIraqData {
    return @{@"Agency": @"United Nations High Commissioner For Refugees Iraq",
             @"Abbr": @"UNHCR Iraq"};
}

@end
