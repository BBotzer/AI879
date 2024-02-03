I = imread('L06 sunflower.png');
mrp = multiresolutionPyramid(I,4);
%visualizePyramid(mrp);
lapp = laplacianPyramid(mrp);
%showLaplacianPyramid(lapp);
lapp_quantized = roundPixelValues(lapp);
out = reconstructFromLaplacianPyramid(lapp_quantized);
subplot(2,1,1); imshow(I); % Original
subplot(2,1,2); imshow(out);

function mrp = multiresolutionPyramid(A,num_levels)
    %multiresolutionPyramid(A,numlevels)
%   mrp = multiresolutionPyramid(A,numlevels) returns a multiresolution
%   pyramd from the input image, A. The output, mrp, is a 1-by-numlevels
%   cell array. The first element of mrp, mrp{1}, is the input image.
%
%   If numlevels is not specified, then it is automatically computed to
%   keep the smallest level in the pyramid at least 32-by-32.
%   from https://blogs.mathworks.com/steve/2019/04/09/multiresolution-image-pyramids-and-impyramid-part-2/
%   Steve Eddins
    A = im2double(A);
    M = size(A,1);
    N = size(A,2);
    if nargin < 2
        lower_limit = 32;
        num_levels = min(floor(log2([M N]) - log2(lower_limit))) + 1;
    else
        num_levels = min(num_levels, min(floor(log2([M N]))) + 2);
    end
    mrp = cell(1,num_levels);
    smallest_size = [M N] / 2^(num_levels - 1);
    smallest_size = ceil(smallest_size);
    padded_size = smallest_size * 2^(num_levels - 1);
    Ap = padarray(A,padded_size - [M N],'replicate','post');
    mrp{1} = Ap;
    for k = 2:num_levels
        mrp{k} = imresize(mrp{k-1},0.5,'bilinear');
    end
    mrp{1} = A;
end

function tiles_out = visualizePyramid(p)
    % Steve Eddins
    M = size(p{1},1);
    N = size(p{1},2);

    for k = 1:numel(p)
        Mk = size(p{k},1);
        Nk = size(p{k},2);
        Mpad1 = ceil((M - Mk)/2);
        Mpad2 = M - Mk - Mpad1;
        Npad1 = ceil((N - Nk)/2);
        Npad2 = N - Nk - Npad1;

        A = p{k};
        A = padarray(A,[Mpad1 Npad1],0.5,'pre');
        A = padarray(A,[Mpad2 Npad2],0.5,'post');
        p{k} = A;
    end
    tiles = imtile(p,'GridSize',[NaN 2],'BorderSize',20,'BackgroundColor',[0.3 0.3 0.3]);
    imshow(tiles)

    if nargout > 0
        tiles_out = tiles;
    end
end

function lapp = laplacianPyramid(mrp)
    % Steve Eddins
    lapp = cell(size(mrp));
    num_levels = numel(mrp);
    lapp{num_levels} = mrp{num_levels};
    for k = 1:(num_levels - 1)
        A = mrp{k};
        B = imresize(mrp{k+1},2,'bilinear');
        [M,N,~] = size(A);
        lapp{k} = A - B(1:M,1:N,:);
    end
    lapp{end} = mrp{end};
end

function showLaplacianPyramid(p)
    % Steve Eddins
    M = size(p{1},1);
    N = size(p{1},2);
    stretch_factor = 3;
    for k = 1:numel(p)
        Mk = size(p{k},1);
        Nk = size(p{k},2);
        Mpad1 = ceil((M - Mk)/2);
        Mpad2 = M - Mk - Mpad1;
        Npad1 = ceil((N - Nk)/2);
        Npad2 = N - Nk - Npad1;
        if (k < numel(p))
            pad_value = -0.1/stretch_factor;
        else
            pad_value = 0.4;
        end
        A = p{k};
        A = padarray(A,[Mpad1 Npad1],pad_value,'pre');
        A = padarray(A,[Mpad2 Npad2],pad_value,'post');
        p{k} = A;
    end

    for k = 1:(numel(p)-1)
        p{k} = (stretch_factor*p{k} + 0.5);
    end
    imshow(imtile(p,'GridSize',[NaN 2],'BorderSize',20,'BackgroundColor',[0.3 0.3 0.3]))
end

function lapp_quantized = roundPixelValues(lapp)
    for k = 1:(numel(lapp) - 1)
        lapp_quantized{k} = round(lapp{k},1);
    end
    lapp_quantized{numel(lapp)} = lapp{end};
end

function out = reconstructFromLaplacianPyramid(lapp)
    % Steve Eddins
    num_levels = numel(lapp);
    out = lapp{end};
    for k = (num_levels - 1) : -1 : 1
        out = imresize(out,2,'bilinear');
        g = lapp{k};
        [M,N,~] = size(g);
        out = out(1:M,1:N,:) + g;
    end
end
