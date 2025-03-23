% MATLAB Code for JPEG Compression with File Size Control
function jpegcompress(input_image_path, output_image_path, target_size_kb, resize_factor)
    % Input parameters:
    % input_image_path: Path to input image
    % output_image_path: Path to save compressed image
    % target_size_kb: Target file size in kilobytes (KB)
    % resize_factor: Optional resize factor (e.g., 0.5 = half size)
    
    % Default values
    if nargin < 1
        input_image_path = 'input_image.jpg';
    end
    if nargin < 2
        output_image_path = 'compressed_image.jpg';
    end
    if nargin < 3
        target_size_kb = 1500; % Default target: 500 KB
    end
    if nargin < 4
        resize_factor = 1; % Default: no resize
    end
    
    fprintf('Target file size: %d KB\n', target_size_kb);
    
    % Read the image
    try
        img = imread(input_image_path);
        [original_height, original_width, ~] = size(img);
        fprintf('Original image dimensions: %d x %d\n', original_width, original_height);
        
        % Get original file info
        info = dir(input_image_path);
        original_size_kb = info.bytes / 1024;
        fprintf('Original file size: %.1f KB\n', original_size_kb);
    catch
        error('Error: Could not read the image file. Please check the path and filename.');
    end
    
    % Resize if specified
    if resize_factor ~= 1
        img = imresize(img, resize_factor);
    end
    
    % Get dimensions after initial resize (if any)
    [current_height, current_width, ~] = size(img);
    fprintf('Working with dimensions: %d x %d\n', current_width, current_height);
    
    % Two-step approach:
    % 1. Try using just quality adjustment
    % 2. If that doesn't work, use resizing as well
    
    % Step 1: Try quality adjustment
    quality = 95;
    current_size_kb = inf;
    min_quality = 5;
    
    while current_size_kb > target_size_kb && quality >= min_quality
        % Save with current quality
        imwrite(img, output_image_path, 'jpg', 'Quality', quality);
        
        % Check size
        info = dir(output_image_path);
        current_size_kb = info.bytes / 1024;
        
        % Adjust quality reduction based on how far we are from the target
        ratio = current_size_kb / target_size_kb;
        
        if ratio > 3
            % Far from target, reduce quality more aggressively
            quality = max(quality - 10, min_quality);
        elseif ratio > 1.5
            quality = max(quality - 5, min_quality);
        else
            % Close to target, reduce more gradually
            quality = max(quality - 2, min_quality);
        end
    end
    
    % Step 2: If we couldn't reach target size with quality alone, try resizing
    if current_size_kb > target_size_kb
        fprintf('Could not reach target size with quality adjustment alone.\n');
        fprintf('Starting combined quality and resize reduction...\n');
        
        % Start with modest resize
        current_resize = 0.9;
        min_resize = 0.1;
        quality = 30; % Start with low but acceptable quality
        
        while current_size_kb > target_size_kb && current_resize >= min_resize
            % Resize original image
            resized_img = imresize(img, current_resize);
            
            % Save with current quality
            imwrite(resized_img, output_image_path, 'jpg', 'Quality', quality);
            
            % Check size
            info = dir(output_path);
            current_size_kb = info.bytes / 1024;
            
            % If still too large, reduce size more
            if current_size_kb > target_size_kb
                current_resize = max(current_resize - 0.1, min_resize);
            end
        end
    end
    
    % Get final dimensions of the output file
    final_img = imread(output_image_path);
    [final_height, final_width, ~] = size(final_img);
    
    % Report final results
    info = dir(output_image_path);
    final_size_kb = info.bytes / 1024;
    
    fprintf('\n--- Compression Results ---\n');
    fprintf('Original size: %.1f KB (%d x %d)\n', original_size_kb, original_width, original_height);
    fprintf('Final size: %.1f KB (%d x %d)\n', final_size_kb, final_width, final_height);
    fprintf('Compression ratio: %.1f:1\n', original_size_kb / final_size_kb);
    fprintf('Target size: %d KB\n', target_size_kb);
    if final_size_kb <= target_size_kb
        fprintf('Target achieved! ✓\n');
    else
        fprintf('Could not reach target size while maintaining acceptable quality.\n');
        fprintf('Smallest achievable size: %.1f KB\n', final_size_kb);
    end
    
    % Display comparison
    figure;
    subplot(1, 2, 1);
    imshow(imread(input_image_path));
    title(sprintf('Original: %.1f KB', original_size_kb));
    
    subplot(1, 2, 2);
    imshow(imread(output_image_path));
    title(sprintf('Compressed: %.1f KB', final_size_kb));
    
    fprintf('\nCompressed image saved as: %s\n', output_image_path);
end

% Alternative function that focuses purely on reaching the target size
function compress_to_target_size(input_path, output_path, target_size_kb)
    % Simple function to compress an image to a specific target size
    % using a binary search approach to find the optimal quality
    
    img = imread(input_path);
    info = dir(input_path);
    original_size = info.bytes / 1024;
    
    fprintf('Original size: %.1f KB\n', original_size);
    fprintf('Target size: %d KB\n', target_size_kb);
    
    if original_size <= target_size_kb
        fprintf('Image already smaller than target size. Copying original.\n');
        imwrite(img, output_path);
        return;
    end
    
    % Binary search for the right quality value
    min_q = 1;
    max_q = 100;
    best_q = 50;
    best_size = inf;
    tolerance = 5; % KB tolerance
    max_iterations = 10;
    
    for i = 1:max_iterations
        current_q = round((min_q + max_q) / 2);
        
        % Try the current quality
        imwrite(img, output_path, 'jpg', 'Quality', current_q);
        info = dir(output_path);
        current_size = info.bytes / 1024;
        
        fprintf('Iteration %d: Quality %d -> Size %.1f KB\n', i, current_q, current_size);
        
        % Check if this is the best result so far
        if abs(current_size - target_size_kb) < abs(best_size - target_size_kb)
            best_q = current_q;
            best_size = current_size;
        end
        
        % If we're close enough, stop
        if abs(current_size - target_size_kb) < tolerance
            break;
        end
        
        % Adjust the search range
        if current_size > target_size_kb
            max_q = current_q - 1;
        else
            min_q = current_q + 1;
        end
        
        % If search range is exhausted, exit
        if min_q > max_q
            break;
        end
    end
    
    % Ensure we use the best quality found
    if best_size ~= current_size
        imwrite(img, output_path, 'jpg', 'Quality', best_q);
    end
    
    fprintf('\nFinal compression: Quality %d, Size %.1f KB\n', best_q, best_size);
    fprintf('Compression ratio: %.1f:1\n', original_size / best_size);
end