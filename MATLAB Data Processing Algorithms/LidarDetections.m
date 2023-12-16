function headingAngle = lidar_lane_detection_and_heading(pointCloudPath)
    % Load LiDAR Point Cloud
    ptCloud = pcread(pointCloudPath); % Load the point cloud

    % Validate Point Cloud
    if isempty(ptCloud)
        error('Point cloud data is empty or invalid.');
    end

    % Enhanced Data Preprocessing
    preprocessedData = preprocessPointCloud(ptCloud);

    % Process the point cloud to detect lane lines
    laneLines = detectLaneLinesFromPointCloud(preprocessedData);

    % Error handling if no lanes are detected
    if isempty(laneLines)
        headingAngle = NaN;
        warning('No lane lines detected.');
        return;
    end

    % Calculate the trajectory with noise reduction
    trajectory = calculateSmoothTrajectory(laneLines, size(ptCloud.Location, 1));

    % Calculate the heading angle with additional error handling
    headingAngle = calculateHeadingAngle(trajectory);

    % Visualize the result with enhanced visualization
    visualizeLidarResult(ptCloud, laneLines, trajectory);
end

function preprocessedData = preprocessPointCloud(ptCloud)
    % Noise Reduction using Statistical Outlier Removal
    ptCloud = pcdenoise(ptCloud);

    % Outlier Removal based on Distance
    distances = pdist2(ptCloud.Location, mean(ptCloud.Location, 1));
    threshold = mean(distances) + 2*std(distances);
    validPoints = distances <= threshold;

    % Return preprocessed data
    preprocessedData = select(ptCloud, validPoints);
end


function trajectory = calculateSmoothTrajectory(lines, imageHeight)
    % Initialize an array for the lane centers
    laneCenters = [];

    % Iterate over y-values
    for y = imageHeight:-10:0
        xPositions = [];
        
        % Calculate x-positions for each line
        for k = 1:length(lines)
            p1 = lines(k).point1;
            p2 = lines(k).point2;

            % Line intersection with current y-value
            if (p1(2) - y) * (p2(2) - y) < 0
                x = interp1([p1(2), p2(2)], [p1(1), p2(1)], y);
                xPositions(end + 1) = x;
            end
        end

        % Average x-position for lane center
        if ~isempty(xPositions)
            laneCenter = mean(xPositions);
            laneCenters = [laneCenters; [laneCenter, y]];
        end
    end

    % Apply a smoothing spline to reduce noise
    splineFit = fit(laneCenters(:,2), laneCenters(:,1), 'smoothingspline');
    smoothPoints = feval(splineFit, laneCenters(:,2));

    % Return the smooth trajectory
    trajectory = [smoothPoints, laneCenters(:,2)];
end


function headingAngle = calculateHeadingAngle(trajectory)
    if size(trajectory, 1) < 2
        headingAngle = NaN; % Cannot calculate angle
        return;
    end
    deltaY = trajectory(end, 2) - trajectory(1, 2);
    deltaX = trajectory(end, 1) - trajectory(1, 1);
    headingAngle = atan2(deltaY, deltaX); % Angle in radians
end

function visualizeLidarResult(ptCloud, laneLines, trajectory)
    % Create a figure for visualization
    figure;

    % Plot the original point cloud
    pcshow(ptCloud);
    hold on;

    % Plot each detected lane line
    for k = 1:length(laneLines)
        line = laneLines(k);
        p1 = line.point1;
        p2 = line.point2;
        plot3([p1(1), p2(1)], [p1(2), p2(2)], [p1(3), p2(3)], 'LineWidth', 2, 'Color', 'r');
    end

    % Plot the trajectory
    if ~isempty(trajectory)
        plot3(trajectory(:,1), trajectory(:,2), zeros(size(trajectory, 1), 1), 'LineWidth', 2, 'Color', 'g');
    end

    % Adjust plot properties
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('LiDAR Data with Detected Lane Lines and Trajectory');
    grid on;
    hold off;
end


function laneLines = detectLaneLinesFromPointCloud(ptCloud)
    % Project LiDAR data onto a 2D plane
    projectedData = projectLiDARto2D(ptCloud);

    % Filter the projected data to enhance potential lane lines
    filteredData = filterForLaneLines(projectedData);

    % Detect lane lines using a line detection algorithm
    laneLines = detectLines(filteredData);
end

function projectedData = projectLiDARto2D(ptCloud)
    % Extract x, y, and z coordinates
    x = ptCloud.Location(:,1);
    y = ptCloud.Location(:,2);
    z = ptCloud.Location(:,3);

    projectedData = [x, y];

end

function filteredData = filterForLaneLines(data)
    % Example of a simple threshold filter to focus on areas
    % where lane lines are more likely to be located.
    laneLineThreshold = 0.5; 
    
    % Apply a spatial filter or thresholding operation
    filteredData = data(data(:,2) < laneLineThreshold, :);
end


function lines = detectLines(data)
    binaryImage = false(1000, 1000);
    indices = sub2ind(size(binaryImage), data(:,1), data(:,2));
    binaryImage(indices) = true;

    % Apply Hough Transform to detect lines
    [H, theta, rho] = hough(binaryImage);
    peaks = houghpeaks(H, 5, 'threshold', ceil(0.3*max(H(:))));
    lines = houghlines(binaryImage, theta, rho, peaks, 'FillGap', 20, 'MinLength', 30);
end
