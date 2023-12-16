function headingAngle = lane_detection_and_heading(imagePath)
    % Read an Frame
    frame = imread(imagePath); % Load the image

    % Process the image to detect lane lines
    lines = detectLaneLines(frame);

    % Calculate the trajectory
    trajectory = calculateTrajectory(lines, size(frame, 1));

    % Calculate the heading angle
    headingAngle = calculateHeadingAngle(trajectory);

    % Visualize the result
    visualizeResult(frame, lines, trajectory);
end

function lines = detectLaneLines(frame)
    % Convert to Grayscale
    gray = rgb2gray(frame);

    % Apply Gaussian Blur
    blurred = imgaussfilt(gray, 2);

    % Edge Detection
    edges = edge(blurred, 'Canny');

    % Define Region of Interest (ROI)
    roi = [0, size(edges,1); size(edges,2), size(edges,1); size(edges,2)/2, size(edges,1)/2];
    mask = poly2mask(roi(:,1), roi(:,2), size(edges,1), size(edges,2));
    maskedEdges = edges & mask;

    % Hough Transform for Line Detection
    [H, theta, rho] = hough(maskedEdges);
    peaks = houghpeaks(H, 5, 'threshold', ceil(0.3*max(H(:))));
    lines = houghlines(maskedEdges, theta, rho, peaks, 'FillGap', 20, 'MinLength', 30);
end

function trajectory = calculateTrajectory(lines, imageHeight)
    % Initialize an array to hold the center points of the lane
    laneCenters = [];

    % Iterate over a range of y-values (vertical positions in the image)
    for y = imageHeight:-10:0
        xPositions = [];

        % For each line, calculate the x-position at the current y-value
        for k = 1:length(lines)
            % Get the start and end points of the line
            p1 = lines(k).point1;
            p2 = lines(k).point2;

            % Check if the line crosses the current y-value
            if (p1(2) - y) * (p2(2) - y) < 0
                % Interpolate the x-position at the current y-value
                x = interp1([p1(2), p2(2)], [p1(1), p2(1)], y);
                xPositions(end + 1) = x;
            end
        end

        % Calculate the average x-position (center of the lane) at this y-value
        if ~isempty(xPositions)
            laneCenter = mean(xPositions);
            laneCenters = [laneCenters; [laneCenter, y]];
        end
    end

    % Return the calculated trajectory
    trajectory = laneCenters;
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


function visualizeResult(frame, lines, trajectory)
    figure, imshow(frame), hold on;
    for k = 1:length(lines)
        xy = [lines(k).point1; lines(k).point2];
        plot(xy(:,1), xy(:,2), 'LineWidth', 2, 'Color', 'green');
    end
    plot(trajectory(:,1), trajectory(:,2), 'LineWidth', 2, 'Color', 'blue');
    hold off;
end

