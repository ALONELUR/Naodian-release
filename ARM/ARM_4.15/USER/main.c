#include "led.h"
#include "delay.h"
#include "key.h"
#include "sys.h"
#include "usart.h"
#include "timer.h"
#include "IO.h"
 
/************************************************
轮椅控制程序
V2通道控制前后，接黄线，TIM_SetCompare2
V1通道控制左右，接绿线，TIM_SetCompare1
编码：
0x00:停止，初始状态
0x01:前进
0x03:后退
0x04:左转
0x02:右转
0x05:速度加一
0x06:速度减一
0x07:喇叭
0x09:速度重置
通信协议
ARM->电脑: xx 0a
电脑->ARM: xx 0d 0a
IO连接
SPEED_UP PBout(13)
SPEED_DOWN PBout(14)
HORN PBout(15)
************************************************/

u16 front_speed=310;  //前进PWM值
u16 left_speed=150;   //左转PWM值
u16 right_speed=350;  //右转PWM值
u16 back_speed=190;   //倒车PWM值
u16 delta_front_speed=10;
u16 delta_back_speed=10;
u16 delta_turn_speed=10;
u16 PWM_delay=5; //每次PWM控制间隔时间，ms
u16 wheel_status=0;  //轮椅状态
u16 turn_time=1200;  //前进中转弯持续时间，ms
u16 temp;


