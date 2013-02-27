xx = dir('*matchinglen2.mat')

for f = 1:size(xx, 1);
    n = xx(f).name
    xx2 = load(n);
    xx3.names = xx2.names;
    xx3.onsets = struct2cell(xx2.onsets);
    xx3.durations = struct2cell(xx2.durations);
    save(n,'-struct','xx3')
end
