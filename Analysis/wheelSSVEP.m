classdef  wheelSSVEP < handle
    properties (Access = public)
        Status;
        ReceiveT=[];
        AnalyT=[];

        %实验参数
        Gazetime;
        HarmNum;
        FilterNum;
        Tragetfreq;
        Samplefreq;
        Magnification;

        % 对比度算法阈值
        threshold;

        strRec;            %已接收的字符串
        %绘图句柄
        Timeplot;
        Freqplot;
        Ccaplot1;
        Ccaplot2;
        Ccaplot3;
        %通讯端口相关
        COMS;
        DataCom;
        TeleCom;
        scom;
        Num_Data_com_n;
        Num_Tele_com_n
        %实验数据
        RefData;
        AnalysisData;
        OrigtolData;
        TempData;
        OrigData;
        %实验结果
        TotalResult;
        IndivResult;

        %Mode
    end

    methods (Access = public)
        % 此函数是程序连续进行分析的程序
        function mode1(app)
             while ~get(app.scom, 'BytesAvailable')         
                app.receive(1);
                app.AnalysisData = app.TempData;
                app.OrigtolData = app.OrigData;
                app.analytical_data(1);
                app.judgeANDsend();
            end
           app.pause();
        end
        % 此函数是程序只进行一次分析的程序
        function mode2(app)
            app.receive(1);
            app.AnalysisData = app.TempData;
            app.OrigtolData = app.OrigData;
            app.analytical_data(2);
            app.Axesplot();
            app.judgeANDsend();
            app.pause();
        end

        % 此函数是接收数据，进行数据解析的函数
        function receive (app,divided)
            
            DATA_NUM = round(app.Gazetime * app.Samplefreq / divided);
            DATA_SIZE = 34;
            NUM = DATA_NUM * DATA_SIZE;
