%% EEGӲ����������ʵ�ִ���λ����ȡԭʼ���ݣ����������֮��ĸ�ͨ������
% %
%
% Ӳ��������ʼ�����豸���ͣ����ݶ˿ڣ������ʣ��Ŵ���������ʱ�䣩
% �޸���λ�������������ʡ��Ŵ���������ʱ�䣩
% ��ȡ���ݲ�����
% ���÷�ʽ��
%
% �ٳ�ʼ��ʵ����һ������
%     mydrive = EEG_Drive(Type,sCOM,Rate,Gain); 
%     Type:�豸���ͣ�4��8��;
%     sCOM:�豸�˿ں�;
%     Rate:�豸��ʼ������;����λ:Hz��
%     Gain:�豸��ʼ������;����λ:����
%     Time:�豸��ʼ������ʱ�䣨��λ���룩;
% eg: mydrive = EEG_Drive(4,12,500,2,2); 
% 
% ��ѡ��ģʽ��
%   ���ݶ�ȡ�ķ��������֣�����������
%       ����ģʽ�� mydrive.OnlineInit(refreshRate, timeLength)
%           refreshRate    :ˢ����(Hz)
%           timeLength     :�������ݵĳ���(s)
%               ����ģʽ�У��Ե����ݱ���Ϊһ���Ƚ��ȳ��Ķ��У���ʼ��ʱ��Ҫ��������ˢ�µ�Ƶ���Լ��������ݵĳ��ȣ�����ˢ�����Ƽ����ܳ���10Hz��
%       ����ģʽ�� mydrive.OfflineInit(timeLength)
%           timeLength     :�ɼ����ݵĳ���(s)
%               ������ģʽ�У��ɼ�ָ��ʱ�䳤�ȵ��Ե�����
% �ۿ�ʼ��ȡ��
%     mydrive.ReadStart();
%     �������ڲ���ʼ��ȡ����
%
% ��ֹͣ��ȡ��
%     mydrive.ReadStop();
%     �رմ��ڲ���������뻺�����е�����
%
% �ݻ�ȡ����
%     Output = mydrive.DataSequenceOutput();
%       Output {#timeLength, #channelNum}
%     ������ݶ��У���������κ�ʱ����ô˺�����������ݣ����Ǵ˺���������ģʽ�»����ڲ��ȴ�����ˢ�£�ֻ���µ����ݲ����˲Ż������Output��
%  �����ⲿ�����Ե����ݵĳ���ִ��һ�ε�ʱ������С������ˢ�µ����ڣ��������ܱ�֤ÿ��ȥ��ȡʱ�ܶ�ȡ�������ݲ��Ҳ��ᶪʧ���ݡ���ʧ���ݲ�����������ݴ���ֻ�ǽ��������ݵ������ʡ�
%     ������ģʽ�£�����ֻ�����һ�Σ���������ݾͱ���ա�
%
% ���޸Ĳ�����
%     mydrive.ChangeRate(value) 4ͨ���豸֧��250 500 1000��8ͨ���豸֧��250 500
%
% ���޸ķŴ���
%     mydrive.ChangeGain(value) 1 2 4 6 8 12 24
%
% ���޸Ĳ���ʱ��
%     mydrive.ChangeTime(value) 
%
% Zhang Yajun, Yin Wenhan,29-July-2019
% B504 of BeiHang University 
% %

%% ʵ��
classdef  EEG_Drive < handle
    
    %% ���з��� Ϊ�ⲿ�����ṩ�ӿ�
    methods (Access = public)
        %���캯��
        function obj = EEG_Drive(Type,sCOM,Rate,Gain)
            if nargin == 4
                obj.init(Type,sCOM,Rate,Gain);
                obj.init_Device_uart();
                WaitSecs(0.5);
                obj.ModifyMeasuringMode('input');%�޸Ĳ���ģʽΪ����
                WaitSecs(0.5);
                obj.writeDevice_uart(0, obj.SampleRate);%�޸Ĳ�����
                WaitSecs(0.5);
                obj.writeDevice_uart(1, obj.SampleGain);%�޸ķŴ���
                WaitSecs(0.5);
                obj.Close_Device_uart();%�ر����ݶ˿�

                % obj.isDataReady = false;
                % obj.StopCollect(); % ����ֹͣ�ɼ�ָ��
                % if obj.EEG_COM.BytesAvailable ~= 0
                %     fread(obj.EEG_COM, obj.EEG_COM.BytesAvailable); %��ջ�����
                % end
                % WaitSecs(0.3);
                % obj.StartCollect();% ���Ϳ�ʼ�ɼ�ָ��

                fprintf('EEG_Drive Success.\n');
            else
                fprintf('EEG_Drive Input Error!\n');
                clear obj
            end
            
            if nargout == 0
                clear obj
            end
        end
        
        %��������
        function delete(obj)
            delete(obj);
            delete(instrfind);
        end
        
        % %��ȡ����
        % function output = GetData(obj)
        %     % ReceiveData(obj);
        %     % output = obj.DeviceData;
        % end
        
        %�޸Ĳ����ʣ�ChangeType 0 writeDevice_uart(0��Value)
        function ChangeRate(obj, Value)
            try
                writeDevice_uart(obj,0, Value);
                WaitSecs(0.5);
                writeDevice_uart(obj,0, Value);
                WaitSecs(0.5);
            catch
                fprintf('���Ĳ�����ʧ�ܣ�\n');
            end
        end
        %�޸ķŴ�����ChangeType 1 writeDevice_uart(1��Value)
        function ChangeGain(obj, Value)
            try
                writeDevice_uart(obj,1, Value);
                WaitSecs(0.5);
                writeDevice_uart(obj,1, Value);
                WaitSecs(0.5);
            catch
                fprintf('����ʧ�ܣ�\n');
            end
        end

    end
    
    %% ˽�з���
    methods (Access = private)
        %��ʼ������
        function init(obj,Type,sCOM,Rate,Gain)
            obj.DeviceType = Type;
            obj.DeviceCom = sCOM;
            obj.SampleRate = Rate;
            obj.SampleGain = Gain;
            
            
            switch Type % ��ͨ���豸��8ͨ���豸ÿ֡���ݳ��Ȳ�ͬ
                case 4
                    obj.OneFrameByte = 20;
                case 8
                    obj.OneFrameByte = 34;
                otherwise
                fprintf('EEG_Drive DeviceType Error!\n');
            end
        end
        
        %��ʼ���豸����
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

        %�ر��豸����
        function Close_Device_uart(obj)
            fclose(obj.EEG_COM);
        end

        %�޸Ĳ���ģʽ
        function ModifyMeasuringMode(obj,Type)
            %�޸Ĳ���ģʽ 
            %
            % Syntax: ModifyMeasuringMode(Type)
            %
            % Type input ������λ���������  Type impedance ������λ���迹����
            switch Type
                case 'input'
                    fwrite(obj.EEG_COM, [83 84 77 48 69 68], 'uint8', 'async');
                case 'impedance'
                    fwrite(obj.EEG_COM, [83 84 77 49 69 68], 'uint8', 'async');
                otherwise
                    fprintf('�����ڴ˲���ģʽ��\n');
            end
        end
        
        %�����޸�����(ChangeType 0 �޸Ĳ����ʣ�ChangeType 1 �޸ķŴ���) writeDevice_uart(ChangeType��Value)
        function writeDevice_uart(obj,ChangeType, Value)%[83 84 71 0 0 0]
            if ChangeType == 0 %�޸Ĳ�����
                switch Value
                    case 250
                        fwrite(obj.EEG_COM, [83 84 82 54 69 68], 'uint8', 'async');
                        obj.SampleRate = Value;      
                        fprintf('�����ʸ��ĳɹ���\n');
                    case 500
                        fwrite(obj.EEG_COM, [83 84 82 53 69 68], 'uint8', 'async');
                        obj.SampleRate = Value;
                        fprintf('�����ʸ��ĳɹ���\n');
                    case 1000
                        if obj.DeviceType == 4
                            fwrite(obj.EEG_COM, [83 84 82 52 69 68], 'uint8', 'async');
                            obj.SampleRate = Value;
                            fprintf('�����ʸ��ĳɹ���\n');
                        else
                            fprintf('EEG_Drive ��֧�ָò�����! \n');
                        end
                    otherwise
                        fprintf('EEG_Drive ��֧�ָò�����! \n');
                end
            elseif ChangeType == 1 %�޸ķŴ���
                switch Value
                    case 1
                        fwrite(obj.EEG_COM, [83 84 71 0 0 0], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 2
                        fwrite(obj.EEG_COM, [83 84 71 36 146 73], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 4
                        fwrite(obj.EEG_COM, [83 84 71 73 36 146], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 6
                        fwrite(obj.EEG_COM, [83 84 71 109 182 219], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 8
                        fwrite(obj.EEG_COM, [83 84 71 146 73 36], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 12
                        fwrite(obj.EEG_COM, [83 84 71 182 219 109], 'uint8', 'async');
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;
                    case 24
                        fwrite(obj.EEG_COM, [83 84 71 219 109 182], 'uint8', 'async'); 
                        fprintf('�Ŵ������ĳɹ���\n');
                        obj.SampleGain = Value;                        
                    otherwise
                        fprintf('EEG_Drive ��֧�ָ÷Ŵ���(1 2 4 6 8 12 24)! \n');
                end
            end          
        end
                
        %�������е�DataBuffer���н��������Ҷ�������������
        function output = Decoding(obj)
            receiveNum = length(obj.DataBuffer);
            Tongdaoshu = obj.DeviceType;
            temp_data = zeros(obj.dataFrameLength,obj.OneFrameByte);
            output = zeros(obj.dataFrameLength, Tongdaoshu);
            iRec = 1;
            iTem = 1;
            if obj.DeviceType == 4
                while 1
                    % ��ʱһ֡���ݶ�Ӧ�����ұ��
                    startPtr = iRec;
                    endPtr = iRec + obj.OneFrameByte - 1;
                    % �����ʱԭʼ�����Ѿ�����һ֡������
                    if endPtr > receiveNum
                        popIndex = startPtr;
                        break
                    end

                    %% �ж� 55 55 AA AA ֡ͷ
                    if(obj.DataBuffer(startPtr) == 85 && obj.DataBuffer(startPtr + 1) == 85 && obj.DataBuffer(startPtr + 2) == 170 && obj.DataBuffer(startPtr + 3) == 170)
                        temp_data(iTem,:) = obj.DataBuffer(:,startPtr:endPtr);
                        for coloum_j = 1:1:Tongdaoshu  %%����ȡ��Tongdaoshu��ͨ������
                            coloum_i = 3 * coloum_j + 4; 
                            temp_dec = obj.dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                            temp_value = ((temp_dec*4.5/(2^23-1)))*10^6;
                            output(iTem, coloum_j)=temp_value;                      
                        end
                        iTem = iTem + 1;
                        iRec = endPtr + 1;
                        % ���ԭʼ�����Ѿ����꣬����
                        % ���Ҫ��������Ѿ��㹻������
                        if iRec > receiveNum || iTem - 1 == obj.dataFrameLength
                            popIndex = iRec;
                            break
                        end
                    else
                        iRec = startPtr + 1;
                        % ���ԭʼ�����Ѿ����꣬����
                        if iRec > receiveNum
                            popIndex = iRec;
                            break
                        end
                    end
                end
            end
            if obj.DeviceType == 8
                while 1
                    % ��ʱһ֡���ݶ�Ӧ�����ұ��
                    startPtr = iRec;
                    endPtr = iRec + obj.OneFrameByte - 1;
                    % �����ʱԭʼ�����Ѿ�����һ֡������
                    if endPtr > receiveNum
                        popIndex = startPtr;
                        break
                    end

                    %% 55 55 AA AA ֡ͷ
                    if(obj.DataBuffer(startPtr) == 85 && obj.DataBuffer(startPtr + 1) == 85 && obj.DataBuffer(startPtr + 2) == 170 && obj.DataBuffer(startPtr + 3) == 170)
                        temp_data(iTem,:) = obj.DataBuffer(:,startPtr:endPtr);
                        for coloum_j = 1:1:Tongdaoshu  %%����ȡ��Tongdaoshu��ͨ������
                            coloum_i = 3 * coloum_j + 6; 
                            temp_dec = obj.dec2dec(temp_data(iTem,coloum_i+1), temp_data(iTem, coloum_i+2), temp_data(iTem, coloum_i+3));                    
                            temp_value = ((temp_dec*4.5/(2^23-1)))*10^6;
                            output(iTem, coloum_j)=temp_value;                      
                        end
                        iTem = iTem + 1;
                        iRec = endPtr + 1;
                        % ���ԭʼ�����Ѿ����꣬����
                        % ���Ҫ��������Ѿ��㹻������
                        if iRec > receiveNum || iTem - 1 == obj.dataFrameLength
                            popIndex = iRec;
                            break
                        end
                    else
                        iRec = startPtr + 1;
                        % ���ԭʼ�����Ѿ����꣬����
                        if iRec > receiveNum 
                            popIndex = iRec;
                            break
                        end
                    end
                end
            end

            obj.BufferFlag = obj.BufferPop(popIndex, obj.BufferFlag);

            % ����Ѿ���ֵ�����������Ϊ���ݳ��ȣ������Զ�����
            if iTem-1 ~= obj.dataFrameLength
                output = obj.expend(output,iTem - 1);
                warning('����ʹ�����Զ�����');
            end
        end
    end
    
    %% ��̬���� ����Ҫʵ������
    methods (Static)  
        
        %��֤����������
        function output = expend(data,iEnd)
            DATA_NUM = size(data,1);
            if iEnd < DATA_NUM
                temp = data(iEnd-(DATA_NUM-iEnd-1):iEnd,:);
                data(iEnd+1:end,:) = flip(temp,1);
            end
            output = data;
        end
        
        %����ת��
        function output = dec2dec(a,b,c)
            output = a * 65536 + b * 256 + c;
            if a  > 128
                output = output - 2^24;
            end
        end
        
    end
    
    %% ����
    properties (Access = public)
        
        % ��������
        DeviceType; %�豸����
        OneFrameByte; %һ֡�����ֽڳ���
        DeviceCom;  %�豸�˿�
        SampleRate; %������
        SampleGain;   %�Ŵ���
        EEG_COM; %����λ��ͨ�Ŷ˿ڶ���
        
    end

    %
    %
    % ������ʵ�ֶ�ȡ���ݵĳ���
    % ��Ϊ�����ߺ���������ģʽ
    % 
    %

    properties (Access = public)
        % ԭʼ��������BUFFER
        DataBuffer;
        % ��Ҫ��ÿ��BufferPush��Pop��ʱ�򶼰�����Ϊ�������룬����������֤Push��Pop�Ƿ���ƥ���
        BufferFlag;
        % �������У�ʹ��DataSequenceOutput��DataSequenceInput���ж�ȡ����
        DataSequence;
        % ��������Ҫ�����С����
        dataLength;
        % ָʾ���������Ƿ�׼�����ˣ�Ϊtrueʱ���Զ�ȡ
        isDataReady; 
        % ָʾ�����Ƿ��ж�ʧ
        isLastData;

        % ���ݶ�ȡģʽ
        readMode;

        % һ֡�����ݸ���
        dataFrameLength;

    end


    %
    % ����ģʽ���÷���
    %

    methods (Access = public)
        function OnlineInit(obj,refreshRate,timeLength)
        %OnlineInit - ��������ģʽ�ĳ�ʼ��
        %
        % Syntax:  obj.OnlineInit(refreshRate,timeLength)
        % refreshRate:      �������ݸ���Ƶ��(Hz)
        % timeLength:       �������ݵ�ʱ�䳤��
        %
            try
                % ����ģʽΪ����
                obj.readMode = 'Online';
                % ��λ��־λ
                obj.isDataReady = false;
                % �����������
                obj.DataSequence = zeros(0);
                % ������Ҫ��buffer��С���Ҷ��1֡
                obj.dataLength = round(obj.SampleRate * timeLength);

                obj.dataFrameLength = round(obj.SampleRate / refreshRate);

                bytesCount = (obj.dataFrameLength+ 1) * obj.OneFrameByte ;

                baud_rate = 921600;
                parity = 'none';
                data_bits = 8; 
                stop_bits = 1;  
                % ���ô��ڻ������Ĵ�С,����������ʱ���лص������ĵ���
                obj.EEG_COM = serial (strcat('com',num2str(obj.DeviceCom)));
                set(obj.EEG_COM, 'BaudRate', baud_rate, 'Parity', parity, 'DataBits', ...
                data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', bytesCount, ...
                'BytesAvailableFcnMode', 'byte',...
                'InputBufferSize', bytesCount);
                % ����matlab������Ҫ���޸��˻ص������ĵ��÷���
                obj.EEG_COM.BytesAvailableFcn =@(src,event)obj.SerialRead(src,event,obj);
                % ���Դ򿪴���
                fopen(obj.EEG_COM);
                % ֹͣ����մ��ڻ�����
                obj.ReadStop();
                fprintf('Online Mode initialized!\n');
            catch
                warning('Online Mode initialization failed!\n');
            end

        end

        function  OfflineInit(obj, timeLength)
        %OfflineInit - ����ģʽ��ʼ��
        %
        % Syntax:  = OfflineInit(obj, timeLength)
        % timeLength:   ����������Ҫ�೤
        %
            try
                % ����ģʽΪ����
                obj.readMode = 'Offline';
                % ��λ��־λ
                obj.isDataReady = false;
                % �����������
                obj.DataSequence = zeros(0);
                % ������С��Ҫ���ݵ���
                obj.dataLength = round(obj.SampleRate * timeLength);

                obj.dataFrameLength = obj.dataLength;
                % ��ȡһ����Ҫ���ֽ���
                bytesCount = (obj.dataFrameLength + 1) * obj.OneFrameByte;

                baud_rate = 921600;
                parity = 'none';
                data_bits = 8; 
                stop_bits = 1;  
                % ���ô��ڻ������Ĵ�С,����������ʱ���лص������ĵ���
                obj.EEG_COM = serial (strcat('com',num2str(obj.DeviceCom)));
                set(obj.EEG_COM, 'BaudRate', baud_rate, 'Parity', parity, 'DataBits', ...
                data_bits, 'StopBits', stop_bits, 'BytesAvailableFcnCount', bytesCount, ...
                'BytesAvailableFcnMode', 'byte',...
                'InputBufferSize', bytesCount);
                % ����matlab������Ҫ���޸��˻ص������ĵ��÷���
                obj.EEG_COM.BytesAvailableFcn =@(src,event)obj.SerialRead(src,event,obj);
                % ���Դ򿪴���
                fopen(obj.EEG_COM);
                % ֹͣ����մ��ڻ�����
                obj.ReadStop();
                fprintf('Offline Mode initialized!\n');
            catch
                warning('Offline Mode initialization failed!\n');
            end            
        end

        function  ReadStart(obj)
        %ReadStart - ��ʼ���ж�ȡ
        %
        % Syntax:  obj.ReadStart()
        %
            try
                if ~isempty(obj.DataBuffer)
                    obj.DataBuffer = [];
                end
                fopen(obj.EEG_COM);
                % ����λ�����Ϳ�ʼ�������ݵ�ָ��
                fwrite(obj.EEG_COM, [83 83], 'uint8', 'async');
                fprintf('Read start!\n');
            catch err
                warning(err.message);
                warning('Read failed!');
            end
            
        end

        function ReadStop(obj)
        %ReadStop - ֹͣ���ڣ�����մ������뻺����
        %
        % Syntax:  obj.ReadStop()
        %
        % 
            % ������׼��λ��λ
            obj.isDataReady = false;
            % ����λ������ֹͣ�������ݵ�ָ��
            fwrite(obj.EEG_COM, [69 69], 'uint8', 'async'); % Э����Ҫ����
            pause(0.2);
            if obj.EEG_COM.BytesAvailable ~= 0
                fread(obj.EEG_COM, obj.EEG_COM.BytesAvailable); % ��ջ�����
            end
            fclose(obj.EEG_COM);
        end

        % �����µ����ݵ㣬ʵ��FIFO�����ݿ���λ(isDataReady)�Ŀ���
        function DataSequenceInput(obj, ori_data)            
            try
                % ��������ƴ��
                obj.DataSequence = [obj.DataSequence; ori_data];
                % ����������г����Ѿ����������õ�Ҫ�����С���ݵ�������ȥ����ĵ���������ȷ�������Ƿ��Ѿ�׼����
                if size(obj.DataSequence, 1 ) >= obj.dataLength
                    obj.DataSequence = obj.DataSequence((end - obj.dataLength + 1):end,:);
                    % �����һ�ε�����׼����true��˵���û�û������һ����ȡ�����н������ݶ�ȡ������������ʾ
                    if obj.isDataReady == true
                        warning('�����ݶ�ʧ�������������ݴ�������Ч�ܣ��羯�淢���ڶ˿�ֹͣ�����п�������');
                        obj.isLastData = true;
                    else
                        obj.isLastData = false;
                    end
                    obj.isDataReady = true;
                else
                    obj.isDataReady = false;
                end
            catch
                %error('���������ݽ�������')
            end
        end

        % ���Ŀǰ���������У����Ҹ�λ���ݿ���λ
        function output = DataSequenceOutput(obj)
            for i = 1 : obj.dataLength*10
                pause(0.001);
                if obj.isDataReady == true
                    output = obj.DataSequence;
                    obj.isDataReady = false;
                    % ���������ģʽ�Ļ������һ�κ��ֹͣ����
                    if strcmp(obj.readMode, 'Offline')
                        obj.ReadStop();
                    end
                    return
                end
            end
            error('��ȡ���ݳ�ʱ');
        end

        % ��Buffer���д���, ע�⣬ֻ��ʹ��BufferPush��BufferPop����Buffer�Ķ�д
        function outFlag = BufferPush(obj, data, bufferFlag)
            % ����ǵ�һ�ν���Push,ֱ�Ӵ��룬���Ҳ���֤flag

            % data��һ�����������ĳ�������
            if isempty(obj.DataBuffer)
                obj.DataBuffer = data';
                outFlag = 'Pushed';
                return 
            end
            if ~strcmp(bufferFlag, 'Popped')
                error('BufferPush: BufferPushǰû�н���Pop');
            end
            % ������ǵ�һ�ν���Push����bufferFlagҲΪ'Popped'��ֱ�ӽ���data�ӵ�Դ�����
            obj.DataBuffer = [obj.DataBuffer, data'];
            outFlag = 'Pushed';
        end

        % ��Buffer����Pop��ע�⣡�ú����������Buffer�ڵ����ݣ�ֻ�ǽ������ݵĶ�������Ҫ������Ϊͷ�������±�
        function outFlag = BufferPop(obj, popIndex, bufferFlag)
            % ���bufferFlag����'Pushed'�򱨴�
            if ~strcmp(bufferFlag, 'Pushed')
                error('BufferPop: BufferPopǰû�н���Push');
            end

            % ����Ѿ���ȫ���ֱ꣬�����Buffer
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
            % ��ȡ���ڿɻ�ȡ�����ݸ���
%             availableCount = get(obj, 'BytesAvailable');
            % �����ڴ��ڵ����ݣ����ж�ȡ
%             if availableCount
                % fread�������л������������ݣ�����Decoding���н�����Ȼ�󽫽��������ӵ�DataSequence
            data = fread(obj);
            drive.BufferFlag =  drive.BufferPush(data, drive.BufferFlag);
            drive.DataSequenceInput(drive.Decoding());
        end
    end
end