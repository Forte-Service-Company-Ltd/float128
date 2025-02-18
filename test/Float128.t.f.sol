/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/console2.sol";
import "src/Float128.sol";
import "test/FloatPythonUtils.sol";

contract Float128FuzzTest is FloatPythonUtils {
    using Float128 for int256;
    function setBounds(int aMan, int aExp, int bMan, int bExp) internal pure returns (int _aMan, int _aExp, int _bMan, int _bExp) {
        // numbers with more than 38 digits lose precision
        _aMan = bound(aMan, -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _aExp = bound(aExp, -74, 74);
        _bMan = bound(bMan, -99999999999999999999999999999999999999, 99999999999999999999999999999999999999);
        _bExp = bound(bExp, -74, 74);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp) internal pure {
        checkResults(rMan, rExp, pyMan, pyExp, false);
    }

    function checkResults(int rMan, int rExp, int pyMan, int pyExp, bool couldBeOffBy1) internal pure {
        // we always check that the result is normalized since this is vital for the library. Only exception is when the result is zero
        if (pyMan != 0) assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan)), 38, "Solidity result is not normalized");
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
        if (couldBeOffBy1) {
            // we could be off by one due to rounding issues. The error should be less than 1/1e76
            if (pyMan != rMan) {
                if (pyMan > rMan) assertEq(pyMan, rMan + 1);
                else assertEq(pyMan + 1, rMan);
            }
        } else {
            assertEq(pyMan, rMan);
        }
        if (pyMan != 0) assertEq(pyExp, rExp);
    }
    function testStruct_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.mul(aMan.toFloat(aExp), bMan.toFloat(bExp));

        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testEncoded_mul(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "mul");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.mul(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testStruct_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        if (bMan == 0) bMan = 1; //TODO check for division by zero

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.div(aMan.toFloat(aExp), bMan.toFloat(bExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testEncoded_div(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);
        if (bMan == 0) bMan = 1; //TODO check for division by zero

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "div");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.div(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testEncoded_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.add(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testStruct_add(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "add");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.add(aMan.toFloat(aExp), bMan.toFloat(bExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testEncoded_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);
        packedFloat b = Float128.toPackedFloat(bMan, bExp);

        packedFloat result = Float128.sub(a, b);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testStruct_sub(int aMan, int aExp, int bMan, int bExp) public {
        (aMan, aExp, bMan, bExp) = setBounds(aMan, aExp, bMan, bExp);

        string[] memory inputs = _buildFFIMul128(aMan, aExp, bMan, bExp, "sub");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.sub(aMan.toFloat(aExp), bMan.toFloat(bExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;
        if (pyMan != 0) assertEq(findNumberOfDigits(uint(rMan < 0 ? rMan * -1 : rMan)), 38, "Solidity result is not normalized");

        checkResults(rMan, rExp, pyMan, pyExp, true);
    }

    function testEncoded_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        // sqrt root should always receive a positive number
        if (aMan < 0) aMan = aMan * -1;

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "sqrt");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        packedFloat a = Float128.toPackedFloat(aMan, aExp);

        packedFloat result = Float128.sqrt(a);
        (int rMan, int rExp) = Float128.decode(result);

        checkResults(rMan, rExp, pyMan, pyExp);
    }

    function testStruct_sqrt(int aMan, int aExp) public {
        (aMan, aExp, , ) = setBounds(aMan, aExp, 0, 0);
        // sqrt root should always receive a positive number
        if (aMan < 0) aMan = aMan * -1;

        string[] memory inputs = _buildFFIMul128(aMan, aExp, 0, 0, "sqrt");
        bytes memory res = vm.ffi(inputs);
        (int pyMan, int pyExp) = abi.decode((res), (int256, int256));

        Float memory result = Float128.sqrt(aMan.toFloat(aExp));
        int rMan = result.mantissa;
        int rExp = result.exponent;

        checkResults(rMan, rExp, pyMan, pyExp);
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
