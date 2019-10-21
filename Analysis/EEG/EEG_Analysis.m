%% EEG���������� �˲�����ͼ��CCA��
%{

���÷�ʽ��
�ٳ�ʼ��ʵ����һ������
    myAnalysis =
    EEG_Analysis(SampleRate,SampleTime,decivetype,TargetFre,harms);
    SampleRate:�豸������;����λ:Hz��
    SampleTime:�豸����ʱ��;����λ:�룩
    TargetFre:�̼�Ŀ��Ƶ��;����λ:Hz��
    decivetype:�����豸ͨ����; 4��8
    harms: ʹ��г������ 1����ֻ����1��г�� 0����δʹ��г��

eg: myAnalysis = EEG_Analysis(500,3,[8 9 10],8); 

�ڼ���EEG����
    myAnalysis.LoadData(Data)

�������˲�
    myAnalysis.Filter(tongdao) ��ͨ���˲�
    myAnalysis.Filter() ȫͨ���˲�  ����Filter_init()�������޸��˲�������

�ܻ�ʱ����
    myAnalysis.PlotTime(type,tongdao[ ,ax]) 
    type: ����Դ����('origin','filter')
    tongdao: ��ͼͨ��
    ax: ͼƬ�������ڵ�����������

�ݻ�Ƶ����
    myAnalysis.PlotFFT(type,tongdao[ ,ax]) 
    type: ����Դ����('origin','filter')
    tongdao: ��ͼͨ��
    ax: ͼƬ�������ڵ�����������

��CCA����
    myAnalysis.CCA()  ���������obj.CCAResult �У�

������Ȼ���
    myAnalysis.PlotSNR(obj,type,tongdao)

Zhang Yajun,24-July-2019
B504 of BeiHang University 
%}

