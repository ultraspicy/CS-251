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

    // notes: the form must follow quadratic(x, y) + linear(x, y) + C
    // quadratic1(x, y) + quadratic2(x, y) is not considered as quadratic
    intermediate <== condition * true_value;
    out <== intermediate + (1 - condition) * false_value;
}

component main = IfThenElse();