%% Clear workspace
%�������ռ�
clear
close all

%% Set Serial
%��������

%scomΪ���������ͨ�Ŵ��ڣ�������9600
%����55��������ʼ���У�����56��������ֹͣ����,����57���������Ե���ֵģʽ����
%�������ݸ�ʽΪ[55,XX,0A],XXΪ����λ��30-38�ֱ��ʾ�������Ϊ��Ŀ�ꡢǰ������ת�����ˡ���ת�����١����١����ѡ�ͣ��

%scom2Ϊ����λ��ͨ�Ŵ��ڣ�������115200
%�������ݸ�ʽΪ[XX,0D,0A]��XXΪ����λ��00-09�ֱ��ʾָ��ͣ����ǰ������ת�����ˡ���ת�����١����١����ѡ���ʼ��������
%����ָ�����λ���ظ�[XX,0A]
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
    error("���ڴ���");
end

%% Screen setup
%��Ļ����

% ����ͬ����飬ȷ��ʵ��̼���ȷ�İ��ո�����ʱ�����
Screen('Preference', 'SkipSyncTests', 1);

%��ȡ��ʾ�������0Ϊȫ����1=��һ����ʾ�� 2=�ڶ�����ʾ���������Դ�����
screens = Screen('Screens');

% Select the external screen if it is present, else revert to the native
screenNumber = max(screens);

% Open an on screen window and color it grey
% window�Ǵ����Ĵ��ڷ��صĴ��ھ����windowRect�ǳߴ�
[window, windowRect] = Screen('Openwindow', screenNumber, [0 0 0]); 

% Query the frame duration
% ��ȡָ��ҳ�棨window������ǰ��̨�����л�����ʱ��Ĺ���ֵ����Ϊ��λ��������ʾ����Ļˢ��һ֡���õ�ʱ��
time_interval = Screen('GetFlipInterval',window);

% Get the centre coordinate of the window in pixels
% �õ�windowRect��ʾ�ľ��ε��������꣨������Ϊ��λ��
[x_center, y_center] = RectCenter(windowRect);

% The first time to complete the screen
% �л�ǰ̨�ͺ�̨���壬��time_intervalʱ�����׸��ع�����л��������֡����
vbl = Screen('Flip', window, time_interval, 0); 

% frequency
% ��ȡˢ��Ƶ��
fre = Screen('FrameRate',window);

% Ԥ��ֵ 
indexflip = 1;

%�������
HideCursor;

%% Fixed parameter
%ʵ�����

% ����̼�Ƶ��
frequ=[18.3 17 20.3 19.3 21 16.3 22.3 15.3]-1; 

%��������
show_welcome = imread('welcome.jpg');%��������ͼ��
show_welcome_ptr = Screen('MakeTexture', window, show_welcome );
show_background = imread('background.png');%����ͼ��
show_background_ptr = Screen('MakeTexture', window, show_background );
show_whistle = imread('whistle.jpg');%���Ѱ�ť
show_whistle_ptr = Screen('MakeTexture', window, show_whistle);
show_S = imread('S.png');%ͣ����ť
show_S_ptr = Screen('MakeTexture', window, show_S);

%���¾�Ϊ���̼�Ŀ����״λ�ò���
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

%�̼�Ŀ������λ��  ��ͷ��-��-��-��-�Ӻ�-����-����-�ٶ���
Center=[x_center,1.2*a;x_center+y_center-1.2*a,y_center;xcenter,y_center*2-1.2*a;x_center-y_center+1.2*a,y_center;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center/3-25*x_center/960;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center*5/3+25*x_center/960+wc;...
    1.2*wb+100*x_center/960-100*x_center/960,y_center/3;...
    1.2*wb+100*x_center/960-100*x_center/960,y_center*5/3+wc;...
    x_center*2-wb-wc-100*x_center/960+100*x_center/960,y_center+40*x_center/960];

p=[0,-a;b,0;c,0;c,d;-c,d;-c,0;-b,0];%��ͷ

pointlist(:,:,1)=Center(1,:)+p;                     %�ϼ�ͷ
pointlist(:,:,2)=Center(2,:)+p*[0,1;1,0].*[-1,1];   %�Ҽ�ͷ
pointlist(:,:,3)=Center(3,:)+p.*[1,-1];             %�¼�ͷ
pointlist(:,:,4)=Center(4,:)+p*[0,1;1,0];           %���ͷ

%�ٶ���
S1=Center(9,:)+[0,2*sa]+[-sc-sd,-sa+sb;sc+sd,-sa+sb;sc,sa-sb;-sc,sa-sb];
S2=Center(9,:)+[-sc-2*sd,-sa+sb;sc+2*sd,-sa+sb;sc+sd,sa-sb;-sc-sd,sa-sb];
S3=Center(9,:)+[0,-2*sa]+[-sc-3*sd,-sa+sb;sc+3*sd,-sa+sb;sc+2*sd,sa-sb;-sc-2*sd,sa-sb];

