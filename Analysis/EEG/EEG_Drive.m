%% EEG硬件驱动程序，实现从下位机读取原始数据，并输出解析之后的各通道数据
% %
%
% 硬件驱动初始化（设备类型，数据端口，采样率，放大倍数，采样时间）
% 修改下位机参数（采样率、放大倍数，采样时间）
% 获取数据并解析
% 调用方式：
%
% ①初始，实例化一个对象
%     mydrive = EEG_Drive(Type,sCOM,Rate,Gain); 
%     Type:设备类型（4或8）;
%     sCOM:设备端口号;
%     Rate:设备初始采样率;（单位:Hz）
%     Gain:设备初始化增益;（单位:倍）
%     Time:设备初始化采样时间（单位：秒）;
% eg: mydrive = EEG_Drive(4,12,500,2,2); 
% 
% ②选择模式：
%   数据读取的方法有两种，在线与离线
%       在线模式： mydrive.OnlineInit(refreshRate, timeLength)
%           refreshRate    :刷新率(Hz)
%           timeLength     :缓存数据的长度(s)
%               在线模式中，脑电数据保存为一个先进先出的队列，初始化时需要输入数据刷新的频率以及缓存数据的长度，其中刷新率推荐不能超过10Hz。
%       离线模式： mydrive.OfflineInit(timeLength)
%           timeLength     :采集数据的长度(s)
%               在离线模式中，采集指定时间长度的脑电数据
% ③开始读取：
%     mydrive.ReadStart();
%     开启串口并开始读取数据
%
% ④停止读取：
%     mydrive.ReadStop();
%     关闭串口并且清空输入缓存区中的数据
%
% ⑤获取数据
%     Output = mydrive.DataSequenceOutput();
%       Output {#timeLength, #channelNum}
%     输出数据队列，你可以在任何时候调用此函数来获得数据，但是此函数在在线模式下会在内部等待数据刷新，只有新的数据产生了才会输出至Output。
%  所以外部分析脑电数据的程序执行一次的时长必须小于数据刷新的周期，这样才能保证每次去读取时能读取到新数据并且不会丢失数据。丢失数据并不会造成数据错误，只是降低了数据的利用率。
%     在离线模式下，数据只能输出一次，输出后数据就被清空。
%
% ⑥修改采样率
%     mydrive.ChangeRate(value) 4通道设备支持250 500 1000；8通道设备支持250 500
%
% ⑦修改放大倍数
%     mydrive.ChangeGain(value) 1 2 4 6 8 12 24
%
% ⑧修改采样时间
%     mydrive.ChangeTime(value) 
%
% Zhang Yajun, Yin Wenhan,29-July-2019
% B504 of BeiHang University 
% %

%% 实现
classdef  EEG_Drive < handle
    
    %% 公有方法 为外部调用提供接口
    methods (Access = public)
        %构造函数
        function obj = EEG_Drive(Type,sCOM,Rate,Gain)
            if nargin == 4
                obj.init(Type,sCOM,Rate,Gain);
                obj.init_Device_uart();
                WaitSecs(0.5);
                obj.ModifyMeasuringMode('input');%修改测量模式为输入
                WaitSecs(0.5);
                obj.writeDevice_uart(0, obj.SampleRate);%修改采样率
                WaitSecs(0.5);
                obj.writeDevice_uart(1, obj.SampleGain);%修改放大倍数
                WaitSecs(0.5);
                obj.Close_Device_uart();%关闭数据端口

                % obj.isDataReady = false;
                % obj.StopCollect(); % 发送停止采集指令
                % if obj.EEG_COM.BytesAvailable ~= 0
                %     fread(obj.EEG_COM, obj.EEG_COM.BytesAvailable); %清空缓存区
                % end
                % WaitSecs(0.3);
                % obj.StartCollect();% 发送开始采集指令

                fprintf('EEG_Drive Success.\n');
            else
                fprintf('EEG_Drive Input Error!\n');
                clear obj
            end
            
            if nargout == 0
                clear obj
            end
        end
        
        %析构函数
        function delete(obj)
            delete(obj);
            delete(instrfind);
        end
        
        % %获取数据
        % function output = GetData(obj)
        %     % ReceiveData(obj);
        %     % output = obj.DeviceData;
        % end
        
        %修改采样率，ChangeType 0 writeDevice_uart(0，Value)
        function ChangeRate(obj, Value)
            try
                writeDevice_uart(obj,0, Value);
                WaitSecs(0.5);
                writeDevice_uart(obj,0, Value);
                WaitSecs(0.5);
            catch
                fprintf('更改采样率失败！\n');
            end
        end
        %修改放大倍数，ChangeType 1 writeDevice_uart(1，Value)
        function ChangeGain(obj, Value)
            try
                writeDevice_uart(obj,1, Value);
                WaitSecs(0.5);
                writeDevice_uart(obj,1, Value);
                WaitSecs(0.5);
            catch
                fprintf('更改失败！\n');
            end
        end

    end
    
    %% 私有方法
    methods (Access = private)
        %初始化函数
        function init(obj,Type,sCOM,Rate,Gain)
            obj.DeviceType = Type;
            obj.DeviceCom = sCOM;
            obj.SampleRate = Rate;
            obj.SampleGain = Gain;
            
            
            switch Type % 单通道设备和8通道设备每帧数据长度不同
                case 4
                    obj.OneFrameByte = 20;
                case 8
                    obj.OneFrameByte = 34;
                otherwise
                fprintf('EEG_Drive DeviceType Error!\n');
            end
        end
        
        %初始化设备串口
        function init_Device_uart(obj)
            % delete(instrfind);
            try
                baud_rate = 921600;
                parity = 'none';
                data_bits = 8; 
                stop_bits = 1;  
                obj.EEG_COM = serial (strcat('com',num2str(obj.DeviceCom)));
                set(obj.EEG_COM, 'BaudRate', baud_rate, 'Parity', parity, 'DataBits',...
                data_bits, 'StopBits', stop_bits);
                fopen(obj.EEG_COM);
                fprintf('EEG device connected!\n');
            catch
                fprintf('EEG device unconnected!\n');
                
            end
        end

        %关闭设备串口
        function Close_Device_uart(obj)
            fclose(obj.EEG_COM);
        end

        %修改测量模式
        function ModifyMeasuringMode(obj,Type)
            %修改测量模式 
            %
            % Syntax: ModifyMeasuringMode(Type)
            %
            % Type input 代表下位机输入测量  Type impedance 代表下位机阻抗测量
            switch Type
                case 'input'
                    fwrite(obj.EEG_COM, [83 84 77 48 69 68], 'uint8', 'async');
                case 'impedance'
                    fwrite(obj.EEG_COM, [83 84 77 49 69 68], 'uint8', 'async');
                otherwise
                    fprintf('不存在此测量模式！\n');
            end
        end
        
        %发送修改命令(ChangeType 0 修改采样率，ChangeType 1 修改放大倍数) writeDevice_uart(ChangeType，Value)
        function writeDevice_uart(obj,ChangeType, Value)%[83 84 71 0 0 0]
            if ChangeType == 0 %修改采样率
                switch Value
                    case 250
                        fwrite(obj.EEG_COM, [83 84 82 54 69 68], 'uint8', 'async');
                        obj.SampleRate = Value;      
                        fprintf('采样率更改成功！\n');
                    case 500
                        fwrite(obj.EEG_COM, [83 84 82 53 69 68], 'uint8', 'async');
                        obj.SampleRate = Value;
                        fprintf('采样率更改成功！\n');
                    case 1000
                        if obj.DeviceType == 4
                            fwrite(obj.EEG_COM, [83 84 82 52 69 68], 'uint8', 'async');
                            obj.SampleRate = Value;
                            fprintf('采样率更改成功！\n');
                        else
                            fprintf('EEG_Drive 不支持该采样率! \n');
                        end
                    otherwise
                        fprintf('EEG_Drive 不支持该采样率! \n');
                end
            elseif ChangeType == 1 %修改放大倍数
                switch Value
                    case 1
                        fwrite(obj.EEG_COM, [83 84 71 0 0 0], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 2
                        fwrite(obj.EEG_COM, [83 84 71 36 146 73], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 4
                        fwrite(obj.EEG_COM, [83 84 71 73 36 146], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 6
                        fwrite(obj.EEG_COM, [83 84 71 109 182 219], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 8
                        fwrite(obj.EEG_COM, [83 84 71 146 73 36], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 12
                        fwrite(obj.EEG_COM, [83 84 71 182 219 109], 'uint8', 'async');
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;
                    case 24
                        fwrite(obj.EEG_COM, [83 84 71 219 109 182], 'uint8', 'async'); 
                        fprintf('放大倍数更改成功！\n');
                        obj.SampleGain = Value;                        
                    otherwise
                        fprintf('EEG_Drive 不支持该放大倍数(1 2 4 6 8 12 24)! \n');
                end
            end          
        end
                
        %对属性中的DataBuffer进行解析，并且丢弃解析过数据
        function output = Decoding(obj)
            receiveNum = length(obj.DataBuffer);
            Tongdaoshu = obj.DeviceType;
            temp_data = zeros(obj.dataFrameLength,obj.OneFrameByte);
            output = zeros(obj.dataFrameLength, Tongdaoshu);
            iRec = 1;
            iTem = 1;
            if obj.DeviceType == 4
                while 1
                    % 此时一帧数据对应的左右标号
                    startPtr = iRec;
                    endPtr = iRec + obj.OneFrameByte - 1;
                    % 如果此时原始数据已经不足一帧，跳出
                    if endPtr > receiveNum
                        popIndex = startPtr;
                        break
                    end

                    %% 判断 55 55 AA AA 帧头
                    if(obj.DataBuffer(startPtr) == 85 && obj.DataBuffer(startPtr + 1) == 85 && obj.DataBuffer(startPtr + 2) == 170 && obj.DataBuffer(startPtr + 3) == 170)
                        temp_data(iTem,:) = obj.DataBuffer(:,startPtr:endPtr);
                        for coloum_j = 1:1:Tongdaoshu  %%依次取出Tongdaoshu个通道数据
                            coloum_i = 3 * coloum_j + 4; 
                            temp_dec = obj.dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                            temp_value = ((temp_dec*4.5/(2^23-1)))*10^6;
                            output(iTem, coloum_j)=temp_value;                      
                        end
                        iTem = iTem + 1;
                        iRec = endPtr + 1;
                        % 如果原始数据已经读完，跳出
                        % 如果要求的数据已经足够，跳出
                        if iRec > receiveNum || iTem - 1 == obj.dataFrameLength
                            popIndex = iRec;
                            break
                        end
                    else
                        iRec = startPtr + 1;
                        % 如果原始数据已经读完，跳出
                        if iRec > receiveNum
                            popIndex = iRec;
                            break
                        end
                    end
                end
            end
            if obj.DeviceType == 8
                while 1
                    % 此时一帧数据对应的左右标号
                    startPtr = iRec;
                    endPtr = iRec + obj.OneFrameByte - 1;
                    % 如果此时原始数据已经不足一帧，跳出
                    if endPtr > receiveNum
                        popIndex = startPtr;
                        break
                    end

                    %% 55 55 AA AA 帧头
                    if(obj.DataBuffer(startPtr) == 85 && obj.DataBuffer(startPtr + 1) == 85 && obj.DataBuffer(startPtr + 2) == 170 && obj.DataBuffer(startPtr + 3) == 170)
                        temp_data(iTem,:) = obj.DataBuffer(:,startPtr:endPtr);
                        for coloum_j = 1:1:Tongdaoshu  %%依次取出Tongdaoshu个通道数据
                            coloum_i = 3 * coloum_j + 6; 
                            temp_dec = obj.dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                            temp_value = ((temp_dec*4.5/(2^23-1)))*10^6;
                            output(iTem, coloum_j)=temp_value;                      
                        end
                        iTem = iTem + 1;
                        iRec = endPtr + 1;
                        % 如果原始数据已经读完，跳出
                        % 如果要求的数据已经足够，跳出
                        if iRec > receiveNum || iTem - 1 == obj.dataFrameLength
                            popIndex = iRec;
                            break
                        end
                    else
                        iRec = startPtr + 1;
                        % 如果原始数据已经读完，跳出
                        if iRec > receiveNum 
                            popIndex = iRec;
                            break
                        end
                    end
                end
            end

            obj.BufferFlag = obj.BufferPop(popIndex, obj.BufferFlag);

            % 如果已经赋值的输出个数不为数据长度，启用自动补齐
            if iTem-1 ~= obj.dataFrameLength
                output = obj.expend(output,iTem - 1);
                warning('数据使用了自动补齐');
            end
        end
    end
    
    %% 静态方法 不需要实例对象
    methods (Static)  
        
        %保证数据完整性
        function output = expend(data,iEnd)
            DATA_NUM = size(data,1);
            if iEnd < DATA_NUM
                temp = data(iEnd-(DATA_NUM-iEnd-1):iEnd,:);
                data(iEnd+1:end,:) = flip(temp,1);
            end
            output = data;
        end
        
        %数据转化
        function output = dec2dec(a,b,c)
            output = a * 65536 + b * 256 + c;
            if a  > 128
                output = output - 2^24;
            end
        end
        
    end
    
    %% 属性
    properties (Access = public)
        
        % 基本参数
        DeviceType; %设备类型
        OneFrameByte; %一帧数据字节长度
        DeviceCom;  %设备端口
        SampleRate; %采样率
        SampleGain;   %放大倍数
        EEG_COM; %与下位机通信端口对象
        
    end

    %
    %
    % 下面是实现读取数据的程序
    % 分为在在线和离线两种模式
    % 
    %

    properties (Access = public)
        % 原始数据数列BUFFER
        DataBuffer;
        % 重要！每次BufferPush和Pop的时候都把它作为参数传入，并传出，验证Push和Pop是否是匹配的
        BufferFlag;
        % 数据序列，使用DataSequenceOutput和DataSequenceInput进行读取更改
        DataSequence;
        % 数据序列要求的最小长度
        dataLength;
        % 指示数据序列是否准备好了，为true时可以读取
        isDataReady; 
        % 指示数据是否有丢失
        isLastData;

        % 数据读取模式
        readMode;

        % 一帧的数据个数
        dataFrameLength;

    end


    %
    % 在线模式调用方法
    %

    methods (Access = public)
        function OnlineInit(obj,refreshRate,timeLength)
        %OnlineInit - 进行在线模式的初始化
        %
        % Syntax:  obj.OnlineInit(refreshRate,timeLength)
        % refreshRate:      在线数据更新频率(Hz)
        % timeLength:       在线数据的时间长度
        %
            try
                % 设置模式为在线
                obj.readMode = 'Online';
                % 复位标志位
                obj.isDataReady = false;
                % 清空数据序列
                obj.DataSequence = zeros(0);
                % 计算需要的buffer大小并且多存1帧
                obj.dataLength = round(obj.SampleRate * timeLength);

                obj.dataFrameLength = round(obj.SampleRate / refreshRate);

                bytesCount = (obj.dataFrameLength+ 1) * obj.OneFrameByte ;

                baud_rate = 921600;
                parity = 'none';
                data_bits = 8; 
                stop_bits = 1;  
                % 设置串口缓冲区的大小,当缓冲区满时进行回调函数的调用
                obj.EEG_COM = serial (strcat('com',num2str(obj.DeviceCom)));
                set(obj.EEG_COM, 'BaudRate', baud_rate, 'Parity', parity, 'DataBits', ...
                data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', bytesCount, ...
                'BytesAvailableFcnMode', 'byte',...
                'InputBufferSize', bytesCount);
                % 根据matlab社区的要求修改了回调函数的调用方法
                obj.EEG_COM.BytesAvailableFcn =@(src,event)obj.SerialRead(src,event,obj);
                % 尝试打开串口
                fopen(obj.EEG_COM);
                % 停止并清空串口缓存区
                obj.ReadStop();
                fprintf('Online Mode initialized!\n');
            catch
                warning('Online Mode initialization failed!\n');
            end

        end

        function  OfflineInit(obj, timeLength)
        %OfflineInit - 离线模式初始化
        %
        % Syntax:  = OfflineInit(obj, timeLength)
        % timeLength:   离线数据需要多长
        %
            try
                % 设置模式为离线
                obj.readMode = 'Offline';
                % 复位标志位
                obj.isDataReady = false;
                % 清空数据序列
                obj.DataSequence = zeros(0);
                % 计算最小需要数据点数
                obj.dataLength = round(obj.SampleRate * timeLength);

                obj.dataFrameLength = obj.dataLength;
                % 读取一次需要的字节数
                bytesCount = (obj.dataFrameLength + 1) * obj.OneFrameByte;

                baud_rate = 921600;
                parity = 'none';
                data_bits = 8; 
                stop_bits = 1;  
                % 设置串口缓冲区的大小,当缓冲区满时进行回调函数的调用
                obj.EEG_COM = serial (strcat('com',num2str(obj.DeviceCom)));
                set(obj.EEG_COM, 'BaudRate', baud_rate, 'Parity', parity, 'DataBits', ...
                data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', bytesCount, ...
                'BytesAvailableFcnMode', 'byte',...
                'InputBufferSize', bytesCount);
                % 根据matlab社区的要求修改了回调函数的调用方法
                obj.EEG_COM.BytesAvailableFcn =@(src,event)obj.SerialRead(src,event,obj);
                % 尝试打开串口
                fopen(obj.EEG_COM);
                % 停止并清空串口缓存区
                obj.ReadStop();
                fprintf('Offline Mode initialized!\n');
            catch
                warning('Offline Mode initialization failed!\n');
            end            
        end

        function  ReadStart(obj)
        %ReadStart - 开始进行读取
        %
        % Syntax:  obj.ReadStart()
        %
            try
                if ~isempty(obj.DataBuffer)
                    obj.DataBuffer = [];
                end
                fopen(obj.EEG_COM);
                % 向下位机发送开始发送数据的指令
                fwrite(obj.EEG_COM, [83 83], 'uint8', 'async');
                fprintf('Read start!\n');
            catch err
                warning(err.message);
                warning('Read failed!');
            end
            
        end

        function ReadStop(obj)
        %ReadStop - 停止串口，并清空串口输入缓存区
        %
        % Syntax:  obj.ReadStop()
        %
        % 
            % 把数据准备位复位
            obj.isDataReady = false;
            % 向下位机发送停止发送数据的指令
            fwrite(obj.EEG_COM, [69 69], 'uint8', 'async'); % 协议需要更改
            pause(0.2);
            if obj.EEG_COM.BytesAvailable ~= 0
                fread(obj.EEG_COM, obj.EEG_COM.BytesAvailable); % 清空缓存区
            end
            fclose(obj.EEG_COM);
        end

        % 输入新的数据点，实现FIFO，数据可用位(isDataReady)的控制
        function DataSequenceInput(obj, ori_data)            
            try
                % 进行数据拼接
                obj.DataSequence = [obj.DataSequence; ori_data];
                % 如果数据序列长度已经超过了设置的要求的最小数据点数则舍去最早的点数，并且确定数据是否已经准备好
                if size(obj.DataSequence, 1 ) >= obj.dataLength
                    obj.DataSequence = obj.DataSequence((end - obj.dataLength + 1):end,:);
                    % 如果上一次的数据准备是true，说明用户没有在上一个读取周期中进行数据读取，发出警告提示
                    if obj.isDataReady == true
                        warning('有数据丢失发生！请检查数据处理程序的效能，如警告发生在端口停止过程中可以无视');
                        obj.isLastData = true;
                    else
                        obj.isLastData = false;
                    end
                    obj.isDataReady = true;
                else
                    obj.isDataReady = false;
                end
            catch
                %error('二进制数据解析出错！')
            end
        end

        % 输出目前的数据序列，并且复位数据可用位
        function output = DataSequenceOutput(obj)
            for i = 1 : obj.dataLength*10
                pause(0.001);
                if obj.isDataReady == true
                    output = obj.DataSequence;
                    obj.isDataReady = false;
                    % 如果是离线模式的话，输出一次后就停止串口
                    if strcmp(obj.readMode, 'Offline')
                        obj.ReadStop();
                    end
                    return
                end
            end
            error('读取数据超时');
        end

        % 对Buffer进行存入, 注意，只能使用BufferPush和BufferPop进行Buffer的读写
        function outFlag = BufferPush(obj, data, bufferFlag)
            % 如果是第一次进行Push,直接存入，并且不验证flag

            % data是一个列向量，改成行向量
            if isempty(obj.DataBuffer)
                obj.DataBuffer = data';
                outFlag = 'Pushed';
                return 
            end
            if ~strcmp(bufferFlag, 'Popped')
                error('BufferPush: BufferPush前没有进行Pop');
            end
            % 如果不是第一次进行Push并且bufferFlag也为'Popped'则直接将新data接到源程序后
            obj.DataBuffer = [obj.DataBuffer, data'];
            outFlag = 'Pushed';
        end

        % 对Buffer进行Pop，注意！该函数并不输出Buffer内的内容，只是进行数据的丢弃，需要丢弃后为头的数据下标
        function outFlag = BufferPop(obj, popIndex, bufferFlag)
            % 如果bufferFlag不是'Pushed'则报错
            if ~strcmp(bufferFlag, 'Pushed')
                error('BufferPop: BufferPop前没有进行Push');
            end

            % 如果已经完全读完，直接清空Buffer
            if popIndex > length(obj.DataBuffer)
                obj.DataBuffer = [];
            else
                obj.DataBuffer = obj.DataBuffer(:,popIndex:end);
            end
            outFlag = 'Popped';
        end


    end

    methods (Static, Access = private)
        function SerialRead(obj,~,drive)
            % 获取串口可获取的数据个数
%             availableCount = get(obj, 'BytesAvailable');
            % 若串口存在的数据，进行读取
%             if availableCount
                % fread读出所有缓存区所有数据，交给Decoding进行解析，然后将解析结果添加到DataSequence
            data = fread(obj);
            drive.BufferFlag =  drive.BufferPush(data, drive.BufferFlag);
            drive.DataSequenceInput(drive.Decoding());
        end
    end
end