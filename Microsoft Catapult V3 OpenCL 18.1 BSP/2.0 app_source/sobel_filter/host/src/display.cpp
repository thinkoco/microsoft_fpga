// Copyright (C) 2013-2019 Altera Corporation, San Jose, California, USA. All rights reserved.
// Permission is hereby granted, free of charge, to any person obtaining a copy of this
// software and associated documentation files (the "Software"), to deal in the Software
// without restriction, including without limitation the rights to use, copy, modify, merge,
// publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to
// whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or
// substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
// 
// This agreement shall be governed in all respects by the laws of the State of California and
// by the laws of the United States of America.

#define NOMINMAX // so that windows.h does not define min/max macros

#include <SDL2/SDL.h>
#include <CL/opencl.h>
#include <algorithm>
#include <iostream>
#include "parse_ppm.h"
#include "defines.h"
#include "AOCLUtils/aocl_utils.h"

using namespace aocl_utils;

#define REFRESH_DELAY 10 //ms

int glutWindowHandle;
int graphicsWinWidth = 1024;
int graphicsWinHeight = (int)(((float) ROWS / (float) COLS) * graphicsWinWidth);
float fZoom = 1024;
bool useFilter = false;
unsigned int thresh = 128;
int fps_raw = 0;
double total_fps = 0;

cl_uint *input = NULL;
cl_uint *output = NULL;

cl_uint num_platforms;
cl_platform_id platform;
cl_uint num_devices;
cl_device_id device;
cl_context context;
cl_command_queue queue;
cl_program program;
cl_kernel kernel;
#if USE_SVM_API == 0
cl_mem in_buffer, out_buffer;
#endif /* USE_SVM_API == 0 */

std::string imageFilename;
std::string aocxFilename;
std::string deviceInfo;

SDL_Window *sdlWindow = NULL;
SDL_Surface *sdlWindowSurface = NULL;
SDL_Surface *sdlInputSurface = NULL;
SDL_Surface *sdlOutputSurface = NULL;

static bool profile = false;
bool useDisplay = true;
bool testMode = false;
bool reportAverage = false;
unsigned testThresholds[] = {32, 96, 128, 192, 225};
unsigned testFrameIndex = 0;

// Control whether the fast emulator should be used.
static bool use_fast_emulator = false;

bool initSDL();
void eventLoop();
void keyboardPressEvent(SDL_Event *event);
void repaint();

void teardown(int exit_status = 1);
void initCL();
void dumpFrame(unsigned frameIndex, unsigned *frameData);

void filter()
{
  size_t sobelSize = 1;
  cl_int status;

#if USE_SVM_API == 0
  status = clEnqueueWriteBuffer(queue, in_buffer, CL_FALSE, 0, sizeof(unsigned int) * ROWS * COLS, input, 0, NULL, NULL);
  checkError(status, "Error: could not copy data into device");

  status = clFinish(queue);
  checkError(status, "Error: could not finish successfully");
#endif /* USE_SVM_API == 0 */

  if(!testMode) {
    status = clSetKernelArg(kernel, 3, sizeof(unsigned int), &thresh);
  }
  else {
    // In test mode, iterate through different thresholds automatically.
    status = clSetKernelArg(kernel, 3, sizeof(unsigned int), &testThresholds[testFrameIndex]);
  }
  checkError(status, "Error: could not set sobel threshold");

  cl_event event;
  status = clEnqueueNDRangeKernel(queue, kernel, 1, NULL, &sobelSize, &sobelSize, 0, NULL, &event);
  checkError(status, "Error: could not enqueue sobel filter");

  status  = clFinish(queue);
  checkError(status, "Error: could not finish successfully");

  cl_ulong start, end;
  status  = clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_START, sizeof(cl_ulong), &start, NULL);
  status |= clGetEventProfilingInfo(event, CL_PROFILING_COMMAND_END, sizeof(cl_ulong), &end, NULL);
  checkError(status, "Error: could not get profile information");
  clReleaseEvent(event);

  fps_raw = (int)(1.0f / ((end - start) * 1e-9f));
  total_fps += (1.0f / ((end - start) * 1e-9f));

  if (profile) {
    printf("Throughput: %d FPS\n", fps_raw);
  }
