%% Clear workspace
%清理工作空间
clear
close all

%% Set Serial
%串口设置

try
    global strRec
    global strRec2
    strRec=[0 0 0];
    strRec2=[0 0 0];
    delete(instrfind);
    scom=serial('COM4'); 
    fclose(scom);
    scom2=serial('COM5');
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
frequ=[18.3 17 20.3 19 21 16.3 22.3 15.3]; 

%创建纹理
show_LOGO = imread('LOGO.jpg');
show_LOGO_ptr = Screen('MakeTexture', window, show_LOGO );
show_welcome = imread('1.jpg');
show_welcome_ptr = Screen('MakeTexture', window, show_welcome );
show_run = imread('RM.png');
show_run_ptr = Screen('MakeTexture', window, show_run );
show_brain = imread('brain.jpg');
show_brain_ptr = Screen('MakeTexture', window, show_brain);
show_photo = imread('timg.jpg');
show_photo_ptr = Screen('MakeTexture', window, show_photo);
show_S = imread('S.png');
show_S_ptr = Screen('MakeTexture', window, show_S);

% 刺激目标的位置及大小 上-右-下-左
a=150*x_center/960;
b=75*x_center/960;
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

N_brain=2*x_center/960;%缩小倍数

text_size=x_center/30;%字体大小

%刺激目标中心位置  箭头上-右-下-左-加号-减号-喇叭
Center=[x_center,a;x_center+y_center-a,y_center;x_center,y_center*2-a;x_center-y_center+a,y_center;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center/3-25*x_center/960;x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center*5/3+25*x_center/960;...
    wb+wc+100*x_center/960-100*x_center/960,y_center/3;wb+wc+100*x_center/960-100*x_center/960,y_center*5/3;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center+40*x_center/960];
p=[0,-a;b,0;c,0;c,d;-c,d;-c,0;-b,0];%箭头

pointlist(:,:,1)=Center(1,:)+p;                     %上箭头
pointlist(:,:,2)=Center(2,:)+p*[0,1;1,0].*[-1,1];   %右箭头
pointlist(:,:,3)=Center(3,:)+p.*[1,-1];             %下箭头
pointlist(:,:,4)=Center(4,:)+p*[0,1;1,0];           %左箭头
S1=Center(9,:)+[0,2*sa]+[-sc-sd,-sa+sb;sc+sd,-sa+sb;sc,sa-sb;-sc,sa-sb];
S2=Center(9,:)+[-sc-2*sd,-sa+sb;sc+2*sd,-sa+sb;sc+sd,sa-sb;-sc-sd,sa-sb];
S3=Center(9,:)+[0,-2*sa]+[-sc-3*sd,-sa+sb;sc+3*sd,-sa+sb;sc+2*sd,sa-sb;-sc-2*sd,sa-sb];

plus=Center(5,:)+[-wa,-wa;-wa,-wb;wa,-wb;wa,-wa;wb,-wa;wb,wa;wa,wa;wa,wb;-wa,wb;-wa,wa;-wb,wa;-wb,-wa];
minus=Center(6,:)+[-wb,-wa;wb,-wa;wb,wa;-wb,wa];
whistle=[Center(7,1)-ww,Center(7,2)-wh,Center(7,1)+ww,Center(7,2)+wh];
brain=[x_center-540/N_brain,y_center-308/N_brain,x_center+540/N_brain,y_center+308/N_brain];
stop=[Center(8,1)-wd,Center(8,2)-we,Center(8,1)+wd,Center(8,2)+we];
run=[S1(2,1)+25,S1(3,2)-151/2,S1(2,1)+162/2+25,S1(3,2)];
stopbutton=[-wd*1.732,-wd;0,-2*wd;wd*1.732,-wd;wd*1.732,wd;0,2*wd;-wd*1.732,wd]+Center(8,:);

%刺激频率
col = ones(3,40);
rea_col = zeros(40,216000);

for i = 1:length(frequ)
    for j = 1:216000 
        rea_col(i,j) = 0.5*255*(1+sin((2*pi*frequ(i))*(j/fre)+0.5*(i-1)*pi));
    end 
end

%按键定义
KbName('UnifyKeyNames');    %定义按键前最好都加上这一句
escapeKey = KbName('escape');

