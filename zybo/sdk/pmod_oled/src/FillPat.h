/************************************************************************/
/*																		*/
/*	FillPat.h	--	Fill Pattern Globals for pattern ID's				*/
/*																		*/
/************************************************************************/
/*	Author:		Gene Apperson											*/
/*	Copyright 2011, Digilent Inc.										*/
/************************************************************************/
/*  File Description:													*/
/*	This file defines a set of globals corresponding to the patterns used*/
/*	for filling objects in the FillPat.c array. Each pattern corresponds*/
/*	to one of the values here.											*/
/************************************************************************/

#if !defined(PMODOLED_FILLPAT)
#define	PMODOLED_FILLPAT
/* ------------------------------------------------------------ */
/*					Miscellaneous Declarations					*/
/* ------------------------------------------------------------ */
#define	ciptnVals	8
/* ------------------------------------------------------------ */
/*					General Type Declarations					*/
/* ------------------------------------------------------------ */
#define	iptnBlank		0
#define	iptnSolid		1
#define	iptnCross		2
#define	iptnSpekOpen	3
#define	iptnSpekTight	4
#define	iptnCirclesOpen	5
#define	iptnCircleBar	6
#define	iptnCarrots		7

#endif