#if USE_SVM_API == 0
  status = clEnqueueReadBuffer(queue, out_buffer, CL_FALSE, 0, sizeof(unsigned int) * ROWS * COLS, output, 0, NULL, NULL);
  checkError(status, "Error: could not copy data from device");

  status = clFinish(queue);
  checkError(status, "Error: could not successfully finish copy");
#else
  status = clEnqueueSVMMap(queue, CL_TRUE, CL_MAP_READ,
      (void *)output, sizeof(unsigned int) * ROWS * COLS, 0, NULL, NULL);
  checkError(status, "Failed to map output");
#endif /* USE_SVM_API == 0 */

  if(testMode) {
    // Dump out frame data in PPM (ASCII).
    dumpFrame(testFrameIndex, output);

    // Increment test frame index.
    testFrameIndex++;
    if(testFrameIndex == sizeof(testThresholds)/sizeof(testThresholds[0])) {
      // Exit - all test thresholds completed.
      SDL_Event quitEvent;
      quitEvent.type = SDL_QUIT;
      SDL_PushEvent(&quitEvent);
    }
  }

  // Display FPS in window title bar.
  char title[256];
  sprintf(title, "Sobel Filter (%d FPS)", fps_raw);
  SDL_SetWindowTitle(sdlWindow, title);
#if USE_SVM_API == 1
  status = clEnqueueSVMUnmap(queue, (void *)output, 0, NULL, NULL);
  checkError(status, "Failed to unmap output");
#endif /* USE_SVM_API == 1 */
}

// Dump frame data in PPM format.
void dumpFrame(unsigned frameIndex, unsigned *frameData) {
  char fname[256];
  sprintf(fname, "frame%d.ppm", frameIndex);
  printf("Dumping %s\n", fname);

  FILE *f = fopen(fname, "wb");
  if(f == NULL){
    return;
  }
  
  fprintf(f, "P6 %d %d %d\n", COLS, ROWS, 255);
  for(unsigned y = 0; y < ROWS; ++y) {
    for(unsigned x = 0; x < COLS; ++x) {
      // This assumes byte-order is little-endian.
      unsigned pixel = frameData[y * COLS + x];
      fwrite(&pixel, 1, 3, f);
    }
  }
  fclose(f);
}

int main(int argc, char **argv)
{
  Options options(argc, argv);
  profile = options.has("profile");
  reportAverage = options.has("report-average");

  if(options.has("display")) {
    useDisplay = options.get<bool>("display");
  }

  imageFilename = "sample_image.ppm";
  if(options.has("img")) {
    imageFilename = options.get<std::string>("img");
  }

  // If in test mode, start with useFilter = true.
  if(options.has("test")) {
    useFilter = true;
    testMode = true;
  }

  // Optional argument to specify whether the fast emulator should be used.
  if(options.has("fast-emulator")) {
    use_fast_emulator = options.get<bool>("fast-emulator");
  }

#if USE_SVM_API == 0
  input = (cl_uint*)alignedMalloc(sizeof(unsigned int) * ROWS * COLS);
  output = (cl_uint*)alignedMalloc(sizeof(unsigned int) * ROWS * COLS);
#endif /* USE_SVM_API == 0 */

  if(!initSDL()) {
    return 1;
  }
  initCL();

#if USE_SVM_API == 1
  status = clEnqueueSVMMap(queue, CL_TRUE, CL_MAP_WRITE,
      (void *)input, sizeof(unsigned int) * ROWS * COLS, 0, NULL, NULL);
  checkError(status, "Failed to map input");
#endif /* USE_SVM_API == 1 */

  // Read the image
  if (!parse_ppm(imageFilename.c_str(), COLS, ROWS, (unsigned char *)input)) {
    std::cerr << "Error: could not load " << argv[1] << std::endl;
    teardown();
  }

#if USE_SVM_API == 1
  status = clEnqueueSVMUnmap(queue, (void *)input, 0, NULL, NULL);
  checkError(status, "Failed to unmap input");
#endif /* USE_SVM_API == 1 */

  std::cout << "Commands:" << std::endl;
  std::cout << " <space>  Toggle filter on or off" << std::endl;
  std::cout << " -" << std::endl
            << "  Reduce filter threshold" << std::endl;
  std::cout << " +" << std::endl
            << "  Increase filter threshold" << std::endl;
  std::cout << " =" << std::endl
            << "  Reset filter threshold to default" << std::endl;
  std::cout << " q/<enter>/<esc>" << std::endl
            << "  Quit the program" << std::endl;

  eventLoop();

  teardown(0);
}

