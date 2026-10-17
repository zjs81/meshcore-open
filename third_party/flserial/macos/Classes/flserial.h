#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#if _WIN32
#include <windows.h>
#else
#include <pthread.h>
#include <unistd.h>
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT
#endif


#define MAX_PORT_FIFO_LEN 128*1024
#define MAX_PORT_NAME_LEN 512
#define MAX_PORT_COUNT 16

typedef enum FlCtrl {
  FL_CTRL_LAST_ERROR,
  FL_CTRL_IS_PORT_OPEN,
  FL_CTRL_BREAK,
  FL_CTRL_SET_RTS,
  FL_CTRL_GET_CTS,
  FL_CTRL_SET_DTR,
  FL_CTRL_GET_DSR,
  FL_CTRL_SET_BYTESIZE_5,
  FL_CTRL_SET_BYTESIZE_6,
  FL_CTRL_SET_BYTESIZE_7,
  FL_CTRL_SET_BYTESIZE_8,
  FL_CTRL_SET_PARITY_NONE,
  FL_CTRL_SET_PARITY_ODD,
  FL_CTRL_SET_PARITY_EVEN,
  FL_CTRL_SET_PARITY_MARK,
  FL_CTRL_SET_PARITY_SPACE,
  FL_CTRL_SET_STOPBITS_ONE,
  FL_CTRL_SET_STOPBITS_TWO,
  FL_CTRL_SET_STOPBITS_ONE_POINT_FIVE,
  FL_CTRL_SET_FLOWCONTROL_NONE,
  FL_CTRL_SET_FLOWCONTROL_HARDWARE,
  FL_CTRL_SET_FLOWCONTROL_SOFTWARE,
  FL_CTRL_GET_STATUS_CHANGE,
  FL_CTRL_LAST,
} FlCtrl;

typedef enum FlError {
    FL_ERROR_OK,
    FL_ERROR_UNKNOW,
    FL_ERROR_PORT_ALLREADY_OPEN,
    FL_ERROR_PORT_NOT_EXIST,
    FL_ERROR_IO,
    FL_ERROR_HANDLER,
    FL_ERROR_LAST,
} FlError;

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*flcallback)(unsigned int, unsigned int);

FFI_PLUGIN_EXPORT int fl_init (int portCount);
FFI_PLUGIN_EXPORT int fl_set_callback(int flh, flcallback cb);
FFI_PLUGIN_EXPORT int fl_ports (int index, int buffsize, char *buff);
FFI_PLUGIN_EXPORT int fl_open (int flh, char *portname, int baudrate);
FFI_PLUGIN_EXPORT int fl_read (int flh, int len, char *buff);
FFI_PLUGIN_EXPORT int fl_write (int flh, int len, char *data);
FFI_PLUGIN_EXPORT int fl_close (int flh);
FFI_PLUGIN_EXPORT int fl_ctrl (int flh, FlCtrl param, int value);
FFI_PLUGIN_EXPORT int fl_free (void);


#ifdef __cplusplus
}
#endif
