#include "led.h"
#include "delay.h"
#include "key.h"
#include "sys.h"
#include "usart.h"
#include "timer.h"
#include "IO.h"
#include "infrared.h"
 
/************************************************
���ο��Ƴ���
V2ͨ������ǰ�󣬽ӻ��ߣ�TIM_SetCompare2
V1ͨ���������ң������ߣ�TIM_SetCompare1
���룺
0x00:ֹͣ����ʼ״̬
0x01:ǰ��
0x03:����
0x04:��ת
0x02:��ת
0x05:�ٶȼ�һ
0x06:�ٶȼ�һ
0x07:����
0x09:�ٶ�����
ͨ��Э��
ARM->����: xx 0a
����->ARM: xx 0d 0a
IO����
SPEED_UP PBout(13)
SPEED_DOWN PBout(14)
HORN PBout(15)
************************************************/

/******
PWMƽ���Ϊ250����ת�ͺ������ͣ���ת��ǰ�����ߣ���250���Խ���ٶ�Խ��
��ʵ�������˶������������PWM�������ɻ�����������
******/
u16 front_speed=310;  //ǰ��PWMֵ
u16 left_speed_1=140-10;   //��תPWMֵ  1����������ԭ�����������PWM
u16 right_speed_1=350+10;  //��תPWMֵ
u16 left_speed=155;   //��תPWMֵ
u16 right_speed=335;  //��תPWMֵ
u16 back_speed=190;   //����PWMֵ

/*****************************************************/

u16 delta_front_speed=10;
u16 delta_back_speed=10;
u16 delta_turn_speed=10;
u16 PWM_delay=5; //ÿ��PWM���Ƽ��ʱ�䣬ms
u16 wheel_status=0;  //����״̬
u16 wheel_status_before=0;  //���ϰ�ǰ����״̬
u16 temp=0;
u16 change_flag=0;
u16 data_received=0; //�յ���ִ��ָ��
u16 turn_time=1600;  //ǰ����ת�����ʱ�䣬ms
u16 speed_rank=1; //�ٶȵȼ�
u16 temp;
u16 barrier_time=200; //�ϰ�����ʱ�䣬��ֹ�˹���ͣ����ms
extern int barrier_flag;

