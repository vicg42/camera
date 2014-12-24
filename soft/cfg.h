#ifndef CFG_H
#define CFG_H

#include <QtGlobal>

typedef quint16 TCfg_chunk;
typedef quint8 u8;

#define EER_INVAL    -1
#define EER_NOBUFS   -2
#define EER_TIMEOUT  -3

typedef enum { IOS_IDLE, IOS_WR, IOS_RD } TIOStatus;

/** Configurable subsystems (destinations/sources) */

typedef enum
{
  CFG_DEV_FRR     // "Fiber Routing Rules" (switcher)
, CFG_DEV_FIBER
, CFG_DEV_FG      // "Frame Grabber" (vctrl)
, CFG_DEV_TIMER

} TCFGTarget;


class CCfg
{
  size_t tagcnt;

  struct TLocal_data
  {
    char * db;
    struct TReq
    {
      size_t bsize_app;
      size_t bsize_dev;
      size_t tag;
    } tx;
    struct TRx
    {
      size_t bsize_dev;
    } rx;

    TIOStatus status;
    int error;
  } ld;

public:
  CCfg();
  ~CCfg();

  int setReq(char dir,
            TCFGTarget target,
            TCfg_chunk iai_code,
            size_t index,
            const char * data,
            size_t bcount
            );

  size_t getTxCount(void) { return ld.tx.bsize_dev; }

  char * getTxBuf(void) { return ld.db; }
  char * getRxPayload(void);

  void AckTimeout(void) { ld.status = IOS_IDLE;
                          ld.error = EER_TIMEOUT;
                        }
  TIOStatus getState(void) { return ld.status; }

  size_t getRxCount(void);
  char * setRxBuf(size_t bcount);
  int chkACK(void);

};

#endif // CFG_H
