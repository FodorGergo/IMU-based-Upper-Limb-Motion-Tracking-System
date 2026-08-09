classdef armModel < handle
    properties
        % 3D grafikus elemek
        patch_upper_arm
        patch_forearm
        patch_hand

        % Geometria
        size_upper_arm
        size_forearm
        size_hand
        shoulder_origin % [X, Y, Z]
        isLeftArm       

        % Helyi csúcsok
        V_local_upper_arm
        V_local_forearm
        V_local_hand

        % Nyers és kalibrációs mátrixok
        R_raw_upper_arm; R_raw_forearm; R_raw_hand;
        R_calib_upper_arm; R_calib_forearm; R_calib_hand;

        % Euler-szögek 
        eul_shoulder; eul_elbow; eul_wrist;
    end
    
    methods
        function obj = armModel(p_upper_arm, p_forearm, p_hand, sizes, origin, isLeft)
            obj.patch_upper_arm = p_upper_arm;
            obj.patch_forearm   = p_forearm;
            obj.patch_hand      = p_hand;
           
            
            obj.size_upper_arm      = sizes.upper_arm;
            obj.size_forearm       = sizes.forearm;
            obj.size_hand       = sizes.hand;
            obj.shoulder_origin = origin;
            obj.isLeftArm       = isLeft;
            
            I = eye(3);
            obj.R_raw_upper_arm = I; obj.R_raw_forearm = I; obj.R_raw_hand = I;
            obj.R_calib_upper_arm = I; obj.R_calib_forearm = I; obj.R_calib_hand = I;
            obj.eul_shoulder = [0 0 0]; obj.eul_elbow = [0 0 0]; obj.eul_wrist = [0 0 0];
            
            obj.V_local_upper_arm = obj.createBox(obj.size_upper_arm);
            obj.V_local_forearm  = obj.createBox(obj.size_forearm);
            obj.V_local_hand  = obj.createBox(obj.size_hand);
        end
        
        % Geometria
        function V = createBox(~, dimension)
            lenght = dimension(1)/2;   
            width = dimension(2)/2;     
            height = dimension(3)/2;    
            
            V = [
                -lenght -width -height;
                 lenght -width -height;
                 lenght  width -height;
                -lenght  width -height;
                -lenght -width  height;
                 lenght -width  height;
                 lenght  width  height;
                -lenght  width  height
            ];
        end
        
        
        % Szögtartományok statikus korlátozása
        function R_out = clampJoint(obj, joint_name, R_in, isCalibrated)
            eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
            modell_Z = -eul_deg(1); 
            modell_Y = -eul_deg(2); 
            modell_X = -eul_deg(3); 
            
            if obj.isLeftArm
                modell_Z = -modell_Z;
                modell_Y = -modell_Y;
                modell_X = -modell_X;
            end
            
            switch joint_name
                case 'shoulder'
                    if isCalibrated
                        modell_Z = max(min(modell_Z, 90), -110); 
                        modell_Y = max(min(modell_Y, 90), -90);  
                        modell_X = max(min(modell_X, 95), -95);  
                    end
                case 'elbow'
                    if isCalibrated
                        modell_Z = max(min(modell_Z, 5), -160); 
                        modell_Y = max(min(modell_Y, 95), -95);
                        modell_X = max(min(modell_X, 95), -95);
                    end
                case 'wrist'
                    if isCalibrated
                        modell_Z = max(min(modell_Z, 45), -45);
                        modell_Y = max(min(modell_Y, 90), -90);
                        modell_X = max(min(modell_X, 5), -5);
                    end
            end
            
            if obj.isLeftArm
                modell_Z = -modell_Z;
                modell_Y = -modell_Y; 
                modell_X = -modell_X; 
            end
            
            R_out = eul2rotm(deg2rad([-modell_Z, modell_Y, modell_X]), 'ZYX');
        end
        
        
        % Adatfrissítés
      
        function updateSensorData(obj, segmentId, quatVec)
            R = quat2rotm(quatVec);
            if segmentId == 0, obj.R_raw_upper_arm = R;
            elseif segmentId == 1, obj.R_raw_forearm = R;
            elseif segmentId == 2, obj.R_raw_hand = R;
            end
        end
        
        % Kalibráció
        function calibrate(obj)
            obj.R_calib_upper_arm = obj.R_raw_upper_arm;
            obj.R_calib_forearm  = obj.R_raw_forearm;
            obj.R_calib_hand  = obj.R_raw_hand;
        end
        
        
        % Kinematikai számítás 
        function computeKinematics(obj, R_chest_final, isCalibrated)
            % Offset korrekció
            R_final_upper_arm = obj.R_raw_upper_arm * obj.R_calib_upper_arm';
            R_final_forearm  = obj.R_raw_forearm * obj.R_calib_forearm';
            R_final_hand  = obj.R_raw_hand * obj.R_calib_hand';
            
            % Ízületi szögek (Forgatási mátrixok) 
            R_shoulder_joint = R_chest_final' * R_final_upper_arm;
            R_elbow_joint    = R_final_upper_arm' * R_final_forearm;
            R_wrist_joint    = R_final_forearm' * R_final_hand;
            
            % Ízületi szögek (Euler szögek) 
            obj.eul_shoulder = rad2deg(rotm2eul(R_shoulder_joint, 'ZYX'));
            obj.eul_elbow    = rad2deg(rotm2eul(R_elbow_joint, 'ZYX'));
            obj.eul_wrist    = rad2deg(rotm2eul(R_wrist_joint, 'ZYX'));
            
            % Clamp
            R_shoulder_viz = obj.clampJoint('shoulder', R_shoulder_joint, isCalibrated);
            R_elbow_viz    = obj.clampJoint('elbow', R_elbow_joint, isCalibrated);
            R_wrist_viz    = obj.clampJoint('wrist', R_wrist_joint, isCalibrated);
            
            % T-póz elforgatás (kalibrálásnál a karok vízszintesen kinyújtva állnak: Bal kar +Y, Jobb kar -Y felé)
            if obj.isLeftArm
                R_tpose = [0, -1, 0; 1, 0, 0; 0, 0, 1]; % Bal kar balra kinyújtva (+Y felé)
            else
                R_tpose = [0, 1, 0; -1, 0, 0; 0, 0, 1];  % Jobb kar jobbra kinyújtva (-Y felé)
            end

            R_shoulder_viz = R_shoulder_viz * R_tpose;
            
            % Geometria újjáépítése 
            % Felkar
            V_shifted_upper = obj.V_local_upper_arm + [-obj.size_upper_arm(1)/2, 0, 0];
            V_final_upper = (R_shoulder_viz * V_shifted_upper')' + obj.shoulder_origin;
            set(obj.patch_upper_arm, 'Vertices', V_final_upper);
            
            elbow_pos = (R_shoulder_viz * [-obj.size_upper_arm(1); 0; 0])' + obj.shoulder_origin;
            
            % Alkar
            V_shifted_fore = obj.V_local_forearm + [-obj.size_forearm(1)/2, 0, 0];
            R_global_fore = R_shoulder_viz * R_elbow_viz;
            V_final_fore = (R_global_fore * V_shifted_fore')' + elbow_pos;
            set(obj.patch_forearm, 'Vertices', V_final_fore);
            
            wrist_pos = (R_global_fore * [-obj.size_forearm(1); 0; 0])' + elbow_pos;
            
            % Kézfej
            V_shifted_hand = obj.V_local_hand + [-obj.size_hand(1)/2, 0, 0];
            R_global_hand = R_global_fore * R_wrist_viz;
            V_final_hand = (R_global_hand * V_shifted_hand')' + wrist_pos;
            set(obj.patch_hand, 'Vertices', V_final_hand);
            
            
        end
    end
end