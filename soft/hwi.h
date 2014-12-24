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

#define LSD_CFG_MAX_NCHUNKS       123

#define LSD_CFG_HCHUNK_COUNT       3

#define LSD_CFG_HCHUNK_CTRL        0
#define LSD_CFG_HCHUNK_ADR         1
#define LSD_CFG_HCHUNK_DLEN        2
#define LSD_CFG_HCHUNK_DATA        3

// LSD_CFG_RC*: CFG/REGISTER/CTRL

#define LSD_CFG_TAG_BIT          0
#define LSD_CFG_TAG_MASK         (u16)(0x000f << LSD_CFG_TAG_BIT)
#define LSD_CFG_INC_BIT          6
#define LSD_CFG_INC_MASK         (u16)(0x0001 << LSD_CFG_INC_BIT)
#define LSD_CFG_DIR_BIT          7
#define LSD_CFG_DIR_MASK         (u16)(0x0001 << LSD_CFG_DIR_BIT)
#define LSD_CFG_DEV_BIT          8
#define LSD_CFG_DEV_MASK         (u16)(0x00ff << LSD_CFG_DEV_BIT)

//#define LSD_CFG_DIR_BIT          0
//#define LSD_CFG_DIR_MASK         (u32)(0x0001 << LSD_CFG_RCMO_DIRECTION)
//#define LSD_CFG_INC_BIT          1
//#define LSD_CFG_INC_MASK         (u32)(0x0001 << LSD_CFG_RCMO_INC)
//#define LSD_CFG_TAG_BIT          4
//#define LSD_CFG_TAG_MASK         (u32)(0x00ff << LSD_CFG_RCMO_TAG)
//#define LSD_CFG_DEV_BIT          16
//#define LSD_CFG_DEV_MSAK         (u32)(0x0000ffff << LSD_CFG_RCMO_TARGET)

#define LSD_CFG_INC_ENABLE      0U
#define LSD_CFG_INC_DISABLE     1U

#define LSD_CFG_DIR_WR          0U
#define LSD_CFG_DIR_RD          1U

#define LSD_CFG_DEV_FRR         0U
#define LSD_CFG_DEV_FIBER       1U
#define LSD_CFG_DEV_FG          2U
#define LSD_CFG_DEV_TIMER       3U

