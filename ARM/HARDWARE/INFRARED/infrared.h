#ifndef __INFRARED_H
#define __INFRARED_H	 
#include "sys.h"

#define INF1  GPIO_ReadInputDataBit(GPIOA,GPIO_Pin_3)//��ȡPA.3
#define INF2  GPIO_ReadInputDataBit(GPIOB,GPIO_Pin_12)//��ȡPB.12

void INFRARED_Init(void);//��ʼ��
int INFRARED_Scan(void); //�����ȡ

		 				    
#endif
