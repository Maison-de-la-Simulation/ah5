/*******************************************************************************
 * Copyright (c) 2013-2016, Julien Bigot - CEA (julien.bigot@cea.fr)
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 * * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * * Neither the name of the <organization> nor the
 * names of its contributors may be used to endorse or promote products
 * derived from this software without specific prior written permission.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 ******************************************************************************/

#ifndef AH5_LOGGING_H__
#define AH5_LOGGING_H__

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>

#include "ah5.h"
#include "logging_fwd.h"


struct logging_s {
	/** the file where to log
		*/
	FILE* file;
	
	enum {
		FILE_CLOSE,
		FILE_KEEP_OPEN
	} closing_strategy;

	/** the verbosity level
		*/
	ah5_verbosity_t verbosity;
	
};


#define LOG_ERROR( logger, ... ) do {\
	if ((logger).verbosity >= AH5_VERB_ERROR) {\
		FILE* out = (logger).file? (logger).file : stderr;\
		fprintf(out, "*** Error: %s:%d: ", __FILE__, __LINE__);\
		fprintf(out , ##__VA_ARGS__);\
		fprintf(out, "\n");\
		fflush(out);\
	}\
} while (0)



#define LOG_WARNING( logger, ... ) do {\
	if ((logger).verbosity >= AH5_VERB_WARNING) {\
		FILE* out = (logger).file? (logger).file : stderr;\
		fprintf(out, "*** Warning: %s:%d: ", __FILE__, __LINE__);\
		fprintf(out , ##__VA_ARGS__);\
		fprintf(out, "\n");\
		fflush(out);\
	}\
} while (0)


#define LOG_STATUS( logger, ... ) do {\
	if ( (logger).verbosity >= AH5_VERB_STATUS ) {\
		FILE* out = (logger).file? (logger).file : stderr;\
		fprintf(out, "*** Status: %s:%d: ", __FILE__, __LINE__);\
		fprintf(out , ##__VA_ARGS__);\
		fprintf(out, "\n");\
		fflush(out);\
	}\
} while (0)


#ifndef NDEBUG
#define LOG_DEBUG( logger, ... ) do {\
	if ( (logger).verbosity >= AH5_VERB_DEBUG) {\
		FILE* out = (logger).file? (logger).file : stderr;\
		fprintf(out, "*** Log: %s:%d: ", __FILE__, __LINE__);\
		fprintf(out , ##__VA_ARGS__);\
		fprintf(out, "\n");\
		fflush(out);\
	}\
} while (0)
#else
#define LOG_DEBUG( ... )
#endif


#define SIGNAL_ERROR( logger ) do {\
	int errno_save = errno;\
	LOG_ERROR(logger, " ----- Fatal: exiting -----\n");\
	errno = errno_save;\
	perror(NULL);\
	exit(errno_save);\
} while (0)


#define RETURN_ERROR( logger ) do {\
	int errno_save = errno;\
	LOG_WARNING(logger, " ----- Leaving function -----\n");\
	errno = errno_save;\
	perror(NULL);\
	errno = errno_save;\
	return errno_save;\
} while (0)


/** Returns the number of microseconds elapsed since EPOCH
 * @returns the number of microseconds elapsed since EPOCH
 */
inline static int64_t clockget()
{
	struct timeval tv;
	gettimeofday(&tv, NULL);
	return (int64_t)tv.tv_sec*1000*1000 + tv.tv_usec;
}


/**
 */
void log_init( logging_t *log );


/**
 */
void log_destroy( logging_t *log );


/**
 */
void log_set_lvl( logging_t *log, ah5_verbosity_t log_lvl );


/**
 */
int log_set_filename( logging_t *log, char* file_name );


/**
 */
int log_set_file( logging_t *log, FILE* file, int keep_open );


/**
 */
int log_set_filedesc( logging_t *log, int file_desc, int keep_open );

#endif /* AH5_LOGGING_H__ */
