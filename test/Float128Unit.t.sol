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

    function test_add_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(a, b);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidB_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(b, a);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(a, b);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidB_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(b, a);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(a, b);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidB_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(b, a);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(a, b);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidB_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.add(b, a);
    }

    function test_add_Unit_ValidatePackedFloat_InvalidZero() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: corrupted zero");
        Float128.add(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidB_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(b, a);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidB_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(b, a);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidB_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(b, a);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(a, b);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidB_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.sub(b, a);
    }

    function test_sub_Unit_ValidatePackedFloat_InvalidZero() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: corrupted zero");
        Float128.sub(a, b);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(a, b);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidB_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(b, a);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(a, b);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidB_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(b, a);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(a, b);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidB_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(b, a);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(a, b);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidB_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.mul(b, a);
    }

    function test_mul_Unit_ValidatePackedFloat_InvalidZero() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: corrupted zero");
        Float128.mul(a, b);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(a, b);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidB_MedMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(b, a);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(a, b);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidB_MedMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(b, a);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(a, b);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidB_LMan_GreaterThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(b, a);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(a, b);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidB_LMan_LesserThanAccepted() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: unnormalized float");
        Float128.div(b, a);
    }

    function test_div_Unit_ValidatePackedFloat_InvalidZero() public {
        // 38 digit mantissa (valid)
        int mantissaB = 10000000000000000000000000000000000000;
        int exponentB = -37;

        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();
        packedFloat b = Float128.toPackedFloat(mantissaB, exponentB);

        vm.expectRevert("float128: corrupted zero");
        Float128.div(a, b);
    }

    function test_sqrt_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);

        vm.expectRevert("float128: unnormalized float");
        Float128.sqrt(a);
    }

    function test_sqrt_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);

        vm.expectRevert("float128: unnormalized float");
        Float128.sqrt(a);
    }

    function test_sqrt_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);

        vm.expectRevert("float128: unnormalized float");
        Float128.sqrt(a);
    }

    function test_sqrt_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);

        vm.expectRevert("float128: unnormalized float");
        Float128.sqrt(a);
    }

    function test_sqrt_Unit_ValidatePackedFloat_InvalidZero() public {
        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();

        vm.expectRevert("float128: corrupted zero");
        Float128.sqrt(a);
    }

    function test_ln_Unit_ValidatePackedFloat_InvalidA_MedMan_GreaterThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(false);

        vm.expectRevert("float128: unnormalized float");
        Ln.ln(a);
    }

    function test_ln_Unit_ValidatePackedFloat_InvalidA_MedMan_LesserThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(false);

        vm.expectRevert("float128: unnormalized float");
        Ln.ln(a);
    }

    function test_ln_Unit_ValidatePackedFloat_InvalidA_LMan_GreaterThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_GreaterThanAccepted(true);

        vm.expectRevert("float128: unnormalized float");
        Ln.ln(a);
    }

    function test_ln_Unit_ValidatePackedFloat_InvalidA_LMan_LesserThanAccepted() public {
        // Create an invalid float
        packedFloat a = _invalidFloatHelper_LesserThanAccepted(true);

        vm.expectRevert("float128: unnormalized float");
        Ln.ln(a);
    }

    function test_ln_Unit_ValidatePackedFloat_InvalidZero() public {
        // Create an invalid float
        packedFloat a = _corruptedZeroHelper();

        vm.expectRevert("float128: corrupted zero");
        Ln.ln(a);
    }

    function _invalidFloatHelper_GreaterThanAccepted(bool isLarge) internal returns (packedFloat invalid) {
        // 39 digit or 73 digit mantissa
        int mantissa = isLarge ? int(Float128.MAX_M_DIGIT_NUMBER + 1) : int(Float128.MAX_L_DIGIT_NUMBER + 1);
        invalid = packedFloat.wrap(uint(mantissa));
    }

    function _invalidFloatHelper_LesserThanAccepted(bool isLarge) internal returns (packedFloat invalid) {
        // 37 digit or 71 digit mantissa
        int mantissa = isLarge ? int(Float128.MIN_M_DIGIT_NUMBER - 1) : int(Float128.MIN_L_DIGIT_NUMBER - 1);
        invalid = packedFloat.wrap(uint(mantissa));
    }

    function _corruptedZeroHelper() internal pure returns (packedFloat invalid) {
        // Set the exponent bits to a non-zero value but keep mantissa as 0
        uint rawValue = 0;

        // Set exponent bits (shifting by EXPONENT_BIT = 242)
        // This creates a non-zero float value with zero mantissa
        rawValue |= uint(100) << Float128.EXPONENT_BIT;
        invalid = packedFloat.wrap(rawValue);
    }
}
