/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import {Ln} from "src/Ln.sol";
import "test/FloatUtils.sol";

contract Float128MaliciousEncodingTest is FloatUtils {
    using Float128 for int256;
    using Float128 for packedFloat;
    using Ln for packedFloat;

    function test_add_MaliciousEncoding(uint8 distanceFromExpBound) public {
        {
            // very negative exponent
            int bExp = 0;
            int bMan = 1;
            packedFloat b = bMan.toPackedFloat(bExp);
            int aMan = int(1);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            vm.expectRevert("float128: unnormalized float");
            packedFloat result = a.add(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "add", false, result, 1);
        }
        {
            // very positive exponent
            int aMan = int(9e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            int bExp = aExp;
            int bMan = 9e71;
            packedFloat b = bMan.toPackedFloat(bExp);
            vm.expectRevert("float128: unnormalized float");
            packedFloat result = a.add(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "add", false, result, 1);
        }
    }

    function test_sub_MaliciousEncoding(uint8 distanceFromExpBound) public {
        {
            // very negative exponent
            int aMan = int(2);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            packedFloat b = encodeManually(aMan - 1, aExp, false);
            vm.expectRevert("float128: unnormalized float");
            packedFloat result = a.sub(b);
            decodeAndCheckResults(aMan, aExp, aMan - 1, aExp, "sub", false, result, 1);
        }
        {
            // very positive exponent
            int aMan = int(Float128.MAX_L_DIGIT_NUMBER);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat b = encodeManually(aMan / 2, aExp, true);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 - 1) vm.expectRevert("float128: overflow");
            packedFloat result = a.sub(b);
            decodeAndCheckResults(aMan, aExp, aMan / 2, aExp, "sub", false, result, 1);
        }
    }

    function test_mul_MaliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            int aMan = int(1e37);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            // -37 is the exponent of b after normalization
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 + 37) vm.expectRevert("float128: underflow");
            packedFloat result = a.mul(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "mul", false, result, 1);
        }
        {
            // very positive exponent
            int aMan = int(1e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat result = a.mul(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "mul", false, result, 1);
        }
    }

    function test_div_MaliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            int aMan = int(1e37);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            // -37 is the exponent of b after normalization
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 * 2 - 37) vm.expectRevert("float128: underflow");
            packedFloat result = a.div(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "div", false, result, 1);
        }
        {
            // very positive exponent
            int aMan = int(1e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat result = a.div(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "div", false, result, 1);
        }
    }

    function test_divL_MaliciousEncoding(uint8 distanceFromExpBound) public {
        int bExp = 0;
        int bMan = 1;
        packedFloat b = bMan.toPackedFloat(bExp);
        {
            // very negative exponent
            int aMan = int(1e37);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            // -37 is the exponent of b after normalization
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 * 2 - 37) vm.expectRevert("float128: underflow");
            packedFloat result = a.divL(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "div", true, result, 1);
        }
        {
            // very positive exponent
            int aMan = int(1e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat result = a.divL(b);
            decodeAndCheckResults(aMan, aExp, bMan, bExp, "div", true, result, 1);
        }
    }

    function test_sqrt_MaliciousEncoding(uint8 distanceFromExpBound) public {
        {
            // very negative exponent
            /// @notice sqrt can't underflow due to the way the exponent is handled, and because of the reductionist nature
            /// of a square-root operation over the exponent of a number (it divides it by 2)
            int aMan = int(1e37);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            packedFloat result = a.sqrt();
            decodeAndCheckResults(aMan, aExp, 0, 0, "sqrt", false, result, 0);
        }
        {
            // very positive exponent
            /// @notice sqrt can't overflow due to the way the exponent is handled, and because of the reductionist nature
            /// of a square-root operation over the exponent of a number (it divides it by 2)
            int aMan = int(1e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat result = a.sqrt();
            decodeAndCheckResults(aMan, aExp, 0, 0, "sqrt", false, result, 0);
        }
    }

    function test_ln_MaliciousEncoding(uint8 distanceFromExpBound) public {
        {
            // very negative exponent
            /// @notice ln can't underflow due to the way the exponent is handled, and because of the reductionist nature
            /// of a square-root operation over the exponent of a number (ln results with an exponent close to 0)
            int aMan = int(1e37);
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            packedFloat a = encodeManually(aMan, aExp, false);
            packedFloat result = a.ln();
            decodeAndCheckResults(aMan, aExp, 0, 0, "ln", false, result, LN_MAX_ERROR_ULPS);
        }
        {
            // very positive exponent
            /// @notice ln can't overflow due to the way the exponent is handled, and because of the reductionist nature
            /// of a square-root operation over the exponent of a number (ln results with an exponent close to 0)
            int aMan = int(1e71);
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = encodeManually(aMan, aExp, true);
            packedFloat result = a.ln();
            decodeAndCheckResults(aMan, aExp, 0, 0, "ln", false, result, LN_MAX_ERROR_ULPS);
        }
    }

    function test_toPackedFloat_MaliciousEncoding(uint8 distanceFromExpBound, int aMan) public {
        aMan = bound(aMan, -int(Float128.MAX_76_DIGIT_NUMBER), int(Float128.MAX_76_DIGIT_NUMBER));
        uint nDigits = Float128.findNumberOfDigits(uint(aMan < 0 ? aMan * -1 : aMan));
        {
            // very negative exponent
            int aExp = int(uint(distanceFromExpBound)) - int(Float128.ZERO_OFFSET);
            if (distanceFromExpBound < Float128.MAX_DIGITS_M_X_2 && aMan != 0) vm.expectRevert("float128: underflow");
            packedFloat a = aMan.toPackedFloat(aExp);
            (int rMan, int rExp) = a.decode();
            (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "na", nDigits > 38);
            checkResults(a, rMan, rExp, pyMan, pyExp, 0);
        }
        {
            // very positive exponent
            int aExp = int(Float128.ZERO_OFFSET) - int(uint(distanceFromExpBound)) - 1;
            packedFloat a = aMan.toPackedFloat(aExp);
            (int rMan, int rExp) = a.decode();
            (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "na", nDigits > 38);
            checkResults(a, rMan, rExp, pyMan, pyExp, 0);
        }
    }

    function testExponentiationOverflow_DivisionOfLNumberByOverflowedExpReturnsZero() public pure {
        uint r;
        uint BASE = Float128.BASE;
        uint MAX_L_DIGIT_NUMBER = Float128.MAX_L_DIGIT_NUMBER;
        // we test the whole range of overflowed exponentiation which goes from 10**77 to 10**(exponent whole range)
        for (uint i = 77; i < Float128.ZERO_OFFSET * 2; i++) {
            // since all the overflowed exponentiations are greater than MAX_L_DIGIT_NUMBER, the result will always be zero
            assembly {
                r := div(MAX_L_DIGIT_NUMBER, exp(BASE, i))
            }
            assertEq(r, 0, "dividing an L number by an overflowed power of BASE does not return zero");
        }
    }

    function testExponentiationOverflow_ExpReturnsZeroForExponentsGreaterThan255() public pure {
        uint r;
        uint BASE = Float128.BASE;
        for (uint i = 256; i < Float128.ZERO_OFFSET * 2; i++) {
            assembly {
                r := exp(BASE, i)
            }
            assertEq(r, 0, "BASE to a power greater than 256 is not 0");
        }
    }
}
