Name: []

## Question 1

In the following code-snippet from `Num2Bits`, it looks like `sum_of_bits`
might be a sum of products of signals, making the subsequent constraint not
rank-1. Explain why `sum_of_bits` is actually a _linear combination_ of
signals.

```
        sum_of_bits += (2 ** i) * bits[i];
```

## Answer 1

For each i, 2**i is a constant. So it's summing a constrant with bits[i], and bits[i]
is bit representation of input singal


## Question 2

Explain, in your own words, the meaning of the `<==` operator.

## Answer 2
assignment + contraint enforenment 

## Question 3

Suppose you're reading a `circom` program and you see the following:

```
    signal input a;
    signal input b;
    signal input c;
    (a & 1) * b === c;
```

Explain why this is invalid.

## Answer 3
a & 1 is not a linear comnbination of the input signal a