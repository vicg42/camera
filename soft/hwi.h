/*
 *  file:   hwi.h
 *  date:   22.05.2010
 *  authors:  Topolsky
 *  company:  Linkos
 *  format:   tab4
 *  descript.:  H/W interface definition
 */

#ifndef __LSD_HWI_H
#define __LSD_HWI_H

#include <QtGlobal>

typedef quint32 u32;
typedef quint16 u16;
typedef quint8 u8;

// CFG interface ---------------------------------------------------------------

#define C_CFG_MAX_NCHUNKS       123

#define C_CFG_HCHUNK_COUNT       3

#define C_CFG_HCHUNK_CTRL        0
#define C_CFG_HCHUNK_ADR         1
#define C_CFG_HCHUNK_DLEN        2
#define C_CFG_HCHUNK_DATA        3

//CFG/REGISTER/CTRL
#define C_CFG_DIR_BIT          0
#define C_CFG_DIR_MASK         (u32)(0x0001 << C_CFG_DIR_BIT)
#define C_CFG_FIFO_BIT         1
#define C_CFG_FIFO_MASK        (u32)(0x0001 << C_CFG_FIFO_BIT)
#define C_CFG_DEV_BIT          2
#define C_CFG_DEV_MASK         (u32)(0x0000000f << C_CFG_DEV_BIT)
#define C_CFG_TAG_BIT          6
#define C_CFG_TAG_MASK         (u32)(0x00000003 << C_CFG_TAG_BIT)

#define C_CFG_FIFO_OFF        0U
#define C_CFG_FIFO_ON         1U

#define C_CFG_DIR_WR          0U
#define C_CFG_DIR_RD          1U

#define C_CFG_DEV_FRR         0U
#define C_CFG_DEV_FIBER       1U
#define C_CFG_DEV_FG          2U
#define C_CFG_DEV_TIMER       3U

#endif // __LSD_HWI_H
