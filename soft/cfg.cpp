#include "cfg.h"
#include "hwi.h"
#include <string.h>

CCfg::CCfg()
{
  tagcnt = 0;
  ld.status = IOS_IDLE;
  ld.error = 0;
}

CCfg::~CCfg()
{
  delete ld.db;
}


int CCfg::setReq( char dir,
                 TCFGTarget target,
                 TCfg_chunk iai_code,
                 size_t index,
                 const char * data,
                 size_t bcount
                 )
{
  // check arguments, translate <target> to H/W code

  if (ld.status != IOS_IDLE)
    return EER_INVAL;

  u8 target_code = 0;

  switch (target)
  {
  case CFG_DEV_FRR:
    target_code = LSD_CFG_DEV_FRR;
    break;
  case CFG_DEV_FIBER:
    target_code = LSD_CFG_DEV_FIBER;
    break;
  case CFG_DEV_FG:
    target_code = LSD_CFG_DEV_FG;
    break;
  case CFG_DEV_TIMER:
    target_code = LSD_CFG_DEV_TIMER;
    break;
  default:
    return EER_INVAL;
  }

  const TCfg_chunk cfg_chunk_mask = ~0;

  if ((index & cfg_chunk_mask) != index)
    return EER_INVAL;

  if (!data)
    return EER_INVAL;

  if  (!bcount || ((bcount & cfg_chunk_mask) != bcount))
    return EER_INVAL;

  if (bcount > (LSD_CFG_MAX_NCHUNKS - LSD_CFG_HCHUNK_DATA))
    return EER_NOBUFS;

  // make packet
  size_t chunk_count = 0;

  if (bcount % sizeof(TCfg_chunk))
    chunk_count = ((bcount / sizeof(TCfg_chunk)) + 1);
  else
    chunk_count = bcount;

  ld.tx.tag = tagcnt;
  ld.tx.bsize_app = bcount;

  if (dir == LSD_CFG_DIR_WR)
    ld.tx.bsize_dev = (chunk_count * sizeof(TCfg_chunk))
                      + (LSD_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
  else
  {
    ld.tx.bsize_dev = (LSD_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
    ld.rx.bsize_dev = (chunk_count * sizeof(TCfg_chunk))
                      + (LSD_CFG_HCHUNK_COUNT * sizeof(TCfg_chunk));
  }

  if (!ld.db)
    ld.db = new char[ld.tx.bsize_dev];
  else
  {
    delete ld.db;
    ld.db = new char[ld.tx.bsize_dev];
  }

  memset(ld.db, 0, ld.tx.bsize_dev);

  TCfg_chunk * ptr = (TCfg_chunk *) ld.db;

  ptr[LSD_CFG_HCHUNK_CTRL]
    = ((iai_code << LSD_CFG_INC_BIT) & LSD_CFG_INC_MASK)
    | ((LSD_CFG_DIR_WR << LSD_CFG_DIR_BIT) & LSD_CFG_DIR_MASK)
    | ((tagcnt << LSD_CFG_TAG_BIT) & LSD_CFG_TAG_MASK)
    | ((target_code << LSD_CFG_DEV_BIT) & LSD_CFG_DEV_MASK);
  ptr[LSD_CFG_HCHUNK_ADR] = index;
  ptr[LSD_CFG_HCHUNK_DLEN] = chunk_count;

  if (dir == LSD_CFG_DIR_WR)
  {
    memcpy((char *) &ptr[LSD_CFG_HCHUNK_DATA], data, ld.tx.bsize_app);
    ld.status = IOS_WR;
  }
  else
    ld.status = IOS_RD;

  tagcnt++;
  ld.error = 0;

  return 0;
}


char * CCfg::setRxBuf(size_t bcount)
{
  if (!ld.db)
    ld.db = new char[bcount];
  else
  {
    delete ld.db;
    ld.db = new char[bcount];
  }

  return ld.db;
}


size_t CCfg::getRxCount(void)
{
  switch (ld.status)
  {
    case IOS_WR :
      return ld.tx.bsize_dev;//(LSD_CFG_HEADER_CHANK * sizeof(TCfg_chunk));

    case IOS_RD :
      return ld.rx.bsize_dev;

    default :
      return 0;
  }
}

int CCfg::chkACK(void)
{
  TCfg_chunk * ptr = (TCfg_chunk *) ld.db;
  int result = 0;

  switch (ld.status)
  {
    case IOS_WR :
      {
        if (((ptr[LSD_CFG_HCHUNK_CTRL] & LSD_CFG_TAG_MASK) >> LSD_CFG_TAG_BIT)
            != ld.tx.tag)
          result = EER_INVAL;

        if (ptr[LSD_CFG_HCHUNK_DLEN] != (ld.tx.bsize_dev / sizeof(TCfg_chunk)))
          result = EER_INVAL;
      }
      break;

    case IOS_RD :
      {
        if (((ptr[LSD_CFG_HCHUNK_CTRL] & LSD_CFG_TAG_MASK) >> LSD_CFG_TAG_BIT)
            != ld.tx.tag)
          result = EER_INVAL;

        if (ptr[LSD_CFG_HCHUNK_DLEN] != (ld.tx.bsize_dev / sizeof(TCfg_chunk)))
          result = EER_INVAL;

        result = ld.tx.bsize_app;
      }
      break;

    default :
      result = EER_INVAL;
  }


  ld.status = IOS_IDLE;
  return result;
}

char * CCfg::getRxPayload(void)
{

  TCfg_chunk * ptr = (TCfg_chunk *) ld.db;

  return (char *) &ptr[LSD_CFG_HCHUNK_DATA] ;
}
