pragma circom 2.0.0;
// include "./mimc.circom";

/*
 * IfThenElse sets `out` to `true_value` if `condition` is 1 and `out` to
 * `false_value` if `condition` is 0.
 *
 * It enforces that `condition` is 0 or 1.
 *
 */
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

/*
 * SelectiveSwitch takes two data inputs (`in0`, `in1`) and produces two ouputs.
 * If the "select" (`s`) input is 1, then it inverts the order of the inputs
 * in the ouput. If `s` is 0, then it preserves the order.
 *
 * It enforces that `s` is 0 or 1.
 */
template SelectiveSwitch() {
    signal input in0;
    signal input in1;
    signal input s;
    signal output out0;
    signal output out1;

    // TODO
    s * (1 - s) === 0;
    signal aux;

    aux <== (in0-in1)*s;  
    out0 <==  aux + in1; //s = 0, then out0 <-in1, s = 1, then out0 <- in0
    out1 <== -aux + in0;  //s = 0, then out1 <-in0, s = 1, then out1 <- in1
}

template SelectiveSwitch2() {
    signal input in0;
    signal input in1;
    signal input s;
    signal output out0;
    signal output out1;

    // TODO
    // when s = 1, out <- in0
    // when s = 0, out <- in1 
    component IfThenElse0 = IfThenElse();
    IfThenElse0.true_value <== in0;
    IfThenElse0.false_value <== in1;
    IfThenElse0.condition <== s;

    // when s = 1, out <- in1
    // when s = 0, out <- in0 
    component IfThenElse1 = IfThenElse();
    IfThenElse1.true_value <== in0;
    IfThenElse1.false_value <== in1;
    IfThenElse1.condition <== 1 - s;

    out0 <== IfThenElse0.out;
    out1 <== IfThenElse1.out;
}

/*
 * Verifies the presence of H(`nullifier`, `nonce`) in the tree of depth
 * `depth`, summarized by `digest`.
 * This presence is witnessed by a Merle proof provided as
 * the additional inputs `sibling` and `direction`, 
 * which have the following meaning:
 *   sibling[i]: the sibling of the node on the path to this coin
 *               at the i'th level from the bottom.
 *   direction[i]: "0" or "1" indicating whether that sibling is on the left.
 *       The "sibling" hashes correspond directly to the siblings in the
 *       SparseMerkleTree path.
 *       The "direction" keys the boolean directions from the SparseMerkleTree
 *       path, casted to string-represented integers ("0" or "1").
 */
// template Spend(depth) {
//     signal input digest;
//     signal input nullifier;
//     signal private input nonce;
//     signal private input sibling[depth];
//     signal private input direction[depth];

//     // TODO
// }

component main = SelectiveSwitch2();