%�����̼�Ŀ��λ��
plus_position=Center(5,:)+[-wa,-wa;-wa,-wb;wa,-wb;wa,-wa;wb,-wa;wb,wa;wa,wa;wa,wb;-wa,wb;-wa,wa;-wb,wa;-wb,-wa];
minus_position=Center(6,:)+[-wb,1.2*-wa;wb,1.2*-wa;wb,1.2*wa;-wb,1.2*wa];
whistle_position=[Center(7,1)-ww,Center(7,2)-wh,Center(7,1)+ww,Center(7,2)+wh];
stop_position=[Center(8,1)-wd,Center(8,2)-we,Center(8,1)+wd,Center(8,2)+we];
stopbutton_position=[-wd*1.732,-wd;0,-2*wd;wd*1.732,-wd;wd*1.732,wd;0,2*wd;-wd*1.732,wd]+Center(8,:);

%���ɴ̼�Ƶ�ʵ����ұ��룬����ΪһСʱ
col = ones(3,40);
rea_col = zeros(40,216000);
for i = 1:length(frequ)
    for j = 1:216000 
        rea_col(i,j) = 0.5*255*(1+sin((2*pi*frequ(i))*(j/fre)+0.5*(i-1)*pi));
    end 
end

%��������
KbName('UnifyKeyNames');
escapeKey = KbName('escape');

%������Ƶ������
%����Ϊǰ������ת�����ˡ���ת�����١����١����ѡ�ͣ��
[m1,~]=audioread('��������1\1.mp3'); 
[m2,~]=audioread('��������1\2.mp3'); 
[m3,~]=audioread('��������1\3.mp3'); 
[m4,~]=audioread('��������1\4.mp3'); 
[m5,~]=audioread('��������1\5.mp3'); 
[m6,~]=audioread('��������1\6.mp3'); 
[m7,~]=audioread('��������1\7.mp3'); 
[m8,fs]=audioread('��������1\8.mp3'); 
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
%��ʼʵ��
%Ϊ�õ��̼��������ˢ�µ�ͬʱ������Ƶ��ʹ������Ƶ������audioplayer�����ڿ�����ر���Ƶ������ʱ�������Ե�֡
now_flag=0;%��ǰ״̬
while 1
    Color=ones(8,3);%�̼�Ŀ����ɫ
    Color(8,:)=[1,0,0];
    Timer=0;%Ŀ����̺��ʱ
    [KeyIsDown, secs, KeyCode] = KbCheck;
    [x,y,buttons,focus,valuators,valinfo]=GetMouse(window);%��ȡ�������״̬
    Speed_flag=1;
    for i=1:85
        Screen('DrawTexture', window, show_welcome_ptr, [], [], 0, [], [], 3*i);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        [x,y,buttons,focus,valuators,vailnfo]=GetMouse(window);
        [KeyIsDown, secs, KeyCode] = KbCheck;
        if KeyIsDown||sum(buttons)
            break;
        end
    end%��������
    Is_lowthreshold=0;%�Ƿ�Ϊ����ֵģʽ
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
    end%�ȴ��������룬esc/�Ҽ��˳��̼����棬�м��������ֵģʽ��������������ģʽ
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
        end%�������ֵģʽʱ��������������Ϊ����
    else
        fwrite(scom,85);
    end
    fwrite(scom2,[00,13,10]);
    WaitSecs(0.01);
    fwrite(scom2,[09,13,10]);%��ʼ����λ�����������ٶ�����Ϊ���ֵ
    while ~KeyCode(escapeKey)&&~sum(buttons)
        if now_flag~=0&&Timer==1
            play(player(now_flag));
        end%Ϊ���͵�֡���ڻ�ȡ�������������һ֡�򿪲�����
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
        end%�ٶ���
        Screen('DrawingFinished', window);
        vbl = Screen('Flip', window, vbl + 0.5 * time_interval);
        indexflip=indexflip+1;
        if (indexflip>216000)
            indexflip=1;
        end%�������ұ�����������ʱ����indexflip
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
                            error('ARMӦ��ʱ��');
                        end
                    end
                end
            else
                if strRec(2)~=48
                    sca;
                    fclose(scom);
                    fwrite(scom2,[00,13,10]);
                    fclose(scom2);
                    error('�����ڸô̼�Ŀ�꣡');
                end
            end
            strRec=[0,0,0];
        else
            if sum(strRec)~=0
                sca;
                fclose(scom);
                fwrite(scom2,[00,13,10]);
                fclose(scom2);
                error('ͨ�Ÿ�ʽ����');
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
            end%����1.5���ԭ
        end
    end
    if buttons(1)
        fwrite(scom,86);
        fclose(scom);
    else
        break;
    end%����ص��������棬�Ҽ��˳��̼����档
end
sca;
fwrite(scom,86);
fclose(scom);
fwrite(scom2,[00,13,10]);
fclose(scom2);

%% Functions
%���ڻص�����

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