%% ʵ��
classdef  EEG_Analysis < handle
    
    %% ���з��� Ϊ�ⲿ�����ṩ�ӿ�
    methods (Access = public)
        %���캯��
        function obj = EEG_Analysis(SampleRate,SampleTime,decivetype,TargetFre,harms)
            if nargin == 5
                obj.init(SampleRate,SampleTime,TargetFre,decivetype,harms);
                obj.Filter_init();
                
                fprintf('EEG_Analysis Success.\n');
            else
                fprintf('EEG_Analysis Input Error!\n');
                clear obj
            end
            
            if nargout == 0
                clear obj
            end
        end
        
        %��������
        function delete(obj)
            delete(obj);
        end
        
        %��������
        function LoadData(obj,Data)
            obj.OriEegData = Data;
        end
        
        %��ʱ��ͼ
        function PlotTime(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawTime(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawTime(type,tongdao)
            else
                error('PlotTime error!')
            end
        end
        
        %��Ƶ��
        function PlotFFT(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawFFT(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawFFT(type,tongdao);
            else
                error('PlotFFT error!')
            end
        end
        
        %�����
        function PlotSNR(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawSNR(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawSNR(type,tongdao);
            else
                error('PlotSNR error!')
            end
        end
        
        %��CCA���
        function PlotCCA(obj,varargin)
            if nargin == 2
                axe = varargin{1};
            else
                axe = gca;
            end
            
            % ��Ŀ��̼�Ƶ��ת��ΪԪ����������������x��ı�ǩ
            xLabel = cell(1,length(obj.TargetFre));
            for i = 1:length(obj.TargetFre)
                xLabel{i} = num2str(obj.TargetFre(i));
            end
            x = 1:length(obj.TargetFre);
            y = obj.CCAResult';
            bar(axe,x,y)
            axe.XTickLabel = xLabel;
            title(axe,'The Result of CCA');
            xlabel(axe,'Frequency')
            ylabel(axe,'Correlation Factor')
        end

        %����
        function Save(obj,varargin)
            if nargin == 1
                % �����������1Ϊ1ʱ���������а��save����
                % ��ÿһ��Analysiserʵ����ƥ��һ��ʵ����
                if isempty(obj.saveGroupName)
                    obj.saveGroupName = input('������ʵ�������ƣ�\n','s');
                end

                % ÿ�α���ǰ��Ҫ���뱾�α������ݵ�����
                expName = input('���뱾��ʵ�����ƣ�\n','s');

                dirName = ['./analysiserSaveData/',date,obj.saveGroupName];

                % ���·���Ƿ����
                if ~exist(dirName,'dir')
                    mkdir(dirName);
                end

                saveName = [dirName,'/',expName,'.mat'];

                OriginEEG = obj.OriEegData;
                SampleRate = obj.OriSampleRate; %ԭʼ������
                SampleTime = obj.OriSampleTime; %ԭʼ����ʱ��

                TargetFreq = obj.TargetFre;  %Ŀ��Ƶ��

                Filter = obj.Filter_Hd;  %�˲�������
                FilterEEG = obj.FilterEegData; %�˲�������
                FilterOrder = obj.Filter_Order;   %�˲������� ����ȥ�����ɴ�����
                CCA = obj.CCAResult;  %CCA �������

                % ����Ѿ���ͬ���ļ�����ʾ�û��Ƿ񸲸�
                if exist(saveName, 'file')
                    isOverWrite = input('����ͬ���ļ����Ƿ񸲸������ļ�(y/n)��','s');
                    while(~(size(isOverWrite,2) == 1 && (isOverWrite == 'y' || isOverWrite == 'n')))
                        isOverWrite = input('������(y/n)��');
                    end
                    if isOverWrite == 'y'
                        save(saveName, 'OriginEEG', 'SampleRate', 'SampleTime', 'TargetFreq', ...
                                'Filter', 'FilterEEG', 'FilterOrder', 'CCA');
                        fprintf('Save successed.');
                            try
                                saveas(get(groot,'CurrentFigure'),[dirName,'/',expName,'.jpg']);
                            catch
                                warning('No figure saved')
                            end
                    else
                        return;
                    end
                else
                    save(saveName, 'OriginEEG', 'SampleRate', 'SampleTime', 'TargetFreq', ...
                                'Filter', 'FilterEEG', 'FilterOrder', 'CCA');
                            try
                                saveas(get(groot,'CurrentFigure'),[dirName,'/',expName,'.jpg']);
                            catch
                                warning('No figure saved')
                            end
                     fprintf('Save successed.');
                end
            elseif nargin == 3
                % ������������ʱ��ֱ�Ӱѵڶ��͵������������ͳ�groupName��expNamge
                
                groupName = varargin{1};
                expName = varargin{2};

                dirName = ['./analysiserSaveData/',date,groupName];

                % ���·���Ƿ����
                if ~exist(dirName,'dir')
                    mkdir(dirName);
                end

                saveName = [dirName,'/',expName,'.mat'];

                OriginEEG = obj.OriEegData;
                SampleRate = obj.OriSampleRate; %ԭʼ������
                SampleTime = obj.OriSampleTime; %ԭʼ����ʱ��

                TargetFreq = obj.TargetFre;  %Ŀ��Ƶ��

                Filter = obj.Filter_Hd;  %�˲�������
                FilterEEG = obj.FilterEegData; %�˲�������
                FilterOrder = obj.Filter_Order;   %�˲������� ����ȥ�����ɴ�����
                CCA = obj.CCAResult;  %CCA �������

                % ����Ѿ���ͬ���ļ���ֱ�ӱ���
                if exist(saveName, 'file')
                    error('����ͬ���ļ����������������ļ���');
                else
                    save(saveName, 'OriginEEG', 'SampleRate', 'SampleTime', 'TargetFreq', ...
                                'Filter', 'FilterEEG', 'FilterOrder', 'CCA');
                end
            end
        
        end
        
        
        %�˲�
        function Filter(obj,tongdao)
            obj.isFilter = true;
            if nargin == 2
                obj.FilterIn(tongdao);%��ͨ���˲�
            else
                obj.FilterIn();%ȫͨ���˲�
            end
        end
        
        function CCA(obj)
            if obj.isFilter == false
                obj.CCAResult = obj.cca_analysis(obj.OriEegData,obj.OriRefData,obj.TargetFre);
            else
                obj.CCAResult = obj.cca_analysis(obj.FilterEegData,obj.FiltRefData,obj.TargetFre);
            end
        end
        
    end
    
    %% ˽�з���
    methods (Access = private)
        
        %��ʼ������
        function init(obj,SampleRate,SampleTime,TargetFre,tongdaonum,harms)
            obj.OriSampleRate = SampleRate;
            obj.OriSampleTime = SampleTime;
            obj.OriDataNum = SampleRate*SampleTime;
            obj.TargetFre = TargetFre;
            obj.TongdaoNum = tongdaonum;
            obj.HarmNum = harms;    %ʹ��г������
            
            obj.isFilter = false;
            
            obj.OriRefData = obj.cca_reference(obj.TargetFre,obj.OriSampleRate,obj.OriDataNum,obj.HarmNum); %����ԭʼ�ο��ź�
        end
        
        % �˲�����ʼ����������ͨ�˲������󣬸����������Ʋ�ͬ�˲���
        function Filter_init(obj)
            
            Fs = 500;  % Sampling Frequency

            N    = 200;      % Order
            Fc1  = 8;        % First Cutoff Frequency
            Fc2  = 45;       % Second Cutoff Frequency
            flag = 'scale';  % Sampling Flag
            % Create the window vector for the design algorithm.
            win = blackman(N+1);

            % Calculate the coefficients using the FIR1 function.
            b  = fir1(N, [Fc1 Fc2]/(Fs/2), 'bandpass', win, flag);
            Hd = dfilt.dffir(b);
            
            %%            
            obj.Filter_Hd = Hd;
            obj.Filter_Order = length(obj.Filter_Hd.Numerator);%��ȡ�˲�������
            obj.Filter_CutNum = obj.Filter_Order; % �˲�����ȥ���ݵ���
            obj.Ori_CutNum = obj.Filter_CutNum;   % ԭʼ�źż�ȥ���ݵ��� 
            obj.FilterDataNum = obj.OriDataNum - obj.Filter_CutNum;
            
            obj.FiltRefData = obj.cca_reference(obj.TargetFre,obj.OriSampleRate,obj.FilterDataNum,obj.HarmNum); %�����˲����ݲο��ź�
        end
        
        %��ʱ��ͼ
        function DrawTime(obj,type,tongdao,varargin)
            if nargin == 4
                axe = varargin{1};
            elseif nargin == 3
                axe = gca;
            end
            switch type
                case 'origin'
                   data = obj.OriEegData(tongdao,obj.Ori_CutNum+1:obj.OriDataNum);
                   Fs = obj.OriSampleRate;
                   NFFT = obj.OriDataNum - obj.Ori_CutNum;
                   t = 0:1/Fs:(NFFT-1)/Fs;
                   plot(axe, t, data)
                   xlabel(axe,'t/s');
                   ylabel(axe,'U/uV');
                   title(axe,'The origin signal time domain waveforms');
                case 'filter'
                   data = obj.FilterEegData(tongdao,:);
                   Fs = obj.OriSampleRate;
                   NFFT = obj.FilterDataNum;
                   t = 0:1/Fs:(NFFT-1)/Fs;
                   plot(axe, t, data)
                   xlabel(axe,'t/s');
                   ylabel(axe,'U/uV');
                   title(axe,'The filter signal time domain waveforms');                    
            end
            
        end
        
        %��Ƶ��ͼ
        function DrawFFT(obj,type,tongdao,varargin)
            if nargin == 4
                axe = varargin{1};
            elseif nargin == 3
                axe = gca;
            end
            switch type
                case 'origin'
                   data = obj.OriEegData(tongdao,obj.Ori_CutNum+1:obj.OriDataNum);
                   Fs = obj.OriSampleRate;
                   NFFT = obj.OriDataNum - obj.Ori_CutNum;
                   % t = 0:1/Fs:(NFFT-1)/Fs; tδʹ�ã���ʱע��
                   f=((1:NFFT)-1)*Fs/NFFT;
                   
                   Ori_S_FFT = fft(data,NFFT,2);
                   Ori_S_ln=20*log10(abs(Ori_S_FFT));
                   
                   plot(axe, f,Ori_S_ln);
                   xlabel(axe,'f/Hz');
                   ylabel(axe,'20*lg|FFT|/dB');
                   title(axe,'The origin signal FFT waveforms');
                case 'filter'
                   data = obj.FilterEegData(tongdao,:);
                   Fs = obj.OriSampleRate;
                   NFFT = obj.FilterDataNum;
                   % t = 0:1/Fs:(NFFT-1)/Fs; ��ʾû��ʹ�ñ���t��ʱ����ע����
                   f=((1:NFFT)-1)*Fs/NFFT;

                   Ori_S_FFT = fft(data,NFFT,2);
                   Ori_S_ln=20*log10(abs(Ori_S_FFT));
                   
                   plot(axe, f,Ori_S_ln);
                   xlabel(axe,'f/Hz');
                   ylabel(axe,'20*lg|FFT|/dB');
                   title(axe,'The filter signal FFT waveforms');                    
            end
        end
        
        %����Ȼ���
        function DrawSNR(obj,type,tongdao,varargin)
            if nargin == 4
                axe = varargin{1};
            elseif nargin == 3
                axe = gca;
            end
            switch type
                case 'origin'
                   % data = obj.OriEegData(tongdao,obj.Ori_CutNum+1:obj.OriDataNum);
                   data = detrend(obj.OriEegData(tongdao,obj.Ori_CutNum+1:obj.OriDataNum));
                   Fs = obj.OriSampleRate;
                   NFFT = obj.OriDataNum - obj.Ori_CutNum;
                   % �����Ϊ2���������ͼ�ȥ1
                   if mod(NFFT,2)==1
                       NFFT = NFFT-1;
                   end
                   
                   Ori_S_FFT = fft(data,NFFT,2);
                   % �������ȡһ������ݵ㣬��ΪFFT����ż�ԳƵ�
                   Ori_S_FFT_abs = (abs(Ori_S_FFT(:,1:NFFT/2)));
                   
                   SNR_NFFT = NFFT;
                   Ori_SNR_freqs = zeros(size(Ori_S_FFT_abs));
                   f_SNR=linspace(0,Fs/2,SNR_NFFT/2);
                   
                   
                   Ori_S_FFT_real=Ori_S_FFT_abs/(NFFT/2); 
                   Ori_S_FFT_real(:,1)=Ori_S_FFT_real(:,1)/2;
                   
                   for Ori_SNR_i = 6:1:(SNR_NFFT/2-5)          
                        Ori_front_freqs = sum(Ori_S_FFT_real(:,Ori_SNR_i-5:Ori_SNR_i-1),2);
                        Ori_post_freqs  = sum(Ori_S_FFT_real(:,Ori_SNR_i+1:Ori_SNR_i+5),2);
                        Ori_SNR_freqs(:,Ori_SNR_i) = 20*log10(10 * Ori_S_FFT_real(:,Ori_SNR_i)./(Ori_front_freqs+Ori_post_freqs));      
                   end
                   
                   plot(axe, f_SNR,Ori_SNR_freqs);
                   xlabel(axe,'f/Hz');
                   ylabel(axe,'SNR/Average(5)');
                   title(axe,'The origin signal SNR waveforms');
                case 'filter'
                   % data = obj.FilterEegData(tongdao,:);
                   data = detrend(obj.FilterEegData(tongdao,:));
                   Fs = obj.OriSampleRate;
                   NFFT = obj.FilterDataNum;
                   if mod(NFFT,2)==1
                       NFFT = NFFT-1;
                   end
                   
                   filt_S_FFT = fft(data,NFFT,2);                   
                   filt_S_FFT_abs = (abs(filt_S_FFT(:,1:NFFT/2)));
                   
                   SNR_NFFT = NFFT;
                   filt_SNR_freqs = zeros(size(filt_S_FFT_abs));
                   f_SNR=linspace(0,Fs/2,SNR_NFFT/2);
                   
                   filt_S_FFT_real=filt_S_FFT_abs/(NFFT/2); 
                   filt_S_FFT_real(:,1)=filt_S_FFT_real(:,1)/2;
                   
                   for SNR_i = 6:1:(SNR_NFFT/2-5)          
                        filt_front_freqs = sum(filt_S_FFT_real(:,SNR_i-5:SNR_i-1),2);
                        filt_post_freqs  = sum(filt_S_FFT_real(:,SNR_i+1:SNR_i+5),2);
                        filt_SNR_freqs(:,SNR_i) = 20*log10(10 * filt_S_FFT_real(:,SNR_i)./(filt_front_freqs+filt_post_freqs));      
                   end
                   
                   plot(axe, f_SNR,filt_SNR_freqs);
                   xlabel(axe,'f/Hz');
                   ylabel(axe,'SNR/Average(5)');
                   title(axe,'The filter signal SNR waveforms');                  
            end 
        end
        
        %�˲�
        function FilterIn(obj,tongdao)
            obj.FilterEegData = zeros(obj.TongdaoNum, obj.FilterDataNum);
            if nargin == 2               
                data = obj.OriEegData(tongdao,:);
                temp = filter(obj.Filter_Hd,data);
                obj.FilterEegData(tongdao,:) = temp(obj.Filter_CutNum + 1:obj.OriDataNum);
            else
                for ch_i = 1:1:obj.TongdaoNum
                    data = obj.OriEegData(ch_i,:);
                    temp = filter(obj.Filter_Hd,data);
                    obj.FilterEegData(ch_i,:) = temp(obj.Filter_CutNum + 1:obj.OriDataNum);
                end
            end
        end
        
    end
    
    %% ��̬���� ����Ҫʵ������
    methods (Static)
        
        % ���ɲο��ź� harms:�ο��ź�г������ 1����ֻ����1��г�� 0����δʹ��г��
        function output = cca_reference(targ_fre, fs, sample_num, harms)
            HarmList = 1:1:harms+1;
            harmNum = length(HarmList);
            channelNum = harmNum*2;
            TargetNum = length(targ_fre);
            
            t = linspace(0,sample_num/fs-1/fs,sample_num);  %����ʱ������      
            
            output = zeros(channelNum, sample_num, TargetNum);
            for targ_i = 1:TargetNum
                temp = zeros(channelNum, sample_num);
                for harm_i = 1:2:channelNum-1
                    temp(harm_i:harm_i+1,:) = [sin(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t);cos(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t)];
                end
                output(:,:,targ_i) = temp;
            end
        end
        
        %������ط���data(ͨ����ʱ������)
        function output = cca_analysis(data,refData,targ_fre)
            TargetNum = length(targ_fre);
            output=zeros(1,TargetNum);
            for iTar = 1:TargetNum
                refdata = squeeze(refData(:,:,iTar));
                [~,~,temp] = canoncorr(data', refdata');
                output(1,iTar) = temp(1,1);
            end
        end
        
    end
    
    %% ����
    properties (Access = public)
        % ��������
        TongdaoNum; %ͨ����
        
        OriEegData; %ԭʼ����
        OriSampleRate; %ԭʼ������
        OriSampleTime; %ԭʼ����ʱ��
        OriDataNum; %ԭʼ���ݵ���
        Ori_CutNum; %ԭʼ���ݼ�ȥ����
        OriRefData; %ԭʼ�ο��ź�
        
        TargetFre;  %Ŀ��Ƶ��
        
        isFilter; %flagָʾ�Ƿ�μӹ��˲�
        Filter_Hd;  %�˲�������
        FilterEegData; %�˲�������
        Filter_Order;   %�˲������� ����ȥ�����ɴ�����
        FilterDataNum; %�˲��������ݵ���
        Filter_CutNum; %�˲�����ȥ����      
        FiltRefData; %�˲���ο��ź�
        
        HarmNum;    %ʹ��г������
        CCAResult;  %CCA �������
        
        %DownEegData; %������������
        %DownSampleRate; %�������������
        %DownSampleTime; %�����������ʱ��

        saveGroupName;

    end
        
end

