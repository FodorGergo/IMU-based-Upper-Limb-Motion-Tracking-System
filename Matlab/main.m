% ------------------------------------------------------------------------------------------------------------------------------
% PROGRAM: 3D mozgáskövetés
% SZERZŐ: Fodor Gergő
% DÁTUM: 2025.11.04
% ------------------------------------------------------------------------------------------------------------------------------

function Main_GUI()
clearvars; close all; clc;
app = struct();
app.run = false;

% Főablak (GUI)
app.figure = uifigure('Name','3D Mozgáskövetés','Position', [0 50 1920 787]);
app.figure.CloseRequestFcn = @(~,~) exitProgram(); % Ablakbezárással a program is leáll

% GUI elrendezés
grids = uigridlayout(app.figure,[2 2]); %2x2 felosztás
grids.ColumnWidth = {320,'1x'};         % Oszlop elrendezés (fix - flex)
grids.RowHeight = {'2x', '1x'};         % Sor magassága (flex - flex)

% ------------------------------------------------------------------------------------------------------------------------------
% Panelek
panel_control = uipanel(grids,'Title','Vezérlés','TitlePosition','centertop');
panel_control.Layout.Row = 1; panel_control.Layout.Column = 1;
panel_feedback = uipanel(grids,'Title','Visszajelzés','TitlePosition','centertop');
panel_feedback.Layout.Row = 2; panel_feedback.Layout.Column = 1;
panel_display = uipanel(grids,'Title','3D Mozgáskövetés');
panel_display.Layout.Row = [1 2]; panel_display.Layout.Column = 2;

panel_control_grid = uigridlayout(panel_control,[12 2]);
panel_control_grid.RowHeight = {25, 25, 25, 25, 25, 25, 25, 25, 25, 90, 'fit','fit'};
panel_control_grid.ColumnWidth = {'1x','1x'};

panel_feedback_grid = uigridlayout(panel_feedback,[8 2]);
panel_feedback_grid.RowHeight = {18, 18, 18, 18, 18, 18, 18, 18};
panel_feedback_grid.RowSpacing = 2;
panel_feedback_grid.Padding = [5 5 5 5];
panel_feedback_grid.ColumnWidth = {'fit', '1x'};

grid_display = uigridlayout(panel_display, [1 1]);
model_ax = uiaxes(grid_display);
axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
xlabel(model_ax,'X (Hossz)'); ylabel(model_ax,'Y (Szélesség)'); zlabel(model_ax,'Z (Magasság)');
view(model_ax,3);                                                                   % 3D megjelenítés
xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    % Koordinátarendszer thresholdok

% ------------------------------------------------------------------------------------------------------------------------------
%% Vezérlés
% Kapcsolat választó
uilabel(panel_control_grid,'Text','Kapcsolat:','HorizontalAlignment','right');
dropdown_connection_mode = uidropdown(panel_control_grid, 'Items', {'Soros port', 'Wifi'},'Value', 'Soros port');

% Soros kapcsolat
label_serial_port = uilabel(panel_control_grid,'Text','Soros port szám: (COM):','HorizontalAlignment','right');
label_serial_port.Layout.Row = 2; label_serial_port.Layout.Column = 1;
port = uieditfield(panel_control_grid, 'numeric', 'Value', 3);
port.Layout.Row = 2; port.Layout.Column = 2;

label_baud = uilabel(panel_control_grid,'Text','Baud:','HorizontalAlignment','right');
label_baud.Layout.Row = 3; label_baud.Layout.Column = 1;
baud = uidropdown(panel_control_grid,'Items',{'115200','230400','460800','921600'},'Value','921600');
baud.Layout.Row = 3; baud.Layout.Column = 2;

% Wi-Fi kapcsolat
label_wifi_port = uilabel(panel_control_grid,'Text','Port:','HorizontalAlignment','right', 'Visible','off');
label_wifi_port.Layout.Row = 2; label_wifi_port.Layout.Column = 1;
wifi_port = uieditfield(panel_control_grid, 'numeric', 'Value', 8080, 'Visible','off');
wifi_port.Layout.Row = 2; wifi_port.Layout.Column = 2;

% Kapcsolat
button_connection = uibutton(panel_control_grid,'Text','Csatlakozás');
button_connection.Layout.Row = 5; button_connection.Layout.Column = [1 2];

