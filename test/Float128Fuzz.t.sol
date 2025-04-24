/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import {Ln} from "src/Ln.sol";
import "test/FloatUtils.sol";

contract Float128FuzzTest is FloatUtils {
    using Float128 for int256;
    using Float128 for packedFloat;
    using Ln for packedFloat;

    function test_mul_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "mul", false);
        (, int realAExp) = a.decode();
        (, int realBExp) = b.decode();

        if (aMan != 0 && bMan != 0 && realAExp + realBExp < 76 - int(Float128.ZERO_OFFSET)) vm.expectRevert("float128: underflow");
        if (aMan != 0 && bMan != 0 && realAExp + realBExp > int(Float128.ZERO_OFFSET) - 76) vm.expectRevert("float128: overflow");
        packedFloat result = Float128.mul(a, b);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 0);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_div_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "div", false);
        (, int realAExp) = a.decode();
        (, int realBExp) = b.decode();

        if (bMan == 0) vm.expectRevert("float128: division by zero");
        if (aMan != 0 && bMan != 0 && realAExp - realBExp < 76 * 2 - int(Float128.ZERO_OFFSET)) vm.expectRevert("float128: underflow");
        if (aMan != 0 && bMan != 0 && realAExp - realBExp > int(Float128.ZERO_OFFSET) - 76) vm.expectRevert("float128: overflow");
        packedFloat result = Float128.div(a, b);

        if (bMan != 0) {
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
        }
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_divL_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "div", true);
        (, int realAExp) = a.decode();
        (, int realBExp) = b.decode();

        if (bMan == 0) vm.expectRevert("float128: division by zero");
        if (aMan != 0 && bMan != 0 && realAExp - realBExp < 76 * 2 - int(Float128.ZERO_OFFSET)) vm.expectRevert("float128: underflow");
        if (aMan != 0 && bMan != 0 && realAExp - realBExp > int(Float128.ZERO_OFFSET) - 76) vm.expectRevert("float128: overflow");
        packedFloat result = Float128.divL(a, b);

        if (bMan != 0) {
            (int rMan, int rExp) = Float128.decode(result);
            checkResults(result, rMan, rExp, pyMan, pyExp, 0);
        }
    }

    function test_add_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "add", false);
        packedFloat result = Float128.add(a, b);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
    }

    function test_sub_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "sub", false);
        packedFloat result = Float128.sub(a, b);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_sqrt_Fuzz(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        (packedFloat a, , int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, 0, 0, "sqrt", false);
        if (aMan < 0) vm.expectRevert("float128: squareroot of negative");
        packedFloat result = Float128.sqrt(a);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 0);
    }

    function test_le_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "le", false);
        bool result = Float128.le(a, b);
        assertEq(result, pyMan > 0);
    }

    function test_lt_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "lt", false);
        bool result = Float128.le(a, b);
        assertEq(result, pyMan > 0);
    }

    function test_gt_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "gt", false);
        bool result = Float128.gt(a, b);
        assertEq(result, pyMan > 0);
    }

    function test_ge_Fuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "ge", false);
        bool result = Float128.ge(a, b);
        assertEq(result, pyMan > 0);
    }

    function test_ln_Fuzz_Range1To1Point2(int aMan, int aExp) public {
        aMan = bound(aMan, 10000000000000000000000000000000000000, 10200000000000000000000000000000000000);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = 1 - int(digits);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat retVal = Ln.ln(a);

        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "ln", false);
        (int rMan, int rExp) = Float128.decode(retVal);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, 106);
        }
    }

    function test_ln_Fuzz_Range1Point2To3(int aMan, int aExp) public {
        aMan = bound(aMan, 102000000000000000000000000000000000000000000000000000000000000000000000, 300000000000000000000000000000000000000000000000000000000000000000000000);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = 1 - int(digits);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat retVal = Ln.ln(a);

        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "ln", false);
        (int rMan, int rExp) = Float128.decode(retVal);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, LN_MAX_ERROR_ULPS);
        }
    }

    function test_ln_Fuzz_FuzzRange0To1(int aMan, int aExp) public {
        aMan = bound(aMan, 1, 999999999999999999999999999999999999999999999999999999999999999999999999);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = bound(aExp, -3000, 0 - int(digits));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat retVal = Ln.ln(a);

        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "ln", false);
        (int rMan, int rExp) = Float128.decode(retVal);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, LN_MAX_ERROR_ULPS);
        }
    }

    function test_ln_Fuzz_FuzzRange2ToInfinity(int aMan, int aExp) public {
        aMan = bound(aMan, 200000000000000000000000000000000000000000000000000000000000000000000000, 9999999999999999999999999999999999999999999999999999999999999999999999999999);
        uint digits = findNumberOfDigits(aMan < 0 ? uint(aMan * -1) : uint(aMan));
        aExp = bound(aExp, 1 - int(digits), 3000);

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat retVal = Ln.ln(a);

        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "ln", false);
        (int rMan, int rExp) = Float128.decode(retVal);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, LN_MAX_ERROR_ULPS);
        }
    }

    function test_ln_Fuzz_AllRanges(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        packedFloat a = Float128.toPackedFloat(aMan, aExp);

        if (a.le(int(0).toPackedFloat(0))) vm.expectRevert("float128: ln undefined");
        packedFloat retVal = Ln.ln(a);

        (int pyMan, int pyExp) = getPythonValue(aMan, aExp, 0, 0, "ln", false);
        (int rMan, int rExp) = Float128.decode(retVal);
        if (rMan == 0 && pyMan != 0) {
            // we might have cases for when truncation will make a number 1.0, but Python will take
            // the full number. In those cases, Solidity result will be zero, so we just check the
            // exponent of the Python response to make sure it stays within tolerance
            assertLe(pyExp, -75);
        } else {
            checkResults(retVal, rMan, rExp, pyMan, pyExp, LN_MAX_ERROR_ULPS);
        }
    }

    function test_toPackedFloat_Fuzz(int256 man, int256 exp) public pure {
        (man, exp, , ) = setBounds(man, exp, 0, 0);

        packedFloat float = man.toPackedFloat(exp);
        (int manDecode, int expDecode) = Float128.decode(float);
        packedFloat comp = manDecode.toPackedFloat(expDecode - exp);

        int256 retVal = 0;
        if (man != 0) {
            retVal = _reverseNormalize(comp);
        }
        assertEq(man, retVal);
    }

    function test_findNumbeOfDigits_Fuzz(uint256 man) public pure {
        console2.log(man);
        uint256 comparison = 1;
        uint256 iter = 0;
        while (comparison <= man) {
            comparison *= 10;
            iter += 1;
            if (comparison == 1e77 && comparison <= man) {
                iter += 1;
                break;
            }
        }
        uint256 retVal = Float128.findNumberOfDigits(man);
        assertEq(iter, retVal);
    }

    function test_eq_Fuzz_DifferentRepresentationsPositive(int aMan, int aExp) public pure {
        // Case positive a:
        aMan = bound(aMan, 10000000000000000000000000000000000000, 99999999999999999999999999999999999999);
        aExp = bound(aExp, -8000, 8000);
        int bMan = aMan * int(Float128.BASE_TO_THE_DIGIT_DIFF);
        int bExp = aExp - int(Float128.DIGIT_DIFF_L_M);
        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        bool retVal = Float128.eq(a, b);
        assertTrue(retVal);
    }

    function test_eq_Fuzz_DifferentRepresentationsNegative(int aMan, int aExp) public pure {
        // Case negative b:
        aMan = bound(aMan, 10000000000000000000000000000000000000, 99999999999999999999999999999999999999);
        aExp = bound(aExp, -8000, 8000);
        int bMan = -aMan * int(Float128.BASE_TO_THE_DIGIT_DIFF);
        int bExp = aExp - int(Float128.DIGIT_DIFF_L_M);
        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        bool retVal = Float128.eq(a, b);
        assertFalse(retVal);
    }
}
