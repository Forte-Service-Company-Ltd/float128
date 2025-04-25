/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import {Ln} from "src/Ln.sol";
import "test/FloatUtils.sol";

contract Float128UnitTest is FloatUtils {
    using Float128 for int256;
    using Float128 for packedFloat;
    using Ln for packedFloat;

    function test_ln_Unit_Custom() public {
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

    function test_ln_Unit_CaseOne() public pure {
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

    function test_ln_Unit_CaseTwo() public pure {
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

    function test_ln_Unit_CaseThree() public pure {
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

    function test_ln_Unit_CaseFour() public pure {
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

    function test_add_Unit_ValidatePackedFloat() public {
        // 39 digit mantissa
        int mantissaA = int(Float128.MAX_M_DIGIT_NUMBER + 1);
        int exponentA = -37;

        // 38 digit mantissa
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Have to wrap instead of using toPackedFloat because toPackedFloat normalizes the mantissa
        packedFloat a = packedFloat.wrap(uint(mantissaA));
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: invalid float");
        Float128.add(a, b);

        // Try with 73 digit mantissa
        mantissaA = int(Float128.MAX_L_DIGIT_NUMBER + 1);
        exponentA = -71;

        a = packedFloat.wrap(uint(mantissaA));

        vm.expectRevert("float128: invalid float");
        Float128.add(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat() public {
        // 39 digit mantissa
        int mantissaA = int(Float128.MAX_M_DIGIT_NUMBER + 1);
        int exponentA = -37;

        // 38 digit mantissa
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Have to wrap instead of using toPackedFloat because toPackedFloat normalizes the mantissa
        packedFloat a = packedFloat.wrap(uint(mantissaA));
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: invalid float");
        Float128.sub(a, b);

        // Try with 73 digit mantissa
        mantissaA = int(Float128.MAX_L_DIGIT_NUMBER + 1);
        exponentA = -71;

        a = packedFloat.wrap(uint(mantissaA));

        vm.expectRevert("float128: invalid float");
        Float128.sub(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_MedMantissa() public {
        // 39 digit mantissa
        int mantissaA = int(Float128.MAX_M_DIGIT_NUMBER + 1);
        int exponentA = 0;

        // 38 digit mantissa
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Have to wrap instead of using toPackedFloat because toPackedFloat normalizes the mantissa
        packedFloat a = packedFloat.wrap(uint(mantissaA));
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: invalid float");
        Float128.sub(a, b);
    }
}