void PWM_control(u8 channel,u16 speed,u16 speed_wish);  //PWM������ٳ���,speed:ԭ�ٶ�,speed_wish�����ٶ�


	
 int main(void)
 {		
	u8 t=0;	 
	u16 len;
	
	delay_init();	    	 //��ʱ������ʼ��	  
	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_2); 	 //����NVIC�жϷ���2:2λ��ռ���ȼ���2λ��Ӧ���ȼ�
	uart_init(115200);	 //���ڳ�ʼ��Ϊ115200
	LED_Init();			     //LED�˿ڳ�ʼ��
	SystemInit(); //���³�ʼ��ʱ�ӣ������񲻶ԡ� 
	IO_Init();
	INFRARED_Init();

	TIM2_Int_Init(10*barrier_time,7199); //TIM2Ƶ��=72000000/7200=10Khz
	 
	// 	TIM3_PWM_Init(899,0);	 //����Ƶ��PWMƵ��=72000000/900=80Khz
	TIM3_PWM_Init(500,1);	 //2��Ƶ��PWMƵ��=72000000/500/2=72Khz
	TIM_SetCompare1(TIM3,250);
	TIM_SetCompare2(TIM3,250);	
	 
	
	 while(1)
	{
		t++;
		
		if(USART_RX_STA&0x8000)
		{					   
			len=USART_RX_STA&0x3fff;//�õ��˴ν��յ������ݳ���
			data_received=USART_RX_BUF[0];
//			printf("\r\n�����͵���ϢΪ:\r\n\r\n");
			if(barrier_flag==0)  //������ϰ�����ԭ����ִ��
			{
				if(USART_RX_BUF[0]==0x00) //ֹͣ����ʼ��
				{
	//				PWM_control(1,250);
	//				PWM_control(2,250);				
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,250);
					wheel_status=0;
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x01) //ǰ��
				{
	//				PWM_control(1,250);
	//				PWM_control(2,front_speed);	
					if(wheel_status!=3)
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,front_speed);
						wheel_status=1;
					}
					else if(wheel_status==3) //���ε���ʱ�����ξ�ֹ
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,250);
						wheel_status=0;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x03) //����
				{
	//				PWM_control(1,250);
	//				PWM_control(2,200);
					if(wheel_status==3)  //���ε���ʱ�����ε���
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
						wheel_status=0;
					}
					else if(wheel_status==0)  //���ξ�ֹʱ�����ε���
					{					
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
						wheel_status=3;
					}
					else  //�����˶�ʱ�����ξ�ֹ
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,250);
						wheel_status=0;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x04) //��ת
				{
	//				PWM_control(1,150);
	//				PWM_control(2,250);
					if(wheel_status==1) //����ǰ��ʱ������ת��
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
					else if(wheel_status==3) //���ε���ʱ������ת��
					{
						TIM_SetCompare1(TIM3,left_speed);
						TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
						for(temp=turn_time;temp>0;temp-=100)
							delay_ms(100);
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
					}
					else if(wheel_status==0 && speed_rank==1) //���ξ�ֹʱ����ǰ����ת�䣬��ֹ����������
					{
						/*PWM_control(1,250,left_speed-50);
						//PWM_control(2,250,front_speed-delta_front_speed);
						delay_ms(1500);
						//PWM_control(2,front_speed-delta_front_speed,250);*/
						PWM_control(1,250,left_speed_1);
						wheel_status=4;
					}
					else  //�������ʱ��ԭ��ת��
					{
						TIM_SetCompare1(TIM3,left_speed);
						TIM_SetCompare2(TIM3,250);
						wheel_status=4;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x02) //��ת
				{
	//				PWM_control(1,350);
	//				PWM_control(2,250);
					if(wheel_status==1) //����ǰ��ʱ������ת��
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
					else if(wheel_status==3) //���ε���ʱ������ת��
					{
						TIM_SetCompare1(TIM3,right_speed);
						TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
						for(temp=turn_time;temp>0;temp-=100)
							delay_ms(100);
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
					}
					else if(wheel_status==0 && speed_rank==1) //���ξ�ֹʱ����ǰ����ת�䣬��ֹ����������
					{
						/*PWM_control(1,250,right_speed+50);
						//PWM_control(2,250,300);
						delay_ms(1500);*/
						//PWM_control(2,front_speed-delta_front_speed,250);
						PWM_control(1,250,right_speed_1);
						wheel_status=2;
					}
					else
					{
						TIM_SetCompare1(TIM3,right_speed);
						TIM_SetCompare2(TIM3,250);
						wheel_status=2;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x05) //�ٶȼ�һ
				{
	//================���������ٶ�===========================================	
					SPEED_UP=~SPEED_UP;
					delay_ms(100);
					SPEED_UP=~SPEED_UP;
					speed_rank++;
	//=======================================================================				
				
	////==============PWMռ�ձȿ����ٶ�========================================				
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
				else if(USART_RX_BUF[0]==0x06) //�ٶȼ�һ
				{
	//================���������ٶ�===========================================
					SPEED_DOWN=!SPEED_DOWN;
					delay_ms(100);
					SPEED_DOWN=!SPEED_DOWN;
					speed_rank--;
	//=======================================================================
					
	////==============PWMռ�ձȿ����ٶ�========================================				
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
				else if(USART_RX_BUF[0]==0x07) //����
				{
					HORN=!HORN;			
					delay_ms(1000);				
					HORN=!HORN;
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x09) //�ٶ�����
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
			}
			
			
			
			if(barrier_flag==1)  //������ϰ�
			{
				if(wheel_status==1)
				{
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,250);
					wheel_status=0;
					LED0=!LED0;
				}
					
				if(USART_RX_BUF[0]==0x00) //ֹͣ����ʼ��
				{
	//				PWM_control(1,250);
	//				PWM_control(2,250);				
					TIM_SetCompare1(TIM3,250);
					TIM_SetCompare2(TIM3,250);
					wheel_status=0;
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x01) //ǰ��
				{
					if(wheel_status==3) //���ε���ʱ�����ξ�ֹ
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,250);
						wheel_status=0;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x03) //����
				{
	//				PWM_control(1,250);
	//				PWM_control(2,200);
					if(wheel_status==3)  //���ε���ʱ�����ε���
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
						wheel_status=0;
					}
					else if(wheel_status==0)  //���ξ�ֹʱ�����ε���
					{					
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
						wheel_status=3;
					}
					else  //�����˶�ʱ�����ξ�ֹ
					{
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,250);
						wheel_status=0;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x04) //��ת
				{

					if(wheel_status==3) //���ε���ʱ������ת��
					{
						TIM_SetCompare1(TIM3,left_speed);
						TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
						for(temp=turn_time;temp>0;temp-=100)
							delay_ms(100);
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
					}
					else if(wheel_status==0 && speed_rank==1) //���ξ�ֹʱ����ǰ����ת�䣬��ֹ����������
					{
						PWM_control(1,250,left_speed_1);
						wheel_status=4;
					}
					else  //�������ʱ��ԭ��ת��
					{
						TIM_SetCompare1(TIM3,left_speed);
						TIM_SetCompare2(TIM3,250);
						wheel_status=4;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x02) //��ת
				{

					if(wheel_status==3) //���ε���ʱ������ת��
					{
						TIM_SetCompare1(TIM3,right_speed);
						TIM_SetCompare2(TIM3,back_speed+delta_back_speed);
						for(temp=turn_time;temp>0;temp-=100)
							delay_ms(100);
						TIM_SetCompare1(TIM3,250);
						TIM_SetCompare2(TIM3,back_speed);
					}
					else if(wheel_status==0 && speed_rank==1) //���ξ�ֹʱ����ǰ����ת�䣬��ֹ����������
					{
						PWM_control(1,250,right_speed_1);
						wheel_status=2;
					}
					else
					{
						TIM_SetCompare1(TIM3,right_speed);
						TIM_SetCompare2(TIM3,250);
						wheel_status=2;
					}
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x05) //�ٶȼ�һ
				{
	//================���������ٶ�===========================================	
					SPEED_UP=~SPEED_UP;
					delay_ms(100);
					SPEED_UP=~SPEED_UP;
					speed_rank++;
	//=======================================================================				
				
	////==============PWMռ�ձȿ����ٶ�========================================				
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
				else if(USART_RX_BUF[0]==0x06) //�ٶȼ�һ
				{
	//================���������ٶ�===========================================
					SPEED_DOWN=!SPEED_DOWN;
					delay_ms(100);
					SPEED_DOWN=!SPEED_DOWN;
					speed_rank--;
	//=======================================================================
					
	////==============PWMռ�ձȿ����ٶ�========================================				
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
				else if(USART_RX_BUF[0]==0x07) //����
				{
					HORN=!HORN;			
					delay_ms(1000);				
					HORN=!HORN;
					LED0=!LED0;
				}
				else if(USART_RX_BUF[0]==0x09) //�ٶ�����
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
			}
			
			for(t=0;t<len;t++)
			{
				USART_SendData(USART1, USART_RX_BUF[t]);//�򴮿�1��������
				while(USART_GetFlagStatus(USART1,USART_FLAG_TC)!=SET);//�ȴ����ͽ���
			}
			printf("\n");//���뻻��
			USART_RX_STA=0;
		} 
 		delay_ms(10);
		
		if(temp!=wheel_status)
		{
			wheel_status_before=temp;
		}
		temp=wheel_status;
		
	}
		   
		 
 }
 
 
 void PWM_control(u8 channel,u16 speed,u16 speed_wish)  //PWM������ٳ���,speed:ԭ�ٶ�,speed_wish�����ٶ�
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
