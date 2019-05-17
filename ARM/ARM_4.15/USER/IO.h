#ifndef __IO_H
#define __IO_H	 
#include "sys.h"
 	 


//#define KEY0 PEin(4)   	//PE4
//#define KEY1 PEin(3)	//PE3 
//#define KEY2 PEin(2)	//PE2
//#define WK_UP PAin(0)	//PA0  WK_UP



 

#define SPEED_UP PBout(13)// PB5
#define SPEED_DOWN PBout(15)// PB5
#define HORN PBout(14)// PB5



void IO_Init(void);//IO≥ı ºªØ
					    
#endif
