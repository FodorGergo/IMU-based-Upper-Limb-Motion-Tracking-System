function serial = initialSerial(portName,baudRate)

    % Soros port megnyitása és tisztitása
    if ~isempty(serialportfind)
        delete(serialportfind);
        disp('Régi portok törölve');
    end
    
    try     
        serial = serialport(portName, baudRate);
        configureTerminator(serial, "LF"); % Objektum végén sortörés ( Line Feed )
        serial.Timeout = 5; % Maximum várakozás 
        flush(serial); % Soros buffer törlése
        pause(1); % Várakozás (1s)
        disp(['Sikeres kapcsolat: ' portName]);
        disp([portName 'port megnyitva, adatok olvasása...']);
    catch errSerial
        error(['Hiba a port megnyitásakor: ' errSerial.message]);
    end
end