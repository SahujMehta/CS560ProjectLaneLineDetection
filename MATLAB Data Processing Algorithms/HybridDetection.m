function finalHeadingAngle = combined_lane_detection_and_heading(pointCloudPath, imagePath)
    % Process LIDAR data
    [lidarHeadingAngle, lidarTrajectory] = lidar_lane_detection_and_heading(pointCloudPath);

    % Process Camera data
    [cameraHeadingAngle, cameraTrajectory] = lane_detection_and_heading(imagePath);

    % Merge Trajectories
    mergedTrajectory = mergeTrajectories(lidarTrajectory, cameraTrajectory);

    % Calculate Final Steering Angle
    finalHeadingAngle = calculateFinalHeadingAngle(mergedTrajectory);
end

function headingAngle = lidar_lane_detection_and_heading(pointCloudPath)

    % Load LiDAR Point Cloud
    ptCloud = pcread(pointCloudPath); % Load the point cloud

    % Validate Point Cloud
    if isempty(ptCloud)
        error('Point cloud data is empty or invalid.');
    end

    % Enhanced Data Preprocessing
    preprocessedData = preprocessPointCloud(ptCloud); % Call from LidarDetections.m

    % Process the point cloud to detect lane lines
    laneLines = detectLaneLinesFromPointCloud(preprocessedData); % Call from LidarDetections.m

    % Error handling if no lanes are detected
    if isempty(laneLines)
        headingAngle = NaN;
        warning('No lane lines detected.');
        return;
    end

    % Calculate the trajectory with noise reduction
    trajectory = calculateSmoothTrajectory(laneLines, size(ptCloud.Location, 1)); % Call from LidarDetections.m

    % Calculate the heading angle with additional error handling
    headingAngle = calculateHeadingAngle(trajectory); % Call from LidarDetections.m

    % Visualize the result with enhanced visualization
    visualizeLidarResult(ptCloud, laneLines, trajectory); % Call from LidarDetections.m
end


function [headingAngle, trajectory] = lane_detection_and_heading(imagePath)
    % Load the image
    frame = imread(imagePath); % Load the image

    % Process the image to detect lane lines
    lines = detectLaneLines(frame); % Call from CameraDetections.m

    % Calculate the trajectory
    trajectory = calculateTrajectory(lines, size(frame, 1)); % Call from CameraDetections.m

    % Calculate the heading angle
    headingAngle = calculateHeadingAngle(trajectory); % Call from CameraDetections.m

    % Visualize the result
    visualizeResult(frame, lines, trajectory); % Call from CameraDetections.m
end

function mergedTrajectory = mergeTrajectories(lidarTrajectory, cameraTrajectory)
    % lidarConfidence and cameraConfidence are values between 0 and 1 indicating the confidence of each sensors data can be tuned to balance detections
    lidarConfidence = 0.8;
    cameraConfidence = 0.2;

    % Normalize confidences
    totalConfidence = lidarConfidence + cameraConfidence;
    normalizedLidarConfidence = lidarConfidence / totalConfidence;
    normalizedCameraConfidence = cameraConfidence / totalConfidence;

    % Ensure that both trajectories have the same length
    % This is a simple resampling. For better results, consider interpolation methods.
    minLength = min(size(lidarTrajectory, 1), size(cameraTrajectory, 1));
    lidarTrajectory = lidarTrajectory(1:minLength, :);
    cameraTrajectory = cameraTrajectory(1:minLength, :);

    % Compute the weighted average of the trajectories
    mergedTrajectory = normalizedLidarConfidence * lidarTrajectory + normalizedCameraConfidence * cameraTrajectory;
end


% Function to calculate the final heading angle from the merged trajectory
function finalHeadingAngle = calculateFinalHeadingAngle(trajectory)
    finalHeadingAngle = calculateHeadingAngle(trajectory); % Reuse existing function
end
