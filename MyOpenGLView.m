//
//  MyOpenGLView.m
//  Mini OpenGL Test
//
//  Created by Marc on 29.09.12.
//  Copyright (c) 2012 Marc. All rights reserved.
//

#import "MyOpenGLView.h"
#import <OpenGL/OpenGL.h>

@implementation MyOpenGLView

-(void)awakeFromNib {
  _textureManager=[TextureManager sharedManager];
}

- (void) reshape {
  NSRect rect=[self bounds];
  glViewport(0, 0, (GLsizei) rect.size.width , (GLsizei) rect.size.height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(0, rect.size.width, rect.size.height, 0,-1,1); // heigth + zero exchanged (turn upside down)
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
}

- (void) prepareOpenGL {
  [[self window] makeFirstResponder:self];
  NSRect rect=[self bounds];
  
  glViewport(0, 0, (GLsizei) rect.size.width , (GLsizei) rect.size.height);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  
  glOrtho(0, rect.size.width, rect.size.height, 0,-1,1); // heigth + zero exchanged (turn upside down)
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  
  glEnable(GL_TEXTURE_2D);

  // activate pointer to vertex & texture array
  glEnableClientState(GL_VERTEX_ARRAY);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);

  glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
  glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
  
	
  aTimer=[[NSTimer timerWithTimeInterval:1.0f/30.0f target:self selector:@selector(animationTrigger:) userInfo:self repeats:YES] retain];
  [[NSRunLoop currentRunLoop] addTimer:aTimer forMode:NSDefaultRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:aTimer forMode:NSEventTrackingRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer:aTimer forMode:NSDefaultRunLoopMode];
  
}

-(void)animationTrigger:(NSTimer*)timer {
  [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
  static GLint t[8];
  static GLint v[8];
  GLuint b;

  glClear(GL_COLOR_BUFFER_BIT);

  b=[_textureManager textureByName:@"blocks" needsAlpha:YES];
  // NSLog(@"Texture ID %d loaded",b);
  glBindTexture(GL_TEXTURE_2D,b);
  glEnable(GL_DEPTH_TEST);
  glDisable(GL_BLEND);
  
  [_textureManager getBlockWithNumber:3 forTextureArray:t];
  for (int y=0; y<16; y++) {
    for (int x=0; x<32; x++) {
      [_textureManager getTileX:x Y:y forVertexArray:v];
      glTexCoordPointer(2, GL_INT, 0, t);
      glVertexPointer(2, GL_INT, 0, v);
      glDrawArrays(GL_QUADS, 0, 4);
    }
  }
  
  // b=[_textureManager textureByName:@"c003" needsAlpha:YES];
  // NSLog(@"Texture ID %d loaded",b);
  glBindTexture(GL_TEXTURE_2D,b);	
  glDisable(GL_DEPTH_TEST);
  glEnable(GL_BLEND);

  [_textureManager getBlockWithNumber:1 forTextureArray	:t];
  [_textureManager getTileX:4 Y:4 forVertexArray:v];
  glTexCoordPointer(2, GL_INT, 0, t);
  glVertexPointer(2, GL_INT, 0, v);	
  glDrawArrays(GL_QUADS, 0, 4);
//
  glFlush();
}
@end
