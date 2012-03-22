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
	glDeleteProgram(m_program);
	glDeleteBuffers(2, m_cylinderBufferIds);
	glDeleteVertexArrays(1, &m_vertexArrayId);
	[super dealloc];
}

- (void)sceneInit
{
	GLint result;

	/* create program object and attach shaders */
	m_program = glCreateProgram();
	[self attachShaderToProgram:m_program withType:GL_VERTEX_SHADER fromFile:@"shader.vp"];
	[self attachShaderToProgram:m_program withType:GL_FRAGMENT_SHADER fromFile:@"shader.fp"];

	/* link the program and make sure that there were no errors */
	glLinkProgram(m_program);
	glGetProgramiv(m_program, GL_LINK_STATUS, &result);
	if(result == GL_FALSE) {
		GLint length;
		char *log;

		/* get the program info log */
		glGetProgramiv(m_program, GL_INFO_LOG_LENGTH, &length);
		log = malloc(length);
		glGetProgramInfoLog(m_program, length, &result, log);

		/* print an error message and the info log */
		fprintf(stderr, "sceneInit(): Program linking failed: %s\n", log);
		free(log);

		/* delete the program */
		glDeleteProgram(m_program);
		m_program = 0;
	}

	/* get uniform locations */
	m_programProjectionMatrixLocation = glGetUniformLocation(m_program, "projectionMatrix");
	m_programModelviewMatrixLocation = glGetUniformLocation(m_program, "modelviewMatrix");
	m_programCameraPositionLocation = glGetUniformLocation(m_program, "cameraPosition");
	m_programLightPositionLocation = glGetUniformLocation(m_program, "lightPosition");
	m_programLightColorLocation = glGetUniformLocation(m_program, "lightColor");

	/* get attribute locations */
	m_programVertexPositionLocation = glGetAttribLocation(m_program, "vertexPosition");
	m_programVertexNormalLocation = glGetAttribLocation(m_program, "vertexNormal");

	/* set up red/green/blue lights */
	m_lightColor[0] = 1.0f; m_lightColor[1] = 0.0f; m_lightColor[2] = 0.0f;
	m_lightColor[3] = 0.0f; m_lightColor[4] = 1.0f; m_lightColor[5] = 0.0f;
	m_lightColor[6] = 0.0f; m_lightColor[7] = 0.0f; m_lightColor[8] = 1.0f;

	/* create cylinder */
	[self createCylinder:36];

	/* do the first cycle to initialize positions */
	m_lightRotation = 0.0f;
	[self cycle];

	/* setup camera */
	m_cameraPosition[0] = 0.0f;
	m_cameraPosition[1] = 0.0f;
	m_cameraPosition[2] = 4.0f;
}

- (void)createCylinder:(unsigned int)divisions
{
	unsigned int i, size;
	float *p;
	float *n;

	m_cylinderNumVertices = (divisions + 1) * 2;
	size = m_cylinderNumVertices * 3;

	/* generate vertex data */
	p = malloc(sizeof(float) * size);
	n = malloc(sizeof(float) * size);
	for(i = 0; i <= divisions; ++i) {
		float r = ((M_PI * 2.0f) / (float)divisions) * (float)i;
		unsigned int j = i * 6;

		/* vertex positions */
		p[j+0] = cosf(r);
		p[j+1] = 1.0f;
		p[j+2] = -sinf(r);
		p[j+3] = cosf(r);
		p[j+4] = -1.0f;
		p[j+5] = -sinf(r);

		/* vertex normals */
		n[j+0] = cosf(r);
		n[j+1] = 0.0f;
		n[j+2] = -sinf(r);
		n[j+3] = cosf(r);
		n[j+4] = 0.0f;
		n[j+5] = -sinf(r);
	}
	
	/* create vertex array */
	glGenVertexArrays(1, &m_vertexArrayId);
	glBindVertexArray(m_vertexArrayId);
	
	/* create buffers */
	glGenBuffers(2, m_cylinderBufferIds);

	/* create position buffer */
	glBindBuffer(GL_ARRAY_BUFFER, m_cylinderBufferIds[0]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, p, GL_STATIC_DRAW);
	free(p);
	
	/* create position attribute array */
	glEnableVertexAttribArray(m_programVertexPositionLocation);
	glVertexAttribPointer(m_programVertexPositionLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

	/* create normal buffer */
	glBindBuffer(GL_ARRAY_BUFFER, m_cylinderBufferIds[1]);
	glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, n, GL_STATIC_DRAW);
	free(n);

	/* create normal attribute array */
	glEnableVertexAttribArray(m_programVertexNormalLocation);
	glVertexAttribPointer(m_programVertexNormalLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
}

- (void)attachShaderToProgram:(GLuint)program withType:(GLenum)type fromFile:(NSString *)filePath
{
	NSString *fullPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingString:@"/"] stringByAppendingString:filePath];
	shaderAttachFromFile(program, type, [fullPath UTF8String]);
}

- (void)render:(const float *)projectionMatrix
{
	/* create modelview matrix */
	float modelviewMatrix[16];
	for(int i = 0; i < 4; ++i) {
		for(int j = 0; j < 4; ++j)
			modelviewMatrix[i * 4 + j] = (i == j) ? 1.0f : 0.0f;
	}
	modelviewMatrix[12] = -m_cameraPosition[0];
	modelviewMatrix[13] = -m_cameraPosition[1];
	modelviewMatrix[14] = -m_cameraPosition[2];

	/* enable program and set uniform variables */
	glUseProgram(m_program);
	glUniformMatrix4fv(m_programProjectionMatrixLocation, 1, GL_FALSE, projectionMatrix);
	glUniformMatrix4fv(m_programModelviewMatrixLocation, 1, GL_FALSE, modelviewMatrix);
	glUniform3fv(m_programCameraPositionLocation, 1, m_cameraPosition);
	glUniform3fv(m_programLightPositionLocation, NUM_LIGHTS, m_lightPosition);
	glUniform3fv(m_programLightColorLocation, NUM_LIGHTS, m_lightColor);

	/* render the cylinder */
	glDrawArrays(GL_TRIANGLE_STRIP, 0, m_cylinderNumVertices);

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
	m_lightRotation += (M_PI / 4.0f) * secondsElapsed;
	for(i = 0; i < NUM_LIGHTS; ++i) {
		const float radius = 1.75f;
		float r = (((M_PI * 2.0f) / (float)NUM_LIGHTS) * (float)i) + m_lightRotation;

		m_lightPosition[i * 3 + 0] = cosf(r) * radius;
		m_lightPosition[i * 3 + 1] = cosf(r) * sinf(r);
		m_lightPosition[i * 3 + 2] = sinf(r) * radius;
	}
}

@end