void initCL()
{
  cl_int status;

  if (!setCwdToExeDir()) {
    teardown();
  }

  // Get the OpenCL platform.
  if (use_fast_emulator) {
    platform = findPlatform("Intel(R) FPGA Emulation Platform for OpenCL(TM)");
  } else {
    platform = findPlatform("Intel(R) FPGA SDK for OpenCL(TM)");
  }
  if (platform == NULL) {
    teardown();
  }

  status = clGetDeviceIDs(platform, CL_DEVICE_TYPE_ALL, 1, &device, NULL);
  checkError (status, "Error: could not query devices");
  num_devices = 1; // always only using one device

  char info[256];
  clGetDeviceInfo(device, CL_DEVICE_NAME, sizeof(info), info, NULL);
  deviceInfo = info;

#if USE_SVM_API == 1
  cl_device_svm_capabilities caps = 0;

  status = clGetDeviceInfo(
    device,
    CL_DEVICE_SVM_CAPABILITIES,
    sizeof(cl_device_svm_capabilities),
    &caps,
    0
  );
  checkError(status, "Failed to get device info");

  if (!(caps & CL_DEVICE_SVM_COARSE_GRAIN_BUFFER)) {
    printf("The host was compiled with USE_SVM_API, however the device currently being targeted does not support SVM.\n");
    teardown();
  }
#endif /* USE_SVM_API == 1 */

  context = clCreateContext(0, num_devices, &device, &oclContextCallback, NULL, &status);
  checkError(status, "Error: could not create OpenCL context");

  queue = clCreateCommandQueue(context, device, CL_QUEUE_PROFILING_ENABLE, &status);
  checkError(status, "Error: could not create command queue");

  std::string binary_file = getBoardBinaryFile("sobel", device);
  std::cout << "Using AOCX: " << binary_file << "\n";
  program = createProgramFromBinary(context, binary_file.c_str(), &device, 1);

  status = clBuildProgram(program, num_devices, &device, "", NULL, NULL);
  checkError(status, "Error: could not build program");

  kernel = clCreateKernel(program, "sobel", &status);
  checkError(status, "Error: could not create sobel kernel");

#if USE_SVM_API == 0
  in_buffer = clCreateBuffer(context, CL_MEM_READ_ONLY, sizeof(unsigned int) * ROWS * COLS, NULL, &status);
  checkError(status, "Error: could not create device buffer");

  out_buffer = clCreateBuffer(context, CL_MEM_WRITE_ONLY, sizeof(unsigned int) * ROWS * COLS, NULL, &status);
  checkError(status, "Error: could not create output buffer");
#else
  input = (cl_uint*)clSVMAlloc(context, CL_MEM_READ_WRITE, sizeof(unsigned int) * ROWS * COLS, 0);
  if (NULL == input)
    checkError(-1, "Could not allocate input");
  output = (cl_uint*)clSVMAlloc(context, CL_MEM_READ_WRITE, sizeof(unsigned int) * ROWS * COLS, 0);
  if (NULL == output)
    checkError(-1, "Could not allocate output");
#endif /* USE_SVM_API == 0 */

  int pixels = COLS * ROWS;
#if USE_SVM_API == 0
  status = clSetKernelArg(kernel, 0, sizeof(cl_mem), &in_buffer);
  checkError(status, "Error: could not set sobel arg 0");
  status = clSetKernelArg(kernel, 1, sizeof(cl_mem), &out_buffer);
  checkError(status, "Error: could not set sobel arg 1");
#else
  status = clSetKernelArgSVMPointer(kernel, 0, (void *)input);
  checkError(status, "Error: could not set sobel arg 0");
  status = clSetKernelArgSVMPointer(kernel, 1, (void*)output);
  checkError(status, "Error: could not set sobel arg 1");
#endif /* USE_SVM_API == 0 */
  status = clSetKernelArg(kernel, 2, sizeof(int), &pixels);
  checkError(status, "Error: could not set sobel arg 2");
}

