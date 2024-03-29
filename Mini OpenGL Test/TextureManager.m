//
//  TextureManager.h
//  opengl-test
//
//  Created by Marc Rink on 28.02.12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TextureManager.h"
#import "TextureObject.h"
#import <OpenGL/glu.h>

#define SCALE 2

#define TILE_WIDTH  16
#define TILE_HEIGTH 16	

@implementation TextureManager

+ (TextureManager*)sharedManager {
  static TextureManager* magTextureManager = nil;
  
  if( !magTextureManager ) {
    magTextureManager = [[TextureManager alloc] init];
  }
  
  return magTextureManager;
}

-(id)init {
	self = [super init];
	if(self) {
		_textures = [[NSMutableArray alloc]init];
		return self;
	}
	return nil;
}

-(void)cleanUp
{
  // Texture suchen
  for (id e in _textures) {
    GLuint tmp = [e textureID];
    glDeleteTextures(1, &tmp);
  }
    
	[_textures removeAllObjects];
	[_textures release];	
}

-(void)dealloc {
  [self cleanUp];
  [super dealloc];
}

- (GLuint) textureByName:(NSString *)textureName {
  return [self textureByName:textureName needsAlpha:NO];
}

- (GLuint) textureByName:(NSString *)textureName needsAlpha:(BOOL)needsAlpha {

  // Texture suchen
  for (id e in _textures) {
    if([[e textureName] isEqualToString:textureName]) {
      _currentTextureObject=e;
      return [_currentTextureObject textureID];
    }
  }
  // nicht gefunden -> laden und einfuegen
  // Load the texture .png from the bundle file and get the Bitmap representativ off of it
  NSString* imageName = [[NSBundle mainBundle] pathForResource:textureName ofType:@"png"];
  NSImage *blocks = [[NSImage alloc ]initWithContentsOfFile:imageName];
  NSRect sz= NSMakeRect(0,0,[blocks size].width, [blocks size].height);
  NSBitmapImageRep *result=[[NSBitmapImageRep alloc] initWithCGImage:[blocks CGImageForProposedRect:&sz
                                                                                            context:NULL
                                                                                              hints:NULL]];
  [blocks release];
  
  // Check if ALPHA exists or has to be added
  int samplesPerPixel = (int) [result samplesPerPixel] ;
  int pixelsWide = (int) [result pixelsWide];
  int pixelsHigh = (int) [result pixelsHigh];
  int bytesPerRow = (int) [result bytesPerRow];

  NSLog(@"Asset loaded: %@, sPP:%d, w:%d, h:%d, bpR:%d",textureName,samplesPerPixel,pixelsWide,pixelsHigh,bytesPerRow);
  void * myData=NULL;
  if (needsAlpha==YES)  {
    NSLog(@"Adding ALPHA Channel...");
    
    samplesPerPixel=4;
    bytesPerRow=pixelsWide*samplesPerPixel;
    // Setup Rendering area
    CGRect rect = {{0, 0}, {pixelsWide, pixelsHigh}};
    myData = calloc(pixelsWide * samplesPerPixel, pixelsHigh);
    
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef myBitmapContext = CGBitmapContextCreate (myData,
                                                          pixelsWide, pixelsHigh, 8,
                                                          bytesPerRow, space,
                                                          kCGImageAlphaPremultipliedLast |
                                                          kCGBitmapByteOrder32Big	);
    
    CGContextSetBlendMode(myBitmapContext, kCGBlendModeCopy);
    CGContextDrawImage(myBitmapContext, rect, [result CGImage]);
    
    // calculating ALPHA Channel based on RGB (0,0,0)
    char *ptr=myData;
    for (int i=0; i<pixelsWide * samplesPerPixel * pixelsHigh; i+=4,ptr+=4) {
      ptr[3]=((ptr[0]+ptr[1]+ptr[2])==0)?0:255;
    }
    
//    CGImageRef cImage = CGBitmapContextCreateImage(myBitmapContext);
//    
//    CFURLRef url = (CFURLRef)[NSURL fileURLWithPath:@"/Users/marc/Desktop/Alpha-image.png"];
//    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypePNG, 1, NULL);
//    CGImageDestinationAddImage(destination, cImage, nil);
//      
//    if (!CGImageDestinationFinalize(destination)) {
//      NSLog(@"Failed to write image");
//    }
//      
//    CFRelease(destination);
 
    CGContextRelease(myBitmapContext);	
    CGColorSpaceRelease(space);
  }
  glPushMatrix();
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  // glPixelStorei(GL_UNPACK_ROW_LENGTH, (int)bytesPerRow/(int)samplesPerPixel);
  // glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
  

  glMatrixMode(GL_TEXTURE);
  glLoadIdentity();
  glScalef(1.0f/(float)pixelsWide,
           1.0f/(float)pixelsHigh, 1.0f); // scaling the texture to get pixel coordinates
  
  GLenum glType=(samplesPerPixel==4)?GL_RGBA:GL_RGB;
  GLenum glFormat=GL_UNSIGNED_BYTE;

  NSLog(@"Binding Asset: %@, sPP:%d, w:%d, h:%d, bpR:%d, glType:%d, glFormat:%d",textureName,samplesPerPixel,pixelsWide,pixelsHigh,bytesPerRow,glType,glFormat);

  GLuint tmpTexture;
  glGenTextures (1, &tmpTexture);

  NSLog(@"Bound Asset with ID %d",tmpTexture);
  
  glBindTexture(GL_TEXTURE_2D, tmpTexture); 
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER, GL_NEAREST); // Blurry mode OFF
  glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER, GL_NEAREST); // Blurry mode OFF
  
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);   // Clamped to 0.0 or 1.0
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
  
  glTexImage2D(GL_TEXTURE_2D,0,
               GL_RGBA,
               pixelsWide,
               pixelsHigh,
               0,
               glType,
               glFormat,
               (samplesPerPixel==4)?myData:[result bitmapData]);
	if (myData!=NULL) {
    free(myData);
  }
	//Neues Textureobjekt erzeugen
	TextureObject *t = [[TextureObject alloc]init];
	[t setTextureID:tmpTexture];
	[t setTextureName:textureName];
  [t setWidth:pixelsWide];
  [t setHeight:pixelsHigh];
	[_textures addObject:t];
	_currentTextureObject=t;

  [result release];
	[t release];
  
  glPopMatrix();
  
	return tmpTexture;	
}

