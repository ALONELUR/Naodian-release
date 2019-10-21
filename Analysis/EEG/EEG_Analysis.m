%% EEG分析驱动类 滤波　画图　CCA等
%{

调用方式：
①初始，实例化一个对象
    myAnalysis =
    EEG_Analysis(SampleRate,SampleTime,decivetype,TargetFre,harms);
    SampleRate:设备采样率;（单位:Hz）
    SampleTime:设备采样时间;（单位:秒）
    TargetFre:刺激目标频率;（单位:Hz）
    decivetype:代表设备通道数; 4或8
    harms: 使用谐波次数 1代表只利用1次谐波 0代表未使用谐波

eg: myAnalysis = EEG_Analysis(500,3,[8 9 10],8); 

②加载EEG数据
    myAnalysis.LoadData(Data)

③数据滤波
    myAnalysis.Filter(tongdao) 单通道滤波
    myAnalysis.Filter() 全通道滤波  可在Filter_init()函数内修改滤波器参数

④画时域波形
    myAnalysis.PlotTime(type,tongdao[ ,ax]) 
    type: 数据源类型('origin','filter')
    tongdao: 做图通道
    ax: 图片绘制所在的坐标轴区域

⑤画频域波形
    myAnalysis.PlotFFT(type,tongdao[ ,ax]) 
    type: 数据源类型('origin','filter')
    tongdao: 做图通道
    ax: 图片绘制所在的坐标轴区域

⑥CCA分析
    myAnalysis.CCA()  最后结果存在obj.CCAResult 中，

⑦信噪比绘制
    myAnalysis.PlotSNR(obj,type,tongdao)

Zhang Yajun,24-July-2019
B504 of BeiHang University 
%}

