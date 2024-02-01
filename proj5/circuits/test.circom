pragma circom 2.0.0;

template IfThenElse() {
    signal input condition;
    signal input true_value;
    signal input false_value;
    signal output out;

    // TODO
    // Hint: You will need a helper signal...
    signal intermediate;
    condition * (1 - condition) === 0;
    
    intermediate <-- condition * true_value + (1 - condition) * false_value;
    out <-- intermediate;
}

component main = IfThenElse();