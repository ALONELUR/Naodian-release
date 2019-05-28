#include "infrared.h"
#include "delay.h"
#include "LED.h"

int barrier_flag=0; //障碍标志，为1表示有障碍 
int TIM2_begin=0; //定时器2开始计数标志
extern int wheel_status_before;
extern int front_speed;
extern int wheel_status;

//初始化PB5为输出口.并使能这两个口的时钟		    
//INFARED IO初始化
void INFRARED_Init(void)
{
    //初始化结构体声明
	EXTI_InitTypeDef EXTI_InitStructure;
	NVIC_InitTypeDef NVIC_InitStructure;
	
	GPIO_InitTypeDef  GPIO_InitStructure;

	//初始化IO口
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA|RCC_APB2Periph_GPIOB,ENABLE);//使能PORTA,PORTB时钟

	GPIO_InitStructure.GPIO_Pin  = GPIO_Pin_3;//
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //设置成上拉输入
 	GPIO_Init(GPIOA, &GPIO_InitStructure);//初始化PA.3

	GPIO_InitStructure.GPIO_Pin  = GPIO_Pin_12;//
	GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU; //设置成上拉输入
 	GPIO_Init(GPIOB, &GPIO_InitStructure);//初始化PB.12
	
	
	//初始化外部中断
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO,ENABLE); //开启 AFIO 时钟
	
	//GPIOA.3 中断线以及中断初始化配置,边沿触发
	GPIO_EXTILineConfig(GPIO_PortSourceGPIOA,GPIO_PinSource3);
	EXTI_InitStructure.EXTI_Line=EXTI_Line3;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising_Falling; //边沿触发
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure); //初始化中断线参数
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI3_IRQn; //使能外部中断通道
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x02; //抢占优先级 2，
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x01; //子优先级 2
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE; //使能外部中断通道
	NVIC_Init(&NVIC_InitStructure);//初始化中断通道
	
	//GPIOB.12 中断线以及中断初始化配置,边沿触发
	GPIO_EXTILineConfig(GPIO_PortSourceGPIOB,GPIO_PinSource12);
	EXTI_InitStructure.EXTI_Line=EXTI_Line12;
	EXTI_InitStructure.EXTI_Mode = EXTI_Mode_Interrupt;
	EXTI_InitStructure.EXTI_Trigger = EXTI_Trigger_Rising_Falling; //边沿触发
	EXTI_InitStructure.EXTI_LineCmd = ENABLE;
	EXTI_Init(&EXTI_InitStructure); //初始化中断线参数
	
	NVIC_InitStructure.NVIC_IRQChannel = EXTI15_10_IRQn; //使能按键外部中断通道
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 0x02; //抢占优先级 2，
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0x02; //子优先级 2
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE; //使能外部中断通道
	NVIC_Init(&NVIC_InitStructure);//初始化中断通道
}

void EXTI3_IRQHandler(void)
{
	if(INF1==0) //存在障碍
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
	
	if(INF1==1 && INF2==1) //障碍消失
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
//	if(INF1==0)	 	 //1号红外检测障碍
//	{				 
//		delay_ms(10);//消抖
//		if(INF1==0)  //表示有障碍
//		{
//			if(TIM2_begin==0)   //TIM2未开始计数
//			{
//				TIM_Cmd(TIM2, ENABLE); 
//				TIM2_begin=1;
//			}
//			
//		}
//		TIM_SetCounter(TIM5,0);
//	}
	EXTI_ClearITPendingBit(EXTI_Line3); //清除LINE3上的中断标志位  
}

void EXTI15_10_IRQHandler(void)
{
	if(INF2==0) //存在障碍
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
	
	if(INF1==1 && INF2==1) //障碍消失
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
	EXTI_ClearITPendingBit(EXTI_Line12); //清除LINE3上的中断标志位
}

int INFRARED_Scan(void)  //有障碍：1；  无障碍：0
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



 
