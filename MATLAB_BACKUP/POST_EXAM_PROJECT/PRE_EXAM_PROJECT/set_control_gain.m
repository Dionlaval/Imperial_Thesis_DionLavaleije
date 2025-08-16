function control = set_control_gain(Kp_val, input, control)
    control.Kd = Kp_val*input.w0/(2*pi);
    control.Kp = control.Kd_multiplier*control.Kd/4;
end