%% Performing
%开始实验
restart_flag=1;
while restart_flag
    Color=ones(8,3);
    Color(8,:)=[1,0,0];
    Timer=0;
    [KeyIsDown, secs, KeyCode] = KbCheck;
    [x,y,buttons,focus,valuators,valinfo]=GetMouse(window);
    Speed_flag=1;
    for i=1:85
        Screen('DrawTexture', window, show_welcome_ptr, [], [], 0, [], [], 3*i);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        if KeyIsDown||sum(buttons)
            break;
        end
    end
    while ~KeyIsDown&&~KeyCode(escapeKey)&&~sum(buttons)
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        WaitSecs(0.08);
    end
    while (KeyIsDown||sum(buttons))&&~KeyCode(escapeKey)&&~buttons(3)
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        WaitSecs(0.08);
    end
    if restart_flag
        try
            fopen(scom);
        end
    end
    fwrite(scom,85);
    fwrite(scom2,[00,13,10]);
    WaitSecs(0.01);
    fwrite(scom2,[09,13,10]);
    while ~KeyCode(escapeKey)&&~sum(buttons)
        [KeyIsDown, secs, KeyCode] = KbCheck;
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        Screen('DrawTexture', window, show_brain_ptr, [], brain, 0, [], [], 0.3*255);
        for i=1:4
            Screen('FillPoly', window, Color(i,:)*rea_col(i,indexflip),pointlist(:,:,i),0);
        end
        Screen('FillPoly', window, Color(5,:)*rea_col(5,indexflip),plus,0);
        Screen('FillPoly', window, Color(6,:)*rea_col(6,indexflip),minus,1);
        Screen('DrawTexture', window, show_photo_ptr, [], whistle, 0, [], [],Color(7,:)*rea_col(7,indexflip));
        Screen('FillPoly', window, Color(8,:)*rea_col(8,indexflip),stopbutton,1);
        Screen('DrawTexture', window, show_S_ptr, [], stop, 0, [], [], Color(8,:)*rea_col(8,indexflip));
        Screen('DrawTexture', window, show_run_ptr, [], run, 0, [], [], 255);
        Screen('FillPoly', window, 255, S1, 1);
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
        end
%         Screen('TextSize', window, text_size);
%         Screen('TextFont', window, 'Simsun');
%         Screen('DrawText',window,double('前'),pointlist(5,1,1)+text_size*0.1,pointlist(5,2,1),255);
%         Screen('DrawText',window,double('右'),pointlist(5,1,2)-text_size*2+text_size*0.2,pointlist(5,2,2),255);
%         Screen('DrawText',window,double('后'),pointlist(5,1,3)+text_size*0.1,pointlist(5,2,3)-text_size*2,255);
%         Screen('DrawText',window,double('左'),pointlist(5,1,4)+text_size*0.2,pointlist(5,2,4),255);
%         Screen('DrawText',window,double('加速'),Center(5,1)-text_size*1.7,plus(8,2)+text_size*0.5,255);
%         Screen('DrawText',window,double('减速'),Center(6,1)-text_size*1.7,minus(3,2)+text_size,255);
%         Screen('DrawText',window,double('鸣笛'),Center(7,1)-text_size*1.7,whistle(4),255);
%         Screen('DrawText',window,double('停车'),Center(8,1)-text_size*1.7,stopbutton(5,2),255);
%         Screen('DrawText',window,double('速'),Center(9,1)+text_size*2,Center(9,2)-text_size*2,255);
%         Screen('DrawText',window,double('度'),Center(9,1)+text_size*2,Center(9,2),255);
%         Screen('DrawTexture', window, show_LOGO_ptr, [], [1.2*x_center,1.8*y_center,1.2*x_center+0.2*y_center,2*y_center], 0, [], [], 255);
%         Screen('TextSize', window, text_size*1.5);
%         Screen('DrawText',window,double('SSVEP-BCI'),0.4*x_center,text_size*1.5,255);
%         Screen('DrawText',window,double('脑电轮椅'),1.15*x_center+0.2*y_center,text_size*1.5,255);
%         Screen('TextSize', window, text_size/2);
%         Screen('DrawText',window,double('仪器科学与光电工程学学院'),1.225*x_center+0.2*y_center,1.9*y_center-text_size/3,255);
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        indexflip=indexflip+1;
        if strRec(1)==85&&strRec(3)==10
            Color=ones(8,3);
            Color(8,:)=[1,0,0];
            if strRec(2)>=49&&strRec(2)<=56
                Color(strRec(2)-48,:)=[0,1,0];
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
        if Timer>=60
            Color=ones(8,3);
            Color(8,:)=[1,0,0];
            Timer=0;
        end
        Timer=Timer+1;
    end
    if buttons(1)
        fwrite(scom,86);
        fclose(scom);
        restart_flag=1;
    else
        restart_flag=0;
    end
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