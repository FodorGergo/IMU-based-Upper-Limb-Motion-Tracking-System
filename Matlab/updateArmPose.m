function updateArmPose( ...
        patch_upper_arm, patch_forearm, patch_hand, ...
        marker_elbow, marker_wrist,... %marker_upper_arm, marker_forearm, marker_hand, ...
        V_local_upper_arm, V_local_forearm, V_local_hand, ...
        size_upper_arm, size_forearm, size_hand, ...
        R_upper_arm, R_forearm, R_hand, ...
        upper_arm_fix)
    
    if ~isvalid(patch_upper_arm) || ~isvalid(patch_forearm), 
        return; 
    end
    
    % Felkar
    V_upper_shifted = V_local_upper_arm + [size_upper_arm(1)/2, 0, 0];
    V_upper_rotated = (R_upper_arm * V_upper_shifted')';
    V_upper_final = V_upper_rotated + upper_arm_fix;
    set(patch_upper_arm, 'Vertices', V_upper_final);
    % ------------------------------------------------------------------------------------------------------------------------------
    % Felső marker
    % top_upper_local = [size_upper_arm(1)/2; 0; size_upper_arm(3)/2]; 
    % top_upper_final = upper_arm_fix' + (R_upper_arm * top_upper_local);
    % set(marker_upper_arm, 'XData', top_upper_final(1), 'YData', top_upper_final(2), 'ZData', top_upper_final(3));
    % % ------------------------------------------------------------------------------------------------------------------------------
    elbow_pos = upper_arm_fix' + (R_upper_arm * [size_upper_arm(1); 0; 0]);
    
    % Alkar
    V_forearm_shifted = V_local_forearm + [size_forearm(1)/2, 0, 0];
    V_forearm_rotated = (R_forearm * V_forearm_shifted')';
    V_forearm_final = V_forearm_rotated + elbow_pos';
    set(patch_forearm, 'Vertices', V_forearm_final);
    % ------------------------------------------------------------------------------------------------------------------------------
    % % Alsó marker
    % top_forearm_local = [size_forearm(1)/2; 0; size_forearm(3)/2];
    % top_forearm_final = elbow_pos + (R_forearm * top_forearm_local);
    % set(marker_forearm, 'XData', top_forearm_final(1), 'YData', top_forearm_final(2), 'ZData', top_forearm_final(3));
    % % ------------------------------------------------------------------------------------------------------------------------------
    
    wrist_pos = elbow_pos + (R_forearm * [size_forearm(1); 0; 0]);

    % Kézfej
    V_hand_shifted = V_local_hand + [size_hand(1)/2, 0, 0];
    V_hand_rotated = (R_hand * V_hand_shifted')';
    V_hand_final = V_hand_rotated + wrist_pos';
    set(patch_hand, 'Vertices', V_hand_final);
    % % Kez marker
    % top_hand_local = [size_hand(1)/2; 0; size_hand(3)/2];
    % top_hand_final = wrist_pos + (R_hand * top_hand_local);
    % set(marker_hand, 'XData', top_hand_final(1), 'YData', top_hand_final(2), 'ZData', top_hand_final(3));
    % % ------------------------------------------------------------------------------------------------------------------------------
    
    % Markerek
    set(marker_elbow, 'XData', elbow_pos(1), 'YData', elbow_pos(2), 'ZData', elbow_pos(3));
    set(marker_wrist, 'XData', wrist_pos(1), 'YData', wrist_pos(2), 'ZData', wrist_pos(3));

    drawnow limitrate;
end
