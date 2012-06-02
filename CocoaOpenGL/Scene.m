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

#include <math.h>
#include <sys/time.h>
#import "Scene.h"

/* shader functions defined in shader.c */
extern void shaderAttachFromFile(GLuint, GLenum, const char *);

@interface Scene()
{
	Texture *_normalmap;

	GLuint _program;
	GLint _programProjectionMatrixLocation;
	GLint _programModelviewMatrixLocation;
	GLint _programCameraPositionLocation;
	GLint _programLightPositionLocation;
	GLint _programLightColorLocation;
	GLint _programVertexPositionLocation;
	GLint _programVertexTexCoordsLocation;
	GLint _programVertexTangentLocation;
	GLint _programVertexBitangentLocation;
	GLint _programVertexNormalLocation;
	GLint _programFragmentColorLocation;

	GLuint _vertexArrayId;
	GLuint _cylinderBufferIds[5];
	unsigned int _cylinderNumVertices;

	GLfloat _cameraPosition[3];
	
	float _lightPosition[NUM_LIGHTS * 3];
	float _lightColor[NUM_LIGHTS * 3];
	float _lightRotation;
}

@end

@implementation Scene

- (id)init
{
    self = [super init];
    if (self) {
		[self sceneInit];
    }
    
    return self;
}

- (void)dealloc
{
	glDeleteProgram(_program);
	glDeleteBuffers(5, _cylinderBufferIds);
	glDeleteVertexArrays(1, &_vertexArrayId);
	[_normalmap release];
	[super dealloc];
}

- (void)sceneInit
{
	GLint result;
	
	/* load normalmap texture */
	_normalmap = [[Texture alloc] initFromFile:@"normalmap.png"];

	/* create program object and attach shaders */
	_program = glCreateProgram();
	[self attachShaderToProgram:_program withType:GL_VERTEX_SHADER fromFile:@"shader.vp"];
	[self attachShaderToProgram:_program withType:GL_FRAGMENT_SHADER fromFile:@"shader.fp"];

	/* link the program and make sure that there were no errors */
	glLinkProgram(_program);
	glGetProgramiv(_program, GL_LINK_STATUS, &result);
	if(result == GL_FALSE) {
		GLint length;
		char *log;

		/* get the program info log */
		glGetProgramiv(_program, GL_INFO_LOG_LENGTH, &length);
		log = malloc(length);
		glGetProgramInfoLog(_program, length, &result, log);

		/* print an error message and the info log */
		fprintf(stderr, "sceneInit(): Program linking failed: %s\n", log);
		free(log);

		/* delete the program */
		glDeleteProgram(_program);
		_program = 0;
	}

	/* get uniform locations */
	_programProjectionMatrixLocation = glGetUniformLocation(_program, "projectionMatrix");
	_programModelviewMatrixLocation = glGetUniformLocation(_program, "modelviewMatrix");
	_programCameraPositionLocation = glGetUniformLocation(_program, "cameraPosition");
	_programLightPositionLocation = glGetUniformLocation(_program, "lightPosition");
	_programLightColorLocation = glGetUniformLocation(_program, "lightColor");

	/* get attribute locations */
	_programVertexPositionLocation = glGetAttribLocation(_program, "vertexPosition");
	_programVertexTexCoordsLocation = glGetAttribLocation(_program, "vertexTexCoords");
	_programVertexTangentLocation = glGetAttribLocation(_program, "vertexTangent");
	_programVertexBitangentLocation = glGetAttribLocation(_program, "vertexBitangent");
	_programVertexNormalLocation = glGetAttribLocation(_program, "vertexNormal");

	/* set up red/green/blue lights */
	_lightColor[0] = 1.0f; _lightColor[1] = 0.0f; _lightColor[2] = 0.0f;
	_lightColor[3] = 0.0f; _lightColor[4] = 1.0f; _lightColor[5] = 0.0f;
	_lightColor[6] = 0.0f; _lightColor[7] = 0.0f; _lightColor[8] = 1.0f;

	/* create cylinder */
	[self createCylinder:36];

	/* do the first cycle to initialize positions */
	_lightRotation = 0.0f;
	[self cycle];

	/* setup camera */
	_cameraPosition[0] = 0.0f;
	_cameraPosition[1] = 0.0f;
	_cameraPosition[2] = 4.0f;
}