- (void)getTileX:(int)x Y:(int)y forVertexArray:(GLint*)v {
  v[0]=TILE_WIDTH*SCALE*x;     v[1]=TILE_HEIGTH*SCALE*y;
  v[2]=TILE_WIDTH*SCALE*(x+1); v[3]=TILE_HEIGTH*SCALE*y;
  v[4]=TILE_WIDTH*SCALE*(x+1); v[5]=TILE_HEIGTH*SCALE*(y+1);
  v[6]=TILE_WIDTH*SCALE*x;     v[7]=TILE_HEIGTH*SCALE*(y+1);
}


- (void)getBlockWithNumber:(int)b forTextureArray:(GLint*)t {
  
  int x=b%([_currentTextureObject width]/(TILE_WIDTH));
  int y=b/([_currentTextureObject width]/(TILE_WIDTH));
  
  t[0]=(TILE_WIDTH)*x;     t[1]=(TILE_HEIGTH)*y;
  t[2]=(TILE_WIDTH)*(x+1); t[3]=(TILE_HEIGTH)*y;
  t[4]=(TILE_WIDTH)*(x+1); t[5]=(TILE_HEIGTH)*(y+1);
  t[6]=(TILE_WIDTH)*x;     t[7]=(TILE_HEIGTH)*(y+1);
}

- (TextureObject*)textureObjectByID:(GLuint)textureID	{
	NSEnumerator *enumerator = [_textures objectEnumerator];
	TextureObject *element;
	while(element = [enumerator nextObject]) {
		if([element textureID] == textureID) {
			return element;
		}
  }
	return nil;
}

- (void)unloadTexture:(GLuint)textureID {
	NSEnumerator *enumerator = [_textures objectEnumerator];
	TextureObject *element;
	while(element = [enumerator nextObject]) {
		GLuint texID = [element textureID];
		if(texID == textureID) {
			GLuint tmpTexture = [element textureID];
			glDeleteTextures(1, &tmpTexture);
			[_textures removeObject:element];			
			return;
		}
  }
}

@end
