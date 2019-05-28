#include "infrared.h"
#include "delay.h"
#include "LED.h"

int barrier_flag=0; //�ϰ���־��Ϊ1��ʾ���ϰ� 
int TIM2_begin=0; //��ʱ��2��ʼ������־
extern int wheel_status_before;
extern int front_speed;
extern int wheel_status;

//��ʼ��PB5Ϊ�����.��ʹ���������ڵ�ʱ��		    
//INFARED IO��ʼ��
void INFRARED_Init(void)
{
    //��ʼ���ṹ������
	EXTI_InitTypeDef EXTI_InitStructure;
	NVIC_InitTypeDef NVIC_InitStructure;
	
	GPIO_InitTypeDef  GPIO_InitStructure;

	//��ʼ��IO��
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA|RCC_APB2Periph_GPIOB,ENABLE);//ʹ��PORTA,PORTBʱ��

	GPIO_InitStructure.GPIO_Pin  = GPIO_Pin_3;//
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //���ó���������
 	GPIO_Init(GPIOA, &GPIO_InitStructure);//��ʼ��PA.3

	GPIO_InitStructure.GPIO_Pin  = GPIO_Pin_12;//
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //���ó���������
 	GPIO_Init(GPIOB, &GPIO_InitStructure);//��ʼ��PB.12
	
	
	//��ʼ���ⲿ�ж�
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO,ENABLE); //���� AFIO ʱ��
	
	//GPIOA.3 �ж����Լ��жϳ�ʼ������,���ش���
	GPIO_EXTILineConfig(GPIO_PortSourceGPIOA,GPIO_PinSource3);
	EXTI_InitStructure.EXTI_Line=EXTI_Line3;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising_Falling; //���ش���
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure); //��ʼ���ж��߲���
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI3_IRQn; //ʹ���ⲿ�ж�ͨ��
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x02; //��ռ���ȼ� 2��
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01; //�����ȼ� 2
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE; //ʹ���ⲿ�ж�ͨ��
	NVIC_Init(&NVIC_InitStructure);//��ʼ���ж�ͨ��
	
	//GPIOB.12 �ж����Լ��жϳ�ʼ������,���ش���
	GPIO_EXTILineConfig(GPIO_PortSourceGPIOB,GPIO_PinSource12);
	EXTI_InitStructure.EXTI_Line=EXTI_Line12;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising_Falling; //���ش���
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure); //��ʼ���ж��߲���
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI15_10_IRQn; //ʹ�ܰ����ⲿ�ж�ͨ��
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x02; //��ռ���ȼ� 2��
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x02; //�����ȼ� 2
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE; //ʹ���ⲿ�ж�ͨ��
	NVIC_Init(&NVIC_InitStructure);//��ʼ���ж�ͨ��
}

void EXTI3_IRQHandler(void)
{
	if(INF1==0) //�����ϰ�
	{
		delay_ms(10);
		if(INF1==0)
		{
			barrier_flag=1;
			TIM_SetCompare1(TIM3,250);
			TIM_SetCompare2(TIM3,250);
			wheel_status=0;
			LED0=!LED0;
		}
	}
	
	if(INF1==1 && INF2==1) //�ϰ���ʧ
	{
		delay_ms(10);
		if(INF1==1 && INF2==1)
		{
			barrier_flag=0;
			if(wheel_status_before==1 || wheel_status==1)
			{
				TIM_SetCompare1(TIM3,250);
				TIM_SetCompare2(TIM3,front_speed);
				wheel_status=1;
			}
		}
	}
//	if(INF1==0)	 	 //1�ź������ϰ�
//	{				 
//		delay_ms(10);//����
//		if(INF1==0)  //��ʾ���ϰ�
//		{
//			if(TIM2_begin==0)   //TIM2δ��ʼ����
//			{
//				TIM_Cmd(TIM2, ENABLE); 
//				TIM2_begin=1;
//			}
//			
//		}
//		TIM_SetCounter(TIM5,0);
//	}
	EXTI_ClearITPendingBit(EXTI_Line3); //���LINE3�ϵ��жϱ�־λ  
}

void EXTI15_10_IRQHandler(void)
{
	if(INF2==0) //�����ϰ�
	{
		delay_ms(10);
		if(INF2==0)
		{
			barrier_flag=1;
			TIM_SetCompare1(TIM3,250);
			TIM_SetCompare2(TIM3,250);
			wheel_status=0;
			LED0=!LED0; 
		}
	}
	
	if(INF1==1 && INF2==1) //�ϰ���ʧ
	{
		delay_ms(10);
		if(INF1==1 && INF2==1)
		{
			barrier_flag=0;
			if(wheel_status_before==1 || wheel_status==1)
			{
				TIM_SetCompare1(TIM3,250);
				TIM_SetCompare2(TIM3,front_speed);
				wheel_status=1;
			}
		}
	}
	EXTI_ClearITPendingBit(EXTI_Line12); //���LINE3�ϵ��жϱ�־λ
}

int INFRARED_Scan(void)  //���ϰ���1��  ���ϰ���0
{
	int inf_flag=0;
	
	if(INF1==0)
	{
		delay_ms(10);
		if(INF1==0) inf_flag=1;
	}
	if(INF2==0)
	{
		delay_ms(5);
		if(INF2==0) inf_flag=2;
	}	
	
	
	return inf_flag;
}



 