void PWM_control(u8 channel,u16 speed,u16 speed_wish)  //PWM缓变调速程序,speed:原速度,speed_wish期望速度
{
	int temp=0;
	if(speed<speed_wish)
	{
		temp=speed+10;
		for(;temp<=speed_wish;temp+=10)
		{
			switch(channel)
			{
				case 1 :
					TIM_SetCompare1(TIM3,temp);
				break;
				case 2:
					TIM_SetCompare2(TIM3,temp);
				break;
			}
			delay_ms(PWM_delay);
		}
		
	}
	else if(speed>speed_wish)
	{
		temp=speed-10;
		for(;temp>=speed_wish;temp-=10)
		{
			switch(channel)
			{
				case 1 :
					TIM_SetCompare1(TIM3,temp);
				break;
				case 2:
					TIM_SetCompare2(TIM3,temp);
				break;
			}
			delay_ms(PWM_delay);
		}
		speed=temp;
	}
	else 
		return;	
}
	
 int main(void)
 {		
	u8 t=0;	 
	u16 len;


	delay_init();	    	 //延时函数初始化	  
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2); 	 //设置NVIC中断分组2:2位抢占优先级，2位响应优先级
	uart_init(115200);	 //串口初始化为115200
	LED_Init();			     //LED端口初始化
	SystemInit(); //重新初始化时钟，否则晶振不对。 
	IO_Init();

	// 	TIM3_PWM_Init(899,0);	 //不分频。PWM频率=72000000/900=80Khz
	TIM3_PWM_Init(500,1);	 //2分频。PWM频率=72000000/330/2=109Khz
	TIM_SetCompare1(TIM3,250);
	TIM_SetCompare2(TIM3,250);	
	
	 while(1)
	{
		t++;
		
		if(USART_RX_STA&0x8000)
		{					   
			len=USART_RX_STA&0x3fff;//得到此次接收到的数据长度
//			printf("\r\n您发送的消息为:\r\n\r\n");
			if(USART_RX_BUF[0]==0x00) //停止，初始化
			{
//				PWM_control(1,250);
//				PWM_control(2,250);				
				TIM_SetCompare1(TIM3,250);
				TIM_SetCompare2(TIM3,250);
				wheel_status=0;
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x01) //前进
			{
//				PWM_control(1,250);
//				PWM_control(2,front_speed);	
				if(wheel_status!=3)
				{
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,front_speed);
					wheel_status=1;
				}
				else if(wheel_status==3) //轮椅倒车时，轮椅静止
				{
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,250);
					wheel_status=0;
				}
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x03) //后退
			{
//				PWM_control(1,250);
//				PWM_control(2,200);
				if(wheel_status==3)  //轮椅倒车时，轮椅倒车
				{
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,back_speed);
					wheel_status=0;
				}
				else if(wheel_status==0)  //轮椅静止时，轮椅倒车
				{					
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,back_speed);
					wheel_status=3;
				}
				else  //轮椅运动时，轮椅静止
				{
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,250);
					wheel_status=0;
				}
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x04) //左转
			{
//				PWM_control(1,150);
//				PWM_control(2,250);
				if(wheel_status==1) //轮椅前进时，差速转弯
				{
					PWM_control(1,250,left_speed-delta_turn_speed);
					//TIM_SetCompare1(TIM3,left_speed-delta_turn_speed);
					TIM_SetCompare2(TIM3,front_speed-delta_front_speed);
					for(temp=turn_time;temp>0;temp-=100)
						delay_ms(100);
					PWM_control(1,left_speed-delta_turn_speed,250);
					//TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,front_speed);
				}
				else if(wheel_status==3) //轮椅倒车时，差速转弯
				{
					TIM_SetCompare1(TIM3,left_speed);
					TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
					for(temp=turn_time;temp>0;temp-=100)
						delay_ms(100);
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,back_speed);
				}
				else  //其余情况时，原地转弯
				{
					TIM_SetCompare1(TIM3,left_speed);
					TIM_SetCompare2(TIM3,250);
					wheel_status=4;
				}
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x02) //右转
			{
//				PWM_control(1,350);
//				PWM_control(2,250);
				if(wheel_status==1) //轮椅前进时，差速转弯
				{
					PWM_control(1,250,right_speed+delta_turn_speed);
					//TIM_SetCompare1(TIM3,right_speed+delta_turn_speed);
					TIM_SetCompare2(TIM3,front_speed-delta_front_speed);
					for(temp=turn_time;temp>0;temp-=100)
						delay_ms(100);
					PWM_control(1,right_speed+delta_turn_speed,250);
					//TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,front_speed);
				}
				else if(wheel_status==3) //轮椅倒车时，差速转弯
				{
					TIM_SetCompare1(TIM3,right_speed);
					TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
					for(temp=turn_time;temp>0;temp-=100)
						delay_ms(100);
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,back_speed);
				}
				else
				{
					TIM_SetCompare1(TIM3,right_speed);
					TIM_SetCompare2(TIM3,250);
					wheel_status=2;
				}
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x05) //速度加一
			{
//================按键控制速度===========================================	
				SPEED_UP=~SPEED_UP;
				delay_ms(100);
				SPEED_UP=~SPEED_UP;
//=======================================================================				
			
////==============PWM占空比控制速度========================================				
//				if( front_speed<449)
//				{
//					front_speed+=50;
//					printf("speed up");
//					PWM_control(2,front_speed);
//				}
//				else if(front_speed>450)
//				{
//					printf("The speed of wheelchair has been the maximum.");
//				}
////====================================================================
				
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x06) //速度减一
			{
//================按键控制速度===========================================
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
//=======================================================================
				
////==============PWM占空比控制速度========================================				
//				if(front_speed>351)
//				{
//					front_speed-=50;
//					printf("speed down");
//					TIM_SetCompare1(TIM3,front_speed);
//				}				
//				else if(front_speed<351)
//				{
//					printf("The speed of wheelchair has been the minimum.");
//				}
////=======================================================================					
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x07) //喇叭
			{
				HORN=!HORN;			
				delay_ms(1000);				
				HORN=!HORN;
				LED0=!LED0;
			}
			else if(USART_RX_BUF[0]==0x09) //速度重置
			{
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
				delay_ms(100);
				SPEED_DOWN=!SPEED_DOWN;
			}
			
			for(t=0;t<len;t++)
			{
				USART_SendData(USART1, USART_RX_BUF[t]);//向串口1发送数据
				while(USART_GetFlagStatus(USART1,USART_FLAG_TC)!=SET);//等待发送结束
			}
			printf("\n");//插入换行
			USART_RX_STA=0;
		} 
 		delay_ms(10);
	
		
	}
		   
		 
 }