% Kar választás
label_arm = uilabel(panel_control_grid,'Text','Megjelenített Adat:','HorizontalAlignment','right');
label_arm.Layout.Row = 4; label_arm.Layout.Column = 1;
dropdown_arm = uidropdown(panel_control_grid, 'Items', {'Mindkettő', 'Jobb kar', 'Bal kar'}, 'Value', 'Mindkettő');
dropdown_arm.Layout.Row = 4; dropdown_arm.Layout.Column = 2;

% Start/Stop
button_control = uibutton(panel_control_grid,'Text','Indítás','Enable','off');
button_control.Layout.Row = 6; button_control.Layout.Column = [1 2];

% Kalibráció
button_calibrate  = uibutton(panel_control_grid, 'Text', 'Kalibráció', 'Enable', 'off', 'FontWeight', 'bold');
button_calibrate.Layout.Row = 7; button_calibrate.Layout.Column = [1 2];

% Adatrögzítés
button_record = uibutton(panel_control_grid,'Text','Adatok rögzítése: KI', 'FontColor', 'w', 'FontWeight', 'bold', 'Enable', 'off');
button_record.Layout.Row = 8; button_record.Layout.Column = [1 2];
app.isRecording = false;
app.loggedData = [];
app.logIndex = 0;

% Bezárás
button_exit = uibutton(panel_control_grid,'Text','Kilépés');
button_exit.Layout.Row = 9; button_exit.Layout.Column = [1 2];

% Állapot
label_status = uilabel(panel_control_grid,'Text','Állapot: Lecsatlakozva', 'VerticalAlignment', 'top');
label_status.Layout.Row = 10; label_status.Layout.Column = [1 2];

% Fejlesztői adatok megjelenítése
checkbox_dev = uicheckbox(panel_control_grid, 'Text', 'Fejlesztői adatok megjelenítése', 'Value', 0);
checkbox_dev.Layout.Row = 11; checkbox_dev.Layout.Column = [1 2];
checkbox_dev.ValueChangedFcn = @(src,event) showDevMode(src);

% Gyakolat megjelenítésa
checkbox_guided = uicheckbox(panel_control_grid, 'Text', 'Gyakorló mód', 'Value', 0);
checkbox_guided.Layout.Row = 12; checkbox_guided.Layout.Column = [1 2];
checkbox_guided.ValueChangedFcn = @(src,event) showGuidedMode(src);
% ------------------------------------------------------------------------------------------------------------------------------
%% Visszajelzés
% Fejlesztői adatok - Jobb kar (Piros)
label_right_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Jobb kar'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_right_angle.Layout.Row = 1; label_right_angle.Layout.Column = [1 2];
label_right_shoulder_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Váll:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_right_shoulder_angle.Layout.Row = 2; label_right_shoulder_angle.Layout.Column = [1 2];
label_right_elbow_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Könyök:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_right_elbow_angle.Layout.Row = 3; label_right_elbow_angle.Layout.Column = [1 2];
label_right_wrist_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Csukló:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_right_wrist_angle.Layout.Row = 4; label_right_wrist_angle.Layout.Column = [1 2];

% Fejlesztői adatok - Bal kar (Kék)
label_left_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Bal kar'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_left_angle.Layout.Row = 5; label_left_angle.Layout.Column = [1 2];
label_left_shoulder_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Váll:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_left_shoulder_angle.Layout.Row = 6; label_left_shoulder_angle.Layout.Column = [1 2];
label_left_elbow_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Könyök:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_left_elbow_angle.Layout.Row = 7; label_left_elbow_angle.Layout.Column = [1 2];
label_left_wrist_angle = uilabel(panel_feedback_grid, 'Text', sprintf('Csukló:[Csavarás: 0° | Emelés: 0° | Forgatás: 0°]'), 'HorizontalAlignment', 'left', 'Visible', 'off', 'FontColor', 'r');
label_left_wrist_angle.Layout.Row = 8; label_left_wrist_angle.Layout.Column = [1 2];

