%% Clear workspace
%清理工作空间
clear
close all

%% Set Serial
%串口设置

%scom为与分析程序通信串口，波特率9600
%发送55分析程序开始运行，发送56分析程序停止运行,发送57分析程序以低阈值模式运行
%接收数据格式为[55,XX,0A],XX为数据位，30-38分别表示分析结果为无目标、前进、右转、后退、左转、加速、减速、鸣笛、停车

%scom2为与下位机通信串口，波特率115200
%发送数据格式为[XX,0D,0A]，XX为数据位，00-09分别表示指令停车、前进、右转、后退、左转、加速、减速、鸣笛、初始化控制器
%发送指令后下位机回复[XX,0A]
try
    global strRec
    global strRec2
    strRec=[0 0 0];
    strRec2=[0 0 0];
    delete(instrfind);
    scom=serial('COM5'); 
    fclose(scom);
    scom2=serial('COM4');
    fclose(scom2);
    baud_rate = 9600;
    baud_rate2 = 115200;
    jiaoyan = 'none';
    data_bits = 8;
    stop_bits = 1;
    set(scom, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
        data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 1,...
        'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn',{@bytes},...
        'TimerPeriod', 0.05);
    set(scom2, 'BaudRate', baud_rate2, 'Parity', jiaoyan, 'DataBits',...
        data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 1,...
        'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn',{@bytes2},...
        'TimerPeriod', 0.05);
    fopen(scom);
    fopen(scom2);
catch
    sca;
    error("串口错误！");
end

%% Screen setup
%屏幕设置

% 开启同步检查，确保实验刺激精确的按照给定的时间呈现
Screen('Preference', 'SkipSyncTests', 1);

%获取显示器情况，0为全屏，1=第一个显示器 2=第二个显示器。。。以此类推
screens = Screen('Screens');

% Select the external screen if it is present, else revert to the native
screenNumber = max(screens);

% Open an on screen window and color it grey
% window是创建的窗口返回的窗口句柄，windowRect是尺寸
[window, windowRect] = Screen('Openwindow', screenNumber, [0 0 0]); 

% Query the frame duration
% 获取指定页面（window）进行前后台缓冲切换所需时间的估计值（秒为单位），即显示器屏幕刷新一帧所用的时间
time_interval = Screen('GetFlipInterval',window);

% Get the centre coordinate of the window in pixels
% 得到windowRect表示的矩形的中心坐标（以像素为单位）
[x_center, y_center] = RectCenter(windowRect);

% The first time to complete the screen
% 切换前台和后台缓冲，在time_interval时间后的首个回归进行切换，并清除帧缓存
vbl = Screen('Flip', window, time_interval, 0); 

% frequency
% 获取刷新频率
fre = Screen('FrameRate',window);

% 预设值 
indexflip = 1;

%隐藏鼠标
HideCursor;

%% Fixed parameter
%实验参数

% 所需刺激频率
frequ=[18.3 17 20.3 19.3 21 16.3 22.3 15.3]-1; 

%创建纹理
show_welcome = imread('welcome.jpg');%启动界面图像
show_welcome_ptr = Screen('MakeTexture', window, show_welcome );
show_background = imread('background.png');%背景图像
show_background_ptr = Screen('MakeTexture', window, show_background );
show_whistle = imread('whistle.jpg');%鸣笛按钮
show_whistle_ptr = Screen('MakeTexture', window, show_whistle);
show_S = imread('S.png');%停车按钮
show_S_ptr = Screen('MakeTexture', window, show_S);

%以下均为各刺激目标形状位置参数
a=150*x_center/960;
b=90*x_center/960;
c=30*x_center/960;
d=100*x_center/960;
e=30*x_center/960;

wa=25*x_center/960;
wb=100*x_center/960;
wc=50*x_center/960;
wd=60*x_center/960;
we=75*x_center/960;
ww=100*x_center/960;
wh=100*x_center/960;

sa=80*x_center/960;
sb=16*x_center/960;
sc=10*x_center/960;
sd=5*x_center/960;

%刺激目标中心位置  箭头上-右-下-左-加号-减号-喇叭-速度条
Center=[x_center,1.2*a;x_center+y_center-1.2*a,y_center;xcenter,y_center*2-1.2*a;x_center-y_center+1.2*a,y_center;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center/3-25*x_center/960;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center*5/3+25*x_center/960+wc;...
    1.2*wb+100*x_center/960-100*x_center/960,y_center/3;...
    1.2*wb+100*x_center/960-100*x_center/960,y_center*5/3+wc;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center+40*x_center/960];

p=[0,-a;b,0;c,0;c,d;-c,d;-c,0;-b,0];%箭头

