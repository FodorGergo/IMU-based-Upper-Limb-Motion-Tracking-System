classdef udpReceiver < dataReceiver
    properties
        udpObj
    end
    methods
        function open(obj, params)
            obj.udpObj = udpport("LocalPort", params.port);
            flush(obj.udpObj);
        end

        function dataMatrix = readData(obj)
            dataMatrix = [];
            packetSize = 44;

            numBytes = obj.udpObj.NumBytesAvailable;
            if numBytes >= packetSize
                rawBytes = read(obj.udpObj, numBytes, "uint8");
                len = length(rawBytes);
                index = 1;

                while index <= len - packetSize + 1
                    % Fejléc ellenőrzés (0xAA = 170, 0xBB = 187)
                    if rawBytes(index) == 170 && rawBytes(index+1) == 187
                        packet = rawBytes(index : index + packetSize - 1);

                        % Checksum számítás (3-43 bájtok XOR-ja)
                        calcChecksum = uint8(0);
                        for k = 3:43
                            calcChecksum = bitxor(calcChecksum, packet(k));
                        end

                        if calcChecksum == packet(44)
                            id = double(packet(3));
                            vals = typecast(uint8(packet(4:43)), 'single');
                            dataMatrix = [dataMatrix; id, double(vals(:)')];
                            index = index + packetSize;
                        else
                            index = index + 1;
                        end
                    else
                        index = index + 1;
                    end
                end
            end
        end


        function close(obj)
            if ~isempty(obj.udpObj) && isvalid(obj.udpObj)
                delete(obj.udpObj);
            end
        end
    end
end