%% 实现
classdef  EEG_Analysis < handle
    
    %% 公有方法 为外部调用提供接口
    methods (Access = public)
        %构造函数
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
        
        %析构函数
        function delete(obj)
            delete(obj);
        end
        
        %加载数据
        function LoadData(obj,Data)
            obj.OriEegData = Data;
        end
        
        %画时域图
        function PlotTime(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawTime(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawTime(type,tongdao)
            else
                error('PlotTime error!')
            end
        end
        
        %画频域
        function PlotFFT(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawFFT(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawFFT(type,tongdao);
            else
                error('PlotFFT error!')
            end
        end
        
        %信噪比
        function PlotSNR(obj,type,tongdao,varargin)
            if nargin == 4
                obj.DrawSNR(type,tongdao,varargin{1});
            elseif nargin == 3
                obj.DrawSNR(type,tongdao);
            else
                error('PlotSNR error!')
            end
        end
        
        %画CCA结果
        function PlotCCA(obj,varargin)
            if nargin == 2
                axe = varargin{1};
            else
                axe = gca;
            end
            
            % 把目标刺激频率转化为元胞数组用于坐标轴x轴的标签
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

        %保存
        function Save(obj,varargin)
            if nargin == 1
                % 输入参数个数1为1时运行命令行版的save函数
                % 对每一个Analysiser实例仅匹配一个实验组
                if isempty(obj.saveGroupName)
                    obj.saveGroupName = input('请输入实验组名称：\n','s');
                end

                % 每次保存前需要输入本次保存数据的名称
                expName = input('输入本次实验名称：\n','s');

                dirName = ['./analysiserSaveData/',date,obj.saveGroupName];

                % 检查路径是否存在
                if ~exist(dirName,'dir')
                    mkdir(dirName);
                end

                saveName = [dirName,'/',expName,'.mat'];

                OriginEEG = obj.OriEegData;
                SampleRate = obj.OriSampleRate; %原始采样率
                SampleTime = obj.OriSampleTime; %原始采样时间

                TargetFreq = obj.TargetFre;  %目标频率

                Filter = obj.Filter_Hd;  %滤波器对象
                FilterEEG = obj.FilterEegData; %滤波后数据
                FilterOrder = obj.Filter_Order;   %滤波器阶数 用于去除过渡带数据
                CCA = obj.CCAResult;  %CCA 分析结果

                % 如果已经有同名文件，提示用户是否覆盖
                if exist(saveName, 'file')
                    isOverWrite = input('已有同名文件，是否覆盖现有文件(y/n)：','s');
                    while(~(size(isOverWrite,2) == 1 && (isOverWrite == 'y' || isOverWrite == 'n')))
                        isOverWrite = input('请输入(y/n)：');
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
                % 输入三个参数时，直接把第二和第三个参数解释成groupName和expNamge
                
                groupName = varargin{1};
                expName = varargin{2};

                dirName = ['./analysiserSaveData/',date,groupName];

                % 检查路径是否存在
                if ~exist(dirName,'dir')
                    mkdir(dirName);
                end

                saveName = [dirName,'/',expName,'.mat'];

                OriginEEG = obj.OriEegData;
                SampleRate = obj.OriSampleRate; %原始采样率
                SampleTime = obj.OriSampleTime; %原始采样时间

                TargetFreq = obj.TargetFre;  %目标频率

                Filter = obj.Filter_Hd;  %滤波器对象
                FilterEEG = obj.FilterEegData; %滤波后数据
                FilterOrder = obj.Filter_Order;   %滤波器阶数 用于去除过渡带数据
                CCA = obj.CCAResult;  %CCA 分析结果

                % 如果已经有同名文件，直接报错
                if exist(saveName, 'file')
                    error('已有同名文件，重新命名保存文件名');
                else
                    save(saveName, 'OriginEEG', 'SampleRate', 'SampleTime', 'TargetFreq', ...
                                'Filter', 'FilterEEG', 'FilterOrder', 'CCA');
                end
            end
        
        end
        
        
        %滤波
        function Filter(obj,tongdao)
            obj.isFilter = true;
            if nargin == 2
                obj.FilterIn(tongdao);%单通道滤波
            else
                obj.FilterIn();%全通道滤波
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
    
    %% 私有方法
    methods (Access = private)
        
        %初始化函数
        function init(obj,SampleRate,SampleTime,TargetFre,tongdaonum,harms)
            obj.OriSampleRate = SampleRate;
            obj.OriSampleTime = SampleTime;
            obj.OriDataNum = SampleRate*SampleTime;
            obj.TargetFre = TargetFre;
            obj.TongdaoNum = tongdaonum;
            obj.HarmNum = harms;    %使用谐波次数
            
            obj.isFilter = false;
            
            obj.OriRefData = obj.cca_reference(obj.TargetFre,obj.OriSampleRate,obj.OriDataNum,obj.HarmNum); %生成原始参考信号
        end
        
        % 滤波器初始化，产生带通滤波器对象，根据需求可设计不同滤波器
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
            obj.Filter_Order = length(obj.Filter_Hd.Numerator);%获取滤波器阶数
            obj.Filter_CutNum = obj.Filter_Order; % 滤波器减去数据点数
            obj.Ori_CutNum = obj.Filter_CutNum;   % 原始信号减去数据点数 
            obj.FilterDataNum = obj.OriDataNum - obj.Filter_CutNum;
            
            obj.FiltRefData = obj.cca_reference(obj.TargetFre,obj.OriSampleRate,obj.FilterDataNum,obj.HarmNum); %生成滤波数据参考信号
        end
        
        %画时域图
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
        
        %画频域图
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
                   % t = 0:1/Fs:(NFFT-1)/Fs; t未使用，暂时注释
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
                   % t = 0:1/Fs:(NFFT-1)/Fs; 提示没有使用变量t暂时把它注释了
                   f=((1:NFFT)-1)*Fs/NFFT;

                   Ori_S_FFT = fft(data,NFFT,2);
                   Ori_S_ln=20*log10(abs(Ori_S_FFT));
                   
                   plot(axe, f,Ori_S_ln);
                   xlabel(axe,'f/Hz');
                   ylabel(axe,'20*lg|FFT|/dB');
                   title(axe,'The filter signal FFT waveforms');                    
            end
        end
        
        %信噪比绘制
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
                   % 如果不为2的整数倍就减去1
                   if mod(NFFT,2)==1
                       NFFT = NFFT-1;
                   end
                   
                   Ori_S_FFT = fft(data,NFFT,2);
                   % 在这里截取一半的数据点，因为FFT谱是偶对称的
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
        
        %滤波
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
    
    %% 静态方法 不需要实例对象
    methods (Static)
        
        % 生成参考信号 harms:参考信号谐波次数 1代表只利用1次谐波 0代表未使用谐波
        function output = cca_reference(targ_fre, fs, sample_num, harms)
            HarmList = 1:1:harms+1;
            harmNum = length(HarmList);
            channelNum = harmNum*2;
            TargetNum = length(targ_fre);
            
            t = linspace(0,sample_num/fs-1/fs,sample_num);  %产生时间序列      
            
            output = zeros(channelNum, sample_num, TargetNum);
            for targ_i = 1:TargetNum
                temp = zeros(channelNum, sample_num);
                for harm_i = 1:2:channelNum-1
                    temp(harm_i:harm_i+1,:) = [sin(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t);cos(2*pi*targ_fre(targ_i)*HarmList((harm_i+1)/2)*t)];
                end
                output(:,:,targ_i) = temp;
            end
        end
        
        %典型相关分析data(通道，时间序列)
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
    
    %% 属性
    properties (Access = public)
        % 基本参数
        TongdaoNum; %通道数
        
        OriEegData; %原始数据
        OriSampleRate; %原始采样率
        OriSampleTime; %原始采样时间
        OriDataNum; %原始数据点数
        Ori_CutNum; %原始数据减去点数
        OriRefData; %原始参考信号
        
        TargetFre;  %目标频率
        
        isFilter; %flag指示是否参加过滤波
        Filter_Hd;  %滤波器对象
        FilterEegData; %滤波后数据
        Filter_Order;   %滤波器阶数 用于去除过渡带数据
        FilterDataNum; %滤波后保留数据点数
        Filter_CutNum; %滤波器减去点数      
        FiltRefData; %滤波后参考信号
        
        HarmNum;    %使用谐波次数
        CCAResult;  %CCA 分析结果
        
        %DownEegData; %降采样后数据
        %DownSampleRate; %降采样后采样率
        %DownSampleTime; %降采样后采样时间

        saveGroupName;

    end
        
end

