classdef serialReceiver < dataReceiver
    properties
        portObj
        buffer uint8 = uint8([])
    end
    methods
        function open(obj, params)
            % Régi portok törlése
            if ~isempty(serialportfind)
                delete(serialportfind);
                disp('Régi portok törölve');
            end

            % Port megnyitása és konfigurálása
            obj.portObj = serialport(params.portName, params.baudRate);
            obj.portObj.Timeout = 5;
            flush(obj.portObj);
            obj.buffer = uint8([]);

            disp(['Sikeres kapcsolat: ', char(params.portName)]);
        end

        function dataMatrix = readData(obj)
            dataMatrix = [];
            packetSize = 44;

            bytesAvailable = obj.portObj.NumBytesAvailable;
            if bytesAvailable > 0
                newBytes = read(obj.portObj, bytesAvailable, "uint8");
                obj.buffer = [obj.buffer, uint8(newBytes(:)')];
            end

            % Puffer túlzott feltorlódása elleni védelem (lag-preventer):
            % Ha több mint 10 csomag (440 bájt) felgyülemlett, a legutolsó 440 bájtra ugrunk
            if length(obj.buffer) > packetSize * 10
                obj.buffer = obj.buffer(end - (packetSize * 10) + 1 : end);
            end

            while length(obj.buffer) >= packetSize
                % Header ellenőrzése (0xAA = 170, 0xBB = 187)
                if obj.buffer(1) == 170 && obj.buffer(2) == 187
                    packet = obj.buffer(1:packetSize);

                    % Checksum számítás (3-43 bájtok XOR-ja)
                    calcChecksum = uint8(0);
                    for k = 3:43
                        calcChecksum = bitxor(calcChecksum, packet(k));
                    end

                    if calcChecksum == packet(44)
                        id = double(packet(3));
                        vals = typecast(uint8(packet(4:43)), 'single');
                        dataMatrix = [dataMatrix; id, double(vals(:)')];
                        obj.buffer(1:packetSize) = [];
                    else
                        % Hibás checksum esetén eldobunk 1 bájtot
                        obj.buffer(1) = [];
                    end
                else
                    % Ha nem fejléc, eldobunk 1 bájtot
                    obj.buffer(1) = [];
                end
            end
        end

        function close(obj)
            if ~isempty(obj.portObj) && isvalid(obj.portObj)
                delete(obj.portObj);
            end
        end
    end
end
