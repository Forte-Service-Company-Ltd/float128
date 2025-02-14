# Float128 Solidity Library

## Overview

This is a signed floating-point library optimized for Solidity.

#### General floating-point concepts

a floating point number is a way to represent numbers in an efficient way. It is composed by 3 elements:

- **The mantissa**: the significant digits of the number. It is an integer that is later multiplied by the base elevated to the exponent's power.
- **The base**: generally either 2 or 10. It determines the base of the multiplier factor.
- **The exponent**: the amount of times the base will multiply/divide itself to later be applied to the mantissa.

Some examples:

- -0.0001 can be expressed as -1 x $10^{-4}$. 
    - Mantissa: -1
    - Base: 10
    - Exponent: -4

- 2222000000000000 can be expressed as 2222 x $10^{12}$. 
    - Mantissa: 2222
    - Base: 10
    - Exponent: 12

Floating point numbers can represent the same number in infinite ways by playing with the exponent. For instance, the first example could be also represented by -10 x $10^{-5}$, -100 x $10^{-6}$, -1000 x $10^{-7}$, etc. 

#### Library main features

- Base: 10
- Significant digits: 38
- Exponent range: -16384 and +16383

Available operations:

- Addition (add)
- Subtraction (sub)
- Multiplication (mul)
- Division (div)
- Square root (sqrt)

#### Types

This library uses 2 types. Although their gas usage is very similar, one of them is optimized for storage, and the other one is optimized for operations:

- **Float**: a struct that uses 2 256-bit words. Optimized for operations.
- **packedFloat**: a 256-bit word. Optimized for storage.

```Solidity
type packedFloat is uint256;

struct Float {
    int mantissa;
    int exponent;
}
```

All the operations are available for both types. Their usage are exactly the same for both, and there are conversion functions to go back and forth between them:

```Solidity
function convertToPackedFloat(Float memory _float) internal pure returns(packedFloat float);

function convertToUnpackedFloat(packedFloat _float) internal pure returns(Float memory float);
```

## Usage

Imagine you need to express a fractional number in Solidity such as 12345.678. The way to achieve that is:

Float version:

```Solidity
import "lib/Float128.sol"

contract Mathing{
    using Float128 for Float;

    ...

    int mantissa = 12345678;
    int exponent = -3;
    Float memory n = mantissa.toFloat(exponent);

    ...

}

```

packedFloat version:

```Solidity
import "lib/Float128.sol"

contract Mathing{
    using Float128 for packedFloat;

    ...

    int mantissa = 12345678;
    int exponent = -3;
    packedFloat n = mantissa.toPackedFloat(exponent);

    ...

}
```

Once you have your floating-point numbers in the correct format, you can start using them to carry out calculations:

```Solidity
    ...

    packedFloat E = m.mul(C.mul(C));

    ...

    Float memory c = (a.mul(a).add(b.mul(b))).sqrt();
```

## Normalization

Normalization is a **vital** step to ensure the highest gas efficiency and precision in this library. Normalization in this context means that the number is always expressed using 38 significant digits without leading zeros. Never more, and never less. The way to achieve this is by playing with the exponent.

For example, the number 12345.678 will have only one proper representation in this library: 12345678000000000000000000000000000000 x $10^{-33}$

For this reason, it is important to use the functions `toFloat()` and `toPackedFloat()` since these functions will normalize the numbers automatically.

_Note: It is encouraged to store the numbers as floating-point values, and not to convert them to fixed-point numbers or any other conversion that might truncate the significant digits as this will mean nothing less than loss of precision._

### Representation of zero

Zero is a special case in this library. It is the only number which mantissa is represented by all zeros. Its exponent is the smallest possible which is -16384.
