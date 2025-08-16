figure;
plot((1:size(experiment.B_history, 2)), experiment.B_history(3:end, :)');
legend(string((2:7)), Location="best")
xlim([0 10])