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

    function testEncoded_mul_regular(int aMan, int aExp, int bMan, int bExp) public {
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
    function testEncoded_div_regular(int aMan, int aExp, int bMan, int bExp) public {
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
    function testEncoded_divL(int aMan, int aExp, int bMan, int bExp) public {
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

    function testEncoded_add_regular(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "add", false);
        packedFloat result = Float128.add(a, b);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
    }

    function testEncoded_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "sub", false);
        packedFloat result = Float128.sub(a, b);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 1);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testEncoded_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        (packedFloat a, , int pyMan, int pyExp) = getPackedFloatInputsAndPythonValues(aMan, aExp, 0, 0, "sqrt", false);
        if (aMan < 0) vm.expectRevert("float128: squareroot of negative");
        packedFloat result = Float128.sqrt(a);
        (int rMan, int rExp) = Float128.decode(result);
        checkResults(result, rMan, rExp, pyMan, pyExp, 0);
    }

    function testLEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "le", false);
        bool result = Float128.le(a, b);
        assertEq(result, pyMan > 0);
    }

    function testLTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "lt", false);
        bool result = Float128.le(a, b);
        assertEq(result, pyMan > 0);
    }

    function testGTpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "gt", false);
        bool result = Float128.gt(a, b);
        assertEq(result, pyMan > 0);
    }

    function testGEpackedFloatFuzz(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        (packedFloat a, packedFloat b, int pyMan, ) = getPackedFloatInputsAndPythonValues(aMan, aExp, bMan, bExp, "ge", false);
        bool result = Float128.ge(a, b);
        assertEq(result, pyMan > 0);
    }

    function testLnpackedFloatFuzzRange1To1Point2(int aMan, int aExp) public {
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

    function testLnpackedFloatFuzzRange1Point2To3(int aMan, int aExp) public {
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

    function testLnpackedFloatFuzzRange0To1(int aMan, int aExp) public {
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

    function testLnpackedFloatFuzzRange2ToInfinity(int aMan, int aExp) public {
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

    function testLnpackedFloatFuzzAllRanges(int aMan, int aExp) public {
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

    function testLnpackedFloatUnit() public {
        int aMan = 10089492627524701326248021367100041644;
        int aExp = -37;

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

    function testToPackedFloatFuzz(int256 man, int256 exp) public pure {
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

    function testFindNumbeOfDigits(uint256 man) public pure {
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

    function testLNCaseOne() public pure {
        // Test Case 1:
        int mantissa = 339046758471559584917568900955540863464438633576559162723246173766731092;
        int exponent = -84;
        int expectedResultMantissa = -28712638366447213800267852694553857212;
        int expectedResultExp = -36;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseTwo() public pure {
        // Test Case 2:
        int mantissa = 419133353677143729020445529447665547757094903875495880378394873359780286;
        int exponent = -72;
        int expectedResultMantissa = -86956614316348604164580027803497950664;
        int expectedResultExp = -38;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseThree() public pure {
        // Test Case 3:
        int mantissa = 471738548555985204842829168083810940950366912454141453216936305944405297;
        int exponent = -73;
        int expectedResultMantissa = -30539154624132792807849865290472860264;
        int expectedResultExp = -37;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testLNCaseFour() public pure {
        // Test Case 1:
        int mantissa = 100000000000000000000000000000000000000000000000000000000000000000000000;
        int exponent = -71;
        int expectedResultMantissa = 0;
        int expectedResultExp = -8192;
        packedFloat a = Float128.toPackedFloat(mantissa, exponent);

        packedFloat retVal = Ln.ln(a);
        (int mantissaF, int exponentF) = Float128.decode(retVal);
        assertEq(mantissaF, expectedResultMantissa);
        assertEq(exponentF, expectedResultExp);
    }

    function testEqDifferentRepresentationsPositive(int aMan, int aExp) public pure {
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

    function testEqDifferentRepresentationsNegative(int aMan, int aExp) public pure {
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