pointlist(:,:,1)=Center(1,:)+p;                     %上箭头
pointlist(:,:,2)=Center(2,:)+p*[0,1;1,0].*[-1,1];   %右箭头
pointlist(:,:,3)=Center(3,:)+p.*[1,-1];             %下箭头
pointlist(:,:,4)=Center(4,:)+p*[0,1;1,0];           %左箭头

%速度条
S1=Center(9,:)+[0,2*sa]+[-sc-sd,-sa+sb;sc+sd,-sa+sb;sc,sa-sb;-sc,sa-sb];
S2=Center(9,:)+[-sc-2*sd,-sa+sb;sc+2*sd,-sa+sb;sc+sd,sa-sb;-sc-sd,sa-sb];
S3=Center(9,:)+[0,-2*sa]+[-sc-3*sd,-sa+sb;sc+3*sd,-sa+sb;sc+2*sd,sa-sb;-sc-2*sd,sa-sb];

%其他刺激目标位置
plus_position=Center(5,:)+[-wa,-wa;-wa,-wb;wa,-wb;wa,-wa;wb,-wa;wb,wa;wa,wa;wa,wb;-wa,wb;-wa,wa;-wb,wa;-wb,-wa];
minus_position=Center(6,:)+[-wb,1.2*-wa;wb,1.2*-wa;wb,1.2*wa;-wb,1.2*wa];
whistle_position=[Center(7,1)-ww,Center(7,2)-wh,Center(7,1)+ww,Center(7,2)+wh];
stop_position=[Center(8,1)-wd,Center(8,2)-we,Center(8,1)+wd,Center(8,2)+we];
stopbutton_position=[-wd*1.732,-wd;0,-2*wd;wd*1.732,-wd;wd*1.732,wd;0,2*wd;-wd*1.732,wd]+Center(8,:);

%生成刺激频率的正弦编码，长度为一小时
col = ones(3,40);
rea_col = zeros(40,216000);
for i = 1:length(frequ)
    for j = 1:216000 
        rea_col(i,j) = 0.5*255*(1+sin((2*pi*frequ(i))*(j/fre)+0.5*(i-1)*pi));
    end 
end

%按键定义
KbName('UnifyKeyNames');
escapeKey = KbName('escape');

%创建音频播放器
%依次为前进、左转、后退、右转、加速、减速、鸣笛、停车
[m1,~]=audioread('轮椅语音1\1.mp3'); 
[m2,~]=audioread('轮椅语音1\2.mp3'); 
[m3,~]=audioread('轮椅语音1\3.mp3'); 
[m4,~]=audioread('轮椅语音1\4.mp3'); 
[m5,~]=audioread('轮椅语音1\5.mp3'); 
[m6,~]=audioread('轮椅语音1\6.mp3'); 
[m7,~]=audioread('轮椅语音1\7.mp3'); 
[m8,fs]=audioread('轮椅语音1\8.mp3'); 
m1=m1';
m2=m2';
m3=m3';
m4=m4';
m5=m5';
m6=m6';
m7=m7';
m8=m8';
player(1)=audioplayer(m1,fs);
player(2)=audioplayer(m2,fs);
player(3)=audioplayer(m3,fs);
player(4)=audioplayer(m4,fs);
player(5)=audioplayer(m5,fs);
player(6)=audioplayer(m6,fs);
player(7)=audioplayer(m7,fs);
player(8)=audioplayer(m8,fs);