% Gyakorló mód (Nagyobb prioritású elemek, ugyanazokra a sorokra illesztve)
label_exercise_title = uilabel(panel_feedback_grid, 'Text', 'Aktuális gyakorlat:', 'FontWeight', 'bold', 'Visible', 'off');
label_exercise_title.Layout.Row = 1; label_exercise_title.Layout.Column = 1;
dropdown_exercise = uidropdown(panel_feedback_grid, ...
    'Items', {'1. Gyakorlat', '2. Gyakorlat', '3. Gyakorlat', '4. Gyakorlat', '5. Gyakorlat'}, ...
    'Value', '1. Gyakorlat', 'Visible','off');
dropdown_exercise.Layout.Row = 1; dropdown_exercise.Layout.Column = 2;
dropdown_exercise.ValueChangedFcn = @(src,event) changeExercise(src);
gif_display = uiimage(panel_feedback_grid, 'ImageSource', 'bicepsz.gif', 'ScaleMethod', 'fit', 'Visible','off');
gif_display.Layout.Row = [2 4]; gif_display.Layout.Column = [1 2];
label_movement_type = uilabel(panel_feedback_grid,'Text','Mozgásforma:','HorizontalAlignment','left');
label_movement_type.Layout.Row = 5; label_movement_type.Layout.Column = [1 2];

% ------------------------------------------------------------------------------------------------------------------------------
%% 3D Modellek
sizes.upper_arm = [30 10 10];
sizes.forearm  = [30 10 10];
sizes.hand  = [10 10 10];

% Jobb kar
patch_upper_arm_R   = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'r', 'FaceAlpha', 0.6);
patch_forearm_R = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'g', 'FaceAlpha', 0.6);
patch_hand_R = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'b', 'FaceAlpha', 0.6);


% Bal kar Patchek
patch_upper_arm_L   = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'r', 'FaceAlpha', 0.6);
patch_forearm_L = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'g', 'FaceAlpha', 0.6);
patch_hand_L = patch(model_ax, 'Vertices', [], 'Faces', [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8], 'FaceColor', 'b', 'FaceAlpha', 0.6);


origin_L = [0, -25, 30]; % Bal kar a képernyő BAL oldalára (Y = -25)
origin_R = [0,  25, 30]; % Jobb kar a képernyő JOBB oldalára (Y = +25)

% Modell alaphelyzetbe állítása
app.arm_right = armModel(patch_upper_arm_R, patch_forearm_R, patch_hand_R, sizes, origin_R, false);
app.arm_left  = armModel(patch_upper_arm_L, patch_forearm_L, patch_hand_L, sizes, origin_L, true);

% ------------------------------------------------------------------------------------------------------------------------------
%% Kalibráció
app.R_raw_chest = eye(3);
app.R_calib_chest = eye(3);
app.isCalibrated = false;
app.requestCalibration = false;

% ------------------------------------------------------------------------------------------------------------------------------
% Callback-ek
dropdown_connection_mode.ValueChangedFcn = @(src,event) switchMode(src);
button_exit.ButtonPushedFcn = @(src,event) exitProgram();
button_connection.ButtonPushedFcn = @(src,event) Connection();
button_control.ButtonPushedFcn = @(src,event) runControl();
button_calibrate.ButtonPushedFcn  = @(src,event) Calibration();
button_record.ButtonPushedFcn = @(src,event) Recording();

