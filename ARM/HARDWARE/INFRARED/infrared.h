#ifndef __INFRARED_H
#define __INFRARED_H	 
#include "sys.h"

#define INF1  GPIO_ReadInputDataBit(GPIOA,GPIO_Pin_3)//读取PA.3
#define INF2  GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_12)//读取PB.12

void INFRARED_Init(void);//初始化
int INFRARED_Scan(void); //红外读取

		 				    
#endif
