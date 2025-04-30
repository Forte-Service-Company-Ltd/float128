/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "src/Float128.sol";

contract FloatUtils is Test {
    using Float128 for packedFloat;

    int constant ZERO_OFFSET_NEG = -8192;
    uint LN_MAX_ERROR_ULPS = 99;
    int256 constant BOUNDS_LOW = -int(Float128.ZERO_OFFSET) + int(Float128.MAX_DIGITS_M_X_2) * 2;
    int256 constant BOUNDS_HIGH = int(Float128.ZERO_OFFSET) - int(Float128.MAX_DIGITS_M_X_2) * 2;

    function _buildFFIFloat128Python(int aMan, int aExp, int bMan, int bExp, string memory operation, int largeResult) internal pure returns (string[] memory) {
        string[] memory inputs = new string[](8);
        inputs[0] = "python3";
        inputs[1] = "script/float128_test.py";
        inputs[2] = vm.toString(aMan);
        inputs[3] = vm.toString(aExp);
        inputs[4] = vm.toString(bMan);
        inputs[5] = vm.toString(bExp);
        inputs[6] = operation;
        inputs[7] = vm.toString(largeResult);
        return inputs;
    }

    function _reverseNormalize(packedFloat float) internal pure returns (int256 mantissa) {
        int normalizedExponent;
        (mantissa, normalizedExponent) = float.decode();
        bool negative = false;
        if (normalizedExponent < 0) {
            normalizedExponent = normalizedExponent * -1;
            negative = true;
        }
        int256 expo = 1;
        for (int i = 0; i < normalizedExponent; i++) {
            expo = expo * 10;
        }
        if (negative) {
            mantissa = mantissa / expo;
        } else {
            mantissa = mantissa * expo;
        }
    }

    function setBounds(int aMan, int aExp, int bMan, int bExp) internal pure returns (int _aMan, int _aExp, int _bMan, int _bExp) {
        _aMan = bound(aMan, -999999999999999999999999999999999999999999999999999999999999999999999999, 999999999999999999999999999999999999999999999999999999999999999999999999);
        _aExp = bound(aExp, BOUNDS_LOW, BOUNDS_HIGH);
        _bMan = bound(bMan, -999999999999999999999999999999999999999999999999999999999999999999999999, 999999999999999999999999999999999999999999999999999999999999999999999999);
        _bExp = bound(bExp, BOUNDS_LOW, BOUNDS_HIGH);
    }

    function setBounds(int aMan, int aExp) internal pure returns (int _aMan, int _aExp) {
        _aMan = bound(aMan, -999999999999999999999999999999999999999999999999999999999999999999999999, 999999999999999999999999999999999999999999999999999999999999999999999999);
        _aExp = bound(aExp, BOUNDS_LOW, BOUNDS_HIGH);
    }

    function getPythonValue(int aMan, int aExp, int bMan, int bExp, string memory operation, bool isL) internal returns (int pyMan, int pyExp) {
        string[] memory inputs = _buildFFIFloat128Python(aMan, aExp, bMan, bExp, operation, isL ? int(1) : int(0));
        bytes memory res = vm.ffi(inputs);
        (pyMan, pyExp) = abi.decode((res), (int256, int256));
    }

    function getPackedFloatInputs(int aMan, int aExp, int bMan, int bExp) internal pure returns (packedFloat a, packedFloat b) {
        a = Float128.toPackedFloat(aMan, aExp);
        b = Float128.toPackedFloat(bMan, bExp);
    }

    function getPackedFloatInputsAndPythonValues(
        int aMan,
        int aExp,
        int bMan,
        int bExp,
        string memory operation,
        bool isL
    ) internal returns (packedFloat a, packedFloat b, int pyMan, int pyExp) {
        (pyMan, pyExp) = getPythonValue(aMan, aExp, bMan, bExp, operation, isL);
        (a, b) = getPackedFloatInputs(aMan, aExp, bMan, bExp);
    }

    function encodeManually(int xMan, int xExp, bool isL) internal pure returns (packedFloat x) {
        uint manuallyEncodedFloat = ((uint(xExp + int(Float128.ZERO_OFFSET)) << Float128.EXPONENT_BIT)) |
            (xMan < 0 ? Float128.MANTISSA_SIGN_MASK : 0) |
            (xMan < 0 ? uint(xMan * -1) : uint(xMan)) |
            (isL ? Float128.MANTISSA_L_FLAG_MASK : 0);
        x = packedFloat.wrap(manuallyEncodedFloat);
    }

    function decodeAndCheckResults(int aMan, int aExp, int bMan, int bExp, string memory operation, bool isL, packedFloat result, uint _ulpsOfTolerance) internal {
        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, bMan, bExp, operation, isL);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, _ulpsOfTolerance);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, 0);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp, uint _ulpsOfTolerance) internal pure {
        checkResults(packedFloat.wrap(0), rMan, rExp, pyMan, pyExp, _ulpsOfTolerance);
    }

    function checkResults(packedFloat r, int rMan, int rExp, int pyMan, int pyExp, uint _ulpsOfTolerance) internal pure {
        int ulpsOfTolerance = int(_ulpsOfTolerance);
        console2.log("solResult", packedFloat.unwrap(r));
        console2.log("rMan", rMan);
        console2.log("rExp", rExp);
        console2.log("pyMan", pyMan);
        console2.log("pyExp", pyExp);

        bool isLarge = packedFloat.unwrap(r) & Float128.MANTISSA_L_FLAG_MASK > 0;
        console2.log("isLarge", isLarge);

        // we always check that the result is normalized since this is vital for the library. Only exception is when the result is zero
        uint nDigits = findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan));
        console2.log("nDigits", nDigits);
        if (pyMan != 0) assertTrue(((nDigits == 38) || (nDigits == 72)), "Solidity result is not normalized");
        if (pyMan == 0) {
            assertEq(rMan, 0, "Solidity result is not zero");
            assertEq(rExp, ZERO_OFFSET_NEG, "Solidity result is not zero");
        }
        if (packedFloat.unwrap(r) != 0) nDigits == 38 ? assertFalse(isLarge) : assertTrue(isLarge);
        // we fix the python result due to the imprecision of python's log10. We cut precision where needed
        if (pyExp != rExp) {
            if (pyExp > rExp) {
                ++rExp;
                rMan /= 10;
            } else {
                ++pyExp;
                pyMan /= 10;
            }
        }
        // we only accept off by 1 if explicitly signaled. (addition/subtraction are famous for rounding difference with Python)
        if (ulpsOfTolerance > 0) {
            // we could be off by one due to rounding issues. The error should be less than 1/1e76
            if (pyMan != rMan) {
                console2.log("ulpsOfTolerance", ulpsOfTolerance);
                if (pyMan > rMan) assertLe(pyMan, rMan + ulpsOfTolerance);
                else assertGe(pyMan + ulpsOfTolerance, rMan);
            }
        } else assertEq(pyMan, rMan);

        if (pyMan != 0) assertEq(pyExp, rExp);
    }

    /**
     * @dev pure Solidity implementation of the normalization procedure that takes place in toPackedFloat function.
     */
    function emulateNormalization(int man, int exp) internal pure returns (int mantissa, int exponent) {
        if (man == 0) return (0, -8192);
        mantissa = man;
        exponent = exp;
        uint nDigits = findNumberOfDigits(uint(man < 0 ? -1 * man : man));
        if (nDigits != 38 && nDigits != 72) {
            int adj = int(Float128.MAX_DIGITS_M) - int(nDigits);
            exponent = exp - adj;
            if (exponent > Float128.MAXIMUM_EXPONENT) {
                if (adj > 0) {
                    exponent -= int(Float128.DIGIT_DIFF_L_M);
                    mantissa *= (int(Float128.BASE_TO_THE_DIGIT_DIFF * Float128.BASE ** uint(adj)));
                } else {
                    exponent += int(Float128.DIGIT_DIFF_L_M);
                    mantissa /= (int(Float128.BASE_TO_THE_DIGIT_DIFF) / int(Float128.BASE ** uint(-adj)));
                }
            } else {
                if (adj > 0) {
                    mantissa *= int(Float128.BASE ** uint(adj));
                } else {
                    mantissa /= int(Float128.BASE ** uint(-adj));
                }
            }
        } else if (nDigits == 38 && exponent > Float128.MAXIMUM_EXPONENT) {
            exponent -= int(Float128.DIGIT_DIFF_L_M);
            mantissa *= (int(Float128.BASE_TO_THE_DIGIT_DIFF));
        }
    }

    function findNumberOfDigits(uint x) internal pure returns (uint log) {
        assembly {
            if gt(x, 0) {
                if gt(x, 9999999999999999999999999999999999999999999999999999999999999999) {
                    log := 64
                    x := div(x, 10000000000000000000000000000000000000000000000000000000000000000)
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
