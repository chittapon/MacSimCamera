//
//  MacSimCameraLoader.m
//  MacSimCamera
//
//  Created by Chittapon Thongchim on 25/12/2566 BE.
//

#import <Foundation/Foundation.h>
#import <MacSimCamera/MacSimCamera-Swift.h>

@implementation NSObject(MacSimCameraLoader)

+ (void)load {
    static MacSimCamera *singleton;
    singleton = MacSimCamera.instance;
    [singleton performSwizzle];
}

@end
