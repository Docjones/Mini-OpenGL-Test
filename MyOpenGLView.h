//
//  MyOpenGLView.h
//  Mini OpenGL Test
//
//  Created by Marc on 29.09.12.
//  Copyright (c) 2012 Marc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "TextureManager.h"

@interface MyOpenGLView : NSOpenGLView {

  TextureManager *_textureManager;
  GLuint i;
  NSTimer *aTimer;

}

@end