%             receive_data = ReadSerialPort18(app.Num_Data_com_n, NUM);
            receive_data = readlast20190528(app.Num_Data_com_n, NUM);

            if(receive_data(1)==205 && receive_data(end)==205)
                 msgbox('蓝牙数据错误');
                 app.pause();
            end
            temp_data = zeros(DATA_NUM,DATA_SIZE);
            ori_data = zeros(DATA_NUM, 8);
            down_data = zeros(2, 8);
            dec_data = zeros(floor(DATA_NUM/2),8);
            
            receiveNum = size(receive_data,2);
            iRec = 1;
            iTem = 1;
            
            while iRec <= receiveNum-DATA_SIZE+1
                if(receive_data(iRec) == 85 && receive_data(iRec + 1) == 85 && receive_data(iRec + 2) == 170 && receive_data(iRec + 3) == 170)%% 55 55 AA AA 帧头
                    temp_data(iTem,:) = receive_data(:,iRec:iRec+DATA_SIZE-1);
                    
                    for coloum_j = 1:1:8  %%依次取出8个通道数据
                        coloum_i = 3 * coloum_j + 6; 
                        temp_dec = dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                        temp_value = ((temp_dec*4.5/(2^23-1))./app.Magnification)*10^6;
                        ori_data(iTem, coloum_j)=temp_value;
                        down_data(mod(iTem, 2)+1, coloum_j) = temp_value;
                    end
                    if mod(iTem, 2) == 0
                        dec_data(floor(iTem/2), :) = mean(down_data); %% 降采样后取平均值
                    end
                    
                    iTem = iTem + 1;
                    iRec = iRec + DATA_SIZE;
                else
                    iRec = iRec + 1;
                end
            end
            
            dec_data = dec_data(1:floor(DATA_NUM/2),:);
            ori_data = ori_data(1:DATA_NUM,:);
            dec_data = app.expend(dec_data,floor((iTem-1)/2));
            ori_data = app.expend(ori_data,iTem-1);
            
            app.OrigData = ori_data;
            app.TempData = dec_data;
        end
        
        % 此程序是对数据进行分析的程序
        function analytical_data(app,mod)
            if mod==2
            % FFT
                N_fft=size(app.OrigtolData,1);
                if app.Gazetime>=1
                    num_tongdao = 1;
                    
                %     N_fft = 1024;
                    fre_fft=app.Samplefreq;
                    t=0:1/fre_fft:(N_fft-1)/fre_fft;
                    f=(0:N_fft-1)*fre_fft/N_fft; 
                     
                    Ori_S_FFT = fft(app.OrigtolData(:,num_tongdao)',N_fft); 
                %     Ori_S_FFT_abs = (abs(Ori_S_FFT));
                    figure(2);
                    app.Timeplot = plot(t, app.OrigtolData(:,num_tongdao)');
                    title('Time domain');
                    
                    Ori_S_ln=20*log10(abs(Ori_S_FFT));
                    figure(3);
                    app.Freqplot = plot(f(1,1:1:(floor(N_fft*80/fre_fft))), Ori_S_ln(1,1:1:(floor(N_fft*80/fre_fft))));
                    title('Frequency domain');
                end
            end 
            
            dec_data = app.AnalysisData;
            
            % 典型相关分析算法
            testdata = notch_filter(dec_data', app.Samplefreq / 2);
            app.TotalResult = cca_analysis(testdata, app.RefData, ...
                app.Tragetfreq);
        end

        % 对分析得到的相关系数进行判断，是否显著性足够高，并且发送结果
        function judgeANDsend(app)
            p = app.TotalResult;
            [~,index] = max(p);
            index = index(end);
%=============阈值判断法
%             if p(index)>0.42
%                 fwrite(app.scom, [85 48+index 10]);
%             else
%                 fwrite(app.scom, [85 48 10]);
%             end
            
%=============对比度判断法
            
            p = p - min(p);
            p = p ./ p(index);
            constract = p(index) / ((sum(p) - p(index))/(size(p,2)-1));
            if constract > app.threshold(index)
                fwrite(app.scom, [85 48+index 10]);
            else
                fwrite(app.scom, [85 48 10]);
            end
        end

        % 这个程序没啥用，还没有完成
        function  training(app)
            TrainNum = size(app.Tragetfreq, 2);
            for iTrain = 1 : TrainNum
                fwrite(app.scom, [85 64+index 10]);
                app.receive(0.5);
                app.AnalysisData = app.TempData;
                app.OrigtolData = app.OrigData;
                app.analytical_data(1);   
            end
        end
           
        % 程序是绘图程序
        function Axesplot(app)
                figure(1);
                app.Ccaplot1 = plot(1:length(app.TotalResult), app.TotalResult);
                title('Analysis Result');
        end
    
        % 生成参考信号的程序
        function reference(app,divided)
            DATA_NUM = round(app.Gazetime * app.Samplefreq / divided);
            SampleNum = floor(DATA_NUM / 2);
            app.RefData = cca_reference(app.Tragetfreq,app.Samplefreq/2, SampleNum*divided,[1,4]);
        end
    
        function pause(app)
            app.Status = "pause";
            fprintf('Finished\n');
        end
    end

    methods (Static)
            
        function bytes(obj,~,app)

            % 获取串口可获取的数据个数
            n = get(app.scom, 'BytesAvailable');
            % 若串口有数据，接收所有数据
            if n
                % 更新hasData参数，表明串口有数据需要显示
                % 读取串口数据
                app.strRec = fread(obj, 1);
                % 解析数据
                if app.strRec == 85
                    app.threshold = [2.8, 3, 3, 2.6, 2.8, 3, 2, 4]*1.4;%YWH
                    fprintf('Start as Mode 1\n');
                    app.reference(1);
                    app.mode1();
                elseif app.strRec == 86
                    app.threshold = [2.8, 3, 3, 2.6, 2.8, 3, 2, 4]*1.2;%YWH
                    fprintf('Start as Mode 2\n');
                   app.reference(1);
                   app.mode2();
                elseif app.strRec == 87
                    app.threshold = [2.8, 3, 3, 2.6, 2.8, 3, 2, 4]*1.1;%YWH
%                     app.threshold = ones(1,8);
                    fprintf('Start as Mode 3\n');
                    app.reference(1);
                    app.mode1();
                end
            end
        end
    
        function output = expend(data,iEnd)
            DATA_NUM = size(data,1);
            
            if iEnd ~= DATA_NUM
                temp = data(iEnd-(DATA_NUM-iEnd-1):iEnd,:);
                data(iEnd+1:DATA_NUM,:) = flip(temp,1);
            end
            output = data;
            
        end
    end


    % Callbacks that handle component events
    methods (Access = private)

        % 每次程序开始都会执行
        function init(app)
            
            app.Gazetime = 2.5;
            app.HarmNum = 2;
            app.FilterNum = 5;
            app.Tragetfreq = [18.3 17 20.3 19.3 21 16.3 22.3 15.3 ] - 1;
            app.Samplefreq = 500;
            app.Magnification = 1;
            
            addpath('./function');
            %=======================================
            delete(instrfind);
            baud_rate = 9600;
            jiaoyan = 'none';
            data_bits = 8;                                                                                          
            stop_bits = 1; 
            app.Num_Data_com_n = 9;
            
            app.Num_Tele_com_n = 3;
  
            app.scom = serial(['COM' '0'+app.Num_Tele_com_n]);
            %=======================================
            set(app.scom, 'BaudRate', baud_rate, 'Parity', jiaoyan, 'DataBits',...
            data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', 1,...
            'BytesAvailableFcnMode', 'byte', 'BytesAvailableFcn', {@app.bytes,app},...
            'TimerPeriod', 0.05);
                try
                    fopen(app.scom); %打开串口
%                     StartSerialPort5(app.Num_Data_com_n);%%Num_Data_com_n 代表数据来源端口号，范围COM1-COM9，不可大于com9
                    startlast20190528(app.Num_Data_com_n);%%Num_Data_com_n 代表数据来源端口号，范围COM1-COM9，不可大于com9
                    fprintf('UART connected.\n');
                catch 
                    msgbox('串口不可获得！');
                    app.delete();
                end
        end
    end                                                                                                

    methods (Access = public)

        % Construct app
        function app = wheelSSVEP

            % Execute the startup function
            app.init();

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)
            t = timerfind;
            if ~isempty(t)
                stop(t);
                delete(t);
            end
            % Delete UIFigure when app is deleted
            delete(app);
        end
    end
end