bool initSDL()
{
  // Initialize.
  if(SDL_Init(useDisplay ? SDL_INIT_VIDEO : 0) != 0) {
    std::cerr << "Error: Could not initialize SDL: " << SDL_GetError() << "\n";
    return false;
  }

  if(useDisplay) {
    // Create the window.
    sdlWindow = SDL_CreateWindow("Sobel Filter", 
      SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
      1024, 1024 * ROWS / COLS, 0);
    if(sdlWindow == NULL) {
      std::cerr << "Error: Could not create SDL window: " << SDL_GetError() << "\n";
      return false;
    }

    // Get the window's surface.
    sdlWindowSurface = SDL_GetWindowSurface(sdlWindow);
    if(sdlWindowSurface == NULL) {
      std::cerr << "Error: Could not get SDL window surface: " << SDL_GetError() << "\n";
      return false;
    }

    // Create the input and output surfaces.
    sdlInputSurface = SDL_CreateRGBSurfaceFrom(input, COLS, ROWS, 32, COLS * sizeof(unsigned int),
        0xff, 0xff00, 0xff0000, 0);
    sdlOutputSurface = SDL_CreateRGBSurfaceFrom(output, COLS, ROWS, 32, COLS * sizeof(unsigned int),
        0xff, 0xff00, 0xff0000, 0);
  }

  return true;
}

void eventLoop()
{
  bool running = true;
  while(running) {
    SDL_Event event;
    if(SDL_PollEvent(&event)) {
      switch(event.type) {
        case SDL_QUIT:
          running = false;
          break;

        case SDL_KEYDOWN:
          keyboardPressEvent(&event);
          break;

        case SDL_WINDOWEVENT:
          if(event.window.event == SDL_WINDOWEVENT_EXPOSED) {
            repaint();
          }
          break;
      }
    }
    else {
      repaint();
    }
  }

  if (profile && reportAverage) {
    printf("Average Throughput: %d FPS\n", int (total_fps / (sizeof(testThresholds)/sizeof(testThresholds[0]))));
  }
}

void keyboardPressEvent(SDL_Event *event) 
{
  SDL_KeyboardEvent *keyEvent = (SDL_KeyboardEvent *)event;
  switch(keyEvent->keysym.sym) {
    // Quit.
    case SDLK_ESCAPE:
    case SDLK_RETURN:
    case SDLK_q: {
      SDL_Event quitEvent;
      quitEvent.type = SDL_QUIT;
      SDL_PushEvent(&quitEvent);
      break;
    }

    // Toggle filter.
    case SDLK_SPACE:
      useFilter ^= true;
      break;

    // Threshold adjustments.
    case SDLK_EQUALS:
      thresh = 128;
      break;

    case SDLK_KP_MINUS:
    case SDLK_MINUS:
      thresh = std::max(thresh - 10, 16u);
      break;

    case SDLK_KP_PLUS:
    case SDLK_PLUS:
      thresh = std::min(thresh + 10, 255u);
      break;
  }
}

void repaint() 
{
  if(useFilter) {
    filter();
  }

  if(useDisplay) {
    if(!useFilter) {
      // Reset window title.
      SDL_SetWindowTitle(sdlWindow, "Sobel Filter");
    }

    // Blit the image surface to the window surface.
    SDL_BlitScaled(useFilter ? sdlOutputSurface : sdlInputSurface, NULL, sdlWindowSurface, NULL);

    // Update the window surface.
    SDL_UpdateWindowSurface(sdlWindow);
  }
}

void cleanup()
{
  // Called from aocl_utils::check_error, so there's an error.
  teardown(-1);
}

void teardown(int exit_status)
{
#if USE_SVM_API == 0
  if (input) alignedFree(input);
  if (output) alignedFree(output);
  if (in_buffer) clReleaseMemObject(in_buffer);
  if (out_buffer) clReleaseMemObject(out_buffer);
#else
  if (input) clSVMFree(context, input);
  if (output) clSVMFree(context, output);
#endif /* USE_SVM_API == 0 */
  if (kernel) clReleaseKernel(kernel);
  if (program) clReleaseProgram(program);
  if (queue) clReleaseCommandQueue(queue);
  if (context) clReleaseContext(context);

  SDL_Quit();
  exit(exit_status);
}

