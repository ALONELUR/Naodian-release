classdef  wheelSSVEP < handle
    properties (Access = public)
        Status;
        ReceiveT=[];
        AnalyT=[];

        %ʵ�����
        Gazetime;
        HarmNum;
        FilterNum;
        Tragetfreq;
        Samplefreq;
        Magnification;

        % �Աȶ��㷨��ֵ
        threshold;

        strRec;            %�ѽ��յ��ַ���
        %��ͼ���
        Timeplot;
        Freqplot;
        Ccaplot1;
        Ccaplot2;
        Ccaplot3;
        %ͨѶ�˿����
        COMS;
        DataCom;
        TeleCom;
        scom;
        Num_Data_com_n;
        Num_Tele_com_n
        %ʵ������
        RefData;
        AnalysisData;
        OrigtolData;
        TempData;
        OrigData;
        %ʵ����
        TotalResult;
        IndivResult;

        %Mode
    end

    methods (Access = public)
        % �˺����ǳ����������з����ĳ���
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
        % �˺����ǳ���ֻ����һ�η����ĳ���
        function mode2(app)
            app.receive(1);
            app.AnalysisData = app.TempData;
            app.OrigtolData = app.OrigData;
            app.analytical_data(2);
            app.Axesplot();
            app.judgeANDsend();
            app.pause();
        end

        % �˺����ǽ������ݣ��������ݽ����ĺ���
        function receive (app,divided)
            
            DATA_NUM = round(app.Gazetime * app.Samplefreq / divided);
            DATA_SIZE = 34;
            NUM = DATA_NUM * DATA_SIZE;
%             receive_data = ReadSerialPort18(app.Num_Data_com_n, NUM);
            receive_data = readlast20190528(app.Num_Data_com_n, NUM);

            if(receive_data(1)==205 && receive_data(end)==205)
                 msgbox('�������ݴ���');
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
                if(receive_data(iRec) == 85 && receive_data(iRec + 1) == 85 && receive_data(iRec + 2) == 170 && receive_data(iRec + 3) == 170)%% 55 55 AA AA ֡ͷ
                    temp_data(iTem,:) = receive_data(:,iRec:iRec+DATA_SIZE-1);
                    
                    for coloum_j = 1:1:8  %%����ȡ��8��ͨ������
                        coloum_i = 3 * coloum_j + 6; 
                        temp_dec = dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                        temp_value = ((temp_dec*4.5/(2^23-1))./app.Magnification)*10^6;
                        ori_data(iTem, coloum_j)=temp_value;
                        down_data(mod(iTem, 2)+1, coloum_j) = temp_value;
                    end
                    if mod(iTem, 2) == 0
                        dec_data(floor(iTem/2), :) = mean(down_data); %% ��������ȡƽ��ֵ
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
        
        % �˳����Ƕ����ݽ��з����ĳ���
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
            
            % ������ط����㷨
            testdata = notch_filter(dec_data', app.Samplefreq / 2);
            app.TotalResult = cca_analysis(testdata, app.RefData, ...
                app.Tragetfreq);
        end

        % �Է����õ������ϵ�������жϣ��Ƿ��������㹻�ߣ����ҷ��ͽ��
        function judgeANDsend(app)
            p = app.TotalResult;
            [~,index] = max(p);
            index = index(end);
%=============��ֵ�жϷ�
%             if p(index)>0.42
%                 fwrite(app.scom, [85 48+index 10]);
%             else
%                 fwrite(app.scom, [85 48 10]);
%             end
            
%=============�Աȶ��жϷ�
            
            p = p - min(p);
            p = p ./ p(index);
            constract = p(index) / ((sum(p) - p(index))/(size(p,2)-1));
            if constract > app.threshold(index)
                fwrite(app.scom, [85 48+index 10]);
            else
                fwrite(app.scom, [85 48 10]);
            end
        end

        % �������ûɶ�ã���û�����
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
           
        % �����ǻ�ͼ����
        function Axesplot(app)
                figure(1);
                app.Ccaplot1 = plot(1:length(app.TotalResult), app.TotalResult);
                title('Analysis Result');
        end
    
        % ���ɲο��źŵĳ���
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

            % ��ȡ���ڿɻ�ȡ�����ݸ���
            n = get(app.scom, 'BytesAvailable');
            % �����������ݣ�������������
            if n
                % ����hasData����������������������Ҫ��ʾ
                % ��ȡ��������
                app.strRec = fread(obj, 1);
                % ��������
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

        % ÿ�γ���ʼ����ִ��
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
                    fopen(app.scom); %�򿪴���
%                     StartSerialPort5(app.Num_Data_com_n);%%Num_Data_com_n ����������Դ�˿ںţ���ΧCOM1-COM9�����ɴ���com9
                    startlast20190528(app.Num_Data_com_n);%%Num_Data_com_n ����������Դ�˿ںţ���ΧCOM1-COM9�����ɴ���com9
                    fprintf('UART connected.\n');
                catch 
                    msgbox('���ڲ��ɻ�ã�');
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