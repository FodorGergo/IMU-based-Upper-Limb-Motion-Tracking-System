% ------------------------------------------------------------------------------------------------------------------------------
% PROGRAM: 3D mozgáskövetés 
% SZERZŐ: Fodor Gergő 
% DÁTUM: 2025.11.04
% Utolsó módosítás: 2026.03.14
% Utolsó ismert észrevétel:
% Előfeltétel (Clamp) koordinátarendszerek:
% Tesztből megvan 1 testre, hogy hogyan kellene megolani, a
% koordinátarendszert. Kell 1 referencia szenzor, valamint mind a 2 szenzor leddel felfelé, valamint tetejével kifelé kell kalibrálni. 
%Következő lépés: Korlátozás megoldása/ kiterjesztés több testre?
% ------------------------------------------------------------------------------------------------------------------------------

% ------------------------------------------------------------------------------------------------------------------------------
% Teendők: 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Nem begfelelő baud esetén hibaüzenet (próba volt, nem jött be, ezzel még foglalkozni kell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Anatómiai korlátok (szög korlátozás - clamp)  (próba volt, részben jó volt az alkar behajlítása jó lehet, de a dőlés és a csavarás még buggos) 
% Ízületi szögek - MEGVAN 
% Kalibráció - MEGVAN
% Betanító adatok
% Mozgásfelismerés 
% Validáció
%%%%%%%%%%%%%%%%%%%%%%% Akadozás megszüntetés (mondhatni megvan)   
% ------------------------------------------------------------------------------------------------------------------------------

% ------------------------------------------------------------------------------------------------------------------------------
%% Külső függvények
% switchMode() - Soros / Wifi mód váltogatás
% initialSerial() - Soros kapcsolaat inicializálása
% boxGeometry() - Testek megalkotása
% updateArmPose() - Kar mozgásának frissítése
% clapJointRotation()  - Szögtartomány beállítása
% ------------------------------------------------------------------------------------------------------------------------------

% ------------------------------------------------------------------------------------------------------------------------------
%% Lokális függvények
% refreshSettings() - Beállítások frissítése 
% connectSerial() - Kapcsolat létrehozása
% startProgram() - Futtatás
% stopProgram() - Megállítás
% disconnectSerial() - Kapcsolat megszűntetése
% Calibration() - Kalibráció
% exitProgram() - Kilépés

% ------------------------------------------------------------------------------------------------------------------------------

function Program()

    clearvars; close all; clc;
    app = struct(); % Központi adattároló struktúra
    
    
    %% Főablak (GUI)
    app.figure = uifigure('Name','3D Mozgáskövetés','Position', [0 50 1920 787]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); %%% Ablakbezárással a program is leáll

    %% GUI elrendezés
    grids = uigridlayout(app.figure,[2 2]); %2x2 felosztás
    grids.ColumnWidth = {320,'1x'};         % Oszlop elrendezés (fix - flex)
    grids.RowHeight = {'1x', '1x'};         % Sor magassága (flex - flex)
    
    % ------------------------------------------------------------------------------------------------------------------------------
    %%% GUI felépítése
    %% Panelek
    % Létrehozás
    panel_control = uipanel(grids,'Title','Vezérlés','TitlePosition','centertop');
    panel_control.Layout.Row = 1; panel_control.Layout.Column = 1;

    panel_feedback = uipanel(grids,'Title','Visszajelzés','TitlePosition','centertop');
    panel_feedback.Layout.Row = 2; panel_feedback.Layout.Column = 1;

    panel_display = uipanel(grids,'Title','3D Mozgáskövetés');
    panel_display.Layout.Row = [1 2]; panel_display.Layout.Column = 2;

    % Beállítások
    panel_control_grid = uigridlayout(panel_control,[9 2]);
    panel_control_grid.RowHeight = {25, 25, 25, 25, 25, 25, 25, 25, 65};
    panel_control_grid.ColumnWidth = {'1x','1x'}; % A második oszlop szélesebb a beviteli mezőknek

    panel_feedback_grid = uigridlayout(panel_feedback,[6 2]);
    
    grid_display = uigridlayout(panel_display, [1 1]);
    model_ax = uiaxes(grid_display);
    axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
    xlabel(model_ax,'X'); ylabel(model_ax,'Y'); zlabel(model_ax,'Z');
    view(model_ax,3);                                                                   % 3D megjelenítés
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    % Koordinátarendszer thresholdok
    
    % ------------------------------------------------------------------------------------------------------------------------------
    
    % ------------------------------------------------------------------------------------------------------------------------------
    %%% I/O komponensek

    %% Kapcsolat választó
    uilabel(panel_control_grid,'Text','Kapcsolat:','HorizontalAlignment','right');
    dropdown_mode = uidropdown(panel_control_grid, 'Items', {'Soros port', 'Wifi'},'Value', 'Soros port');
    
    %% Soros kapcsolat
    % Portválasztás
    label_serial_port = uilabel(panel_control_grid,'Text','Soros port szám: (COM):','HorizontalAlignment','right','Tag','SerialGroup');
    label_serial_port.Layout.Row = 2; label_serial_port.Layout.Column = 1;
    
    port = uieditfield(panel_control_grid, 'numeric','Tag','SerialGroup', 'Visible','on'); 
    port.Layout.Row = 2; port.Layout.Column = 2;
    app.portName= "COM" + string(port.Value);
    
    % Szimbólumsebesség  (szimbólm/s)
    label_baud = uilabel(panel_control_grid,'Text','Baud:','HorizontalAlignment','right', 'Tag','SerialGroup');
    label_baud.Layout.Row = 3; label_baud.Layout.Column = 1;

    baud = uidropdown(panel_control_grid,'Items',{'115200','230400','460800'},'Value','115200', 'Tag','SerialGroup');
    baud.Layout.Row = 3; baud.Layout.Column = 2;
    app.baudRate= baud.Value;

    %% Wifi kapcsolat
    % IP-cím
    label_ip = uilabel(panel_control_grid,'Text','IP Cím:','HorizontalAlignment','right', 'Tag','WifiGroup', 'Visible','off');
    label_ip.Layout.Row = 2; label_ip.Layout.Column = 1;

    ip = uieditfield(panel_control_grid, 'text', 'Value', '192.168.4.1','Tag','WifiGroup', 'Visible','off');
    ip.Layout.Row = 2; ip.Layout.Column = 2;
    
    % Wifi port
    label_wifi_port = uilabel(panel_control_grid,'Text','Wifi Port:','HorizontalAlignment','right', 'Tag','WifiGroup', 'Visible','off');
    label_wifi_port.Layout.Row = 3; label_wifi_port.Layout.Column = 1;
    wifi_port = uieditfield(panel_control_grid, 'numeric', 'Value', 8080,'Tag','WifiGroup', 'Visible','off');
    wifi_port.Layout.Row = 3; wifi_port.Layout.Column = 2;
    
    %% Vezérlő gombok
    % Port keresés
    button_refresh = uibutton(panel_control_grid,'Text','Port keresés (Frissít)','Tag','SerialGroup');
    button_refresh.Layout.Row = 4; button_refresh.Layout.Column = [1 2];
    
    % Csatlakozás
    button_connect = uibutton(panel_control_grid,'Text','Csatlakozás');
    button_connect.Layout.Row = 5; button_connect.Layout.Column = 1;
    
    % Megszakítás
    button_disconnect = uibutton(panel_control_grid,'Text','Lecsatlakozás','Enable','off');
    button_disconnect.Layout.Row = 5; button_disconnect.Layout.Column = 2;
        
    % Indítás
    button_start = uibutton(panel_control_grid,'Text','Indítás','Enable','off');
    button_start.Layout.Row = 6; button_start.Layout.Column = 1;
    
    % Leállítás
    button_stop = uibutton(panel_control_grid,'Text','Megállítás','Enable','off');
    button_stop.Layout.Row = 6; button_stop.Layout.Column = 2;
    
    % Kalibráció
    button_calibrate  = uibutton(panel_control_grid, 'Text', 'Kalibráció', 'Enable', 'off', 'FontWeight', 'bold');
    button_calibrate.Layout.Row = 7; button_calibrate.Layout.Column = [1 2];
    
    % Kilépés
    button_exit = uibutton(panel_control_grid,'Text','Kilépés','Enable','on');
    button_exit.Layout.Row = 8; button_exit.Layout.Column = [1 2];

    % Állapot
    label_status = uilabel(panel_control_grid,'Text','Status: Disconnected');
    label_status.Layout.Row = 9; label_status.Layout.Column = [1 2];

    %% Visszajelzés
    % Mozgásforma
    label_movement_type = uilabel(panel_feedback_grid,'Text','Mozgásforma:','HorizontalAlignment','left');
    label_movement_type.Layout.Row = 1; label_movement_type.Layout.Column = [1 2];
    
    % Könyök szög
    label_elbow_angle = uilabel(panel_feedback_grid, 'Text', 'Könyök szög: 0°','HorizontalAlignment','left');
    value_elbow_angle.Layout.Row = 2; value_elbow_angle.Layout.Column = [1 2];
    
    % Csukló szög
    label_wrist_angle = uilabel(panel_feedback_grid, 'Text', 'Csukló szög: 0°','HorizontalAlignment','left');
    value_wrist_angle.Layout.Row = 3; value_wrist_angle.Layout.Column = [1 2];
    
    % ------------------------------------------------------------------------------------------------------------------------------
    
    % ------------------------------------------------------------------------------------------------------------------------------
    %% 3D modellek
    % Kar méretek és geometria
    app.size_upper_arm = [30 10 10];
    app.size_forearm = [30 10 10];
    app.size_hand = [10 10 10];
    app.upper_arm_fix = [0, 0, 30];

    % Csúcsok és oldalak
    [app.V_local_upper_arm, app.Faces] = boxGeometry(app.size_upper_arm);
    [app.V_local_forearm, ~] = boxGeometry(app.size_forearm);
    [app.V_local_hand, ~] = boxGeometry(app.size_hand);

    % Patchek - Felkar/Alkar/Kézfej
    app.patch_upper_arm = patch(model_ax, 'Vertices', app.V_local_upper_arm, 'Faces', app.Faces, 'FaceColor', 'red', 'FaceAlpha', 0.5);
    app.patch_forearm   = patch(model_ax, 'Vertices', app.V_local_forearm, 'Faces', app.Faces, 'FaceColor', 'green', 'FaceAlpha', 0.5);
    app.patch_hand      = patch(model_ax, 'Vertices', app.V_local_hand, 'Faces', app.Faces, 'FaceColor', 'blue', 'FaceAlpha', 0.5);
    
    % Plotok létrehozása - Könyök/Csukló + szögívek
    app.marker_elbow    = plot3(model_ax, 0, 0, 0, 'mo','MarkerSize', 12,'MarkerFaceColor', 'm');
    app.marker_wrist    = plot3(model_ax, 0, 0, 0, 'mo','MarkerSize', 12);

    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % ÚJ MARKEREK: A testek teteje (Orientáció vizualizálása)
    % app.marker_upper_arm = plot3(model_ax, 0, 0, 0, 'ro','MarkerSize', 8, 'MarkerFaceColor', 'w');
    % app.marker_forearm   = plot3(model_ax, 0, 0, 0, 'go','MarkerSize', 8, 'MarkerFaceColor', 'w');
    % app.marker_hand      = plot3(model_ax, 0, 0, 0, 'bo','MarkerSize', 8, 'MarkerFaceColor', 'w');
    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % ------------------------------------------------------------------------------------------------------------------------------
 
    % ------------------------------------------------------------------------------------------------------------------------------
    % Alaphelyzet
    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    updateArmPose(app.patch_upper_arm, app.patch_forearm, app.patch_hand, ... 
                  app.marker_elbow, app.marker_wrist, ... 
                  app.V_local_upper_arm, app.V_local_forearm, app.V_local_hand, ... 
                  app.size_upper_arm, app.size_forearm, app.size_hand, ... 
                  eye(3), eye(3), eye(3), ... 
                  app.upper_arm_fix);
    drawnow;
    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    % ------------------------------------------------------------------------------------------------------------------------------

    % ------------------------------------------------------------------------------------------------------------------------------
    % Kalibráció
    app.R_offset_upper_arm = eye(3);
    app.R_offset_forearm = eye(3);
    app.R_offset_hand = eye(3);
    
    % Kalibrációs kérés jelzése
    app.requestCalibration = false;
    
    % ------------------------------------------------------------------------------------------------------------------------------
    % Callback-ek
    dropdown_mode.ValueChangedFcn = @(src,event) switchMode(src,panel_control_grid);    
    button_refresh.ButtonPushedFcn = @(src,event) refreshSettings();                    
    button_exit.ButtonPushedFcn = @(src,event) exitProgram();                          
    button_connect.ButtonPushedFcn = @(src,event) connectSerial();                      
    button_disconnect.ButtonPushedFcn = @(src,event) disconnectSerial();                
    button_start.ButtonPushedFcn = @(src,event) startProgram();                            
    button_stop.ButtonPushedFcn = @(src,event) stopProgram();                              
    button_calibrate.ButtonPushedFcn  = @(src,event) Calibration();
    
    % ------------------------------------------------------------------------------------------------------------------------------
 
    % ------------------------------------------------------------------------------------------------------------------------------
    % Lokális függvények
    
    function refreshSettings()
        % Leírás: 
        % Az inputokból kiolvassa és menti a megadott soros port paramétereit. 

        app.portName = "COM" + string(port.Value);
        app.baudRate = str2double(baud.Value);
        
        % Output
        label_status.Text = "Beállítás frissítve: " + app.portName + ", " + baud.Value;
        label_status.FontColor = 'w';
    end
    
    function connectSerial()
        % Leírás: 
        % Megkísérli a soros kommunikáció létrehozását a beállított paraméterek alapján.
        
        % Paraméterek
        app.portName = "COM" + string(port.Value);
        app.baudRate = str2double(baud.Value);
        
        % Soros kapcsolat
        try
            app.serial = initialSerial(app.portName, app.baudRate);  % Külső függvény

            
            label_status.Text = "Csatlakozva: " + app.portName;
            label_status.FontColor = 'g';
            button_start.Enable = 'on';
            button_disconnect.Enable = 'on';

        catch errConnection
            label_status.Text = "Hiba: " + errConnection.message;
            label_status.WordWrap = 'on';
            label_status.FontColor = 'r';
            label_status.FontSize = 9;
        end
    end

    function startProgram()

        % Leírás: 

        %!!!!!!
        % if isempty(app.serial)
        %     uialert(app.figure, 'Nincs aktív kapcsolat!', 'Hiba');
        %     return; 
        % end
        %!!!!!!

        app.run = true; % Fut-e a program? 
        button_start.Enable = 'off';
        button_stop.Enable = 'on';
        button_disconnect.Enable = 'off';
        button_calibrate.Enable = 'on';

        label_status.Text = 'Adatok fogadása...';
        label_status.FontColor = [0 0.8 0];

        % Kezdő mátrixok
        R_upper_arm = eye(3);
        R_forearm = eye(3);
        R_hand = eye(3);

        while app.run
            if ~isvalid(app.figure), 
                break; 
            end
            
            % % % % % % % Buffer flush
            % % % % % % if app.serial.NumBytesAvailable > 50
            % % % % % %     flush(app.serial, "input");
            % % % % % %     %pause(0.002);
            % % % % % %     % continue;
            % % % % % % end

            % Adatolvasás
            if app.serial.NumBytesAvailable > 0
                try
                    line = char(readline(app.serial));
                    
                    % 1. szenzor - Felkar
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); % 4 szám 
                        if length(data) == 4
                            R_upper_arm = quat2rotm(data');
                        end
                    
                    % 2. szenzor - Alkar
                    elseif startsWith(line, '1:')
                        data = sscanf(line, '1: %f %f %f %f'); 
                        if length(data) == 4
                            R_forearm = quat2rotm(data'); 
                        end
                    
                    % 3. szenzor : Kézfej
                    elseif startsWith(line, '2:')
                        data = sscanf(line, '2: %f %f %f %f'); 
                        if length(data) == 4
                            R_hand = quat2rotm(data'); 
                        end
                    end

                    % Kalibráció
                    if app.requestCalibration

                        % A transzponált az inverz R^-1 = R^T
                        app.R_offset_upper_arm = R_upper_arm'; 
                        app.R_offset_forearm = R_forearm';
                        app.R_offset_hand = R_hand';
                        
                        app.requestCalibration = false;
                        
                        label_status.Text = 'Kalibráció türtént!';
                        label_status.FontColor = 'b';
                        pause(1);
                    end
                    
                    % R_final = R_offset * R
                    R_upper_arm_final = app.R_offset_upper_arm * R_upper_arm;
                    R_forearm_final = app.R_offset_forearm * R_forearm;
                    R_hand_final = app.R_offset_hand * R_hand;

                    % --------------------------------------------------------------------------------------------------------------
                    %% Ízületi szögek számítása

                    % a*b = |a|*|b|*cos(Théta)
                    % cos(Théta) = (a*b)/(|a|*|b|)

                    % Irányvektorok
                    v_upper_arm = R_upper_arm_final(:, 1); 
                    v_forearm = R_forearm_final(:, 1); 
                    v_hand = R_hand_final(:, 1); 

                    % Skaláris szorzatok 
                    cos_theta_elbow = dot(v_upper_arm, v_forearm);
                    cos_theta_wrist = dot(v_forearm, v_hand);

                    % Számítási pontatlanságokból eredő hibák kivédése (Clamp -1 és 1 közé)
                    cos_theta_elbow = max(-1, min(1, cos_theta_elbow));
                    cos_theta_wrist = max(-1, min(1, cos_theta_wrist));

                    angle_elbow_deg = real(rad2deg(acos(cos_theta_elbow)));
                    angle_wrist_deg = real(rad2deg(acos(cos_theta_wrist)));
                    label_elbow_angle.Text = sprintf('Könyök szög: %.1f°', angle_elbow_deg);
                    label_wrist_angle.Text = sprintf('Csukló szög: %.1f°', angle_wrist_deg);
                    
                    % --------------------------------------------------------------------------------------------------------------
                    
                    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    % Szöghatárok
                    
                    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    
                    % Modell frissítése
                    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
                    updateArmPose(app.patch_upper_arm, app.patch_forearm, app.patch_hand, ... 
                                  app.marker_elbow, app.marker_wrist,...
                                  app.V_local_upper_arm, app.V_local_forearm, app.V_local_hand, ... 
                                  app.size_upper_arm, app.size_forearm, app.size_hand, ... 
                                  R_upper_arm_final, R_forearm_final, R_hand_final, ... 
                                  app.upper_arm_fix);
                    
                    drawnow limitrate;
                    % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          
                    
                catch errRead
                    fprintf('Beolvasási hiba: %s\n', errRead.message);
                end
            else
                pause(0.002);
            end
        end
    end

    function stopProgram()

        % Leírás: 
        % Leállítja az adatok feldolgozását.

        app.run = false;
        button_start.Enable = 'on';
        button_stop.Enable = 'off';
        button_disconnect.Enable = 'on';
        label_status.Text = "Mérés leállítva.";
    end

    function disconnectSerial()
        % Leírás:
        % A soros kapcsolat biztonságos bontása
        try
            if ~isempty(app.serial)
                delete(app.serial);
                app.serial = [];
            end
    
            label_status.Text = "Lecsatlakozva.";
            button_connect.Enable = "on";
            button_disconnect.Enable = "off";
            button_start.Enable = "off";
            button_stop.Enable = "off";
    
        catch errDisconnect
            label_status.Text = "Hiba: " + errDisconnect.message;
        end
    end
    
    function Calibration()
        % Leírás:
        % Elindít egy kalibrációt
        app.requestCalibration = true;
        label_status.Text = "Kalibrálás folyamatban...";
    end

    function exitProgram()
        % Leírás:
        % Leállítja és bezárja a programot,megszakítja a kapcsolatot
            app.run = false;
        
            if isfield(app, "serial") && ~isempty(app.serial)
                try
                    delete(app.serial);
                catch errExit
                    label_status.Text = "Hiba: " + errExit.message;
                end
            end
            delete(app.figure);
     end
    
end