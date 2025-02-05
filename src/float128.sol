// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

type float128 is uint256;

struct Float {
    int significand;
    int exponent;
}

library FloatStructLibSol {
    function addStructs(
        Float memory a,
        Float memory b
    ) internal pure returns (Float memory r) {
        if (a.exponent == b.exponent) {
            r.significand = a.significand + b.significand;
            r.exponent = a.exponent;
        } else if (a.exponent > b.exponent) {
            r.exponent = a.exponent;
            r.significand =
                a.significand +
                (b.significand / int(10 ** uint(a.exponent - b.exponent)));
        } else {
            r.exponent = b.exponent;
            r.significand =
                b.significand +
                (a.significand / int(10 ** uint(b.exponent - a.exponent)));
        }
    }
}

library FloatStructLibYul {
    function add(
        Float memory a,
        Float memory b
    ) internal pure returns (Float memory r) {
        assembly {
            if eq(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(r, add(mload(a), mload(b)))
            }
            if gt(mload(add(a, 0x20)), mload(add(b, 0x20))) {
                mstore(add(r, 0x20), mload(add(a, 0x20)))
                mstore(
                    r,
                    add(
                        mload(a),
                        div(
                            mload(b),
                            exp(
                                10,
                                add(
                                    mload(add(a, 0x20)),
                                    add(not(mload(add(b, 0x20))), 1)
                                )
                            )
                        )
                    )
                )
            }
            if gt(mload(add(b, 0x20)), mload(add(a, 0x20))) {
                mstore(add(r, 0x20), mload(add(b, 0x20)))
                mstore(
                    r,
                    add(
                        mload(b),
                        div(
                            mload(a),
                            exp(
                                10,
                                add(
                                    mload(add(b, 0x20)),
                                    add(not(mload(add(a, 0x20))), 1)
                                )
                            )
                        )
                    )
                )
            }
        }
    }
}

library Float2Ints {
    function addInts(
        int aMan,
        int aExp,
        int bMan,
        int bExp
    ) internal pure returns (int rMan, int rExp) {
        assembly {
            if eq(aExp, bExp) {
                rExp := aExp
                rMan := add(aMan, bMan)
            }
            if gt(aExp, bExp) {
                rExp := aExp
                rMan := add(
                    aMan,
                    div(bMan, exp(10, add(aExp, add(not(bExp), 1))))
                )
            }
            if gt(bExp, aExp) {
                rExp := bExp
                rMan := add(
                    bMan,
                    div(aMan, exp(10, add(bExp, add(not(aExp), 1))))
                )
            }
        }
    }

    function mul128(
        int aMan,
        int aExp,
        int bMan,
        int bExp
    ) external pure returns (int256 rMan, int256 rExp) {
        //int c = aMan * bMan;
        //int newExp = aExp + bExp;
        bool isNegativeA;
        bool isNegativeB;
        assembly {
            if gt(shr(255, aMan), 0) {
                aMan := add(not(aMan), 1)
                isNegativeA := 1
            }
            if gt(shr(255, bMan), 0) {
                bMan := add(not(bMan), 1)
                isNegativeB := 1
            }
            rMan := mul(aMan, bMan)
            rExp := add(aExp, bExp)
        }

        uint256 rawResultSize = log10Ceiling(uint(rMan));
        assembly {
            if gt(rawResultSize, 38) {
                let expReducer := sub(rawResultSize, 38)
                rMan := div(rMan, exp(10, expReducer))
                rExp := sub(rExp, expReducer)
            }
            if xor(isNegativeA, isNegativeB) {
                rMan := add(not(rMan), 1)
            }
        }
    }

    function log10Ceiling(uint x) internal pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(
                    x,
                    9999999999999999999999999999999999999999999999999999999999999999
                ) {
                    log := 64
                    x := div(
                        x,
                        10000000000000000000000000000000000000000000000000000000000000000
                    )
                }
                if gt(x, 99999999999999999999999999999999) {
                    log := add(log, 32)
                    x := div(x, 100000000000000000000000000000000)
                }
                if gt(x, 9999999999999999) {
                    log := add(log, 16)
                    x := div(x, 10000000000000000)
                }
                if gt(x, 99999999) {
                    log := add(log, 8)
                    x := div(x, 100000000)
                }
                if gt(x, 9999) {
                    log := add(log, 4)
                    x := div(x, 10000)
                }
                if gt(x, 99) {
                    log := add(log, 2)
                    x := div(x, 100)
                }
                if gt(x, 9) {
                    log := add(log, 1)
                }
                log := add(log, 1)
            }
        }
    }
}

