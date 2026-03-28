function datalogger_test()
    clearvars; close all; clc;
    app = struct(); % Központi adattároló
    
    %% Főablak (GUI)
    app.figure = uifigure('Name','Datalogger Tesztkörnyezet','Position', [0 50 1200 700]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    
    grids = uigridlayout(app.figure,[2 2]); 
    grids.ColumnWidth = {320,'1x'};         
    grids.RowHeight = {'2x', '1x'};         
    
    %% Panelek
    panel_control = uipanel(grids,'Title','Vezérlés');
    panel_control.Layout.Row = 1; panel_control.Layout.Column = 1;
    panel_feedback = uipanel(grids,'Title','Visszajelzés');
    panel_feedback.Layout.Row = 2; panel_feedback.Layout.Column = 1;
    panel_display = uipanel(grids,'Title','3D / Adat vizualizáció');
    panel_display.Layout.Row = [1 2]; panel_display.Layout.Column = 2;
    
    %% Vezérlés elemei
    panel_control_grid = uigridlayout(panel_control,[8 2]);
    
    uilabel(panel_control_grid,'Text','COM Port:','HorizontalAlignment','right');
    port = uieditfield(panel_control_grid, 'numeric', 'Value', 3); 
    
    button_connect = uibutton(panel_control_grid,'Text','Csatlakozás');
    button_start = uibutton(panel_control_grid,'Text','Olvasás Indítása','Enable','off');
    
    % --- ÚJ: ADATNAPLÓZÓ GOMB ---
    button_record = uibutton(panel_control_grid,'Text','FELVÉTEL INDÍTÁSA', 'BackgroundColor', [0.8 0.2 0.2], 'FontColor', 'w', 'FontWeight', 'bold', 'Enable', 'off');
    button_record.Layout.Row = 5; button_record.Layout.Column = [1 2];
    
    label_status = uilabel(panel_control_grid,'Text','Status: Készen áll');
    label_status.Layout.Row = 8; label_status.Layout.Column = [1 2];
    
    %% Visszajelzés elemei
    panel_feedback_grid = uigridlayout(panel_feedback,[3 1]);
    label_elbow_angle = uilabel(panel_feedback_grid, 'Text', 'Könyök szög: 0°');
    label_wrist_angle = uilabel(panel_feedback_grid, 'Text', 'Csukló szög: 0°');
    label_record_status = uilabel(panel_feedback_grid, 'Text', 'Adatok rögzítése: KI', 'FontColor', 'r');
    
    %% 3D Ablak (Placeholder a teszthez)
    grid_display = uigridlayout(panel_display, [1 1]);
    model_ax = uiaxes(grid_display);
    axis(model_ax,'equal'); grid(model_ax,'on'); view(model_ax,3);
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);
    
    %% Datalogger Változók
    app.isRecording = false;
    app.loggedData = []; % Itt gyűjtjük az adatokat: [Idő, Könyök_szög, Csukló_szög]
    
    %% Callback-ek
    button_connect.ButtonPushedFcn = @(src,event) connectSerial();                      
    button_start.ButtonPushedFcn = @(src,event) startProgram(); 
    button_record.ButtonPushedFcn = @(src,event) toggleRecording();
    
    %% Lokális Függvények
    function connectSerial()
        app.portName = "COM" + string(port.Value);
        try
            app.serial = serialport(app.portName, 115200); % Közvetlen inicializálás a teszthez
            configureTerminator(app.serial, "LF");
            label_status.Text = "Csatlakozva: " + app.portName;
            button_start.Enable = 'on';
        catch err
            label_status.Text = "Hiba: " + err.message;
        end
    end

    function toggleRecording()
        if ~app.isRecording
            % Felvétel indítása
            app.isRecording = true;
            app.loggedData = []; % Memória törlése új felvételhez
            app.recordStartTime = tic; % Stopper indítása
            
            button_record.Text = 'FELVÉTEL LEÁLLÍTÁSA ÉS MENTÉS';
            button_record.BackgroundColor = [0.2 0.8 0.2]; % Zöld
            label_record_status.Text = 'Adatok rögzítése: FOLYAMATBAN...';
            label_record_status.FontColor = [0 0.8 0];
        else
            % Felvétel leállítása és CSV generálás
            app.isRecording = false;
            
            button_record.Text = 'FELVÉTEL INDÍTÁSA';
            button_record.BackgroundColor = [0.8 0.2 0.2]; % Vissza pirosra
            label_record_status.Text = 'Adatok rögzítése: MENTVE';
            label_record_status.FontColor = 'b';
            
            % --- ADATOK EXPORTÁLÁSA CSV-BE ---
            if ~isempty(app.loggedData)
                % Fejléc elkészítése
                header = {'Ido_mp', 'Konyok_szog', 'Csuklo_szog'};
                T = array2table(app.loggedData, 'VariableNames', header);
                
                % Fájlba írás
                filename = 'Meresi_Adatok.csv';
                writetable(T, filename);
                label_status.Text = "Adatok sikeresen mentve: " + filename;
            end
        end
    end

    function startProgram()
        app.run = true; 
        button_start.Enable = 'off';
        button_record.Enable = 'on'; % Csak olvasás közben lehessen rögzíteni
        
        R_raw_upper_arm = eye(3); R_raw_forearm = eye(3); R_raw_hand = eye(3);
        
        while app.run
            if ~isvalid(app.figure), break; end
            
            if app.serial.NumBytesAvailable > 0
                line = char(readline(app.serial));
                
                % (Ide jön a te beolvasó logikád, most egyszerűsítve)
                if startsWith(line, '0:')
                    data = sscanf(line, '0: %f %f %f %f');
                    if length(data) == 4, R_raw_upper_arm = quat2rotm(data'); end
                elseif startsWith(line, '2:')
                    data = sscanf(line, '2: %f %f %f %f');
                    if length(data) == 4, R_raw_forearm = quat2rotm(data'); end
                elseif startsWith(line, '1:')
                    data = sscanf(line, '1: %f %f %f %f');
                    if length(data) == 4, R_raw_hand = quat2rotm(data'); end
                end
                
                % Szögek számítása (Saját calculateJointAngle függvényeddel)
                % (Most generálunk egy teszt adatot, hogy lásd hogyan működik a mentés)
                angle_elbow_deg = rand() * 90; % TESZT ADAT! Cseréld le a sajátodra!
                angle_wrist_deg = rand() * 45; % TESZT ADAT! Cseréld le a sajátodra!
                
                % GUI Frissítés
                label_elbow_angle.Text = sprintf('Könyök szög: %.1f°', angle_elbow_deg);
                label_wrist_angle.Text = sprintf('Csukló szög: %.1f°', angle_wrist_deg);
                
                % --- ADATOK NAPLÓZÁSA A MEMÓRIÁBA ---
                if app.isRecording
                    currentTime = toc(app.recordStartTime); % Eltelt idő másodpercben
                    newRow = [currentTime, angle_elbow_deg, angle_wrist_deg];
                    app.loggedData = [app.loggedData; newRow]; % Hozzáadás a táblázathoz
                end
                
                drawnow limitrate;
            else
                pause(0.002);
            end
        end
    end

    function exitProgram()
        app.run = false;
        if isfield(app, "serial") && ~isempty(app.serial), delete(app.serial); end
        delete(app.figure);
    end
end