- (void)createCylinder:(unsigned int)divisions
{
	unsigned int i, size, tcSize;
	float *p, *tc, *t, *b, *n;

	_cylinderNumVertices = (divisions + 1) * 2;
	size = _cylinderNumVertices * 3;
	tcSize = _cylinderNumVertices * 2;

	/* generate vertex data */
	p = malloc(sizeof(float) * size);
	tc = malloc(sizeof(float) * tcSize);
	t = malloc(sizeof(float) * size);
	b = malloc(sizeof(float) * size);
	n = malloc(sizeof(float) * size);
	for(i = 0; i <= divisions; ++i) {
		float r1 = ((M_PI * 2.0f) / (float)divisions) * (float)i;
		float r2 = r1 + M_PI / 2.0f;
		
		float c1 = cosf(r1);
		float s1 = sinf(r1);
		float c2 = cosf(r2);
		float s2 = sinf(r2);
		
		unsigned int j = i * 6;
		unsigned int k = i * 4;

		/* vertex positions */
		p[j+0] = c1;
		p[j+1] = 1.0f;
		p[j+2] = -s1;
		p[j+3] = c1;
		p[j+4] = -1.0f;
		p[j+5] = -s1;
		
		/* vertex texture coordinates */
		tc[k+0] = 1.0f / (float)divisions * (float)i * 3.0f;
		tc[k+1] = 0.0f;
		tc[k+2] = tc[k+0];
		tc[k+3] = 1.0f;
		
		/* vertex tangents */
		t[j+0] = c2;
		t[j+1] = 0.0f;
		t[j+2] = -s2;
		t[j+3] = c2;
		t[j+4] = 0.0f;
		t[j+5] = -s2;

		/* vertex bitangents */
		b[j+0] = 0.0f;
		b[j+1] = 1.0f;
		b[j+2] = 0.0f;
		b[j+3] = 0.0f;
		b[j+4] = 1.0f;
		b[j+5] = 0.0f;

		/* vertex normals */
		n[j+0] = c1;
		n[j+1] = 0.0f;
		n[j+2] = -s1;
		n[j+3] = c1;
		n[j+4] = 0.0f;
		n[j+5] = -s1;
	}
	
	/* create vertex array */
	glGenVertexArrays(1, &_vertexArrayId);
	glBindVertexArray(_vertexArrayId);
	
	/* create buffers */
	glGenBuffers(5, _cylinderBufferIds);

	/* create position buffer */
	glBindBuffer(GL_ARRAY_BUFFER, _cylinderBufferIds[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, p, GL_STATIC_DRAW);
	free(p);
	
	/* create position attribute array */
	glEnableVertexAttribArray(_programVertexPositionLocation);
	glVertexAttribPointer(_programVertexPositionLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
	
	/* create texture coordinates buffer */
	glBindBuffer(GL_ARRAY_BUFFER, _cylinderBufferIds[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * tcSize, tc, GL_STATIC_DRAW);
	free(tc);
	
	/* create texture coordinates attribute array */
	glEnableVertexAttribArray(_programVertexTexCoordsLocation);
	glVertexAttribPointer(_programVertexTexCoordsLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);

	/* create tangent buffer */
	glBindBuffer(GL_ARRAY_BUFFER, _cylinderBufferIds[2]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, t, GL_STATIC_DRAW);
	free(t);

	/* create tangent attribute array */
	glEnableVertexAttribArray(_programVertexTangentLocation);
	glVertexAttribPointer(_programVertexTangentLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
	
	/* create bitangent buffer */
	glBindBuffer(GL_ARRAY_BUFFER, _cylinderBufferIds[3]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, b, GL_STATIC_DRAW);
	free(b);

	/* create bitangent attribute array */
	glEnableVertexAttribArray(_programVertexBitangentLocation);
	glVertexAttribPointer(_programVertexBitangentLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
	
	/* create normal buffer */
	glBindBuffer(GL_ARRAY_BUFFER, _cylinderBufferIds[4]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, n, GL_STATIC_DRAW);
	free(n);

	/* create normal attribute array */
	glEnableVertexAttribArray(_programVertexNormalLocation);
	glVertexAttribPointer(_programVertexNormalLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void)attachShaderToProgram:(GLuint)program withType:(GLenum)type
	fromFile:(NSString *)filePath
{
	NSString *fullPath = [[[[NSBundle mainBundle] resourcePath]
		stringByAppendingString:@"/"] stringByAppendingString:filePath];
	shaderAttachFromFile(program, type, [fullPath UTF8String]);
}

- (void)renderWithProjectionMatrix:(const float *)projectionMatrix
{
	/* create modelview matrix */
	float modelviewMatrix[16];
	for(int i = 0; i < 4; ++i) {
		for(int j = 0; j < 4; ++j)
			modelviewMatrix[i * 4 + j] = (i == j) ? 1.0f : 0.0f;
	}
	modelviewMatrix[12] = -_cameraPosition[0];
	modelviewMatrix[13] = -_cameraPosition[1];
	modelviewMatrix[14] = -_cameraPosition[2];

	/* enable program and set uniform variables */
	glUseProgram(_program);
	glUniformMatrix4fv(_programProjectionMatrixLocation, 1, GL_FALSE, projectionMatrix);
	glUniformMatrix4fv(_programModelviewMatrixLocation, 1, GL_FALSE, modelviewMatrix);
	glUniform3fv(_programCameraPositionLocation, 1, _cameraPosition);
	glUniform3fv(_programLightPositionLocation, NUM_LIGHTS, _lightPosition);
	glUniform3fv(_programLightColorLocation, NUM_LIGHTS, _lightColor);

	/* render the cylinder */
	glDrawArrays(GL_TRIANGLE_STRIP, 0, _cylinderNumVertices);

	/* disable program */
	glUseProgram(0);
}

static long
getTicks(void)
{
	struct timeval t;

	gettimeofday(&t, NULL);

	return (t.tv_sec * 1000) + (t.tv_usec / 1000);
}

- (void)cycle
{
	static long prevTicks = 0;
	long ticks;
	float secondsElapsed;
	int i;

	/* calculate the number of seconds that have
	 * passed since the last call to this function */
	if(prevTicks == 0)
		prevTicks = getTicks();
	ticks = getTicks();
	secondsElapsed = (float)(ticks - prevTicks) / 1000.0f;
	prevTicks = ticks;

	/* update the light positions */
	_lightRotation += (M_PI / 4.0f) * secondsElapsed;
	for(i = 0; i < NUM_LIGHTS; ++i) {
		const float radius = 1.75f;
		float r = (((M_PI * 2.0f) / (float)NUM_LIGHTS) * (float)i) + _lightRotation;

		_lightPosition[i * 3 + 0] = cosf(r) * radius;
		_lightPosition[i * 3 + 1] = cosf(r) * sinf(r);
		_lightPosition[i * 3 + 2] = sinf(r) * radius;
	}
}

@end
