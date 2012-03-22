/*
 * Copyright (C) 2011-2012 Josh A. Beam
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice, this list of conditions and the following disclaimer in the
 *      documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 * OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>
#import <OpenGL/gl3.h>

#define NUM_LIGHTS 3

@interface Scene : NSObject
{
	GLuint m_program;
	GLint m_programProjectionMatrixLocation;
	GLint m_programModelviewMatrixLocation;
	GLint m_programCameraPositionLocation;
	GLint m_programLightPositionLocation;
	GLint m_programLightColorLocation;
	GLint m_programVertexPositionLocation;
	GLint m_programVertexNormalLocation;
	GLint m_programFragmentColorLocation;

	GLuint m_vertexArrayId;
	GLuint m_cylinderBufferIds[2];
	unsigned int m_cylinderNumVertices;
	
	GLfloat m_cameraPosition[3];
	
	float m_lightPosition[NUM_LIGHTS * 3];
	float m_lightColor[NUM_LIGHTS * 3];
	float m_lightRotation;
}

- (void)sceneInit;
- (void)createCylinder:(unsigned int)divisions;
- (void)attachShaderToProgram:(GLuint)program withType:(GLenum)type fromFile:(NSString *)filePath;
- (void)render:(const float *)projectionMatrix;
- (void)cycle;

@end