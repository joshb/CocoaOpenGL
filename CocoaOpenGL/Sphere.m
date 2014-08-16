/*
 * Copyright (C) 2011-2014 Josh A. Beam
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

#import "Sphere.h"
#import "ShaderProgram.h"

@interface Sphere()
{
	unsigned int _numVertices;
	GLuint _vertexArrayId;
	GLuint _bufferIds[5];
}

@end

@implementation Sphere

- (id)initWithProgram:(ShaderProgram *)program andNumberOfDivisions:(unsigned int)divisions
{
	if((self = [super init])) {
		unsigned int i, h, size, tcSize;
		float *p, *tc, *t, *b, *n;

		_numVertices = divisions * (divisions + 1) * 2;
		size = _numVertices * 3;
		tcSize = _numVertices * 2;

		// allocate memory for vertex data
		p = malloc(sizeof(float) * size);
		tc = malloc(sizeof(float) * tcSize);
		t = malloc(sizeof(float) * size);
		b = malloc(sizeof(float) * size);
		n = malloc(sizeof(float) * size);

		// generate vertex data
		for(h = 0; h < divisions; ++h) {
			float hr1 = (M_PI / (float)divisions) * (float)h;
			float hr2 = (M_PI / (float)divisions) * (float)(h+1);

			float hc1 = cosf(hr1);
			float hs1 = sinf(hr1);
			float hc2 = cosf(hr2);
			float hs2 = sinf(hr2);

			for(i = 0; i <= divisions; ++i) {
				float r1 = ((M_PI * 2.0f) / (float)divisions) * (float)i;
				float r2 = r1 + M_PI / 2.0f;

				float c1 = cosf(r1);
				float s1 = sinf(r1);
				float c2 = cosf(r2);
				float s2 = sinf(r2);

				unsigned int j = (h * (divisions + 1) + i) * 6;
				unsigned int k = (h * (divisions + 1) + i) * 4;

				// vertex positions
				p[j+0] = c1 * hs1;
				p[j+1] = hc1;
				p[j+2] = -s1 * hs1;
				p[j+3] = c1 * hs2;
				p[j+4] = hc2;
				p[j+5] = -s1 * hs2;

				// vertex texture coordinates
				tc[k+0] = 1.0f / (float)divisions * (float)i * 3.0f;
				tc[k+1] = 1.0f / (float)divisions * (float)h;
				tc[k+2] = tc[k+0];
				tc[k+3] = 1.0f / (float)divisions * (float)(h+1);

				// vertex tangents
				t[j+0] = c2;
				t[j+1] = 0.0f;
				t[j+2] = -s2;
				t[j+3] = c2;
				t[j+4] = 0.0f;
				t[j+5] = -s2;

				// vertex bitangents
				b[j+0] = 0.0f;
				b[j+1] = 1.0f;
				b[j+2] = 0.0f;
				b[j+3] = 0.0f;
				b[j+4] = 1.0f;
				b[j+5] = 0.0f;

				// vertex normals
				n[j+0] = c1 * hs1;
				n[j+1] = hc1;
				n[j+2] = -s1 * hs1;
				n[j+3] = c1 * hs2;
				n[j+4] = hc2;
				n[j+5] = -s1 * hs2;
			}
		}

		// get the program's vertex data locations
		GLint programVertexPositionLocation = [program getLocationOfAttributeWithName:@"vertexPosition"];
		GLint programVertexTexCoordsLocation = [program getLocationOfAttributeWithName:@"vertexTexCoords"];
		GLint programVertexTangentLocation = [program getLocationOfAttributeWithName:@"vertexTangent"];
		GLint programVertexBitangentLocation = [program getLocationOfAttributeWithName:@"vertexBitangent"];
		GLint programVertexNormalLocation = [program getLocationOfAttributeWithName:@"vertexNormal"];

		// create vertex array
		glGenVertexArrays(1, &_vertexArrayId);
		glBindVertexArray(_vertexArrayId);

		// create buffers
		glGenBuffers(5, _bufferIds);

		// create position buffer
		glBindBuffer(GL_ARRAY_BUFFER, _bufferIds[0]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, p, GL_STATIC_DRAW);
		free(p);

		// create position attribute array
		glEnableVertexAttribArray(programVertexPositionLocation);
		glVertexAttribPointer(programVertexPositionLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

		// create texture coordinates buffer
		glBindBuffer(GL_ARRAY_BUFFER, _bufferIds[1]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float) * tcSize, tc, GL_STATIC_DRAW);
		free(tc);

		// create texture coordinates attribute array
		glEnableVertexAttribArray(programVertexTexCoordsLocation);
		glVertexAttribPointer(programVertexTexCoordsLocation, 2, GL_FLOAT, GL_FALSE, 0, 0);

		// create tangent buffer
		glBindBuffer(GL_ARRAY_BUFFER, _bufferIds[2]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, t, GL_STATIC_DRAW);
		free(t);

		// create tangent attribute array
		glEnableVertexAttribArray(programVertexTangentLocation);
		glVertexAttribPointer(programVertexTangentLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

		// create bitangent buffer
		glBindBuffer(GL_ARRAY_BUFFER, _bufferIds[3]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, b, GL_STATIC_DRAW);
		free(b);

		// create bitangent attribute array
		glEnableVertexAttribArray(programVertexBitangentLocation);
		glVertexAttribPointer(programVertexBitangentLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);

		// create normal buffer
		glBindBuffer(GL_ARRAY_BUFFER, _bufferIds[4]);
		glBufferData(GL_ARRAY_BUFFER, sizeof(float) * size, n, GL_STATIC_DRAW);
		free(n);

		// create normal attribute array
		glEnableVertexAttribArray(programVertexNormalLocation);
		glVertexAttribPointer(programVertexNormalLocation, 3, GL_FLOAT, GL_FALSE, 0, 0);
	}

	return self;
}

- (void)render
{
	glBindVertexArray(_vertexArrayId);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, _numVertices);
}

- (void)dealloc
{
	glDeleteBuffers(5, _bufferIds);
	glDeleteVertexArrays(1, &_vertexArrayId);
}

@end
