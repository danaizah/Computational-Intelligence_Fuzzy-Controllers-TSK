function [Dtrn, Dval, Dtst] = stratified_sampling_split_scale(data, preproc)

    % Identify unique class labels
    classes = unique(data(:, end));
    ratios = [0.6, 0.2, 0.2];

    Dtrn = [];
    Dval = [];
    Dtst = [];

    % Loop through each class and split proportionally
    for c = 1:numel(classes)
        classData = data(data(:, end) == classes(c), :);
        classData = classData(randperm(size(classData, 1)), :);  % shuffle
        
        n = size(classData, 1);
        nTrn = round(ratios(1) * n);
        nVal = round(ratios(2) * n);

        Dtrn = [Dtrn; classData(1:nTrn, :)];
        Dval = [Dval; classData(nTrn+1:nTrn+nVal, :)];
        Dtst = [Dtst; classData(nTrn+nVal+1:end, :)];
    end

    % Shuffle each set again
    Dtrn = Dtrn(randperm(size(Dtrn, 1)), :);
    Dval = Dval(randperm(size(Dval, 1)), :);
    Dtst = Dtst(randperm(size(Dtst, 1)), :);

    % Scale features to [0,1] using training bounds
    trnX = Dtrn(:, 1:end-1);
    valX = Dval(:, 1:end-1);
    tstX = Dtst(:, 1:end-1);

    if preproc == 1
        xmin = min(trnX, [], 1);
        xmax = max(trnX, [], 1);
        trnX = (trnX - xmin) ./ (xmax - xmin + eps);
        valX = (valX - xmin) ./ (xmax - xmin + eps);
        tstX = (tstX - xmin) ./ (xmax - xmin + eps);
    end

    % Reattach targets
    Dtrn = [trnX Dtrn(:, end)];
    Dval = [valX Dval(:, end)];
    Dtst = [tstX Dtst(:, end)];
end