library FloatUintLib {
    /// 256 ... EXPONENT ... 129, MANTISSA_SIGN (128), 127 .. MANTISSA ... 0
    uint constant MANTISSA_MASK = 0xffffffffffffffffffffffffffffffff;
    uint constant MANTISSA_SIGN_MASK = 0x100000000000000000000000000000000;
    /// the exponent is signed using the offset zero to 128. max values: -128 and +127. Plenty for our case
    uint constant EXPONENT_MASK =
        0xfffffffffffffffffffffffffffffffe00000000000000000000000000000000;
    uint constant TOW_COMPLEMENT_SIGN_MASK =
        0x8000000000000000000000000000000000000000000000000000000000000000;

    function addUints(uint256 a, uint256 b) internal pure returns (float128 r) {
        assembly {
            // we extract the exponent and mantissas for both
            let aExp := and(a, EXPONENT_MASK)
            let bExp := and(b, EXPONENT_MASK)
            let aMan := and(a, MANTISSA_MASK)
            let bMan := and(b, MANTISSA_MASK)
            // we adjust the significant digits and set the exponent of the result
            if gt(aExp, bExp) {
                r := aExp
                bMan := div(bMan, exp(10, sub(shr(129, aExp), shr(129, bExp))))
            }
            if gt(bExp, aExp) {
                r := bExp
                aMan := div(aMan, exp(10, sub(shr(129, bExp), shr(129, aExp))))
            }
            if eq(aExp, bExp) {
                r := aExp
            }
            /// we use complements 2 for mantissa sign
            if and(a, MANTISSA_SIGN_MASK) {
                aMan := add(not(aMan), 1)
            }
            if and(b, MANTISSA_SIGN_MASK) {
                bMan := add(not(bMan), 1)
            }
            let addition := add(aMan, bMan)
            if and(TOW_COMPLEMENT_SIGN_MASK, addition) {
                r := or(r, MANTISSA_SIGN_MASK) // assign the negative sign
                addition := add(not(addition), 1) // convert back from 2's complement
            }
            r := or(r, addition)
        }
    }

    function encode(
        int mantissa,
        int exponent
    ) internal pure returns (uint256 float) {
        // bounds not enforced yet
        assembly {
            if and(mantissa, TOW_COMPLEMENT_SIGN_MASK) {
                float := add(MANTISSA_SIGN_MASK, add(not(mantissa), 1))
            }
            if iszero(and(mantissa, TOW_COMPLEMENT_SIGN_MASK)) {
                float := mantissa
            }
            float := or(float, shl(129, add(exponent, 128)))
        }
    }

    function decode(
        float128 float
    ) internal pure returns (int mantissa, int exponent) {
        assembly {
            // exponent
            let _exp := shr(129, and(float, EXPONENT_MASK))
            if gt(128, _exp) {
                exponent := add(not(sub(128, _exp)), 1)
            }
            if gt(_exp, 127) {
                exponent := sub(_exp, 128)
            }
            // mantissa
            mantissa := and(float, MANTISSA_MASK)
            /// we use complements 2 for mantissa sign
            if and(float, MANTISSA_SIGN_MASK) {
                mantissa := add(not(mantissa), 1)
            }
        }
    }

    function log10Ceiling(uint x) public pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(x, 99999999999999999999999999999999) {
                    log := 32
                    x := div(x, 100000000000000000000000000000000)
                }
                if gt(x, 9999999999999999) {
                    log := add(log, 16)
                    x := div(x, 10000000000000000)
                }
                if gt(x, 99999999) {
                    log := add(log, 8)
                    x := div(x, 100000000)
                }
                if gt(x, 9999) {
                    log := add(log, 4)
                    x := div(x, 10000)
                }
                if gt(x, 99) {
                    log := add(log, 2)
                    x := div(x, 100)
                }
                if gt(x, 9) {
                    log := add(log, 1)
                }
                log := add(log, 1)
            }
        }
    }
}

/*contract EquationWithStructs {
    using FloatStructLibYul for Float;

    uint public a;
    uint public b;

    function setAStructs(uint _a) internal {
        a = _a;
    }

    function setBStructs(uint _b) internal {
        b = _b;
    }

    // execution cost Sol 5186
    // execution cost Yul 5098
    function testStructs() internal view returns (uint r) {
        Float memory A = Float({exponent: -36, significand: int(a)});
        Float memory B = Float({exponent: -36, significand: int(b)});
        Float memory _r = A.add(B);

        if (_r.exponent == -36) {
            r = uint(_r.significand);
        } else if (_r.exponent < -36) {
            r = uint(_r.significand / int(10 ** uint(-36 - _r.exponent)));
        } else {
            r = uint(_r.significand * int(10 ** uint(-36 - _r.exponent)));
        }
    }
}

contract EquationUintFloat {
    using FloatUintLib for float128;

    float128 public a;
    float128 public b;

    function setA(float128 _a) internal {
        a = _a;
    }

    function setB(float128 _b) internal {
        b = _b;
    }

    // execution cost 4923
    function testUints() external view returns (float128 r) {
        r = a.add(b);
    }
}

contract FloatEncoder {
    using FloatUintLib for float128;
    using FloatUintLib for int256;

    function encode(
        int mantissa,
        int exponent
    ) external pure returns (float128 float) {
        float = mantissa.encode(exponent);
    }

    function decode(
        float128 float
    ) external pure returns (int mantissa, int exponent) {
        (mantissa, exponent) = float.decode();
    }
}

contract EquationWith2Ints {
    using Float2Ints for int;

    /*int public aMan;
    int public aExp;
    int public bMan;
    int public bExp;

    function setAInts(int _aMan, int _aExp) internal {
        aMan = _aMan;
        aExp = _aExp;
    }

    function setBInts(int _bMan, int _bExp) internal {
        bMan = _bMan;
        bExp = _bExp;
    }

    // execution cost Yul 5023
    function testInts(
        int aMan,
        int bMan
    ) internal view returns (int rMan, int rExp) {
        (rMan, rExp) = aMan.add(-36, bMan, -36);
    }
}*/