%% Performing
%开始实验
%为得到刺激界面持续刷新的同时播放音频，使用了音频播放器audioplayer，但在开启或关闭音频播放器时具有明显掉帧
now_flag=0;%当前状态
while 1
    Color=ones(8,3);%刺激目标颜色
    Color(8,:)=[1,0,0];
    Timer=0;%目标变绿后记时
    [KeyIsDown, secs, KeyCode] = KbCheck;
    [x,y,buttons,focus,valuators,valinfo]=GetMouse(window);%获取键盘鼠标状态
    Speed_flag=1;
    for i=1:85
        Screen('DrawTexture', window, show_welcome_ptr, [], [], 0, [], [], 3*i);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        if KeyIsDown||sum(buttons)
            break;
        end
    end%启动界面
    Is_lowthreshold=0;%是否为低阈值模式
    while ~KeyIsDown&&~KeyCode(escapeKey)&&~sum(buttons)
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        WaitSecs(0.08);
        Is_lowthreshold=buttons(2);
    end
    while (KeyIsDown||sum(buttons))&&~KeyCode(escapeKey)&&~buttons(3)
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        WaitSecs(0.08);
    end%等待键鼠输入，esc/右键退出刺激界面，中键进入低阈值模式，其他进入正常模式
    try
        fopen(scom);
    end
    if(Is_lowthreshold)
        fwrite(scom,87);
        for i=1:85
            Screen('DrawTexture', window, show_welcome_ptr, [], [], 0, [], [], 255-3*i);
            vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
            [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
            [KeyIsDown, secs, KeyCode] = KbCheck;
            if KeyIsDown||sum(buttons)
                break;
            end
        end%进入低阈值模式时淡出启动界面作为区分
    else
        fwrite(scom,85);
    end
    fwrite(scom2,[00,13,10]);
    WaitSecs(0.01);
    fwrite(scom2,[09,13,10]);%初始化下位机，将轮椅速度设置为最低值
    while ~KeyCode(escapeKey)&&~sum(buttons)
        if now_flag~=0&&Timer==1
            play(player(now_flag));
        end%为降低掉帧，于获取到分析结果后下一帧打开播放器
        [KeyIsDown, secs, KeyCode] = KbCheck;
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        Screen('DrawTexture', window, show_background_ptr, [], [0,0,2*x_center,2*y_center], 0, [], []);
        for i=1:4
            Screen('FillPoly', window, Color(i,:)*rea_col(i,indexflip),pointlist(:,:,i),0);
        end
        Screen('FillPoly', window, Color(5,:)*rea_col(5,indexflip),plus_position,0);
        Screen('FillPoly', window, Color(6,:)*rea_col(6,indexflip),minus_position,1);
        Screen('DrawTexture', window, show_whistle_ptr, [], whistle_position, 0, [], [],Color(7,:)*rea_col(7,indexflip));
        Screen('FillPoly', window, Color(8,:)*rea_col(8,indexflip),stopbutton_position,1);
        Screen('DrawTexture', window, show_S_ptr, [], stop_position, 0, [], [], Color(8,:)*rea_col(8,indexflip));
        if Speed_flag>=2
            Screen('FillPoly', window, 255, S2, 1);
            if Speed_flag>=3
                Screen('FillPoly', window, 255, S3, 1);
            else
                Screen('FillPoly', window, 80, S3, 1);
            end
        else
            Screen('FillPoly', window, 80, S2, 1);
            Screen('FillPoly', window, 80, S3, 1);
        end%速度条
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        indexflip=indexflip+1;
        if (indexflip>216000)
            indexflip=1;
        end%到达正弦编码数组上限时重置indexflip
        if strRec(1)==85&&strRec(3)==10
            Color=ones(8,3);
            Color(8,:)=[1,0,0];
            if strRec(2)>=49&&strRec(2)<=56
                Color(strRec(2)-48,:)=[0,1,0];
                now_flag=strRec(2)-48;
                Timer=0;
                if strRec(2)==53
                    if Speed_flag~=3
                        Speed_flag=Speed_flag+1;
                        send_message=5;
                    else
                        send_message=-1;
                    end
                end
                if strRec(2)==54
                    if Speed_flag~=1
                        Speed_flag=Speed_flag-1;
                        send_message=6;
                    else
                        send_message=-1;
                    end
                end
                if strRec(2)~=53&&strRec(2)~=54
                    if strRec(2)==56
                        send_message=0;
                    else
                        send_message=strRec(2)-48;
                    end
                end
                if send_message~=-1
                    fwrite(scom2,[send_message,13,10]);
                    ans_time=0;
                    while strRec2~=[send_message;10]
                        ans_time=ans_time+1;
                        WaitSecs(0.01);
                        if ans_time>=10
                            sca;
                            fclose(scom1);
                            fwrite(scom2,[00,13,10])
                            fclose(scom2);
                            error('ARM应答超时！');
                        end
                    end
                end
            else
                if strRec(2)~=48
                    sca;
                    fclose(scom);
                    fwrite(scom2,[00,13,10]);
                    fclose(scom2);
                    error('不存在该刺激目标！');
                end
            end
            strRec=[0,0,0];
        else
            if sum(strRec)~=0
                sca;
                fclose(scom);
                fwrite(scom2,[00,13,10]);
                fclose(scom2);
                error('通信格式错误！');
            end
        end
        if now_flag
            Timer=Timer+1;
            if Timer>90
                Color=ones(8,3);
                Color(8,:)=[1,0,0];
                Timer=0;
                stop(player(now_flag));
                now_flag=0;
            end%变绿1.5秒后复原
        end
    end
    if buttons(1)
        fwrite(scom,86);
        fclose(scom);
    else
        break;
    end%左键回到启动界面，右键退出刺激界面。
end
sca;
fwrite(scom,86);
fclose(scom);
fwrite(scom2,[00,13,10]);
fclose(scom2);

%% Functions
%串口回调函数

function bytes(obj,~)
global strRec
n = get(obj, 'BytesAvailable');
    if n
        strRec = fread(obj,3);
    end
end

function bytes2(obj,~)
global strRec2
n = get(obj, 'BytesAvailable');
    if n
        strRec2 = fread(obj,2);
    end
end