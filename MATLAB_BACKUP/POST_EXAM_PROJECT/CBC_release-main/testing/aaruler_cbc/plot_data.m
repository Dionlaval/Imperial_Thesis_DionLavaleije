%% Example script to show how to plot data from the interface object

% number of samples to record in stream
stream_samples = 2000;
% downsampling to skip points
down_sample = 0;

% clean streams
ds_rtc.remove_stream

% set a stream and specify the variables to be recorded
ds_rtc.set_stream(1, {'out1','in1','out2','in2'}, stream_samples, down_sample);
% datafields may also be used here
% ds_rtc.set_stream(1, ds_rtc.datafields.dynamic_fields, stream_samples, down_sample);

% run a stream by seleting the stream id number
data = ds_rtc.run_stream('stream_id', 1, 'return_struct', true);

% % alternative to run_stream is to start_stream, wait, then get_stream
% % run_stream does all of this automatically
% ds_rtc.start_stream;
% pause(5);
% data=ds_rtc.get_stream;

% compute time array
data.time = (0:down_sample+1:stream_samples-1) * ds_rtc.par.time_step;


% plot
close all;
figure;
subplot(2,1,1);
plot(data.time, data.out1,'-')
xlabel('time (s)')
ylabel('out1')
subplot(2,1,2);
plot(data.time, data.out2,'-')
xlabel('time (s)')
ylabel('out2')

