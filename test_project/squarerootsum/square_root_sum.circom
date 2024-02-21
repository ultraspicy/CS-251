pragma circom 2.0.0;

// out <== (a - b) ^ 2
template DiffSquare(){
   //Declaration of signals.
   signal input in1;
   signal input in2;
   signal output out;

   signal diff;
   diff <== in1 - in2;
   out <== diff * diff;
}

// sum two number
template sum2() {
    signal input in1;
    signal input in2;

    signal output out;
    out <== in1 + in2;
}

// sum N number
template sumN(N) {
    //Declaration of signals.
    signal input in[N];
    signal output out;
    component comp[N-1];

    //Statements.
    for(var i = 0; i < N-1; i++){
        comp[i] = sum2();
    }
    comp[0].in1 <== in[0];
    comp[0].in2 <== in[1];
    for(var i = 0; i < N-2; i++){
        comp[i+1].in1 <== comp[i].out;
        comp[i+1].in2 <== in[i+2];
    }
    out <== comp[N-2].out;
}

// take two vector as input, compute the sqaure
template SquareRootSum(n) {
    signal input in1[n];
    signal input in2[n];

    signal output out;

    signal sigdiffsquare[n];
    component comdiffsquare[n];

    //Statements.
    for(var i = 0; i < n; i++){
        comdiffsquare[i] = DiffSquare();
    }

    for(var i = 0; i < n; i++) {
        comdiffsquare[i].in1 <== in1[i];
        comdiffsquare[i].in2 <== in2[i];
        sigdiffsquare[i] <== comdiffsquare[i].out;
    }

    component comsumn = sumN(n);
    for(var i = 0; i < n; i++) {
        comsumn.in[i] <== sigdiffsquare[i];
    }
    out <== comsumn.out;

}

component main = SquareRootSum(3);