% ------------------------------------------------------------------------------------------------------------------------------
% Lokális függvények
    function switchMode(src)
        if strcmp(src.Value, 'Wifi')
            label_serial_port.Visible = 'off'; port.Visible = 'off';
            label_baud.Visible = 'off'; baud.Visible = 'off';
            label_wifi_port.Visible = 'on'; wifi_port.Visible = 'on';
        else
            label_serial_port.Visible = 'on'; port.Visible = 'on';
            label_baud.Visible = 'on'; baud.Visible = 'on';
            label_wifi_port.Visible = 'off'; wifi_port.Visible = 'off';
        end
    end

    function showDevMode(src)
        if src.Value
            visState = 'on';
        else
            visState = 'off';
        end

        label_right_angle.Visible = visState;
        label_right_shoulder_angle.Visible = visState;
        label_right_elbow_angle.Visible = visState;
        label_right_wrist_angle.Visible = visState;

        label_left_angle.Visible = visState;
        label_left_shoulder_angle.Visible = visState;
        label_left_elbow_angle.Visible = visState;
        label_left_wrist_angle.Visible = visState;

        if checkbox_guided.Value
            uistack(label_exercise_title, 'top');
            uistack(dropdown_exercise, 'top');
            uistack(gif_display, 'top');
        end
    end

    function changeExercise(src)
        switch src.Value
            case '1. Könyökhajlítás'
                gif_display.ImageSource = 'bicepsz.gif';
            case '2. Alkar forgatás'
                gif_display.ImageSource = 'alkar_forgatas.gif';
            case '3. Váll előreemelés'
                gif_display.ImageSource = 'vall_elore.gif';
            case '4. Váll oldalra emelés'
                gif_display.ImageSource = 'vall_oldalra.gif';
            case '5. Váll csavarás'
                gif_display.ImageSource = 'vall_csavaras.gif';
        end
    end

    function Connection()
        if strcmp(button_connection.Text, 'Csatlakozás')
            try
                if strcmp(dropdown_connection_mode.Value, 'Wifi')
                    app.receiver = udpReceiver();
                    params.port = wifi_port.Value;
                else
                    app.receiver = serialReceiver();
                    params.portName = "COM" + string(port.Value);
                    params.baudRate = str2double(baud.Value);
                end

                app.receiver.open(params);

                label_status.Text = "Csatlakozva (" + dropdown_connection_mode.Value + ")";
                label_status.FontColor = 'g';
                button_connection.Text = 'Lecsatlakozás';
                button_control.Enable = 'on';

            catch errConnection
                label_status.Text = "Hiba: " + errConnection.message;
                label_status.FontColor = 'r';
                label_status.WordWrap = 'on';
                label_status.FontSize = 9;
            end
        else
            if isfield(app, 'receiver') && ~isempty(app.receiver)
                app.receiver.close();
            end
            label_status.Text = "Lecsatlakozva.";
            label_status.FontColor = 'k';
            button_connection.Text = 'Csatlakozás';
            button_control.Enable = "off";
            app.run = false;
        end
    end




    function showGuidedMode(src)
        if src.Value
            state = 'on';
            label_movement_type.Text='Helyesség:';
        else
            state = 'off';
            label_movement_type.Text='Mozgásforma:';
        end

        label_exercise_title.Visible = state;
        dropdown_exercise.Visible = state;
        gif_display.Visible = state;

    end
    function runControl()
        if ~app.run
            app.run = true;
            button_control.Text = 'Megállítás';
            button_calibrate.Enable = 'on';
            button_record.Enable = 'on';
            app.totalPacketCount = 0;
            app.lastDataTime = tic;
            label_status.Text = 'Adatok fogadása és feldolgozása...';
            label_status.FontColor = [0 0.8 0];

            % A Modern Aszinkron Főciklus
            while app.run
                if ~isvalid(app.figure), break; end

                % Adatok beolvasása
                dataMatrix = app.receiver.readData();

                if ~isempty(dataMatrix)
                    app.totalPacketCount = app.totalPacketCount + size(dataMatrix, 1);
                    app.lastDataTime = tic;

                    if ~isfield(app, 'lastUIUpdateTime')
                        app.lastUIUpdateTime = tic;
                    end

                    for row = 1:size(dataMatrix, 1)
                        sensorID = dataMatrix(row, 1);
                        quaternionVector = dataMatrix(row, 2:5);

                        if isfield(app, 'latestSensorBuffer') && sensorID >= 0 && sensorID <= 6 && size(dataMatrix, 2) >= 11
                            app.latestSensorBuffer(sensorID + 1, :) = dataMatrix(row, 2:11);
                        end

                        % Fix Hardver Kiosztás (7 szenzor / 2 kar):
                        % S3 = Mellkas
                        % S0, S1, S2 = BAL KAR (S0: Bal Kézfej, S1: Bal Alkar, S2: Bal Felkar)
                        % S4, S5, S6 = JOBB KAR (S4: Jobb Kézfej, S5: Jobb Alkar, S6: Jobb Felkar)
                        if sensorID == 3
                            app.R_raw_chest = quat2rotm(quaternionVector) * [1, 0, 0; 0, 0, 1; 0, -1, 0];
                            % BAL KAR
                        elseif sensorID == 2,  app.arm_left.updateSensorData(0, quaternionVector); % S2: Bal Felkar
                        elseif sensorID == 1,  app.arm_left.updateSensorData(1, quaternionVector); % S1: Bal Alkar
                        elseif sensorID == 0,  app.arm_left.updateSensorData(2, quaternionVector); % S0: Bal Kézfej
                            % JOBB KAR
                        elseif sensorID == 6,  app.arm_right.updateSensorData(0, quaternionVector); % S6: Jobb Felkar
                        elseif sensorID == 5,  app.arm_right.updateSensorData(1, quaternionVector); % S5: Jobb Alkar
                        elseif sensorID == 4,  app.arm_right.updateSensorData(2, quaternionVector); % S4: Jobb Kézfej
                        end
                    end

                    % Kalibráció
                    if app.requestCalibration
                        app.arm_right.calibrate();
                        app.arm_left.calibrate();
                        app.R_calib_chest = app.R_raw_chest;

                        app.requestCalibration = false;
                        app.isCalibrated = true;
                        label_status.Text = 'Kalibrálás megtörtént';
                    end

                    % Kinematikai frissítés és 3D rajzolás
                    chest_final = app.R_raw_chest * app.R_calib_chest';
                    app.arm_right.computeKinematics(chest_final, app.isCalibrated);
                    app.arm_left.computeKinematics(chest_final, app.isCalibrated);

                    % 3D Modell Láthatóságának beállítása a Dropdown alapján
                    switch dropdown_arm.Value
                        case 'Mindkettő'
                            set([app.arm_right.patch_upper_arm, app.arm_right.patch_forearm, app.arm_right.patch_hand], 'Visible', 'on');
                            set([app.arm_left.patch_upper_arm, app.arm_left.patch_forearm, app.arm_left.patch_hand], 'Visible', 'on');
                        case 'Jobb kar'
                            set([app.arm_right.patch_upper_arm, app.arm_right.patch_forearm, app.arm_right.patch_hand], 'Visible', 'on');
                            set([app.arm_left.patch_upper_arm, app.arm_left.patch_forearm, app.arm_left.patch_hand], 'Visible', 'off');
                        case 'Bal kar'
                            set([app.arm_right.patch_upper_arm, app.arm_right.patch_forearm, app.arm_right.patch_hand], 'Visible', 'off');
                            set([app.arm_left.patch_upper_arm, app.arm_left.patch_forearm, app.arm_left.patch_hand], 'Visible', 'on');
                    end

                    % UI Címkék frissítése 10 Hz-re korlátozva
                    if toc(app.lastUIUpdateTime) > 0.1
                        app.lastUIUpdateTime = tic;
                        label_status.Text = sprintf('Adatfolyam AKTÍV');
                        label_status.FontColor = [0 0.7 0];

                        eulR_shoulder = app.arm_right.eul_shoulder; eulR_elbow = app.arm_right.eul_elbow; eulR_wrist = app.arm_right.eul_wrist;
                        eulL_shoulder = app.arm_left.eul_shoulder;  eulL_elbow = app.arm_left.eul_elbow;  eulL_wrist = app.arm_left.eul_wrist;

                        label_right_shoulder_angle.Text = sprintf('Váll (Jobb):  [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulR_shoulder(3), eulR_shoulder(2), eulR_shoulder(1));
                        label_right_elbow_angle.Text    = sprintf('Könyök (Jobb): [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulR_elbow(3),    eulR_elbow(2),    eulR_elbow(1));
                        label_right_wrist_angle.Text    = sprintf('Csukló (Jobb): [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulR_wrist(3),    eulR_wrist(2),    eulR_wrist(1));

                        label_left_shoulder_angle.Text  = sprintf('Váll (Bal):   [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulL_shoulder(3), eulL_shoulder(2), eulL_shoulder(1));
                        label_left_elbow_angle.Text     = sprintf('Könyök (Bal):  [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulL_elbow(3),    eulL_elbow(2),    eulL_elbow(1));
                        label_left_wrist_angle.Text     = sprintf('Csukló (Bal):  [Csavarás: %4.1f° | Emelés: %4.1f° | Forgatás: %4.1f°]', eulL_wrist(3),    eulL_wrist(2),    eulL_wrist(1));
                    end

                    % Adatok rögzítése (Optimalizált tömb-hozzáfűzéssel)
                    if app.isRecording
                        currentTime = toc(app.recordStartTime);
                        if ~isfield(app, 'latestSensorBuffer') || isempty(app.latestSensorBuffer)
                            app.latestSensorBuffer = zeros(7, 10);
                        end
                        imuFlat = reshape(app.latestSensorBuffer', 1, []);
                        newRow = [currentTime, imuFlat, app.currentLabelID];
                        app.logIndex = app.logIndex + 1;
                        app.loggedData(app.logIndex, :) = newRow;
                    end

                    % Azonnali sima rajzolás minden beérkező adatcsomagra
                    drawnow limitrate;
                else
                    if isfield(app, 'lastDataTime') && toc(app.lastDataTime) > 1.5
                        label_status.Text = 'Várakozás ESP32 adatokra... (Nincs érkező csomag)';
                        label_status.FontColor = [0.85 0.2 0.2];
                    end
                    pause(0.002); % Mikro-szünet a CPU felpörgés és az akadozás megszüntetésére
                end
            end
        else
            if app.isRecording
                Recording(); % Leállítjuk a rögzítést ha a mérés leáll
            end
            app.run = false;
            button_control.Text = 'Indítás';
            button_record.Enable = 'off';
            label_status.Text = "Mérés leállítva.";
            label_status.FontColor = 'k';
        end
    end

    function Recording()
        if ~app.isRecording
            app.isRecording = true;
            app.recordStartTime = tic;
            app.loggedData = [];
            app.latestSensorBuffer = zeros(7, 10);

            % Címke felismerése a kiválasztott gyakorlatból
            selectedEx = dropdown_exercise.Value;
            if contains(selectedEx, '1.')
                app.currentLabelID = 1; app.currentLabelName = 'Konyokhajlitas';
            elseif contains(selectedEx, '2.')
                app.currentLabelID = 2; app.currentLabelName = 'AlkarForgatas';
            elseif contains(selectedEx, '3.')
                app.currentLabelID = 3; app.currentLabelName = 'VallEloreEmeles';
            elseif contains(selectedEx, '4.')
                app.currentLabelID = 4; app.currentLabelName = 'VallOldalraEmeles';
            elseif contains(selectedEx, '5.')
                app.currentLabelID = 5; app.currentLabelName = 'VallCsavaras';
            else
                app.currentLabelID = 0; app.currentLabelName = 'Gyakorlat';
            end

            button_record.Text = 'RÖGZÍTÉS FOLYAMATBAN (Stop)';
            button_record.BackgroundColor = [0.85 0.2 0.2];
            button_record.FontColor = 'w';
            label_status.Text = sprintf('Adatrögzítés elindítva: %s (ID: %d)', app.currentLabelName, app.currentLabelID);
            label_status.FontColor = [0.8 0 0];
        else
            app.isRecording = false;
            button_record.Text = 'Adatok rögzítése: KI';
            button_record.BackgroundColor = [0.94 0.94 0.94];
            button_record.FontColor = 'k';

            if ~isempty(app.loggedData)
                if ~exist('dataset', 'dir')
                    mkdir('dataset');
                end
                timeStr = datestr(now, 'yyyy-mm-dd_HHMMSS');
                fileNameBase = sprintf('dataset/Ex%d_%s_%s', app.currentLabelID, app.currentLabelName, timeStr);

                loggedData = app.loggedData;
                save([fileNameBase, '.mat'], 'loggedData');
                writematrix(loggedData, [fileNameBase, '.csv']);

                label_status.Text = sprintf('Mérés elmentve: %s.csv (%d sor)', fileNameBase, size(loggedData, 1));
                label_status.FontColor = [0 0.6 0];
            else
                label_status.Text = 'Rögzítés leállítva (nincs mentett adat).';
                label_status.FontColor = 'k';
            end
        end
    end

    function Calibration()
        app.requestCalibration = true;
    end

    function exitProgram()
        % Leállítja és bezárja a programot,megszakítja a kapcsolatot
        app.run = false;
        if isfield(app, "receiver") && ~isempty(app.receiver)
            app.receiver.close();
        end
        delete(app.figure);
    end
end